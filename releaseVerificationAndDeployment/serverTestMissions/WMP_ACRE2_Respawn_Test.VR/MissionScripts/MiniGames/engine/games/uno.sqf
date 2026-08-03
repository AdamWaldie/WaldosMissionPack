/*
 * Waldos Mini Games - UNO
 * All Waldo_MG_fnc_* functions implementing the UNO mini game (server logic + local UI).
 *
 * Original engine: "Party Games Scripted" by |LorD|[Habilidade]Deus Ex.
 * Ported into WaldosMissionPack and rebranded to the Waldo_MG_ namespace; game
 * logic is preserved from the original composition. Do not claim original authorship.
 *
 * This file is an engine fragment: it defines a group of Waldo_MG_fnc_* runtime
 * functions and is #included by Waldo_fnc_MiniGamesInit (miniGamesInit.sqf).
 * It is not a standalone CfgFunctions entry and is not called directly.
 */

Waldo_MG_fnc_unoIsCard = {
    params [["_card", []]];
    if ((typeName _card) != "ARRAY" || {(count _card) < 3}) exitWith {false};
    private _id = _card param [0, -1];
    private _colour = _card param [1, -1];
    private _kind = _card param [2, -1];
    (typeName _id) == "SCALAR"
        && {(typeName _colour) == "SCALAR"}
        && {(typeName _kind) == "SCALAR"}
        && {_id == floor _id}
        && {_id >= 0}
        && {_colour == floor _colour}
        && {_colour >= 0}
        && {_colour <= 4}
        && {_kind == floor _kind}
        && {_kind >= 0}
        && {_kind <= 15}
};

Waldo_MG_fnc_unoColourName = {
    params [["_colour", -1]];
    switch (_colour) do {
        case 0: {"RED"};
        case 1: {"BLUE"};
        case 2: {"GREEN"};
        case 3: {"YELLOW"};
        case 4: {"BLACK"};
        default {"UNKNOWN"};
    }
};

Waldo_MG_fnc_unoKindLabel = {
    params [["_kind", -1]];
    if (_kind >= 0 && {_kind <= 10}) exitWith {str _kind};
    switch (_kind) do {
        case 11: {"BLOCK"};
        case 12: {"REVERSE"};
        case 13: {"+2"};
        case 14: {"WILD"};
        case 15: {"+4"};
        default {"?"};
    }
};

Waldo_MG_fnc_unoMarkerClass = {
    params [["_kind", -1]];
    switch (_kind) do {
        case 11: {"mil_warning"};
        case 12: {"respawn_unknown"};
        case 14: {"mil_unknown"};
        default {""};
    }
};

Waldo_MG_fnc_unoCardName = {
    params [["_card", []], ["_effectiveColour", -1]];
    if (!([_card] call Waldo_MG_fnc_unoIsCard)) exitWith {"Unknown UNO card"};
    private _colour = _card param [1, 4];
    private _kind = _card param [2, -1];
    if (_kind in [14, 15] && {_effectiveColour in [0, 1, 2, 3]}) then {
        _colour = _effectiveColour;
    };
    format [
        "%1 %2",
        [_colour] call Waldo_MG_fnc_unoColourName,
        [_kind] call Waldo_MG_fnc_unoKindLabel
    ]
};

Waldo_MG_fnc_unoShuffleCardsServer = {
    params [["_cardsSource", []]];
    private _source = if ((typeName _cardsSource) == "ARRAY") then {+_cardsSource} else {[]};
    private _shuffled = [];
    while {(count _source) > 0} do {
        private _pick = floor (random (count _source));
        _shuffled pushBack (_source deleteAt _pick);
    };
    _shuffled
};

Waldo_MG_fnc_unoCreateShuffledDeckServer = {
    private _cards = [];
    private _uniqueId = 0;
    for "_colour" from 0 to 3 do {
        _cards pushBack [_uniqueId, _colour, 0];
        _uniqueId = _uniqueId + 1;
        for "_number" from 1 to 10 do {
            for "_copy" from 1 to 2 do {
                _cards pushBack [_uniqueId, _colour, _number];
                _uniqueId = _uniqueId + 1;
            };
        };
        for "_kind" from 11 to 13 do {
            for "_copy" from 1 to 2 do {
                _cards pushBack [_uniqueId, _colour, _kind];
                _uniqueId = _uniqueId + 1;
            };
        };
    };
    for "_copy" from 1 to 4 do {
        _cards pushBack [_uniqueId, 4, 14];
        _uniqueId = _uniqueId + 1;
        _cards pushBack [_uniqueId, 4, 15];
        _uniqueId = _uniqueId + 1;
    };
    [_cards] call Waldo_MG_fnc_unoShuffleCardsServer
};

Waldo_MG_fnc_unoCanPlayCard = {
    params [
        ["_card", []],
        ["_topCard", []],
        ["_activeColour", -1],
        ["_pendingKind", -1]
    ];
    if (!([_card] call Waldo_MG_fnc_unoIsCard)) exitWith {false};
    private _kind = _card param [2, -1];
    if (_pendingKind in [13, 15]) exitWith {_kind == _pendingKind};
    if (_kind in [14, 15]) exitWith {true};
    if (!([_topCard] call Waldo_MG_fnc_unoIsCard)) exitWith {true};
    (_card param [1, -1]) == _activeColour
        || {_kind == (_topCard param [2, -2])}
};

Waldo_MG_fnc_unoCanPlayFromHand = {
    params [
        ["_card", []],
        ["_hand", []],
        ["_topCard", []],
        ["_activeColour", -1],
        ["_pendingKind", -1]
    ];
    private _legal = [_card, _topCard, _activeColour, _pendingKind] call Waldo_MG_fnc_unoCanPlayCard;
    if (!_legal) exitWith {false};
    if ((_card param [2, -1]) == 15 && {_pendingKind != 15}) then {
        {
            if (
                (_x param [1, 4]) == _activeColour
                && {!((_x param [2, -1]) in [14, 15])}
            ) then {
                _legal = false;
            };
        } forEach _hand;
    };
    _legal
};

Waldo_MG_fnc_unoCountActiveRoles = {
    params [["_activeFlags", []]];
    private _count = 0;
    {
        if ((typeName _x) == "BOOL" && {_x}) then {_count = _count + 1;};
    } forEach _activeFlags;
    _count
};

Waldo_MG_fnc_unoGetNextActiveRole = {
    params [
        ["_start", -1],
        ["_direction", 1],
        ["_activeFlags", []],
        ["_steps", 1]
    ];
    private _count = count _activeFlags;
    if (_count <= 0 || {([_activeFlags] call Waldo_MG_fnc_unoCountActiveRoles) <= 0}) exitWith {-1};
    _direction = if (_direction < 0) then {-1} else {1};
    _steps = 1 max (floor _steps);
    private _cursor = _start;
    private _moved = 0;
    private _guard = 0;
    while {_moved < _steps && {_guard < (_count * (_steps + 1))}} do {
        _cursor = (_cursor + _direction) mod _count;
        if (_cursor < 0) then {_cursor = _cursor + _count;};
        if (_activeFlags param [_cursor, false]) then {_moved = _moved + 1;};
        _guard = _guard + 1;
    };
    if (_moved == _steps) then {_cursor} else {-1}
};


Waldo_MG_fnc_unoCreateEmptySnapshot = {
    [
        "IDLE", -1, -1, 1, [], 0, 0, [], [], -1, 0, -1, [], -1, -1,
        "Waiting for an UNO match.", [], [], 0, 0
    ]
};

Waldo_MG_fnc_unoPublishRevisionServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    _table setVariable [
        "Waldo_MG_UNORevision",
        (_table getVariable ["Waldo_MG_UNORevision", 0]) + 1,
        true
    ];
    _table setVariable [
        "Waldo_MG_TableRevision",
        (_table getVariable ["Waldo_MG_TableRevision", 0]) + 1,
        true
    ];
};

Waldo_MG_fnc_unoRefreshSnapshotCountsServer = {
    params [
        ["_table", objNull],
        ["_snapshot", []]
    ];
    if (!isServer || {isNull _table}) exitWith {_snapshot};
    private _state = +_snapshot;
    private _hands = _table getVariable ["Waldo_MG_UNOHandsServer", []];
    private _counts = [];
    {
        _counts pushBack (if ((typeName _x) == "ARRAY") then {count _x} else {0});
    } forEach _hands;
    _state set [6, count (_table getVariable ["Waldo_MG_UNODeckServer", []])];
    _state set [7, _counts];
    _state set [16, +(_table getVariable ["Waldo_MG_UNOHandVersionsServer", []])];
    _state
};

Waldo_MG_fnc_unoSetSnapshotServer = {
    params [
        ["_table", objNull],
        ["_snapshot", []]
    ];
    if (!isServer || {isNull _table}) exitWith {};
    private _state = [_table, _snapshot] call Waldo_MG_fnc_unoRefreshSnapshotCountsServer;
    _table setVariable ["Waldo_MG_UNOSnapshotServer", _state];
    _table setVariable ["Waldo_MG_UNOSnapshot", _state, true];
    [_table] call Waldo_MG_fnc_unoPublishRevisionServer;
};

Waldo_MG_fnc_unoBumpHandVersionServer = {
    params [
        ["_table", objNull],
        ["_role", -1]
    ];
    if (!isServer || {isNull _table} || {_role < 0}) exitWith {-1};
    private _versions = +(_table getVariable ["Waldo_MG_UNOHandVersionsServer", []]);
    if (_role >= (count _versions)) exitWith {-1};
    private _version = (_versions param [_role, 0]) + 1;
    _versions set [_role, _version];
    _table setVariable ["Waldo_MG_UNOHandVersionsServer", _versions];
    _version
};

Waldo_MG_fnc_unoSendPrivateHandServer = {
    params [
        ["_table", objNull],
        ["_role", -1]
    ];
    if (!isServer || {isNull _table} || {_role < 0}) exitWith {};
    private _players = _table getVariable ["Waldo_MG_UNOPlayers", []];
    if (_role >= (count _players)) exitWith {};
    private _recipient = _players param [_role, objNull];
    if (isNull _recipient) exitWith {};
    private _hands = _table getVariable ["Waldo_MG_UNOHandsServer", []];
    private _versions = _table getVariable ["Waldo_MG_UNOHandVersionsServer", []];
    private _justDrawn = _table getVariable ["Waldo_MG_UNOJustDrawnIdsServer", []];
    private _payload = [
        _table getVariable ["Waldo_MG_UNOGameId", ""],
        _versions param [_role, 0],
        +(_hands param [_role, []]),
        _justDrawn param [_role, -1]
    ];
    _recipient setVariable ["Waldo_MG_UNOPrivateHand", _payload, owner _recipient];
};

Waldo_MG_fnc_unoSendPrivateHandsServer = {
    params [
        ["_table", objNull],
        ["_roles", []]
    ];
    if (!isServer || {isNull _table}) exitWith {};
    {
        if ((typeName _x) == "SCALAR") then {
            [_table, floor _x] call Waldo_MG_fnc_unoSendPrivateHandServer;
        };
    } forEach _roles;
};

Waldo_MG_fnc_unoClearPrivateHandsServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    {
        if (!isNull _x) then {
            _x setVariable ["Waldo_MG_UNOPrivateHand", [], owner _x];
        };
    } forEach (_table getVariable ["Waldo_MG_UNOPlayers", []]);
};

Waldo_MG_fnc_unoDrawCardsServer = {
    params [
        ["_table", objNull],
        ["_role", -1],
        ["_requested", 1]
    ];
    if (!isServer || {isNull _table} || {_role < 0}) exitWith {[0, -1]};
    private _hands = +(_table getVariable ["Waldo_MG_UNOHandsServer", []]);
    if (_role >= (count _hands)) exitWith {[0, -1]};
    private _hand = +(_hands param [_role, []]);
    private _deck = +(_table getVariable ["Waldo_MG_UNODeckServer", []]);
    private _discard = +(_table getVariable ["Waldo_MG_UNODiscardServer", []]);
    private _drawn = 0;
    private _lastId = -1;
    private _target = 0 max (floor _requested);
    while {_drawn < _target} do {
        if ((count _deck) <= 0 && {(count _discard) > 1}) then {
            private _top = _discard deleteAt ((count _discard) - 1);
            _deck = [_discard] call Waldo_MG_fnc_unoShuffleCardsServer;
            _discard = [_top];
        };
        if ((count _deck) <= 0) exitWith {};
        private _card = _deck deleteAt ((count _deck) - 1);
        _hand pushBack _card;
        _lastId = _card param [0, -1];
        _drawn = _drawn + 1;
    };
    _hands set [_role, _hand];
    _table setVariable ["Waldo_MG_UNOHandsServer", _hands];
    _table setVariable ["Waldo_MG_UNODeckServer", _deck];
    _table setVariable ["Waldo_MG_UNODiscardServer", _discard];
    if (_drawn > 0) then {[_table, _role] call Waldo_MG_fnc_unoBumpHandVersionServer;};
    [_drawn, _lastId]
};

Waldo_MG_fnc_unoClearServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    [_table] call Waldo_MG_fnc_unoClearPrivateHandsServer;
    _table setVariable ["Waldo_MG_UNOActive", false, true];
    _table setVariable ["Waldo_MG_UNOFinished", false, true];
    _table setVariable ["Waldo_MG_UNOGameId", "", true];
    _table setVariable ["Waldo_MG_UNOPlayers", [], true];
    _table setVariable ["Waldo_MG_UNOPlayerNames", [], true];
    _table setVariable ["Waldo_MG_UNOSeatIndices", [], true];
    _table setVariable ["Waldo_MG_UNOHandsServer", []];
    _table setVariable ["Waldo_MG_UNODeckServer", []];
    _table setVariable ["Waldo_MG_UNODiscardServer", []];
    _table setVariable ["Waldo_MG_UNOHandVersionsServer", []];
    _table setVariable ["Waldo_MG_UNOJustDrawnIdsServer", []];
    private _snapshot = call Waldo_MG_fnc_unoCreateEmptySnapshot;
    _table setVariable ["Waldo_MG_UNOSnapshotServer", _snapshot];
    _table setVariable ["Waldo_MG_UNOSnapshot", _snapshot, true];
    [_table] call Waldo_MG_fnc_unoPublishRevisionServer;
};

Waldo_MG_fnc_unoStartServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {false};
    if ([_table] call Waldo_MG_fnc_isTableGameActive) exitWith {false};
    if ((_table getVariable ["Waldo_MG_TableSelectedGame", ""]) != "uno") exitWith {false};
    if ((_table getVariable ["Waldo_MG_TablePhase", "LOBBY"]) != "READY") exitWith {false};
    private _seats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
    private _players = [];
    private _seatIndices = [];
    for "_index" from 0 to (Waldo_MG_CFG_SEAT_COUNT - 1) do {
        private _unit = _seats param [_index, objNull];
        if (!isNull _unit) then {
            _players pushBack _unit;
            _seatIndices pushBack _index;
        };
    };
    private _playerCount = count _players;
    if (_playerCount < 2 || {_playerCount > 4}) exitWith {false};

    [_table] call Waldo_MG_fnc_unoClearPrivateHandsServer;
    private _deck = call Waldo_MG_fnc_unoCreateShuffledDeckServer;
    private _hands = [];
    private _names = [];
    private _statuses = [];
    private _actions = [];
    private _activeFlags = [];
    private _versions = [];
    private _justDrawn = [];
    private _armed = [];
    for "_role" from 0 to (_playerCount - 1) do {
        _hands pushBack [];
        _names pushBack (name (_players param [_role, objNull]));
        _statuses pushBack "ACTIVE";
        _actions pushBack "Ready";
        _activeFlags pushBack true;
        _versions pushBack 1;
        _justDrawn pushBack -1;
        _armed pushBack false;
    };
    for "_round" from 1 to Waldo_MG_CFG_UNO_STARTING_CARDS do {
        for "_role" from 0 to (_playerCount - 1) do {
            private _hand = +(_hands param [_role, []]);
            _hand pushBack (_deck deleteAt ((count _deck) - 1));
            _hands set [_role, _hand];
        };
    };

    private _deferredWilds = [];
    private _topCard = [];
    while {(count _deck) > 0 && {(count _topCard) <= 0}} do {
        private _candidate = _deck deleteAt ((count _deck) - 1);
        if ((_candidate param [2, -1]) in [14, 15]) then {
            _deferredWilds pushBack _candidate;
        } else {
            _topCard = _candidate;
        };
    };
    _deck append _deferredWilds;
    _deck = [_deck] call Waldo_MG_fnc_unoShuffleCardsServer;
    if ((count _topCard) <= 0) exitWith {false};

    private _dealer = floor (random _playerCount);
    private _direction = 1;
    private _turn = [_dealer, _direction, _activeFlags, 1] call Waldo_MG_fnc_unoGetNextActiveRole;
    private _pendingKind = -1;
    private _pendingAmount = 0;
    private _topKind = _topCard param [2, -1];
    private _status = format [
        "%1 begins in ascending player order. %2 is on the discard pile.",
        _names param [_turn, "Player"],
        [_topCard] call Waldo_MG_fnc_unoCardName
    ];
    if (_topKind == 11) then {
        private _skipped = _turn;
        _turn = [_turn, _direction, _activeFlags, 1] call Waldo_MG_fnc_unoGetNextActiveRole;
        _status = format ["Opening Block skips %1. %2 begins.", _names param [_skipped, "Player"], _names param [_turn, "Player"]];
    };
    if (_topKind == 12) then {
        _direction = -1;
        _turn = _dealer;
        _status = format ["Opening Reverse starts descending player order. %1 begins.", _names param [_turn, "Player"]];
    };
    if (_topKind == 13) then {
        _pendingKind = 13;
        _pendingAmount = 2;
        _status = format ["Opening +2 targets %1. Stack another +2 or draw two.", _names param [_turn, "Player"]];
    };

    _table setVariable ["Waldo_MG_UNOActive", true, true];
    _table setVariable ["Waldo_MG_UNOFinished", false, true];
    _table setVariable [
        "Waldo_MG_UNOGameId",
        format ["Waldo_MG_UNO_%1_%2", floor (serverTime * 10), floor (random 1000000)],
        true
    ];
    _table setVariable ["Waldo_MG_UNOPlayers", _players, true];
    _table setVariable ["Waldo_MG_UNOPlayerNames", _names, true];
    _table setVariable ["Waldo_MG_UNOSeatIndices", _seatIndices, true];
    _table setVariable ["Waldo_MG_UNOHandsServer", _hands];
    _table setVariable ["Waldo_MG_UNODeckServer", _deck];
    _table setVariable ["Waldo_MG_UNODiscardServer", [_topCard]];
    _table setVariable ["Waldo_MG_UNOHandVersionsServer", _versions];
    _table setVariable ["Waldo_MG_UNOJustDrawnIdsServer", _justDrawn];
    private _snapshot = [
        "PLAYING", _dealer, _turn, _direction, _topCard, _topCard param [1, 0],
        count _deck, [], _statuses, _pendingKind, _pendingAmount, -1,
        _actions, -1, -1, _status, _versions, _armed, 0, 0
    ];
    _snapshot = [_table, _snapshot] call Waldo_MG_fnc_unoRefreshSnapshotCountsServer;
    _table setVariable ["Waldo_MG_UNOSnapshotServer", _snapshot];
    _table setVariable ["Waldo_MG_UNOSnapshot", _snapshot, true];
    _table setVariable ["Waldo_MG_TableSelectedGame", "uno", true];
    _table setVariable ["Waldo_MG_TablePhase", "PLAYING", true];
    [_table] call Waldo_MG_fnc_unoPublishRevisionServer;
    [_table, [0, 1, 2, 3]] call Waldo_MG_fnc_unoSendPrivateHandsServer;
    true
};

Waldo_MG_fnc_unoFinishServer = {
    params [
        ["_table", objNull],
        ["_snapshot", []],
        ["_winnerRole", -1],
        ["_status", "UNO finished."],
        ["_changedRoles", []]
    ];
    if (!isServer || {isNull _table}) exitWith {};
    private _state = +_snapshot;
    private _statuses = +(_state param [8, []]);
    if (_winnerRole >= 0 && {_winnerRole < (count _statuses)}) then {
        _statuses set [_winnerRole, "WINNER"];
    };
    _state set [0, "FINISHED"];
    _state set [2, -1];
    _state set [8, _statuses];
    _state set [9, -1];
    _state set [10, 0];
    _state set [11, -1];
    _state set [13, -1];
    _state set [14, _winnerRole];
    _state set [15, _status];
    _table setVariable ["Waldo_MG_UNOFinished", true, true];
    _table setVariable ["Waldo_MG_TablePhase", "FINISHED", true];
    [_table, _state] call Waldo_MG_fnc_unoSetSnapshotServer;
    [_table, _changedRoles] call Waldo_MG_fnc_unoSendPrivateHandsServer;
};

Waldo_MG_fnc_unoHandleDepartureServer = {
    params [
        ["_table", objNull],
        ["_departing", objNull],
        ["_seatIndex", -1]
    ];
    if (!isServer || {isNull _table} || {!(_table getVariable ["Waldo_MG_UNOActive", false])}) exitWith {};
    private _players = _table getVariable ["Waldo_MG_UNOPlayers", []];
    private _seatIndices = _table getVariable ["Waldo_MG_UNOSeatIndices", []];
    private _role = if (isNull _departing) then {
        _seatIndices find _seatIndex
    } else {
        _players find _departing
    };
    if (_role < 0) then {_role = _seatIndices find _seatIndex;};
    if (_role < 0) exitWith {};
    private _state = +(_table getVariable ["Waldo_MG_UNOSnapshotServer", []]);
    private _matchWasFinished = (_state param [0, "IDLE"]) == "FINISHED";
    private _activeFlags = +(_state param [8, []]);
    private _statuses = +_activeFlags;
    for "_index" from 0 to ((count _activeFlags) - 1) do {
        _activeFlags set [_index, (_statuses param [_index, "LEFT"]) != "LEFT"];
    };
    if (!(_activeFlags param [_role, false])) exitWith {};

    private _hands = +(_table getVariable ["Waldo_MG_UNOHandsServer", []]);
    private _deck = +(_table getVariable ["Waldo_MG_UNODeckServer", []]);
    _deck append +(_hands param [_role, []]);
    _deck = [_deck] call Waldo_MG_fnc_unoShuffleCardsServer;
    _hands set [_role, []];
    _table setVariable ["Waldo_MG_UNOHandsServer", _hands];
    _table setVariable ["Waldo_MG_UNODeckServer", _deck];
    [_table, _role] call Waldo_MG_fnc_unoBumpHandVersionServer;
    if (!isNull _departing) then {
        _departing setVariable ["Waldo_MG_UNOPrivateHand", [], owner _departing];
    };

    _statuses set [_role, "LEFT"];
    _activeFlags set [_role, false];
    private _actions = +(_state param [12, []]);
    _actions set [_role, "Left table"];
    private _armed = +(_state param [17, []]);
    _armed set [_role, false];
    private _turn = _state param [2, -1];
    private _direction = _state param [3, 1];
    if ((_state param [13, -1]) == _role) then {_state set [13, -1];};
    if ((_state param [11, -1]) == _role) then {_state set [11, -1];};
    if (_turn == _role) then {
        _state set [9, -1];
        _state set [10, 0];
        _turn = [_role, _direction, _activeFlags, 1] call Waldo_MG_fnc_unoGetNextActiveRole;
        _state set [2, _turn];
    };
    _state set [8, _statuses];
    _state set [12, _actions];
    _state set [17, _armed];
    if (!_matchWasFinished) then {
        _state set [15, format ["%1 left the UNO table.", if (isNull _departing) then {"A player"} else {name _departing}]];
    };
    private _remaining = [_activeFlags] call Waldo_MG_fnc_unoCountActiveRoles;
    if (_remaining <= 0) exitWith {
        [_table] call Waldo_MG_fnc_unoClearServer;
        _table setVariable ["Waldo_MG_TableReady", [false, false, false, false], true];
        _table setVariable ["Waldo_MG_TablePhase", "LOBBY", true];
    };
    if (_remaining == 1 && {!_matchWasFinished}) exitWith {
        private _winner = _activeFlags find true;
        private _names = _table getVariable ["Waldo_MG_UNOPlayerNames", []];
        [_table, _state, _winner, format ["%1 wins UNO by forfeit.", _names param [_winner, "Player"]], []] call Waldo_MG_fnc_unoFinishServer;
    };
    [_table, _state] call Waldo_MG_fnc_unoSetSnapshotServer;
};

Waldo_MG_fnc_unoReconcilePlayersServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table} || {!(_table getVariable ["Waldo_MG_UNOActive", false])}) exitWith {};
    private _players = +(_table getVariable ["Waldo_MG_UNOPlayers", []]);
    private _seatIndices = _table getVariable ["Waldo_MG_UNOSeatIndices", []];
    private _seats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
    for "_role" from 0 to ((count _players) - 1) do {
        private _unit = _players param [_role, objNull];
        private _seat = _seatIndices param [_role, -1];
        private _valid = !isNull _unit
            && {_seat >= 0}
            && {_seat < Waldo_MG_CFG_SEAT_COUNT}
            && {(_seats param [_seat, objNull]) == _unit}
            && {_unit in allPlayers}
            && {alive _unit}
            && {(lifeState _unit) != "INCAPACITATED"}
            && {(vehicle _unit) == _unit};
        if (!_valid) then {
            [_table, _unit, _seat] call Waldo_MG_fnc_unoHandleDepartureServer;
        };
    };
};

Waldo_MG_fnc_unoResetServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    [_table] call Waldo_MG_fnc_unoClearServer;
    _table setVariable ["Waldo_MG_TableReady", [false, false, false, false], true];
    [_table] call Waldo_MG_fnc_refreshTableConsensusServer;
};

Waldo_MG_fnc_processUNOActionRequestServer = {
    params [
        ["_unit", objNull],
        ["_request", []]
    ];
    if (!isServer || {isNull _unit}) exitWith {};
    _unit setVariable ["Waldo_MG_UNOActionRequest", [], true];
    if ((count _request) < 6) exitWith {};
    private _token = _request param [0, ""];
    if (!([_token] call Waldo_MG_fnc_rememberHandledTokenServer)) exitWith {};
    private _tableNetId = _request param [1, ""];
    private _gameId = _request param [2, ""];
    private _expectedRevision = _request param [3, -1];
    private _action = _request param [4, ""];
    private _payload = _request param [5, []];
    if (
        (typeName _tableNetId) != "STRING"
        || {(typeName _gameId) != "STRING"}
        || {(typeName _expectedRevision) != "SCALAR"}
        || {(typeName _action) != "STRING"}
        || {(typeName _payload) != "ARRAY"}
    ) exitWith {
        [_unit, _token, "UNO action rejected: malformed request data."] call Waldo_MG_fnc_resultServer;
    };
    if (_expectedRevision != (floor _expectedRevision)) exitWith {
        [_unit, _token, "UNO action rejected: revision must be a whole number."] call Waldo_MG_fnc_resultServer;
    };
    private _table = objectFromNetId _tableNetId;
    if (isNull _table || {_table != (_unit getVariable ["Waldo_MG_SeatedTable", objNull])}) exitWith {
        [_unit, _token, "UNO action rejected: you are no longer seated at that table."] call Waldo_MG_fnc_resultServer;
    };
    if (!(_table getVariable ["Waldo_MG_UNOActive", false])) exitWith {
        [_unit, _token, "There is no active UNO match at this table."] call Waldo_MG_fnc_resultServer;
    };
    if (_gameId != (_table getVariable ["Waldo_MG_UNOGameId", ""])) exitWith {
        [_unit, _token, "That UNO session has already changed."] call Waldo_MG_fnc_resultServer;
    };
    private _players = _table getVariable ["Waldo_MG_UNOPlayers", []];
    private _role = _players find _unit;
    if (_role < 0) exitWith {
        [_unit, _token, "Only assigned UNO players may use this table."] call Waldo_MG_fnc_resultServer;
    };
    private _state = +(_table getVariable ["Waldo_MG_UNOSnapshotServer", []]);
    private _phase = _state param [0, "IDLE"];
    if (_action == "SYNC_HAND") exitWith {
        [_table, _role] call Waldo_MG_fnc_unoSendPrivateHandServer;
        [_unit, _token, "Your private UNO hand was synchronized."] call Waldo_MG_fnc_resultServer;
    };
    if (_action == "RESET") exitWith {
        if (!(_table getVariable ["Waldo_MG_UNOFinished", false])) then {
            [_unit, _token, "Finish the UNO match before returning to the lobby."] call Waldo_MG_fnc_resultServer;
        } else {
            [_table] call Waldo_MG_fnc_unoResetServer;
            [_unit, _token, "UNO cleared. The table has returned to its lobby."] call Waldo_MG_fnc_resultServer;
        };
    };
    if (_phase != "PLAYING" || {_table getVariable ["Waldo_MG_UNOFinished", false]}) exitWith {
        [_unit, _token, "That UNO match is no longer accepting plays."] call Waldo_MG_fnc_resultServer;
    };
    private _revision = _table getVariable ["Waldo_MG_UNORevision", 0];
    if (_expectedRevision != _revision) exitWith {
        [_unit, _token, "The UNO table changed before that action arrived. Please act again."] call Waldo_MG_fnc_resultServer;
    };
    private _statuses = +(_state param [8, []]);
    if ((_statuses param [_role, "LEFT"]) == "LEFT") exitWith {
        [_unit, _token, "Your UNO role is no longer active."] call Waldo_MG_fnc_resultServer;
    };
    private _hands = +(_table getVariable ["Waldo_MG_UNOHandsServer", []]);
    private _hand = +(_hands param [_role, []]);
    private _actions = +(_state param [12, []]);
    private _armed = +(_state param [17, []]);

    if (_action == "UNO") exitWith {
        private _vulnerable = _state param [13, -1];
        if (_vulnerable == _role && {(count _hand) == 1}) then {
            _state set [13, -1];
            _armed set [_role, false];
            _actions set [_role, "UNO!"];
            _state set [12, _actions];
            _state set [15, format ["%1 called UNO before anyone caught them.", name _unit]];
            _state set [17, _armed];
            [_table, _state] call Waldo_MG_fnc_unoSetSnapshotServer;
            [_unit, _token, "UNO called in time."] call Waldo_MG_fnc_resultServer;
        } else {
            if ((_state param [2, -1]) != _role) then {
                [_unit, _token, "You may arm UNO on your turn, or call it while you are vulnerable."] call Waldo_MG_fnc_resultServer;
            } else {
                _armed set [_role, true];
                _actions set [_role, "UNO armed"];
                _state set [12, _actions];
                _state set [15, format ["%1 armed UNO for their next play.", name _unit]];
                _state set [17, _armed];
                [_table, _state] call Waldo_MG_fnc_unoSetSnapshotServer;
                [_unit, _token, "UNO armed. Now play the card that will leave you with one."] call Waldo_MG_fnc_resultServer;
            };
        };
    };

    if (_action == "CALLOUT") exitWith {
        private _offender = _state param [13, -1];
        if (_offender < 0 || {_offender == _role} || {(_statuses param [_offender, "LEFT"]) == "LEFT"}) then {
            [_unit, _token, "There is currently nobody you can call out."] call Waldo_MG_fnc_resultServer;
        } else {
            private _drawResult = [_table, _offender, Waldo_MG_CFG_UNO_CALLOUT_PENALTY] call Waldo_MG_fnc_unoDrawCardsServer;
            private _drawn = _drawResult param [0, 0];
            private _justDrawn = +(_table getVariable ["Waldo_MG_UNOJustDrawnIdsServer", []]);
            _justDrawn set [_offender, -1];
            _table setVariable ["Waldo_MG_UNOJustDrawnIdsServer", _justDrawn];
            private _names = _table getVariable ["Waldo_MG_UNOPlayerNames", []];
            _state set [13, -1];
            _armed set [_offender, false];
            _actions set [_role, format ["Called out %1", _names param [_offender, "Player"]]];
            _actions set [_offender, format ["Caught: drew %1", _drawn]];
            _state set [12, _actions];
            _state set [15, format ["%1 caught %2 without UNO. The penalty is %3 cards.", name _unit, _names param [_offender, "Player"], _drawn]];
            _state set [17, _armed];
            [_table, _state] call Waldo_MG_fnc_unoSetSnapshotServer;
            [_table, [_offender]] call Waldo_MG_fnc_unoSendPrivateHandsServer;
            [_unit, _token, format ["Callout accepted. %1 drew %2 cards.", _names param [_offender, "Player"], _drawn]] call Waldo_MG_fnc_resultServer;
        };
    };

    if (!alive _unit || {(lifeState _unit) == "INCAPACITATED"} || {(vehicle _unit) != _unit}) exitWith {
        [_unit, _token, "You cannot act at the UNO table in your current state."] call Waldo_MG_fnc_resultServer;
    };
    private _turn = _state param [2, -1];
    if (_turn != _role) exitWith {
        [_unit, _token, "It is another player's turn."] call Waldo_MG_fnc_resultServer;
    };

    if ((_state param [13, -1]) >= 0) then {
        _state set [13, -1];
    };
    private _direction = _state param [3, 1];
    private _activeFlags = [];
    {
        _activeFlags pushBack (_x != "LEFT");
    } forEach _statuses;
    private _pendingKind = _state param [9, -1];
    private _pendingAmount = _state param [10, 0];
    private _drawnRole = _state param [11, -1];
    private _justDrawnIds = +(_table getVariable ["Waldo_MG_UNOJustDrawnIdsServer", []]);

    if (_action == "DRAW") exitWith {
        if (_drawnRole == _role) then {
            [_unit, _token, "Play the newly drawn card or press Pass."] call Waldo_MG_fnc_resultServer;
        } else {
            _armed set [_role, false];
            if (_pendingAmount > 0 && {_pendingKind in [13, 15]}) then {
                private _drawResult = [_table, _role, _pendingAmount] call Waldo_MG_fnc_unoDrawCardsServer;
                private _drawn = _drawResult param [0, 0];
                _justDrawnIds = +(_table getVariable ["Waldo_MG_UNOJustDrawnIdsServer", []]);
                _justDrawnIds set [_role, -1];
                _table setVariable ["Waldo_MG_UNOJustDrawnIdsServer", _justDrawnIds];
                _actions set [_role, format ["Accepted +%1", _drawn]];
                _turn = [_role, _direction, _activeFlags, 1] call Waldo_MG_fnc_unoGetNextActiveRole;
                _state set [2, _turn];
                _state set [9, -1];
                _state set [10, 0];
                _state set [11, -1];
                _state set [12, _actions];
                _state set [15, format ["%1 drew %2 cards and was skipped.", name _unit, _drawn]];
                _state set [17, _armed];
                _state set [18, 0];
                _state set [19, (_state param [19, 0]) + 1];
                [_table, _state] call Waldo_MG_fnc_unoSetSnapshotServer;
                [_table, [_role]] call Waldo_MG_fnc_unoSendPrivateHandsServer;
                [_unit, _token, format ["Draw chain accepted: %1 cards drawn.", _drawn]] call Waldo_MG_fnc_resultServer;
            } else {
                private _drawResult = [_table, _role, 1] call Waldo_MG_fnc_unoDrawCardsServer;
                private _drawn = _drawResult param [0, 0];
                private _drawnId = _drawResult param [1, -1];
                if (_drawn <= 0) then {
                    private _hasLegalCard = false;
                    {
                        if ([_x, _hand, _state param [4, []], _state param [5, -1], -1] call Waldo_MG_fnc_unoCanPlayFromHand) then {
                            _hasLegalCard = true;
                        };
                    } forEach _hand;
                    if (_hasLegalCard) then {
                        _actions set [_role, "Must play a held card"];
                        _state set [11, -1];
                        _state set [12, _actions];
                        _state set [15, format ["The draw pile is empty, but %1 still has a legal play.", name _unit]];
                        _state set [17, _armed];
                        _state set [18, 0];
                        [_table, _state] call Waldo_MG_fnc_unoSetSnapshotServer;
                        [_unit, _token, "The pile is empty, but you hold a playable card. Play it to continue."] call Waldo_MG_fnc_resultServer;
                    } else {
                        private _noProgress = (_state param [18, 0]) + 1;
                        _turn = [_role, _direction, _activeFlags, 1] call Waldo_MG_fnc_unoGetNextActiveRole;
                        _actions set [_role, "No card available"];
                        _state set [2, _turn];
                        _state set [11, -1];
                        _state set [12, _actions];
                        _state set [15, format ["The pile could not produce a card and %1 has no legal play. The turn advances.", name _unit]];
                        _state set [17, _armed];
                        _state set [18, _noProgress];
                        _state set [19, (_state param [19, 0]) + 1];
                        if (_noProgress >= ([_activeFlags] call Waldo_MG_fnc_unoCountActiveRoles)) then {
                            [_table, _state, -1, "UNO ends in a draw: no drawable or playable cards remain.", []] call Waldo_MG_fnc_unoFinishServer;
                        } else {
                            [_table, _state] call Waldo_MG_fnc_unoSetSnapshotServer;
                        };
                        [_unit, _token, "No card was available and you had no legal play; your turn passed."] call Waldo_MG_fnc_resultServer;
                    };
                } else {
                    _hands = +(_table getVariable ["Waldo_MG_UNOHandsServer", []]);
                    _hand = +(_hands param [_role, []]);
                    private _drawnCard = [];
                    {
                        if ((_x param [0, -2]) == _drawnId) exitWith {_drawnCard = _x;};
                    } forEach _hand;
                    private _playable = [_drawnCard, _hand, _state param [4, []], _state param [5, -1], -1] call Waldo_MG_fnc_unoCanPlayFromHand;
                    _justDrawnIds = +(_table getVariable ["Waldo_MG_UNOJustDrawnIdsServer", []]);
                    if (_playable) then {
                        _justDrawnIds set [_role, _drawnId];
                        _state set [11, _role];
                        _actions set [_role, "Drew a playable card"];
                        _state set [15, format ["%1 drew one card and may play only that card, or Pass.", name _unit]];
                    } else {
                        _justDrawnIds set [_role, -1];
                        _turn = [_role, _direction, _activeFlags, 1] call Waldo_MG_fnc_unoGetNextActiveRole;
                        _state set [2, _turn];
                        _state set [11, -1];
                        _actions set [_role, "Drew and passed"];
                        _state set [15, format ["%1 drew an unplayable card. The turn advances.", name _unit]];
                    };
                    _table setVariable ["Waldo_MG_UNOJustDrawnIdsServer", _justDrawnIds];
                    _state set [12, _actions];
                    _state set [17, _armed];
                    _state set [18, 0];
                    _state set [19, (_state param [19, 0]) + 1];
                    [_table, _state] call Waldo_MG_fnc_unoSetSnapshotServer;
                    [_table, [_role]] call Waldo_MG_fnc_unoSendPrivateHandsServer;
                    [_unit, _token, if (_playable) then {"Card drawn. Play that card or press Pass."} else {"Card drawn; it was not playable, so your turn passed."}] call Waldo_MG_fnc_resultServer;
                };
            };
        };
    };

    if (_action == "PASS") exitWith {
        if (_drawnRole != _role) then {
            [_unit, _token, "Pass is available only after drawing a playable card."] call Waldo_MG_fnc_resultServer;
        } else {
            _turn = [_role, _direction, _activeFlags, 1] call Waldo_MG_fnc_unoGetNextActiveRole;
            _justDrawnIds set [_role, -1];
            _table setVariable ["Waldo_MG_UNOJustDrawnIdsServer", _justDrawnIds];
            _armed set [_role, false];
            _actions set [_role, "Passed drawn card"];
            _state set [2, _turn];
            _state set [11, -1];
            _state set [12, _actions];
            _state set [15, format ["%1 kept the drawn card and passed.", name _unit]];
            _state set [17, _armed];
            _state set [18, 0];
            _state set [19, (_state param [19, 0]) + 1];
            [_table, _state] call Waldo_MG_fnc_unoSetSnapshotServer;
            [_table, [_role]] call Waldo_MG_fnc_unoSendPrivateHandsServer;
            [_unit, _token, "Turn passed."] call Waldo_MG_fnc_resultServer;
        };
    };

    if (_action != "PLAY") exitWith {
        [_unit, _token, "Unknown UNO action."] call Waldo_MG_fnc_resultServer;
    };
    if ((count _payload) < 2) exitWith {
        [_unit, _token, "UNO play rejected: select a card first."] call Waldo_MG_fnc_resultServer;
    };
    private _cardIds = _payload param [0, []];
    private _chosenColour = _payload param [1, -1];
    if ((typeName _cardIds) != "ARRAY" || {(typeName _chosenColour) != "SCALAR"}) exitWith {
        [_unit, _token, "UNO play rejected: malformed card selection."] call Waldo_MG_fnc_resultServer;
    };
    if ((count _cardIds) <= 0 || {(count _cardIds) > 2}) exitWith {
        [_unit, _token, "Select one card, or two exact duplicate numbered cards."] call Waldo_MG_fnc_resultServer;
    };
    if (_chosenColour != (floor _chosenColour)) exitWith {
        [_unit, _token, "UNO colour choice must be a whole number."] call Waldo_MG_fnc_resultServer;
    };
    private _uniqueIds = [];
    private _selectedCards = [];
    private _selectedIndexes = [];
    private _selectionValid = true;
    {
        if ((typeName _x) != "SCALAR" || {_x != (floor _x)} || {_x in _uniqueIds}) then {
            _selectionValid = false;
        } else {
            _uniqueIds pushBack _x;
            private _foundIndex = -1;
            for "_handIndex" from 0 to ((count _hand) - 1) do {
                if (_foundIndex < 0 && {((_hand param [_handIndex, []]) param [0, -2]) == _x}) then {
                    _foundIndex = _handIndex;
                };
            };
            if (_foundIndex < 0) then {
                _selectionValid = false;
            } else {
                _selectedIndexes pushBack _foundIndex;
                _selectedCards pushBack +(_hand param [_foundIndex, []]);
            };
        };
    } forEach _cardIds;
    if (!_selectionValid) exitWith {
        [_unit, _token, "UNO play rejected: a selected card is stale or not in your hand."] call Waldo_MG_fnc_resultServer;
    };
    private _firstCard = _selectedCards param [0, []];
    private _firstColour = _firstCard param [1, -1];
    private _firstKind = _firstCard param [2, -1];
    if ((count _selectedCards) > 1) then {
        if (_firstKind < 0 || {_firstKind > 10}) then {_selectionValid = false;};
        {
            if ((_x param [1, -2]) != _firstColour || {(_x param [2, -2]) != _firstKind}) then {
                _selectionValid = false;
            };
        } forEach _selectedCards;
    };
    if (!_selectionValid) exitWith {
        [_unit, _token, "Only exact duplicate numbered cards may be played together."] call Waldo_MG_fnc_resultServer;
    };
    if (
        _drawnRole == _role
        && {
            (count _cardIds) != 1
            || {(_cardIds param [0, -2]) != (_justDrawnIds param [_role, -1])}
        }
    ) exitWith {
        [_unit, _token, "After drawing, you may play only the newly drawn card."] call Waldo_MG_fnc_resultServer;
    };
    if (!([_firstCard, _state param [4, []], _state param [5, -1], _pendingKind] call Waldo_MG_fnc_unoCanPlayCard)) exitWith {
        [_unit, _token, if (_pendingKind == 13) then {"A +2 chain accepts only another +2."} else {if (_pendingKind == 15) then {"A +4 chain accepts only another +4."} else {"That card does not match the active colour or symbol."}}] call Waldo_MG_fnc_resultServer;
    };
    if (!([_firstCard, _hand, _state param [4, []], _state param [5, -1], _pendingKind] call Waldo_MG_fnc_unoCanPlayFromHand)) exitWith {
        [_unit, _token, "+4 is legal only when you hold no card of the active colour."] call Waldo_MG_fnc_resultServer;
    };
    if (_firstKind in [14, 15] && {!(_chosenColour in [0, 1, 2, 3])}) exitWith {
        [_unit, _token, "Choose Red, Blue, Green, or Yellow for the Wild card."] call Waldo_MG_fnc_resultServer;
    };
    _selectedIndexes sort false;
    {
        _hand deleteAt _x;
    } forEach _selectedIndexes;
    _hands set [_role, _hand];
    _table setVariable ["Waldo_MG_UNOHandsServer", _hands];
    [_table, _role] call Waldo_MG_fnc_unoBumpHandVersionServer;
    _justDrawnIds set [_role, -1];
    _table setVariable ["Waldo_MG_UNOJustDrawnIdsServer", _justDrawnIds];
    private _discard = +(_table getVariable ["Waldo_MG_UNODiscardServer", []]);
    {_discard pushBack _x;} forEach _selectedCards;
    _table setVariable ["Waldo_MG_UNODiscardServer", _discard];
    private _topCard = _selectedCards param [(count _selectedCards) - 1, _firstCard];
    private _activeColour = if (_firstKind in [14, 15]) then {_chosenColour} else {_firstColour};
    private _playedName = [_topCard, _activeColour] call Waldo_MG_fnc_unoCardName;
    private _hadUNOArmed = _armed param [_role, false];
    _armed set [_role, false];
    private _remainingCards = count _hand;
    private _vulnerable = -1;
    private _unoText = "";
    if (_remainingCards == 1) then {
        if (_hadUNOArmed) then {
            _unoText = " UNO!";
        } else {
            _vulnerable = _role;
            _unoText = " UNO was not called!";
        };
    };
    _actions set [_role, format ["Played %1%2", _playedName, _unoText]];
    _state set [4, _topCard];
    _state set [5, _activeColour];
    _state set [11, -1];
    _state set [12, _actions];
    _state set [13, _vulnerable];
    _state set [17, _armed];
    _state set [18, 0];
    _state set [19, (_state param [19, 0]) + 1];

    if (_remainingCards <= 0) exitWith {
        private _changedRoles = [_role];
        if (_firstKind in [13, 15]) then {
            private _finalPenalty = if (_firstKind == 13) then {2} else {4};
            if (_pendingKind == _firstKind) then {_finalPenalty = _finalPenalty + _pendingAmount;};
            private _victim = [_role, _direction, _activeFlags, 1] call Waldo_MG_fnc_unoGetNextActiveRole;
            if (_victim >= 0 && {_victim != _role}) then {
                private _drawResult = [_table, _victim, _finalPenalty] call Waldo_MG_fnc_unoDrawCardsServer;
                private _drawn = _drawResult param [0, 0];
                _justDrawnIds = +(_table getVariable ["Waldo_MG_UNOJustDrawnIdsServer", []]);
                _justDrawnIds set [_victim, -1];
                _table setVariable ["Waldo_MG_UNOJustDrawnIdsServer", _justDrawnIds];
                _actions set [_victim, format ["Final penalty: +%1", _drawn]];
                _state set [12, _actions];
                _changedRoles pushBackUnique _victim;
            };
        };
        private _names = _table getVariable ["Waldo_MG_UNOPlayerNames", []];
        [_table, _state, _role, format ["%1 wins UNO by shedding every card.", _names param [_role, name _unit]], _changedRoles] call Waldo_MG_fnc_unoFinishServer;
        [_unit, _token, "Card accepted. You won the UNO match."] call Waldo_MG_fnc_resultServer;
    };

    if (_firstKind == 13) then {
        _pendingAmount = (if (_pendingKind == 13) then {_pendingAmount} else {0}) + 2;
        _pendingKind = 13;
        _turn = [_role, _direction, _activeFlags, 1] call Waldo_MG_fnc_unoGetNextActiveRole;
    } else {
        if (_firstKind == 15) then {
            _pendingAmount = (if (_pendingKind == 15) then {_pendingAmount} else {0}) + 4;
            _pendingKind = 15;
            _turn = [_role, _direction, _activeFlags, 1] call Waldo_MG_fnc_unoGetNextActiveRole;
        } else {
            _pendingKind = -1;
            _pendingAmount = 0;
            if (_firstKind == 11) then {
                _turn = [_role, _direction, _activeFlags, 2] call Waldo_MG_fnc_unoGetNextActiveRole;
            } else {
                if (_firstKind == 12) then {
                    if (([_activeFlags] call Waldo_MG_fnc_unoCountActiveRoles) == 2) then {
                        _turn = _role;
                    } else {
                        _direction = -_direction;
                        _turn = [_role, _direction, _activeFlags, 1] call Waldo_MG_fnc_unoGetNextActiveRole;
                    };
                } else {
                    _turn = [_role, _direction, _activeFlags, 1] call Waldo_MG_fnc_unoGetNextActiveRole;
                };
            };
        };
    };
    private _names = _table getVariable ["Waldo_MG_UNOPlayerNames", []];
    private _status = format ["%1 played %2.%3 %4 is next.", name _unit, _playedName, _unoText, _names param [_turn, "Player"]];
    if (_pendingAmount > 0) then {
        _status = format ["%1 played %2. %3 must stack the same draw card or take +%4.", name _unit, _playedName, _names param [_turn, "Player"], _pendingAmount];
    };
    _state set [2, _turn];
    _state set [3, _direction];
    _state set [9, _pendingKind];
    _state set [10, _pendingAmount];
    _state set [15, _status];
    [_table, _state] call Waldo_MG_fnc_unoSetSnapshotServer;
    [_table, [_role]] call Waldo_MG_fnc_unoSendPrivateHandsServer;
    [_unit, _token, "UNO play accepted."] call Waldo_MG_fnc_resultServer;
};

Waldo_MG_fnc_processPriorityUNORequestsServer = {
    params [["_players", []]];
    if (!isServer) exitWith {};

    {
        private _unit = _x;
        private _request = _unit getVariable ["Waldo_MG_UNOActionRequest", []];
        if ((typeName _request) == "ARRAY" && {(count _request) >= 6} && {(_request param [4, ""]) == "UNO"}) then {
            private _tableNetId = _request param [1, ""];
            if ((typeName _tableNetId) == "STRING") then {
                private _table = objectFromNetId _tableNetId;
                if (!isNull _table && {_table getVariable ["Waldo_MG_UNOActive", false]}) then {
                    private _role = (_table getVariable ["Waldo_MG_UNOPlayers", []]) find _unit;
                    private _state = _table getVariable ["Waldo_MG_UNOSnapshotServer", []];
                    private _hands = _table getVariable ["Waldo_MG_UNOHandsServer", []];
                    if (
                        _role >= 0
                        && {(_state param [13, -1]) == _role}
                        && {(count (_hands param [_role, []])) == 1}
                    ) then {
                        [_unit, +_request] call Waldo_MG_fnc_processUNOActionRequestServer;
                    };
                };
            };
        };
    } forEach _players;

    {
        private _unit = _x;
        private _request = _unit getVariable ["Waldo_MG_UNOActionRequest", []];
        if ((typeName _request) == "ARRAY" && {(count _request) >= 6} && {(_request param [4, ""]) == "CALLOUT"}) then {
            [_unit, +_request] call Waldo_MG_fnc_processUNOActionRequestServer;
        };
    } forEach _players;
};

Waldo_MG_fnc_submitUNOActionRequestLocal = {
    params [
        ["_table", objNull],
        ["_action", ""],
        ["_payload", []]
    ];
    if (!hasInterface || {isNull player} || {isNull _table} || {_action == ""}) exitWith {false};
    private _pending = missionNamespace getVariable ["Waldo_MG_UNOPendingRequestLocal", []];
    if ((count _pending) >= 2 && {(diag_tickTime - (_pending param [1, -10])) < 1.5}) exitWith {
        ["Waiting for the table host to answer your previous UNO action..."] call Waldo_MG_fnc_notifyLocal;
        false
    };
    private _token = ["UNO_ACTION"] call Waldo_MG_fnc_makeToken;
    missionNamespace setVariable ["Waldo_MG_UNOPendingRequestLocal", [_token, diag_tickTime]];
    player setVariable [
        "Waldo_MG_UNOActionRequest",
        [
            _token,
            netId _table,
            _table getVariable ["Waldo_MG_UNOGameId", ""],
            _table getVariable ["Waldo_MG_UNORevision", -1],
            _action,
            _payload
        ],
        true
    ];
    true
};

Waldo_MG_fnc_getUNOPlayerRoleLocal = {
    params [["_table", objNull]];
    if (isNull _table || {isNull player}) exitWith {-1};
    (_table getVariable ["Waldo_MG_UNOPlayers", []]) find player
};

Waldo_MG_fnc_unoSafePositionLocal = {
    params [
        ["_x", 0],
        ["_y", 0],
        ["_width", 0],
        ["_height", 0]
    ];
    [
        safeZoneX + (safeZoneW * _x),
        safeZoneY + (safeZoneH * _y),
        safeZoneW * _width,
        safeZoneH * _height
    ]
};

Waldo_MG_fnc_unoColourRGBA = {
    params [["_colour", 4]];
    switch (_colour) do {
        case 0: {[0.68, 0.06, 0.05, 1]};
        case 1: {[0.02, 0.25, 0.62, 1]};
        case 2: {[0.03, 0.42, 0.20, 1]};
        case 3: {[0.92, 0.70, 0.04, 1]};
        default {[0.035, 0.045, 0.055, 1]};
    }
};

Waldo_MG_fnc_unoSymbolRGBA = {
    params [["_colour", 4]];
    if (_colour == 3) then {[0.025, 0.045, 0.060, 1]} else {[1, 0.96, 0.88, 1]}
};

Waldo_MG_fnc_unoGetMarkerTextureLocal = {
    params [["_kind", -1]];
    private _markerClass = [_kind] call Waldo_MG_fnc_unoMarkerClass;
    if (_markerClass == "") exitWith {""};
    private _config = configFile >> "CfgMarkers" >> _markerClass;
    private _texture = getText (_config >> "icon");
    if (_texture == "") then {_texture = getText (_config >> "texture");};
    _texture
};

Waldo_MG_fnc_getUNOPrivateHandLocal = {
    params [["_table", objNull]];
    if (isNull _table || {isNull player}) exitWith {[]};
    private _payload = player getVariable ["Waldo_MG_UNOPrivateHand", []];
    if ((_payload param [0, ""]) != (_table getVariable ["Waldo_MG_UNOGameId", ""])) exitWith {[]};
    +(_payload param [2, []])
};

Waldo_MG_fnc_createUNOCardControlsLocal = {
    disableSerialization;
    params [
        ["_display", displayNull],
        ["_x", 0],
        ["_y", 0],
        ["_width", 0.08],
        ["_height", 0.22],
        ["_clickable", true]
    ];
    if (isNull _display) exitWith {[]};
    private _frame = _display ctrlCreate ["RscText", -1];
    _frame ctrlSetPosition ([_x - 0.003, _y - 0.004, _width + 0.006, _height + 0.008] call Waldo_MG_fnc_unoSafePositionLocal);
    _frame ctrlSetBackgroundColor [0.12, 0.14, 0.16, 1];
    _frame ctrlCommit 0;
    private _button = _display ctrlCreate ["RscButton", -1];
    _button ctrlSetPosition ([_x, _y, _width, _height] call Waldo_MG_fnc_unoSafePositionLocal);
    _button ctrlSetText "";
    _button ctrlEnable _clickable;
    _button ctrlCommit 0;
    private _label = _display ctrlCreate ["RscText", -1];
    _label ctrlSetPosition ([_x + (_width * 0.27), _y + (_height * 0.35), _width * 0.55, _height * 0.28] call Waldo_MG_fnc_unoSafePositionLocal);
    _label ctrlSetFontHeight 0.050;
    _label ctrlEnable false;
    _label ctrlCommit 0;
    private _marker = _display ctrlCreate ["RscPictureKeepAspect", -1];
    _marker ctrlSetPosition ([_x + (_width * 0.16), _y + (_height * 0.22), _width * 0.68, _height * 0.56] call Waldo_MG_fnc_unoSafePositionLocal);
    _marker ctrlEnable false;
    _marker ctrlCommit 0;
    if (_clickable) then {
        _button ctrlAddEventHandler [
            "ButtonClick",
            {
                params ["_control"];
                [_control] call Waldo_MG_fnc_handleUNOCardClickLocal;
            }
        ];
    };
    [_frame, _button, _label, _marker]
};

Waldo_MG_fnc_renderUNOCardLocal = {
    disableSerialization;
    params [
        ["_bundle", []],
        ["_card", []],
        ["_selected", false],
        ["_effectiveColour", -1],
        ["_enabled", true]
    ];
    if ((count _bundle) < 4) exitWith {};
    private _frame = _bundle param [0, controlNull];
    private _button = _bundle param [1, controlNull];
    private _label = _bundle param [2, controlNull];
    private _marker = _bundle param [3, controlNull];
    private _valid = [_card] call Waldo_MG_fnc_unoIsCard;
    {if (!isNull _x) then {_x ctrlShow _valid;};} forEach _bundle;
    if (!_valid) exitWith {};
    private _baseColour = _card param [1, 4];
    private _kind = _card param [2, -1];
    private _displayColour = if (_kind in [14, 15] && {_effectiveColour in [0, 1, 2, 3]}) then {_effectiveColour} else {_baseColour};
    private _background = [_displayColour] call Waldo_MG_fnc_unoColourRGBA;
    private _symbolColour = [_displayColour] call Waldo_MG_fnc_unoSymbolRGBA;
    private _markerClass = [_kind] call Waldo_MG_fnc_unoMarkerClass;
    private _labelText = if (_kind <= 10 || {_kind in [13, 15]}) then {[_kind] call Waldo_MG_fnc_unoKindLabel} else {""};
    if (!isNull _frame) then {
        _frame ctrlSetBackgroundColor (if (_selected) then {
            [1, 0.67, 0.08, 1]
        } else {
            if (_enabled) then {[0.38, 0.95, 0.64, 1]} else {[0.055, 0.075, 0.095, 1]}
        });
    };
    if (!isNull _button) then {
        _button ctrlSetBackgroundColor _background;
        _button ctrlSetText _labelText;
        _button ctrlSetTextColor _symbolColour;
        _button ctrlSetFontHeight (if (_kind <= 10) then {0.100} else {0.050});
        _button ctrlSetTooltip ([_card, _effectiveColour] call Waldo_MG_fnc_unoCardName);

        _button ctrlEnable true;
        _button setVariable ["Waldo_MG_UNOCardId", _card param [0, -1]];
        _button setVariable ["Waldo_MG_UNOCardUsable", _enabled];
    };
    if (!isNull _label) then {
        _label ctrlSetText "";
        _label ctrlSetTextColor _symbolColour;
        _label ctrlShow false;
    };
    if (!isNull _marker) then {
        _marker ctrlSetText ([_kind] call Waldo_MG_fnc_unoGetMarkerTextureLocal);
        _marker ctrlSetTextColor _symbolColour;
        _marker ctrlShow (_markerClass != "");
    };
    {if (!isNull _x) then {_x ctrlCommit 0;};} forEach _bundle;
};

Waldo_MG_fnc_unoDefocusLocal = {
    disableSerialization;
    params [["_display", displayNull]];
    if (isNull _display) exitWith {};
    private _sink = _display getVariable ["Waldo_MG_UNOFocusSink", controlNull];
    if (!isNull _sink) then {ctrlSetFocus _sink;};
};

Waldo_MG_fnc_handleUNOCardClickLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    if (isNull _display) exitWith {};
    [_display] call Waldo_MG_fnc_unoDefocusLocal;
    private _table = _display getVariable ["Waldo_MG_UNOTable", objNull];
    private _cardId = _control getVariable ["Waldo_MG_UNOCardId", -1];
    if (isNull _table || {_cardId < 0}) exitWith {};
    private _state = _table getVariable ["Waldo_MG_UNOSnapshot", []];
    private _role = [_table] call Waldo_MG_fnc_getUNOPlayerRoleLocal;
    if ((_state param [0, "IDLE"]) != "PLAYING" || {(_state param [2, -1]) != _role}) exitWith {
        ["Wait for your UNO turn."] call Waldo_MG_fnc_notifyLocal;
    };
    private _privatePayload = player getVariable ["Waldo_MG_UNOPrivateHand", []];
    private _handVersions = _state param [16, []];
    if (
        (_privatePayload param [0, ""]) != (_table getVariable ["Waldo_MG_UNOGameId", ""])
        || {(_privatePayload param [1, -2]) != (_handVersions param [_role, -1])}
    ) exitWith {
        ["Your private hand is synchronizing. Try again in a moment."] call Waldo_MG_fnc_notifyLocal;
    };
    private _hand = +(_privatePayload param [2, []]);
    private _card = [];
    {
        if ((_x param [0, -2]) == _cardId) exitWith {_card = _x;};
    } forEach _hand;
    if ((count _card) <= 0) exitWith {};
    if ((_state param [11, -1]) == _role && {(_privatePayload param [3, -1]) != _cardId}) exitWith {
        ["After drawing, only the newly drawn card may be played."] call Waldo_MG_fnc_notifyLocal;
    };
    if (!([_card, _hand, _state param [4, []], _state param [5, -1], _state param [9, -1]] call Waldo_MG_fnc_unoCanPlayFromHand)) exitWith {
        ["That card is not legal against the active colour, symbol, or draw chain."] call Waldo_MG_fnc_notifyLocal;
    };
    private _selected = +(_display getVariable ["Waldo_MG_UNOSelectedCardIds", []]);
    private _existing = _selected find _cardId;
    if (_existing >= 0) then {
        _selected deleteAt _existing;
    } else {
        private _compatible = true;
        if ((count _selected) > 0) then {
            private _firstId = _selected param [0, -1];
            private _firstCard = [];
            {
                if ((_x param [0, -2]) == _firstId) exitWith {_firstCard = _x;};
            } forEach _hand;
            if (
                (_firstCard param [2, -1]) > 10
                || {(_card param [2, -2]) != (_firstCard param [2, -1])}
                || {(_card param [1, -2]) != (_firstCard param [1, -1])}
            ) then {_compatible = false;};
        };
        if (!_compatible) exitWith {["Only exact duplicate numbered cards can be selected together."] call Waldo_MG_fnc_notifyLocal;};
        if ((count _selected) >= 2) exitWith {
            ["This ruleset batches at most the two duplicate copies."] call Waldo_MG_fnc_notifyLocal;
        };
        _selected pushBack _cardId;
    };
    _display setVariable ["Waldo_MG_UNOSelectedCardIds", _selected];
    [_display] call Waldo_MG_fnc_refreshUNOLocal;
};

Waldo_MG_fnc_changeUNOPageLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    if (isNull _display) exitWith {};
    [_display] call Waldo_MG_fnc_unoDefocusLocal;
    private _delta = _control getVariable ["Waldo_MG_UNOPageDelta", 0];
    _display setVariable ["Waldo_MG_UNOHandPage", (_display getVariable ["Waldo_MG_UNOHandPage", 0]) + _delta];
    [_display] call Waldo_MG_fnc_refreshUNOLocal;
};

Waldo_MG_fnc_setUNOColourModalLocal = {
    disableSerialization;
    params [
        ["_display", displayNull],
        ["_visible", false]
    ];
    if (isNull _display) exitWith {};
    {
        if (!isNull _x) then {_x ctrlShow _visible;};
    } forEach (_display getVariable ["Waldo_MG_UNOColourModalControls", []]);
    if (_visible) then {
        {
            if (!isNull _x) then {_x ctrlEnable false;};
        } forEach (_display getVariable ["Waldo_MG_UNOInteractiveControls", []]);
    } else {
        _display setVariable ["Waldo_MG_UNOColourPendingCards", []];
        _display setVariable ["Waldo_MG_UNOColourPendingRevision", -1];
    };
    _display setVariable ["Waldo_MG_UNOColourModalVisible", _visible];
    [_display] call Waldo_MG_fnc_unoDefocusLocal;
    if (!_visible && {!(_display getVariable ["Waldo_MG_UNORefreshing", false])}) then {
        [_display] call Waldo_MG_fnc_refreshUNOLocal;
    };
};

Waldo_MG_fnc_chooseUNOColourLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    if (isNull _display) exitWith {};
    private _table = _display getVariable ["Waldo_MG_UNOTable", objNull];
    private _colour = _control getVariable ["Waldo_MG_UNOChosenColour", -1];
    private _cards = +(_display getVariable ["Waldo_MG_UNOColourPendingCards", []]);
    if (isNull _table || {!(_colour in [0, 1, 2, 3])} || {(count _cards) <= 0}) exitWith {};
    if ([_table, "PLAY", [_cards, _colour]] call Waldo_MG_fnc_submitUNOActionRequestLocal) then {
        [_display, false] call Waldo_MG_fnc_setUNOColourModalLocal;
    };
};

Waldo_MG_fnc_submitUNOButtonLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    if (isNull _display) exitWith {};
    [_display] call Waldo_MG_fnc_unoDefocusLocal;
    private _table = _display getVariable ["Waldo_MG_UNOTable", objNull];
    private _action = _control getVariable ["Waldo_MG_UNOAction", ""];
    if (isNull _table || {_action == ""}) exitWith {};
    if (_action == "PLAY") exitWith {
        private _selected = +(_display getVariable ["Waldo_MG_UNOSelectedCardIds", []]);
        if ((count _selected) <= 0) exitWith {["Select a playable UNO card first."] call Waldo_MG_fnc_notifyLocal;};
        private _hand = [_table] call Waldo_MG_fnc_getUNOPrivateHandLocal;
        private _firstCard = [];
        private _firstId = _selected param [0, -1];
        {
            if ((_x param [0, -2]) == _firstId) exitWith {_firstCard = _x;};
        } forEach _hand;
        if ((count _firstCard) <= 0) exitWith {["That card selection is stale."] call Waldo_MG_fnc_notifyLocal;};
        if ((_firstCard param [2, -1]) in [14, 15]) then {
            _display setVariable ["Waldo_MG_UNOColourPendingCards", _selected];
            _display setVariable ["Waldo_MG_UNOColourPendingRevision", _table getVariable ["Waldo_MG_UNORevision", -1]];
            [_display, true] call Waldo_MG_fnc_setUNOColourModalLocal;
        } else {
            [_table, "PLAY", [_selected, -1]] call Waldo_MG_fnc_submitUNOActionRequestLocal;
        };
    };
    [_table, _action, []] call Waldo_MG_fnc_submitUNOActionRequestLocal;
};

Waldo_MG_fnc_refreshUNOLocal = {
    disableSerialization;
    params [["_display", displayNull]];
    if (isNull _display || {_display getVariable ["Waldo_MG_UNORefreshing", false]}) exitWith {};
    _display setVariable ["Waldo_MG_UNORefreshing", true];
    private _table = _display getVariable ["Waldo_MG_UNOTable", objNull];
    private _spectating = _display getVariable ["Waldo_MG_SpectatorMode", false];
    if (!([_table, _spectating] call Waldo_MG_fnc_isValidGameViewerLocal)) exitWith {
        _display setVariable ["Waldo_MG_UNORefreshing", false];
        _display closeDisplay 1;
    };
    if (([_table] call Waldo_MG_fnc_getTableActiveGameId) != "uno") exitWith {
        _display setVariable ["Waldo_MG_UNORefreshing", false];
        if (_spectating) then {
            [true] call Waldo_MG_fnc_exitSpectatorLocal;
        } else {
            _display closeDisplay 1;
            [_table] spawn {
                params ["_lobbyTable"];
                uiSleep 0.1;
                if (!isNull _lobbyTable && {_lobbyTable == (player getVariable ["Waldo_MG_SeatedTable", objNull])}) then {
                    [_lobbyTable] call Waldo_MG_fnc_openLobbyLocal;
                };
            };
        };
    };
    private _state = _table getVariable ["Waldo_MG_UNOSnapshot", []];
    private _phase = _state param [0, "IDLE"];
    private _turn = _state param [2, -1];
    private _direction = _state param [3, 1];
    private _topCard = _state param [4, []];
    private _activeColour = _state param [5, 0];
    private _deckCount = _state param [6, 0];
    private _handCounts = _state param [7, []];
    private _statuses = _state param [8, []];
    private _pendingKind = _state param [9, -1];
    private _pendingAmount = _state param [10, 0];
    private _drawnRole = _state param [11, -1];
    private _actions = _state param [12, []];
    private _vulnerable = _state param [13, -1];
    private _winner = _state param [14, -1];
    private _status = _state param [15, "UNO in progress."];
    private _handVersions = _state param [16, []];
    private _armed = _state param [17, []];
    private _role = [_table] call Waldo_MG_fnc_getUNOPlayerRoleLocal;
    if (_role < 0 && {!_spectating}) exitWith {

        _display setVariable ["Waldo_MG_UNORefreshing", false];
    };
    private _names = _table getVariable ["Waldo_MG_UNOPlayerNames", []];
    private _playing = _phase == "PLAYING";
    private _finished = _phase == "FINISHED";
    private _yourTurn = !_spectating && {_role >= 0} && {_playing} && {_turn == _role};

    private _playerRows = _display getVariable ["Waldo_MG_UNOPlayerRows", []];
    for "_row" from 0 to ((count _playerRows) - 1) do {
        private _bundle = _playerRows param [_row, []];
        private _rowBackground = _bundle param [0, controlNull];
        private _arrow = _bundle param [1, controlNull];
        private _nameControl = _bundle param [2, controlNull];
        private _actionControl = _bundle param [3, controlNull];
        private _countControl = _bundle param [4, controlNull];
        private _exists = _row < (count _names);
        {
            if (!isNull _x) then {_x ctrlShow _exists;};
        } forEach _bundle;
        if (!isNull _rowBackground) then {
            _rowBackground ctrlSetBackgroundColor (if (_row == _turn && {_playing}) then {[0.40, 0.27, 0.04, 0.98]} else {if (_row == _role) then {[0.04, 0.18, 0.29, 0.98]} else {[0.025, 0.055, 0.075, 0.96]}});
        };
        if (!isNull _arrow) then {
            _arrow ctrlShow (_exists && {_row == _turn} && {_playing});
            _arrow ctrlSetText ">";
        };
        if (_exists) then {
            private _playerName = _names param [_row, "Player"];
            if (!isNull _nameControl) then {_nameControl ctrlSetText _playerName; _nameControl ctrlSetTooltip _playerName;};
            private _actionText = _actions param [_row, "Waiting"];
            if (_row == _vulnerable) then {_actionText = "NO UNO - CALL OUT!";};
            if (_row == _winner) then {_actionText = "WINNER";};
            if (!isNull _actionControl) then {_actionControl ctrlSetText _actionText; _actionControl ctrlSetTooltip _actionText;};
            if (!isNull _countControl) then {
                _countControl ctrlSetText str (_handCounts param [_row, 0]);
                _countControl ctrlSetTooltip format ["%1 cards", _handCounts param [_row, 0]];
            };
        };
        {if (!isNull _x) then {_x ctrlCommit 0;};} forEach _bundle;
    };

    private _deckLabel = _display getVariable ["Waldo_MG_UNODeckCount", controlNull];
    if (!isNull _deckLabel) then {_deckLabel ctrlSetText str _deckCount; _deckLabel ctrlCommit 0;};
    private _directionLabel = _display getVariable ["Waldo_MG_UNODirectionLabel", controlNull];
    if (!isNull _directionLabel) then {
        _directionLabel ctrlSetText (if (_direction > 0) then {"ASCENDING  >"} else {"<  DESCENDING"});
        _directionLabel ctrlCommit 0;
    };
    private _drawStackLabel = _display getVariable ["Waldo_MG_UNODrawStackLabel", controlNull];
    if (!isNull _drawStackLabel) then {
        _drawStackLabel ctrlSetText (if (_pendingAmount > 0) then {format ["DRAW CHAIN: +%1  (%2 ONLY)", _pendingAmount, [_pendingKind] call Waldo_MG_fnc_unoKindLabel]} else {"DRAW CHAIN: CLEAR"});
        _drawStackLabel ctrlSetTextColor (if (_pendingAmount > 0) then {[1, 0.46, 0.18, 1]} else {[0.62, 0.78, 0.69, 1]});
        _drawStackLabel ctrlCommit 0;
    };
    private _turnLabel = _display getVariable ["Waldo_MG_UNOTurnLabel", controlNull];
    if (!isNull _turnLabel) then {
        _turnLabel ctrlSetText (if (_finished) then {if (_winner >= 0) then {format ["WINNER: %1", _names param [_winner, "Player"]]} else {"MATCH DRAWN"}} else {format ["TURN: %1", _names param [_turn, "Player"]]});
        _turnLabel ctrlCommit 0;
    };
    private _statusOne = _display getVariable ["Waldo_MG_UNOStatusOne", controlNull];
    private _statusTwo = _display getVariable ["Waldo_MG_UNOStatusTwo", controlNull];
    private _lineOneWords = [];
    private _lineTwoWords = [];
    {
        private _candidate = (_lineOneWords + [_x]) joinString " ";
        if ((count _candidate) <= 48 || {(count _lineOneWords) == 0}) then {_lineOneWords pushBack _x;} else {_lineTwoWords pushBack _x;};
    } forEach (_status splitString " ");
    if (!isNull _statusOne) then {_statusOne ctrlSetText (_lineOneWords joinString " "); _statusOne ctrlSetTooltip _status; _statusOne ctrlCommit 0;};
    if (!isNull _statusTwo) then {_statusTwo ctrlSetText (_lineTwoWords joinString " "); _statusTwo ctrlSetTooltip _status; _statusTwo ctrlCommit 0;};
    [_display getVariable ["Waldo_MG_UNOTopCard", []], _topCard, false, _activeColour, false] call Waldo_MG_fnc_renderUNOCardLocal;

    private _privatePayload = if (_spectating) then {[]} else {player getVariable ["Waldo_MG_UNOPrivateHand", []]};
    private _expectedHandVersion = if (_role >= 0) then {_handVersions param [_role, -1]} else {-1};
    private _privateValid = (_privatePayload param [0, ""]) == (_table getVariable ["Waldo_MG_UNOGameId", ""])
        && {(_privatePayload param [1, -2]) == _expectedHandVersion};
    private _hand = if (_privateValid) then {+(_privatePayload param [2, []])} else {[]};
    private _pendingRequest = missionNamespace getVariable ["Waldo_MG_UNOPendingRequestLocal", []];
    private _requestPending = (count _pendingRequest) >= 2
        && {(diag_tickTime - (_pendingRequest param [1, -10])) < 1.5};
    if (!_spectating && {!_privateValid} && {_role >= 0} && {(_statuses param [_role, "LEFT"]) != "LEFT"}) then {
        private _lastSync = _display getVariable ["Waldo_MG_UNOLastHandSync", -10];
        if ((diag_tickTime - _lastSync) > 2.5) then {
            _display setVariable ["Waldo_MG_UNOLastHandSync", diag_tickTime];
            [_table, "SYNC_HAND", []] call Waldo_MG_fnc_submitUNOActionRequestLocal;
        };
    };
    private _validIds = [];
    {_validIds pushBack (_x param [0, -1]);} forEach _hand;
    private _selected = +(_display getVariable ["Waldo_MG_UNOSelectedCardIds", []]);
    private _cleanSelection = [];
    {if (_x in _validIds) then {_cleanSelection pushBackUnique _x;};} forEach _selected;
    _selected = _cleanSelection;
    if (!_yourTurn) then {_selected = [];};
    if (_role >= 0 && {_drawnRole == _role}) then {
        private _drawnId = _privatePayload param [3, -1];
        private _drawSelection = [];
        {if (_x == _drawnId) then {_drawSelection pushBackUnique _x;};} forEach _selected;
        _selected = _drawSelection;
    };
    _display setVariable ["Waldo_MG_UNOSelectedCardIds", _selected];
    private _modalCards = +(_display getVariable ["Waldo_MG_UNOColourPendingCards", []]);
    private _modalCardsValid = (count _modalCards) > 0;
    {if (!(_x in _validIds)) then {_modalCardsValid = false;};} forEach _modalCards;
    private _modalStillValid = _playing
        && {!_spectating}
        && {_yourTurn}
        && {_privateValid}
        && {_modalCardsValid}
        && {(_display getVariable ["Waldo_MG_UNOColourPendingRevision", -1]) == (_table getVariable ["Waldo_MG_UNORevision", -2])};
    if ((_display getVariable ["Waldo_MG_UNOColourModalVisible", false]) && {!_modalStillValid}) then {
        [_display, false] call Waldo_MG_fnc_setUNOColourModalLocal;
    };
    private _pageSize = Waldo_MG_CFG_UNO_HAND_PAGE_SIZE max 1;
    private _maxPage = floor ((((count _hand) - 1) max 0) / _pageSize);
    private _page = ((_display getVariable ["Waldo_MG_UNOHandPage", 0]) max 0) min _maxPage;
    _display setVariable ["Waldo_MG_UNOHandPage", _page];
    private _cardBundles = _display getVariable ["Waldo_MG_UNOHandCards", []];
    for "_slot" from 0 to ((count _cardBundles) - 1) do {
        private _handIndex = (_page * _pageSize) + _slot;
        private _card = if (_handIndex < (count _hand)) then {_hand param [_handIndex, []]} else {[]};
        private _cardId = _card param [0, -1];
        private _cardLegal = [_card, _hand, _topCard, _activeColour, _pendingKind] call Waldo_MG_fnc_unoCanPlayFromHand;
        private _cardEnabled = _privateValid && {_yourTurn} && {!_finished} && {!_requestPending} && {_cardLegal};
        if (_role >= 0 && {_drawnRole == _role}) then {_cardEnabled = _cardEnabled && {_cardId == (_privatePayload param [3, -2])};};
        private _cardBundle = _cardBundles param [_slot, []];
        [_cardBundle, _card, _cardId in _selected, -1, _cardEnabled] call Waldo_MG_fnc_renderUNOCardLocal;
        private _cardButton = _cardBundle param [1, controlNull];
        if (!isNull _cardButton && {[_card] call Waldo_MG_fnc_unoIsCard} && {!_cardLegal}) then {
            _cardButton ctrlSetTooltip format ["%1 - not legal against the current colour, symbol, or draw chain.", [_card] call Waldo_MG_fnc_unoCardName];
        };
    };
    private _pageLabel = _display getVariable ["Waldo_MG_UNOPageLabel", controlNull];
    if (!isNull _pageLabel) then {_pageLabel ctrlSetText format ["PAGE %1 / %2", _page + 1, _maxPage + 1]; _pageLabel ctrlCommit 0;};
    private _previous = _display getVariable ["Waldo_MG_UNOPreviousButton", controlNull];
    private _next = _display getVariable ["Waldo_MG_UNONextButton", controlNull];
    if (!isNull _previous) then {_previous ctrlEnable (!_spectating && {_page > 0}); _previous ctrlShow (!_spectating && {_maxPage > 0});};
    if (!isNull _next) then {_next ctrlEnable (!_spectating && {_page < _maxPage}); _next ctrlShow (!_spectating && {_maxPage > 0});};
    private _handTitle = _display getVariable ["Waldo_MG_UNOHandTitle", controlNull];
    if (!isNull _handTitle) then {
        _handTitle ctrlSetText (if (_spectating) then {"SPECTATOR VIEW  /  PRIVATE HANDS HIDDEN"} else {format ["YOUR PRIVATE HAND  /  %1 CARDS", count _hand]});
        _handTitle ctrlCommit 0;
    };
    private _helpLabel = _display getVariable ["Waldo_MG_UNOHelpLabel", controlNull];
    private _pageHelpLabel = _display getVariable ["Waldo_MG_UNOPageHelpLabel", controlNull];
    if (!isNull _helpLabel) then {
        _helpLabel ctrlSetText (if (_spectating) then {"SPECTATORS SEE PUBLIC COUNTS, TURN ORDER, DRAW PILE AND DISCARD."} else {"BRIGHT BORDER = PLAYABLE. SELECT ONE CARD OR TWO IDENTICAL NUMBERS."});
        _helpLabel ctrlCommit 0;
    };
    if (!isNull _pageHelpLabel) then {
        _pageHelpLabel ctrlSetText (if (_spectating) then {"PRIVATE HAND CONTENT NEVER ENTERS THE SPECTATOR VIEW."} else {"USE THE SIDE ARROWS WHEN YOUR HAND SPANS MULTIPLE PAGES."});
        _pageHelpLabel ctrlCommit 0;
    };
    private _selectionLabel = _display getVariable ["Waldo_MG_UNOSelectionLabel", controlNull];
    if (!isNull _selectionLabel) then {
        private _selectionText = if (_spectating) then {"PUBLIC TABLE STATE ONLY - CARD COUNTS REMAIN VISIBLE"} else {"SELECTED: NONE"};
        if (!_spectating && {(count _selected) > 0}) then {
            private _selectedCard = [];
            {
                if ((_x param [0, -2]) == (_selected param [0, -1])) exitWith {_selectedCard = _x;};
            } forEach _hand;
            _selectionText = format ["SELECTED: %1 x %2", count _selected, [_selectedCard] call Waldo_MG_fnc_unoCardName];
        };
        _selectionLabel ctrlSetText _selectionText;
        _selectionLabel ctrlCommit 0;
    };

    private _drawButton = _display getVariable ["Waldo_MG_UNODrawButton", controlNull];
    private _unoButton = _display getVariable ["Waldo_MG_UNOButton", controlNull];
    private _calloutButton = _display getVariable ["Waldo_MG_UNOCalloutButton", controlNull];
    private _playButton = _display getVariable ["Waldo_MG_UNOPlayButton", controlNull];
    private _leaveButton = _display getVariable ["Waldo_MG_UNOLeaveButton", controlNull];
    if (!isNull _leaveButton) then {_leaveButton ctrlEnable true;};
    private _selectionCanPlay = _privateValid && {_yourTurn} && {(count _selected) > 0};
    if (_selectionCanPlay) then {
        private _selectedCard = [];
        {
            if ((_x param [0, -2]) == (_selected param [0, -1])) exitWith {_selectedCard = _x;};
        } forEach _hand;
        _selectionCanPlay = [_selectedCard, _hand, _topCard, _activeColour, _pendingKind] call Waldo_MG_fnc_unoCanPlayFromHand;
        if (_role >= 0 && {_drawnRole == _role}) then {
            _selectionCanPlay = _selectionCanPlay
                && {(count _selected) == 1}
                && {(_selected param [0, -2]) == (_privatePayload param [3, -1])};
        };
    };
    if (!isNull _drawButton) then {
        private _drawAction = if (_role >= 0 && {_drawnRole == _role}) then {"PASS"} else {"DRAW"};
        _drawButton setVariable ["Waldo_MG_UNOAction", _drawAction];
        _drawButton ctrlSetText (if (_role >= 0 && {_drawnRole == _role}) then {"Pass"} else {if (_pendingAmount > 0) then {format ["Take +%1", _pendingAmount]} else {"Draw Card"}});
        _drawButton ctrlEnable (!_spectating && {_yourTurn} && {_privateValid} && {!_requestPending});
        _drawButton ctrlShow (!_spectating && {!_finished});
    };
    if (!isNull _unoButton) then {
        private _isArmed = if (_role >= 0) then {_armed param [_role, false]} else {false};
        _unoButton ctrlSetText (if (_vulnerable == _role) then {"Call UNO!"} else {if (_isArmed) then {"UNO ARMED"} else {"UNO"}});
        _unoButton ctrlEnable (!_spectating && {_playing} && {!_requestPending} && {(_vulnerable == _role) || {_yourTurn && {_privateValid} && {!_isArmed}}});
        _unoButton ctrlShow (!_spectating && {!_finished});
    };
    if (!isNull _calloutButton) then {
        _calloutButton ctrlEnable (!_spectating && {_playing} && {!_requestPending} && {_vulnerable >= 0} && {_vulnerable != _role});
        _calloutButton ctrlShow (!_spectating && {!_finished});
    };
    if (!isNull _playButton) then {
        if (_finished) then {
            _playButton ctrlSetText "Reset to Lobby";
            _playButton setVariable ["Waldo_MG_UNOAction", "RESET"];
            _playButton ctrlEnable (!_spectating && {!_requestPending});
            _playButton ctrlShow !_spectating;
        } else {
            _playButton ctrlSetText "Play Selected";
            _playButton setVariable ["Waldo_MG_UNOAction", "PLAY"];
            _playButton ctrlEnable (!_spectating && {_selectionCanPlay} && {!_requestPending});
            _playButton ctrlShow !_spectating;
        };
    };
    {if (!isNull _x) then {_x ctrlCommit 0;};} forEach [_drawButton, _unoButton, _calloutButton, _playButton, _previous, _next, _leaveButton];
    if (_display getVariable ["Waldo_MG_UNOColourModalVisible", false]) then {
        {
            if (!isNull _x) then {_x ctrlEnable false;};
        } forEach (_display getVariable ["Waldo_MG_UNOInteractiveControls", []]);
    };
    _display setVariable ["Waldo_MG_UNORefreshing", false];
};

Waldo_MG_fnc_openUNOLocal = {
    disableSerialization;
    params [
        ["_table", objNull],
        ["_spectating", false]
    ];
    if (!hasInterface || {isNull player}) exitWith {};
    if (
        isNull _table
        || {!([_table, _spectating] call Waldo_MG_fnc_isValidGameViewerLocal)}
        || {([_table] call Waldo_MG_fnc_getTableActiveGameId) != "uno"}
    ) exitWith {["No active UNO match is available to this viewer."] call Waldo_MG_fnc_notifyLocal;};
    private _parent = findDisplay 46;
    if (isNull _parent) exitWith {["The UNO display is unavailable."] call Waldo_MG_fnc_notifyLocal;};
    {
        if (!isNull _x) then {_x closeDisplay 1;};
    } forEach [
        uiNamespace getVariable ["Waldo_MG_LobbyDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_BattleshipDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_WhosWhoDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_ShotgunDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_CheckersDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_RPSDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_BlackjackDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_ChessDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_PokerDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_UNODisplay", displayNull]
    ];
    private _display = _parent createDisplay "RscDisplayEmpty";
    if (isNull _display) exitWith {};
    uiNamespace setVariable ["Waldo_MG_UNODisplay", _display];
    _display setVariable ["Waldo_MG_UNOTable", _table];
    _display setVariable ["Waldo_MG_SpectatorMode", _spectating];
    _display setVariable ["Waldo_MG_UNOHandPage", 0];
    _display setVariable ["Waldo_MG_UNOSelectedCardIds", []];
    _display setVariable ["Waldo_MG_UNOLastHandSync", -10];
    _display setVariable ["Waldo_MG_UNOColourModalVisible", false];
    [_display] call Waldo_MG_fnc_installEscapeGuardLocal;
    private _focusSink = _display ctrlCreate ["RscButton", -1];
    _focusSink ctrlSetPosition [-10, -10, 0.001, 0.001];
    _focusSink ctrlSetText "";
    _focusSink ctrlCommit 0;
    _display setVariable ["Waldo_MG_UNOFocusSink", _focusSink];
    ctrlSetFocus _focusSink;

    private _background = _display ctrlCreate ["RscText", -1];
    _background ctrlSetPosition ([0.010, 0.015, 0.980, 0.970] call Waldo_MG_fnc_unoSafePositionLocal);
    _background ctrlSetBackgroundColor [0.008, 0.014, 0.020, 0.988];
    _background ctrlCommit 0;
    private _topBar = _display ctrlCreate ["RscText", -1];
    _topBar ctrlSetPosition ([0.010, 0.015, 0.980, 0.070] call Waldo_MG_fnc_unoSafePositionLocal);
    _topBar ctrlSetBackgroundColor [0.36, 0.06, 0.08, 1];
    _topBar ctrlCommit 0;
    private _title = _display ctrlCreate ["RscText", -1];
    _title ctrlSetPosition ([0.030, 0.026, 0.500, 0.045] call Waldo_MG_fnc_unoSafePositionLocal);
    _title ctrlSetText (if (_spectating) then {"PARTYGAMES  /  UNO SPECTATOR"} else {"PARTYGAMES  /  UNO"});
    _title ctrlSetTextColor [1, 0.94, 0.84, 1];
    _title ctrlSetFontHeight 0.040;
    _title ctrlCommit 0;
    private _turnLabel = _display ctrlCreate ["RscText", -1];
    _turnLabel ctrlSetPosition ([0.510, 0.028, 0.255, 0.040] call Waldo_MG_fnc_unoSafePositionLocal);
    _turnLabel ctrlSetTextColor [1, 0.84, 0.42, 1];
    _turnLabel ctrlSetFontHeight 0.025;
    _turnLabel ctrlCommit 0;
    _display setVariable ["Waldo_MG_UNOTurnLabel", _turnLabel];
    private _leaveButton = _display ctrlCreate ["RscButtonMenu", -1];
    _leaveButton ctrlSetPosition ([0.815, 0.028, 0.155, 0.042] call Waldo_MG_fnc_unoSafePositionLocal);
    _leaveButton ctrlSetText (if (_spectating) then {"Exit Spectate"} else {"Leave Table"});
    _leaveButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_handleViewerExitButtonLocal;}];
    _leaveButton ctrlCommit 0;
    _display setVariable ["Waldo_MG_UNOLeaveButton", _leaveButton];

    private _rosterFrame = _display ctrlCreate ["RscText", -1];
    _rosterFrame ctrlSetPosition ([0.020, 0.100, 0.235, 0.465] call Waldo_MG_fnc_unoSafePositionLocal);
    _rosterFrame ctrlSetBackgroundColor [0.014, 0.032, 0.045, 0.98];
    _rosterFrame ctrlCommit 0;
    private _rosterTitle = _display ctrlCreate ["RscText", -1];
    _rosterTitle ctrlSetPosition ([0.035, 0.112, 0.108, 0.035] call Waldo_MG_fnc_unoSafePositionLocal);
    _rosterTitle ctrlSetText "PLAYERS / CARDS";
    _rosterTitle ctrlSetTextColor [0.68, 0.88, 0.96, 1];
    _rosterTitle ctrlSetFontHeight 0.023;
    _rosterTitle ctrlCommit 0;
    private _directionLabel = _display ctrlCreate ["RscText", -1];
    _directionLabel ctrlSetPosition ([0.145, 0.112, 0.095, 0.035] call Waldo_MG_fnc_unoSafePositionLocal);
    _directionLabel ctrlSetTextColor [0.82, 0.91, 0.86, 1];
    _directionLabel ctrlSetFontHeight 0.019;
    _directionLabel ctrlCommit 0;
    _display setVariable ["Waldo_MG_UNODirectionLabel", _directionLabel];
    private _playerRows = [];
    for "_row" from 0 to 3 do {
        private _rowY = 0.158 + (_row * 0.095);
        private _rowBackground = _display ctrlCreate ["RscText", -1];
        _rowBackground ctrlSetPosition ([0.035, _rowY, 0.205, 0.082] call Waldo_MG_fnc_unoSafePositionLocal);
        _rowBackground ctrlCommit 0;
        private _arrow = _display ctrlCreate ["RscText", -1];
        _arrow ctrlSetPosition ([0.040, _rowY + 0.008, 0.025, 0.064] call Waldo_MG_fnc_unoSafePositionLocal);
        _arrow ctrlSetTextColor [1, 0.72, 0.16, 1];
        _arrow ctrlSetFontHeight 0.055;
        _arrow ctrlCommit 0;
        private _nameControl = _display ctrlCreate ["RscText", -1];
        _nameControl ctrlSetPosition ([0.067, _rowY + 0.002, 0.118, 0.042] call Waldo_MG_fnc_unoSafePositionLocal);
        _nameControl ctrlSetTextColor [0.91, 0.96, 1, 1];
        _nameControl ctrlSetFontHeight 0.044;
        _nameControl ctrlCommit 0;
        private _actionControl = _display ctrlCreate ["RscText", -1];
        _actionControl ctrlSetPosition ([0.067, _rowY + 0.043, 0.120, 0.036] call Waldo_MG_fnc_unoSafePositionLocal);
        _actionControl ctrlSetTextColor [0.96, 0.72, 0.31, 1];
        _actionControl ctrlSetFontHeight 0.030;
        _actionControl ctrlCommit 0;
        private _countControl = _display ctrlCreate ["RscText", -1];
        _countControl ctrlSetPosition ([0.192, _rowY + 0.011, 0.042, 0.058] call Waldo_MG_fnc_unoSafePositionLocal);
        _countControl ctrlSetBackgroundColor [0.06, 0.12, 0.17, 1];
        _countControl ctrlSetTextColor [1, 0.92, 0.64, 1];
        _countControl ctrlSetFontHeight 0.032;
        _countControl ctrlCommit 0;
        _playerRows pushBack [_rowBackground, _arrow, _nameControl, _actionControl, _countControl];
    };
    _display setVariable ["Waldo_MG_UNOPlayerRows", _playerRows];

    private _tableFrame = _display ctrlCreate ["RscText", -1];
    _tableFrame ctrlSetPosition ([0.265, 0.100, 0.715, 0.465] call Waldo_MG_fnc_unoSafePositionLocal);
    _tableFrame ctrlSetBackgroundColor [0.028, 0.095, 0.075, 0.98];
    _tableFrame ctrlCommit 0;
    private _deckTitle = _display ctrlCreate ["RscText", -1];
    _deckTitle ctrlSetPosition ([0.292, 0.126, 0.130, 0.033] call Waldo_MG_fnc_unoSafePositionLocal);
    _deckTitle ctrlSetText "DRAW PILE";
    _deckTitle ctrlSetTextColor [0.70, 0.86, 0.78, 1];
    _deckTitle ctrlSetFontHeight 0.020;
    _deckTitle ctrlCommit 0;
    private _deckCountLabel = _display ctrlCreate ["RscText", -1];
    _deckCountLabel ctrlSetPosition ([0.300, 0.185, 0.065, 0.085] call Waldo_MG_fnc_unoSafePositionLocal);
    _deckCountLabel ctrlSetBackgroundColor [0.015, 0.035, 0.055, 1];
    _deckCountLabel ctrlSetTextColor [0.72, 0.90, 1, 1];
    _deckCountLabel ctrlSetFontHeight 0.042;
    _deckCountLabel ctrlSetTooltip "Cards remaining before the discard pile is recycled";
    _deckCountLabel ctrlCommit 0;
    _display setVariable ["Waldo_MG_UNODeckCount", _deckCountLabel];
    private _discardTitle = _display ctrlCreate ["RscText", -1];
    _discardTitle ctrlSetPosition ([0.510, 0.126, 0.145, 0.033] call Waldo_MG_fnc_unoSafePositionLocal);
    _discardTitle ctrlSetText "TOP DISCARD";
    _discardTitle ctrlSetTextColor [0.70, 0.86, 0.78, 1];
    _discardTitle ctrlSetFontHeight 0.020;
    _discardTitle ctrlCommit 0;
    private _topCardBundle = [_display, 0.525, 0.175, 0.095, 0.235, false] call Waldo_MG_fnc_createUNOCardControlsLocal;
    _display setVariable ["Waldo_MG_UNOTopCard", _topCardBundle];
    private _drawStackLabel = _display ctrlCreate ["RscText", -1];
    _drawStackLabel ctrlSetPosition ([0.665, 0.250, 0.280, 0.038] call Waldo_MG_fnc_unoSafePositionLocal);
    _drawStackLabel ctrlSetFontHeight 0.020;
    _drawStackLabel ctrlCommit 0;
    _display setVariable ["Waldo_MG_UNODrawStackLabel", _drawStackLabel];

    private _drawButton = _display ctrlCreate ["RscButtonMenu", -1];
    _drawButton ctrlSetPosition ([0.665, 0.305, 0.130, 0.050] call Waldo_MG_fnc_unoSafePositionLocal);
    _drawButton setVariable ["Waldo_MG_UNOAction", "DRAW"];
    _drawButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_submitUNOButtonLocal;}];
    _drawButton ctrlCommit 0;
    _display setVariable ["Waldo_MG_UNODrawButton", _drawButton];
    private _unoButton = _display ctrlCreate ["RscButtonMenu", -1];
    _unoButton ctrlSetPosition ([0.815, 0.305, 0.130, 0.050] call Waldo_MG_fnc_unoSafePositionLocal);
    _unoButton setVariable ["Waldo_MG_UNOAction", "UNO"];
    _unoButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_submitUNOButtonLocal;}];
    _unoButton ctrlCommit 0;
    _display setVariable ["Waldo_MG_UNOButton", _unoButton];
    private _calloutButton = _display ctrlCreate ["RscButtonMenu", -1];
    _calloutButton ctrlSetPosition ([0.665, 0.370, 0.130, 0.050] call Waldo_MG_fnc_unoSafePositionLocal);
    _calloutButton ctrlSetText "Callout";
    _calloutButton setVariable ["Waldo_MG_UNOAction", "CALLOUT"];
    _calloutButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_submitUNOButtonLocal;}];
    _calloutButton ctrlCommit 0;
    _display setVariable ["Waldo_MG_UNOCalloutButton", _calloutButton];
    private _playButton = _display ctrlCreate ["RscButtonMenu", -1];
    _playButton ctrlSetPosition ([0.815, 0.370, 0.130, 0.050] call Waldo_MG_fnc_unoSafePositionLocal);
    _playButton ctrlSetText "Play Selected";
    _playButton setVariable ["Waldo_MG_UNOAction", "PLAY"];
    _playButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_submitUNOButtonLocal;}];
    _playButton ctrlCommit 0;
    _display setVariable ["Waldo_MG_UNOPlayButton", _playButton];
    private _statusOne = _display ctrlCreate ["RscText", -1];
    _statusOne ctrlSetPosition ([0.290, 0.442, 0.655, 0.048] call Waldo_MG_fnc_unoSafePositionLocal);
    _statusOne ctrlSetBackgroundColor [0.012, 0.050, 0.040, 0.94];
    _statusOne ctrlSetTextColor [0.91, 0.96, 0.92, 1];
    _statusOne ctrlSetFontHeight 0.034;
    _statusOne ctrlCommit 0;
    _display setVariable ["Waldo_MG_UNOStatusOne", _statusOne];
    private _statusTwo = _display ctrlCreate ["RscText", -1];
    _statusTwo ctrlSetPosition ([0.290, 0.497, 0.655, 0.048] call Waldo_MG_fnc_unoSafePositionLocal);
    _statusTwo ctrlSetBackgroundColor [0.012, 0.050, 0.040, 0.94];
    _statusTwo ctrlSetTextColor [0.73, 0.86, 0.78, 1];
    _statusTwo ctrlSetFontHeight 0.032;
    _statusTwo ctrlCommit 0;
    _display setVariable ["Waldo_MG_UNOStatusTwo", _statusTwo];

    private _handFrame = _display ctrlCreate ["RscText", -1];
    _handFrame ctrlSetPosition ([0.020, 0.580, 0.960, 0.390] call Waldo_MG_fnc_unoSafePositionLocal);
    _handFrame ctrlSetBackgroundColor [0.014, 0.032, 0.050, 0.985];
    _handFrame ctrlCommit 0;
    private _handTitle = _display ctrlCreate ["RscText", -1];
    _handTitle ctrlSetPosition ([0.040, 0.596, 0.520, 0.040] call Waldo_MG_fnc_unoSafePositionLocal);
    _handTitle ctrlSetText "YOUR PRIVATE HAND";
    _handTitle ctrlSetTextColor [0.65, 0.86, 1, 1];
    _handTitle ctrlSetFontHeight 0.025;
    _handTitle ctrlCommit 0;
    _display setVariable ["Waldo_MG_UNOHandTitle", _handTitle];
    private _pageLabel = _display ctrlCreate ["RscText", -1];
    _pageLabel ctrlSetPosition ([0.745, 0.596, 0.190, 0.040] call Waldo_MG_fnc_unoSafePositionLocal);
    _pageLabel ctrlSetTextColor [0.77, 0.86, 0.92, 1];
    _pageLabel ctrlSetFontHeight 0.022;
    _pageLabel ctrlCommit 0;
    _display setVariable ["Waldo_MG_UNOPageLabel", _pageLabel];
    private _previousButton = _display ctrlCreate ["RscButtonMenu", -1];
    _previousButton ctrlSetPosition ([0.030, 0.690, 0.045, 0.110] call Waldo_MG_fnc_unoSafePositionLocal);
    _previousButton ctrlSetText "<";
    _previousButton setVariable ["Waldo_MG_UNOPageDelta", -1];
    _previousButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_changeUNOPageLocal;}];
    _previousButton ctrlCommit 0;
    _display setVariable ["Waldo_MG_UNOPreviousButton", _previousButton];
    private _nextButton = _display ctrlCreate ["RscButtonMenu", -1];
    _nextButton ctrlSetPosition ([0.925, 0.690, 0.045, 0.110] call Waldo_MG_fnc_unoSafePositionLocal);
    _nextButton ctrlSetText ">";
    _nextButton setVariable ["Waldo_MG_UNOPageDelta", 1];
    _nextButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_changeUNOPageLocal;}];
    _nextButton ctrlCommit 0;
    _display setVariable ["Waldo_MG_UNONextButton", _nextButton];
    private _handCards = [];
    private _cardButtons = [];
    for "_slot" from 0 to (Waldo_MG_CFG_UNO_HAND_PAGE_SIZE - 1) do {
        private _bundle = [_display, 0.085 + (_slot * 0.083), 0.650, 0.072, 0.220, true] call Waldo_MG_fnc_createUNOCardControlsLocal;
        _handCards pushBack _bundle;
        _cardButtons pushBack (_bundle param [1, controlNull]);
    };
    _display setVariable ["Waldo_MG_UNOHandCards", _handCards];
    private _selectionLabel = _display ctrlCreate ["RscText", -1];
    _selectionLabel ctrlSetPosition ([0.040, 0.875, 0.900, 0.040] call Waldo_MG_fnc_unoSafePositionLocal);
    _selectionLabel ctrlSetTextColor [1, 0.77, 0.28, 1];
    _selectionLabel ctrlSetFontHeight 0.038;
    _selectionLabel ctrlCommit 0;
    _display setVariable ["Waldo_MG_UNOSelectionLabel", _selectionLabel];
    private _helpLabel = _display ctrlCreate ["RscText", -1];
    _helpLabel ctrlSetPosition ([0.040, 0.916, 0.900, 0.028] call Waldo_MG_fnc_unoSafePositionLocal);
    _helpLabel ctrlSetText "BRIGHT BORDER = PLAYABLE. SELECT ONE CARD OR TWO IDENTICAL NUMBERS.";
    _helpLabel ctrlSetTextColor [0.62, 0.73, 0.80, 1];
    _helpLabel ctrlSetFontHeight 0.030;
    _helpLabel ctrlCommit 0;
    _display setVariable ["Waldo_MG_UNOHelpLabel", _helpLabel];
    private _pageHelpLabel = _display ctrlCreate ["RscText", -1];
    _pageHelpLabel ctrlSetPosition ([0.040, 0.944, 0.900, 0.024] call Waldo_MG_fnc_unoSafePositionLocal);
    _pageHelpLabel ctrlSetText "USE THE SIDE ARROWS WHEN YOUR HAND SPANS MULTIPLE PAGES.";
    _pageHelpLabel ctrlSetTextColor [0.50, 0.64, 0.72, 1];
    _pageHelpLabel ctrlSetFontHeight 0.030;
    _pageHelpLabel ctrlCommit 0;
    _display setVariable ["Waldo_MG_UNOPageHelpLabel", _pageHelpLabel];

    private _interactive = [_leaveButton, _drawButton, _unoButton, _calloutButton, _playButton, _previousButton, _nextButton] + _cardButtons;
    _display setVariable ["Waldo_MG_UNOInteractiveControls", _interactive];

    private _dimmer = _display ctrlCreate ["RscText", -1];
    _dimmer ctrlSetPosition ([0.010, 0.015, 0.980, 0.970] call Waldo_MG_fnc_unoSafePositionLocal);
    _dimmer ctrlSetBackgroundColor [0, 0, 0, 0.72];
    _dimmer ctrlCommit 0;
    private _modalPanel = _display ctrlCreate ["RscText", -1];
    _modalPanel ctrlSetPosition ([0.300, 0.300, 0.400, 0.320] call Waldo_MG_fnc_unoSafePositionLocal);
    _modalPanel ctrlSetBackgroundColor [0.018, 0.030, 0.045, 1];
    _modalPanel ctrlCommit 0;
    private _modalPrompt = _display ctrlCreate ["RscText", -1];
    _modalPrompt ctrlSetPosition ([0.330, 0.325, 0.340, 0.045] call Waldo_MG_fnc_unoSafePositionLocal);
    _modalPrompt ctrlSetText "CHOOSE THE WILD CARD'S ACTIVE COLOUR";
    _modalPrompt ctrlSetTextColor [1, 0.90, 0.62, 1];
    _modalPrompt ctrlSetFontHeight 0.026;
    _modalPrompt ctrlCommit 0;
    private _modalControls = [_dimmer, _modalPanel, _modalPrompt];
    private _colourData = [
        [0, "RED", 0.330, 0.395],
        [1, "BLUE", 0.520, 0.395],
        [2, "GREEN", 0.330, 0.470],
        [3, "YELLOW", 0.520, 0.470]
    ];
    {
        private _button = _display ctrlCreate ["RscButton", -1];
        _button ctrlSetPosition ([_x param [2, 0], _x param [3, 0], 0.150, 0.060] call Waldo_MG_fnc_unoSafePositionLocal);
        _button ctrlSetText (_x param [1, "COLOUR"]);
        _button ctrlSetBackgroundColor ([_x param [0, 4]] call Waldo_MG_fnc_unoColourRGBA);
        _button ctrlSetTextColor ([_x param [0, 4]] call Waldo_MG_fnc_unoSymbolRGBA);
        _button setVariable ["Waldo_MG_UNOChosenColour", _x param [0, -1]];
        _button ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_chooseUNOColourLocal;}];
        _button ctrlCommit 0;
        _modalControls pushBack _button;
    } forEach _colourData;
    private _modalCancel = _display ctrlCreate ["RscButtonMenu", -1];
    _modalCancel ctrlSetPosition ([0.425, 0.550, 0.150, 0.040] call Waldo_MG_fnc_unoSafePositionLocal);
    _modalCancel ctrlSetText "Cancel";
    _modalCancel ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [ctrlParent _control, false] call Waldo_MG_fnc_setUNOColourModalLocal;}];
    _modalCancel ctrlCommit 0;
    _modalControls pushBack _modalCancel;
    _display setVariable ["Waldo_MG_UNOColourModalControls", _modalControls];
    [_display, false] call Waldo_MG_fnc_setUNOColourModalLocal;

    [_display] call Waldo_MG_fnc_refreshUNOLocal;
    [_display] spawn {
        disableSerialization;
        params ["_activeDisplay"];
        while {!isNull _activeDisplay} do {
            [_activeDisplay] call Waldo_MG_fnc_refreshUNOLocal;
            uiSleep Waldo_MG_CFG_UNO_UI_TICK;
        };
    };
};
