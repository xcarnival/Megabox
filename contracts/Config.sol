// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "./lib/Paused.sol";

contract Config is Paused {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    struct Collateral {
        uint256 bade; //Basic Adequacy ratio
        uint256 aade; //Alarm Adequacy ratio
        uint256 fade; //Frozen Adequacy ratio
        uint256 line; 
        bool isDeprecated;
    }

    mapping(address => Collateral) public collaterals;
    EnumerableSetUpgradeable.AddressSet private _tokens;

    uint256 public step; //Single mint minimum limit
    uint256 public gade; //global adequacy ratio
    address public feeRecipient;
    address public oracle;
    uint256 public mintFee;

    function initialize(
        address admin,
        address owner,
        address locker
    ) public initializer {
        __Paused_init(admin, owner, locker);
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

    function hasToken(address token) external view returns (bool) {
        return _tokens.contains(token);
    }

    function tokens() external view returns (address[] memory) {
        address[] memory addresses = new address[](_tokens.length());
        for (uint256 i = 0; i < _tokens.length(); ++i) {
            addresses[i] = _tokens.at(i);
        }
        return addresses;
    }

    function line(address token) external view returns (uint256) {
        return collaterals[token].line;
    }

    function isDeprecated(address token) external view returns (bool) {
        return collaterals[token].isDeprecated;
    }

    function setStep(uint256 _step) external onlyOwner {
        step = _step;
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }

    //批量设置充足率
    function setAdes(
        address _token,
        uint256 _bade,
        uint256 _aade,
        uint256 _fade
    ) external onlyOwner {
        require(_tokens.contains(_token), "Not found token");
        require(_bade > _aade && _aade > _fade, "Partial order required");

        collaterals[_token].bade = _bade;
        collaterals[_token].aade = _aade;
        collaterals[_token].fade = _fade;
    }

    function setLine(address token, uint256 _line) external onlyOwner {
        require(_tokens.contains(token), "Not found token");
        collaterals[token].line = _line;
    }

    function setGade(uint256 _gade) external onlyOwner {
        gade = _gade;
    }

    function addToken(address token) external onlyOwner {
        require(
            _tokens.add(token) || collaterals[token].isDeprecated,
            "Added token exists"
        );
        collaterals[token].isDeprecated = false;
    }

    function deprecateToken(address token) external onlyOwner {
        require(_tokens.contains(token), "Not found token");
        collaterals[token].isDeprecated = true;
    }

    function removeToken(address token) external onlyOwner {
        require(collaterals[token].isDeprecated, "Not isDeprecated Token");
        require(_tokens.remove(token), "Not found token");
        collaterals[token].isDeprecated = false;
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }

    function setMintFee(uint256 _mintFee) external onlyOwner {
        require(_mintFee <= 10000000000000000, "maximum 1% mint fee"); 
        mintFee = _mintFee;
    }
}
