// SPDX-License-Identifier: CC0 1.0 Universal
pragma solidity ^0.8.28;

import {Script, console} from "forge-std-1.9.7/src/Script.sol";
import {Zarya} from "../src/Zarya.sol";

contract ZaryaScript is Script {
    function run() public {
        vm.broadcast();
        Zarya zarya = new Zarya();
        console.log("Zarya deployed at:", address(zarya));
    }
}
