// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {QuickSave} from "../src/QuickSave.sol";

contract QuickSaveScript is Script {
    address constant USDC_ADDRESS = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
    QuickSave public quicksave;

    function run() external {
        vm.startBroadcast();

        quicksave = new QuickSave(USDC_ADDRESS);

        vm.stopBroadcast();
    }
}