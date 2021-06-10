// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IAsset {
    function deposit(
        address payer,
        address token,
        uint256 reserve
    ) external payable returns (uint256);

    function withdraw(
        address payable receiver,
        address token,
        uint256 reserve
    ) external returns (uint256);

    function balances(address token) external view returns (uint256);
    function decimals(address token) external view returns (uint256);
}
