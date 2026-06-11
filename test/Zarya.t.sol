// SPDX-License-Identifier: CC0 1.0 Universal
pragma solidity ^0.8.28;

import {Test} from "forge-std-1.9.7/src/Test.sol";

contract ZaryaTest is Test {}

// import {Zarya} from "../src/Zarya.sol";
// import {PartyOrgans, PartyOrgan} from "../src/libraries/PartyOrgans.sol";
// import {Regions} from "../src/libraries/Regions.sol";
// import {Votings} from "../src/libraries/Votings.sol";

// contract ZaryaTest is Test {
//     Zarya public zarya;

//     address member1 = address(0x1);
//     address member2 = address(0x2);
//     address member3 = address(0x3);
//     address nonMember = address(0x4);
//     address chairman = address(0x5);

//     PartyOrgan testOrgan;
//     PartyOrgan chairmanOrgan;

//     uint256 constant DEFAULT_DURATION = 7 days;
//     uint256 constant MINIMUM_QUORUM = 2;
//     uint256 constant MINIMUM_APPROVAL = 51; // 51%

//     function setUp() public {
//         zarya = new Zarya(chairman);

//         testOrgan = PartyOrgans.from(PartyOrgans.PartyOrganType.LocalSoviet, Regions.Region.MOSCOW_77, 1);
//         chairmanOrgan = PartyOrgans.from(PartyOrgans.PartyOrganType.Chairperson, Regions.Region.FEDERAL, 0);

//         vm.label(member1, "Member 1");
//         vm.label(member2, "Member 2");
//         vm.label(member3, "Member 3");
//         vm.label(nonMember, "Non-Member");
//         vm.label(chairman, "Chairman");
//     }

//     function _initOrgans(PartyOrgan[] memory organs, address[] memory addrs) internal {
//         vm.prank(chairman);
//         zarya.initializeOrgans(organs, addrs);
//     }

//     // ============ Membership Voting Tests ============

//     function test_CreateMembershipVoting_RevertsForNonMember() public {
//         vm.prank(nonMember);
//         vm.expectRevert(abi.encodeWithSelector(PartyOrgans.NotActiveMember.selector, testOrgan, nonMember));
//         zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);
//     }

//     function test_CreateMembershipVoting_Success() public {
//         PartyOrgan[] memory organs = new PartyOrgan[](1);
//         address[] memory addrs = new address[](1);
//         organs[0] = testOrgan;
//         addrs[0] = member1;
//         _initOrgans(organs, addrs);

//         vm.prank(member1);
//         uint256 votingId = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);

//         assertEq(votingId, 1);
//         assertEq(zarya.nextVotingId(), 1);
//         assertTrue(zarya.isVotingActive(votingId));
//         assertFalse(zarya.isVotingFinalized(votingId));
//     }

//     function test_CreateMembershipVoting_SuccessAsChairman() public {
//         PartyOrgan[] memory organs = new PartyOrgan[](1);
//         address[] memory addrs = new address[](1);
//         organs[0] = chairmanOrgan;
//         addrs[0] = chairman;
//         _initOrgans(organs, addrs);

//         vm.prank(chairman);
//         uint256 votingId = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);

//         assertEq(votingId, 1);
//         assertEq(zarya.nextVotingId(), 1);
//         assertTrue(zarya.isVotingActive(votingId));
//         assertFalse(zarya.isVotingFinalized(votingId));
//     }

//     function test_CreateMembershipVoting_OrganMemberCanStillCreate() public {
//         PartyOrgan[] memory organs = new PartyOrgan[](2);
//         address[] memory addrs = new address[](2);
//         organs[0] = chairmanOrgan;
//         addrs[0] = chairman;
//         organs[1] = testOrgan;
//         addrs[1] = member1;
//         _initOrgans(organs, addrs);

//         vm.prank(member1);
//         uint256 votingId = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);

//         assertEq(votingId, 1);
//         assertTrue(zarya.isVotingActive(votingId));
//     }

//     // ============ Category Voting Tests ============

//     function test_CreateCategoryVoting_Success() public {
//         PartyOrgan[] memory organs = new PartyOrgan[](1);
//         address[] memory addrs = new address[](1);
//         organs[0] = testOrgan;
//         addrs[0] = member1;
//         _initOrgans(organs, addrs);

//         vm.prank(member1);
//         uint256 votingId = zarya.createCategoryVoting(testOrgan, 1, 1, 100, "TestCategory", DEFAULT_DURATION);

//         assertEq(votingId, 1);
//         assertTrue(zarya.isVotingActive(votingId));
//     }

//     // ============ Decimals Voting Tests ============

//     function test_CreateDecimalsVoting_Success() public {
//         PartyOrgan[] memory organs = new PartyOrgan[](1);
//         address[] memory addrs = new address[](1);
//         organs[0] = testOrgan;
//         addrs[0] = member1;
//         _initOrgans(organs, addrs);

//         vm.prank(member1);
//         uint256 votingId = zarya.createDecimalsVoting(testOrgan, 1, 1, 2, DEFAULT_DURATION);

//         assertEq(votingId, 1);
//         assertTrue(zarya.isVotingActive(votingId));
//     }

//     // ============ Theme Voting Tests ============

//     function test_CreateThemeVoting_Success() public {
//         vm.prank(member1);
//         uint256 votingId = zarya.createThemeVoting(true, 1, "Economy", DEFAULT_DURATION);

//         assertEq(votingId, 1);
//         assertTrue(zarya.isVotingActive(votingId));
//     }

//     // ============ Statement Voting Tests ============

//     function test_CreateStatementVoting_Success() public {
//         vm.prank(member1);
//         uint256 votingId = zarya.createStatementVoting(true, 1, 1, "GDP Growth", DEFAULT_DURATION);

//         assertEq(votingId, 1);
//         assertTrue(zarya.isVotingActive(votingId));
//     }

//     // ============ Categorical Value Voting Tests ============

//     function test_CreateCategoricalValueVoting_Success() public {
//         PartyOrgan[] memory organs = new PartyOrgan[](1);
//         address[] memory addrs = new address[](1);
//         organs[0] = testOrgan;
//         addrs[0] = member1;
//         _initOrgans(organs, addrs);

//         vm.prank(member1);
//         uint256 votingId = zarya.createCategoricalValueVoting(testOrgan, 1, 1, 50, member1, DEFAULT_DURATION);

//         assertEq(votingId, 1);
//         assertTrue(zarya.isVotingActive(votingId));
//     }

//     // ============ Numerical Value Voting Tests ============

//     function test_CreateNumericalValueVoting_Success() public {
//         PartyOrgan[] memory organs = new PartyOrgan[](1);
//         address[] memory addrs = new address[](1);
//         organs[0] = testOrgan;
//         addrs[0] = member1;
//         _initOrgans(organs, addrs);

//         vm.prank(member1);
//         uint256 votingId = zarya.createNumericalValueVoting(testOrgan, 1, 1, 1500, member1, DEFAULT_DURATION);

//         assertEq(votingId, 1);
//         assertTrue(zarya.isVotingActive(votingId));
//     }

//     // ============ Vote Casting Tests ============

//     function test_CastVote_Success() public {
//         PartyOrgan[] memory organs = new PartyOrgan[](1);
//         address[] memory addrs = new address[](1);
//         organs[0] = testOrgan;
//         addrs[0] = member1;
//         _initOrgans(organs, addrs);

//         vm.prank(member1);
//         uint256 votingId = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);

//         vm.prank(member1);
//         zarya.castVote(votingId, true, testOrgan);

//         assertTrue(zarya.hasVoted(votingId, member1));

//         Votings.VoteResults memory results = zarya.getVotingResults(votingId);
//         assertEq(results.forVotes, 1);
//         assertEq(results.againstVotes, 0);
//         assertEq(results.totalVotes, 1);
//     }

//     function test_CastVote_RevertsForNonMember() public {
//         PartyOrgan[] memory organs = new PartyOrgan[](1);
//         address[] memory addrs = new address[](1);
//         organs[0] = testOrgan;
//         addrs[0] = member1;
//         _initOrgans(organs, addrs);

//         vm.prank(member1);
//         uint256 votingId = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);

//         vm.prank(nonMember);
//         vm.expectRevert(abi.encodeWithSelector(PartyOrgans.NotActiveMember.selector, testOrgan, nonMember));
//         zarya.castVote(votingId, true, testOrgan);
//     }

//     function test_CastVote_RevertsWhenVotingInactive() public {
//         PartyOrgan[] memory organs = new PartyOrgan[](1);
//         address[] memory addrs = new address[](1);
//         organs[0] = testOrgan;
//         addrs[0] = member1;
//         _initOrgans(organs, addrs);

//         vm.prank(member1);
//         uint256 votingId = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);

//         vm.warp(block.timestamp + DEFAULT_DURATION + 1);

//         vm.prank(member1);
//         vm.expectRevert(abi.encodeWithSelector(Votings.VotingNotActive.selector, votingId));
//         zarya.castVote(votingId, true, testOrgan);
//     }

//     function test_CastVote_RevertsOnDoubleVote() public {
//         PartyOrgan[] memory organs = new PartyOrgan[](1);
//         address[] memory addrs = new address[](1);
//         organs[0] = testOrgan;
//         addrs[0] = member1;
//         _initOrgans(organs, addrs);

//         vm.prank(member1);
//         uint256 votingId = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);

//         vm.prank(member1);
//         zarya.castVote(votingId, true, testOrgan);

//         vm.prank(member1);
//         vm.expectRevert(abi.encodeWithSelector(Votings.AlreadyVoted.selector, member1));
//         zarya.castVote(votingId, true, testOrgan);
//     }

//     function test_CastVote_MultipleMembers() public {
//         PartyOrgan[] memory organs = new PartyOrgan[](3);
//         address[] memory addrs = new address[](3);
//         organs[0] = testOrgan;
//         addrs[0] = member1;
//         organs[1] = testOrgan;
//         addrs[1] = member2;
//         organs[2] = testOrgan;
//         addrs[2] = member3;
//         _initOrgans(organs, addrs);

//         vm.prank(member1);
//         uint256 votingId = zarya.createMembershipVoting(testOrgan, nonMember, DEFAULT_DURATION);

//         // member1 votes for
//         vm.prank(member1);
//         zarya.castVote(votingId, true, testOrgan);

//         // member2 votes against
//         vm.prank(member2);
//         zarya.castVote(votingId, false, testOrgan);

//         // member3 votes for
//         vm.prank(member3);
//         zarya.castVote(votingId, true, testOrgan);

//         Votings.VoteResults memory results = zarya.getVotingResults(votingId);
//         assertEq(results.forVotes, 2);
//         assertEq(results.againstVotes, 1);
//         assertEq(results.totalVotes, 3);
//     }

//     // ============ Vote Execution Tests ============

//     function test_ExecuteVoting_RevertsWhenActive() public {
//         PartyOrgan[] memory organs = new PartyOrgan[](1);
//         address[] memory addrs = new address[](1);
//         organs[0] = testOrgan;
//         addrs[0] = member1;
//         _initOrgans(organs, addrs);

//         vm.prank(member1);
//         uint256 votingId = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);

//         vm.expectRevert(abi.encodeWithSelector(Votings.VotingStillActive.selector, votingId));
//         zarya.executeVoting(votingId, MINIMUM_QUORUM, MINIMUM_APPROVAL);
//     }

//     function test_ExecuteVoting_RevertsOnInsufficientQuorum() public {
//         PartyOrgan[] memory organs = new PartyOrgan[](1);
//         address[] memory addrs = new address[](1);
//         organs[0] = testOrgan;
//         addrs[0] = member1;
//         _initOrgans(organs, addrs);

//         vm.prank(member1);
//         uint256 votingId = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);

//         vm.prank(member1);
//         zarya.castVote(votingId, true, testOrgan);

//         vm.warp(block.timestamp + DEFAULT_DURATION + 1);

//         vm.expectRevert(abi.encodeWithSelector(Votings.InsufficientVotes.selector, 1, 0));
//         zarya.executeVoting(votingId, MINIMUM_QUORUM, MINIMUM_APPROVAL);
//     }

//     function test_ExecuteVoting_SuccessfulMembershipVoting() public {
//         PartyOrgan[] memory organs = new PartyOrgan[](2);
//         address[] memory addrs = new address[](2);
//         organs[0] = testOrgan;
//         addrs[0] = member1;
//         organs[1] = testOrgan;
//         addrs[1] = member2;
//         _initOrgans(organs, addrs);

//         vm.prank(member1);
//         uint256 votingId = zarya.createMembershipVoting(testOrgan, member3, DEFAULT_DURATION);

//         vm.prank(member1);
//         zarya.castVote(votingId, true, testOrgan);

//         vm.prank(member2);
//         zarya.castVote(votingId, true, testOrgan);

//         vm.warp(block.timestamp + DEFAULT_DURATION + 1);

//         bool success = zarya.executeVoting(votingId, MINIMUM_QUORUM, MINIMUM_APPROVAL);

//         assertTrue(success);
//         assertTrue(zarya.isVotingFinalized(votingId));
//     }

//     function test_ExecuteVoting_FailedDueToInsufficientApproval() public {
//         PartyOrgan[] memory organs = new PartyOrgan[](3);
//         address[] memory addrs = new address[](3);
//         organs[0] = testOrgan;
//         addrs[0] = member1;
//         organs[1] = testOrgan;
//         addrs[1] = member2;
//         organs[2] = testOrgan;
//         addrs[2] = member3;
//         _initOrgans(organs, addrs);

//         vm.prank(member1);
//         uint256 votingId = zarya.createMembershipVoting(testOrgan, nonMember, DEFAULT_DURATION);

//         vm.prank(member1);
//         zarya.castVote(votingId, true, testOrgan);

//         vm.prank(member2);
//         zarya.castVote(votingId, false, testOrgan);

//         vm.prank(member3);
//         zarya.castVote(votingId, false, testOrgan);

//         vm.warp(block.timestamp + DEFAULT_DURATION + 1);

//         bool success = zarya.executeVoting(votingId, MINIMUM_QUORUM, MINIMUM_APPROVAL);

//         assertFalse(success);
//         assertTrue(zarya.isVotingFinalized(votingId));
//     }

//     function test_ExecuteVoting_RevertsOnDoubleExecution() public {
//         PartyOrgan[] memory organs = new PartyOrgan[](2);
//         address[] memory addrs = new address[](2);
//         organs[0] = testOrgan;
//         addrs[0] = member1;
//         organs[1] = testOrgan;
//         addrs[1] = member2;
//         _initOrgans(organs, addrs);

//         vm.prank(member1);
//         uint256 votingId = zarya.createMembershipVoting(testOrgan, member3, DEFAULT_DURATION);

//         vm.prank(member1);
//         zarya.castVote(votingId, true, testOrgan);

//         vm.prank(member2);
//         zarya.castVote(votingId, true, testOrgan);

//         vm.warp(block.timestamp + DEFAULT_DURATION + 1);

//         zarya.executeVoting(votingId, MINIMUM_QUORUM, MINIMUM_APPROVAL);

//         // Try to execute again
//         vm.expectRevert(abi.encodeWithSelector(Votings.VotingAlreadyFinalized.selector, votingId));
//         zarya.executeVoting(votingId, MINIMUM_QUORUM, MINIMUM_APPROVAL);
//     }

//     // ============ Edge Cases and View Functions ============

//     function test_GetVotingResults_NonExistentVoting() public {
//         vm.expectRevert(abi.encodeWithSelector(Votings.VotingNotFound.selector, 999));
//         zarya.getVotingResults(999);
//     }

//     function test_HasVoted_ReturnsFalseForNonVoter() public {
//         PartyOrgan[] memory organs = new PartyOrgan[](1);
//         address[] memory addrs = new address[](1);
//         organs[0] = testOrgan;
//         addrs[0] = member1;
//         _initOrgans(organs, addrs);

//         vm.prank(member1);
//         uint256 votingId = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);

//         assertFalse(zarya.hasVoted(votingId, member2));
//     }

//     function test_IsVotingActive_ReturnsFalseAfterExpiry() public {
//         PartyOrgan[] memory organs = new PartyOrgan[](1);
//         address[] memory addrs = new address[](1);
//         organs[0] = testOrgan;
//         addrs[0] = member1;
//         _initOrgans(organs, addrs);

//         vm.prank(member1);
//         uint256 votingId = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);

//         assertTrue(zarya.isVotingActive(votingId));

//         vm.warp(block.timestamp + DEFAULT_DURATION + 1);

//         assertFalse(zarya.isVotingActive(votingId));
//     }

//     function test_MultipleVotingsInSequence() public {
//         PartyOrgan[] memory organs = new PartyOrgan[](1);
//         address[] memory addrs = new address[](1);
//         organs[0] = testOrgan;
//         addrs[0] = member1;
//         _initOrgans(organs, addrs);

//         vm.startPrank(member1);

//         uint256 votingId1 = zarya.createMembershipVoting(testOrgan, member2, DEFAULT_DURATION);
//         uint256 votingId2 = zarya.createCategoryVoting(testOrgan, 1, 1, 100, "TestCategory", DEFAULT_DURATION);
//         uint256 votingId3 = zarya.createDecimalsVoting(testOrgan, 1, 1, 2, DEFAULT_DURATION);

//         vm.stopPrank();

//         assertEq(votingId1, 1);
//         assertEq(votingId2, 2);
//         assertEq(votingId3, 3);
//         assertEq(zarya.nextVotingId(), 3);

//         assertTrue(zarya.isVotingActive(votingId1));
//         assertTrue(zarya.isVotingActive(votingId2));
//         assertTrue(zarya.isVotingActive(votingId3));
//     }
// }
