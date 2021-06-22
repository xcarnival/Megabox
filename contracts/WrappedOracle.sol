// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IWrappedOracle {
    function get(address token) external view returns (uint256, bool);
}

contract WrappedOracle {
    address public oracle;

    constructor(address _oracle) public {
        oracle = _oracle;
    }

    function getLatestPrice(address token) external view returns (uint256) {
        (uint256 price, bool valid) = IWrappedOracle(oracle).get(token);
        require(valid, "Invalid price");
        return price;
    }
}
