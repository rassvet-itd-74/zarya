// SPDX-License-Identifier: CC0 1.0 Universal
pragma solidity ^0.8.28;

import {Script, console} from "forge-std-1.9.7/src/Script.sol";
import {Zarya} from "../src/Zarya.sol";
import {PartyOrgans, PartyOrgan} from "../src/libraries/PartyOrgans.sol";
import {Regions} from "../src/libraries/Regions.sol";

contract ZaryaRegionalScript is Script {
    function run() public {
        address zaryaAddress = vm.envAddress("ZARYA_ADDRESS");
        uint256 duration = vm.envUint("VOTING_DURATION");

        // Comma-separated list of member addresses, e.g. "0x1...,0x2...,0x3..."
        address[] memory regionalSovietMembers = vm.envAddress("REGIONAL_SOVIET_MEMBERS", ",");

        Zarya zarya = Zarya(zaryaAddress);

        PartyOrgan regionalSoviet =
            PartyOrgans.from(PartyOrgans.PartyOrganType.RegionalSoviet, Regions.Region.CHELYABINSKAYA_OBLAST, 0);

        for (uint256 i = 0; i < regionalSovietMembers.length; i++) {
            vm.broadcast();
            uint256 votingId = zarya.createMembershipVoting(regionalSoviet, regionalSovietMembers[i], duration);
            console.log(
                unicode"Голосование о вступлении члена 74.СОВ создано, id:",
                votingId
            );
            console.log(unicode"Кандидат:", regionalSovietMembers[i]);
        }
    }
}
