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
    mapping(address => mapping(PartyOrgan => bool)) private _chairmanUsedPrivilege;

    error OrgansAlreadyInitialized();
    error InvalidMemberAddress();
    error EmptyInitializationData();
    error ChairmanPrivilegeAlreadyUsed(address chairman, PartyOrgan organ);
    error CannotRemoveChairman(PartyOrgan organ, address member);

    /// @notice Снапшот одной записи из истории значений ячейки матрицы.
    struct CellCheckpoint {
        uint32 timestamp;
        address author;
        uint64 value;
    }

    /// @notice Пограничный результат запроса истории значений ячейки
    /// матрицы.
    struct CellHistory {
        uint32[] timestamps;
        address[] authors;
        uint64[] values;
    }

    /// @notice Общая информация о ячейке категорийной матрицы.
    struct CategoricalCellInfoResult {
        PartyOrgan organ;
        uint64[] allowedCategories;
        uint256 sampleLength;
    }

    /// @notice Общая информация о ячейке числовой матрицы.
    struct NumericalCellInfoResult {
        PartyOrgan organ;
        uint8 decimals;
        uint256 sampleLength;
    }

    modifier onlyMember(PartyOrgan organ) {
        _onlyMember(organ);
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

    function _onlyMemberOrChairman(PartyOrgan organ) internal {
        EnumerableSet.AddressSet storage members = _partyMembersRegistry.membersByOrgan[organ];

        if (!members.contains(msg.sender)) {
            PartyOrgan chairperson = PartyOrgans.from(PartyOrgans.PartyOrganType.Chairperson, Regions.Region.FEDERAL, 0);
            EnumerableSet.AddressSet storage chairmanMembers = _partyMembersRegistry.membersByOrgan[chairperson];

            if (!chairmanMembers.contains(msg.sender)) {
                revert PartyOrgans.NotActiveMember(organ, msg.sender);
            }

            mapping(PartyOrgan => bool) storage privileges = _chairmanUsedPrivilege[msg.sender];
            if (privileges[organ]) {
                revert ChairmanPrivilegeAlreadyUsed(msg.sender, organ);
            }
            privileges[organ] = true;
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

    function _unpackCheckpoint(Matricies.DecodedCheckpoint memory checkpoint)
        internal
        pure
        returns (uint32 timestamp, address author, uint64 value)
    {
        return (checkpoint.timestamp, checkpoint.author, checkpoint.value);
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

    /// @notice Initialize organs with their members - can only be called once in the contract's lifetime
    /// @param organs Array of party organs to initialize
    /// @param members Array of member addresses corresponding to each organ
    /// @dev Arrays must be the same length. Each member will be added to the corresponding organ.
    function initializeOrgans(PartyOrgan[] calldata organs, address[] calldata members) external {
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

    // Voting participation functions
    function castVote(
        uint256 votingId,
        bool support,
        PartyOrgan organ
    )
        external
        votingExists(votingId)
        onlyMember(organ)
    {
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

    // View functions
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

    // ============ Matrix View Functions ============

    // Theme and Statement Queries
    function getTheme(bool isCategorical, uint256 x) external view returns (string memory) {
        return _matricies.getTheme(isCategorical, x);
    }

    function getStatement(bool isCategorical, uint256 y) external view returns (string memory) {
        return _matricies.getStatement(isCategorical, y);
    }

    // Organ Queries
    function getCategoricalCellOrgan(uint256 x, uint256 y) external view returns (PartyOrgan) {
        return _matricies.getCategoricalCellOrgan(x, y);
    }

    function getNumericalCellOrgan(uint256 x, uint256 y) external view returns (PartyOrgan) {
        return _matricies.getNumericalCellOrgan(x, y);
    }

    // Category Queries
    function getAllowedCategories(uint256 x, uint256 y) external view returns (uint64[] memory) {
        return _matricies.getAllowedCategories(x, y);
    }

    function getCategoryName(uint256 x, uint256 y, uint64 category) external view returns (string memory) {
        return _matricies.getCategoryName(x, y, category);
    }

    function isCategoryAllowed(uint256 x, uint256 y, uint64 category) external view returns (bool) {
        return _matricies.isCategoryAllowed(x, y, category);
    }

    // Cell Info Aggregates
    function getCategoricalCellInfo(
        uint256 x,
        uint256 y
    )
        external
        view
        returns (CategoricalCellInfoResult memory result)
    {
        (result.organ, result.allowedCategories, result.sampleLength) = _matricies.getCategoricalCellInfo(x, y);
    }

    function getNumericalCellInfo(uint256 x, uint256 y) external view returns (NumericalCellInfoResult memory result) {
        (result.organ, result.decimals, result.sampleLength) = _matricies.getNumericalCellInfo(x, y);
    }

    // Sample Length Queries
    function getCategoricalSampleLength(uint256 x, uint256 y) external view returns (uint256) {
        return _matricies.getCategoricalSampleLength(x, y);
    }

    function getNumericalSampleLength(uint256 x, uint256 y) external view returns (uint256) {
        return _matricies.getNumericalSampleLength(x, y);
    }

    // Latest Value Queries
    function getCategoricalLatestValue(uint256 x, uint256 y) external view returns (CellCheckpoint memory result) {
        (result.timestamp, result.author, result.value) = _unpackCheckpoint(_matricies.getLatestCategoricalValue(x, y));
    }

    function getNumericalLatestValue(uint256 x, uint256 y) external view returns (CellCheckpoint memory result) {
        (result.timestamp, result.author, result.value) = _unpackCheckpoint(_matricies.getLatestNumericalValue(x, y));
    }

    // Indexed Value Access
    function getCategoricalValueAt(
        uint256 x,
        uint256 y,
        uint256 index
    )
        external
        view
        returns (CellCheckpoint memory result)
    {
        (result.timestamp, result.author, result.value) =
            _unpackCheckpoint(_matricies.getCategoricalValueAt(x, y, index));
    }

    function getNumericalValueAt(
        uint256 x,
        uint256 y,
        uint256 index
    )
        external
        view
        returns (CellCheckpoint memory result)
    {
        (result.timestamp, result.author, result.value) = _unpackCheckpoint(_matricies.getNumericalValueAt(x, y, index));
    }

    // Timestamp Lookup
    function getCategoricalValueAtTimestamp(
        uint256 x,
        uint256 y,
        uint32 timestamp
    )
        external
        view
        returns (CellCheckpoint memory result)
    {
        (result.timestamp, result.author, result.value) =
            _unpackCheckpoint(_matricies.getCategoricalValueAtTimestamp(x, y, timestamp));
    }

    function getNumericalValueAtTimestamp(
        uint256 x,
        uint256 y,
        uint32 timestamp
    )
        external
        view
        returns (CellCheckpoint memory result)
    {
        (result.timestamp, result.author, result.value) =
            _unpackCheckpoint(_matricies.getNumericalValueAtTimestamp(x, y, timestamp));
    }

    // Paginated History Queries
    function getCategoricalHistory(
        uint256 x,
        uint256 y,
        uint256 offset,
        uint256 limit
    )
        external
        view
        returns (CellHistory memory result)
    {
        (result.timestamps, result.authors, result.values) = _matricies.getCategoricalHistory(x, y, offset, limit);
    }

    function getNumericalHistory(
        uint256 x,
        uint256 y,
        uint256 offset,
        uint256 limit
    )
        external
        view
        returns (CellHistory memory result)
    {
        (result.timestamps, result.authors, result.values) = _matricies.getNumericalHistory(x, y, offset, limit);
    }
}
