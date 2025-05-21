// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {QuickSave} from "../src/QuickSave.sol";

contract QuickSaveScript is Script {
    address constant USDC_BASE = 0x036CbD53842c5426634e7929541eC2318f3dCF7e; //testnet USDC to change for base mainnet
    // address constant USDC_BASE = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    QuickSave public quicksave;

    function run() external {
        vm.startBroadcast();

        quicksave = new QuickSave(USDC_BASE);

        vm.stopBroadcast();
    }
}