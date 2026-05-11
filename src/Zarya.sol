// SPDX-License-Identifier: CC0 1.0 Universal
pragma solidity ^0.8.28;

import {EnumerableSet} from "@openzeppelin-contracts-5.4.0-rc.1/utils/structs/EnumerableSet.sol";

import {Regions} from "./libraries/Regions.sol";
import {PartyOrgans, PartyOrgan} from "./libraries/PartyOrgans.sol";
import {Matricies} from "./libraries/Matricies.sol";
import {Votings} from "./libraries/Votings.sol";

contract Zarya {
    using Regions for Regions.Region;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Votings for Votings.Voting;
    using Matricies for Matricies.PairOfMatricies;

    uint256 public nextVotingId;
    bool private _organsInitialized;

    mapping(uint256 => Votings.Voting) internal _votings;
    PartyOrgans.MembersRegistry internal _partyMembersRegistry;
    Matricies.PairOfMatricies internal _matricies;

    error OrgansAlreadyInitialized();
    error InvalidMemberAddress();
    error EmptyInitializationData();
    error CannotRemoveChairman(PartyOrgan organ, address member);
    error NotChairman(address caller);

    constructor(address _chairman) {
        if (_chairman == address(0)) revert InvalidMemberAddress();
        PartyOrgan chairperson = PartyOrgans.from(PartyOrgans.PartyOrganType.Chairperson, Regions.Region.FEDERAL, 0);
        _partyMembersRegistry.membersByOrgan[chairperson].add(_chairman);
    }

    modifier onlyMember(PartyOrgan organ) {
        _onlyMember(organ);
        _;
    }

    modifier onlyChairman() {
        if (!_isChairman(msg.sender)) {
            revert NotChairman(msg.sender);
        }
        _;
    }

    modifier votingExists(uint256 votingId) {
        _votingExists(votingId);
        _;
    }

    function _onlyMember(PartyOrgan organ) internal view {
        if (!_partyMembersRegistry.membersByOrgan[organ].contains(msg.sender)) {
            revert PartyOrgans.NotActiveMember(organ, msg.sender);
        }
    }

    function _votingExists(uint256 votingId) internal view {
        if (votingId > nextVotingId || votingId == 0) {
            revert Votings.VotingNotFound(votingId);
        }
    }

    function _onlyMemberOrChairman(PartyOrgan organ) internal view {
        EnumerableSet.AddressSet storage members = _partyMembersRegistry.membersByOrgan[organ];

        if (!members.contains(msg.sender)) {
            PartyOrgan chairperson = PartyOrgans.from(PartyOrgans.PartyOrganType.Chairperson, Regions.Region.FEDERAL, 0);
            EnumerableSet.AddressSet storage chairmanMembers = _partyMembersRegistry.membersByOrgan[chairperson];

            if (!chairmanMembers.contains(msg.sender)) {
                revert PartyOrgans.NotActiveMember(organ, msg.sender);
            }
        }
    }

    function _getNextVotingId() internal returns (uint256) {
        unchecked {
            return ++nextVotingId;
        }
    }

    function _isChairman(address member) internal view returns (bool) {
        PartyOrgan chairperson = PartyOrgans.from(PartyOrgans.PartyOrganType.Chairperson, Regions.Region.FEDERAL, 0);
        return _partyMembersRegistry.membersByOrgan[chairperson].contains(member);
    }

    function _createValueVoting(
        bool isCategorical,
        PartyOrgan organ,
        uint256 x,
        uint256 y,
        uint64 value,
        address valueAuthor,
        uint256 duration
    )
        internal
        returns (uint256 votingId)
    {
        votingId = _getNextVotingId();
        if (isCategorical) {
            _votings[votingId].createCategoricalValueVoting(
                votingId, msg.sender, duration, organ, x, y, value, valueAuthor
            );
        } else {
            _votings[votingId].createNumericalValueVoting(
                votingId, msg.sender, duration, organ, x, y, value, valueAuthor
            );
        }
    }

    // ============ Initialization ============

    function initializeOrgans(PartyOrgan[] calldata organs, address[] calldata members) external onlyChairman {
        if (_organsInitialized) {
            revert OrgansAlreadyInitialized();
        }
        if (organs.length == 0 || organs.length != members.length) {
            revert EmptyInitializationData();
        }

        _organsInitialized = true;

        for (uint256 i = 0; i < organs.length; i++) {
            if (members[i] == address(0)) {
                revert InvalidMemberAddress();
            }
            _partyMembersRegistry.membersByOrgan[organs[i]].add(members[i]);
        }
    }

    // ============ Membership Votings ============

    function createMembershipVoting(
        PartyOrgan organ,
        address member,
        uint256 duration
    )
        external
        returns (uint256 votingId)
    {
        _onlyMemberOrChairman(organ);
        votingId = _getNextVotingId();
        _votings[votingId].createMembershipVoting(votingId, msg.sender, duration, organ, member);
    }

    function createMembershipRevocationVoting(
        PartyOrgan organ,
        address member,
        uint256 duration
    )
        external
        returns (uint256 votingId)
    {
        _onlyMemberOrChairman(organ);

        if (_isChairman(member)) {
            revert CannotRemoveChairman(organ, member);
        }

        votingId = _getNextVotingId();
        _votings[votingId].createMembershipRevocationVoting(votingId, msg.sender, duration, organ, member);
    }

    // ============ Matrix Configuration Votings ============

    function createCategoryVoting(
        PartyOrgan organ,
        uint256 x,
        uint256 y,
        uint64 category,
        string calldata categoryName,
        uint256 duration
    )
        external
        onlyMember(organ)
        returns (uint256 votingId)
    {
        votingId = _getNextVotingId();
        _votings[votingId].createCategoryVoting(votingId, msg.sender, duration, organ, x, y, category, categoryName);
    }

    function createDecimalsVoting(
        PartyOrgan organ,
        uint256 x,
        uint256 y,
        uint8 decimals,
        uint256 duration
    )
        external
        onlyMember(organ)
        returns (uint256 votingId)
    {
        votingId = _getNextVotingId();
        _votings[votingId].createDecimalsVoting(votingId, msg.sender, duration, organ, x, y, decimals);
    }

    // ============ Theme, Statement and Value Votings ============

    function createThemeVoting(
        bool isCategorical,
        uint256 x,
        string calldata theme,
        uint256 duration
    )
        external
        returns (uint256 votingId)
    {
        votingId = _getNextVotingId();
        _votings[votingId].createThemeVoting(votingId, msg.sender, duration, isCategorical, x, theme);
    }

    function createStatementVoting(
        bool isCategorical,
        uint256 x,
        uint256 y,
        string calldata statement,
        uint256 duration
    )
        external
        returns (uint256 votingId)
    {
        votingId = _getNextVotingId();
        _votings[votingId].createStatementVoting(votingId, msg.sender, duration, isCategorical, x, y, statement);
    }

    function createCategoricalValueVoting(
        PartyOrgan organ,
        uint256 x,
        uint256 y,
        uint64 value,
        address valueAuthor,
        uint256 duration
    )
        external
        onlyMember(organ)
        returns (uint256 votingId)
    {
        return _createValueVoting(true, organ, x, y, value, valueAuthor, duration);
    }

    function createNumericalValueVoting(
        PartyOrgan organ,
        uint256 x,
        uint256 y,
        uint64 value,
        address valueAuthor,
        uint256 duration
    )
        external
        onlyMember(organ)
        returns (uint256 votingId)
    {
        return _createValueVoting(false, organ, x, y, value, valueAuthor, duration);
    }

    // ============ Voting Participation ============

    function castVote(uint256 votingId, bool support, PartyOrgan organ) external votingExists(votingId) {
        _onlyMemberOrChairman(organ);
        _votings[votingId].castVote(support, msg.sender);
    }

    function executeVoting(
        uint256 votingId,
        uint256 minimumQuorum,
        uint256 minimumApprovalPercentage
    )
        external
        votingExists(votingId)
        returns (bool success)
    {
        return
            _votings[votingId].executeVoting(
                minimumQuorum, minimumApprovalPercentage, _matricies, _partyMembersRegistry
            );
    }

    // ============ Voting Views ============

    function getVotingResults(uint256 votingId)
        external
        view
        votingExists(votingId)
        returns (Votings.VoteResults memory)
    {
        return _votings[votingId].getVoteResults();
    }

    function hasVoted(uint256 votingId, address member) external view votingExists(votingId) returns (bool) {
        return _votings[votingId].hasPartyMemberVoted(member);
    }

    function isVotingActive(uint256 votingId) external view votingExists(votingId) returns (bool) {
        return _votings[votingId].isActive();
    }

    function isVotingFinalized(uint256 votingId) external view votingExists(votingId) returns (bool) {
        return _votings[votingId].isFinalized();
    }

    // ============ Party Organ Helper Functions ============

    function getPartyOrgan(
        PartyOrgans.PartyOrganType organType,
        Regions.Region region,
        uint256 number
    )
        external
        pure
        returns (PartyOrgan)
    {
        return PartyOrgans.from(organType, region, number);
    }

    function getPartyOrganIdentifier(
        PartyOrgans.PartyOrganType organType,
        Regions.Region region,
        uint256 number
    )
        external
        pure
        returns (string memory)
    {
        return PartyOrgans.getPartyOrganIdentifier(organType, region, number);
    }

    function isMember(PartyOrgan organ, address member) external view returns (bool) {
        return _partyMembersRegistry.membersByOrgan[organ].contains(member);
    }

    function transferChairmanship(address newChairman) external onlyChairman {
        if (newChairman == address(0)) {
            revert InvalidMemberAddress();
        }
        PartyOrgan chairperson = PartyOrgans.from(PartyOrgans.PartyOrganType.Chairperson, Regions.Region.FEDERAL, 0);
        _partyMembersRegistry.membersByOrgan[chairperson].remove(msg.sender);
        _partyMembersRegistry.membersByOrgan[chairperson].add(newChairman);
    }

    // ============ Matrix Views ============

    function getTheme(bool isCategorical, uint256 x) external view returns (string memory) {
        return _matricies.getTheme(isCategorical, x);
    }

    function getStatement(bool isCategorical, uint256 y) external view returns (string memory) {
        return _matricies.getStatement(isCategorical, y);
    }

    function getCategoricalCellOrgan(uint256 x, uint256 y) external view returns (PartyOrgan) {
        return _matricies.getCategoricalCellOrgan(x, y);
    }

    function getNumericalCellOrgan(uint256 x, uint256 y) external view returns (PartyOrgan) {
        return _matricies.getNumericalCellOrgan(x, y);
    }

    function getAllowedCategories(uint256 x, uint256 y) external view returns (uint64[] memory) {
        return _matricies.getAllowedCategories(x, y);
    }

    function getCategoryName(uint256 x, uint256 y, uint64 category) external view returns (string memory) {
        return _matricies.getCategoryName(x, y, category);
    }

    function isCategoryAllowed(uint256 x, uint256 y, uint64 category) external view returns (bool) {
        return _matricies.isCategoryAllowed(x, y, category);
    }

    function getCategoricalCellInfo(
        uint256 x,
        uint256 y
    )
        external
        view
        returns (PartyOrgan organ, uint64[] memory allowedCategories, uint256 sampleLength)
    {
        return _matricies.getCategoricalCellInfo(x, y);
    }

    function getNumericalCellInfo(
        uint256 x,
        uint256 y
    )
        external
        view
        returns (PartyOrgan organ, uint8 decimals, uint256 sampleLength)
    {
        return _matricies.getNumericalCellInfo(x, y);
    }

    function getCategoricalSampleLength(uint256 x, uint256 y) external view returns (uint256) {
        return _matricies.getCategoricalSampleLength(x, y);
    }

    function getNumericalSampleLength(uint256 x, uint256 y) external view returns (uint256) {
        return _matricies.getNumericalSampleLength(x, y);
    }

    function getCategoricalLatestValue(uint256 x, uint256 y)
        external
        view
        returns (Matricies.DecodedCheckpoint memory)
    {
        return _matricies.getLatestCategoricalValue(x, y);
    }

    function getNumericalLatestValue(uint256 x, uint256 y) external view returns (Matricies.DecodedCheckpoint memory) {
        return _matricies.getLatestNumericalValue(x, y);
    }

    function getCategoricalValueAt(
        uint256 x,
        uint256 y,
        uint256 index
    )
        external
        view
        returns (Matricies.DecodedCheckpoint memory)
    {
        return _matricies.getCategoricalValueAt(x, y, index);
    }

    function getNumericalValueAt(
        uint256 x,
        uint256 y,
        uint256 index
    )
        external
        view
        returns (Matricies.DecodedCheckpoint memory)
    {
        return _matricies.getNumericalValueAt(x, y, index);
    }

    function getCategoricalValueAtTimestamp(
        uint256 x,
        uint256 y,
        uint32 timestamp
    )
        external
        view
        returns (Matricies.DecodedCheckpoint memory)
    {
        return _matricies.getCategoricalValueAtTimestamp(x, y, timestamp);
    }

    function getNumericalValueAtTimestamp(
        uint256 x,
        uint256 y,
        uint32 timestamp
    )
        external
        view
        returns (Matricies.DecodedCheckpoint memory)
    {
        return _matricies.getNumericalValueAtTimestamp(x, y, timestamp);
    }

    function getCategoricalHistory(
        uint256 x,
        uint256 y,
        uint256 offset,
        uint256 limit
    )
        external
        view
        returns (uint32[] memory timestamps, address[] memory authors, uint64[] memory values)
    {
        return _matricies.getCategoricalHistory(x, y, offset, limit);
    }

    function getNumericalHistory(
        uint256 x,
        uint256 y,
        uint256 offset,
        uint256 limit
    )
        external
        view
        returns (uint32[] memory timestamps, address[] memory authors, uint64[] memory values)
    {
        return _matricies.getNumericalHistory(x, y, offset, limit);
    }
}
