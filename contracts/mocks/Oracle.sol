// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Oracle is OwnableUpgradeable {
    mapping(address => uint256) public oracles;

    constructor() public {
        __Ownable_init();
    }

    function getLatestPrice(address token) public view returns (uint256) {
        return oracles[token];
    }

    function setPrice(address token, uint256 price) public onlyOwner {
        oracles[token] = price;
    }
}
