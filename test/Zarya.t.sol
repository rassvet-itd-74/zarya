// SPDX-License-Identifier: CC0 1.0 Universal
pragma solidity ^0.8.28;

import {Test} from "forge-std-1.9.7/src/Test.sol";
import {ZaryaTestHelper} from "./ZaryaTestHelper.sol";
import {PartyOrgans, PartyOrgan} from "../src/libraries/PartyOrgans.sol";
import {Regions} from "../src/libraries/Regions.sol";
import {Votings} from "../src/libraries/Votings.sol";

contract ZaryaTest is Test {
    ZaryaTestHelper public zarya;

    address member1 = address(0x1);
    address member2 = address(0x2);
    address member3 = address(0x3);
    address nonMember = address(0x4);
    address chairman = address(0x5);

    PartyOrgan testOrgan;
    PartyOrgan chairmanOrgan;

    uint256 constant DEFAULT_DURATION = 7 days;
    uint256 constant MINIMUM_QUORUM = 2;
    uint256 constant MINIMUM_APPROVAL = 51; // 51%

    function setUp() public {
        zarya = new ZaryaTestHelper();

        // Create a test organ for Moscow local soviet
        testOrgan = PartyOrgans.from(PartyOrgans.PartyOrganType.LocalSoviet, Regions.Region.MOSCOW_77, 1);

        // Create chairperson organ
        chairmanOrgan = PartyOrgans.from(PartyOrgans.PartyOrganType.Chairperson, Regions.Region.FEDERAL, 0);

        vm.label(member1, "Member 1");
        vm.label(member2, "Member 2");
        vm.label(member3, "Member 3");
        vm.label(nonMember, "Non-Member");
        vm.label(chairman, "Chairman");
    }

    // Helper function to add a member
    function _addMemberDirectly(address member, PartyOrgan organ) internal {
        zarya.addMemberForTesting(member, organ);
    }

    // ============ Membership Voting Tests ============

    function test_CreateMembershipVoting_RevertsForNonMember() public {
        vm.prank(nonMember);
        vm.expectRevert(abi.encodeWithSelector(PartyOrgans.NotActiveMember.selector, testOrgan, nonMember));
        zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);
    }

    function test_CreateMembershipVoting_Success() public {
        // First add member1 to the organ
        _addMemberDirectly(member1, testOrgan);

        vm.prank(member1);
        uint256 votingId = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);

        assertEq(votingId, 1);
        assertEq(zarya.nextVotingId(), 1);
        assertTrue(zarya.isVotingActive(votingId));
        assertFalse(zarya.isVotingFinalized(votingId));
    }

    function test_CreateMembershipVoting_SuccessAsChairman() public {
        // Add chairman to the chairperson organ
        _addMemberDirectly(chairman, chairmanOrgan);

        // Chairman can create membership voting for any organ without being a member of that organ
        vm.prank(chairman);
        uint256 votingId = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);

        assertEq(votingId, 1);
        assertEq(zarya.nextVotingId(), 1);
        assertTrue(zarya.isVotingActive(votingId));
        assertFalse(zarya.isVotingFinalized(votingId));
    }

    function test_CreateMembershipVoting_OrganMemberCanStillCreate() public {
        // Add both chairman and organ member
        _addMemberDirectly(chairman, chairmanOrgan);
        _addMemberDirectly(member1, testOrgan);

        // Organ member can still create
        vm.prank(member1);
        uint256 votingId = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);

        assertEq(votingId, 1);
        assertTrue(zarya.isVotingActive(votingId));
    }

    // ============ Category Voting Tests ============

    function test_CreateCategoryVoting_Success() public {
        _addMemberDirectly(member1, testOrgan);

        vm.prank(member1);
        uint256 votingId = zarya.createCategoryVoting(testOrgan, 1, 1, 100, "TestCategory", DEFAULT_DURATION);

        assertEq(votingId, 1);
        assertTrue(zarya.isVotingActive(votingId));
    }

    // ============ Decimals Voting Tests ============

    function test_CreateDecimalsVoting_Success() public {
        _addMemberDirectly(member1, testOrgan);

        vm.prank(member1);
        uint256 votingId = zarya.createDecimalsVoting(testOrgan, 1, 1, 2, DEFAULT_DURATION);

        assertEq(votingId, 1);
        assertTrue(zarya.isVotingActive(votingId));
    }

    // ============ Theme Voting Tests ============

    function test_CreateThemeVoting_Success() public {
        vm.prank(member1);
        uint256 votingId = zarya.createThemeVoting(true, 1, "Economy", DEFAULT_DURATION);

        assertEq(votingId, 1);
        assertTrue(zarya.isVotingActive(votingId));
    }

    // ============ Statement Voting Tests ============

    function test_CreateStatementVoting_Success() public {
        vm.prank(member1);
        uint256 votingId = zarya.createStatementVoting(true, 1, 1, "GDP Growth", DEFAULT_DURATION);

        assertEq(votingId, 1);
        assertTrue(zarya.isVotingActive(votingId));
    }

    // ============ Categorical Value Voting Tests ============

    function test_CreateCategoricalValueVoting_Success() public {
        _addMemberDirectly(member1, testOrgan);

        vm.prank(member1);
        uint256 votingId = zarya.createCategoricalValueVoting(testOrgan, 1, 1, 50, member1, DEFAULT_DURATION);

        assertEq(votingId, 1);
        assertTrue(zarya.isVotingActive(votingId));
    }

    // ============ Numerical Value Voting Tests ============

    function test_CreateNumericalValueVoting_Success() public {
        _addMemberDirectly(member1, testOrgan);

        vm.prank(member1);
        uint256 votingId = zarya.createNumericalValueVoting(testOrgan, 1, 1, 1500, member1, DEFAULT_DURATION);

        assertEq(votingId, 1);
        assertTrue(zarya.isVotingActive(votingId));
    }

    // ============ Vote Casting Tests ============

    function test_CastVote_Success() public {
        _addMemberDirectly(member1, testOrgan);

        vm.prank(member1);
        uint256 votingId = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);

        vm.prank(member1);
        zarya.castVote(votingId, true, testOrgan);

        assertTrue(zarya.hasVoted(votingId, member1));

        Votings.VoteResults memory results = zarya.getVotingResults(votingId);
        assertEq(results.forVotes, 1);
        assertEq(results.againstVotes, 0);
        assertEq(results.totalVotes, 1);
    }

    function test_CastVote_RevertsForNonMember() public {
        _addMemberDirectly(member1, testOrgan);

        vm.prank(member1);
        uint256 votingId = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);

        vm.prank(nonMember);
        vm.expectRevert(abi.encodeWithSelector(PartyOrgans.NotActiveMember.selector, testOrgan, nonMember));
        zarya.castVote(votingId, true, testOrgan);
    }

    function test_CastVote_RevertsWhenVotingInactive() public {
        _addMemberDirectly(member1, testOrgan);

        vm.prank(member1);
        uint256 votingId = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);

        // Warp past the voting period
        vm.warp(block.timestamp + DEFAULT_DURATION + 1);

        vm.prank(member1);
        vm.expectRevert(abi.encodeWithSelector(Votings.VotingNotActive.selector, votingId));
        zarya.castVote(votingId, true, testOrgan);
    }

    function test_CastVote_RevertsOnDoubleVote() public {
        _addMemberDirectly(member1, testOrgan);

        vm.prank(member1);
        uint256 votingId = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);

        vm.prank(member1);
        zarya.castVote(votingId, true, testOrgan);

        vm.prank(member1);
        vm.expectRevert(abi.encodeWithSelector(Votings.AlreadyVoted.selector, member1));
        zarya.castVote(votingId, true, testOrgan);
    }

    function test_CastVote_MultipleMembers() public {
        _addMemberDirectly(member1, testOrgan);
        _addMemberDirectly(member2, testOrgan);
        _addMemberDirectly(member3, testOrgan);

        vm.prank(member1);
        uint256 votingId = zarya.createMembershipVoting(testOrgan, nonMember, DEFAULT_DURATION);

        // member1 votes for
        vm.prank(member1);
        zarya.castVote(votingId, true, testOrgan);

        // member2 votes against
        vm.prank(member2);
        zarya.castVote(votingId, false, testOrgan);

        // member3 votes for
        vm.prank(member3);
        zarya.castVote(votingId, true, testOrgan);

        Votings.VoteResults memory results = zarya.getVotingResults(votingId);
        assertEq(results.forVotes, 2);
        assertEq(results.againstVotes, 1);
        assertEq(results.totalVotes, 3);
    }

    // ============ Vote Execution Tests ============

    function test_ExecuteVoting_RevertsWhenActive() public {
        _addMemberDirectly(member1, testOrgan);

        vm.prank(member1);
        uint256 votingId = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);

        vm.expectRevert(abi.encodeWithSelector(Votings.VotingStillActive.selector, votingId));
        zarya.executeVoting(votingId, MINIMUM_QUORUM, MINIMUM_APPROVAL);
    }

    function test_ExecuteVoting_RevertsOnInsufficientQuorum() public {
        _addMemberDirectly(member1, testOrgan);

        vm.prank(member1);
        uint256 votingId = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);

        // Only one vote
        vm.prank(member1);
        zarya.castVote(votingId, true, testOrgan);

        // Warp past voting period
        vm.warp(block.timestamp + DEFAULT_DURATION + 1);

        // Expect revert due to insufficient quorum (need 2, have 1)
        vm.expectRevert(abi.encodeWithSelector(Votings.InsufficientVotes.selector, 1, 0));
        zarya.executeVoting(votingId, MINIMUM_QUORUM, MINIMUM_APPROVAL);
    }

    function test_ExecuteVoting_SuccessfulMembershipVoting() public {
        _addMemberDirectly(member1, testOrgan);
        _addMemberDirectly(member2, testOrgan);

        vm.prank(member1);
        uint256 votingId = zarya.createMembershipVoting(testOrgan, member3, DEFAULT_DURATION);

        // Two votes for
        vm.prank(member1);
        zarya.castVote(votingId, true, testOrgan);

        vm.prank(member2);
        zarya.castVote(votingId, true, testOrgan);

        // Warp past voting period
        vm.warp(block.timestamp + DEFAULT_DURATION + 1);

        bool success = zarya.executeVoting(votingId, MINIMUM_QUORUM, MINIMUM_APPROVAL);

        assertTrue(success);
        assertTrue(zarya.isVotingFinalized(votingId));
    }

    function test_ExecuteVoting_FailedDueToInsufficientApproval() public {
        _addMemberDirectly(member1, testOrgan);
        _addMemberDirectly(member2, testOrgan);
        _addMemberDirectly(member3, testOrgan);

        vm.prank(member1);
        uint256 votingId = zarya.createMembershipVoting(testOrgan, nonMember, DEFAULT_DURATION);

        // 1 for, 2 against (33% approval)
        vm.prank(member1);
        zarya.castVote(votingId, true, testOrgan);

        vm.prank(member2);
        zarya.castVote(votingId, false, testOrgan);

        vm.prank(member3);
        zarya.castVote(votingId, false, testOrgan);

        // Warp past voting period
        vm.warp(block.timestamp + DEFAULT_DURATION + 1);

        bool success = zarya.executeVoting(votingId, MINIMUM_QUORUM, MINIMUM_APPROVAL);

        assertFalse(success);
        assertTrue(zarya.isVotingFinalized(votingId));
    }

    function test_ExecuteVoting_RevertsOnDoubleExecution() public {
        _addMemberDirectly(member1, testOrgan);
        _addMemberDirectly(member2, testOrgan);

        vm.prank(member1);
        uint256 votingId = zarya.createMembershipVoting(testOrgan, member3, DEFAULT_DURATION);

        vm.prank(member1);
        zarya.castVote(votingId, true, testOrgan);

        vm.prank(member2);
        zarya.castVote(votingId, true, testOrgan);

        vm.warp(block.timestamp + DEFAULT_DURATION + 1);

        zarya.executeVoting(votingId, MINIMUM_QUORUM, MINIMUM_APPROVAL);

        // Try to execute again
        vm.expectRevert(abi.encodeWithSelector(Votings.VotingAlreadyFinalized.selector, votingId));
        zarya.executeVoting(votingId, MINIMUM_QUORUM, MINIMUM_APPROVAL);
    }

    // ============ Edge Cases and View Functions ============

    function test_GetVotingResults_NonExistentVoting() public {
        vm.expectRevert(abi.encodeWithSelector(Votings.VotingNotFound.selector, 999));
        zarya.getVotingResults(999);
    }

    function test_HasVoted_ReturnsFalseForNonVoter() public {
        _addMemberDirectly(member1, testOrgan);

        vm.prank(member1);
        uint256 votingId = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);

        assertFalse(zarya.hasVoted(votingId, member2));
    }

    function test_IsVotingActive_ReturnsFalseAfterExpiry() public {
        _addMemberDirectly(member1, testOrgan);

        vm.prank(member1);
        uint256 votingId = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);

        assertTrue(zarya.isVotingActive(votingId));

        vm.warp(block.timestamp + DEFAULT_DURATION + 1);

        assertFalse(zarya.isVotingActive(votingId));
    }

    function test_MultipleVotingsInSequence() public {
        _addMemberDirectly(member1, testOrgan);

        vm.startPrank(member1);

        uint256 votingId1 = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);
        uint256 votingId2 = zarya.createCategoryVoting(testOrgan, 1, 1, 100, "TestCategory", DEFAULT_DURATION);
        uint256 votingId3 = zarya.createDecimalsVoting(testOrgan, 1, 1, 2, DEFAULT_DURATION);

        vm.stopPrank();

        assertEq(votingId1, 1);
        assertEq(votingId2, 2);
        assertEq(votingId3, 3);
        assertEq(zarya.nextVotingId(), 3);

        assertTrue(zarya.isVotingActive(votingId1));
        assertTrue(zarya.isVotingActive(votingId2));
        assertTrue(zarya.isVotingActive(votingId3));
    }
}
