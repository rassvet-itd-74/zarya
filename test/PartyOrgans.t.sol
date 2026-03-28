// SPDX-License-Identifier: CC0 1.0 Universal
pragma solidity ^0.8.28;

import {Test} from "forge-std-1.9.7/src/Test.sol";
import {PartyOrgans, PartyOrgan} from "../src/libraries/PartyOrgans.sol";
import {Regions} from "../src/libraries/Regions.sol";

contract PartyOrgansTest is Test {
    using PartyOrgans for PartyOrgan;

    function test_GetPartyOrganIdentifier_LocalSoviet() public pure {
        string memory identifier =
            PartyOrgans.getPartyOrganIdentifier(PartyOrgans.PartyOrganType.LocalSoviet, Regions.Region.MOSCOW_77, 1);
        assertEq(identifier, unicode"77.1.СОВ");
    }

    function test_GetPartyOrganIdentifier_LocalGeneralAssembly() public pure {
        string memory identifier = PartyOrgans.getPartyOrganIdentifier(
            PartyOrgans.PartyOrganType.LocalGeneralAssembly, Regions.Region.MOSCOW_77, 5
        );
        assertEq(identifier, unicode"77.5.ОБС");
    }

    function test_GetPartyOrganIdentifier_RegionalSoviet() public pure {
        string memory identifier = PartyOrgans.getPartyOrganIdentifier(
            PartyOrgans.PartyOrganType.RegionalSoviet, Regions.Region.SAINT_PETERSBURG_78, 0
        );
        assertEq(identifier, unicode"78.СОВ");
    }

    function test_GetPartyOrganIdentifier_RegionalConference() public pure {
        string memory identifier = PartyOrgans.getPartyOrganIdentifier(
            PartyOrgans.PartyOrganType.RegionalConference, Regions.Region.TATARSTAN_REPUBLIC, 0
        );
        assertEq(identifier, unicode"16.КОН");
    }

    function test_GetPartyOrganIdentifier_RegionalGeneralAssembly() public pure {
        string memory identifier = PartyOrgans.getPartyOrganIdentifier(
            PartyOrgans.PartyOrganType.RegionalGeneralAssembly, Regions.Region.BASHKORTOSTAN_REPUBLIC, 0
        );
        assertEq(identifier, unicode"02.ОБС");
    }

    function test_GetPartyOrganIdentifier_Chairperson() public pure {
        string memory identifier =
            PartyOrgans.getPartyOrganIdentifier(PartyOrgans.PartyOrganType.Chairperson, Regions.Region.FEDERAL, 0);
        assertEq(identifier, unicode"ПРЛ");
    }

    function test_GetPartyOrganIdentifier_CentralSoviet() public pure {
        string memory identifier =
            PartyOrgans.getPartyOrganIdentifier(PartyOrgans.PartyOrganType.CentralSoviet, Regions.Region.FEDERAL, 0);
        assertEq(identifier, unicode"СОВ");
    }

    function test_GetPartyOrganIdentifier_Congress() public pure {
        string memory identifier =
            PartyOrgans.getPartyOrganIdentifier(PartyOrgans.PartyOrganType.Congress, Regions.Region.FEDERAL, 0);
        assertEq(identifier, unicode"СЗД");
    }

    function test_From_LocalSoviet() public pure {
        PartyOrgan organ = PartyOrgans.from(PartyOrgans.PartyOrganType.LocalSoviet, Regions.Region.MOSCOW_77, 1);

        // Verify it creates a consistent hash
        PartyOrgan organ2 = PartyOrgans.from(PartyOrgans.PartyOrganType.LocalSoviet, Regions.Region.MOSCOW_77, 1);

        assertEq(PartyOrgan.unwrap(organ), PartyOrgan.unwrap(organ2));
    }

    function test_From_DifferentOrgansHaveDifferentHashes() public pure {
        PartyOrgan organ1 = PartyOrgans.from(PartyOrgans.PartyOrganType.LocalSoviet, Regions.Region.MOSCOW_77, 1);

        PartyOrgan organ2 = PartyOrgans.from(PartyOrgans.PartyOrganType.LocalSoviet, Regions.Region.MOSCOW_77, 2);

        assertTrue(PartyOrgan.unwrap(organ1) != PartyOrgan.unwrap(organ2));
    }

    function test_From_RegionalVsLocalDifference() public pure {
        PartyOrgan localOrgan = PartyOrgans.from(PartyOrgans.PartyOrganType.LocalSoviet, Regions.Region.MOSCOW_77, 1);

        PartyOrgan regionalOrgan =
            PartyOrgans.from(PartyOrgans.PartyOrganType.RegionalSoviet, Regions.Region.MOSCOW_77, 0);

        assertTrue(PartyOrgan.unwrap(localOrgan) != PartyOrgan.unwrap(regionalOrgan));
    }

    function test_From_CentralOrgans() public pure {
        PartyOrgan chairperson = PartyOrgans.from(PartyOrgans.PartyOrganType.Chairperson, Regions.Region.FEDERAL, 0);

        PartyOrgan centralSoviet = PartyOrgans.from(PartyOrgans.PartyOrganType.CentralSoviet, Regions.Region.FEDERAL, 0);

        PartyOrgan congress = PartyOrgans.from(PartyOrgans.PartyOrganType.Congress, Regions.Region.FEDERAL, 0);

        // All should be different
        assertTrue(PartyOrgan.unwrap(chairperson) != PartyOrgan.unwrap(centralSoviet));
        assertTrue(PartyOrgan.unwrap(chairperson) != PartyOrgan.unwrap(congress));
        assertTrue(PartyOrgan.unwrap(centralSoviet) != PartyOrgan.unwrap(congress));
    }
}
