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
import "./interfaces/IFlashLoanReceiver.sol";

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

    event FlashLoan(
        address indexed receiver,
        address indexed token,
        uint256 amount,
        uint256 fee,
        uint256 time
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

    function deposit(address token, uint256 reserve)
        public
        payable
        nonReentrant
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

    function withdraw(address token, uint256 reserve) public nonReentrant {
        _withdraw(token, reserve);
        require(
            ade(msg.sender, token) >= IConfig(config).aade(token),
            "Main.withdraw.EID00063"
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

    function mint(address token, uint256 supply) public nonReentrant {
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

    function burn(address token, uint256 supply) public nonReentrant {
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
    ) public payable nonReentrant {
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
        address[] memory users 
    ) public nonReentrant {
        require(!IConfig(config).locked(), "Main.exchange.EID00030");
        require(supply != 0, "Main.exchange.EID00090");
        address[] memory _users = _refresh(token, users);
        require(_users.length != 0, "Main.exchange.EID00091");

        //缓存被冻结仓位的状态. 避免兑换人自己的仓位也属于冻结仓位时, 避免由于其他仓位数据划转(到兑换人的仓位)而导致兑换人自己的仓位数据发生变化
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
        IBurnable(coin).burn(msg.sender, __supply);
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
            _getLatestPrice(token)
        );
    }

    function flashloan(
        address receiver,
        address token,
        uint256 amount,
        bytes memory params
    ) public nonReentrant {
        require(!IConfig(config).locked(), "Main.flashloan.EID00030");
        require(
            IConfig(config).hasToken(token) &&
                !IConfig(config).isDeprecated(token),
            "Main.flashloan.EID00070"
        );

        require(amount > 0, "Main.flashloan.EID00090");
        uint256 balancesBefore = IAsset(asset).balances(token);
        require(balancesBefore >= amount, "Main.flashlon.EID00100");

        uint256 flashloanFee = IConfig(config).flashloanFee();
        uint256 fee = amount.mul(flashloanFee).div(1e18);
        require(fee > 0, "Main.flashloan.EID00101");

        IFlashLoanReceiver flashLoanReceiver = IFlashLoanReceiver(receiver);
        address payable _receiver = address(uint160(receiver));

        IAsset(asset).withdraw(_receiver, token, amount);
        flashLoanReceiver.execute(token, amount, fee, asset, params);

        uint256 balancesAfter = IAsset(asset).balances(token);
        require(
            balancesAfter == balancesBefore.add(fee),
            "Main.flashloan.EID00102"
        );

        IAsset(asset).withdraw(IConfig(config).flashloanFeeRecipient(), token, fee);
        emit FlashLoan(receiver, token, amount, fee, block.timestamp);
    }

    //充足率 (Adequacy ratio)

    //@who @token 对应的资产充足率
    function ade(address owner, address token) public view returns (uint256) {
        IBalance.Swap memory swap = IBalance(balance).swaps(owner, token);
        if (swap.supply == 0) return uint256(-1);
        return
            swap
                .reserve
                .mul(_getLatestPrice(token))
                .mul(10**_dec(coin))
                .div(10**_dec(token))
                .div(swap.supply);
    }

    //@token 对应的资产充足率
    function ade(address token) public view returns (uint256) {
        IBalance.Swap memory gswap = IBalance(balance).gswaps(token);
        if (gswap.supply == 0) return uint256(-1);
        return
            gswap
                .reserve
                .mul(_getLatestPrice(token))
                .mul(10**_dec(coin))
                .div(10**_dec(token))
                .div(gswap.supply);
    }

    //系统总资产充足率
    function ade() public view returns (uint256) {
        uint256 reserve_values = 0;
        address[] memory tokens = IConfig(config).tokens();
        for (uint256 i = 0; i < tokens.length; ++i) {
            reserve_values = reserve_values.add(
                IBalance(balance).reserve(tokens[i]).mul(_getLatestPrice(tokens[i])).div(
                    10**_dec(tokens[i])
                )
            );
        }
        uint256 gsupply_values = IBalance(balance).gsupply();
        if (gsupply_values == 0) return uint256(-1);
        return reserve_values.mul(10**_dec(coin)).div(gsupply_values);
    }

    /** innernal functions */

    function _burn(address token, uint256 supply) internal {
        //全局停机
        require(!IConfig(config).locked(), "Main.burn.EID00030");
        //被废弃的代币生成的QIAN仍然允许销毁.
        require(IConfig(config).hasToken(token), "Main.burn.EID00070");
        uint256 _supply = IBalance(balance).supply(msg.sender, token);
        require(_supply >= supply, "Main.burn.EID00080");
        IBurnable(coin).burn(msg.sender, supply);
        IBalance(balance).burn(msg.sender, token, supply);
    }

    function _deposit(address token, uint256 reserve)
        internal
        returns (uint256)
    {
        require(!IConfig(config).locked(), "Main.deposit.EID00030");
        // //仅当受支持的代币才允许增加准备金(被废弃的代币不允许)
        require(
            IConfig(config).hasToken(token) &&
                !IConfig(config).isDeprecated(token),
            "Main.deposit.EID00070"
        );
        uint256 _reserve =
            IAsset(asset).deposit{value: msg.value}(msg.sender, token, reserve);
        IBalance(balance).deposit(msg.sender, token, _reserve);
        return _reserve;
    }

    function _mint(address token, uint256 supply) internal {
        require(!IConfig(config).locked(), "Main.mint.EID00030");
        require(
            IConfig(config).hasToken(token) &&
                !IConfig(config).isDeprecated(token),
            "Main.mint.EID00071"
        );

        uint256 _step = IConfig(config).step();
        require(supply >= _step, "Main.mint.EID00092");

        IMintable(coin).mint(msg.sender, supply);
        IBalance(balance).mint(msg.sender, token, supply);

        //后置充足率检测.
        require(
            ade(msg.sender, token) >= IConfig(config).bade(token),
            "Main.mint.EID00062"
        );

        uint256 _supply = IBalance(balance).supply(token);
        uint256 _line = IConfig(config).line(token);
        require(_supply <= _line, "Main.mint.EID00093");
    }

    function _withdraw(address token, uint256 reserve) internal {
        require(!IConfig(config).locked(), "Main.withdraw.EID00030");
        require(IConfig(config).hasToken(token), "Main.withdraw.EID00070");
        uint256 _reserve = IBalance(balance).reserve(msg.sender, token);
        require(_reserve >= reserve, "Main.withdraw.EID00081");
        IBalance(balance).withdraw(msg.sender, token, reserve);
        IAsset(asset).withdraw(msg.sender, token, reserve);
        //充足率检测在外部调用处进行.
    }

    function _getLatestPrice(address token) internal view returns (uint256) {
        return IOracle(IConfig(config).oracle()).getLatestPrice(token);
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
        for (uint256 i = 0; i < users.length; ++i) {
            if (_isfade(users[i], token))
                users[n++] = users[i];
        address[] memory _users = new address[](n);
        for (uint256 i = 0; i < n; ++i)
            _users[i] = users[i];
        return _users;
    }

    function _dec(address token) public view returns (uint256) {
        return IAsset(asset).decimals(token);
    }
}
