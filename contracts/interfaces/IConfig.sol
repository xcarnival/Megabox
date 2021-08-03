// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IConfig {
    function bade(address token) external view returns (uint256);
    function aade(address token) external view returns (uint256);
    function fade(address token) external view returns (uint256);
    function gade() external view returns(uint256);
    function line(address token) external view returns (uint256);
    function step() external view returns (uint256);
    function oracle() external view returns (address);
    function tokens() external view returns (address[] memory);
    function hasToken(address token) external view returns(bool);
    function isDeprecated(address token) external view returns(bool);
    function flashloanFee() external view returns(uint256);
    function feeRecipient() external view returns(address payable);
    function paused() external view returns(bool);
    function exFee() external view returns(uint256);
    function mintFee() external view returns(uint256);
}
