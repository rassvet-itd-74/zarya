// SPDX-License-Identifier: CC0 1.0 Universal
pragma solidity ^0.8.28;

import {Test} from "forge-std-1.9.7/src/Test.sol";
import {ZaryaUI} from "../src/ZaryaUI.sol";
import {PartyOrgans} from "../src/libraries/PartyOrgans.sol";
import {Regions} from "../src/libraries/Regions.sol";

contract ZaryaUITest is Test {
    ZaryaUI public zaryaUI;

    address member1 = address(0x1);
    address member2 = address(0x2);
    address nonMember = address(0x3);
    address chairman = address(0x4);

    string constant CHAIRPERSON_ID = unicode"ПРЛ";
    string constant CENTRAL_SOVIET_ID = unicode"СОВ";
    string constant CHELYABINSK_SOVIET_ID = unicode"74.СОВ";
    string constant CHELYABINSK_LOCAL_SOVIET_ID = unicode"74.3.СОВ";
    string constant MOSCOW_LOCAL_SOVIET_ID = unicode"77.1.СОВ";

    uint256 constant DEFAULT_DURATION = 7 days;

    function setUp() public {
        zaryaUI = new ZaryaUI();
        vm.label(member1, "Member 1");
        vm.label(member2, "Member 2");
        vm.label(nonMember, "Non-Member");
        vm.label(chairman, "Chairman");
    }

    /// @dev Инициализирует контракт с одним членом в одном органе
    function _init(address member, string memory organId) internal {
        string[] memory organIds = new string[](1);
        organIds[0] = organId;
        address[] memory members = new address[](1);
        members[0] = member;
        zaryaUI.initializeOrgansReadable(organIds, members);
    }

    // ============ Initialization Tests ============

    function test_InitializeOrgansReadable_Success() public {
        string[] memory organIds = new string[](3);
        organIds[0] = CHAIRPERSON_ID;
        organIds[1] = CENTRAL_SOVIET_ID;
        organIds[2] = CHELYABINSK_SOVIET_ID;

        address[] memory members = new address[](3);
        members[0] = chairman;
        members[1] = member1;
        members[2] = member2;

        zaryaUI.initializeOrgansReadable(organIds, members);

        assertTrue(zaryaUI.checkMembership(chairman, CHAIRPERSON_ID));
        assertTrue(zaryaUI.checkMembership(member1, CENTRAL_SOVIET_ID));
        assertTrue(zaryaUI.checkMembership(member2, CHELYABINSK_SOVIET_ID));
        assertFalse(zaryaUI.checkMembership(nonMember, CHAIRPERSON_ID));
    }

    function test_InitializeOrgansReadable_RevertsOnSecondCall() public {
        _init(chairman, CHAIRPERSON_ID);
        string[] memory organIds = new string[](1);
        organIds[0] = CHAIRPERSON_ID;
        address[] memory members = new address[](1);
        members[0] = chairman;
        vm.expectRevert();
        zaryaUI.initializeOrgansReadable(organIds, members);
    }

    // ============ Membership Check Tests ============

    function test_AmIChairman() public {
        _init(chairman, CHAIRPERSON_ID);
        vm.prank(chairman);
        assertTrue(zaryaUI.amIChairman());
        vm.prank(nonMember);
        assertFalse(zaryaUI.amIChairman());
    }

    // ============ Proposal Creation Tests ============

    function test_ProposeMembership_Success() public {
        _init(member1, CENTRAL_SOVIET_ID);
        vm.prank(member1);
        assertEq(zaryaUI.proposeMembership(CENTRAL_SOVIET_ID, member2, DEFAULT_DURATION), 1);
    }

    function test_ProposeMembershipRevocation_Success() public {
        string[] memory organIds = new string[](2);
        organIds[0] = CENTRAL_SOVIET_ID;
        organIds[1] = CENTRAL_SOVIET_ID;
        address[] memory members = new address[](2);
        members[0] = member1;
        members[1] = member2;
        zaryaUI.initializeOrgansReadable(organIds, members);

        vm.prank(member1);
        assertEq(zaryaUI.proposeMembershipRevocation(CENTRAL_SOVIET_ID, member2, DEFAULT_DURATION), 1);
    }

    function test_ProposeCategory_Success() public {
        _init(member1, CENTRAL_SOVIET_ID);
        vm.prank(member1);
        assertEq(
            zaryaUI.proposeCategory(CENTRAL_SOVIET_ID, 0, 0, 1, unicode"Категория 1", DEFAULT_DURATION), 1
        );
    }

    function test_ProposeDecimals_Success() public {
        _init(member1, CENTRAL_SOVIET_ID);
        vm.prank(member1);
        assertEq(zaryaUI.proposeDecimals(CENTRAL_SOVIET_ID, 0, 0, 2, DEFAULT_DURATION), 1);
    }

    function test_ProposeThemeLabel_Success() public {
        assertEq(zaryaUI.proposeThemeLabel(true, 0, unicode"Тема 1", DEFAULT_DURATION), 1);
    }

    function test_ProposeStatementLabel_Success() public {
        assertEq(zaryaUI.proposeStatementLabel(true, 0, 0, unicode"Утверждение 1", DEFAULT_DURATION), 1);
    }

    function test_ProposeCategoricalValue_Success() public {
        _init(member1, CENTRAL_SOVIET_ID);
        vm.prank(member1);
        assertEq(zaryaUI.proposeCategoricalValue(CENTRAL_SOVIET_ID, 0, 0, 1, member1, DEFAULT_DURATION), 1);
    }

    function test_ProposeNumericalValue_Success() public {
        _init(member1, CENTRAL_SOVIET_ID);
        vm.prank(member1);
        assertEq(zaryaUI.proposeNumericalValue(CENTRAL_SOVIET_ID, 0, 0, 100, member1, DEFAULT_DURATION), 1);
    }

    // ============ Voting Tests ============

    function test_Vote_Success() public {
        _init(member1, CENTRAL_SOVIET_ID);
        vm.prank(member1);
        uint256 votingId = zaryaUI.proposeMembership(CENTRAL_SOVIET_ID, member2, DEFAULT_DURATION);
        vm.prank(member1);
        zaryaUI.vote(votingId, true, CENTRAL_SOVIET_ID);
    }

    // ============ Voting Info Tests ============

    function test_GetVotingInfo_MembershipProposal() public {
        _init(member1, CENTRAL_SOVIET_ID);
        vm.prank(member1);
        uint256 votingId = zaryaUI.proposeMembership(CENTRAL_SOVIET_ID, member2, DEFAULT_DURATION);

        ZaryaUI.VotingInfo memory info = zaryaUI.getVotingInfo(votingId);

        assertEq(info.votingId, votingId);
        assertEq(info.proposedBy, member1);
        assertTrue(info.active);
        assertFalse(info.finalized);
        assertEq(info.proposalType, unicode"Членство");
        assertEq(info.subjectAddress, member2);
    }

    function test_GetVotingInfo_CategoryProposal() public {
        _init(member1, CENTRAL_SOVIET_ID);
        vm.prank(member1);
        uint256 votingId = zaryaUI.proposeCategory(
            CENTRAL_SOVIET_ID, 5, 3, 42, unicode"Тестовая Категория", DEFAULT_DURATION
        );

        ZaryaUI.VotingInfo memory info = zaryaUI.getVotingInfo(votingId);

        assertEq(info.proposalType, unicode"Категория");
        assertEq(info.columnIndex, 5);
        assertEq(info.rowIndex, 3);
        assertEq(info.categoryId, 42);
        assertEq(info.categoryLabel, unicode"Тестовая Категория");
    }

    function test_GetVotingInfo_ThemeProposal() public {
        uint256 votingId = zaryaUI.proposeThemeLabel(true, 10, unicode"Новая Тема", DEFAULT_DURATION);

        ZaryaUI.VotingInfo memory info = zaryaUI.getVotingInfo(votingId);

        assertEq(info.proposalType, unicode"Тема");
        assertTrue(info.isCategorical);
        assertEq(info.columnIndex, 10);
        assertEq(info.label, unicode"Новая Тема");
    }

    // ============ Voting IDs Pagination Tests ============

    function test_GetVotingIds_EmptyList() public view {
        ZaryaUI.VotingPage memory page = zaryaUI.getVotingIds(0, 10);
        assertEq(page.totalCount, 0);
        assertEq(page.ids.length, 0);
    }

    function test_GetVotingIds_Pagination() public {
        for (uint256 i = 0; i < 15; i++) {
            zaryaUI.proposeThemeLabel(true, i, unicode"Тема", DEFAULT_DURATION);
        }

        ZaryaUI.VotingPage memory page1 = zaryaUI.getVotingIds(0, 5);
        assertEq(page1.totalCount, 15);
        assertEq(page1.ids[0], 15);
        assertEq(page1.ids[4], 11);

        ZaryaUI.VotingPage memory page2 = zaryaUI.getVotingIds(5, 5);
        assertEq(page2.ids[0], 10);
        assertEq(page2.ids[4], 6);

        ZaryaUI.VotingPage memory page3 = zaryaUI.getVotingIds(10, 5);
        assertEq(page3.ids[0], 5);
        assertEq(page3.ids[4], 1);
    }

    function test_GetVotingIds_OffsetBeyondTotal() public {
        zaryaUI.proposeThemeLabel(true, 0, unicode"Тема", DEFAULT_DURATION);
        ZaryaUI.VotingPage memory page = zaryaUI.getVotingIds(10, 5);
        assertEq(page.totalCount, 1);
        assertEq(page.ids.length, 0);
    }

    // ============ Organ Identifier Tests ============

    function test_OrganIdentifier_Chairperson() public view {
        assertEq(
            zaryaUI.organIdentifier(PartyOrgans.PartyOrganType.Chairperson, Regions.Region.FEDERAL, 0), CHAIRPERSON_ID
        );
    }

    function test_OrganIdentifier_CentralSoviet() public view {
        assertEq(
            zaryaUI.organIdentifier(PartyOrgans.PartyOrganType.CentralSoviet, Regions.Region.FEDERAL, 0),
            CENTRAL_SOVIET_ID
        );
    }

    function test_OrganIdentifier_RegionalSoviet() public view {
        assertEq(
            zaryaUI.organIdentifier(PartyOrgans.PartyOrganType.RegionalSoviet, Regions.Region.CHELYABINSKAYA_OBLAST, 0),
            CHELYABINSK_SOVIET_ID
        );
    }

    function test_OrganIdentifier_LocalSoviet() public view {
        assertEq(
            zaryaUI.organIdentifier(PartyOrgans.PartyOrganType.LocalSoviet, Regions.Region.CHELYABINSKAYA_OBLAST, 3),
            CHELYABINSK_LOCAL_SOVIET_ID
        );
        assertEq(
            zaryaUI.organIdentifier(PartyOrgans.PartyOrganType.LocalSoviet, Regions.Region.MOSCOW_77, 1),
            MOSCOW_LOCAL_SOVIET_ID
        );
    }

    // ============ Cell Details Tests ============

    function test_CategoricalCellDetails_DefaultState() public view {
        ZaryaUI.CategoricalCellDetails memory details = zaryaUI.categoricalCellDetails(0, 0);
        assertEq(details.allowedCategories.length, 0);
        assertEq(details.sampleLength, 0);
        assertEq(bytes(details.organId).length, 66);
    }

    function test_NumericalCellDetails_DefaultState() public view {
        ZaryaUI.NumericalCellDetails memory details = zaryaUI.numericalCellDetails(0, 0);
        assertEq(details.decimals, 0);
        assertEq(details.sampleLength, 0);
        assertEq(bytes(details.organId).length, 66);
    }

    // ============ Edge Cases ============

    function test_ProposeMembership_RevertsForNonMember() public {
        vm.prank(nonMember);
        vm.expectRevert();
        zaryaUI.proposeMembership(CENTRAL_SOVIET_ID, member2, DEFAULT_DURATION);
    }

    function test_Vote_RevertsForNonMember() public {
        _init(member1, CENTRAL_SOVIET_ID);
        vm.prank(member1);
        uint256 votingId = zaryaUI.proposeMembership(CENTRAL_SOVIET_ID, member2, DEFAULT_DURATION);
        vm.prank(nonMember);
        vm.expectRevert();
        zaryaUI.vote(votingId, true, CENTRAL_SOVIET_ID);
    }

    function test_GetVotingInfo_RevertsForNonExistentVoting() public {
        vm.expectRevert();
        zaryaUI.getVotingInfo(999);
    }

    function test_ProposeMembershipRevocation_RevertsForChairman() public {
        string[] memory organIds = new string[](2);
        organIds[0] = CHAIRPERSON_ID;
        organIds[1] = CENTRAL_SOVIET_ID;
        address[] memory members = new address[](2);
        members[0] = chairman;
        members[1] = member1;
        zaryaUI.initializeOrgansReadable(organIds, members);

        vm.prank(member1);
        vm.expectRevert();
        zaryaUI.proposeMembershipRevocation(CHAIRPERSON_ID, chairman, DEFAULT_DURATION);
    }
}
