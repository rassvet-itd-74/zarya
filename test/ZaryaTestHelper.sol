// SPDX-License-Identifier: CC0 1.0 Universal
pragma solidity ^0.8.28;

import {Zarya} from "../src/Zarya.sol";
import {PartyOrgan} from "../src/libraries/PartyOrgans.sol";
import {Votings} from "../src/libraries/Votings.sol";
import {EnumerableSet} from "@openzeppelin-contracts-5.4.0-rc.1/utils/structs/EnumerableSet.sol";

/**
 * @dev Test helper contract that exposes internal functionality for testing
 */
contract ZaryaTestHelper is Zarya {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Votings for Votings.Voting;

    /// @dev Voting does not exist
    error VotingDoesNotExist();
    /// @dev Array length mismatch
    error ArrayLengthMismatch();

    /**
     * @dev Add a member to an organ directly (for testing purposes only)
     */
    function addMemberForTesting(address member, PartyOrgan organ) external {
        _partyMembersRegistry.membersByOrgan[organ].add(member);
    }

    /**
     * @dev Remove a member from an organ directly (for testing purposes only)
     */
    function removeMemberForTesting(address member, PartyOrgan organ) external {
        _partyMembersRegistry.membersByOrgan[organ].remove(member);
    }

    /**
     * @dev Check if an address is a member of an organ (for testing purposes only)
     */
    function isMemberForTesting(address member, PartyOrgan organ) external view returns (bool) {
        return _partyMembersRegistry.membersByOrgan[organ].contains(member);
    }

    /**
     * @dev Execute a voting by directly setting its end time to the past (for testing purposes only)
     * This bypasses the time wait requirement for votings
     */
    function executeVotingForTesting(uint256 votingId, uint256 minimumQuorum, uint256 minimumApproval) external {
        // Get the voting to check it exists
        Votings.Voting storage voting = _votings[votingId];
        if (voting.startTime == 0) revert VotingDoesNotExist();

        // Set the end time to the past so execution doesn't fail on time check
        voting.endTime = block.timestamp - 1;

        // Execute the voting internally
        voting.executeVoting(minimumQuorum, minimumApproval, _matricies, _partyMembersRegistry);
    }

    /**
     * @dev Cast a vote on behalf of any address (for testing purposes only)
     * This bypasses the onlyMember modifier
     */
    function castVoteForTesting(uint256 votingId, bool support, address voter) external {
        Votings.Voting storage voting = _votings[votingId];
        if (voting.startTime == 0) revert VotingDoesNotExist();
        voting.castVote(support, voter);
    }

    /**
     * @dev Batch cast votes on behalf of multiple addresses (for testing purposes only)
     * This bypasses the onlyMember modifier
     */
    function batchCastVotesForTesting(
        uint256[] calldata votingIds,
        bool[] calldata votes,
        address[] calldata voters
    ) external {
        if (votingIds.length != votes.length || votingIds.length != voters.length) revert ArrayLengthMismatch();

        for (uint256 i = 0; i < votingIds.length; i++) {
            Votings.Voting storage voting = _votings[votingIds[i]];
            if (voting.startTime == 0) revert VotingDoesNotExist();
            voting.castVote(votes[i], voters[i]);
        }
    }

    /**
     * @dev Batch create theme votings (for testing purposes only)
     * This bypasses any access control modifiers
     */
    function batchCreateThemeVotings(
        bool[] calldata isCategoricals,
        uint256[] calldata xs,
        string[] calldata themes,
        uint256[] calldata durations
    ) external returns (uint256[] memory votingIds) {
        if (isCategoricals.length != xs.length || xs.length != themes.length || themes.length != durations.length) {
            revert ArrayLengthMismatch();
        }

        votingIds = new uint256[](isCategoricals.length);
        for (uint256 i = 0; i < isCategoricals.length; i++) {
            votingIds[i] = _getNextVotingId();
            _votings[votingIds[i]].createThemeVoting(votingIds[i], msg.sender, durations[i], isCategoricals[i], xs[i], themes[i]);
        }
    }

    /**
     * @dev Batch create statement votings (for testing purposes only)
     * This bypasses any access control modifiers
     */
    function batchCreateStatementVotings(
        bool[] calldata isCategoricals,
        uint256[] calldata xs,
        uint256[] calldata ys,
        string[] calldata statements,
        uint256[] calldata durations
    ) external returns (uint256[] memory votingIds) {
        if (isCategoricals.length != xs.length || xs.length != ys.length || ys.length != statements.length || statements.length != durations.length) {
            revert ArrayLengthMismatch();
        }

        votingIds = new uint256[](isCategoricals.length);
        for (uint256 i = 0; i < isCategoricals.length; i++) {
            votingIds[i] = _getNextVotingId();
            _votings[votingIds[i]].createStatementVoting(votingIds[i], msg.sender, durations[i], isCategoricals[i], xs[i], ys[i], statements[i]);
        }
    }

    /**
     * @dev Batch create category votings (for testing purposes only)
     * This bypasses the onlyMember modifier
     */
    function batchCreateCategoryVotings(
        PartyOrgan[] calldata organs,
        uint256[] calldata xs,
        uint256[] calldata ys,
        uint64[] calldata categories,
        string[] calldata categoryNames,
        uint256[] calldata durations
    ) external returns (uint256[] memory votingIds) {
        uint256 len = organs.length;
        if (len != xs.length || len != ys.length || len != categories.length || len != categoryNames.length || len != durations.length) {
            revert ArrayLengthMismatch();
        }

        votingIds = new uint256[](len);
        for (uint256 i = 0; i < len;) {
            votingIds[i] = _createCategoryVotingInternal(organs[i], xs[i], ys[i], categories[i], categoryNames[i], durations[i]);
            unchecked { ++i; }
        }
    }

    function _createCategoryVotingInternal(
        PartyOrgan organ,
        uint256 x,
        uint256 y,
        uint64 category,
        string calldata categoryName,
        uint256 duration
    ) private returns (uint256 vId) {
        vId = _getNextVotingId();
        _votings[vId].createCategoryVoting(vId, msg.sender, duration, organ, x, y, category, categoryName);
    }

    /**
     * @dev Batch create decimals votings (for testing purposes only)
     * This bypasses the onlyMember modifier
     */
    function batchCreateDecimalsVotings(
        PartyOrgan[] calldata organs,
        uint256[] calldata xs,
        uint256[] calldata ys,
        uint8[] calldata decimals,
        uint256[] calldata durations
    ) external returns (uint256[] memory votingIds) {
        if (organs.length != xs.length || xs.length != ys.length || ys.length != decimals.length || decimals.length != durations.length) {
            revert ArrayLengthMismatch();
        }

        votingIds = new uint256[](organs.length);
        for (uint256 i = 0; i < organs.length; i++) {
            votingIds[i] = _getNextVotingId();
            _votings[votingIds[i]].createDecimalsVoting(votingIds[i], msg.sender, durations[i], organs[i], xs[i], ys[i], decimals[i]);
        }
    }

    /**
     * @dev Batch create categorical value votings (for testing purposes only)
     * This bypasses the onlyMember modifier
     */
    function batchCreateCategoricalValueVotings(
        PartyOrgan[] calldata organs,
        uint256[] calldata xs,
        uint256[] calldata ys,
        uint64[] calldata values,
        address[] calldata valueAuthors,
        uint256[] calldata durations
    ) external returns (uint256[] memory votingIds) {
        uint256 len = organs.length;
        if (len != xs.length || len != ys.length || len != values.length || len != valueAuthors.length || len != durations.length) {
            revert ArrayLengthMismatch();
        }

        votingIds = new uint256[](len);
        for (uint256 i = 0; i < len;) {
            votingIds[i] = _createCategoricalValueVotingInternal(organs[i], xs[i], ys[i], values[i], valueAuthors[i], durations[i]);
            unchecked { ++i; }
        }
    }

    function _createCategoricalValueVotingInternal(
        PartyOrgan organ,
        uint256 x,
        uint256 y,
        uint64 value,
        address valueAuthor,
        uint256 duration
    ) private returns (uint256 vId) {
        vId = _getNextVotingId();
        _votings[vId].createCategoricalValueVoting(vId, msg.sender, duration, organ, x, y, value, valueAuthor);
    }

    /**
     * @dev Batch create numerical value votings (for testing purposes only)
     * This bypasses the onlyMember modifier
     */
    function batchCreateNumericalValueVotings(
        PartyOrgan[] calldata organs,
        uint256[] calldata xs,
        uint256[] calldata ys,
        uint64[] calldata values,
        address[] calldata valueAuthors,
        uint256[] calldata durations
    ) external returns (uint256[] memory votingIds) {
        uint256 len = organs.length;
        if (len != xs.length || len != ys.length || len != values.length || len != valueAuthors.length || len != durations.length) {
            revert ArrayLengthMismatch();
        }

        votingIds = new uint256[](len);
        for (uint256 i = 0; i < len;) {
            votingIds[i] = _createNumericalValueVotingInternal(organs[i], xs[i], ys[i], values[i], valueAuthors[i], durations[i]);
            unchecked { ++i; }
        }
    }

    function _createNumericalValueVotingInternal(
        PartyOrgan organ,
        uint256 x,
        uint256 y,
        uint64 value,
        address valueAuthor,
        uint256 duration
    ) private returns (uint256 vId) {
        vId = _getNextVotingId();
        _votings[vId].createNumericalValueVoting(vId, msg.sender, duration, organ, x, y, value, valueAuthor);
    }

    /**
     * @dev Batch execute multiple votings (for testing purposes only)
     */
    function batchExecuteVotingsForTesting(
        uint256[] calldata votingIds,
        uint256[] calldata minimumQuorums,
        uint256[] calldata minimumApprovals
    ) external {
        if (votingIds.length != minimumQuorums.length || votingIds.length != minimumApprovals.length) revert ArrayLengthMismatch();

        for (uint256 i = 0; i < votingIds.length; i++) {
            Votings.Voting storage voting = _votings[votingIds[i]];
            if (voting.startTime == 0) revert VotingDoesNotExist();
            voting.endTime = block.timestamp - 1;
            voting.executeVoting(minimumQuorums[i], minimumApprovals[i], _matricies, _partyMembersRegistry);
        }
    }
}
