// SPDX-License-Identifier: CC0 1.0 Universal
pragma solidity ^0.8.28;

import {Test} from "forge-std-1.9.7/src/Test.sol";
import {Regions} from "../src/libraries/Regions.sol";

contract RegionsTest is Test {
    using Regions for Regions.Region;

    function test_RegionToString_Federal() public pure {
        assertEq(Regions.Region.FEDERAL.toString(), "00");
    }

    function test_RegionToString_Adygea() public pure {
        assertEq(Regions.Region.ADYGEA_REPUBLIC.toString(), "01");
    }

    function test_RegionToString_Moscow77() public pure {
        assertEq(Regions.Region.MOSCOW_77.toString(), "77");
    }

    function test_RegionToString_Moscow97() public pure {
        assertEq(Regions.Region.MOSCOW_97.toString(), "97");
    }

    function test_RegionToString_Moscow99() public pure {
        assertEq(Regions.Region.MOSCOW_99.toString(), "99");
    }

    function test_RegionToString_SaintPetersburg78() public pure {
        assertEq(Regions.Region.SAINT_PETERSBURG_78.toString(), "78");
    }

    function test_RegionToString_SaintPetersburg98() public pure {
        assertEq(Regions.Region.SAINT_PETERSBURG_98.toString(), "98");
    }

    function test_RegionToString_Sevastopol() public pure {
        assertEq(Regions.Region.SEVASTOPOL.toString(), "92");
    }

    function test_RegionToString_ChechenRepublic() public pure {
        assertEq(Regions.Region.CHECHEN_REPUBLIC.toString(), "95");
    }

    function test_RegionToString_KrymRepublic() public pure {
        assertEq(Regions.Region.KRYM_REPUBLIC.toString(), "82");
    }

    function test_RegionToString_DonetskPeoplesRepublic() public pure {
        assertEq(Regions.Region.DONETSK_PEOPLES_REPUBLIC.toString(), "80");
    }

    function test_RegionToString_LuganskPeoplesRepublic() public pure {
        assertEq(Regions.Region.LUGANSK_PEOPLES_REPUBLIC.toString(), "81");
    }

    function test_RegionToString_HersonskayaOblast() public pure {
        assertEq(Regions.Region.HERSONSKAYA_OBLAST.toString(), "84");
    }

    function test_RegionToString_ZaporozhskayaOblast() public pure {
        assertEq(Regions.Region.ZAPOROZHSKAYA_OBLAST.toString(), "85");
    }

    function test_RegionToString_ExternalLands88() public pure {
        assertEq(Regions.Region.EXTERNAL_LANDS_88.toString(), "88");
    }

    function test_RegionToString_ExternalLands94() public pure {
        assertEq(Regions.Region.EXTERNAL_LANDS_94.toString(), "94");
    }

    function test_RegionToString_VariousRegions() public pure {
        assertEq(Regions.Region.TATARSTAN_REPUBLIC.toString(), "16");
        assertEq(Regions.Region.BASHKORTOSTAN_REPUBLIC.toString(), "02");
        assertEq(Regions.Region.SAKHA_REPUBLIC_YAKUTIA.toString(), "14");
        assertEq(Regions.Region.SVERDLOVSKAYA_OBLAST_66.toString(), "66");
        assertEq(Regions.Region.SVERDLOVSKAYA_OBLAST_96.toString(), "96");
        assertEq(Regions.Region.KRASNODARSKY_KRAI_23.toString(), "23");
        assertEq(Regions.Region.KRASNODARSKY_KRAI_93.toString(), "93");
    }
}
