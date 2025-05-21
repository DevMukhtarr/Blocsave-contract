// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {AdasheFactory} from "../src/AdasheFactory.sol";

contract AdasheScript is Script {
    AdasheFactory public adashefactory;

      function run() external {
        vm.startBroadcast();

        adashefactory = new AdasheFactory();

        vm.stopBroadcast();
    }
}