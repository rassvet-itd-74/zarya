// SPDX-License-Identifier: CC0 1.0 Universal
pragma solidity ^0.8.28;

import {Script, console} from "forge-std-1.9.7/src/Script.sol";
import {ZaryaUI} from "../src/ZaryaUI.sol";

/// @notice Региональный тест 74 РО — деплой + инициализация членов +
/// полная схема матрицы.
/// Запуск:
///   forge script script/ZaryaUI.s.sol --rpc-url <RPC> --broadcast --sender <DEPLOYER>
///
/// Переменные окружения (задать перед запуском):
///   MEMBER_01 .. MEMBER_12 — адреса 12 членов Совета РО
///   ZARYA_ADDRESS           — адрес уже задеплоенного контракта (если
/// пропустить деплой)
contract ZaryaUIScript is Script {
    // ── Продолжительность голосований в секундах
    // ──────────────────────────
    // Схемные голосования — короткие, т.к. сразу исполняем в этом же
    // скрипте.
    uint256 constant SCHEMA_DURATION = 1;
    // Голосования шага 4 задаются вручную через abi.ninja.
    // Для тестовой сети рекомендуем duration = 60 (1 минута).

    // ── Кворум и порог для схемных голосований
    // ───────────────────────────
    uint256 constant QUORUM = 1;
    uint256 constant APPROVAL = 51;

    string constant ORGAN = unicode"74.СОВ";

    function run() public {
        // Читаем адреса членов из окружения. Если переменная не
        // задана — адрес нулевой,
        // и контракт ревертнётся сам с InvalidMemberAddress.
        address[12] memory members = [
            vm.envOr("MEMBER_01", address(0)),
            vm.envOr("MEMBER_02", address(0)),
            vm.envOr("MEMBER_03", address(0)),
            vm.envOr("MEMBER_04", address(0)),
            vm.envOr("MEMBER_05", address(0)),
            vm.envOr("MEMBER_06", address(0)),
            vm.envOr("MEMBER_07", address(0)),
            vm.envOr("MEMBER_08", address(0)),
            vm.envOr("MEMBER_09", address(0)),
            vm.envOr("MEMBER_10", address(0)),
            vm.envOr("MEMBER_11", address(0)),
            vm.envOr("MEMBER_12", address(0))
        ];

        vm.startBroadcast();

        // ── 1. Деплой
        // ─────────────────────────────────────────────────────
        ZaryaUI zarya = new ZaryaUI();
        console.log("ZaryaUI deployed at:", address(zarya));

        // ── 2. Инициализация всех 12 членов одним вызовом
        // ────────────────
        string[] memory organIds = new string[](12);
        address[] memory memberAddrs = new address[](12);
        for (uint256 i = 0; i < 12; i++) {
            organIds[i] = ORGAN;
            memberAddrs[i] = members[i];
        }
        zarya.initializeOrgansReadable(organIds, memberAddrs);
        console.log("12 members initialized");

        // ── 3. Схема матрицы
        // ──────────────────────────────────────────────
        _setupSchema(zarya);

        vm.stopBroadcast();
    }

    /// @dev Создаёт все голосования схемы и сразу исполняет их (quorum=1,
    /// duration=1s).
    ///      Все вызовы идут от msg.sender (broadcaster), который является членом
    /// органа.
    function _setupSchema(ZaryaUI zarya) internal {
        // ── S_Y: 16 категориальных столбцов (y = x для уникальности
        // слота) ──

        // x=0 | Экология
        _schemaCategory(
            zarya,
            true,
            0,
            unicode"Экология",
            unicode"Совет РО считает, что количество выбросов X."
        );
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 0, 0, 1, unicode"Приемлемо", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 0, 0, 2, unicode"Неприемлемо", SCHEMA_DURATION));
        _execVoting(
            zarya,
            zarya.proposeCategory(
                ORGAN,
                0,
                0,
                3,
                unicode"Неизвестно и сделать вывод невозможно",
                SCHEMA_DURATION
            )
        );

        // x=1 | Внутренняя политика
        _schemaCategory(
            zarya,
            true,
            1,
            unicode"Внутренняя политика",
            unicode"Совет РО считает свои действия X сопричастными действиям органа центрального руководства Партии."
        );
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 1, 1, 1, unicode"Абсолютно", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 1, 1, 2, unicode"Скорее", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 1, 1, 3, unicode"Скорее не", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 1, 1, 4, unicode"Не", SCHEMA_DURATION));

        // x=2 | Организация работы РО — оценка за год [1..7]
        _schemaCategory(
            zarya,
            true,
            2,
            unicode"Организация работы РО",
            unicode"Члены нашего РО оценивают нашу работу за год как Х"
        );
        _execVoting(
            zarya, zarya.proposeCategory(ORGAN, 2, 2, 1, unicode"1 — неэффективно", SCHEMA_DURATION)
        );
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 2, 2, 2, unicode"2", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 2, 2, 3, unicode"3", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 2, 2, 4, unicode"4", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 2, 2, 5, unicode"5", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 2, 2, 6, unicode"6", SCHEMA_DURATION));
        _execVoting(
            zarya,
            zarya.proposeCategory(
                ORGAN, 2, 2, 7, unicode"7 — максимально эффективно", SCHEMA_DURATION
            )
        );

        // x=3 | Внешняя политика — замороженные ЕС средства
        _schemaCategory(
            zarya,
            true,
            3,
            unicode"Внешняя политика",
            unicode"Совет РО считает, что замороженные ЕС средства нужно отдать РФ на восстановление Курской и Белгородской области"
        );
        _addYesNoUnknown(zarya, 3, 3);

        // x=4 | Внешняя политика — ПАСЕ и оппозиция
        _schemaCategory(
            zarya,
            true,
            4,
            unicode"Внешняя политика",
            unicode"Совет РО считает, что в платформе ПАСЕ должны быть представители оппозиции, проживающие на территории РФ"
        );
        _addYesNoUnknown(zarya, 4, 4);

        // x=5 | Свобода интернета — МАХ
        _schemaCategory(
            zarya,
            true,
            5,
            unicode"Свобода интернета",
            unicode"Совет РО считает, что нужно призывать население не использовать МАХ"
        );
        _addYesNoUnknown(zarya, 5, 5);

        // x=6 | Внешняя политика — разморозка активов ЕС
        _schemaCategory(
            zarya,
            true,
            6,
            unicode"Внешняя политика",
            unicode"Совет РО считает, что недопустимо поднимать вопрос о разморозке активов ЕС до подписания мирного договора"
        );
        _addYesNoUnknown(zarya, 6, 6);

        // x=7 | Внешняя политика — главные проблемы страны
        _schemaCategory(
            zarya,
            true,
            7,
            unicode"Внешняя политика",
            unicode"Совет РО считает, что главные проблемы страны сегодня, это Х"
        );
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 7, 7, 1, unicode"война", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 7, 7, 2, unicode"путин", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 7, 7, 3, unicode"репрессии", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 7, 7, 4, unicode"коррупция", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 7, 7, 5, unicode"пропаганда", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 7, 7, 6, unicode"экология", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 7, 7, 7, unicode"транспорт", SCHEMA_DURATION));
        _execVoting(
            zarya,
            zarya.proposeCategory(ORGAN, 7, 7, 8, unicode"блокировки интернета", SCHEMA_DURATION)
        );
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 7, 7, 9, unicode"образование", SCHEMA_DURATION));
        _execVoting(
            zarya, zarya.proposeCategory(ORGAN, 7, 7, 10, unicode"здравоохранение", SCHEMA_DURATION)
        );
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 7, 7, 11, unicode"другое", SCHEMA_DURATION));

        // x=8 | Работа РО — политическая активность
        _schemaCategory(
            zarya,
            true,
            8,
            unicode"Работа РО",
            unicode"Совет РО считает, что следующая (Х) партийная активность является политической"
        );
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 8, 8, 1, unicode"письма ПЗК", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 8, 8, 2, unicode"митинги", SCHEMA_DURATION));
        _execVoting(
            zarya,
            zarya.proposeCategory(
                ORGAN, 8, 8, 3, unicode"благотворительные акции", SCHEMA_DURATION
            )
        );
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 8, 8, 4, unicode"петиции", SCHEMA_DURATION));
        _execVoting(
            zarya,
            zarya.proposeCategory(ORGAN, 8, 8, 5, unicode"обращения в госорганы", SCHEMA_DURATION)
        );
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 8, 8, 6, unicode"экоакции", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 8, 8, 7, unicode"зоозащита", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 8, 8, 8, unicode"дебаты", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 8, 8, 9, unicode"киноклуб", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 8, 8, 10, unicode"выборы", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 8, 8, 11, unicode"другое", SCHEMA_DURATION));

        // x=9 | Организация работы РО — куда идут взносы
        _schemaCategory(
            zarya,
            true,
            9,
            unicode"Организация работы РО",
            unicode"Совет РО считает, что взносы должны идти на Х"
        );
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 9, 9, 1, unicode"премии", SCHEMA_DURATION));
        _execVoting(
            zarya,
            zarya.proposeCategory(
                ORGAN, 9, 9, 2, unicode"аренда помещения под собрания", SCHEMA_DURATION
            )
        );
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 9, 9, 3, unicode"юрист", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 9, 9, 4, unicode"ЧП", SCHEMA_DURATION));
        _execVoting(
            zarya,
            zarya.proposeCategory(ORGAN, 9, 9, 5, unicode"аренда оборудования", SCHEMA_DURATION)
        );
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 9, 9, 6, unicode"другое", SCHEMA_DURATION));

        // x=10 | Внутренняя политика партии — самоцензура
        _schemaCategory(
            zarya,
            true,
            10,
            unicode"Внутренняя политика партии",
            unicode"Совет РО считает, что допустима самоцензура в официальных социальных сетях регионального отделения"
        );
        _execVoting(
            zarya,
            zarya.proposeCategory(ORGAN, 10, 10, 1, unicode"Абсолютно допустима", SCHEMA_DURATION)
        );
        _execVoting(
            zarya, zarya.proposeCategory(ORGAN, 10, 10, 2, unicode"скорее допустима", SCHEMA_DURATION)
        );
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 10, 10, 3, unicode"не знаю", SCHEMA_DURATION));
        _execVoting(
            zarya,
            zarya.proposeCategory(ORGAN, 10, 10, 4, unicode"скорее не допустима", SCHEMA_DURATION)
        );
        _execVoting(
            zarya,
            zarya.proposeCategory(ORGAN, 10, 10, 5, unicode"абсолютно недопустима", SCHEMA_DURATION)
        );

        // x=11 | Внутренняя политика партии — активность в СМИ
        _schemaCategory(
            zarya,
            true,
            11,
            unicode"Внутренняя политика партии",
            unicode"Совет РО считает, что партия «Рассвет» и её представители должны вести более активную информационную деятельность в СМИ и соцсетях"
        );
        _addYesNoUnknown(zarya, 11, 11);

        // x=12 | Внутренняя политика партии — понятность курса
        _schemaCategory(
            zarya,
            true,
            12,
            unicode"Внутренняя политика партии",
            unicode"Совет РО считает, что курс политической партии «Рассвет» понятен (X)"
        );
        _execVoting(
            zarya, zarya.proposeCategory(ORGAN, 12, 12, 1, unicode"Абсолютно понятен", SCHEMA_DURATION)
        );
        _execVoting(
            zarya, zarya.proposeCategory(ORGAN, 12, 12, 2, unicode"скорее понятен", SCHEMA_DURATION)
        );
        _execVoting(
            zarya, zarya.proposeCategory(ORGAN, 12, 12, 3, unicode"скорее не понятен", SCHEMA_DURATION)
        );
        _execVoting(
            zarya,
            zarya.proposeCategory(ORGAN, 12, 12, 4, unicode"абсолютно не понятен", SCHEMA_DURATION)
        );

        // x=13 | Внутренняя политика партии — менеджер по PR
        _schemaCategory(
            zarya,
            true,
            13,
            unicode"Внутренняя политика партии",
            unicode"Совет РО считает, что в политической партии «Рассвет» должен быть менеджер по связям с общественностью/СМИ (X)"
        );
        _execVoting(
            zarya,
            zarya.proposeCategory(ORGAN, 13, 13, 1, unicode"Абсолютно согласен", SCHEMA_DURATION)
        );
        _execVoting(
            zarya, zarya.proposeCategory(ORGAN, 13, 13, 2, unicode"скорее согласен", SCHEMA_DURATION)
        );
        _execVoting(
            zarya, zarya.proposeCategory(ORGAN, 13, 13, 3, unicode"скорее не согласен", SCHEMA_DURATION)
        );
        _execVoting(
            zarya,
            zarya.proposeCategory(ORGAN, 13, 13, 4, unicode"абсолютно не согласен", SCHEMA_DURATION)
        );

        // x=14 | Организация работы РО — успешность мероприятий
        _schemaCategory(
            zarya,
            true,
            14,
            unicode"Организация работы РО",
            unicode"Совет РО считает, что РО проводит успешно (X) мероприятия"
        );
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 14, 14, 1, unicode"Успешно", SCHEMA_DURATION));
        _execVoting(
            zarya, zarya.proposeCategory(ORGAN, 14, 14, 2, unicode"Скорее успешно", SCHEMA_DURATION)
        );
        _execVoting(
            zarya, zarya.proposeCategory(ORGAN, 14, 14, 3, unicode"Скорее не успешно", SCHEMA_DURATION)
        );
        _execVoting(zarya, zarya.proposeCategory(ORGAN, 14, 14, 4, unicode"Безуспешно", SCHEMA_DURATION));

        // x=15 | Союз с другими политическими силами
        _schemaCategory(
            zarya,
            true,
            15,
            unicode"Союз с другими политическими силами",
            unicode"Совет РО считает, что необходимо (X) сотрудничать с другими политическими силами Челябинской области"
        );
        _execVoting(
            zarya,
            zarya.proposeCategory(ORGAN, 15, 15, 1, unicode"Абсолютно согласен", SCHEMA_DURATION)
        );
        _execVoting(
            zarya, zarya.proposeCategory(ORGAN, 15, 15, 2, unicode"скорее согласен", SCHEMA_DURATION)
        );
        _execVoting(
            zarya, zarya.proposeCategory(ORGAN, 15, 15, 3, unicode"скорее не согласен", SCHEMA_DURATION)
        );
        _execVoting(
            zarya,
            zarya.proposeCategory(ORGAN, 15, 15, 4, unicode"абсолютно не согласен", SCHEMA_DURATION)
        );

        // ── S_X: 8 числовых столбцов (y = x)
        // ─────────────────────────────

        // x=0 | Внутренняя политика — средства от спонсоров (decimals=2)
        _schemaDecimals(
            zarya,
            false,
            0,
            2,
            unicode"Внутренняя политика",
            unicode"Совет РО считает, что количество средств от спонсоров для эффективной деятельности РО должно равняться как минимум Х"
        );

        // x=1 | Внутренняя политика — сторонники для узнаваемости
        // партии
        _schemaDecimals(
            zarya,
            false,
            1,
            0,
            unicode"Внутренняя политика",
            unicode"Совет РО считает, что количество сторонников РО необходимое для узнаваемости партии равняется Х"
        );

        // x=2 | Организация работы РО — минимальные взносы
        _schemaDecimals(
            zarya,
            false,
            2,
            0,
            unicode"Организация работы РО",
            unicode"Совет РО считает, что минимальные взносы должны составлять Х"
        );

        // x=3 | Электоральная политика партии — % на выборах в ГД
        _schemaDecimals(
            zarya,
            false,
            3,
            0,
            unicode"Электоральная политика партии",
            unicode"Совет РО считает, что если бы партия «Рассвет» была официально допущена к выборам в Государственную Думу, то она набрала бы X процентов избирателей"
        );

        // x=4 | Внутренняя политика партии — часов в неделю на партию
        _schemaDecimals(
            zarya,
            false,
            4,
            0,
            unicode"Внутренняя политика партии",
            unicode"Совет РО считает, что член регионального отделения может уделять X часов на деятельности партии в неделю"
        );

        // x=5 | Организация работы РО — мероприятий в месяц
        _schemaDecimals(
            zarya,
            false,
            5,
            0,
            unicode"Организация работы РО",
            unicode"Совет РО считает, что региональное отделение партии должно организовывать X очных мероприятий в месяц"
        );

        // x=6 | Организация работы РО — минимальный бюджет в месяц
        _schemaDecimals(
            zarya,
            false,
            6,
            0,
            unicode"Организация работы РО",
            unicode"Совет РО считает, что минимальный бюджет регионального отделения партии для эффективной деятельности в месяц должен составлять X рублей"
        );

        // x=7 | Организация работы РО — сторонники для узнаваемости РО
        _schemaDecimals(
            zarya,
            false,
            7,
            0,
            unicode"Организация работы РО",
            unicode"Совет РО считает, что для узнаваемости регионального отделения у него должно быть X сторонников"
        );

        console.log("Schema setup complete");
    }

    // ── Вспомогательные функции
    // ───────────────────────────────────────────

    /// @dev Создаёт Theme + Statement голосования и сразу исполняет их.
    function _schemaCategory(
        ZaryaUI zarya,
        bool isCategorical,
        uint256 x,
        string memory theme,
        string memory statement
    )
        internal
    {
        _execVoting(zarya, zarya.proposeThemeLabel(isCategorical, x, theme, SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeStatementLabel(isCategorical, x, x, statement, SCHEMA_DURATION));
    }

    /// @dev Создаёт Theme + Statement + Decimals голосования и сразу исполняет их.
    function _schemaDecimals(
        ZaryaUI zarya,
        bool isCategorical,
        uint256 x,
        uint8 decimals,
        string memory theme,
        string memory statement
    )
        internal
    {
        _execVoting(zarya, zarya.proposeThemeLabel(isCategorical, x, theme, SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeStatementLabel(isCategorical, x, x, statement, SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeDecimals(ORGAN, x, x, decimals, SCHEMA_DURATION));
    }

    /// @dev Добавляет категории Да/Нет/Не знаю (ID 1/2/3) для ячейки (x, y).
    function _addYesNoUnknown(ZaryaUI zarya, uint256 x, uint256 y) internal {
        _execVoting(zarya, zarya.proposeCategory(ORGAN, x, y, 1, unicode"Да", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, x, y, 2, unicode"Нет", SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeCategory(ORGAN, x, y, 3, unicode"Не знаю", SCHEMA_DURATION));
    }

    /// @dev Голосует «за» от имени broadcaster и исполняет голосование с
    /// quorum=1.
    function _execVoting(ZaryaUI zarya, uint256 votingId) internal {
        zarya.vote(votingId, true, ORGAN);
        zarya.executeVoting(votingId, QUORUM, APPROVAL);
    }
}
