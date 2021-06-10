// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IMintable {
    function mint(address who, uint256 supply) external;
}