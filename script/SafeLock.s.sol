// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SafeLockFactory} from "../src/SafeLockFactory.sol";

contract SafeLockScript is Script {
    SafeLockFactory public safelockfactory;

    function run() external {
        vm.startBroadcast();

        safelockfactory = new SafeLockFactory();

        vm.stopBroadcast();
    }
}