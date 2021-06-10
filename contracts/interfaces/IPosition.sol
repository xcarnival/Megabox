// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPosition {
    function position(uint256 index) external view returns (address, address);
    function index(address owner, address token) external view returns (uint256);
    function length() external view returns (uint256);
    function insert(address owner, address token) external returns (uint256);
}
