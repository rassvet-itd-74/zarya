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
///   MEMBERS — адреса членов Совета РО через запятую
contract ZaryaUIScript is Script {
    // Голосования шага 4 задаются вручную через abi.ninja.
    // Для тестовой сети рекомендуем duration = 60 (1 минута).

    // Кворум и порог для голосований за точность (decimals)
    uint256 constant SCHEMA_DURATION = 1;
    uint256 constant QUORUM = 1;
    uint256 constant APPROVAL = 51;

    string constant ORGAN = unicode"74.СОВ";

    function run() public {
        address[] memory memberAddrs = vm.envAddress("MEMBERS", ",");
        uint256 memberCount = memberAddrs.length;

        vm.startBroadcast();

        // 1. Деплой
        ZaryaUI zarya = new ZaryaUI();
        console.log("ZaryaUI deployed at:", address(zarya));

        // 2. Инициализация: члены + вся схема матрицы в одном вызове.
        //    Темы, высказывания и категории устанавливаются напрямую
        // без голосований.
        //    Остаются только голосования за точность числовых
        // значений (decimals).
        string[] memory organIds = new string[](memberCount);
        for (uint256 i = 0; i < memberCount; i++) {
            organIds[i] = ORGAN;
        }
        zarya.initializeReadable(
            organIds, memberAddrs, _catThemes(), _catStatements(), _numThemes(), _numStatements(), _catCells()
        );
        console.log("Members and schema initialized");

        // 3. Голосования за точность числовых ячеек
        _setupDecimals(zarya);

        vm.stopBroadcast();
    }

    // Данные схемы

    function _catThemes() internal pure returns (string[] memory t) {
        t = new string[](15);
        t[0] = unicode"Экология";
        t[1] = unicode"Внутренняя политика";
        t[2] = unicode"Внешняя политика";
        t[3] = unicode"Внешняя политика";
        t[4] = unicode"Свобода интернета";
        t[5] = unicode"Внешняя политика";
        t[6] = unicode"Внешняя политика";
        t[7] = unicode"Работа РО";
        t[8] = unicode"Организация работы РО";
        t[9] = unicode"Внутренняя политика партии";
        t[10] = unicode"Внутренняя политика партии";
        t[11] = unicode"Внутренняя политика партии";
        t[12] = unicode"Внутренняя политика партии";
        t[13] = unicode"Организация работы РО";
        t[14] = unicode"Союз с другими политическими силами";
    }

    function _catStatements() internal pure returns (string[] memory s) {
        s = new string[](15);
        s[0] = unicode"Совет РО считает, что количество выбросов {{value}}.";
        s[1] =
            unicode"Совет РО считает свои действия {{value}} сопричастными действиям органа центрального руководства Партии.";
        s[2] =
            unicode"Совет РО считает, что замороженные ЕС средства нужно отдать РФ на восстановление Курской и Белгородской области";
        s[3] =
            unicode"Совет РО считает, что в платформе ПАСЕ должны быть представители оппозиции, проживающие на территории РФ";
        s[4] =
            unicode"Совет РО считает, что нужно призывать население не использовать МАХ";
        s[5] =
            unicode"Совет РО считает, что недопустимо поднимать вопрос о разморозке активов ЕС до подписания мирного договора";
        s[6] =
            unicode"Совет РО считает, что главные проблемы страны сегодня, это {{value}}";
        s[7] =
            unicode"Совет РО считает, что следующая ({{value}}) партийная активность является политической";
        s[8] = unicode"Совет РО считает, что взносы должны идти на {{value}}";
        s[9] =
            unicode"Совет РО считает, что допустима самоцензура в официальных социальных сетях регионального отделения";
        s[10] =
            unicode"Совет РО считает, что партия «Рассвет» и её представители должны вести более активную информационную деятельность в СМИ и соцсетях";
        s[11] =
            unicode"Совет РО считает, что курс политической партии «Рассвет» понятен ({{value}})";
        s[12] =
            unicode"Совет РО считает, что в политической партии «Рассвет» должен быть менеджер по связям с общественностью/СМИ ({{value}})";
        s[13] =
            unicode"Совет РО считает, что РО проводит успешно ({{value}}) мероприятия";
        s[14] =
            unicode"Совет РО считает, что необходимо ({{value}}) сотрудничать с другими политическими силами Челябинской области";
    }

    function _numThemes() internal pure returns (string[] memory t) {
        t = new string[](9);
        t[0] = unicode"Внутренняя политика";
        t[1] = unicode"Внутренняя политика";
        t[2] = unicode"Организация работы РО";
        t[3] = unicode"Электоральная политика партии";
        t[4] = unicode"Внутренняя политика партии";
        t[5] = unicode"Организация работы РО";
        t[6] = unicode"Организация работы РО";
        t[7] = unicode"Организация работы РО";
        t[8] = unicode"Организация работы РО";
    }

    function _numStatements() internal pure returns (string[] memory s) {
        s = new string[](9);
        s[0] =
            unicode"Совет РО считает, что количество средств от спонсоров для эффективной деятельности РО должно равняться как минимум {{value}}";
        s[1] =
            unicode"Совет РО считает, что количество сторонников РО необходимое для узнаваемости партии равняется {{value}}";
        s[2] =
            unicode"Совет РО считает, что минимальные взносы должны составлять {{value}}";
        s[3] =
            unicode"Совет РО считает, что если бы партия «Рассвет» была официально допущена к выборам в Государственную Думу, то она набрала бы {{value}} процентов избирателей";
        s[4] =
            unicode"Совет РО считает, что член регионального отделения может уделять {{value}} часов на деятельности партии в неделю";
        s[5] =
            unicode"Совет РО считает, что региональное отделение партии должно организовывать {{value}} очных мероприятий в месяц";
        s[6] =
            unicode"Совет РО считает, что минимальный бюджет регионального отделения партии для эффективной деятельности в месяц должен составлять {{value}} рублей";
        s[7] =
            unicode"Совет РО считает, что для узнаваемости регионального отделения у него должно быть {{value}} сторонников";
        s[8] =
            unicode"Совет РО оценивает работу регионального отделения за год как {{value}} из 7, где 1 — неэффективно, 7 — максимально эффективно";
    }

    function _catCells() internal pure returns (ZaryaUI.CategoricalCellInit[] memory cells) {
        cells = new ZaryaUI.CategoricalCellInit[](15);

        // x=0 | Экология
        cells[0].x = 0;
        cells[0].y = 0;
        cells[0].organId = ORGAN;
        cells[0].categoryIds = new uint64[](3);
        cells[0].categoryLabels = new string[](3);
        cells[0].categoryIds[0] = 1;
        cells[0].categoryLabels[0] = unicode"Приемлемо";
        cells[0].categoryIds[1] = 2;
        cells[0].categoryLabels[1] = unicode"Неприемлемо";
        cells[0].categoryIds[2] = 3;
        cells[0].categoryLabels[2] = unicode"Неизвестно и сделать вывод невозможно";

        // x=1 | Внутренняя политика
        cells[1].x = 1;
        cells[1].y = 1;
        cells[1].organId = ORGAN;
        cells[1].categoryIds = new uint64[](4);
        cells[1].categoryLabels = new string[](4);
        cells[1].categoryIds[0] = 1;
        cells[1].categoryLabels[0] = unicode"Абсолютно";
        cells[1].categoryIds[1] = 2;
        cells[1].categoryLabels[1] = unicode"Скорее";
        cells[1].categoryIds[2] = 3;
        cells[1].categoryLabels[2] = unicode"Скорее не";
        cells[1].categoryIds[3] = 4;
        cells[1].categoryLabels[3] = unicode"Не";

        // x=2..5, 10 | Да / Нет / Не знаю
        _fillYesNoUnknown(cells, 2);
        _fillYesNoUnknown(cells, 3);
        _fillYesNoUnknown(cells, 4);
        _fillYesNoUnknown(cells, 5);
        _fillYesNoUnknown(cells, 10);

        // x=6 | Внешняя политика — главные проблемы страны [11
        // категорий]
        cells[6].x = 6;
        cells[6].y = 6;
        cells[6].organId = ORGAN;
        cells[6].categoryIds = new uint64[](11);
        cells[6].categoryLabels = new string[](11);
        cells[6].categoryIds[0] = 1;
        cells[6].categoryLabels[0] = unicode"война";
        cells[6].categoryIds[1] = 2;
        cells[6].categoryLabels[1] = unicode"путин";
        cells[6].categoryIds[2] = 3;
        cells[6].categoryLabels[2] = unicode"репрессии";
        cells[6].categoryIds[3] = 4;
        cells[6].categoryLabels[3] = unicode"коррупция";
        cells[6].categoryIds[4] = 5;
        cells[6].categoryLabels[4] = unicode"пропаганда";
        cells[6].categoryIds[5] = 6;
        cells[6].categoryLabels[5] = unicode"экология";
        cells[6].categoryIds[6] = 7;
        cells[6].categoryLabels[6] = unicode"транспорт";
        cells[6].categoryIds[7] = 8;
        cells[6].categoryLabels[7] = unicode"блокировки интернета";
        cells[6].categoryIds[8] = 9;
        cells[6].categoryLabels[8] = unicode"образование";
        cells[6].categoryIds[9] = 10;
        cells[6].categoryLabels[9] = unicode"здравоохранение";
        cells[6].categoryIds[10] = 11;
        cells[6].categoryLabels[10] = unicode"другое";

        // x=7 | Работа РО — политическая активность [11 категорий]
        cells[7].x = 7;
        cells[7].y = 7;
        cells[7].organId = ORGAN;
        cells[7].categoryIds = new uint64[](11);
        cells[7].categoryLabels = new string[](11);
        cells[7].categoryIds[0] = 1;
        cells[7].categoryLabels[0] = unicode"письма ПЗК";
        cells[7].categoryIds[1] = 2;
        cells[7].categoryLabels[1] = unicode"митинги";
        cells[7].categoryIds[2] = 3;
        cells[7].categoryLabels[2] = unicode"благотворительные акции";
        cells[7].categoryIds[3] = 4;
        cells[7].categoryLabels[3] = unicode"петиции";
        cells[7].categoryIds[4] = 5;
        cells[7].categoryLabels[4] = unicode"обращения в госорганы";
        cells[7].categoryIds[5] = 6;
        cells[7].categoryLabels[5] = unicode"экоакции";
        cells[7].categoryIds[6] = 7;
        cells[7].categoryLabels[6] = unicode"зоозащита";
        cells[7].categoryIds[7] = 8;
        cells[7].categoryLabels[7] = unicode"дебаты";
        cells[7].categoryIds[8] = 9;
        cells[7].categoryLabels[8] = unicode"киноклуб";
        cells[7].categoryIds[9] = 10;
        cells[7].categoryLabels[9] = unicode"выборы";
        cells[7].categoryIds[10] = 11;
        cells[7].categoryLabels[10] = unicode"другое";

        // x=8 | Организация работы РО — куда идут взносы [6 категорий]
        cells[8].x = 8;
        cells[8].y = 8;
        cells[8].organId = ORGAN;
        cells[8].categoryIds = new uint64[](6);
        cells[8].categoryLabels = new string[](6);
        cells[8].categoryIds[0] = 1;
        cells[8].categoryLabels[0] = unicode"премии";
        cells[8].categoryIds[1] = 2;
        cells[8].categoryLabels[1] = unicode"аренду помещения под собрания";
        cells[8].categoryIds[2] = 3;
        cells[8].categoryLabels[2] = unicode"юрист";
        cells[8].categoryIds[3] = 4;
        cells[8].categoryLabels[3] = unicode"ЧП";
        cells[8].categoryIds[4] = 5;
        cells[8].categoryLabels[4] = unicode"аренду оборудования";
        cells[8].categoryIds[5] = 6;
        cells[8].categoryLabels[5] = unicode"другое";

        // x=9 | Внутренняя политика партии — самоцензура [5 категорий]
        cells[9].x = 9;
        cells[9].y = 9;
        cells[9].organId = ORGAN;
        cells[9].categoryIds = new uint64[](5);
        cells[9].categoryLabels = new string[](5);
        cells[9].categoryIds[0] = 1;
        cells[9].categoryLabels[0] = unicode"Абсолютно допустима";
        cells[9].categoryIds[1] = 2;
        cells[9].categoryLabels[1] = unicode"скорее допустима";
        cells[9].categoryIds[2] = 3;
        cells[9].categoryLabels[2] = unicode"не знаю";
        cells[9].categoryIds[3] = 4;
        cells[9].categoryLabels[3] = unicode"скорее не допустима";
        cells[9].categoryIds[4] = 5;
        cells[9].categoryLabels[4] = unicode"абсолютно недопустима";

        // x=11 | Внутренняя политика партии — понятность курса [4
        // категории]
        cells[11].x = 11;
        cells[11].y = 11;
        cells[11].organId = ORGAN;
        cells[11].categoryIds = new uint64[](4);
        cells[11].categoryLabels = new string[](4);
        cells[11].categoryIds[0] = 1;
        cells[11].categoryLabels[0] = unicode"Абсолютно понятен";
        cells[11].categoryIds[1] = 2;
        cells[11].categoryLabels[1] = unicode"скорее понятен";
        cells[11].categoryIds[2] = 3;
        cells[11].categoryLabels[2] = unicode"скорее не понятен";
        cells[11].categoryIds[3] = 4;
        cells[11].categoryLabels[3] = unicode"абсолютно не понятен";

        // x=12 | Внутренняя политика партии — менеджер по PR [4 категории]
        cells[12].x = 12;
        cells[12].y = 12;
        cells[12].organId = ORGAN;
        cells[12].categoryIds = new uint64[](4);
        cells[12].categoryLabels = new string[](4);
        cells[12].categoryIds[0] = 1;
        cells[12].categoryLabels[0] = unicode"Абсолютно согласен";
        cells[12].categoryIds[1] = 2;
        cells[12].categoryLabels[1] = unicode"скорее согласен";
        cells[12].categoryIds[2] = 3;
        cells[12].categoryLabels[2] = unicode"скорее не согласен";
        cells[12].categoryIds[3] = 4;
        cells[12].categoryLabels[3] = unicode"абсолютно не согласен";

        // x=13 | Организация работы РО — успешность мероприятий [4
        // категории]
        cells[13].x = 13;
        cells[13].y = 13;
        cells[13].organId = ORGAN;
        cells[13].categoryIds = new uint64[](4);
        cells[13].categoryLabels = new string[](4);
        cells[13].categoryIds[0] = 1;
        cells[13].categoryLabels[0] = unicode"Успешно";
        cells[13].categoryIds[1] = 2;
        cells[13].categoryLabels[1] = unicode"Скорее успешно";
        cells[13].categoryIds[2] = 3;
        cells[13].categoryLabels[2] = unicode"Скорее не успешно";
        cells[13].categoryIds[3] = 4;
        cells[13].categoryLabels[3] = unicode"Безуспешно";

        // x=14 | Союз с другими политическими силами [4 категории]
        cells[14].x = 14;
        cells[14].y = 14;
        cells[14].organId = ORGAN;
        cells[14].categoryIds = new uint64[](4);
        cells[14].categoryLabels = new string[](4);
        cells[14].categoryIds[0] = 1;
        cells[14].categoryLabels[0] = unicode"Абсолютно согласен";
        cells[14].categoryIds[1] = 2;
        cells[14].categoryLabels[1] = unicode"скорее согласен";
        cells[14].categoryIds[2] = 3;
        cells[14].categoryLabels[2] = unicode"скорее не согласен";
        cells[14].categoryIds[3] = 4;
        cells[14].categoryLabels[3] = unicode"абсолютно не согласен";
    }

    function _fillYesNoUnknown(ZaryaUI.CategoricalCellInit[] memory cells, uint256 idx) internal pure {
        cells[idx].x = idx;
        cells[idx].y = idx;
        cells[idx].organId = ORGAN;
        cells[idx].categoryIds = new uint64[](3);
        cells[idx].categoryLabels = new string[](3);
        cells[idx].categoryIds[0] = 1;
        cells[idx].categoryLabels[0] = unicode"Да";
        cells[idx].categoryIds[1] = 2;
        cells[idx].categoryLabels[1] = unicode"Нет";
        cells[idx].categoryIds[2] = 3;
        cells[idx].categoryLabels[2] = unicode"Не знаю";
    }

    // Голосования за точность числовых ячеек

    function _setupDecimals(ZaryaUI zarya) internal {
        // x=0 | средства от спонсоров — 2 знака после запятой
        _execVoting(zarya, zarya.proposeDecimals(ORGAN, 0, 0, 2, SCHEMA_DURATION));
        // x=1..8 | целые числа
        _execVoting(zarya, zarya.proposeDecimals(ORGAN, 1, 1, 0, SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeDecimals(ORGAN, 2, 2, 0, SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeDecimals(ORGAN, 3, 3, 0, SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeDecimals(ORGAN, 4, 4, 0, SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeDecimals(ORGAN, 5, 5, 0, SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeDecimals(ORGAN, 6, 6, 0, SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeDecimals(ORGAN, 7, 7, 0, SCHEMA_DURATION));
        _execVoting(zarya, zarya.proposeDecimals(ORGAN, 8, 8, 0, SCHEMA_DURATION));
        console.log("Decimals configured");
    }

    function _execVoting(ZaryaUI zarya, uint256 votingId) internal {
        zarya.vote(votingId, true, ORGAN);
        zarya.executeVoting(votingId, QUORUM, APPROVAL);
    }
}
