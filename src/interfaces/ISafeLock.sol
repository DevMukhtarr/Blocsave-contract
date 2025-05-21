// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
interface ISafeLock {
    function deposit(uint256 amount) external;
    function withdraw(uint256 index) external; 
}