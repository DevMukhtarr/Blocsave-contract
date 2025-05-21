// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

interface ISafeLock {
    function deposit(uint256 amount) external;
    function withdraw(uint256 index) external;
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract SafeLockInteraction is Test {
    address constant SAFELOCK_ADDRESS = 0x42d10277A13689350725Bc8E71d6b8A25F54Be89;
    address constant USDC_ADDRESS = 0x42d10277A13689350725Bc8E71d6b8A25F54Be89;

    function run() external {
        // Load private key from .env
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(privateKey);

        // Start broadcasting real transactions
        vm.startBroadcast(privateKey);

        ISafeLock safelock = ISafeLock(SAFELOCK_ADDRESS);
        IERC20 usdc = IERC20(USDC_ADDRESS);

        // Approve SafeLock to spend your USDC
        usdc.approve(SAFELOCK_ADDRESS, 1e6);

        // Deposit 2 USDC (assuming 6 decimals)
        safelock.deposit(1e6);

        // Withdraw from index 0
        safelock.withdraw(0);

        vm.stopBroadcast();
    }
}