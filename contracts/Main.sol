// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";

import "./interfaces/IBalance.sol";
import "./interfaces/IConfig.sol";
import "./interfaces/IAsset.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IBurnable.sol";
import "./interfaces/IMintable.sol";
import "./interfaces/IBroker.sol";
import "./interfaces/IPosition.sol";

contract Main is ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    event Deposit(
        address indexed sender,
        address indexed token,
        uint256 reserve,
        uint256 sysbalance
    );
    event Withdraw(
        address indexed sender,
        address indexed token,
        uint256 reserve,
        uint256 sysbalance
    );
    event Mint(
        address indexed sender,
        address indexed token,
        uint256 supply,
        uint256 coinsupply
    );
    event Burn(
        address indexed sender,
        address indexed token,
        uint256 supply,
        uint256 coinsupply
    );
    event Open(
        address indexed sender,
        address indexed token,
        uint256 reserve,
        uint256 supply,
        uint256 sysbalance,
        uint256 coinsupply
    );
    event Exchange(
        address indexed sender,
        uint256 supply,
        address indexed token,
        uint256 reserve,
        uint256 sysbalance,
        uint256 coinsupply,
        address[] frozens,
        uint256 price
    );

    address public config;
    address public balance;
    address public coin;
    address public asset;
    address public broker;
    address public position;

    function initialize(
        address _config,
        address _balance,
        address _asset,
        address _coin,
        address _broker,
        address _position
    ) public initializer {
        __ReentrancyGuard_init();
        config = _config;
        balance = _balance;
        asset = _asset;
        coin = _coin;
        broker = _broker;
        position = _position;
    }

    modifier notPaused() {
        require(!IConfig(config).paused(), "Paused");
        _;
    }

    function deposit(address token, uint256 reserve)
        external 
        payable
        nonReentrant
        notPaused
    {
        uint256 _reserve = _deposit(token, reserve);
        IBroker(broker).publish(
            keccak256("deposit"),
            abi.encode(msg.sender, token, _reserve)
        );
        IPosition(position).insert(msg.sender, token);
        emit Deposit(
            msg.sender,
            token,
            _reserve,
            IAsset(asset).balances(token)
        );
    }

    function withdraw(address token, uint256 reserve)
        external
        nonReentrant
        notPaused
    {
        _withdraw(token, reserve);
        require(
            ade(msg.sender, token) >= IConfig(config).bade(token),
            "Adequacy ratio too low"
        );
        IBroker(broker).publish(
            keccak256("withdraw"),
            abi.encode(msg.sender, token, reserve)
        );
        emit Withdraw(
            msg.sender,
            token,
            reserve,
            IAsset(asset).balances(token)
        );
    }

    function mint(address token, uint256 supply) external nonReentrant notPaused {
        _mint(token, supply);
        IBroker(broker).publish(
            keccak256("mint"),
            abi.encode(msg.sender, token, supply)
        );
        emit Mint(
            msg.sender,
            token,
            supply,
            IERC20Upgradeable(coin).totalSupply()
        );
    }

    function burn(address token, uint256 supply) external nonReentrant notPaused {
        _burn(token, supply);
        IBroker(broker).publish(
            keccak256("burn"),
            abi.encode(msg.sender, token, supply)
        );
        emit Burn(
            msg.sender,
            token,
            supply,
            IERC20Upgradeable(coin).totalSupply()
        );
    }

    function open(
        address token, //deposit token
        uint256 reserve,
        uint256 supply
    ) external payable nonReentrant notPaused {
        uint256 _reserve = _deposit(token, reserve);
        _mint(token, supply);
        IBroker(broker).publish(
            keccak256("open"),
            abi.encode(msg.sender, token, _reserve, supply)
        );
        IPosition(position).insert(msg.sender, token);
        emit Open(
            msg.sender,
            token,
            _reserve,
            supply,
            IAsset(asset).balances(token),
            IERC20Upgradeable(coin).totalSupply()
        );
    }

    function exchange(
        uint256 supply,
        address token,
        address[] memory users //frozen positions
    ) external nonReentrant notPaused {
        require(supply > 0, "Invalid argument: supply");
        address[] memory _users = _refresh(token, users);
        require(_users.length != 0, "No frozens");
        // Cache the status of frozen positions.
        // Avoid changes to the liquidator's own position data due to the transfer of other positions (to the liquidator's position) when the liquidator's own position is also a frozen position
        IBalance.Swap[] memory swaps = new IBalance.Swap[](_users.length);
        for (uint256 i = 0; i < _users.length; ++i) {
            //fix: Stack too deep, try removing local variables.
            (address _owner, address _token) = (_users[i], token);
            swaps[i] = IBalance(balance).swaps(_owner, _token);
        }

        uint256 _supply = supply;
        uint256 reserve = 0;
        for (uint256 i = 0; i < _users.length; ++i) {
            //fix: Stack too deep, try removing local variables.
            (address _owner, address _token) = (_users[i], token);

            uint256 rid = MathUpgradeable.min(swaps[i].supply, _supply);
            _supply = _supply.sub(rid);

            uint256 lot = rid.mul(swaps[i].reserve).div(swaps[i].supply);
            lot = MathUpgradeable.min(lot, swaps[i].reserve);

            IBalance(balance).exchange(msg.sender, _owner, _token, rid, lot);
            IBroker(broker).publish(
                keccak256("burn"),
                abi.encode(_owner, _token, rid)
            );
            reserve = reserve.add(lot);
            if (_supply == 0) break;
        }

        uint256 __supply = supply.sub(_supply);
        IBurnable(coin).burnFrom(msg.sender, __supply);
        _withdraw(token, reserve);
        IBroker(broker).publish(
            keccak256("exchange"),
            abi.encode(msg.sender, __supply, token, reserve, _users)
        );
        emit Exchange(
            msg.sender,
            __supply,
            token,
            reserve,
            IAsset(asset).balances(token),
            IERC20Upgradeable(coin).totalSupply(),
            _users,
            getLatestPrice(token)
        );
    }

    function ade(address owner, address token) public view returns (uint256) {
        IBalance.Swap memory swap = IBalance(balance).swaps(owner, token);
        if (swap.supply == 0) return uint256(-1);
        return
            swap
                .reserve
                .mul(getLatestPrice(token))
                .mul(10**_dec(coin))
                .div(10**_dec(token))
                .div(swap.supply);
    }

    function ade(address token) public view returns (uint256) {
        IBalance.Swap memory gswap = IBalance(balance).gswaps(token);
        if (gswap.supply == 0) return uint256(-1);
        return
            gswap
                .reserve
                .mul(getLatestPrice(token))
                .mul(10**_dec(coin))
                .div(10**_dec(token))
                .div(gswap.supply);
    }

    function ade() public view returns (uint256) {
        uint256 reserve_values = 0;
        address[] memory tokens = IConfig(config).tokens();
        for (uint256 i = 0; i < tokens.length; ++i) {
            reserve_values = reserve_values.add(
                IBalance(balance)
                    .reserve(tokens[i])
                    .mul(getLatestPrice(tokens[i]))
                    .div(10**_dec(tokens[i]))
            );
        }
        uint256 gsupply_values = IBalance(balance).gsupply();
        if (gsupply_values == 0) return uint256(-1);
        return reserve_values.mul(10**_dec(coin)).div(gsupply_values);
    }

    /** innernal functions */

    function _burn(address token, uint256 supply) internal {
        require(IConfig(config).hasToken(token), "Token not supported");
        uint256 _supply = IBalance(balance).supply(msg.sender, token);
        require(_supply >= supply, "Insufficient supply to burn");
        IBurnable(coin).burnFrom(msg.sender, supply);
        IBalance(balance).burn(msg.sender, token, supply);
    }

    function _deposit(address token, uint256 reserve)
        internal
        returns (uint256)
    {
        require(
            IConfig(config).hasToken(token) &&
                !IConfig(config).isDeprecated(token),
            "Token not supported to deposit"
        );
        uint256 _reserve = IAsset(asset).deposit{value: msg.value}(
            msg.sender,
            token,
            reserve
        );
        IBalance(balance).deposit(msg.sender, token, _reserve);
        return _reserve;
    }

    function _mint(address token, uint256 supply) internal {
        require(
            IConfig(config).hasToken(token) &&
                !IConfig(config).isDeprecated(token),
            "Token not supported to mint"
        );

        uint256 _step = IConfig(config).step();
        require(supply >= _step, "Minted too little");

        IBalance(balance).mint(msg.sender, token, supply);

        uint256 feeAmount = supply.mul(IConfig(config).mintFee()).div(1e18);
        IMintable(coin).mint(IConfig(config).feeRecipient(), feeAmount);
        uint256 mintAmount = supply.sub(feeAmount);
        IMintable(coin).mint(msg.sender, mintAmount);

        require(
            ade(msg.sender, token) >= IConfig(config).bade(token),
            "Adequacy ratio too low"
        );

        uint256 _supply = IBalance(balance).supply(token);
        uint256 _line = IConfig(config).line(token);
        require(_supply <= _line, "Supply reaches ceiling");
    }

    function _withdraw(
        address token,
        uint256 reserve
    ) internal {
        require(IConfig(config).hasToken(token), "Token not supported to mint");
        uint256 _reserve = IBalance(balance).reserve(msg.sender, token);
        require(_reserve >= reserve, "Insufficient reserve to withdraw");
        IBalance(balance).withdraw(msg.sender, token, reserve);
        IAsset(asset).withdraw(msg.sender, token, reserve);
    }

    function getLatestPrice(address token) internal view returns (uint256) {
        (uint256 price, bool valid) = IOracle(IConfig(config).oracle()).get(token);
        require(valid, "Price is valid");
        return price;
    }

    function _isfade(address owner, address token)
        internal
        view
        returns (bool)
    {
        return ade(owner, token) < IConfig(config).fade(token);
    }

    function _refresh(address token, address[] memory users)
        internal
        view
        returns (address[] memory)
    {
        uint256 n = 0;
        for (uint256 i = 0; i < users.length; ++i)
            if (_isfade(users[i], token)) users[n++] = users[i];
        address[] memory _users = new address[](n);
        for (uint256 i = 0; i < n; ++i) _users[i] = users[i];
        return _users;
    }

    function _dec(address token) public view returns (uint256) {
        return IAsset(asset).decimals(token);
    }
}
