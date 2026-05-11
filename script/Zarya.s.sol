// SPDX-License-Identifier: CC0 1.0 Universal
pragma solidity ^0.8.28;

import {Script, console} from "forge-std-1.9.7/src/Script.sol";
import {Zarya} from "../src/Zarya.sol";
import {PartyOrgans, PartyOrgan} from "../src/libraries/PartyOrgans.sol";
import {Regions} from "../src/libraries/Regions.sol";

contract ZaryaScript is Script {
    function run() public {
        address regionalSovietMember = vm.envAddress("REGIONAL_SOVIET_MEMBER");
        address chairman = vm.envAddress("CHAIRMAN");

        PartyOrgan regionalSoviet = PartyOrgans.from(
            PartyOrgans.PartyOrganType.RegionalSoviet,
            Regions.Region.CHELYABINSKAYA_OBLAST,
            0
        );
        PartyOrgan chairperson = PartyOrgans.from(
            PartyOrgans.PartyOrganType.Chairperson,
            Regions.Region.FEDERAL,
            0
        );

        PartyOrgan[] memory organs = new PartyOrgan[](2);
        address[] memory members = new address[](2);
        organs[0] = regionalSoviet;  members[0] = regionalSovietMember;
        organs[1] = chairperson;     members[1] = chairman;

        vm.broadcast();
        Zarya zarya = new Zarya();
        console.log(unicode"Заря развёрнута по адресу:", address(zarya));

        vm.broadcast();
        zarya.initializeOrgans(organs, members);
        console.log(unicode"Органы инициализированы");
        console.log(unicode"Член 74.СОВ:", regionalSovietMember);
        console.log(unicode"Председатель (ПРЛ):", chairman);
    }
}
