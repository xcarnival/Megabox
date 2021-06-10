// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IFlashLoanProvider {
    function flashloan(address receiver, address token, uint256 amount, bytes calldata params) external;
}