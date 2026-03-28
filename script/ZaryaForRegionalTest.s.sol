// SPDX-License-Identifier: CC0 1.0 Universal
pragma solidity ^0.8.28;

import {Script, console} from "forge-std-1.9.7/src/Script.sol";
import {ZaryaTestHelper} from "../test/ZaryaTestHelper.sol";
import {PartyOrgans, PartyOrgan} from "../src/libraries/PartyOrgans.sol";
import {Regions} from "../src/libraries/Regions.sol";

/**
 * @title ZaryaForRegionalTestScript
 * @notice Deploys and initializes Zarya contract with test data for Chelyabinsk Oblast (Region 74)
 * 
 * MATRIX STRUCTURE CREATED:
 * ========================
 * 
 * CATEGORICAL MATRIX (3x1):
 * -------------------------
 * Themes (rows, x-axis):
 *   x=0: "Экономика" (Economy)
 *   x=1: "Образование" (Education) 
 *   x=2: "Экология" (Ecology)
 * 
 * Statements (columns, y-axis):
 *   y=0: Different statement for each theme:
 *     - x=0: "Налоговая реформа" (Tax Reform)
 *     - x=1: "Зарплаты учителей" (Teachers' Salaries)
 *     - x=2: "Рекультивация свалок" (Landfill Reclamation)
 * 
 * Allowed Categories (per cell):
 *   Each cell (x,y) has 3 allowed categories: [1, 2, 3]
 *   Note: Category IDs only - no text names are set
 * 
 * Values Set:
 *   Cell(0,0): category=2 | Organ: Regional Soviet 74 | Author: MEMBER_1
 *   Cell(1,0): category=1 | Organ: Regional Soviet 74 | Author: MEMBER_2
 *   Cell(2,0): category=1 | Organ: Regional Soviet 74 | Author: MEMBER_3
 * 
 * 
 * NUMERICAL MATRIX (3x1):
 * -----------------------
 * Themes (rows, x-axis):
 *   x=0: "Безработица" (Unemployment)
 *   x=1: "Бюджет на образование" (Education Budget)
 *   x=2: "Экологический ущерб" (Ecological Damage)
 * 
 * Statements (columns, y-axis):
 *   y=0: Different statement for each theme:
 *     - x=0: "Уровень безработицы (%)" (Unemployment Rate %)
 *     - x=1: "Доля бюджета (%)" (Budget Share %)
 *     - x=2: "Оценка ущерба (баллы 0-10)" (Damage Assessment 0-10 points)
 * 
 * Decimals (per cell):
 *   Cell(0,0): decimals=1 (0.1 precision)
 *   Cell(1,0): decimals=1 (0.1 precision)
 *   Cell(2,0): decimals=0 (integer precision)
 * 
 * Values Set:
 *   Cell(0,0): value=75  (with decimals=1 → 7.5%)  | Organ: Regional Soviet 74 | Author: MEMBER_1
 *   Cell(1,0): value=123 (with decimals=1 → 12.3%) | Organ: Regional Soviet 74 | Author: MEMBER_2
 *   Cell(2,0): value=7   (with decimals=0 → 7)     | Organ: Regional Soviet 74 | Author: MEMBER_3
 */
contract ZaryaForRegionalTestScript is Script {
    address constant CHAIRMAN_ADDRESS = 0x57eb63d0aab5822EFCd7A9B56775F772D3e03CfD;
    address constant REGIONAL_SOVIET_74_1_MEMBER = 0xF7472BD43B119c49D0E80D5e70733A26AcCB6C44;
    address constant REGIONAL_SOVIET_74_2_MEMBER = 0xe63F4cbe5E06529155c3e70Cbf6a84cdf2C8F17E;
    address constant REGIONAL_SOVIET_74_3_MEMBER = 0x2aF5b7345A705Ea8910c209d7469656831aE5357;

    ZaryaTestHelper zarya;
    PartyOrgan chairpersonOrgan;
    PartyOrgan regionalSoviet74;

    uint256 constant VOTING_DURATION = 2 minutes; // Short duration for real network testing
    uint256 constant MINIMUM_QUORUM = 2;
    uint256 constant MINIMUM_APPROVAL = 51; // 51%
    uint256 constant INITIAL_ORGANS_COUNT = 4;
    uint256 constant CHAIRMAN_VOTINGS_COUNT = 12;
    uint256 constant CATEGORY_DECIMALS_VOTINGS_COUNT = 12;
    uint256 constant VALUE_VOTINGS_COUNT = 6; // 3 categorical + 3 numerical
    uint256 constant TOTAL_VOTINGS_COUNT = 30; // 12 chairman + 12 category/decimals + 6 value
    uint256 constant CHAIRPERSON_QUORUM = 1;
    uint256 constant REGIONAL_SOVIET_QUORUM = 1;
    uint256 constant FIRST_REGIONAL_VOTING_ID = 13;
    uint256 constant FIRST_VALUE_VOTING_ID = 25;
    uint256 constant THEME_INDEX_ECONOMY = 0;
    uint256 constant THEME_INDEX_EDUCATION = 1;
    uint256 constant THEME_INDEX_ECOLOGY = 2;
    uint256 constant STATEMENT_INDEX_0 = 0;
    uint64 constant CATEGORY_INDEX_1 = 1;
    uint64 constant CATEGORY_INDEX_2 = 2;
    uint64 constant CATEGORY_INDEX_3 = 3;
    uint8 constant DECIMALS_ONE = 1;
    uint8 constant DECIMALS_ZERO = 0;

    function run() public {
        vm.startBroadcast();

        zarya = new ZaryaTestHelper();
        console.log("ZaryaTestHelper deployed at:", address(zarya));

        // Set up the Chairperson organ
        chairpersonOrgan = PartyOrgans.from(PartyOrgans.PartyOrganType.Chairperson, Regions.Region.FEDERAL, 0);

        // Set up Regional Soviet for region 74 (Chelyabinsk)
        regionalSoviet74 =
            PartyOrgans.from(PartyOrgans.PartyOrganType.RegionalSoviet, Regions.Region.CHELYABINSKAYA_OBLAST, 0);

        // Initialize organs (can only be done once)
        PartyOrgan[] memory organs = new PartyOrgan[](INITIAL_ORGANS_COUNT);
        address[] memory members = new address[](INITIAL_ORGANS_COUNT);

        // Chairperson
        organs[THEME_INDEX_ECONOMY] = chairpersonOrgan;
        members[THEME_INDEX_ECONOMY] = CHAIRMAN_ADDRESS;

        // Regional Soviet 74 members
        organs[THEME_INDEX_EDUCATION] = regionalSoviet74;
        members[THEME_INDEX_EDUCATION] = REGIONAL_SOVIET_74_1_MEMBER;

        organs[THEME_INDEX_ECOLOGY] = regionalSoviet74;
        members[THEME_INDEX_ECOLOGY] = REGIONAL_SOVIET_74_2_MEMBER;

        organs[CATEGORY_INDEX_3] = regionalSoviet74;
        members[CATEGORY_INDEX_3] = REGIONAL_SOVIET_74_3_MEMBER;

        zarya.initializeOrgans(organs, members);

        // Add deployer to both organs for testing (allows single private key deployment)
        zarya.addMemberForTesting(msg.sender, chairpersonOrgan);
        zarya.addMemberForTesting(msg.sender, regionalSoviet74);
        zarya.addMemberForTesting(REGIONAL_SOVIET_74_1_MEMBER, regionalSoviet74);
        zarya.addMemberForTesting(REGIONAL_SOVIET_74_2_MEMBER, regionalSoviet74);
        zarya.addMemberForTesting(REGIONAL_SOVIET_74_3_MEMBER, regionalSoviet74);

        console.log("Organs initialized with constants + deployer:", msg.sender);

        _createChairmanVotings();
        _createCategoryAndDecimalsVotings();
        _executeStructureVotings();
        _createValueVotings();
        _executeValueVotings();

        console.log("\n=== Deployment completed:", TOTAL_VOTINGS_COUNT, "votings created & executed ===");
        console.log("ZaryaTestHelper address:", address(zarya));

        vm.stopBroadcast();
    }

    function _createChairmanVotings() internal {
        console.log("\n=== Creating chairman votings (batch) ===");

        // Create 6 theme votings (3 categorical + 3 numerical)
        bool[] memory isCategoricalThemes = new bool[](6);
        isCategoricalThemes[0] = true; isCategoricalThemes[1] = true; isCategoricalThemes[2] = true;
        
        uint256[] memory themeIndices = new uint256[](6);
        themeIndices[1] = THEME_INDEX_EDUCATION; themeIndices[2] = THEME_INDEX_ECOLOGY;
        themeIndices[3] = THEME_INDEX_ECONOMY; themeIndices[4] = THEME_INDEX_EDUCATION; themeIndices[5] = THEME_INDEX_ECOLOGY;
        
        string[] memory themeNames = new string[](6);
        themeNames[0] = unicode"Экономика"; themeNames[1] = unicode"Образование"; themeNames[2] = unicode"Экология";
        themeNames[3] = unicode"Безработица"; themeNames[4] = unicode"Бюджет на образование"; themeNames[5] = unicode"Экологический ущерб";
        
        uint256[] memory durations = new uint256[](6);
        for (uint256 i = 0; i < 6; i++) durations[i] = VOTING_DURATION;

        uint256[] memory themeVotingIds = zarya.batchCreateThemeVotings(isCategoricalThemes, themeIndices, themeNames, durations);
        console.log("Created", themeVotingIds.length, "theme votings");

        // Create 6 statement votings (3 categorical + 3 numerical)
        bool[] memory isCategoricalStatements = new bool[](6);
        isCategoricalStatements[0] = true; isCategoricalStatements[1] = true; isCategoricalStatements[2] = true;
        
        uint256[] memory statementThemeIndices = new uint256[](6);
        statementThemeIndices[1] = THEME_INDEX_EDUCATION; statementThemeIndices[2] = THEME_INDEX_ECOLOGY;
        statementThemeIndices[3] = THEME_INDEX_ECONOMY; statementThemeIndices[4] = THEME_INDEX_EDUCATION; statementThemeIndices[5] = THEME_INDEX_ECOLOGY;
        
        uint256[] memory statementIndices = new uint256[](6); // all zeros
        
        string[] memory statementNames = new string[](6);
        statementNames[0] = unicode"Налоговая реформа"; statementNames[1] = unicode"Зарплаты учителей"; statementNames[2] = unicode"Рекультивация свалок";
        statementNames[3] = unicode"Уровень безработицы (%)"; statementNames[4] = unicode"Доля бюджета (%)"; statementNames[5] = unicode"Оценка ущерба (баллы 0-10)";

        uint256[] memory statementVotingIds = zarya.batchCreateStatementVotings(isCategoricalStatements, statementThemeIndices, statementIndices, statementNames, durations);
        console.log("Created", statementVotingIds.length, "statement votings");

        // Vote on all chairman votings
        _batchVote(themeVotingIds, statementVotingIds);
        console.log("Cast votes for all", CHAIRMAN_VOTINGS_COUNT, "chairman votings");
    }

    function _createCategoryAndDecimalsVotings() internal {
        console.log("\n=== Creating category and decimals votings (batch) ===");

        // Create 9 category votings (3 per theme)
        PartyOrgan[] memory categoryOrgans = new PartyOrgan[](9);
        uint256[] memory categoryThemeIndices = new uint256[](9);
        uint64[] memory categories = new uint64[](9);
        string[] memory categoryNames = new string[](9);
        uint256[] memory categoryDurations = new uint256[](9);
        
        string[3] memory names = [unicode"За", unicode"Против", unicode"Воздержался"];
        
        for (uint256 i = 0; i < 9; i++) {
            categoryOrgans[i] = regionalSoviet74;
            categoryThemeIndices[i] = i / 3; // 0,0,0,1,1,1,2,2,2
            categories[i] = uint64((i % 3) + 1); // 1,2,3,1,2,3,1,2,3
            categoryNames[i] = names[i % 3]; // "За" - For, "Против" - Against, "Воздержался" - Abstained, repeated
            categoryDurations[i] = VOTING_DURATION;
        }
        
        uint256[] memory categoryStatementIndices = new uint256[](9); // all zeros
        uint256[] memory categoryVotingIds = zarya.batchCreateCategoryVotings(categoryOrgans, categoryThemeIndices, categoryStatementIndices, categories, categoryNames, categoryDurations);
        console.log("Created", categoryVotingIds.length, "category votings");

        // Create 3 decimals votings
        PartyOrgan[] memory decimalsOrgans = new PartyOrgan[](3);
        uint256[] memory decimalsThemeIndices = new uint256[](3);
        uint256[] memory decimalsStatementIndices = new uint256[](3);
        uint8[] memory decimals = new uint8[](3);
        uint256[] memory decimalsDurations = new uint256[](3);
        
        for (uint256 i = 0; i < 3; i++) {
            decimalsOrgans[i] = regionalSoviet74;
            decimalsThemeIndices[i] = i;
            decimals[i] = i < 2 ? DECIMALS_ONE : DECIMALS_ZERO;
            decimalsDurations[i] = VOTING_DURATION;
        }

        uint256[] memory decimalsVotingIds = zarya.batchCreateDecimalsVotings(decimalsOrgans, decimalsThemeIndices, decimalsStatementIndices, decimals, decimalsDurations);
        console.log("Created", decimalsVotingIds.length, "decimals votings");

        // Vote on all
        _batchVote(categoryVotingIds, decimalsVotingIds);
        console.log("Cast votes for all", CATEGORY_DECIMALS_VOTINGS_COUNT, "category/decimals votings");
    }

    function _executeStructureVotings() internal {
        console.log("\n=== Executing structure votings ===");

        _batchExecute(CATEGORY_INDEX_1, CHAIRMAN_VOTINGS_COUNT, CHAIRPERSON_QUORUM);
        console.log("Executed chairman votings: 1 -", CHAIRMAN_VOTINGS_COUNT);

        _batchExecute(FIRST_REGIONAL_VOTING_ID, CATEGORY_DECIMALS_VOTINGS_COUNT, REGIONAL_SOVIET_QUORUM);
        console.log("Executed regional votings:", FIRST_REGIONAL_VOTING_ID, "-", FIRST_REGIONAL_VOTING_ID + CATEGORY_DECIMALS_VOTINGS_COUNT - 1);

        console.log("Total structure votings executed:", CHAIRMAN_VOTINGS_COUNT + CATEGORY_DECIMALS_VOTINGS_COUNT, "(in 2 batches)");
    }

    function _createValueVotings() internal {
        console.log("\n=== Creating value votings (batch) ===");

        // Create 3 categorical value votings
        PartyOrgan[] memory valueOrgans = new PartyOrgan[](3);
        uint256[] memory valueThemeIndices = new uint256[](3);
        uint256[] memory valueStatementIndices = new uint256[](3);
        uint64[] memory values = new uint64[](3);
        address[] memory authors = new address[](3);
        uint256[] memory valueDurations = new uint256[](3);
        
        address[3] memory members = [REGIONAL_SOVIET_74_1_MEMBER, REGIONAL_SOVIET_74_2_MEMBER, REGIONAL_SOVIET_74_3_MEMBER];
        
        for (uint256 i = 0; i < 3; i++) {
            valueOrgans[i] = regionalSoviet74;
            valueThemeIndices[i] = i;
            values[i] = i == 0 ? CATEGORY_INDEX_2 : CATEGORY_INDEX_1;
            authors[i] = members[i];
            valueDurations[i] = VOTING_DURATION;
        }

        zarya.batchCreateCategoricalValueVotings(valueOrgans, valueThemeIndices, valueStatementIndices, values, authors, valueDurations);
        console.log("Created 3 categorical value votings");

        // Create 3 numerical value votings
        uint64[3] memory numericalValues = [uint64(75), uint64(123), uint64(7)];
        
        for (uint256 i = 0; i < 3; i++) {
            values[i] = numericalValues[i];
        }

        zarya.batchCreateNumericalValueVotings(valueOrgans, valueThemeIndices, valueStatementIndices, values, authors, valueDurations);
        console.log("Created 3 numerical value votings");
    }

    function _executeValueVotings() internal {
        console.log("\n=== Executing value votings ===");

        // Vote and execute
        address[3] memory members = [REGIONAL_SOVIET_74_1_MEMBER, REGIONAL_SOVIET_74_2_MEMBER, REGIONAL_SOVIET_74_3_MEMBER];
        
        uint256[] memory votingIds = new uint256[](VALUE_VOTINGS_COUNT * 3);
        bool[] memory votes = new bool[](VALUE_VOTINGS_COUNT * 3);
        address[] memory voters = new address[](VALUE_VOTINGS_COUNT * 3);
        
        for (uint256 i = 0; i < VALUE_VOTINGS_COUNT; i++) {
            for (uint256 j = 0; j < 3; j++) {
                uint256 idx = i * 3 + j;
                votingIds[idx] = FIRST_VALUE_VOTING_ID + i;
                votes[idx] = true;
                voters[idx] = members[j];
            }
        }

        zarya.batchCastVotesForTesting(votingIds, votes, voters);
        console.log("Batch cast", votingIds.length, "votes");

        _batchExecute(FIRST_VALUE_VOTING_ID, VALUE_VOTINGS_COUNT, REGIONAL_SOVIET_QUORUM);
        console.log("Batch executed", VALUE_VOTINGS_COUNT, "value votings");
    }

    function _batchVote(uint256[] memory ids1, uint256[] memory ids2) internal {
        uint256 total = ids1.length + ids2.length;
        uint256[] memory votingIds = new uint256[](total);
        bool[] memory votes = new bool[](total);
        address[] memory voters = new address[](total);
        
        for (uint256 i = 0; i < ids1.length; i++) {
            votingIds[i] = ids1[i];
            votes[i] = true;
            voters[i] = msg.sender;
        }
        for (uint256 i = 0; i < ids2.length; i++) {
            votingIds[ids1.length + i] = ids2[i];
            votes[ids1.length + i] = true;
            voters[ids1.length + i] = msg.sender;
        }
        
        zarya.batchCastVotesForTesting(votingIds, votes, voters);
    }

    function _batchExecute(uint256 startId, uint256 count, uint256 quorum) internal {
        uint256[] memory votingIds = new uint256[](count);
        uint256[] memory quorums = new uint256[](count);
        uint256[] memory approvals = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            votingIds[i] = startId + i;
            quorums[i] = quorum;
            approvals[i] = MINIMUM_APPROVAL;
        }
        
        zarya.batchExecuteVotingsForTesting(votingIds, quorums, approvals);
    }
}
