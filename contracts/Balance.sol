// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "./lib/Owned.sol";

contract Balance is Owned {
    using SafeMathUpgradeable for uint256;

    struct Swap {
        uint256 reserve;
        uint256 supply;
    }

    mapping(address => mapping(address => Swap)) public swaps; //user->token->Swap
    mapping(address => Swap) public gswaps; //token -> Swap
    uint256 public gsupply;

    function initialize(address admin, address owner) external initializer {
        __Owned_init(admin, owner);
    }

    function deposit(
        address payer,
        address token,
        uint256 reserve
    ) external onlyOwner {
        swaps[payer][token].reserve = swaps[payer][token].reserve.add(reserve);
        gswaps[token].reserve = gswaps[token].reserve.add(reserve);
    }

    function withdraw(
        address receiver,
        address token,
        uint256 reserve
    ) external onlyOwner {
        swaps[receiver][token].reserve = swaps[receiver][token].reserve.sub(
            reserve
        );
        gswaps[token].reserve = gswaps[token].reserve.sub(reserve);
    }

    function burn(
        address payer,
        address token,
        uint256 supply
    ) external onlyOwner {
        swaps[payer][token].supply = swaps[payer][token].supply.sub(supply);
        gswaps[token].supply = gswaps[token].supply.sub(supply);
        gsupply = gsupply.sub(supply);
    }

    function mint(
        address receiver,
        address token,
        uint256 supply
    ) external onlyOwner {
        swaps[receiver][token].supply = swaps[receiver][token].supply.add(
            supply
        );
        gswaps[token].supply = gswaps[token].supply.add(supply);
        gsupply = gsupply.add(supply);
    }

    //Destroy USDxc of @payer, and add corresponding @reserve records to @payer, while @owner reduces the corresponding records.
    function exchange(
        address payer,
        address owner,
        address token,
        uint256 supply,
        uint256 reserve
    ) external onlyOwner {
        swaps[owner][token].supply = swaps[owner][token].supply.sub(supply);
        gswaps[token].supply = gswaps[token].supply.sub(supply);
        gsupply = gsupply.sub(supply);
        swaps[owner][token].reserve = swaps[owner][token].reserve.sub(reserve);
        swaps[payer][token].reserve = swaps[payer][token].reserve.add(reserve);
    }

    function reserve(address who, address token)
        external
        view
        returns (uint256)
    {
        return swaps[who][token].reserve;
    }

    function supply(address who, address token)
        external
        view
        returns (uint256)
    {
        return swaps[who][token].supply;
    }

    function reserve(address token) external view returns (uint256) {
        return gswaps[token].reserve;
    }

    function supply(address token) external view returns (uint256) {
        return gswaps[token].supply;
    }
}
