// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SafeLockFactory} from "../src/SafeLockFactory.sol";
import {SafeLock} from "../src/SafeLock.sol";

   interface IERC20 {
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}
contract SafeLockForkScript is Script {
  address constant USDC_HOLDER = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
//   address constant USDC_ADDRESS_MAINNET = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
  address constant USDC_ADDRESS = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
//   address constant COMET_ADDRESS_MAINNET = 0xc3d688B66703497DAA19211EEdff47f25384cdc3;
  address constant COMET_ADDRESS = 0x571621Ce60Cebb0c1D442B5afb38B1663C6Bf017;

  SafeLockFactory factory;
  SafeLock lock;
  IERC20 usdc = IERC20(USDC_ADDRESS);

 function setUp() public {
        vm.startPrank(USDC_HOLDER);
        factory = new SafeLockFactory();
    }

    function run()  external {
        testCreateSafeLockDepositAndWithdraw(); 
    }

    function testCreateSafeLockDepositAndWithdraw() public {
        // 1. Create SafeLock
        address safeLockAddr = factory.createSafeLock(30);
        lock = SafeLock(payable(safeLockAddr));

        uint256 amountToDeposit = 52 * 1e6; // 1000 USDC

        // 2. Approve SafeLock to spend USDC
        usdc.approve(address(lock), amountToDeposit);

        uint256 initialBalance = usdc.balanceOf(USDC_HOLDER);
        console.log("initial BalanceUSDC Balance before lock:", initialBalance);

        // 3. Deposit into SafeLock
        lock.deposit(amountToDeposit);
        console.log("Deposited");

        // 4. Fast forward time past lock period
        vm.warp(block.timestamp + 30 days);


       SafeLock.LockedSaving[] memory savings = lock.getLockedSaving();

        for (uint i = 0; i < savings.length; i++) {
        SafeLock.LockedSaving memory saving = savings[i];
        console.log(saving.lockPeriod);
        console.log(saving.amount);
    }
        console.log(lock.totalDeposited());

        // 5. Withdraw from SafeLock
        lock.withdraw(0);
        console.log("Withdrawn");

        uint256 balance = usdc.balanceOf(USDC_HOLDER);
        console.log("Final USDC Balance:", balance);
    }
}