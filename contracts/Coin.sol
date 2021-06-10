// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20BurnableUpgradeable.sol";
import "./lib/Blacklist.sol";

contract Coin is ERC20BurnableUpgradeable, Blacklist {

    event DestroyedFrom(address indexed account, uint256 amount);

    function initialize(
        address admin,
        address owner,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public initializer {
        __Blacklist_init(admin, owner);
        __ERC20_init(name, symbol);
        _setupDecimals(decimals);
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        notBlacklisted(msg.sender)
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public
        virtual 
        override 
        notBlacklisted(sender) 
        returns (bool) 
    {
        return super.transferFrom(sender, recipient, amount);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function destroyFrom(address account) public onlyOwner {
        require(isBlacklisted(account), "Account not in blacklist");
        uint256 dirtyAmount = balanceOf(account);
        _burn(account, dirtyAmount);
        emit DestroyedFrom(account, dirtyAmount);
    }
}
