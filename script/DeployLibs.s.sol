// SPDX-License-Identifier: CC0 1.0 Universal
pragma solidity ^0.8.28;

import {Script} from "forge-std-1.9.7/src/Script.sol";
import {console} from "forge-std-1.9.7/src/console.sol";

contract DeployLibsScript is Script {
    function run() public {
        vm.startBroadcast();
        console.log("Deploying libraries...");

        address matriciesAddr = deployCode("Matricies.sol:Matricies");
        console.log("Matricies:", matriciesAddr);

        address partyOrgansAddr = deployCode("PartyOrgans.sol:PartyOrgans");
        console.log("PartyOrgans:", partyOrgansAddr);

        address regionsAddr = deployCode("Regions.sol:Regions");
        console.log("Regions:", regionsAddr);

        address votingsAddr = deployCode("Votings.sol:Votings");
        console.log("Votings:", votingsAddr);

        console.log("Libraries deployed.");
        vm.stopBroadcast();
    }
}
