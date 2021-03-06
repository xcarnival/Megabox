// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "./lib/Published.sol";


contract Broker is ReentrancyGuardUpgradeable, Published {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    function initialize(address admin, address owner, address publisher) public initializer {
        __ReentrancyGuard_init();
        __Published_init(admin, owner, publisher);
    }

    //publisher => topic => subscriber
    mapping(address => mapping(bytes32 => EnumerableSetUpgradeable.AddressSet))
        private _subscribers;
    //subscriber => publisher => topic => handler
    mapping(address => mapping(address => mapping(bytes32 => bytes4)))
        public handlers;

    function subscribe(
        address subscriber, 
        address publisher, 
        bytes32 topic, 
        bytes4 handler
    ) external onlyOwner {
        require(
            handlers[subscriber][publisher][topic] != handler,
            "Already subscribed"
        );
        _subscribers[publisher][topic].add(subscriber);
        handlers[subscriber][publisher][topic] = handler;
    }

    function unsubscribe(
        address subscriber,
        address publisher,
        bytes32 topic
    ) external onlyOwner {
        require(
            handlers[subscriber][publisher][topic] != bytes4(0),
            "Not found subscribed topic"
        );
        _subscribers[publisher][topic].remove(subscriber);
        delete handlers[subscriber][publisher][topic];
    }

    //sig: handler(address publiser, bytes32 topic, bytes memory data)
    function publish(bytes32 topic, bytes calldata data)
        external
        nonReentrant
        onlyPublisher
    {
        uint256 length = _subscribers[msg.sender][topic].length();
        for (uint256 i = 0; i < length; ++i) {
            address subscriber = _subscribers[msg.sender][topic].at(i);
            bytes memory _data =
                abi.encodeWithSelector(
                    handlers[subscriber][msg.sender][topic],
                    msg.sender,
                    topic,
                    data
                );
            (bool successed, ) = subscriber.call(_data);
            require(successed, "Call to subscriber failed");
        }
    }

    function subscribers(address publisher, bytes32 topic)
        external
        view
        returns (address[] memory)
    {
        address[] memory values =
            new address[](_subscribers[publisher][topic].length());
        for (uint256 i = 0; i < values.length; ++i) {
            values[i] = _subscribers[publisher][topic].at(i);
        }
        return values;
    }
}
