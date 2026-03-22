// SPDX-License-Identifier: CC0 1.0 Universal
pragma solidity ^0.8.28;

import {Zarya} from "./Zarya.sol";
import {PartyOrgans, PartyOrgan} from "./libraries/PartyOrgans.sol";
import {Regions} from "./libraries/Regions.sol";
import {Votings} from "./libraries/Votings.sol";
import {EnumerableSet} from "@openzeppelin-contracts-5.4.0-rc.1/utils/structs/EnumerableSet.sol";

/**
 * @title ZaryaUI
 * @notice Обёртка над контрактом Zarya, удобная для интерфейса Scaffold ETH 2.
 *
 * Базовый контракт Zarya использует `PartyOrgan` — пользовательский тип
 * на основе `bytes32`,
 * получаемый хешированием строки-идентификатора органа через
 * keccak256.
 * Вводить сырые значения bytes32 в веб-интерфейсе неудобно и чревато
 * ошибками.
 *
 * Этот контракт заменяет каждый параметр `PartyOrgan` одним строковым
 * идентификатором органа, например «ПРЛ», «СОВ», «74.СОВ», «74.3.СОВ».
 * Используйте вспомогательную функцию `organIdentifier`, чтобы получить
 * нужную строку по типу органа и региону.
 *
 * Дополнительные функции просмотра возвращают структуру VotingInfo,
 * чтобы интерфейс мог отображать полную информацию о предложении
 * без
 * ручного декодирования ABI.
 *
 * Внутренняя логика полностью сохранена: контроль доступа,
 * процесс
 * голосования и обновление матриц по-прежнему делегируются
 * библиотекам Zarya.
 */
contract ZaryaUI is Zarya {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Votings for Votings.Voting;

    // ─────────────────────────────────────────────────────────────────────────
    // Структура отображения — все поля являются примитивами или
    // строками, без bytes32
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Постраничный результат запроса списка голосований.
    struct VotingPage {
        uint256[] ids;
        uint256 totalCount;
    }

    /// @notice Детали ячейки категорийной матрицы без bytes32
    /// (идентификатор органа — строка hex).
    struct CategoricalCellDetails {
        string organId;
        uint64[] allowedCategories;
        uint256 sampleLength;
    }

    /// @notice Детали ячейки числовой матрицы без bytes32 (идентификатор
    /// органа — строка hex).
    struct NumericalCellDetails {
        string organId;
        uint8 decimals;
        uint256 sampleLength;
    }

    /**
     * @notice Полный снимок одного предложения о голосовании, готовый
     * для отображения в интерфейсе.
     *
     * Заполняются только поля, относящиеся к данному
     * `типуПредложения`; остальные
     * остаются нулевыми или пустыми.
     *
     * Значения типа предложения:
     *   "Членство"               – добавить участника в орган
     *   "Отзыв Членства"          – исключить участника из органа
     *   "Категория"              – зарегистрировать новую допустимую
     * категорию в ячейке матрицы
     *   "Точность"              – задать точность десятичного числа для
     * ячейки матрицы
     *   "Тема"                   – задать заголовок столбца матрицы
     *   "Утверждение"            – задать заголовок строки матрицы
     *   "Категориальное Значение"   – записать категориальное
     * значение в
     * ячейку
     *   "Числовое Значение"       – записать числовое значение в
     * ячейку
     */
    struct VotingInfo {
        // ── Общие поля (заполняются всегда)
        // ───────────────────────────────────
        uint256 votingId;
        address proposedBy;
        uint256 startTime; // Временная метка Unix — начало голосования
        uint256 endTime; // Временная метка Unix — конец голосования
        bool active; // true пока окно голосования открыто
        bool finalized; // true после вызова executeVoting
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVotesCast;
        string proposalType; // Человекочитаемое название типа предложения
        // ── Поля о предмете (заполняются в зависимости от типа
        // предложения) ──
        /// Адрес, которого касается предложение (участник для
        // добавления/исключения или автор данных)
        address subjectAddress;
        /// Идентификатор органа в формате hex (строка «0x…»)
        string organIdentifier;
        /// Индекс столбца матрицы (x)
        uint256 columnIndex;
        /// Индекс строки матрицы (y)
        uint256 rowIndex;
        /// Тип матрицы: true — категорийная, false — числовая
        bool isCategorical;
        /// Текст метки (тема или утверждение)
        string label;
        /// Числовой идентификатор категории
        uint64 categoryId;
        /// Человекочитаемое название категории
        string categoryLabel;
        /// Предлагаемая точность десятичного числа
        uint8 decimals;
        /// Предлагаемое значение (ID категории для категорийных ячеек,
        /// целое число для числовых)
        uint64 proposedValue;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Вспомогательные функции просмотра органов
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Возвращает строку-идентификатор органа в
     * человекочитаемом виде.
     *
     * Примеры:
     *   organIdentifier(CentralSoviet, FEDERAL, 0)              → «СОВ»
     *   organIdentifier(Chairperson,   FEDERAL, 0)              → «ПРЛ»
     *   organIdentifier(RegionalSoviet, CHELYABINSKAYA_OBLAST,0) → «74.СОВ»
     *   organIdentifier(LocalSoviet,   CHELYABINSKAYA_OBLAST, 3) → «74.3.СОВ»
     *
     * @param organType    Значение перечисления типа органа.
     * @param region       Значение перечисления региона (используйте FEDERAL = 0
     * для центральных органов).
     * @param localNumber  Номер ячейки в регионе; укажите 0 для региональных
     * и федеральных органов.
     */
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

    /**
     * @notice Проверяет, является ли адрес членом указанного органа.
     *
     * @param member    Адрес кошелька для проверки.
     * @param organId   Строковый идентификатор органа, например «74.СОВ»
     * или «ПРЛ».
     *                  Используйте функцию `organIdentifier` для получения нужной
     * строки.
     */
    function checkMembership(address member, string calldata organId) external view returns (bool) {
        return _partyMembersRegistry.membersByOrgan[_organFromId(organId)].contains(member);
    }

    /**
     * @notice Возвращает true, если вызывающий (msg.sender) является членом
     * органа Председателя.
     */
    function amIChairman() external view returns (bool) {
        return _isChairman(msg.sender);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Инициализация
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Однократная инициализация: регистрация основателей по
     * органам.
     *         Оба массива должны иметь одинаковую длину.
     *         Может быть вызвана только один раз; повторные вызовы
     * завершатся ошибкой.
     *
     * @param organIds  Строковые идентификаторы органов (например, «ПРЛ»,
     * «74.СОВ»).
     *                  Используйте функцию `organIdentifier` для получения нужных
     * строк.
     * @param members   Адрес кошелька регистрируемого участника для
     * каждой записи.
     */
    function initializeOrgansReadable(string[] calldata organIds, address[] calldata members) external {
        uint256 len = organIds.length;
        PartyOrgan[] memory organs = new PartyOrgan[](len);
        for (uint256 i; i < len; ++i) {
            organs[i] = _organFromId(organIds[i]);
        }
        // Делегируется базовой реализации, которая владеет
        // однократной защитой
        this.initializeOrgans(organs, members);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Обёртки создания предложений
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Предложить добавить `candidateAddress` в указанный орган.
     *         Вызывающий должен уже быть членом этого органа или
     * Председателем.
     *
     * @param organId           Строковый идентификатор органа, например
     * «74.СОВ» или «ПРЛ».
     * @param candidateAddress  Адрес кошелька добавляемого участника.
     * @param durationInSeconds Продолжительность окна голосования (в
     * секундах).
     * @return votingId         Идентификатор для голосования и запроса
     * результатов.
     */
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

    /**
     * @notice Предложить исключить `memberToRemove` из указанного органа.
     *         Исключаемый не должен быть Председателем.
     *
     * @param organId           Строковый идентификатор органа, например
     * «74.СОВ» или «ПРЛ».
     * @param memberToRemove    Адрес кошелька исключаемого участника.
     * @param durationInSeconds Продолжительность окна голосования (в
     * секундах).
     * @return votingId         Идентификатор для голосования и запроса
     * результатов.
     */
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

    /**
     * @notice Предложить зарегистрировать новую допустимую категорию
     * для ячейки матрицы.
     *         Вызывающий должен быть членом указанного органа.
     *
     * @param organId           Строковый идентификатор органа, например
     * «74.СОВ» или «ПРЛ».
     * @param columnIndex       Столбец матрицы (x).
     * @param rowIndex          Строка матрицы (y).
     * @param categoryId        Числовой идентификатор новой категории.
     * @param categoryLabel     Человекочитаемое название категории.
     * @param durationInSeconds Продолжительность окна голосования (в
     * секундах).
     * @return votingId         Идентификатор для голосования и запроса
     * результатов.
     */
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

    /**
     * @notice Предложить задать точность десятичного числа для ячейки
     * числовой матрицы.
     *         Вызывающий должен быть членом указанного органа.
     *
     * @param organId           Строковый идентификатор органа, например
     * «74.СОВ» или «ПРЛ».
     * @param columnIndex       Столбец матрицы (x).
     * @param rowIndex          Строка матрицы (y).
     * @param decimalPlaces     Количество знаков после запятой (обычно 0–18).
     * @param durationInSeconds Продолжительность окна голосования (в
     * секундах).
     * @return votingId         Идентификатор для голосования и запроса
     * результатов.
     */
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

    /**
     * @notice Предложить задать текст метки для столбца матрицы (тему).
     *
     * @param isCategorical     true — категорийная матрица, false — числовая.
     * @param columnIndex       Индекс столбца матрицы (x).
     * @param themeText         Текст метки.
     * @param durationInSeconds Продолжительность окна голосования (в
     * секундах).
     * @return votingId         Идентификатор для голосования и запроса
     * результатов.
     */
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

    /**
     * @notice Предложить задать текст метки для строки матрицы
     * (утверждение).
     *
     * @param isCategorical     true — категорийная матрица, false — числовая.
     * @param columnIndex       Индекс столбца матрицы (x) — столбец темы, к
     * которому относится утверждение.
     * @param rowIndex          Индекс строки матрицы (y).
     * @param statementText     Текст метки.
     * @param durationInSeconds Продолжительность окна голосования (в
     * секундах).
     * @return votingId         Идентификатор для голосования и запроса
     * результатов.
     */
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

    /**
     * @notice Предложить записать категорийное значение в ячейку
     * матрицы.
     *         Вызывающий должен быть членом органа, управляющего
     * данной ячейкой.
     *
     * @param organId           Строковый идентификатор органа, например
     * «74.СОВ» или «ПРЛ».
     * @param columnIndex       Столбец матрицы (x).
     * @param rowIndex          Строка матрицы (y).
     * @param categoryValue     Числовой идентификатор категории для записи
     * (должен быть предварительно одобрен).
     * @param dataOriginator    Адрес, которому будет засчитана данная точка
     * данных.
     * @param durationInSeconds Продолжительность окна голосования (в
     * секундах).
     * @return votingId         Идентификатор для голосования и запроса
     * результатов.
     */
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

    /**
     * @notice Предложить записать числовое значение в ячейку матрицы.
     *         Вызывающий должен быть членом органа, управляющего
     * данной ячейкой.
     *         Значение является целым числом; используйте `getNumericalCellInfo`
     * для получения точности.
     *
     * @param organId           Строковый идентификатор органа, например
     * «74.СОВ» или «ПРЛ».
     * @param columnIndex       Столбец матрицы (x).
     * @param rowIndex          Строка матрицы (y).
     * @param numericalValue    Целое значение для записи.
     * @param dataOriginator    Адрес, которому будет засчитана данная точка
     * данных.
     * @param durationInSeconds Продолжительность окна голосования (в
     * секундах).
     * @return votingId         Идентификатор для голосования и запроса
     * результатов.
     */
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

    // ─────────────────────────────────────────────────────────────────────────
    // Участие в голосовании
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Проголосовать по открытому предложению.
     *         Вы должны быть членом указанного органа (орган служит
     * подтверждением
     *         активного членства, необязательно совпадает с органом
     * предложения).
     *
     * @param votingId  Идентификатор, возвращённый при создании
     * предложения.
     * @param support   true — голосовать «за», false — голосовать «против».
     * @param organId   Строковый идентификатор органа вашего членства,
     * например «74.СОВ».
     */
    function vote(uint256 votingId, bool support, string calldata organId) external votingExists(votingId) {
        _onlyMember(_organFromId(organId));
        _votings[votingId].castVote(support, msg.sender);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Функции расширенного просмотра
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Возвращает все данные об одном предложении в виде
     * структуры, удобной для интерфейса.
     *         Поля, не относящиеся к данному типу предложения, остаются
     * нулевыми или пустыми.
     *
     * @param votingId  Идентификатор запрашиваемого предложения.
     * @return info     Полностью заполненная структура VotingInfo.
     */
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
        info.proposalType = _suggestionTypeName(v.suggestionType);

        if (v.suggestionType == Votings.SuggestionType.Membership) {
            info.subjectAddress = v.memberSuggestionData.member;
            info.organIdentifier = _organToHex(v.memberSuggestionData.organ);
        } else if (v.suggestionType == Votings.SuggestionType.MembershipRevocation) {
            info.subjectAddress = v.memberRevocationSuggestionData.member;
            info.organIdentifier = _organToHex(v.memberRevocationSuggestionData.organ);
        } else if (v.suggestionType == Votings.SuggestionType.Category) {
            info.columnIndex = v.categorySuggestionData.x;
            info.rowIndex = v.categorySuggestionData.y;
            info.categoryId = v.categorySuggestionData.category;
            info.categoryLabel = v.categorySuggestionData.categoryName;
            info.organIdentifier = _organToHex(v.categorySuggestionData.organ);
        } else if (v.suggestionType == Votings.SuggestionType.Decimals) {
            info.columnIndex = v.decimalsSuggestionData.x;
            info.rowIndex = v.decimalsSuggestionData.y;
            info.decimals = v.decimalsSuggestionData.decimals;
            info.organIdentifier = _organToHex(v.decimalsSuggestionData.organ);
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
            info.organIdentifier = _organToHex(v.categoricalValueSuggestionData.organ);
        } else if (v.suggestionType == Votings.SuggestionType.NumericalValue) {
            info.columnIndex = v.numericalValueSuggestionData.x;
            info.rowIndex = v.numericalValueSuggestionData.y;
            info.proposedValue = v.numericalValueSuggestionData.value;
            info.subjectAddress = v.numericalValueSuggestionData.author;
            info.organIdentifier = _organToHex(v.numericalValueSuggestionData.organ);
        }
    }

    /**
     * @notice Постраничный список идентификаторов голосований, от
     * новых к старым.
     *
     * @param offset Количество пропускаемых записей (начиная с самых
     * новых).
     * @param limit  Максимальное количество возвращаемых
     * идентификаторов.
     * @return page  Страница результатов: массив ID (новые первыми) и общее
     * количество.
     */
    function getVotingIds(uint256 offset, uint256 limit) external view returns (VotingPage memory page) {
        page.totalCount = nextVotingId;
        if (offset >= page.totalCount) return page;
        uint256 available = page.totalCount - offset;
        uint256 count = available < limit ? available : limit;
        page.ids = new uint256[](count);
        for (uint256 i; i < count; ++i) {
            page.ids[i] = page.totalCount - offset - i;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Внутренние утилиты
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev Кодирует PartyOrgan (хеш bytes32) в строку вида «0x…».
    ///      Текст идентификатора органа не может быть восстановлен из
    /// хеша on-chain,
    ///      поэтому возвращается hex-представление как однозначная
    /// ссылка.
    function _organToHex(PartyOrgan organ) internal pure returns (string memory) {
        bytes32 raw = PartyOrgan.unwrap(organ);
        bytes memory s = new bytes(66); // «0x» + 64 hex-символа
        s[0] = "0";
        s[1] = "x";
        for (uint256 i; i < 32; ++i) {
            uint8 b = uint8(raw[i]);
            s[2 + i * 2] = _nibble(b >> 4);
            s[3 + i * 2] = _nibble(b & 0x0f);
        }
        return string(s);
    }

    function _nibble(uint8 n) internal pure returns (bytes1) {
        return n < 10 ? bytes1(n + 0x30) : bytes1(n + 0x57);
    }

    /// @dev Преобразует строковый идентификатор органа (например,
    /// «74.СОВ») в PartyOrgan
    ///      путём вычисления keccak256 от строки — точно так же, как это
    /// делает PartyOrgans.from().
    function _organFromId(string memory organId) internal pure returns (PartyOrgan) {
        return PartyOrgan.wrap(keccak256(abi.encodePacked(organId)));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Обёртки деталей ячеек без bytes32
    // (в наследуемых getCategoricalCellInfo / getNumericalCellInfo поле organ
    //  является PartyOrgan; эти функции преобразуют его в hex-строку и
    //  возвращают чистые структуры)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Детали ячейки категорийной матрицы без bytes32:
     *         идентификатор органа возвращается как строка hex.
     *         Используйте вместо наследуемого `getCategoricalCellInfo`.
     */
    function categoricalCellDetails(uint256 x, uint256 y) external view returns (CategoricalCellDetails memory result) {
        CategoricalCellInfoResult memory raw = this.getCategoricalCellInfo(x, y);
        result.organId = _organToHex(raw.organ);
        result.allowedCategories = raw.allowedCategories;
        result.sampleLength = raw.sampleLength;
    }

    /**
     * @notice Детали ячейки числовой матрицы без bytes32:
     *         идентификатор органа возвращается как строка hex.
     *         Используйте вместо наследуемого `getNumericalCellInfo`.
     */
    function numericalCellDetails(uint256 x, uint256 y) external view returns (NumericalCellDetails memory result) {
        NumericalCellInfoResult memory raw = this.getNumericalCellInfo(x, y);
        result.organId = _organToHex(raw.organ);
        result.decimals = raw.decimals;
        result.sampleLength = raw.sampleLength;
    }

    function _suggestionTypeName(Votings.SuggestionType t) internal pure returns (string memory) {
        if (t == Votings.SuggestionType.Membership) return unicode"Членство";
        if (t == Votings.SuggestionType.MembershipRevocation) return unicode"Отзыв Членства";
        if (t == Votings.SuggestionType.Category) return unicode"Категория";
        if (t == Votings.SuggestionType.Decimals) return unicode"Точность";
        if (t == Votings.SuggestionType.Theme) return unicode"Тема";
        if (t == Votings.SuggestionType.Statement) return unicode"Утверждение";
        if (t == Votings.SuggestionType.CategoricalValue) {
            return unicode"Категориальное Значение";
        }
        if (t == Votings.SuggestionType.NumericalValue) return unicode"Числовое Значение";
        return unicode"Неизвестно";
    }
}
