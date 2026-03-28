// SPDX-License-Identifier: CC0 1.0 Universal
pragma solidity ^0.8.28;

import {Script, console} from "forge-std-1.9.7/src/Script.sol";
import {ZaryaUI} from "../src/ZaryaUI.sol";

contract ZaryaUIScript is Script {
    function run() public {
        vm.startBroadcast();
        ZaryaUI zaryaUI = new ZaryaUI();
        console.log("ZaryaUI deployed at:", address(zaryaUI));
        vm.stopBroadcast();
    }
}
