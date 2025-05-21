// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockComet {
    mapping(address => mapping(address => uint256)) public collateralBalances; 

    function supply(address token, uint256 amount) external {
        require(amount > 0, "Invalid amount");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        collateralBalances[msg.sender][token] += amount;
    }

    function withdraw(address token, uint256 amount) external {
        require(collateralBalances[msg.sender][token] >= amount, "Insufficient collateral");
        collateralBalances[msg.sender][token] -= amount;
        IERC20(token).transfer(msg.sender, amount);
    }

    function withdrawTo(address token, address to, uint256 amount) external {
        require(collateralBalances[msg.sender][token] >= amount, "Insufficient collateral");
        collateralBalances[msg.sender][token] -= amount;
        IERC20(token).transfer(to, amount);
    }

    function collateralBalanceOf(address user, address token) external view returns (uint256) {
        return collateralBalances[user][token];
    }
}
