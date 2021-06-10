// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IBroker {
    function publish(bytes32 topic, bytes calldata data) external;
}
