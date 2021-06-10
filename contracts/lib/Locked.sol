// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Owned.sol";

contract Locked is Owned {
    bytes32 public constant LOCK_ROLE = keccak256("LOCK_ROLE");

    event AddedLocker(address indexed account);
    event RemovedLocker(address indexed account);

    bool public locked;

    function __Locked_init(address admin, address owner, address locker) internal {
        __Owned_init(admin, owner);
        __Locked_init_unchained(locker);
    }

    function __Locked_init_unchained(address locker) internal {
        _setRoleAdmin(LOCK_ROLE, OWNER_ROLE);
        _setupRole(LOCK_ROLE, locker);
        locked = false;
    }

    modifier onlyLocker() {
        require(isLocker(msg.sender), "!whitelist");
        _;
    }

    function isLocker(address account) public view returns (bool) {
        return hasRole(LOCK_ROLE, account);
    }

    function getLockers() public view returns (address[] memory) {
        uint256 count = getRoleMemberCount(LOCK_ROLE);
        address[] memory lockers = new address[](count);
        for (uint256 i = 0; i < count; ++i) {
            lockers[i] = getRoleMember(LOCK_ROLE, i);
        }
        return lockers;
    }

    function addLocker(address account) public onlyOwner {
        grantRole(LOCK_ROLE, account);
        emit AddedLocker(account);
    }

    function removeLocker(address account) public onlyOwner {
        revokeRole(LOCK_ROLE, account);
        emit RemovedLocker(account);
    }

    function lock() public onlyLocker {
        locked = true;
    }

    function unlock() public onlyLocker {
        locked = false;
    }
}
