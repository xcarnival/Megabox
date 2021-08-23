// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "./interfaces/IERC20Decimals.sol";
import "./lib/Owned.sol";

contract Asset is Owned {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address payable;

    receive() external payable {
        require(msg.sender.isContract(), "Only contracts can send ether");
    }

    function initialize(address admin, address owner) external initializer {
        __Owned_init(admin, owner);
    }

    function deposit(
        address payer,
        address token,
        uint256 reserve
    ) external payable onlyOwner returns (uint256) {
        if (token == address(0)) {
            require(msg.value == reserve, "Unexpected msg.value");
            return reserve;
        } else {
            require(msg.value == 0, "Unexpected msg.value");
            uint256 balanceOfSaved = IERC20Upgradeable(token).balanceOf(
                address(this)
            );
            IERC20Upgradeable(token).safeTransferFrom(
                payer,
                address(this),
                reserve
            );
            return
                IERC20Upgradeable(token).balanceOf(address(this)).sub(
                    balanceOfSaved
                );
        }
    }

    function withdraw(
        address payable receiver,
        address token,
        uint256 reserve
    ) external onlyOwner returns (uint256) {
        require(receiver != address(0), "Receiver is a zero address");
        if (token == address(0)) {
            receiver.transfer(reserve);
        } else {
            IERC20Upgradeable(token).safeTransfer(receiver, reserve);
        }
        return reserve;
    }

    function balances(address token) external view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        }
        return IERC20Upgradeable(token).balanceOf(address(this));
    }

    function decimals(address token) external view returns (uint256) {
        if (token == address(0)) {
            return 18;
        }
        return IERC20Decimals(token).decimals();
    }
}
