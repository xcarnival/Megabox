// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./lib/Owned.sol";

contract Position is Owned {
    event Insert(address indexed owner, address indexed token, uint256 index);

    struct Key {
        address user;
        address token;
    }

    struct Index {
        uint256 index;
        uint256 iflag;
    }

    uint256 private _length;
    mapping(uint256 => Key) private _keys;
    mapping(address => mapping(address => Index)) private _indexes;

    function initialize(address admin, address owner) public initializer {
        __Owned_init(admin, owner); 
        _length = 0;
    }

    function insert(address _user, address _token) public returns (uint256) {
        require(_length < uint256(-1), "Index overflow");
        Index memory index = _indexes[_user][_token];
        if(index.iflag == 1)
            return index.index;
        _keys[_length] = Key(_user, _token);
        _indexes[_user][_token] = Index(_length, 1);
        emit Insert(_user, _token, _length);
        return _length++;
    }
    
    function position(uint256 index) public view returns (address, address) {
        return (_keys[index].user, _keys[index].token);
    }

    function index(address _user, address _token) public view returns (uint256) {
        return _indexes[_user][_token].iflag == 1 ? _indexes[_user][_token].index : uint256(-1);
    }

    function length() public view returns (uint256) {
        return _length;
    }
}
