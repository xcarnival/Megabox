// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IOracle {
    function getLatestPrice(address token) external view returns (uint256);
}
