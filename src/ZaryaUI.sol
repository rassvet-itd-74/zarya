// SPDX-License-Identifier: CC0 1.0 Universal
pragma solidity ^0.8.28;

import {Zarya} from "./Zarya.sol";
import {PartyOrgans, PartyOrgan} from "./libraries/PartyOrgans.sol";
import {Regions} from "./libraries/Regions.sol";
import {Votings} from "./libraries/Votings.sol";
import {Matricies} from "./libraries/Matricies.sol";
import {EnumerableSet} from "@openzeppelin-contracts-5.4.0-rc.1/utils/structs/EnumerableSet.sol";

/// @title ZaryaUI
/// @notice Scaffold ETH 2 wrapper: accepts string organ IDs instead of bytes32.
contract ZaryaUI is Zarya {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Votings for Votings.Voting;
    using Matricies for Matricies.PairOfMatricies;

    struct VotingPage {
        uint256[] ids;
        uint256 totalCount;
    }

    struct VotingInfo {
        uint256 votingId;
        address proposedBy;
        uint256 startTime;
        uint256 endTime;
        bool active;
        bool finalized;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVotesCast;
        string proposalType;
        address subjectAddress;
        bytes32 organRaw;
        uint256 columnIndex;
        uint256 rowIndex;
        bool isCategorical;
        string label;
        uint64 categoryId;
        string categoryLabel;
        uint8 decimals;
        uint64 proposedValue;
    }

    struct CategoricalCellDetails {
        uint64[] allowedCategories;
        uint256 sampleLength;
        string organId;
    }

    struct NumericalCellDetails {
        uint8 decimals;
        uint256 sampleLength;
        string organId;
    }

    struct CategoricalCellInit {
        uint256 x;
        uint256 y;
        string organId;
        uint64[] categoryIds;
        string[] categoryLabels;
    }

    function organIdentifier(
        PartyOrgans.PartyOrganType organType,
        Regions.Region region,
        uint256 localNumber
    )
        external
        pure
        returns (string memory)
    {
        return PartyOrgans.getPartyOrganIdentifier(organType, region, localNumber);
    }

    function checkMembership(address member, string calldata organId) external view returns (bool) {
        return _partyMembersRegistry.membersByOrgan[_organFromId(organId)].contains(member);
    }

    function amIChairman() external view returns (bool) {
        return _isChairman(msg.sender);
    }

    function initializeReadable(
        string[] calldata organIds,
        address[] calldata members,
        string[] calldata categoricalThemes,
        string[] calldata categoricalStatements,
        string[] calldata numericalThemes,
        string[] calldata numericalStatements,
        CategoricalCellInit[] calldata categoricalCells
    )
        external
    {
        uint256 len = organIds.length;
        PartyOrgan[] memory organs = new PartyOrgan[](len);
        for (uint256 i; i < len;) {
            organs[i] = _organFromId(organIds[i]);
            unchecked {
                ++i;
            }
        }
        this.initializeOrgans(organs, members);
        for (uint256 i; i < categoricalThemes.length;) {
            _matricies.setTheme(true, i, categoricalThemes[i]);
            unchecked {
                ++i;
            }
        }
        for (uint256 i; i < numericalThemes.length;) {
            _matricies.setTheme(false, i, numericalThemes[i]);
            unchecked {
                ++i;
            }
        }
        for (uint256 i; i < categoricalStatements.length;) {
            _matricies.setStatement(true, 0, i, categoricalStatements[i]);
            unchecked {
                ++i;
            }
        }
        for (uint256 i; i < numericalStatements.length;) {
            _matricies.setStatement(false, 0, i, numericalStatements[i]);
            unchecked {
                ++i;
            }
        }
        for (uint256 i; i < categoricalCells.length;) {
            CategoricalCellInit calldata cell = categoricalCells[i];
            PartyOrgan organ = _organFromId(cell.organId);
            for (uint256 j; j < cell.categoryIds.length;) {
                _matricies.addCategory(organ, cell.x, cell.y, cell.categoryIds[j], cell.categoryLabels[j]);
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    function proposeMembership(
        string calldata organId,
        address candidateAddress,
        uint256 durationInSeconds
    )
        external
        returns (uint256 votingId)
    {
        PartyOrgan organ = _organFromId(organId);
        _onlyMemberOrChairman(organ);
        votingId = _getNextVotingId();
        _votings[votingId].createMembershipVoting(votingId, msg.sender, durationInSeconds, organ, candidateAddress);
    }

    function proposeMembershipRevocation(
        string calldata organId,
        address memberToRemove,
        uint256 durationInSeconds
    )
        external
        returns (uint256 votingId)
    {
        PartyOrgan organ = _organFromId(organId);
        _onlyMemberOrChairman(organ);
        if (_isChairman(memberToRemove)) revert CannotRemoveChairman(organ, memberToRemove);
        votingId = _getNextVotingId();
        _votings[votingId].createMembershipRevocationVoting(
            votingId, msg.sender, durationInSeconds, organ, memberToRemove
        );
    }

    function proposeCategory(
        string calldata organId,
        uint256 columnIndex,
        uint256 rowIndex,
        uint64 categoryId,
        string calldata categoryLabel,
        uint256 durationInSeconds
    )
        external
        returns (uint256 votingId)
    {
        PartyOrgan organ = _organFromId(organId);
        _onlyMember(organ);
        votingId = _getNextVotingId();
        _votings[votingId].createCategoryVoting(
            votingId, msg.sender, durationInSeconds, organ, columnIndex, rowIndex, categoryId, categoryLabel
        );
    }

    function proposeDecimals(
        string calldata organId,
        uint256 columnIndex,
        uint256 rowIndex,
        uint8 decimalPlaces,
        uint256 durationInSeconds
    )
        external
        returns (uint256 votingId)
    {
        PartyOrgan organ = _organFromId(organId);
        _onlyMember(organ);
        votingId = _getNextVotingId();
        _votings[votingId].createDecimalsVoting(
            votingId, msg.sender, durationInSeconds, organ, columnIndex, rowIndex, decimalPlaces
        );
    }

    function proposeThemeLabel(
        bool isCategorical,
        uint256 columnIndex,
        string calldata themeText,
        uint256 durationInSeconds
    )
        external
        returns (uint256 votingId)
    {
        votingId = _getNextVotingId();
        _votings[votingId].createThemeVoting(
            votingId, msg.sender, durationInSeconds, isCategorical, columnIndex, themeText
        );
    }

    function proposeStatementLabel(
        bool isCategorical,
        uint256 columnIndex,
        uint256 rowIndex,
        string calldata statementText,
        uint256 durationInSeconds
    )
        external
        returns (uint256 votingId)
    {
        votingId = _getNextVotingId();
        _votings[votingId].createStatementVoting(
            votingId, msg.sender, durationInSeconds, isCategorical, columnIndex, rowIndex, statementText
        );
    }

    function proposeCategoricalValue(
        string calldata organId,
        uint256 columnIndex,
        uint256 rowIndex,
        uint64 categoryValue,
        address dataOriginator,
        uint256 durationInSeconds
    )
        external
        returns (uint256 votingId)
    {
        PartyOrgan organ = _organFromId(organId);
        _onlyMember(organ);
        votingId = _getNextVotingId();
        _votings[votingId].createCategoricalValueVoting(
            votingId, msg.sender, durationInSeconds, organ, columnIndex, rowIndex, categoryValue, dataOriginator
        );
    }

    function proposeNumericalValue(
        string calldata organId,
        uint256 columnIndex,
        uint256 rowIndex,
        uint64 numericalValue,
        address dataOriginator,
        uint256 durationInSeconds
    )
        external
        returns (uint256 votingId)
    {
        PartyOrgan organ = _organFromId(organId);
        _onlyMember(organ);
        votingId = _getNextVotingId();
        _votings[votingId].createNumericalValueVoting(
            votingId, msg.sender, durationInSeconds, organ, columnIndex, rowIndex, numericalValue, dataOriginator
        );
    }

    function vote(uint256 votingId, bool support, string calldata organId) external votingExists(votingId) {
        _onlyMember(_organFromId(organId));
        _votings[votingId].castVote(support, msg.sender);
    }

    function getVotingInfo(uint256 votingId) external view votingExists(votingId) returns (VotingInfo memory info) {
        Votings.Voting storage v = _votings[votingId];
        Votings.VoteResults memory r = v.getVoteResults();

        info.votingId = votingId;
        info.proposedBy = v.author;
        info.startTime = v.startTime;
        info.endTime = v.endTime;
        info.active = v.isActive();
        info.finalized = v.isFinalized();
        info.votesFor = r.forVotes;
        info.votesAgainst = r.againstVotes;
        info.totalVotesCast = r.totalVotes;
        info.proposalType = _suggestionTypeLabel(v.suggestionType);

        if (v.suggestionType == Votings.SuggestionType.Membership) {
            info.subjectAddress = v.memberSuggestionData.member;
            info.organRaw = PartyOrgan.unwrap(v.memberSuggestionData.organ);
        } else if (v.suggestionType == Votings.SuggestionType.MembershipRevocation) {
            info.subjectAddress = v.memberRevocationSuggestionData.member;
            info.organRaw = PartyOrgan.unwrap(v.memberRevocationSuggestionData.organ);
        } else if (v.suggestionType == Votings.SuggestionType.Category) {
            info.columnIndex = v.categorySuggestionData.x;
            info.rowIndex = v.categorySuggestionData.y;
            info.categoryId = v.categorySuggestionData.category;
            info.categoryLabel = v.categorySuggestionData.categoryName;
            info.organRaw = PartyOrgan.unwrap(v.categorySuggestionData.organ);
        } else if (v.suggestionType == Votings.SuggestionType.Decimals) {
            info.columnIndex = v.decimalsSuggestionData.x;
            info.rowIndex = v.decimalsSuggestionData.y;
            info.decimals = v.decimalsSuggestionData.decimals;
            info.organRaw = PartyOrgan.unwrap(v.decimalsSuggestionData.organ);
        } else if (v.suggestionType == Votings.SuggestionType.Theme) {
            info.isCategorical = v.themeSuggestionData.isCategorical;
            info.columnIndex = v.themeSuggestionData.x;
            info.label = v.themeSuggestionData.theme;
        } else if (v.suggestionType == Votings.SuggestionType.Statement) {
            info.isCategorical = v.statementSuggestionData.isCategorical;
            info.columnIndex = v.statementSuggestionData.x;
            info.rowIndex = v.statementSuggestionData.y;
            info.label = v.statementSuggestionData.statement;
        } else if (v.suggestionType == Votings.SuggestionType.CategoricalValue) {
            info.columnIndex = v.categoricalValueSuggestionData.x;
            info.rowIndex = v.categoricalValueSuggestionData.y;
            info.proposedValue = v.categoricalValueSuggestionData.value;
            info.subjectAddress = v.categoricalValueSuggestionData.author;
            info.organRaw = PartyOrgan.unwrap(v.categoricalValueSuggestionData.organ);
        } else if (v.suggestionType == Votings.SuggestionType.NumericalValue) {
            info.columnIndex = v.numericalValueSuggestionData.x;
            info.rowIndex = v.numericalValueSuggestionData.y;
            info.proposedValue = v.numericalValueSuggestionData.value;
            info.subjectAddress = v.numericalValueSuggestionData.author;
            info.organRaw = PartyOrgan.unwrap(v.numericalValueSuggestionData.organ);
        }
    }

    function getVotingIds(uint256 offset, uint256 limit) external view returns (VotingPage memory page) {
        page.totalCount = nextVotingId;
        if (offset >= page.totalCount) return page;
        uint256 available = page.totalCount - offset;
        uint256 count = available < limit ? available : limit;
        page.ids = new uint256[](count);
        for (uint256 i; i < count;) {
            page.ids[i] = page.totalCount - offset - i;
            unchecked {
                ++i;
            }
        }
    }

    function categoricalCellDetails(uint256 x, uint256 y)
        external
        view
        returns (CategoricalCellDetails memory details)
    {
        CategoricalCellInfoResult memory info = this.getCategoricalCellInfo(x, y);
        details.allowedCategories = info.allowedCategories;
        details.sampleLength = info.sampleLength;
        details.organId = _toHexString(PartyOrgan.unwrap(info.organ));
    }

    function numericalCellDetails(uint256 x, uint256 y) external view returns (NumericalCellDetails memory details) {
        NumericalCellInfoResult memory info = this.getNumericalCellInfo(x, y);
        details.decimals = info.decimals;
        details.sampleLength = info.sampleLength;
        details.organId = _toHexString(PartyOrgan.unwrap(info.organ));
    }

    function _suggestionTypeLabel(Votings.SuggestionType t) internal pure returns (string memory) {
        if (t == Votings.SuggestionType.Membership) return unicode"Членство";
        if (t == Votings.SuggestionType.MembershipRevocation) return unicode"Отзыв членства";
        if (t == Votings.SuggestionType.Category) return unicode"Категория";
        if (t == Votings.SuggestionType.Decimals) return unicode"Точность";
        if (t == Votings.SuggestionType.Theme) return unicode"Тема";
        if (t == Votings.SuggestionType.Statement) return unicode"Высказывание";
        if (t == Votings.SuggestionType.CategoricalValue) {
            return unicode"Категориальное значение";
        }
        if (t == Votings.SuggestionType.NumericalValue) return unicode"Числовое значение";
        return "";
    }

    function _organFromId(string memory organId) internal pure returns (PartyOrgan) {
        return PartyOrgan.wrap(keccak256(abi.encodePacked(organId)));
    }

    function _toHexString(bytes32 value) internal pure returns (string memory) {
        bytes memory hexChars = "0123456789abcdef";
        bytes memory result = new bytes(66);
        result[0] = "0";
        result[1] = "x";
        for (uint256 i = 0; i < 32; i++) {
            result[2 + i * 2] = hexChars[uint8(value[i]) >> 4];
            result[3 + i * 2] = hexChars[uint8(value[i]) & 0x0f];
        }
        return string(result);
    }
}
