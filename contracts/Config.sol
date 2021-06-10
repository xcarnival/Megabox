// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "./lib/Locked.sol";

contract Config is Locked {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    struct Collateral {
        uint256 bade; //Basic Adequacy ratio
        uint256 aade; //Alarm Adequacy ratio
        uint256 fade; //Frozen Adequacy ratio
        uint256 line; //
        bool isDeprecated;
    }

    mapping(address => Collateral) public collaterals;
    EnumerableSetUpgradeable.AddressSet private _tokens;

    uint256 public step; //单次最低铸币量(所有币种)
    uint256 public gade; //全局充足率 //global adequacy ratio
    uint256 public flashloanFee;
    address public flashloanFeeRecipient;
    address public oracle;

    function initialize(
        address admin,
        address owner,
        address locker
    ) public initializer {
        __Locked_init(admin, owner, locker);
    }

    function bade(address token) external view returns (uint256) {
        return collaterals[token].bade;
    }

    function aade(address token) external view returns (uint256) {
        return collaterals[token].aade;
    }

    function fade(address token) external view returns (uint256) {
        return collaterals[token].fade;
    }

    function hasToken(address token) public view returns (bool) {
        return _tokens.contains(token);
    }

    function tokens() external view returns (address[] memory) {
        address[] memory addresses = new address[](_tokens.length());
        for (uint256 i = 0; i < _tokens.length(); ++i) {
            addresses[i] = _tokens.at(i);
        }
        return addresses;
    }

    function line(address token) public view returns (uint256) {
        return collaterals[token].line;
    }

    function isDeprecated(address token) public view returns(bool) {
        return collaterals[token].isDeprecated;
    }

    function setStep(uint256 _step) public onlyOwner {
        step = _step;
    }

    function setOracle(address _oracle) public onlyOwner {
        oracle = _oracle;
    }

    //批量设置充足率
    function setAdes(
        address _token,
        uint256 _bade,
        uint256 _aade,
        uint256 _fade
    ) public onlyOwner {
        require(hasToken(_token), "Not found token");
        require(_bade > _aade && _aade > _fade, "Partial order required");

        collaterals[_token].bade = _bade;
        collaterals[_token].aade = _aade;
        collaterals[_token].fade = _fade;
    }

    function setLine(address token, uint256 _line) public onlyOwner {
        require(hasToken(token), "Not found token");
        collaterals[token].line = _line;
    }

    function setGade(uint256 _gade) public onlyOwner {
        gade = _gade;
    }

    function addToken(address token) public onlyOwner {
        require(
            _tokens.add(token) || isDeprecated(token),
            "Added token exists"
        );
        collaterals[token].isDeprecated = false;
    }

    function deprecateToken(address token) public onlyOwner {
        require(_tokens.contains(token), "Not found token");
        collaterals[token].isDeprecated = true;
    }

    function removeToken(address token) public onlyOwner {
        require(isDeprecated(token), "Not isDeprecated Token");
        require(_tokens.remove(token), "Not found token");
        collaterals[token].isDeprecated = false;
    }

    function setFlashloanFee(uint256 _flashloanFee) public onlyOwner {
        flashloanFee = _flashloanFee;
    }

    function setFlashloanFeeRecipient(address _flashloanFeeRecipient) public onlyOwner {
        flashloanFeeRecipient = _flashloanFeeRecipient;
    }
}
