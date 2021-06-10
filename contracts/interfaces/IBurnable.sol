// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IBurnable {
    function burn(address who, uint256 supply) external;
}