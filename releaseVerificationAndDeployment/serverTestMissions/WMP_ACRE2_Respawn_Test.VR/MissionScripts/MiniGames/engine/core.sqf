/*
 * Author: WaldoTheWarfighter
 * Implements the WMP table-minigame core: seating, lobby/menu state, server-authoritative rounds,
 * client presentation loops, spectating, result dispatch and shared display lifecycle hooks.
 *
 * Arguments: None. This included fragment declares Waldo_MG_fnc_* runtime functions.
 *
 * Return Value: Nothing directly; declared functions provide their own documented results.
 *
 * Example: #include "engine\core.sqf"
 * Current caller: MiniGamesInit includes this fragment during minigame bootstrap.
 */

Waldo_MG_fnc_getGame = {
    params [["_gameId", ""]];
    private _game = [];
    {
        if ((_x param [0, ""]) == _gameId) exitWith {
            _game = +_x;
        };
    } forEach Waldo_MG_Games;
    _game
};

Waldo_MG_fnc_getGameName = {
    params [["_gameId", ""]];
    private _game = [_gameId] call Waldo_MG_fnc_getGame;
    _game param [1, "No vote"]
};

Waldo_MG_fnc_getPlayerRequirementText = {
    params [["_game", []]];
    if ((count _game) < 5) exitWith {"Unknown player requirement"};
    private _minimum = _game param [3, 2];
    private _maximum = _game param [4, 4];
    if (_minimum == _maximum) exitWith {
        format ["Exactly %1 players", _minimum]
    };
    format ["%1-%2 players", _minimum, _maximum]
};

Waldo_MG_fnc_normalizeSeats = {
    params [["_source", []]];
    if ((typeName _source) != "ARRAY") then {
        _source = [];
    };
    private _result = [objNull, objNull, objNull, objNull];
    private _limit = (count _source) min Waldo_MG_CFG_SEAT_COUNT;
    if (_limit > 0) then {
        for "_index" from 0 to (_limit - 1) do {
            private _value = _source param [_index, objNull];
            if ((typeName _value) == "OBJECT") then {
                _result set [_index, _value];
            };
        };
    };
    _result
};

Waldo_MG_fnc_normalizeVotes = {
    params [["_source", []]];
    if ((typeName _source) != "ARRAY") then {
        _source = [];
    };
    private _result = ["", "", "", ""];
    private _limit = (count _source) min Waldo_MG_CFG_SEAT_COUNT;
    if (_limit > 0) then {
        for "_index" from 0 to (_limit - 1) do {
            private _value = _source param [_index, ""];
            if ((typeName _value) == "STRING") then {
                _result set [_index, _value];
            };
        };
    };
    _result
};

Waldo_MG_fnc_normalizeReady = {
    params [["_source", []]];
    if ((typeName _source) != "ARRAY") then {
        _source = [];
    };
    private _result = [false, false, false, false];
    private _limit = (count _source) min Waldo_MG_CFG_SEAT_COUNT;
    if (_limit > 0) then {
        for "_index" from 0 to (_limit - 1) do {
            private _value = _source param [_index, false];
            if ((typeName _value) == "BOOL") then {
                _result set [_index, _value];
            };
        };
    };
    _result
};

Waldo_MG_fnc_normalizeOccupancy = {
    params [["_source", []]];
    if ((typeName _source) != "ARRAY") then {
        _source = [];
    };
    private _result = [false, false, false, false];
    private _limit = (count _source) min Waldo_MG_CFG_SEAT_COUNT;
    if (_limit > 0) then {
        for "_index" from 0 to (_limit - 1) do {
            private _value = _source param [_index, false];
            if ((typeName _value) == "BOOL") then {
                _result set [_index, _value];
            };
        };
    };
    _result
};

Waldo_MG_fnc_getTableOccupantCount = {
    params [["_table", objNull]];
    if (isNull _table) exitWith {0};
    private _count = 0;
    {
        if (!isNull _x) then {
            _count = _count + 1;
        };
    } forEach ([(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats);
    _count
};

Waldo_MG_fnc_getVoteCount = {
    params [
        ["_table", objNull],
        ["_gameId", ""]
    ];
    if (isNull _table || {_gameId == ""}) exitWith {0};
    private _seats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
    private _votes = [(_table getVariable ["Waldo_MG_TableVotes", []])] call Waldo_MG_fnc_normalizeVotes;
    private _count = 0;
    for "_index" from 0 to (Waldo_MG_CFG_SEAT_COUNT - 1) do {
        if (!isNull (_seats param [_index, objNull]) && {(_votes param [_index, ""]) == _gameId}) then {
            _count = _count + 1;
        };
    };
    _count
};

Waldo_MG_fnc_isGameEligibleAtTable = {
    params [
        ["_table", objNull],
        ["_gameId", ""]
    ];
    if (isNull _table) exitWith {false};
    private _game = [_gameId] call Waldo_MG_fnc_getGame;
    if ((count _game) < 5) exitWith {false};
    private _players = [_table] call Waldo_MG_fnc_getTableOccupantCount;
    _players >= (_game param [3, 2]) && {_players <= (_game param [4, 4])}
};

Waldo_MG_fnc_getSeatIndex = {
    params [
        ["_table", objNull],
        ["_unit", objNull]
    ];
    if (isNull _table || {isNull _unit}) exitWith {-1};
    private _seats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
    _seats find _unit
};

Waldo_MG_fnc_getUnitKey = {
    params [["_unit", objNull]];
    if (isNull _unit) exitWith {""};
    private _key = getPlayerUID _unit;
    if (_key == "") then {
        _key = format ["NAME_%1", name _unit];
    };
    if (_key == "NAME_") then {
        _key = format ["NET_%1", netId _unit];
    };
    _key
};

Waldo_MG_fnc_makeToken = {
    params [["_prefix", "WMG"]];
    format [
        "%1_%2_%3_%4",
        _prefix,
        [player] call Waldo_MG_fnc_getUnitKey,
        floor (diag_tickTime * 1000),
        floor (random 1000000)
    ]
};

Waldo_MG_fnc_collectTaggedClassObjects = {
    params [
        ["_classes", []],
        ["_tag", ""]
    ];
    private _found = [];
    {
        if (isClass (configFile >> "CfgVehicles" >> _x)) then {
            {
                if (!isNull _x && {_x getVariable [_tag, false]}) then {
                    _found pushBackUnique _x;
                };
            } forEach (allMissionObjects _x);
        };
    } forEach _classes;
    _found
};

Waldo_MG_fnc_enforceInvulnerableLocal = {
    params [["_object", objNull]];
    if (isNull _object) exitWith {};
    if (local _object) then {
        _object allowDamage false;
    };
}; 
 

Waldo_MG_fnc_resultServer = {
    params [
        ["_unit", objNull],
        ["_token", ""],
        ["_message", ""]
    ];
    if (!isServer || {isNull _unit} || {_token == ""}) exitWith {};
    _unit setVariable ["Waldo_MG_RequestResult", [_token, _message], true];
};

Waldo_MG_fnc_rememberHandledTokenServer = {
    params [["_token", ""]];
    if (!isServer) exitWith {false};
    if (_token == "" || {(typeName _token) != "STRING"}) exitWith {false};
    private _handled = +(missionNamespace getVariable ["Waldo_MG_HandledTokensServer", []]);
    if (_token in _handled) exitWith {false};
    _handled pushBack _token;
    while {(count _handled) > 256} do {
        _handled deleteAt 0;
    };
    missionNamespace setVariable ["Waldo_MG_HandledTokensServer", _handled];
    true
};

Waldo_MG_fnc_getKnownCuratorsServer = {
    private _curators = [];
    if (!isServer) exitWith {_curators};
    {
        if (!isNull _x) then {
            _curators pushBackUnique _x;
        };
    } forEach allCurators;
    _curators
};

Waldo_MG_fnc_registerCuratorEditableServer = {
    params [["_object", objNull]];
    if (!isServer || {isNull _object}) exitWith {};
    {
        _x addCuratorEditableObjects [[_object], true];
    } forEach (call Waldo_MG_fnc_getKnownCuratorsServer);
};

Waldo_MG_fnc_getTableActiveGameId = {
    params [["_table", objNull]];
    if (isNull _table) exitWith {""};
    private _activeGame = "";
    if (_table getVariable ["Waldo_MG_BattleshipActive", false]) then {_activeGame = "battleship";};
    if (_activeGame == "" && {_table getVariable ["Waldo_MG_WhosWhoActive", false]}) then {_activeGame = "whoswho";};
    if (_activeGame == "" && {_table getVariable ["Waldo_MG_ShotgunActive", false]}) then {_activeGame = "shotgun";};
    if (_activeGame == "" && {_table getVariable ["Waldo_MG_CheckersActive", false]}) then {_activeGame = "checkers";};
    if (_activeGame == "" && {_table getVariable ["Waldo_MG_RPSActive", false]}) then {_activeGame = "rps";};
    if (_activeGame == "" && {_table getVariable ["Waldo_MG_BlackjackActive", false]}) then {_activeGame = "blackjack";};
    if (_activeGame == "" && {_table getVariable ["Waldo_MG_ChessActive", false]}) then {_activeGame = "chess";};
    if (_activeGame == "" && {_table getVariable ["Waldo_MG_PokerActive", false]}) then {_activeGame = "poker";};
    if (_activeGame == "" && {_table getVariable ["Waldo_MG_DrawPokerActive", false]}) then {_activeGame = "drawpoker";};
    if (_activeGame == "" && {_table getVariable ["Waldo_MG_LiarsDiceActive", false]}) then {_activeGame = "liarsdice";};
    if (_activeGame == "" && {_table getVariable ["Waldo_MG_ConnectFourActive", false]}) then {_activeGame = "connectfour";};
    if (_activeGame == "" && {_table getVariable ["Waldo_MG_UNOActive", false]}) then {_activeGame = "uno";};
    if (_activeGame == "") then {
        private _phase = _table getVariable ["Waldo_MG_TablePhase", "LOBBY"];
        private _selected = _table getVariable ["Waldo_MG_TableSelectedGame", ""];
        if (_phase in ["PLAYING", "FINISHED"] && {_selected in ["battleship", "whoswho", "shotgun", "checkers", "rps", "blackjack", "chess", "poker", "drawpoker", "liarsdice", "connectfour", "uno"]}) then {
            _activeGame = _selected;
        };
    };
    _activeGame
};

Waldo_MG_fnc_isTableGameActive = {
    params [["_table", objNull]];
    ([_table] call Waldo_MG_fnc_getTableActiveGameId) != ""
};

Waldo_MG_fnc_refreshTableConsensusServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};

    private _seats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
    private _votes = [(_table getVariable ["Waldo_MG_TableVotes", []])] call Waldo_MG_fnc_normalizeVotes;
    private _ready = [(_table getVariable ["Waldo_MG_TableReady", []])] call Waldo_MG_fnc_normalizeReady;
    private _occupancy = [false, false, false, false];
    private _occupied = 0;
    for "_index" from 0 to (Waldo_MG_CFG_SEAT_COUNT - 1) do {
        if (!isNull (_seats param [_index, objNull])) then {
            _occupancy set [_index, true];
            _occupied = _occupied + 1;
        };
    };

    private _bestGameId = "";
    private _bestVotes = 0;
    {
        private _gameId = _x param [0, ""];
        private _minimum = _x param [3, 2];
        private _maximum = _x param [4, 4];
        if (_occupied >= _minimum && {_occupied <= _maximum}) then {
            private _voteCount = 0;
            for "_index" from 0 to (Waldo_MG_CFG_SEAT_COUNT - 1) do {
                if ((_occupancy param [_index, false]) && {(_votes param [_index, ""]) == _gameId}) then {
                    _voteCount = _voteCount + 1;
                };
            };
            if (_voteCount > _bestVotes) then {
                _bestVotes = _voteCount;
                _bestGameId = _gameId;
            };
        };
    } forEach Waldo_MG_Games;

    private _requiredVotes = if (_occupied > 0) then {
        floor (_occupied / 2) + 1
    } else {
        1
    };
    private _selectedGame = "";
    if (_bestVotes >= _requiredVotes) then {
        _selectedGame = _bestGameId;
    };

    private _selectedCatalogEntry = [_selectedGame] call Waldo_MG_fnc_getGame;
    private _selectedMinimum = _selectedCatalogEntry param [3, 2];
    private _allReady = _selectedGame != "" && {_occupied >= _selectedMinimum};
    if (_allReady) then {
        for "_index" from 0 to (Waldo_MG_CFG_SEAT_COUNT - 1) do {
            if (!isNull (_seats param [_index, objNull])) then {
                if (!(_ready param [_index, false])) then {
                    _allReady = false;
                };
            };
        };
    };

    private _phase = if (_allReady) then {"READY"} else {"LOBBY"};
    if (_table getVariable ["Waldo_MG_WhosWhoActive", false]) then {
        _selectedGame = "whoswho";
        _phase = _table getVariable ["Waldo_MG_TablePhase", "PLAYING"];
        if (!(_phase in ["PLAYING", "FINISHED"])) then {
            _phase = "PLAYING";
        };
    };
    if (_table getVariable ["Waldo_MG_ShotgunActive", false]) then {
        _selectedGame = "shotgun";
        _phase = _table getVariable ["Waldo_MG_TablePhase", "PLAYING"];
        if (!(_phase in ["PLAYING", "FINISHED"])) then {
            _phase = "PLAYING";
        };
    };
    if (_table getVariable ["Waldo_MG_CheckersActive", false]) then {
        _selectedGame = "checkers";
        _phase = _table getVariable ["Waldo_MG_TablePhase", "PLAYING"];
        if (!(_phase in ["PLAYING", "FINISHED"])) then {
            _phase = "PLAYING";
        };
    };
    if (_table getVariable ["Waldo_MG_RPSActive", false]) then {
        _selectedGame = "rps";
        _phase = _table getVariable ["Waldo_MG_TablePhase", "PLAYING"];
        if (!(_phase in ["PLAYING", "FINISHED"])) then {
            _phase = "PLAYING";
        };
    };
    if (_table getVariable ["Waldo_MG_BlackjackActive", false]) then {
        _selectedGame = "blackjack";
        _phase = _table getVariable ["Waldo_MG_TablePhase", "PLAYING"];
        if (!(_phase in ["PLAYING", "FINISHED"])) then {
            _phase = "PLAYING";
        };
    };
    if (_table getVariable ["Waldo_MG_ChessActive", false]) then {
        _selectedGame = "chess";
        _phase = _table getVariable ["Waldo_MG_TablePhase", "PLAYING"];
        if (!(_phase in ["PLAYING", "FINISHED"])) then {
            _phase = "PLAYING";
        };
    };
    if (_table getVariable ["Waldo_MG_PokerActive", false]) then {
        _selectedGame = "poker";
        _phase = _table getVariable ["Waldo_MG_TablePhase", "PLAYING"];
        if (!(_phase in ["PLAYING", "FINISHED"])) then {
            _phase = "PLAYING";
        };
    };
    if (_table getVariable ["Waldo_MG_DrawPokerActive", false]) then {
        _selectedGame = "drawpoker";
        _phase = _table getVariable ["Waldo_MG_TablePhase", "PLAYING"];
        if (!(_phase in ["PLAYING", "FINISHED"])) then {_phase = "PLAYING";};
    };
    if (_table getVariable ["Waldo_MG_LiarsDiceActive", false]) then {
        _selectedGame = "liarsdice";
        _phase = _table getVariable ["Waldo_MG_TablePhase", "PLAYING"];
        if (!(_phase in ["PLAYING", "FINISHED"])) then {_phase = "PLAYING";};
    };
    if (_table getVariable ["Waldo_MG_ConnectFourActive", false]) then {
        _selectedGame = "connectfour";
        _phase = _table getVariable ["Waldo_MG_TablePhase", "PLAYING"];
        if (!(_phase in ["PLAYING", "FINISHED"])) then {_phase = "PLAYING";};
    };
    if (_table getVariable ["Waldo_MG_UNOActive", false]) then {
        _selectedGame = "uno";
        _phase = _table getVariable ["Waldo_MG_TablePhase", "PLAYING"];
        if (!(_phase in ["PLAYING", "FINISHED"])) then {
            _phase = "PLAYING";
        };
    };
    private _changed = false;
    {
        _x params ["_name", "_value", "_fallback"];
        if !((_table getVariable [_name, _fallback]) isEqualTo _value) then {
            _table setVariable [_name, _value, true];
            _changed = true;
        };
    } forEach [
        ["Waldo_MG_TableSeats", _seats, []],
        ["Waldo_MG_TableVotes", _votes, []],
        ["Waldo_MG_TableReady", _ready, []],
        ["Waldo_MG_TableOccupancy", _occupancy, []],
        ["Waldo_MG_TableSelectedGame", _selectedGame, ""],
        ["Waldo_MG_TableRequiredVotes", _requiredVotes, -1],
        ["Waldo_MG_TablePhase", _phase, ""]
    ];
    if (_changed) then {
        _table setVariable [
            "Waldo_MG_TableRevision",
            (_table getVariable ["Waldo_MG_TableRevision", 0]) + 1,
            true
        ];
    };
};

Waldo_MG_fnc_markTableServer = {
    params [
        ["_table", objNull],
        ["_creatorName", "Composition"],
        ["_creatorKey", "COMPOSITION"]
    ];
    if (!isServer || {isNull _table}) exitWith {objNull};

    private _wasMarked = _table getVariable ["Waldo_MG_IsPartyTable", false];
    [_table] call Waldo_MG_fnc_enforceInvulnerableLocal;
    _table setVariable ["Waldo_MG_IsPartyTable", true, true];
    if (!_wasMarked) then {
        _table setVariable [
            "Waldo_MG_TableId",
            format ["Waldo_MG_TABLE_%1_%2", floor (serverTime * 10), floor (random 1000000)],
            true
        ];
        _table setVariable ["Waldo_MG_TableCreatorName", _creatorName, true];
        _table setVariable ["Waldo_MG_TableCreatorKey", _creatorKey, true];
        _table setVariable ["Waldo_MG_TableSeats", [objNull, objNull, objNull, objNull], true];
        _table setVariable ["Waldo_MG_TableVotes", ["", "", "", ""], true];
        _table setVariable ["Waldo_MG_TableReady", [false, false, false, false], true];
        _table setVariable ["Waldo_MG_TableOccupancy", [false, false, false, false], true];
        _table setVariable ["Waldo_MG_TableSelectedGame", "", true];
        _table setVariable ["Waldo_MG_TableRequiredVotes", 1, true];
        _table setVariable ["Waldo_MG_TablePhase", "LOBBY", true];
        _table setVariable ["Waldo_MG_TableRevision", 0, true];
        [_table] call Waldo_MG_fnc_battleshipClearServer;
        [_table] call Waldo_MG_fnc_whosWhoClearServer;
        [_table] call Waldo_MG_fnc_shotgunClearServer;
        [_table] call Waldo_MG_fnc_checkersClearServer;
        [_table] call Waldo_MG_fnc_rpsClearServer;
        [_table] call Waldo_MG_fnc_blackjackClearServer;
        [_table] call Waldo_MG_fnc_chessClearServer;
        [_table] call Waldo_MG_fnc_pokerClearServer;
        [_table] call Waldo_MG_fnc_drawPokerClearServer;
        [_table] call Waldo_MG_fnc_liarsDiceClearServer;
        [_table] call Waldo_MG_fnc_connectFourClearServer;
        [_table] call Waldo_MG_fnc_unoClearServer;
        [_table] call Waldo_MG_fnc_refreshTableConsensusServer;
    };

    private _tables = +(missionNamespace getVariable ["Waldo_MG_Tables", []]);
    _tables pushBackUnique _table;
    missionNamespace setVariable ["Waldo_MG_Tables", _tables, true];
    [_table] call Waldo_MG_fnc_registerCuratorEditableServer;
    _table
};

Waldo_MG_fnc_clearUnitSeatVariablesServer = {
    params [["_unit", objNull]];
    if (!isServer || {isNull _unit}) exitWith {};
    _unit setVariable ["Waldo_MG_BattleshipPrivateFleet", [], owner _unit];
    _unit setVariable ["Waldo_MG_UNOPrivateHand", [], owner _unit];
    _unit setVariable ["Waldo_MG_ShotgunPrivatePeek", [], owner _unit];
    _unit setVariable ["Waldo_MG_WhosWhoPrivateTarget", [], owner _unit];
    _unit setVariable ["Waldo_MG_PokerPrivateHand", [], owner _unit];
    _unit setVariable ["Waldo_MG_DrawPokerPrivateHand", [], owner _unit];
    _unit setVariable ["Waldo_MG_LiarsDicePrivateDice", [], owner _unit];
    _unit setVariable ["Waldo_MG_SeatedTable", objNull, true];
    _unit setVariable ["Waldo_MG_SeatIndex", -1, true];
    _unit setVariable ["Waldo_MG_SeatToken", "", true];
};

Waldo_MG_fnc_releaseUnitSeatServer = {
    params [["_unit", objNull]];
    if (!isServer || {isNull _unit}) exitWith {};
    private _table = _unit getVariable ["Waldo_MG_SeatedTable", objNull];
    private _seatIndex = _unit getVariable ["Waldo_MG_SeatIndex", -1];
    if (!isNull _table) then {
        // Only the active implementation may mutate game state. Calling every
        // departure handler made leaving depend on twelve unrelated functions
        // being present and error-free, and could stop before the seat cleared.
        switch ([_table] call Waldo_MG_fnc_getTableActiveGameId) do {
            case "battleship": {[_table, _unit, _seatIndex] call Waldo_MG_fnc_battleshipHandleDepartureServer;};
            case "whoswho": {[_table, _unit, _seatIndex] call Waldo_MG_fnc_whosWhoHandleDepartureServer;};
            case "shotgun": {[_table, _unit, _seatIndex] call Waldo_MG_fnc_shotgunHandleDepartureServer;};
            case "checkers": {[_table, _unit, _seatIndex] call Waldo_MG_fnc_checkersFinishForfeitServer;};
            case "rps": {[_table, _unit, _seatIndex] call Waldo_MG_fnc_rpsFinishForfeitServer;};
            case "blackjack": {[_table, _unit, _seatIndex] call Waldo_MG_fnc_blackjackHandleDepartureServer;};
            case "chess": {[_table, _unit, _seatIndex] call Waldo_MG_fnc_chessFinishForfeitServer;};
            case "poker": {[_table, _unit, _seatIndex] call Waldo_MG_fnc_pokerHandleDepartureServer;};
            case "drawpoker": {[_table, _unit, _seatIndex] call Waldo_MG_fnc_drawPokerFinishForfeitServer;};
            case "liarsdice": {[_table, _unit, _seatIndex] call Waldo_MG_fnc_liarsDiceFinishForfeitServer;};
            case "connectfour": {[_table, _unit, _seatIndex] call Waldo_MG_fnc_connectFourFinishForfeitServer;};
            case "uno": {[_table, _unit, _seatIndex] call Waldo_MG_fnc_unoHandleDepartureServer;};
        };
        private _seats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
        if (_seatIndex < 0 || {_seatIndex >= Waldo_MG_CFG_SEAT_COUNT} || {(_seats param [_seatIndex, objNull]) != _unit}) then {
            _seatIndex = _seats find _unit;
        };
        if (_seatIndex >= 0 && {_seatIndex < Waldo_MG_CFG_SEAT_COUNT}) then {
            private _votes = [(_table getVariable ["Waldo_MG_TableVotes", []])] call Waldo_MG_fnc_normalizeVotes;
            _seats set [_seatIndex, objNull];
            _votes set [_seatIndex, ""];
            _table setVariable ["Waldo_MG_TableSeats", _seats, true];
            _table setVariable ["Waldo_MG_TableVotes", _votes, true];
            _table setVariable ["Waldo_MG_TableReady", [false, false, false, false], true];
            [_table] call Waldo_MG_fnc_refreshTableConsensusServer;
        };
    };
    [_unit] call Waldo_MG_fnc_clearUnitSeatVariablesServer;
};

Waldo_MG_fnc_initializePlayerServer = {
    params [["_unit", objNull]];
    if (!isServer || {isNull _unit}) exitWith {};
    if (_unit getVariable ["Waldo_MG_ServerInitialized", false]) exitWith {};
    if (isNil {_unit getVariable "Waldo_MG_SeatedTable"}) then {
        _unit setVariable ["Waldo_MG_SeatedTable", objNull, true];
    };
    if (isNil {_unit getVariable "Waldo_MG_SeatIndex"}) then {
        _unit setVariable ["Waldo_MG_SeatIndex", -1, true];
    };
    if (isNil {_unit getVariable "Waldo_MG_SeatToken"}) then {
        _unit setVariable ["Waldo_MG_SeatToken", "", true];
    };
    {
        if (isNil {_unit getVariable _x}) then {
            _unit setVariable [_x, [], true];
        };
    } forEach [
        "Waldo_MG_JoinRequest",
        "Waldo_MG_LeaveRequest",
        "Waldo_MG_VoteRequest",
        "Waldo_MG_ReadyRequest",
        "Waldo_MG_BattleshipActionRequest",
        "Waldo_MG_WhosWhoActionRequest",
        "Waldo_MG_ShotgunActionRequest",
        "Waldo_MG_CheckersMoveRequest",
        "Waldo_MG_CheckersResetRequest",
        "Waldo_MG_RPSActionRequest",
        "Waldo_MG_BlackjackActionRequest",
        "Waldo_MG_ChessMoveRequest",
        "Waldo_MG_ChessActionRequest",
        "Waldo_MG_PokerActionRequest",
        "Waldo_MG_DrawPokerActionRequest",
        "Waldo_MG_LiarsDiceActionRequest",
        "Waldo_MG_ConnectFourActionRequest",
        "Waldo_MG_UNOActionRequest",
        "Waldo_MG_RequestResult"
    ];
    _unit setVariable ["Waldo_MG_ServerInitialized", true];
};

Waldo_MG_fnc_reconcileOneTableServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    [_table] call Waldo_MG_fnc_enforceInvulnerableLocal;
    switch ([_table] call Waldo_MG_fnc_getTableActiveGameId) do {
        case "battleship": {[_table] call Waldo_MG_fnc_battleshipReconcilePlayersServer;};
        case "whoswho": {[_table] call Waldo_MG_fnc_whosWhoReconcilePlayersServer;};
        case "shotgun": {
            [_table] call Waldo_MG_fnc_shotgunReconcilePlayersServer;
            [_table] call Waldo_MG_fnc_shotgunProgressServer;
        };
        case "checkers": {[_table] call Waldo_MG_fnc_checkersReconcilePlayersServer;};
        case "rps": {
            [_table] call Waldo_MG_fnc_rpsReconcilePlayersServer;
            [_table] call Waldo_MG_fnc_rpsProgressServer;
        };
        case "blackjack": {
            [_table] call Waldo_MG_fnc_blackjackReconcilePlayersServer;
            [_table] call Waldo_MG_fnc_blackjackProgressServer;
        };
        case "chess": {[_table] call Waldo_MG_fnc_chessReconcilePlayersServer;};
        case "poker": {[_table] call Waldo_MG_fnc_pokerReconcilePlayersServer;};
        case "drawpoker": {[_table] call Waldo_MG_fnc_drawPokerReconcilePlayersServer;};
        case "liarsdice": {
            [_table] call Waldo_MG_fnc_liarsDiceReconcilePlayersServer;
            [_table] call Waldo_MG_fnc_liarsDiceProgressServer;
        };
        case "connectfour": {[_table] call Waldo_MG_fnc_connectFourReconcilePlayersServer;};
        case "uno": {[_table] call Waldo_MG_fnc_unoReconcilePlayersServer;};
    };
    private _originalSeats = _table getVariable ["Waldo_MG_TableSeats", []];
    private _originalVotes = _table getVariable ["Waldo_MG_TableVotes", []];
    private _originalReady = _table getVariable ["Waldo_MG_TableReady", []];
    private _originalOccupancy = _table getVariable ["Waldo_MG_TableOccupancy", []];
    private _seats = [_originalSeats] call Waldo_MG_fnc_normalizeSeats;
    private _votes = [_originalVotes] call Waldo_MG_fnc_normalizeVotes;
    private _ready = [_originalReady] call Waldo_MG_fnc_normalizeReady;
    private _occupancy = [_originalOccupancy] call Waldo_MG_fnc_normalizeOccupancy;
    private _changed = (typeName _originalSeats) != "ARRAY"
        || {(typeName _originalVotes) != "ARRAY"}
        || {(typeName _originalReady) != "ARRAY"}
        || {(typeName _originalOccupancy) != "ARRAY"}
        || {(count _originalSeats) != Waldo_MG_CFG_SEAT_COUNT}
        || {(count _originalVotes) != Waldo_MG_CFG_SEAT_COUNT}
        || {(count _originalReady) != Waldo_MG_CFG_SEAT_COUNT}
        || {(count _originalOccupancy) != Waldo_MG_CFG_SEAT_COUNT};

    for "_index" from 0 to (Waldo_MG_CFG_SEAT_COUNT - 1) do {
        private _unit = _seats param [_index, objNull];
        if (!isNull _unit) then {
            private _valid = alive _unit
                && {(lifeState _unit) != "INCAPACITATED"}
                && {_unit in allPlayers}
                && {(vehicle _unit) == _unit}
                && {(_unit getVariable ["Waldo_MG_SeatedTable", objNull]) == _table}
                && {(_unit getVariable ["Waldo_MG_SeatIndex", -1]) == _index};
            if (!_valid) then {
                if ((_unit getVariable ["Waldo_MG_SeatedTable", objNull]) == _table && {(_unit getVariable ["Waldo_MG_SeatIndex", -1]) == _index}) then {
                    [_unit] call Waldo_MG_fnc_clearUnitSeatVariablesServer;
                };
                _seats set [_index, objNull];
                _votes set [_index, ""];
                _occupancy set [_index, false];
                _changed = true;
            } else {
                if (!(_occupancy param [_index, false])) then {
                    _occupancy set [_index, true];
                    _changed = true;
                };
            };
        } else {
            if ((_occupancy param [_index, false]) || {(_votes param [_index, ""]) != ""} || {_ready param [_index, false]}) then {
                _changed = true;
            };
            _occupancy set [_index, false];
            _votes set [_index, ""];
            _ready set [_index, false];
        };
    };

    if (_changed) then {
        _table setVariable ["Waldo_MG_TableSeats", _seats, true];
        _table setVariable ["Waldo_MG_TableVotes", _votes, true];
        _table setVariable ["Waldo_MG_TableOccupancy", _occupancy, true];
        _table setVariable ["Waldo_MG_TableReady", [false, false, false, false], true];
        [_table] call Waldo_MG_fnc_refreshTableConsensusServer;
    };
};

Waldo_MG_fnc_reconcileRegisteredTablesServer = {
    if (!isServer) exitWith {};
    private _published = +(missionNamespace getVariable ["Waldo_MG_Tables", []]);
    private _clean = [];
    {
        if (!isNull _x && {_x getVariable ["Waldo_MG_IsPartyTable", false]}) then {
            _clean pushBackUnique _x;
            [_x] call Waldo_MG_fnc_reconcileOneTableServer;
        };
    } forEach _published;
    if ((count _clean) != (count _published)) then {
        missionNamespace setVariable ["Waldo_MG_Tables", _clean, true];
    };

    {
        private _unit = _x;
        private _table = _unit getVariable ["Waldo_MG_SeatedTable", objNull];
        private _seatIndex = _unit getVariable ["Waldo_MG_SeatIndex", -1];
        private _valid = false;
        if (!isNull _table && {_table getVariable ["Waldo_MG_IsPartyTable", false]}) then {
            private _seats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
            _valid = _seatIndex >= 0
                && {_seatIndex < Waldo_MG_CFG_SEAT_COUNT}
                && {(_seats param [_seatIndex, objNull]) == _unit}
                && {alive _unit}
                && {(vehicle _unit) == _unit};
        };
        if (!_valid && {(!isNull _table) || {_seatIndex >= 0}}) then {
            [_unit] call Waldo_MG_fnc_clearUnitSeatVariablesServer;
        };
    } forEach allPlayers;
};

Waldo_MG_fnc_reconcileRegistriesServer = {
    if (!isServer) exitWith {};
    private _tables = +(missionNamespace getVariable ["Waldo_MG_Tables", []]);
    private _seeded = [Waldo_MG_CFG_TABLE_CLASSES, "Waldo_MG_CompositionSeed"] call Waldo_MG_fnc_collectTaggedClassObjects;
    private _tagged = [Waldo_MG_CFG_TABLE_CLASSES, "Waldo_MG_IsPartyTable"] call Waldo_MG_fnc_collectTaggedClassObjects;
    {
        if (!isNull _x) then {
            if (!(_x getVariable ["Waldo_MG_IsPartyTable", false])) then {
                [_x, "Composition", "COMPOSITION"] call Waldo_MG_fnc_markTableServer;
            };
            _tables pushBackUnique _x;
        };
    } forEach (_seeded + _tagged);
    private _clean = [];
    {
        if (!isNull _x && {_x getVariable ["Waldo_MG_IsPartyTable", false]}) then {
            _clean pushBackUnique _x;
        };
    } forEach _tables;
    missionNamespace setVariable ["Waldo_MG_Tables", _clean, true];
    call Waldo_MG_fnc_reconcileRegisteredTablesServer;
    {
        [_x] call Waldo_MG_fnc_registerCuratorEditableServer;
    } forEach _clean;
}; 
 

Waldo_MG_fnc_processJoinRequestServer = {
    params [
        ["_unit", objNull],
        ["_request", []]
    ];
    if (!isServer || {isNull _unit}) exitWith {};
    _unit setVariable ["Waldo_MG_JoinRequest", [], true];
    if ((count _request) < 3) exitWith {};
    private _token = _request param [0, ""];
    if (!([_token] call Waldo_MG_fnc_rememberHandledTokenServer)) exitWith {};
    if (!alive _unit) exitWith {
        [_unit, _token, "You must be alive to join a party table."] call Waldo_MG_fnc_resultServer;
    };
    if ((lifeState _unit) == "INCAPACITATED") exitWith {
        [_unit, _token, "Recover before trying to sit at a party table."] call Waldo_MG_fnc_resultServer;
    };
    if ((vehicle _unit) != _unit) exitWith {
        [_unit, _token, "Leave your vehicle before sitting at the table."] call Waldo_MG_fnc_resultServer;
    };
    if (!isNull (_unit getVariable ["Waldo_MG_SeatedTable", objNull])) exitWith {
        [_unit, _token, "You are already seated at a party table."] call Waldo_MG_fnc_resultServer;
    };
    if (!isNull (attachedTo _unit)) exitWith {
        [_unit, _token, "You are already attached to something else and cannot take a table seat."] call Waldo_MG_fnc_resultServer;
    };

    private _tableNetId = _request param [1, ""];
    private _requestPos = _request param [2, []];
    if ((typeName _tableNetId) != "STRING" || {(typeName _requestPos) != "ARRAY"}) exitWith {
        [_unit, _token, "Seat request rejected: malformed request data."] call Waldo_MG_fnc_resultServer;
    };
    private _table = objectFromNetId _tableNetId;
    if (isNull _table || {!(_table getVariable ["Waldo_MG_IsPartyTable", false])}) exitWith {
        [_unit, _token, "That party table is no longer available."] call Waldo_MG_fnc_resultServer;
    };
    if ([_table] call Waldo_MG_fnc_isTableGameActive) exitWith {
        [_unit, _token, "That table is in the middle of a game."] call Waldo_MG_fnc_resultServer;
    };
    if ((count _requestPos) < 2) exitWith {
        [_unit, _token, "Seat request rejected: missing player position."] call Waldo_MG_fnc_resultServer;
    };
    if ((typeName (_requestPos param [0, 0])) != "SCALAR" || {(typeName (_requestPos param [1, 0])) != "SCALAR"}) exitWith {
        [_unit, _token, "Seat request rejected: invalid player position."] call Waldo_MG_fnc_resultServer;
    };
    if ((_unit distance _table) > Waldo_MG_CFG_REQUEST_RANGE) exitWith {
        [_unit, _token, "Move closer to the party table."] call Waldo_MG_fnc_resultServer;
    };
    if ((_requestPos distance2D _table) > Waldo_MG_CFG_REQUEST_RANGE) exitWith {
        [_unit, _token, "Seat request was too far from the table."] call Waldo_MG_fnc_resultServer;
    };

    private _seats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
    private _seatIndex = -1;
    for "_index" from 0 to (Waldo_MG_CFG_SEAT_COUNT - 1) do {
        if (_seatIndex < 0 && {isNull (_seats param [_index, objNull])}) then {
            _seatIndex = _index;
        };
    };
    if (_seatIndex < 0) exitWith {
        [_unit, _token, "That party table already has four players."] call Waldo_MG_fnc_resultServer;
    };

    private _votes = [(_table getVariable ["Waldo_MG_TableVotes", []])] call Waldo_MG_fnc_normalizeVotes;
    _seats set [_seatIndex, _unit];
    _votes set [_seatIndex, ""];
    _table setVariable ["Waldo_MG_TableSeats", _seats, true];
    _table setVariable ["Waldo_MG_TableVotes", _votes, true];
    _table setVariable ["Waldo_MG_TableReady", [false, false, false, false], true];
    _unit setVariable ["Waldo_MG_SeatedTable", _table, true];
    _unit setVariable ["Waldo_MG_SeatIndex", _seatIndex, true];
    _unit setVariable ["Waldo_MG_SeatToken", _token, true];
    [_table] call Waldo_MG_fnc_refreshTableConsensusServer;
    [_unit, _token, format [
        "Seat %1 reserved. The Mini Games lobby is opening.",
        _seatIndex + 1
    ]] call Waldo_MG_fnc_resultServer;
};

Waldo_MG_fnc_processLeaveRequestServer = {
    params [
        ["_unit", objNull],
        ["_request", []]
    ];
    if (!isServer || {isNull _unit}) exitWith {};
    _unit setVariable ["Waldo_MG_LeaveRequest", [], true];
    if ((count _request) < 1) exitWith {};
    private _token = _request param [0, ""];
    if (!([_token] call Waldo_MG_fnc_rememberHandledTokenServer)) exitWith {};
    private _table = _unit getVariable ["Waldo_MG_SeatedTable", objNull];
    if (isNull _table) exitWith {
        [_unit] call Waldo_MG_fnc_clearUnitSeatVariablesServer;
        [_unit, _token, "You are not currently seated at a party table."] call Waldo_MG_fnc_resultServer;
    };
    [_unit] call Waldo_MG_fnc_releaseUnitSeatServer;
    [_unit, _token, "You left the party table."] call Waldo_MG_fnc_resultServer;
};

Waldo_MG_fnc_processVoteRequestServer = {
    params [
        ["_unit", objNull],
        ["_request", []]
    ];
    if (!isServer || {isNull _unit}) exitWith {};
    _unit setVariable ["Waldo_MG_VoteRequest", [], true];
    if ((count _request) < 3) exitWith {};
    private _token = _request param [0, ""];
    if (!([_token] call Waldo_MG_fnc_rememberHandledTokenServer)) exitWith {};
    if (!alive _unit) exitWith {
        [_unit, _token, "Only living players may vote at the table."] call Waldo_MG_fnc_resultServer;
    };
    private _tableNetId = _request param [1, ""];
    private _gameId = _request param [2, ""];
    if ((typeName _tableNetId) != "STRING" || {(typeName _gameId) != "STRING"}) exitWith {
        [_unit, _token, "Vote rejected: malformed request data."] call Waldo_MG_fnc_resultServer;
    };
    private _table = objectFromNetId _tableNetId;
    if (isNull _table || {_table != (_unit getVariable ["Waldo_MG_SeatedTable", objNull])}) exitWith {
        [_unit, _token, "Vote rejected: you are no longer seated at that table."] call Waldo_MG_fnc_resultServer;
    };
    if ([_table] call Waldo_MG_fnc_isTableGameActive) exitWith {
        [_unit, _token, "Voting is locked while a table game is in progress."] call Waldo_MG_fnc_resultServer;
    };
    private _seatIndex = [_table, _unit] call Waldo_MG_fnc_getSeatIndex;
    if (_seatIndex < 0) exitWith {
        [_unit, _token, "Vote rejected: your seat assignment is stale."] call Waldo_MG_fnc_resultServer;
    };
    private _game = [_gameId] call Waldo_MG_fnc_getGame;
    if ((count _game) < 5) exitWith {
        [_unit, _token, "That game is not in the Mini Games catalog."] call Waldo_MG_fnc_resultServer;
    };
    if (!([_table, _gameId] call Waldo_MG_fnc_isGameEligibleAtTable)) exitWith {
        [_unit, _token, format [
            "%1 is locked for the current table size. It requires %2.",
            _game param [1, "Game"],
            [_game] call Waldo_MG_fnc_getPlayerRequirementText
        ]] call Waldo_MG_fnc_resultServer;
    };

    private _votes = [(_table getVariable ["Waldo_MG_TableVotes", []])] call Waldo_MG_fnc_normalizeVotes;
    if ((_votes param [_seatIndex, ""]) == _gameId) exitWith {
        [_unit, _token, format [
            "Your vote for %1 is already recorded. Ready states were left unchanged.",
            _game param [1, "Game"]
        ]] call Waldo_MG_fnc_resultServer;
    };
    _votes set [_seatIndex, _gameId];
    _table setVariable ["Waldo_MG_TableVotes", _votes, true];
    _table setVariable ["Waldo_MG_TableReady", [false, false, false, false], true];
    [_table] call Waldo_MG_fnc_refreshTableConsensusServer;
    [_unit, _token, format [
        "Vote recorded for %1. A ballot change clears every ready state.",
        _game param [1, "Game"]
    ]] call Waldo_MG_fnc_resultServer;
};

Waldo_MG_fnc_processReadyRequestServer = {
    params [
        ["_unit", objNull],
        ["_request", []]
    ];
    if (!isServer || {isNull _unit}) exitWith {};
    _unit setVariable ["Waldo_MG_ReadyRequest", [], true];
    if ((count _request) < 3) exitWith {};
    private _token = _request param [0, ""];
    if (!([_token] call Waldo_MG_fnc_rememberHandledTokenServer)) exitWith {};
    if (!alive _unit) exitWith {
        [_unit, _token, "Only living players may ready at the table."] call Waldo_MG_fnc_resultServer;
    };
    private _tableNetId = _request param [1, ""];
    private _desired = _request param [2, false];
    if ((typeName _tableNetId) != "STRING") exitWith {
        [_unit, _token, "Ready request rejected: malformed table data."] call Waldo_MG_fnc_resultServer;
    };
    private _table = objectFromNetId _tableNetId;
    if ((typeName _desired) != "BOOL") then {
        if ((typeName _desired) == "SCALAR") then {
            _desired = _desired > 0;
        } else {
            _desired = false;
        };
    };
    if (isNull _table || {_table != (_unit getVariable ["Waldo_MG_SeatedTable", objNull])}) exitWith {
        [_unit, _token, "Ready request rejected: you are no longer at that table."] call Waldo_MG_fnc_resultServer;
    };
    if ([_table] call Waldo_MG_fnc_isTableGameActive) exitWith {
        [_unit, _token, "Ready state is locked while a table game is in progress."] call Waldo_MG_fnc_resultServer;
    };
    private _seatIndex = [_table, _unit] call Waldo_MG_fnc_getSeatIndex;
    if (_seatIndex < 0) exitWith {
        [_unit, _token, "Ready request rejected: your seat assignment is stale."] call Waldo_MG_fnc_resultServer;
    };
    private _selectedGame = _table getVariable ["Waldo_MG_TableSelectedGame", ""];
    if (_desired && {_selectedGame == ""}) exitWith {
        [_unit, _token, "The table needs a strict-majority game vote before anyone can ready."] call Waldo_MG_fnc_resultServer;
    };

    private _ready = [(_table getVariable ["Waldo_MG_TableReady", []])] call Waldo_MG_fnc_normalizeReady;
    if ((_ready param [_seatIndex, false]) == _desired) exitWith {
        [_unit, _token, if (_desired) then {
            "You are already marked ready."
        } else {
            "You are already marked not ready."
        }] call Waldo_MG_fnc_resultServer;
    };
    _ready set [_seatIndex, _desired];
    _table setVariable ["Waldo_MG_TableReady", _ready, true];
    [_table] call Waldo_MG_fnc_refreshTableConsensusServer;
    private _gameName = [_selectedGame] call Waldo_MG_fnc_getGameName;
    private _message = if (_desired) then {
        format ["You are ready for %1.", _gameName]
    } else {
        "You are no longer ready."
    };
    if ((_table getVariable ["Waldo_MG_TablePhase", "LOBBY"]) == "READY") then {
        if (_selectedGame == "whoswho") then {
            if ([_table] call Waldo_MG_fnc_whosWhoStartServer) then {
                _message = "Everyone is ready. Who's Who has begun; inspect your private vehicle target.";
            } else {
                _message = "Who's Who could not start: its two-player roster or vanilla vehicle catalog is incomplete.";
            };
        } else {
        if (_selectedGame == "shotgun") then {
            if ([_table] call Waldo_MG_fnc_shotgunStartServer) then {
                _message = "Everyone is ready. Shotgun Roulette has begun; read the shell ledger carefully.";
            } else {
                _message = "Shotgun Roulette could not start because its two-to-four-player roster changed.";
            };
        } else {
        if (_selectedGame == "checkers") then {
            if ([_table] call Waldo_MG_fnc_checkersStartServer) then {
                _message = "Everyone is ready. Checkers has begun; NATO Blue moves first.";
            } else {
                _message = "The Checkers board could not start because its two-player roster changed.";
            };
        } else {
            if (_selectedGame == "rps") then {
                if ([_table] call Waldo_MG_fnc_rpsStartServer) then {
                    _message = "Everyone is ready. Rock Paper Scissors has begun; lock your first choice.";
                } else {
                    _message = "Rock Paper Scissors could not start because its two-player roster changed.";
                };
            } else {
                if (_selectedGame == "blackjack") then {
                    if ([_table] call Waldo_MG_fnc_blackjackStartServer) then {
                        _message = format ["Blackjack has begun with %1 chips each. Place an even bet.", Waldo_MG_CFG_BLACKJACK_STARTING_CHIPS];
                    } else {
                        _message = "The Blackjack table could not start because its one-to-four-player roster changed.";
                    };
                } else {
                    if (_selectedGame == "chess") then {
                        if ([_table] call Waldo_MG_fnc_chessStartServer) then {
                            _message = "Everyone is ready. Chess has begun; NATO White moves first.";
                        } else {
                            _message = "The Chess board could not start because its two-player roster changed.";
                        };
                    } else {
                        if (_selectedGame == "poker") then {
                            if ([_table] call Waldo_MG_fnc_pokerStartServer) then {
                                _message = format [
                                    "Everyone is ready. Poker has begun with %1 chips each and %2/%3 blinds.",
                                    Waldo_MG_CFG_POKER_STARTING_CHIPS,
                                    Waldo_MG_CFG_POKER_SMALL_BLIND,
                                    Waldo_MG_CFG_POKER_BIG_BLIND
                                ];
                            } else {
                                _message = "The Poker table could not start because its roster changed.";
                            };
                        } else {
                            if (_selectedGame == "uno") then {
                                if ([_table] call Waldo_MG_fnc_unoStartServer) then {
                                    _message = format [
                                        "Everyone is ready. UNO has begun with %1 cards each.",
                                        Waldo_MG_CFG_UNO_STARTING_CARDS
                                    ];
                                } else {
                                    _message = "The UNO table could not start because its roster changed.";
                                };
                            } else {
                                if (_selectedGame == "battleship") then {
                                    if ([_table] call Waldo_MG_fnc_battleshipStartServer) then {
                                        _message = "Everyone is ready. Battleship has begun; deploy and lock both private fleets.";
                                    } else {
                                        _message = "The Battleship board could not start because its two-player roster changed.";
                                    };
                                } else {
                                    _message = format ["Everyone is ready for %1.", _gameName];
                                };
                            };
                        };
                    };
                };
            };
        };
        };
        };
    };
    if (_selectedGame == "drawpoker" && {(_table getVariable ["Waldo_MG_TablePhase", "LOBBY"]) == "READY"}) then {
        _message = if ([_table] call Waldo_MG_fnc_drawPokerStartServer) then {
            format ["Five-Card Draw has begun with %1 chips and a %2-chip ante.", Waldo_MG_CFG_DRAWPOKER_STARTING_CHIPS, Waldo_MG_CFG_DRAWPOKER_ANTE]
        } else {"Five-Card Draw could not start because its roster changed."};
    };
    if (_selectedGame == "liarsdice" && {(_table getVariable ["Waldo_MG_TablePhase", "LOBBY"]) == "READY"}) then {
        _message = if ([_table] call Waldo_MG_fnc_liarsDiceStartServer) then {
            format ["Liar's Dice has begun with %1 private dice each.", Waldo_MG_CFG_LIARSDICE_STARTING_DICE]
        } else {"Liar's Dice could not start because its roster changed."};
    };
    if (_selectedGame == "connectfour" && {(_table getVariable ["Waldo_MG_TablePhase", "LOBBY"]) == "READY"}) then {
        _message = if ([_table] call Waldo_MG_fnc_connectFourStartServer) then {
            "Connect Four has begun. Blue O opens the first board."
        } else {"Connect Four could not start because its two-player roster changed."};
    };
    [_unit, _token, _message] call Waldo_MG_fnc_resultServer;
};

Waldo_MG_fnc_processPlayerRequestsServer = {
    params [["_unit", objNull]];
    if (!isServer || {isNull _unit}) exitWith {};
    private _join = _unit getVariable ["Waldo_MG_JoinRequest", []];
    if ((typeName _join) != "ARRAY") then {
        _unit setVariable ["Waldo_MG_JoinRequest", [], true];
        _join = [];
    } else {
        _join = +_join;
    };
    if ((count _join) > 0) then {
        [_unit, _join] call Waldo_MG_fnc_processJoinRequestServer;
    };
    private _leave = _unit getVariable ["Waldo_MG_LeaveRequest", []];
    if ((typeName _leave) != "ARRAY") then {
        _unit setVariable ["Waldo_MG_LeaveRequest", [], true];
        _leave = [];
    } else {
        _leave = +_leave;
    };
    if ((count _leave) > 0) then {
        [_unit, _leave] call Waldo_MG_fnc_processLeaveRequestServer;
    };
    private _vote = _unit getVariable ["Waldo_MG_VoteRequest", []];
    if ((typeName _vote) != "ARRAY") then {
        _unit setVariable ["Waldo_MG_VoteRequest", [], true];
        _vote = [];
    } else {
        _vote = +_vote;
    };
    if ((count _vote) > 0) then {
        [_unit, _vote] call Waldo_MG_fnc_processVoteRequestServer;
    };
    private _ready = _unit getVariable ["Waldo_MG_ReadyRequest", []];
    if ((typeName _ready) != "ARRAY") then {
        _unit setVariable ["Waldo_MG_ReadyRequest", [], true];
        _ready = [];
    } else {
        _ready = +_ready;
    };
    if ((count _ready) > 0) then {
        [_unit, _ready] call Waldo_MG_fnc_processReadyRequestServer;
    };
    private _battleshipAction = _unit getVariable ["Waldo_MG_BattleshipActionRequest", []];
    if ((typeName _battleshipAction) != "ARRAY") then {
        _unit setVariable ["Waldo_MG_BattleshipActionRequest", [], true];
        _battleshipAction = [];
    } else {
        _battleshipAction = +_battleshipAction;
    };
    if ((count _battleshipAction) > 0) then {
        [_unit, _battleshipAction] call Waldo_MG_fnc_processBattleshipActionRequestServer;
    };
    private _whosWhoAction = _unit getVariable ["Waldo_MG_WhosWhoActionRequest", []];
    if ((typeName _whosWhoAction) != "ARRAY") then {
        _unit setVariable ["Waldo_MG_WhosWhoActionRequest", [], true];
        _whosWhoAction = [];
    } else {
        _whosWhoAction = +_whosWhoAction;
    };
    if ((count _whosWhoAction) > 0) then {
        [_unit, _whosWhoAction] call Waldo_MG_fnc_processWhosWhoActionRequestServer;
    };
    private _shotgunAction = _unit getVariable ["Waldo_MG_ShotgunActionRequest", []];
    if ((typeName _shotgunAction) != "ARRAY") then {
        _unit setVariable ["Waldo_MG_ShotgunActionRequest", [], true];
        _shotgunAction = [];
    } else {
        _shotgunAction = +_shotgunAction;
    };
    if ((count _shotgunAction) > 0) then {
        [_unit, _shotgunAction] call Waldo_MG_fnc_processShotgunActionRequestServer;
    };
    private _rpsAction = _unit getVariable ["Waldo_MG_RPSActionRequest", []];
    if ((typeName _rpsAction) != "ARRAY") then {
        _unit setVariable ["Waldo_MG_RPSActionRequest", [], true];
        _rpsAction = [];
    } else {
        _rpsAction = +_rpsAction;
    };
    if ((count _rpsAction) > 0) then {
        [_unit, _rpsAction] call Waldo_MG_fnc_processRPSActionRequestServer;
    };
    private _blackjackAction = _unit getVariable ["Waldo_MG_BlackjackActionRequest", []];
    if ((typeName _blackjackAction) != "ARRAY") then {
        _unit setVariable ["Waldo_MG_BlackjackActionRequest", [], true];
        _blackjackAction = [];
    } else {
        _blackjackAction = +_blackjackAction;
    };
    if ((count _blackjackAction) > 0) then {
        [_unit, _blackjackAction] call Waldo_MG_fnc_processBlackjackActionRequestServer;
    };
    private _checkersMove = _unit getVariable ["Waldo_MG_CheckersMoveRequest", []];
    if ((typeName _checkersMove) != "ARRAY") then {
        _unit setVariable ["Waldo_MG_CheckersMoveRequest", [], true];
        _checkersMove = [];
    } else {
        _checkersMove = +_checkersMove;
    };
    if ((count _checkersMove) > 0) then {
        [_unit, _checkersMove] call Waldo_MG_fnc_processCheckersMoveRequestServer;
    };
    private _checkersReset = _unit getVariable ["Waldo_MG_CheckersResetRequest", []];
    if ((typeName _checkersReset) != "ARRAY") then {
        _unit setVariable ["Waldo_MG_CheckersResetRequest", [], true];
        _checkersReset = [];
    } else {
        _checkersReset = +_checkersReset;
    };
    if ((count _checkersReset) > 0) then {
        [_unit, _checkersReset] call Waldo_MG_fnc_processCheckersResetRequestServer;
    };
    private _chessMove = _unit getVariable ["Waldo_MG_ChessMoveRequest", []];
    if ((typeName _chessMove) != "ARRAY") then {
        _unit setVariable ["Waldo_MG_ChessMoveRequest", [], true];
        _chessMove = [];
    } else {
        _chessMove = +_chessMove;
    };
    if ((count _chessMove) > 0) then {
        [_unit, _chessMove] call Waldo_MG_fnc_processChessMoveRequestServer;
    };
    private _chessAction = _unit getVariable ["Waldo_MG_ChessActionRequest", []];
    if ((typeName _chessAction) != "ARRAY") then {
        _unit setVariable ["Waldo_MG_ChessActionRequest", [], true];
        _chessAction = [];
    } else {
        _chessAction = +_chessAction;
    };
    if ((count _chessAction) > 0) then {
        [_unit, _chessAction] call Waldo_MG_fnc_processChessActionRequestServer;
    };
    private _pokerAction = _unit getVariable ["Waldo_MG_PokerActionRequest", []];
    if ((typeName _pokerAction) != "ARRAY") then {
        _unit setVariable ["Waldo_MG_PokerActionRequest", [], true];
        _pokerAction = [];
    } else {
        _pokerAction = +_pokerAction;
    };
    if ((count _pokerAction) > 0) then {
        [_unit, _pokerAction] call Waldo_MG_fnc_processPokerActionRequestServer;
    };
    private _drawPokerAction = _unit getVariable ["Waldo_MG_DrawPokerActionRequest", []];
    if ((typeName _drawPokerAction) != "ARRAY") then {_unit setVariable ["Waldo_MG_DrawPokerActionRequest", [], true]; _drawPokerAction = [];} else {_drawPokerAction = +_drawPokerAction;};
    if ((count _drawPokerAction) > 0) then {[_unit, _drawPokerAction] call Waldo_MG_fnc_processDrawPokerActionRequestServer;};
    private _liarsDiceAction = _unit getVariable ["Waldo_MG_LiarsDiceActionRequest", []];
    if ((typeName _liarsDiceAction) != "ARRAY") then {_unit setVariable ["Waldo_MG_LiarsDiceActionRequest", [], true]; _liarsDiceAction = [];} else {_liarsDiceAction = +_liarsDiceAction;};
    if ((count _liarsDiceAction) > 0) then {[_unit, _liarsDiceAction] call Waldo_MG_fnc_processLiarsDiceActionRequestServer;};
    private _connectFourAction = _unit getVariable ["Waldo_MG_ConnectFourActionRequest", []];
    if ((typeName _connectFourAction) != "ARRAY") then {_unit setVariable ["Waldo_MG_ConnectFourActionRequest", [], true]; _connectFourAction = [];} else {_connectFourAction = +_connectFourAction;};
    if ((count _connectFourAction) > 0) then {[_unit, _connectFourAction] call Waldo_MG_fnc_processConnectFourActionRequestServer;};
    private _unoAction = _unit getVariable ["Waldo_MG_UNOActionRequest", []];
    if ((typeName _unoAction) != "ARRAY") then {
        _unit setVariable ["Waldo_MG_UNOActionRequest", [], true];
        _unoAction = [];
    } else {
        _unoAction = +_unoAction;
    };
    if ((count _unoAction) > 0) then {
        [_unit, _unoAction] call Waldo_MG_fnc_processUNOActionRequestServer;
    };
};

Waldo_MG_fnc_initializeServerState = {
    if (!isServer) exitWith {};
    if (isNil {missionNamespace getVariable "Waldo_MG_Tables"}) then {
        missionNamespace setVariable ["Waldo_MG_Tables", [], true];
    };
    if (isNil {missionNamespace getVariable "Waldo_MG_HandledTokensServer"}) then {
        missionNamespace setVariable ["Waldo_MG_HandledTokensServer", []];
    };
};

Waldo_MG_fnc_startAuthorityLoop = {
    if (!isServer) exitWith {};
    if (missionNamespace getVariable ["Waldo_MG_AuthorityLoopStarted", false]) exitWith {};
    missionNamespace setVariable ["Waldo_MG_AuthorityLoopStarted", true];
    [] spawn {
        private _nextMaintenance = 0;
        while {true} do {
            private _authorityPlayers = +allPlayers;
            {
                if (!(_x getVariable ["Waldo_MG_ServerInitialized", false])) then {
                    [_x] call Waldo_MG_fnc_initializePlayerServer;
                };
            } forEach _authorityPlayers;
            call Waldo_MG_fnc_reconcileRegisteredTablesServer;
            [_authorityPlayers] call Waldo_MG_fnc_processPriorityUNORequestsServer;
            {
                [_x] call Waldo_MG_fnc_processPlayerRequestsServer;
            } forEach _authorityPlayers;
            if (serverTime >= _nextMaintenance) then {
                call Waldo_MG_fnc_reconcileRegistriesServer;
                _nextMaintenance = serverTime + Waldo_MG_CFG_MAINTENANCE_TICK;
            };
            sleep Waldo_MG_CFG_AUTHORITY_TICK;
        };
    };
}; 

Waldo_MG_fnc_notifyLocal = {
    disableSerialization;
    params [["_message", "", [""]], ["_duration", 5, [0]]];
    if (!hasInterface || {_message == ""}) exitWith {false};

    // An open lobby/game owns its own status region. Keep feedback inside that
    // interface instead of obscuring it with Arma's global hint display.
    private _activeDisplay = displayNull;
    {
        if (_x getVariable ["Waldo_MG_TableGameDisplay", false]) exitWith {_activeDisplay = _x;};
    } forEach allDisplays;
    if (isNull _activeDisplay) then {
        _activeDisplay = uiNamespace getVariable ["Waldo_MG_LobbyDisplay", displayNull];
    };
    if (!isNull _activeDisplay) then {
        private _status = controlNull;
        {
            private _candidate = _activeDisplay getVariable [_x, controlNull];
            if (!isNull _candidate) exitWith {_status = _candidate;};
        } forEach [
            "Waldo_MG_LobbyStatusOne", "Waldo_MG_DrawPokerStatusCtrl",
            "Waldo_MG_LiarsDiceStatusCtrl", "Waldo_MG_ConnectFourStatusCtrl",
            "Waldo_MG_PokerStatusLabel", "Waldo_MG_BlackjackStatusLabel",
            "Waldo_MG_BattleshipStatusLabel", "Waldo_MG_WhosWhoStatusLabel",
            "Waldo_MG_ShotgunStatusLabel", "Waldo_MG_RPSStatusLabel",
            "Waldo_MG_CheckersStatusOne", "Waldo_MG_ChessStatusOne",
            "Waldo_MG_UNOStatusOne"
        ];
        if (!isNull _status) exitWith {
            if ((ctrlType _status) == 13) then {
                _status ctrlSetStructuredText parseText format ["<t color='#F2BE55'>%1</t>", _message];
            } else {
                _status ctrlSetText _message;
                _status ctrlSetTextColor [0.95, 0.75, 0.34, 1];
            };
            _status ctrlCommit 0;
            true
        };
    };

    // Pre-lobby feedback uses one small padded WMP panel, never hint/hintSilent.
    private _display = findDisplay 46;
    if (isNull _display) exitWith {false};
    private _frame = _display displayCtrl 5340;
    private _content = _display displayCtrl 5341;
    if (isNull _frame) then {_frame = _display ctrlCreate ["RscText", 5340];};
    if (isNull _content) then {_content = _display ctrlCreate ["RscStructuredText", 5341];};
    private _left = safeZoneX;
    private _top = safeZoneY;
    private _right = safeZoneX + safeZoneW;
    private _bottom = safeZoneY + safeZoneH;
    private _visibleW = (_right - _left) max 0.2;
    private _visibleH = (_bottom - _top) max 0.2;
    private _panelW = _visibleW * 0.38;
    private _panelX = _left + ((_visibleW - _panelW) / 2);
    private _panelY = _bottom - (_visibleH * 0.14);
    private _padX = _visibleW * 0.010;
    private _padY = _visibleH * 0.007;
    _content ctrlSetStructuredText parseText format ["<t color='#9FCDF2' size='0.72'>PARTY TABLE</t><br/><t color='#FFFFFF' size='0.92'>%1</t>", _message];
    _content ctrlSetPosition [_panelX + _padX, _panelY + _padY, _panelW - (2 * _padX), _visibleH * 0.09];
    _content ctrlCommit 0;
    private _contentH = ((ctrlTextHeight _content) max (_visibleH * 0.055)) min (_visibleH * 0.09);
    private _panelH = _contentH + (2 * _padY);
    _frame ctrlSetPosition [_panelX, _panelY, _panelW, _panelH];
    _frame ctrlSetBackgroundColor [0.02, 0.04, 0.06, 0.94];
    _content ctrlSetPosition [_panelX + _padX, _panelY + _padY, _panelW - (2 * _padX), _contentH];
    _frame ctrlCommit 0;
    _content ctrlCommit 0;
    _frame ctrlShow true;
    _content ctrlShow true;
    private _token = format ["%1_%2", diag_tickTime, random 1e9];
    uiNamespace setVariable ["Waldo_MG_NoticeToken", _token];
    [_frame, _content, _token, _duration max 1] spawn {
        params ["_frame", "_content", "_token", "_duration"];
        uiSleep _duration;
        if ((uiNamespace getVariable ["Waldo_MG_NoticeToken", ""]) == _token) then {
            uiNamespace setVariable ["Waldo_MG_NoticeToken", nil];
            if (!isNull _frame) then {_frame ctrlShow false;};
            if (!isNull _content) then {_content ctrlShow false;};
        };
    };
    true
};
 

Waldo_MG_fnc_submitJoinRequestLocal = {
    params [["_table", objNull]];
    if (!hasInterface || {isNull player}) exitWith {};
    if (isNull _table) exitWith {
        ["That party table is unavailable."] call Waldo_MG_fnc_notifyLocal;
    };
    if (!alive player) exitWith {
        ["You must be alive to sit at the table."] call Waldo_MG_fnc_notifyLocal;
    };
    private _token = ["JOIN"] call Waldo_MG_fnc_makeToken;
    player setVariable [
        "Waldo_MG_JoinRequest",
        [_token, netId _table, getPosATL player],
        true
    ];
    ["Requesting a seat from the table host..."] call Waldo_MG_fnc_notifyLocal;
};

Waldo_MG_fnc_submitLeaveRequestLocal = {
    if (!hasInterface || {isNull player}) exitWith {};
    private _table = player getVariable ["Waldo_MG_SeatedTable", objNull];
    private _token = ["LEAVE"] call Waldo_MG_fnc_makeToken;
    player setVariable [
        "Waldo_MG_LeaveRequest",
        [_token, if (isNull _table) then {""} else {netId _table}],
        true
    ];
    missionNamespace setVariable ["Waldo_MG_LeavePendingLocal", [_token, diag_tickTime]];
    call Waldo_MG_fnc_closeTableGameDisplaysLocal;
    ["Leaving the party table..."] call Waldo_MG_fnc_notifyLocal;
};

Waldo_MG_fnc_submitVoteRequestLocal = {
    params [
        ["_table", objNull],
        ["_gameId", ""]
    ];
    if (!hasInterface || {isNull player}) exitWith {};
    if (isNull _table || {_gameId == ""}) exitWith {
        ["Select an available game before voting."] call Waldo_MG_fnc_notifyLocal;
    };
    private _token = ["VOTE"] call Waldo_MG_fnc_makeToken;
    player setVariable [
        "Waldo_MG_VoteRequest",
        [_token, netId _table, _gameId],
        true
    ];
    ["Submitting your table vote..."] call Waldo_MG_fnc_notifyLocal;
};

Waldo_MG_fnc_submitReadyRequestLocal = {
    params [
        ["_table", objNull],
        ["_desired", true]
    ];
    if (!hasInterface || {isNull player} || {isNull _table}) exitWith {};
    private _token = ["READY"] call Waldo_MG_fnc_makeToken;
    player setVariable [
        "Waldo_MG_ReadyRequest",
        [_token, netId _table, _desired],
        true
    ];
    ["Updating your ready state..."] call Waldo_MG_fnc_notifyLocal;
};

Waldo_MG_fnc_showRequestResultLocal = {
    if (!hasInterface || {isNull player}) exitWith {};
    private _result = player getVariable ["Waldo_MG_RequestResult", []];
    if ((count _result) < 2) exitWith {};
    private _token = _result param [0, ""];
    private _message = _result param [1, ""];
    private _lastToken = missionNamespace getVariable ["Waldo_MG_LastResultTokenLocal", ""];
    if (_token == "" || {_token == _lastToken}) exitWith {};
    missionNamespace setVariable ["Waldo_MG_LastResultTokenLocal", _token];
    private _leavePending = missionNamespace getVariable ["Waldo_MG_LeavePendingLocal", []];
    if ((_leavePending param [0, ""]) == _token) then {
        missionNamespace setVariable ["Waldo_MG_LeavePendingLocal", []];
    };
    private _battleshipPending = missionNamespace getVariable ["Waldo_MG_BattleshipPendingRequestLocal", []];
    if ((_battleshipPending param [0, ""]) == _token) then {
        missionNamespace setVariable ["Waldo_MG_BattleshipPendingRequestLocal", []];
    };
    private _whosWhoPending = missionNamespace getVariable ["Waldo_MG_WhosWhoPendingRequestLocal", []];
    if ((_whosWhoPending param [0, ""]) == _token) then {
        missionNamespace setVariable ["Waldo_MG_WhosWhoPendingRequestLocal", []];
    };
    private _shotgunPending = missionNamespace getVariable ["Waldo_MG_ShotgunPendingRequestLocal", []];
    if ((_shotgunPending param [0, ""]) == _token) then {
        missionNamespace setVariable ["Waldo_MG_ShotgunPendingRequestLocal", []];
    };
    private _rpsPending = missionNamespace getVariable ["Waldo_MG_RPSPendingRequestLocal", []];
    if ((_rpsPending param [0, ""]) == _token) then {
        missionNamespace setVariable ["Waldo_MG_RPSPendingRequestLocal", []];
    };
    private _blackjackPending = missionNamespace getVariable ["Waldo_MG_BlackjackPendingRequestLocal", []];
    if ((_blackjackPending param [0, ""]) == _token) then {
        missionNamespace setVariable ["Waldo_MG_BlackjackPendingRequestLocal", []];
    };
    private _pokerPending = missionNamespace getVariable ["Waldo_MG_PokerPendingRequestLocal", []];
    if ((_pokerPending param [0, ""]) == _token) then {
        missionNamespace setVariable ["Waldo_MG_PokerPendingRequestLocal", []];
    };
    private _unoPending = missionNamespace getVariable ["Waldo_MG_UNOPendingRequestLocal", []];
    if ((_unoPending param [0, ""]) == _token) then {
        missionNamespace setVariable ["Waldo_MG_UNOPendingRequestLocal", []];
    };
    if (_message != "") then {
        [_message] call Waldo_MG_fnc_notifyLocal;
    };
};

Waldo_MG_fnc_discoverTaggedTablesLocal = {
    if (!hasInterface) exitWith {};
    private _tables = [Waldo_MG_CFG_TABLE_CLASSES, "Waldo_MG_IsPartyTable"] call Waldo_MG_fnc_collectTaggedClassObjects;
    private _host = missionNamespace getVariable ["Waldo_MG_CompositionHostObject", objNull];
    if (!isNull _host && {_host getVariable ["Waldo_MG_IsPartyTable", false]}) then {
        _tables pushBackUnique _host;
    };
    missionNamespace setVariable ["Waldo_MG_DiscoveredTablesLocal", _tables];
};

Waldo_MG_fnc_getKnownTablesLocal = {
    private _known = [];
    {
        if (!isNull _x && {_x getVariable ["Waldo_MG_IsPartyTable", false]}) then {
            _known pushBackUnique _x;
        };
    } forEach (missionNamespace getVariable ["Waldo_MG_Tables", []]);
    {
        if (!isNull _x && {_x getVariable ["Waldo_MG_IsPartyTable", false]}) then {
            _known pushBackUnique _x;
        };
    } forEach (missionNamespace getVariable ["Waldo_MG_DiscoveredTablesLocal", []]);
    _known
};

Waldo_MG_fnc_canSitAtTableAction = {
    params [
        ["_table", objNull],
        ["_caller", objNull]
    ];
    if (isNull _table || {isNull _caller} || {!alive _caller} || {(lifeState _caller) == "INCAPACITATED"}) exitWith {false};
    if (!(_table getVariable ["Waldo_MG_IsPartyTable", false])) exitWith {false};
    if ((_caller distance _table) > Waldo_MG_CFG_ACTION_RANGE) exitWith {false};
    if ((vehicle _caller) != _caller) exitWith {false};
    if (!isNull (_caller getVariable ["Waldo_MG_SeatedTable", objNull])) exitWith {false};
    if (!isNull (missionNamespace getVariable ["Waldo_MG_SpectatedTableLocal", objNull])) exitWith {false};
    if ([_table] call Waldo_MG_fnc_isTableGameActive) exitWith {false};
    ([ _table ] call Waldo_MG_fnc_getTableOccupantCount) < Waldo_MG_CFG_SEAT_COUNT
};

Waldo_MG_fnc_canOpenTableAction = {
    params [
        ["_table", objNull],
        ["_caller", objNull]
    ];
    if (isNull _table || {isNull _caller} || {!alive _caller} || {(lifeState _caller) == "INCAPACITATED"}) exitWith {false};
    if ((_caller distance _table) > Waldo_MG_CFG_ACTION_RANGE) exitWith {false};
    (_caller getVariable ["Waldo_MG_SeatedTable", objNull]) == _table
};

Waldo_MG_fnc_canSpectateTableAction = {
    params [
        ["_table", objNull],
        ["_caller", objNull]
    ];
    if (isNull _table || {isNull _caller} || {!alive _caller} || {(lifeState _caller) == "INCAPACITATED"}) exitWith {false};
    if (!(_table getVariable ["Waldo_MG_IsPartyTable", false])) exitWith {false};
    if ((_caller distance _table) > Waldo_MG_CFG_ACTION_RANGE) exitWith {false};
    if ((vehicle _caller) != _caller) exitWith {false};
    if (!isNull (_caller getVariable ["Waldo_MG_SeatedTable", objNull])) exitWith {false};
    if (!isNull (missionNamespace getVariable ["Waldo_MG_SpectatedTableLocal", objNull])) exitWith {false};
    [_table] call Waldo_MG_fnc_isTableGameActive
};

Waldo_MG_fnc_canUsePersonalTableAction = {
    params [
        ["_target", objNull],
        ["_caller", objNull]
    ];
    if (isNull _target || {isNull _caller} || {_target != _caller}) exitWith {false};
    if (!alive _caller || {(lifeState _caller) == "INCAPACITATED"}) exitWith {false};
    !isNull (_caller getVariable ["Waldo_MG_SeatedTable", objNull])
};

Waldo_MG_fnc_ensureTableActionsLocal = {
    if (!hasInterface) exitWith {};
    private _aceLoaded = isClass (configFile >> "CfgPatches" >> "ace_interact_menu");
    private _aceReady = _aceLoaded
        && {!(isNil "ace_interact_menu_fnc_createAction")}
        && {!(isNil "ace_interact_menu_fnc_addActionToObject")};
    if (_aceLoaded && {!_aceReady}) exitWith {};
    {
        private _table = _x;
        if (!isNull _table) then {
            [_table] call Waldo_MG_fnc_enforceInvulnerableLocal;
            if (_aceReady) then {
                if !(_table getVariable ["Waldo_MG_TableACEActionsInstalled", false]) then {
                    private _category = [
                        "Waldo_MG_TableCategory", "Party Table",
                        "\a3\ui_f\data\igui\cfg\simpletasks\types\interact_ca.paa",
                        {}, {true}
                    ] call ace_interact_menu_fnc_createAction;
                    private _sit = [
                        "Waldo_MG_TableSit", "Sit at Table", "",
                        {params ["_target", "_player"]; [_target] call Waldo_MG_fnc_submitJoinRequestLocal;},
                        {params ["_target", "_player"]; [_target, _player] call Waldo_MG_fnc_canSitAtTableAction;}
                    ] call ace_interact_menu_fnc_createAction;
                    private _open = [
                        "Waldo_MG_TableOpen", "Open Party Games", "",
                        {params ["_target", "_player"]; [_target] call Waldo_MG_fnc_openCurrentTableScreenLocal;},
                        {params ["_target", "_player"]; [_target, _player] call Waldo_MG_fnc_canOpenTableAction;}
                    ] call ace_interact_menu_fnc_createAction;
                    private _spectate = [
                        "Waldo_MG_TableSpectate", "Spectate Game", "",
                        {params ["_target", "_player"]; [_target] call Waldo_MG_fnc_openSpectatorLocal;},
                        {params ["_target", "_player"]; [_target, _player] call Waldo_MG_fnc_canSpectateTableAction;}
                    ] call ace_interact_menu_fnc_createAction;
                    private _categoryPath = [_table, 0, ["ACE_MainActions"], _category] call ace_interact_menu_fnc_addActionToObject;
                    private _sitPath = [_table, 0, ["ACE_MainActions", "Waldo_MG_TableCategory"], _sit] call ace_interact_menu_fnc_addActionToObject;
                    private _openPath = [_table, 0, ["ACE_MainActions", "Waldo_MG_TableCategory"], _open] call ace_interact_menu_fnc_addActionToObject;
                    private _spectatePath = [_table, 0, ["ACE_MainActions", "Waldo_MG_TableCategory"], _spectate] call ace_interact_menu_fnc_addActionToObject;
                    _table setVariable ["Waldo_MG_TableACEActionPaths", [_categoryPath, _sitPath, _openPath, _spectatePath]];
                    _table setVariable ["Waldo_MG_TableACEActions", [_category, _sit, _open, _spectate]];
                    _table setVariable ["Waldo_MG_TableACEActionsInstalled", true];
                    diag_log format ["[WMP PARTY] ACE table actions installed table=%1 owner=%2", netId _table, clientOwner];
                };
            };
            // Party tables are deliberately discoverable through both interaction
            // surfaces. Both paths submit the same tokenized request; the server
            // remains the sole authority for seating and game state.
            if ((count (_table getVariable ["Waldo_MG_TableActionIdsLocal", []])) <= 0) then {
                private _sitAction = _table addAction [
                    "Sit at Table",
                    {
                        params ["_target", "_caller"];
                        if (_caller != player) exitWith {};
                        [_target] call Waldo_MG_fnc_submitJoinRequestLocal;
                    },
                    nil,
                    1.7,
                    true,
                    true,
                    "",
                    "[_target, _this] call Waldo_MG_fnc_canSitAtTableAction",
                    Waldo_MG_CFG_ACTION_RANGE
                ];
                private _openAction = _table addAction [
                    "Reopen Mini Games",
                    {
                        params ["_target", "_caller"];
                        if (_caller != player) exitWith {};
                        [_target] call Waldo_MG_fnc_openCurrentTableScreenLocal;
                    },
                    nil,
                    1.6,
                    true,
                    true,
                    "",
                    "[_target, _this] call Waldo_MG_fnc_canOpenTableAction",
                    Waldo_MG_CFG_ACTION_RANGE
                ];
                private _spectateAction = _table addAction [
                    "Spectate Game",
                    {
                        params ["_target", "_caller"];
                        if (_caller != player) exitWith {};
                        [_target] call Waldo_MG_fnc_openSpectatorLocal;
                    },
                    nil,
                    1.65,
                    true,
                    true,
                    "",
                    "[_target, _this] call Waldo_MG_fnc_canSpectateTableAction",
                    Waldo_MG_CFG_ACTION_RANGE
                ];
                _table setVariable ["Waldo_MG_TableActionIdsLocal", [_sitAction, _openAction, _spectateAction]];
            };
            _table setVariable ["Waldo_MG_TableInteractionMode", if (_aceReady) then {"ACE+VANILLA"} else {"VANILLA"}];
        };
    } forEach (call Waldo_MG_fnc_getKnownTablesLocal);
};

Waldo_MG_fnc_ensurePlayerActionsLocal = {
    if (!hasInterface || {isNull player}) exitWith {};
    private _aceLoaded = isClass (configFile >> "CfgPatches" >> "ace_interact_menu");
    private _aceReady = _aceLoaded
        && {!(isNil "ace_interact_menu_fnc_createAction")}
        && {!(isNil "ace_interact_menu_fnc_addActionToObject")};
    if (_aceLoaded && {!_aceReady}) exitWith {};
    private _trackedUnit = missionNamespace getVariable ["Waldo_MG_PlayerActionUnitLocal", objNull];
    private _actionIds = +(missionNamespace getVariable ["Waldo_MG_PlayerActionIdsLocal", []]);
    if (_trackedUnit != player) then {
        if (!isNull _trackedUnit) then {
            {
                _trackedUnit removeAction _x;
            } forEach _actionIds;
        };
        _trackedUnit = player;
        _actionIds = [];
        missionNamespace setVariable ["Waldo_MG_PlayerACEActionsInstalledLocal", false];
    };
    if (_aceReady) then {
        if !(missionNamespace getVariable ["Waldo_MG_PlayerACEActionsInstalledLocal", false]) then {
            private _open = [
                "Waldo_MG_PlayerOpen", "Reopen Party Games", "",
                {
                    private _table = player getVariable ["Waldo_MG_SeatedTable", objNull];
                    [_table] call Waldo_MG_fnc_openCurrentTableScreenLocal;
                },
                {params ["_target", "_player"]; [_target, _player] call Waldo_MG_fnc_canUsePersonalTableAction;}
            ] call ace_interact_menu_fnc_createAction;
            private _leave = [
                "Waldo_MG_PlayerLeave", "Leave Party Table", "",
                {call Waldo_MG_fnc_submitLeaveRequestLocal;},
                {params ["_target", "_player"]; [_target, _player] call Waldo_MG_fnc_canUsePersonalTableAction;}
            ] call ace_interact_menu_fnc_createAction;
            private _openPath = [player, 1, ["ACE_SelfActions"], _open] call ace_interact_menu_fnc_addActionToObject;
            private _leavePath = [player, 1, ["ACE_SelfActions"], _leave] call ace_interact_menu_fnc_addActionToObject;
            missionNamespace setVariable ["Waldo_MG_PlayerACEActionPathsLocal", [_openPath, _leavePath]];
            missionNamespace setVariable ["Waldo_MG_PlayerACEActionsLocal", [_open, _leave]];
            missionNamespace setVariable ["Waldo_MG_PlayerACEActionsInstalledLocal", true];
            diag_log format ["[WMP PARTY] ACE player actions installed player=%1 owner=%2", name player, clientOwner];
        };
    };
    if ((count _actionIds) <= 0) then {
        private _openAction = player addAction [
            "Reopen Mini Games",
            {
                params ["_target", "_caller"];
                if (isNull _target || {_caller != player}) exitWith {};
                private _table = player getVariable ["Waldo_MG_SeatedTable", objNull];
                [_table] call Waldo_MG_fnc_openCurrentTableScreenLocal;
            },
            nil,
            4.0,
            false,
            true,
            "",
            "[_target, _this] call Waldo_MG_fnc_canUsePersonalTableAction",
            Waldo_MG_CFG_PERSONAL_ACTION_RANGE
        ];
        private _leaveAction = player addAction [
            "Leave Party Table",
            {
                params ["_target", "_caller"];
                if (isNull _target || {_caller != player}) exitWith {};
                call Waldo_MG_fnc_submitLeaveRequestLocal;
            },
            nil,
            3.9,
            false,
            true,
            "",
            "[_target, _this] call Waldo_MG_fnc_canUsePersonalTableAction",
            Waldo_MG_CFG_PERSONAL_ACTION_RANGE
        ];
        _actionIds = [_openAction, _leaveAction];
    };
    missionNamespace setVariable ["Waldo_MG_PlayerInteractionModeLocal", if (_aceReady) then {"ACE+VANILLA"} else {"VANILLA"}];
    missionNamespace setVariable ["Waldo_MG_PlayerActionUnitLocal", _trackedUnit];
    missionNamespace setVariable ["Waldo_MG_PlayerActionIdsLocal", _actionIds];
}; 
 

Waldo_MG_fnc_isValidGameViewerLocal = {
    params [
        ["_table", objNull],
        ["_spectating", false]
    ];
    if (!hasInterface || {isNull player} || {isNull _table}) exitWith {false};
    if (_spectating) exitWith {
        alive player
            && {(lifeState player) != "INCAPACITATED"}
            && {isNull (player getVariable ["Waldo_MG_SeatedTable", objNull])}
            && {(missionNamespace getVariable ["Waldo_MG_SpectatedTableLocal", objNull]) == _table}
    };
    (player getVariable ["Waldo_MG_SeatedTable", objNull]) == _table
};

Waldo_MG_fnc_exitSpectatorLocal = {
    disableSerialization;
    params [["_silent", false]];
    private _table = missionNamespace getVariable ["Waldo_MG_SpectatedTableLocal", objNull];
    missionNamespace setVariable ["Waldo_MG_SpectatedTableLocal", objNull];
    {
        if (!isNull _x && {_x getVariable ["Waldo_MG_SpectatorMode", false]}) then {
            _x closeDisplay 1;
        };
    } forEach [
        uiNamespace getVariable ["Waldo_MG_CheckersDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_BattleshipDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_WhosWhoDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_ShotgunDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_RPSDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_BlackjackDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_ChessDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_PokerDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_DrawPokerDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_LiarsDiceDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_ConnectFourDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_UNODisplay", displayNull]
    ];
    if (!_silent && {!isNull _table}) then {
        ["You stopped spectating the table game."] call Waldo_MG_fnc_notifyLocal;
    };
};

Waldo_MG_fnc_openSpectatorLocal = {
    params [["_table", objNull]];
    if (!hasInterface || {isNull player} || {isNull _table}) exitWith {};
    if (!alive player || {(lifeState player) == "INCAPACITATED"} || {(vehicle player) != player}) exitWith {
        ["You must be alive and on foot to spectate a table game."] call Waldo_MG_fnc_notifyLocal;
    };
    if (!isNull (player getVariable ["Waldo_MG_SeatedTable", objNull])) exitWith {
        ["Leave your current table seat before spectating another game."] call Waldo_MG_fnc_notifyLocal;
    };
    if (!([_table] call Waldo_MG_fnc_isTableGameActive)) exitWith {
        ["That table does not currently have a game to spectate."] call Waldo_MG_fnc_notifyLocal;
    };
    [true] call Waldo_MG_fnc_exitSpectatorLocal;
    missionNamespace setVariable ["Waldo_MG_SpectatedTableLocal", _table];
    private _activeGame = [_table] call Waldo_MG_fnc_getTableActiveGameId;
    if (_activeGame == "battleship") exitWith {
        [_table, true] call Waldo_MG_fnc_openBattleshipLocal;
    };
    if (_activeGame == "whoswho") exitWith {
        [_table, true] call Waldo_MG_fnc_openWhosWhoLocal;
    };
    if (_activeGame == "shotgun") exitWith {
        [_table, true] call Waldo_MG_fnc_openShotgunLocal;
    };
    if (_activeGame == "checkers") exitWith {
        [_table, true] call Waldo_MG_fnc_openCheckersLocal;
    };
    if (_activeGame == "rps") exitWith {
        [_table, true] call Waldo_MG_fnc_openRPSLocal;
    };
    if (_activeGame == "blackjack") exitWith {
        [_table, true] call Waldo_MG_fnc_openBlackjackLocal;
    };
    if (_activeGame == "chess") exitWith {
        [_table, true] call Waldo_MG_fnc_openChessLocal;
    };
    if (_activeGame == "poker") exitWith {
        [_table, true] call Waldo_MG_fnc_openPokerLocal;
    };
    if (_activeGame == "drawpoker") exitWith {[_table, true] call Waldo_MG_fnc_openDrawPokerLocal;};
    if (_activeGame == "liarsdice") exitWith {[_table, true] call Waldo_MG_fnc_openLiarsDiceLocal;};
    if (_activeGame == "connectfour") exitWith {[_table, true] call Waldo_MG_fnc_openConnectFourLocal;};
    if (_activeGame == "uno") exitWith {
        [_table, true] call Waldo_MG_fnc_openUNOLocal;
    };
    missionNamespace setVariable ["Waldo_MG_SpectatedTableLocal", objNull];
};

Waldo_MG_fnc_handleViewerExitButtonLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    if (!isNull _display && {_display getVariable ["Waldo_MG_SpectatorMode", false]}) then {
        [] call Waldo_MG_fnc_exitSpectatorLocal;
    } else {
        call Waldo_MG_fnc_submitLeaveRequestLocal;
    };
};

Waldo_MG_fnc_maintainSpectatorStateLocal = {
    if (!hasInterface) exitWith {};
    private _table = missionNamespace getVariable ["Waldo_MG_SpectatedTableLocal", objNull];
    if (isNull _table) exitWith {};
    if (!([_table, true] call Waldo_MG_fnc_isValidGameViewerLocal) || {!([_table] call Waldo_MG_fnc_isTableGameActive)}) exitWith {
        [true] call Waldo_MG_fnc_exitSpectatorLocal;
    };
    private _display = displayNull;
    private _displayTable = objNull;
    private _activeGame = [_table] call Waldo_MG_fnc_getTableActiveGameId;
    if (_activeGame == "battleship") then {
        _display = uiNamespace getVariable ["Waldo_MG_BattleshipDisplay", displayNull];
        if (!isNull _display) then {_displayTable = _display getVariable ["Waldo_MG_BattleshipTable", objNull];};
    };
    if (_activeGame == "whoswho") then {
        _display = uiNamespace getVariable ["Waldo_MG_WhosWhoDisplay", displayNull];
        if (!isNull _display) then {_displayTable = _display getVariable ["Waldo_MG_WhosWhoTable", objNull];};
    };
    if (_activeGame == "shotgun") then {
        _display = uiNamespace getVariable ["Waldo_MG_ShotgunDisplay", displayNull];
        if (!isNull _display) then {_displayTable = _display getVariable ["Waldo_MG_ShotgunTable", objNull];};
    };
    if (_activeGame == "checkers") then {
        _display = uiNamespace getVariable ["Waldo_MG_CheckersDisplay", displayNull];
        if (!isNull _display) then {_displayTable = _display getVariable ["Waldo_MG_CheckersTable", objNull];};
    };
    if (_activeGame == "rps") then {
        _display = uiNamespace getVariable ["Waldo_MG_RPSDisplay", displayNull];
        if (!isNull _display) then {_displayTable = _display getVariable ["Waldo_MG_RPSTable", objNull];};
    };
    if (_activeGame == "blackjack") then {
        _display = uiNamespace getVariable ["Waldo_MG_BlackjackDisplay", displayNull];
        if (!isNull _display) then {_displayTable = _display getVariable ["Waldo_MG_BlackjackTable", objNull];};
    };
    if (_activeGame == "chess") then {
        _display = uiNamespace getVariable ["Waldo_MG_ChessDisplay", displayNull];
        if (!isNull _display) then {_displayTable = _display getVariable ["Waldo_MG_ChessTable", objNull];};
    };
    if (_activeGame == "poker") then {
        _display = uiNamespace getVariable ["Waldo_MG_PokerDisplay", displayNull];
        if (!isNull _display) then {_displayTable = _display getVariable ["Waldo_MG_PokerTable", objNull];};
    };
    if (_activeGame == "drawpoker") then {
        _display = uiNamespace getVariable ["Waldo_MG_DrawPokerDisplay", displayNull];
        if (!isNull _display) then {_displayTable = _display getVariable ["Waldo_MG_DrawPokerTable", objNull];};
    };
    if (_activeGame == "liarsdice") then {
        _display = uiNamespace getVariable ["Waldo_MG_LiarsDiceDisplay", displayNull];
        if (!isNull _display) then {_displayTable = _display getVariable ["Waldo_MG_LiarsDiceTable", objNull];};
    };
    if (_activeGame == "connectfour") then {
        _display = uiNamespace getVariable ["Waldo_MG_ConnectFourDisplay", displayNull];
        if (!isNull _display) then {_displayTable = _display getVariable ["Waldo_MG_ConnectFourTable", objNull];};
    };
    if (_activeGame == "uno") then {
        _display = uiNamespace getVariable ["Waldo_MG_UNODisplay", displayNull];
        if (!isNull _display) then {_displayTable = _display getVariable ["Waldo_MG_UNOTable", objNull];};
    };
    if (isNull _display || {_displayTable != _table} || {!(_display getVariable ["Waldo_MG_SpectatorMode", false])}) then {
        missionNamespace setVariable ["Waldo_MG_SpectatedTableLocal", objNull];
    };
};

Waldo_MG_fnc_fitTableDisplaySafeLocal = {
    disableSerialization;
    params [["_display", displayNull]];
    if (isNull _display || {_display getVariable ["Waldo_MG_SafeFitScheduled", false]}) exitWith {};
    _display setVariable ["Waldo_MG_SafeFitScheduled", true];
    [_display] spawn {
        params ["_display"];
        private _lastCount = -1;
        private _stableFrames = 0;
        for "_attempt" from 0 to 15 do {
            if (isNull _display) exitWith {};
            uiSleep 0.03;
            private _count = count (allControls _display);
            if (_count > 0 && {_count == _lastCount}) then {_stableFrames = _stableFrames + 1;} else {_stableFrames = 0;};
            _lastCount = _count;
            if (_stableFrames >= 2) exitWith {};
        };
        if (isNull _display) exitWith {};
        private _controls = (allControls _display) select {
            private _position = ctrlPosition _x;
            // Focus sinks are deliberately parked at positions such as [-10,-10].
            // They must never participate in the visible-canvas bounds calculation.
            count _position >= 4
            && {(_position select 2) > 0}
            && {(_position select 3) > 0}
            && {(_position select 0) > (safeZoneX - safeZoneW)}
            && {(_position select 1) > (safeZoneY - safeZoneH)}
        };
        if (_controls isEqualTo []) exitWith {};
        private _minX = 1e6;
        private _minY = 1e6;
        private _maxX = -1e6;
        private _maxY = -1e6;
        {
            (ctrlPosition _x) params ["_xPos", "_yPos", "_width", "_height"];
            _minX = _minX min _xPos;
            _minY = _minY min _yPos;
            _maxX = _maxX max (_xPos + _width);
            _maxY = _maxY max (_yPos + _height);
        } forEach _controls;
        private _sourceW = 0.01 max (_maxX - _minX);
        private _sourceH = 0.01 max (_maxY - _minY);
        private _visibleX = safeZoneX;
        private _visibleY = safeZoneY;
        private _visibleRight = safeZoneX + safeZoneW;
        private _visibleBottom = safeZoneY + safeZoneH;
        private _visibleW = (_visibleRight - _visibleX) max 0.2;
        private _visibleH = (_visibleBottom - _visibleY) max 0.2;
        private _targetX = _visibleX + _visibleW * 0.025;
        private _targetY = _visibleY + _visibleH * 0.03;
        private _targetW = _visibleW * 0.95;
        private _targetH = _visibleH * 0.94;
        private _scaleX = _targetW / _sourceW;
        private _scaleY = _targetH / _sourceH;
        {
            (ctrlPosition _x) params ["_xPos", "_yPos", "_width", "_height"];
            private _newHeight = _height * _scaleY;
            _x ctrlSetPosition [
                _targetX + ((_xPos - _minX) * _scaleX),
                _targetY + ((_yPos - _minY) * _scaleY),
                _width * _scaleX,
                _newHeight
            ];
            if ((ctrlType _x) in [0, 1, 2, 11, 16, 41] && {ctrlText _x != ""}) then {
                private _fontHeight = ctrlFontHeight _x;
                if (_fontHeight > 0) then {
                    _fontHeight = (_fontHeight * (_scaleY max 1)) min (_newHeight * 0.72);
                    private _newWidth = _width * _scaleX;
                    private _minimumFont = (0.016 max (_newHeight * 0.30)) min _fontHeight;
                    _x ctrlSetFontHeight _fontHeight;
                    _x ctrlCommit 0;
                    while {
                        _fontHeight > _minimumFont
                        && {
                            ctrlTextHeight _x > (_newHeight * 0.94)
                            || {ctrlTextWidth _x > (_newWidth * 0.94)}
                        }
                    } do {
                        _fontHeight = (_fontHeight - 0.001) max _minimumFont;
                        _x ctrlSetFontHeight _fontHeight;
                        _x ctrlCommit 0;
                    };
                };
            };
            _x ctrlCommit 0;
        } forEach _controls;
        private _findings = [];
        private _right = _targetX + _targetW;
        private _bottom = _targetY + _targetH;
        {
            (ctrlPosition _x) params ["_xPos", "_yPos", "_width", "_height"];
            if (_xPos < (_targetX - 0.001) || {_yPos < (_targetY - 0.001)} || {(_xPos + _width) > (_right + 0.001)} || {(_yPos + _height) > (_bottom + 0.001)}) then {
                _findings pushBack format ["IDC %1 OUTSIDE SAFE CARD", ctrlIDC _x];
            };
            if (_width <= 0 || {_height <= 0}) then {
                _findings pushBack format ["IDC %1 INVALID DIMENSIONS", ctrlIDC _x];
            };
            if ((ctrlType _x) == 13 && {ctrlText _x != ""} && {(ctrlTextHeight _x) > (_height * 1.04)}) then {
                _findings pushBack format ["IDC %1 TEXT HEIGHT CLIPPED", ctrlIDC _x];
            };
            if ((ctrlType _x) in [0, 1, 2, 11, 16, 41] && {ctrlText _x != ""} && {(ctrlTextWidth _x) > (_width * 0.96)}) then {
                _findings pushBack format ["IDC %1 TEXT WIDTH CLIPPED", ctrlIDC _x];
            };
        } forEach _controls;
        _display setVariable ["Waldo_MG_SafeFitComplete", true];
        _display setVariable ["Waldo_MG_SafeFitBounds", [_targetX, _targetY, _targetW, _targetH]];
        _display setVariable ["Waldo_MG_SafeFitFindings", _findings];
        diag_log format ["[WMP PARTY UI] safe-card validation complete: %1 finding(s) %2", count _findings, _findings];
    };
};

Waldo_MG_fnc_installEscapeGuardLocal = {
    disableSerialization;
    params [["_display", displayNull]];
    if (!hasInterface || {isNull _display}) exitWith {};
    if (_display getVariable ["Waldo_MG_EscapeGuardInstalled", false]) exitWith {};
    private _handlerId = _display displayAddEventHandler [
        "KeyDown",
        {
            params ["_displayOrControl", "_key"];
            !isNull _displayOrControl && {_key == 1}
        }
    ];
    _display setVariable ["Waldo_MG_EscapeGuardInstalled", true];
    _display setVariable ["Waldo_MG_EscapeGuardHandlerId", _handlerId];
    [_display] call Waldo_MG_fnc_fitTableDisplaySafeLocal;
    [_display] spawn {
        params ["_display"];
        uiSleep 0.2;
        if (!isNull _display) then {[_display, true] call Waldo_fnc_UiThemeApplyDisplayLocal;};
    };
};

Waldo_MG_fnc_maintainSeatedScreenLocal = {
    if (!hasInterface || {isNull player}) exitWith {};
    private _table = player getVariable ["Waldo_MG_SeatedTable", objNull];
    if (isNull _table || {!alive player} || {(lifeState player) == "INCAPACITATED"}) exitWith {};
    private _leavePending = missionNamespace getVariable ["Waldo_MG_LeavePendingLocal", []];
    if ((count _leavePending) >= 2) then {
        if ((diag_tickTime - (_leavePending param [1, 0])) < 10) exitWith {};
        missionNamespace setVariable ["Waldo_MG_LeavePendingLocal", []];
    };
    private _openDisplays = allDisplays;
    private _screenOpen = false;
    {
        if (!_screenOpen && {!isNull _x} && {_x in _openDisplays}) then {
            _screenOpen = true;
        };
    } forEach [
        uiNamespace getVariable ["Waldo_MG_LobbyDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_CheckersDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_BattleshipDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_WhosWhoDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_ShotgunDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_RPSDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_BlackjackDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_ChessDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_PokerDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_DrawPokerDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_LiarsDiceDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_ConnectFourDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_UNODisplay", displayNull]
    ];
    if (_screenOpen) exitWith {};
    if (!isNull (findDisplay 49)) exitWith {};
    private _lastOpen = missionNamespace getVariable ["Waldo_MG_LastSeatedScreenRecoveryLocal", -10];
    if ((diag_tickTime - _lastOpen) < 1) exitWith {};
    missionNamespace setVariable ["Waldo_MG_LastSeatedScreenRecoveryLocal", diag_tickTime];
    [_table] call Waldo_MG_fnc_openCurrentTableScreenLocal;
}; 
 

Waldo_MG_fnc_releaseSeatPoseLocal = {
    params [
        ["_unit", objNull],
        ["_table", objNull],
        ["_seatIndex", -1],
        ["_placeOutside", true]
    ];
    if (isNull _unit) exitWith {};
    private _exitWorld = [];
    private _outwardDirection = getDir _unit;
    if (!isNull _table && {_seatIndex >= 0} && {_seatIndex < Waldo_MG_CFG_SEAT_COUNT}) then {
        _exitWorld = _table modelToWorldWorld (Waldo_MG_CFG_SEAT_EXIT_OFFSETS param [_seatIndex, [0, -1.8, 0]]);
        _outwardDirection = (
            getDir _table
            + (Waldo_MG_CFG_SEAT_DIRECTIONS param [_seatIndex, 0])
            + 180
        ) mod 360;
    };
    if ((attachedTo _unit) == _table && {!isNull _table}) then {
        detach _unit;
    };
    if (alive _unit && {(lifeState _unit) != "INCAPACITATED"} && {(vehicle _unit) == _unit}) then {
        _unit switchMove "";
        if (_placeOutside && {(count _exitWorld) >= 3}) then {
            _unit setDir _outwardDirection;
            _unit setPosWorld _exitWorld;
        };
    };
};

Waldo_MG_fnc_applySeatPoseLocal = {
    params [
        ["_unit", objNull],
        ["_table", objNull],
        ["_seatIndex", -1]
    ];
    if (!hasInterface || {isNull _unit} || {_unit != player}) exitWith {};
    if (isNull _table || {_seatIndex < 0} || {_seatIndex >= Waldo_MG_CFG_SEAT_COUNT}) exitWith {};
    private _needsPosition = (attachedTo _unit) != _table;
    if (_needsPosition) then {
        private _offset = Waldo_MG_CFG_SEAT_OFFSETS param [_seatIndex, [0, -1.05, 0]];
        private _relativeDirection = Waldo_MG_CFG_SEAT_DIRECTIONS param [_seatIndex, 0];
        _unit attachTo [_table, _offset];
        _unit setDir _relativeDirection;
        _unit setPosWorld (getPosWorld _unit);
    };
    private _animation = toLower (animationState _unit);
    if ((_animation find "hubsittingchair") < 0) then {
        _unit switchMove Waldo_MG_CFG_SEATED_ANIMATION;
        _unit playMoveNow Waldo_MG_CFG_SEATED_ANIMATION;
    };
};

Waldo_MG_fnc_closeLobbyIfInvalidLocal = {
    private _display = uiNamespace getVariable ["Waldo_MG_LobbyDisplay", displayNull];
    private _currentTable = if (isNull player) then {objNull} else {
        player getVariable ["Waldo_MG_SeatedTable", objNull]
    };
    private _spectatedTable = missionNamespace getVariable ["Waldo_MG_SpectatedTableLocal", objNull];
    if (!isNull _display) then {
        private _displayTable = _display getVariable ["Waldo_MG_LobbyTable", objNull];
        if (isNull _displayTable || {_displayTable != _currentTable}) then {
            _display closeDisplay 1;
        };
    };
    private _battleshipDisplay = uiNamespace getVariable ["Waldo_MG_BattleshipDisplay", displayNull];
    if (!isNull _battleshipDisplay) then {
        private _displayTable = _battleshipDisplay getVariable ["Waldo_MG_BattleshipTable", objNull];
        if (isNull _displayTable || {_displayTable != _currentTable && {!((_battleshipDisplay getVariable ["Waldo_MG_SpectatorMode", false]) && {_displayTable == _spectatedTable})}}) then {
            _battleshipDisplay closeDisplay 1;
        };
    };
    private _whosWhoDisplay = uiNamespace getVariable ["Waldo_MG_WhosWhoDisplay", displayNull];
    if (!isNull _whosWhoDisplay) then {
        private _displayTable = _whosWhoDisplay getVariable ["Waldo_MG_WhosWhoTable", objNull];
        if (isNull _displayTable || {_displayTable != _currentTable && {!((_whosWhoDisplay getVariable ["Waldo_MG_SpectatorMode", false]) && {_displayTable == _spectatedTable})}}) then {
            _whosWhoDisplay closeDisplay 1;
        };
    };
    private _shotgunDisplay = uiNamespace getVariable ["Waldo_MG_ShotgunDisplay", displayNull];
    if (!isNull _shotgunDisplay) then {
        private _displayTable = _shotgunDisplay getVariable ["Waldo_MG_ShotgunTable", objNull];
        if (isNull _displayTable || {_displayTable != _currentTable && {!((_shotgunDisplay getVariable ["Waldo_MG_SpectatorMode", false]) && {_displayTable == _spectatedTable})}}) then {
            _shotgunDisplay closeDisplay 1;
        };
    };
    private _checkersDisplay = uiNamespace getVariable ["Waldo_MG_CheckersDisplay", displayNull];
    if (!isNull _checkersDisplay) then {
        private _displayTable = _checkersDisplay getVariable ["Waldo_MG_CheckersTable", objNull];
        if (isNull _displayTable || {_displayTable != _currentTable && {!((_checkersDisplay getVariable ["Waldo_MG_SpectatorMode", false]) && {_displayTable == _spectatedTable})}}) then {
            _checkersDisplay closeDisplay 1;
        };
    };
    private _rpsDisplay = uiNamespace getVariable ["Waldo_MG_RPSDisplay", displayNull];
    if (!isNull _rpsDisplay) then {
        private _displayTable = _rpsDisplay getVariable ["Waldo_MG_RPSTable", objNull];
        if (isNull _displayTable || {_displayTable != _currentTable && {!((_rpsDisplay getVariable ["Waldo_MG_SpectatorMode", false]) && {_displayTable == _spectatedTable})}}) then {
            _rpsDisplay closeDisplay 1;
        };
    };
    private _blackjackDisplay = uiNamespace getVariable ["Waldo_MG_BlackjackDisplay", displayNull];
    if (!isNull _blackjackDisplay) then {
        private _displayTable = _blackjackDisplay getVariable ["Waldo_MG_BlackjackTable", objNull];
        if (isNull _displayTable || {_displayTable != _currentTable && {!((_blackjackDisplay getVariable ["Waldo_MG_SpectatorMode", false]) && {_displayTable == _spectatedTable})}}) then {
            _blackjackDisplay closeDisplay 1;
        };
    };
    private _chessDisplay = uiNamespace getVariable ["Waldo_MG_ChessDisplay", displayNull];
    if (!isNull _chessDisplay) then {
        private _displayTable = _chessDisplay getVariable ["Waldo_MG_ChessTable", objNull];
        if (isNull _displayTable || {_displayTable != _currentTable && {!((_chessDisplay getVariable ["Waldo_MG_SpectatorMode", false]) && {_displayTable == _spectatedTable})}}) then {
            _chessDisplay closeDisplay 1;
        };
    };
    private _pokerDisplay = uiNamespace getVariable ["Waldo_MG_PokerDisplay", displayNull];
    if (!isNull _pokerDisplay) then {
        private _displayTable = _pokerDisplay getVariable ["Waldo_MG_PokerTable", objNull];
        if (isNull _displayTable || {_displayTable != _currentTable && {!((_pokerDisplay getVariable ["Waldo_MG_SpectatorMode", false]) && {_displayTable == _spectatedTable})}}) then {
            _pokerDisplay closeDisplay 1;
        };
    };
    private _unoDisplay = uiNamespace getVariable ["Waldo_MG_UNODisplay", displayNull];
    if (!isNull _unoDisplay) then {
        private _displayTable = _unoDisplay getVariable ["Waldo_MG_UNOTable", objNull];
        if (isNull _displayTable || {_displayTable != _currentTable && {!((_unoDisplay getVariable ["Waldo_MG_SpectatorMode", false]) && {_displayTable == _spectatedTable})}}) then {
            _unoDisplay closeDisplay 1;
        };
    };
    {
        _x params ["_displayKey", "_tableKey"];
        private _gameDisplay = uiNamespace getVariable [_displayKey, displayNull];
        if (!isNull _gameDisplay) then {
            private _displayTable = _gameDisplay getVariable [_tableKey, objNull];
            if (isNull _displayTable || {_displayTable != _currentTable && {!((_gameDisplay getVariable ["Waldo_MG_SpectatorMode", false]) && {_displayTable == _spectatedTable})}}) then {_gameDisplay closeDisplay 1;};
        };
    } forEach [
        ["Waldo_MG_DrawPokerDisplay", "Waldo_MG_DrawPokerTable"],
        ["Waldo_MG_LiarsDiceDisplay", "Waldo_MG_LiarsDiceTable"],
        ["Waldo_MG_ConnectFourDisplay", "Waldo_MG_ConnectFourTable"]
    ];
};

Waldo_MG_fnc_closeTableGameDisplaysLocal = {
    if (!hasInterface) exitWith {};
    {
        private _display = uiNamespace getVariable [_x, displayNull];
        if (!isNull _display) then {_display closeDisplay 1;};
    } forEach [
        "Waldo_MG_LobbyDisplay", "Waldo_MG_BattleshipDisplay", "Waldo_MG_WhosWhoDisplay",
        "Waldo_MG_ShotgunDisplay", "Waldo_MG_CheckersDisplay", "Waldo_MG_RPSDisplay",
        "Waldo_MG_BlackjackDisplay", "Waldo_MG_ChessDisplay", "Waldo_MG_PokerDisplay",
        "Waldo_MG_DrawPokerDisplay", "Waldo_MG_LiarsDiceDisplay", "Waldo_MG_ConnectFourDisplay",
        "Waldo_MG_UNODisplay"
    ];
};

Waldo_MG_fnc_maintainSeatStateLocal = {
    if (!hasInterface) exitWith {};
    private _trackedUnit = missionNamespace getVariable ["Waldo_MG_SeatUnitLocal", objNull];
    private _trackedTable = missionNamespace getVariable ["Waldo_MG_SeatTableLocal", objNull];
    private _trackedIndex = missionNamespace getVariable ["Waldo_MG_SeatIndexLocal", -1];
    private _trackedToken = missionNamespace getVariable ["Waldo_MG_SeatTokenLocal", ""];

    if (_trackedUnit != player) then {
        if (!isNull _trackedUnit) then {
            [_trackedUnit, _trackedTable, _trackedIndex, false] call Waldo_MG_fnc_releaseSeatPoseLocal;
        };
        _trackedUnit = player;
        _trackedTable = objNull;
        _trackedIndex = -1;
        _trackedToken = "";
    };

    if (isNull player) exitWith {};
    private _table = player getVariable ["Waldo_MG_SeatedTable", objNull];
    private _seatIndex = player getVariable ["Waldo_MG_SeatIndex", -1];
    private _seatToken = player getVariable ["Waldo_MG_SeatToken", ""];
    private _valid = alive player
        && {(lifeState player) != "INCAPACITATED"}
        && {!isNull _table}
        && {_table getVariable ["Waldo_MG_IsPartyTable", false]}
        && {_seatIndex >= 0}
        && {_seatIndex < Waldo_MG_CFG_SEAT_COUNT}
        && {(vehicle player) == player};

    if (!_valid) then {
        if (!isNull _trackedTable || {_trackedIndex >= 0}) then {
            [
                player,
                _trackedTable,
                _trackedIndex,
                alive player && {(lifeState player) != "INCAPACITATED"} && {(vehicle player) == player}
            ] call Waldo_MG_fnc_releaseSeatPoseLocal;
        };
        _trackedTable = objNull;
        _trackedIndex = -1;
        _trackedToken = "";
        call Waldo_MG_fnc_closeLobbyIfInvalidLocal;
    } else {
        private _newSeat = _trackedTable != _table
            || {_trackedIndex != _seatIndex}
            || {_trackedToken != _seatToken};
        if (_newSeat && {!isNull _trackedTable}) then {
            [player, _trackedTable, _trackedIndex, false] call Waldo_MG_fnc_releaseSeatPoseLocal;
        };
        _trackedTable = _table;
        _trackedIndex = _seatIndex;
        _trackedToken = _seatToken;
        [player, _table, _seatIndex] call Waldo_MG_fnc_applySeatPoseLocal;
        if (_newSeat) then {
            [_table] call Waldo_MG_fnc_openCurrentTableScreenLocal;
        };
        call Waldo_MG_fnc_closeLobbyIfInvalidLocal;
    };

    missionNamespace setVariable ["Waldo_MG_SeatUnitLocal", _trackedUnit];
    missionNamespace setVariable ["Waldo_MG_SeatTableLocal", _trackedTable];
    missionNamespace setVariable ["Waldo_MG_SeatIndexLocal", _trackedIndex];
    missionNamespace setVariable ["Waldo_MG_SeatTokenLocal", _trackedToken];
}; 
 

Waldo_MG_fnc_refreshLobbyLocal = {
    disableSerialization;
    params [["_display", displayNull]];
    if (isNull _display) exitWith {};
    if (_display getVariable ["Waldo_MG_LobbyRefreshing", false]) exitWith {};
    _display setVariable ["Waldo_MG_LobbyRefreshing", true];
    private _table = _display getVariable ["Waldo_MG_LobbyTable", objNull];
    if (isNull _table || {isNull player} || {(player getVariable ["Waldo_MG_SeatedTable", objNull]) != _table}) exitWith {
        _display closeDisplay 1;
    };

    private _playerList = _display getVariable ["Waldo_MG_LobbyPlayerList", controlNull];
    private _gameList = _display getVariable ["Waldo_MG_LobbyGameList", controlNull];
    private _playerLabel = _display getVariable ["Waldo_MG_LobbyPlayerLabel", controlNull];
    private _gameName = _display getVariable ["Waldo_MG_LobbyGameName", controlNull];
    private _descriptionOne = _display getVariable ["Waldo_MG_LobbyDescriptionOne", controlNull];
    private _descriptionTwo = _display getVariable ["Waldo_MG_LobbyDescriptionTwo", controlNull];
    private _playersText = _display getVariable ["Waldo_MG_LobbyPlayersText", controlNull];
    private _votesTextOne = _display getVariable ["Waldo_MG_LobbyVotesTextOne", controlNull];
    private _votesTextTwo = _display getVariable ["Waldo_MG_LobbyVotesTextTwo", controlNull];
    private _availability = _display getVariable ["Waldo_MG_LobbyAvailability", controlNull];
    private _moduleNoteOne = _display getVariable ["Waldo_MG_LobbyModuleNoteOne", controlNull];
    private _moduleNoteTwo = _display getVariable ["Waldo_MG_LobbyModuleNoteTwo", controlNull];
    private _statusOne = _display getVariable ["Waldo_MG_LobbyStatusOne", controlNull];
    private _statusTwo = _display getVariable ["Waldo_MG_LobbyStatusTwo", controlNull];
    private _voteButton = _display getVariable ["Waldo_MG_LobbyVoteButton", controlNull];
    private _readyButton = _display getVariable ["Waldo_MG_LobbyReadyButton", controlNull];

    private _seats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
    private _votes = [(_table getVariable ["Waldo_MG_TableVotes", []])] call Waldo_MG_fnc_normalizeVotes;
    private _ready = [(_table getVariable ["Waldo_MG_TableReady", []])] call Waldo_MG_fnc_normalizeReady;
    private _occupants = [_table] call Waldo_MG_fnc_getTableOccupantCount;
    private _revision = _table getVariable ["Waldo_MG_TableRevision", 0];
    private _lastRevision = _display getVariable ["Waldo_MG_LobbyLastRevision", -1];

    if (!isNull _playerLabel) then {
        _playerLabel ctrlSetText format ["Players at Table  (%1/%2)", _occupants, Waldo_MG_CFG_SEAT_COUNT];
        _playerLabel ctrlCommit 0;
    };

    if (_revision != _lastRevision) then {
        private _selectedGameId = _display getVariable ["Waldo_MG_LobbySelectedGameId", ""];
        if (!isNull _gameList) then {
            private _oldSelection = lbCurSel _gameList;
            if (_oldSelection >= 0) then {
                _selectedGameId = _gameList lbData _oldSelection;
            };
        };

        if (!isNull _playerList) then {
            lbClear _playerList;
            for "_index" from 0 to (Waldo_MG_CFG_SEAT_COUNT - 1) do {
                private _unit = _seats param [_index, objNull];
                private _row = -1;
                if (isNull _unit) then {
                    _row = _playerList lbAdd format ["Seat %1  -  Open", _index + 1];
                    _playerList lbSetColor [_row, [0.55, 0.58, 0.62, 1]];
                } else {
                    private _voteId = _votes param [_index, ""];
                    private _voteName = [_voteId] call Waldo_MG_fnc_getGameName;
                    private _readyText = if (_ready param [_index, false]) then {"READY"} else {"NOT READY"};
                    _row = _playerList lbAdd format [
                        "Seat %1  -  %2  [%3]",
                        _index + 1,
                        name _unit,
                        _readyText
                    ];
                    _playerList lbSetTooltip [_row, format [
                        "%1 - Vote: %2 - %3",
                        name _unit,
                        _voteName,
                        _readyText
                    ]];
                    if (_unit == player) then {
                        _playerList lbSetColor [_row, [0.30, 0.90, 1, 1]];
                    } else {
                        if (_ready param [_index, false]) then {
                            _playerList lbSetColor [_row, [0.38, 1, 0.48, 1]];
                        };
                    };
                };
            };
        };

        if (!isNull _gameList) then {
            lbClear _gameList;
            private _selectionIndex = -1;
            {
                private _gameId = _x param [0, ""];
                private _eligible = [_table, _gameId] call Waldo_MG_fnc_isGameEligibleAtTable;
                private _voteCount = [_table, _gameId] call Waldo_MG_fnc_getVoteCount;
                private _lockText = if (_eligible) then {"OPEN"} else {"LOCKED"};
                private _row = _gameList lbAdd format [
                    "%1  [%2]  (%3)",
                    _x param [1, "Game"],
                    _lockText,
                    _voteCount
                ];
                _gameList lbSetData [_row, _gameId];
                _gameList lbSetTooltip [_row, format [
                    "%1 - %2",
                    [_x] call Waldo_MG_fnc_getPlayerRequirementText,
                    (_x param [2, [""]]) param [0, ""]
                ]];
                if (!_eligible) then {
                    _gameList lbSetColor [_row, [0.58, 0.58, 0.62, 1]];
                };
                if (_gameId == _selectedGameId) then {
                    _selectionIndex = _row;
                };
            } forEach Waldo_MG_Games;
            if (_selectionIndex < 0 && {(lbSize _gameList) > 0}) then {
                _selectionIndex = 0;
            };
            if (_selectionIndex >= 0) then {
                _gameList lbSetCurSel _selectionIndex;
                _selectedGameId = _gameList lbData _selectionIndex;
            };
            _display setVariable ["Waldo_MG_LobbySelectedGameId", _selectedGameId];
        };
        _display setVariable ["Waldo_MG_LobbyLastRevision", _revision];
    };

    private _selectedListIndex = if (isNull _gameList) then {-1} else {lbCurSel _gameList};
    private _selectedGameId = _display getVariable ["Waldo_MG_LobbySelectedGameId", ""];
    if (_selectedListIndex >= 0 && {!isNull _gameList}) then {
        _selectedGameId = _gameList lbData _selectedListIndex;
        _display setVariable ["Waldo_MG_LobbySelectedGameId", _selectedGameId];
    };
    private _game = [_selectedGameId] call Waldo_MG_fnc_getGame;
    private _eligible = [_table, _selectedGameId] call Waldo_MG_fnc_isGameEligibleAtTable;
    private _voteCount = [_table, _selectedGameId] call Waldo_MG_fnc_getVoteCount;
    private _requiredVotes = _table getVariable [
        "Waldo_MG_TableRequiredVotes",
        floor (_occupants / 2) + 1
    ];
    private _consensusGame = _table getVariable ["Waldo_MG_TableSelectedGame", ""];
    private _phase = _table getVariable ["Waldo_MG_TablePhase", "LOBBY"];
    private _seatIndex = _seats find player;
    private _localReady = _seatIndex >= 0 && {_ready param [_seatIndex, false]};

    if (!isNull _gameName) then {
        _gameName ctrlSetText (_game param [1, "Select a game"]);
        _gameName ctrlCommit 0;
    };
    private _descriptionLines = _game param [
        2,
        ["Select a game from the list to inspect it.", ""]
    ];
    if ((typeName _descriptionLines) != "ARRAY") then {
        _descriptionLines = [_descriptionLines, ""];
    };
    if (!isNull _descriptionOne) then {
        _descriptionOne ctrlSetText (_descriptionLines param [0, ""]);
        _descriptionOne ctrlCommit 0;
    };
    if (!isNull _descriptionTwo) then {
        _descriptionTwo ctrlSetText (_descriptionLines param [1, ""]);
        _descriptionTwo ctrlCommit 0;
    };
    if (!isNull _playersText) then {
        _playersText ctrlSetText format [
            "Player requirement: %1",
            [_game] call Waldo_MG_fnc_getPlayerRequirementText
        ];
        _playersText ctrlCommit 0;
    };
    if (!isNull _votesTextOne) then {
        _votesTextOne ctrlSetText format ["Current votes: %1", _voteCount];
        _votesTextOne ctrlCommit 0;
    };
    if (!isNull _votesTextTwo) then {
        _votesTextTwo ctrlSetText format [
            "Consensus needs %1 matching vote(s)",
            _requiredVotes
        ];
        _votesTextTwo ctrlCommit 0;
    };
    if (!isNull _availability) then {
        _availability ctrlSetText (if (_eligible) then {
            "AVAILABLE for the current table size"
        } else {
            "LOCKED for the current table size"
        });
        _availability ctrlSetTextColor (if (_eligible) then {
            [0.38, 1, 0.48, 1]
        } else {
            [1, 0.43, 0.32, 1]
        });
        _availability ctrlCommit 0;
    };
    private _moduleLines = _game param [
        5,
        ["Game implementation is not available yet.", ""]
    ];
    if ((typeName _moduleLines) != "ARRAY") then {
        _moduleLines = [_moduleLines, ""];
    };
    if (!isNull _moduleNoteOne) then {
        _moduleNoteOne ctrlSetText (_moduleLines param [0, ""]);
        _moduleNoteOne ctrlCommit 0;
    };
    if (!isNull _moduleNoteTwo) then {
        _moduleNoteTwo ctrlSetText (_moduleLines param [1, ""]);
        _moduleNoteTwo ctrlCommit 0;
    };

    private _readyCount = 0;
    for "_index" from 0 to (Waldo_MG_CFG_SEAT_COUNT - 1) do {
        if (!isNull (_seats param [_index, objNull]) && {_ready param [_index, false]}) then {
            _readyCount = _readyCount + 1;
        };
    };
    private _statusLineOne = "Waiting for a player.";
    private _statusLineTwo = "Blackjack supports a solo table.";
    if (_occupants >= 1) then {
        if (_consensusGame == "") then {
            _statusLineOne = if (_occupants == 1) then {"Solo table: Blackjack is available."} else {format ["No consensus: %1 matching vote(s) required.", _requiredVotes]};
            _statusLineTwo = if (_occupants == 1) then {"Vote for Blackjack, or invite another player."} else {"Choose the same supported game."};
        } else {
            if (_phase == "READY") then {
                _statusLineOne = format [
                    "EVERYONE READY: %1",
                    [_consensusGame] call Waldo_MG_fnc_getGameName
                ];
                _statusLineTwo = switch (_consensusGame) do {
                    case "battleship": {"Opening the private fleet deployment grids..."};
                    case "whoswho": {"Assigning each player a private target..."};
                    case "shotgun": {"Loading the authoritative chamber..."};
                    case "blackjack": {"Opening the authoritative Blackjack table..."};
                    case "poker": {"Shuffling the Hold'em deck..."};
                    case "drawpoker": {"Dealing five private cards to each player..."};
                    case "liarsdice": {"Rolling each player's private dice..."};
                    case "chess": {"Preparing the Chess board..."};
                    case "checkers": {"Preparing the Checkers board..."};
                    case "connectfour": {"Preparing the first Connect Four board..."};
                    case "rps": {"Preparing the hidden-choice reveal..."};
                    case "uno": {"Dealing the private UNO hands..."};
                    default {"Preparing the selected game..."};
                };
            } else {
                _statusLineOne = format [
                    "Consensus: %1",
                    [_consensusGame] call Waldo_MG_fnc_getGameName
                ];
                _statusLineTwo = format ["Ready: %1/%2", _readyCount, _occupants];
            };
        };
    };
    if (!isNull _statusOne) then {
        _statusOne ctrlSetText _statusLineOne;
        _statusOne ctrlCommit 0;
    };
    if (!isNull _statusTwo) then {
        _statusTwo ctrlSetText _statusLineTwo;
        _statusTwo ctrlCommit 0;
    };
    if (!isNull _voteButton) then {
        _voteButton ctrlSetText format ["Vote: %1", _game param [1, "Game"]];
        _voteButton ctrlEnable (_seatIndex >= 0 && {_eligible});
        _voteButton ctrlCommit 0;
    };
    if (!isNull _readyButton) then {
        _readyButton ctrlSetText (if (_localReady) then {"Cancel Ready"} else {"Set Ready"});
        _readyButton ctrlEnable (_seatIndex >= 0 && {_localReady || {_consensusGame != ""}});
        _readyButton ctrlCommit 0;
    };
    _display setVariable ["Waldo_MG_LobbyRefreshing", false];
};

Waldo_MG_fnc_openLobbyLocal = {
    disableSerialization;
    params [["_table", objNull]];
    if (!hasInterface || {isNull player}) exitWith {};
    if (isNull _table || {(player getVariable ["Waldo_MG_SeatedTable", objNull]) != _table}) exitWith {
        ["Sit at the party table before opening its lobby."] call Waldo_MG_fnc_notifyLocal;
    };
    private _parent = findDisplay 46;
    if (isNull _parent) exitWith {
        ["Party lobby display is unavailable."] call Waldo_MG_fnc_notifyLocal;
    };
    private _existing = uiNamespace getVariable ["Waldo_MG_LobbyDisplay", displayNull];
    if (!isNull _existing) then {
        _existing closeDisplay 1;
    };

    private _display = _parent createDisplay "RscDisplayEmpty";
    if (isNull _display) exitWith {};
    uiNamespace setVariable ["Waldo_MG_LobbyDisplay", _display];
    _display setVariable ["Waldo_MG_LobbyTable", _table];
    _display setVariable ["Waldo_MG_LobbyLastRevision", -1];
    _display setVariable ["Waldo_MG_LobbySelectedGameId", ""];
    [_display] call Waldo_MG_fnc_installEscapeGuardLocal;
    private _background = _display ctrlCreate ["RscText", -1];
    _background ctrlSetPosition [0.015, 0.02, 1.15, 1.04];
    _background ctrlSetBackgroundColor [0.016, 0.022, 0.040, 0.97];
    _background ctrlCommit 0;

    private _topBar = _display ctrlCreate ["RscText", -1];
    _topBar ctrlSetPosition [0.015, 0.02, 1.15, 0.06];
    _topBar ctrlSetBackgroundColor [0.10, 0.19, 0.40, 0.98];
    _topBar ctrlCommit 0;

    // WMP brand accent bar under the header.
    private _accentBar = _display ctrlCreate ["RscText", -1];
    _accentBar ctrlSetPosition [0.015, 0.079, 1.15, 0.004];
    _accentBar ctrlSetBackgroundColor [0.243, 0.463, 0.827, 1];
    _accentBar ctrlCommit 0;

    private _title = _display ctrlCreate ["RscText", -1];
    _title ctrlSetPosition [0.045, 0.026, 0.72, 0.047];
    _title ctrlSetText "Mini Games Table Lobby";
    _title ctrlSetTextColor [0.84, 0.90, 1, 1];
    _title ctrlSetFontHeight 0.040;
    _title ctrlCommit 0;

    private _subtitle = _display ctrlCreate ["RscText", -1];
    _subtitle ctrlSetPosition [0.75, 0.032, 0.37, 0.036];
    _subtitle ctrlSetText "Vote, ready, play";
    _subtitle ctrlSetTextColor [0.72, 0.94, 1, 1];
    _subtitle ctrlSetFontHeight 0.022;
    _subtitle ctrlCommit 0;

    private _playerLabel = _display ctrlCreate ["RscText", -1];
    _playerLabel ctrlSetPosition [0.045, 0.105, 0.30, 0.043];
    _playerLabel ctrlSetTextColor [0.52, 0.92, 1, 1];
    _playerLabel ctrlSetFontHeight 0.028;
    _playerLabel ctrlCommit 0;

    private _playerList = _display ctrlCreate ["RscListbox", -1];
    _playerList ctrlSetPosition [0.045, 0.155, 0.30, 0.755];
    _playerList ctrlSetBackgroundColor [0.015, 0.025, 0.045, 0.88];
    _playerList ctrlCommit 0;

    private _gamesLabel = _display ctrlCreate ["RscText", -1];
    _gamesLabel ctrlSetPosition [0.375, 0.105, 0.31, 0.043];
    _gamesLabel ctrlSetText "Games and Votes";
    _gamesLabel ctrlSetTextColor [0.55, 0.72, 0.98, 1];
    _gamesLabel ctrlSetFontHeight 0.028;
    _gamesLabel ctrlCommit 0;

    private _gameList = _display ctrlCreate ["RscListbox", -1];
    _gameList ctrlSetPosition [0.375, 0.155, 0.31, 0.57];
    _gameList ctrlSetBackgroundColor [0.020, 0.032, 0.055, 0.90];
    _gameList ctrlCommit 0;

    private _consensusLabel = _display ctrlCreate ["RscText", -1];
    _consensusLabel ctrlSetPosition [0.375, 0.75, 0.31, 0.04];
    _consensusLabel ctrlSetText "Table Status";
    _consensusLabel ctrlSetTextColor [0.70, 0.92, 1, 1];
    _consensusLabel ctrlCommit 0;

    private _statusBackground = _display ctrlCreate ["RscText", -1];
    _statusBackground ctrlSetPosition [0.375, 0.795, 0.31, 0.115];
    _statusBackground ctrlSetBackgroundColor [0.035, 0.055, 0.075, 0.92];
    _statusBackground ctrlCommit 0;

    private _statusOne = _display ctrlCreate ["RscText", -1];
    _statusOne ctrlSetPosition [0.392, 0.812, 0.276, 0.035];
    _statusOne ctrlSetTextColor [0.88, 0.94, 1, 1];
    _statusOne ctrlSetFontHeight 0.020;
    _statusOne ctrlCommit 0;

    private _statusTwo = _display ctrlCreate ["RscText", -1];
    _statusTwo ctrlSetPosition [0.392, 0.855, 0.276, 0.035];
    _statusTwo ctrlSetTextColor [0.72, 0.82, 0.92, 1];
    _statusTwo ctrlSetFontHeight 0.019;
    _statusTwo ctrlCommit 0;

    private _detailBackground = _display ctrlCreate ["RscText", -1];
    _detailBackground ctrlSetPosition [0.715, 0.105, 0.415, 0.805];
    _detailBackground ctrlSetBackgroundColor [0.020, 0.030, 0.045, 0.94];
    _detailBackground ctrlCommit 0;

    private _detailLabel = _display ctrlCreate ["RscText", -1];
    _detailLabel ctrlSetPosition [0.745, 0.125, 0.35, 0.035];
    _detailLabel ctrlSetText "Selected Game";
    _detailLabel ctrlSetTextColor [0.60, 0.80, 0.92, 1];
    _detailLabel ctrlSetFontHeight 0.022;
    _detailLabel ctrlCommit 0;

    private _gameName = _display ctrlCreate ["RscText", -1];
    _gameName ctrlSetPosition [0.745, 0.17, 0.35, 0.052];
    _gameName ctrlSetTextColor [0.80, 0.89, 1, 1];
    _gameName ctrlSetFontHeight 0.035;
    _gameName ctrlCommit 0;

    private _descriptionOne = _display ctrlCreate ["RscText", -1];
    _descriptionOne ctrlSetPosition [0.745, 0.245, 0.35, 0.040];
    _descriptionOne ctrlSetTextColor [0.88, 0.88, 0.92, 1];
    _descriptionOne ctrlSetFontHeight 0.021;
    _descriptionOne ctrlCommit 0;

    private _descriptionTwo = _display ctrlCreate ["RscText", -1];
    _descriptionTwo ctrlSetPosition [0.745, 0.285, 0.35, 0.040];
    _descriptionTwo ctrlSetTextColor [0.88, 0.88, 0.92, 1];
    _descriptionTwo ctrlSetFontHeight 0.021;
    _descriptionTwo ctrlCommit 0;

    private _playersText = _display ctrlCreate ["RscText", -1];
    _playersText ctrlSetPosition [0.745, 0.365, 0.35, 0.042];
    _playersText ctrlSetTextColor [0.64, 0.90, 1, 1];
    _playersText ctrlCommit 0;

    private _votesTextOne = _display ctrlCreate ["RscText", -1];
    _votesTextOne ctrlSetPosition [0.745, 0.425, 0.35, 0.032];
    _votesTextOne ctrlSetTextColor [0.78, 0.82, 1, 1];
    _votesTextOne ctrlSetFontHeight 0.020;
    _votesTextOne ctrlCommit 0;

    private _votesTextTwo = _display ctrlCreate ["RscText", -1];
    _votesTextTwo ctrlSetPosition [0.745, 0.457, 0.35, 0.032];
    _votesTextTwo ctrlSetTextColor [0.68, 0.74, 0.90, 1];
    _votesTextTwo ctrlSetFontHeight 0.019;
    _votesTextTwo ctrlCommit 0;

    private _availability = _display ctrlCreate ["RscText", -1];
    _availability ctrlSetPosition [0.745, 0.50, 0.35, 0.045];
    _availability ctrlSetFontHeight 0.024;
    _availability ctrlCommit 0;

    private _futureLabel = _display ctrlCreate ["RscText", -1];
    _futureLabel ctrlSetPosition [0.745, 0.585, 0.35, 0.035];
    _futureLabel ctrlSetText "Game Module Status";
    _futureLabel ctrlSetTextColor [0.60, 0.80, 0.92, 1];
    _futureLabel ctrlCommit 0;

    private _moduleNoteOne = _display ctrlCreate ["RscText", -1];
    _moduleNoteOne ctrlSetPosition [0.745, 0.63, 0.35, 0.038];
    _moduleNoteOne ctrlSetTextColor [0.78, 0.80, 0.86, 1];
    _moduleNoteOne ctrlSetFontHeight 0.020;
    _moduleNoteOne ctrlCommit 0;

    private _moduleNoteTwo = _display ctrlCreate ["RscText", -1];
    _moduleNoteTwo ctrlSetPosition [0.745, 0.668, 0.35, 0.038];
    _moduleNoteTwo ctrlSetTextColor [0.78, 0.80, 0.86, 1];
    _moduleNoteTwo ctrlSetFontHeight 0.020;
    _moduleNoteTwo ctrlCommit 0;

    private _rulesOne = _display ctrlCreate ["RscText", -1];
    _rulesOne ctrlSetPosition [0.745, 0.75, 0.35, 0.035];
    _rulesOne ctrlSetText "A strict majority selects the game.";
    _rulesOne ctrlSetTextColor [0.66, 0.68, 0.75, 1];
    _rulesOne ctrlSetFontHeight 0.019;
    _rulesOne ctrlCommit 0;

    private _rulesTwo = _display ctrlCreate ["RscText", -1];
    _rulesTwo ctrlSetPosition [0.745, 0.79, 0.35, 0.035];
    _rulesTwo ctrlSetText "Roster or vote changes clear all ready states.";
    _rulesTwo ctrlSetTextColor [0.66, 0.68, 0.75, 1];
    _rulesTwo ctrlSetFontHeight 0.019;
    _rulesTwo ctrlCommit 0;

    private _rulesThree = _display ctrlCreate ["RscText", -1];
    _rulesThree ctrlSetPosition [0.745, 0.83, 0.35, 0.035];
    _rulesThree ctrlSetText "Leave Table releases your seat.";
    _rulesThree ctrlSetTextColor [0.86, 0.62, 0.44, 1];
    _rulesThree ctrlSetFontHeight 0.019;
    _rulesThree ctrlCommit 0;

    private _voteButton = _display ctrlCreate ["RscButtonMenu", -1];
    _voteButton ctrlSetPosition [0.375, 0.955, 0.19, 0.060];
    _voteButton ctrlSetText "Vote";
    _voteButton ctrlCommit 0;

    private _readyButton = _display ctrlCreate ["RscButtonMenu", -1];
    _readyButton ctrlSetPosition [0.575, 0.955, 0.17, 0.060];
    _readyButton ctrlSetText "Set Ready";
    _readyButton ctrlCommit 0;

    private _leaveButton = _display ctrlCreate ["RscButtonMenu", -1];
    _leaveButton ctrlSetPosition [0.845, 0.955, 0.26, 0.060];
    _leaveButton ctrlSetText "Leave Table";
    _leaveButton ctrlCommit 0;

    _display setVariable ["Waldo_MG_LobbyPlayerList", _playerList];
    _display setVariable ["Waldo_MG_LobbyGameList", _gameList];
    _display setVariable ["Waldo_MG_LobbyPlayerLabel", _playerLabel];
    _display setVariable ["Waldo_MG_LobbyGameName", _gameName];
    _display setVariable ["Waldo_MG_LobbyDescriptionOne", _descriptionOne];
    _display setVariable ["Waldo_MG_LobbyDescriptionTwo", _descriptionTwo];
    _display setVariable ["Waldo_MG_LobbyPlayersText", _playersText];
    _display setVariable ["Waldo_MG_LobbyVotesTextOne", _votesTextOne];
    _display setVariable ["Waldo_MG_LobbyVotesTextTwo", _votesTextTwo];
    _display setVariable ["Waldo_MG_LobbyAvailability", _availability];
    _display setVariable ["Waldo_MG_LobbyModuleNoteOne", _moduleNoteOne];
    _display setVariable ["Waldo_MG_LobbyModuleNoteTwo", _moduleNoteTwo];
    _display setVariable ["Waldo_MG_LobbyStatusOne", _statusOne];
    _display setVariable ["Waldo_MG_LobbyStatusTwo", _statusTwo];
    _display setVariable ["Waldo_MG_LobbyVoteButton", _voteButton];
    _display setVariable ["Waldo_MG_LobbyReadyButton", _readyButton];

    _gameList ctrlAddEventHandler [
        "LBSelChanged",
        {
            params ["_control", "_index"];
            private _display = ctrlParent _control;
            if (_index >= 0) then {
                _display setVariable ["Waldo_MG_LobbySelectedGameId", _control lbData _index];
            };
            [_display] call Waldo_MG_fnc_refreshLobbyLocal;
        }
    ];
    _voteButton ctrlAddEventHandler [
        "ButtonClick",
        {
            params ["_control"];
            private _display = ctrlParent _control;
            private _table = _display getVariable ["Waldo_MG_LobbyTable", objNull];
            private _gameList = _display getVariable ["Waldo_MG_LobbyGameList", controlNull];
            private _gameId = "";
            if (!isNull _gameList && {(lbCurSel _gameList) >= 0}) then {
                _gameId = _gameList lbData (lbCurSel _gameList);
            };
            [_table, _gameId] call Waldo_MG_fnc_submitVoteRequestLocal;
        }
    ];
    _readyButton ctrlAddEventHandler [
        "ButtonClick",
        {
            params ["_control"];
            private _display = ctrlParent _control;
            private _table = _display getVariable ["Waldo_MG_LobbyTable", objNull];
            private _seatIndex = [_table, player] call Waldo_MG_fnc_getSeatIndex;
            private _ready = if (isNull _table) then {[]} else {
                [(_table getVariable ["Waldo_MG_TableReady", []])] call Waldo_MG_fnc_normalizeReady
            };
            private _current = _seatIndex >= 0 && {_ready param [_seatIndex, false]};
            [_table, !_current] call Waldo_MG_fnc_submitReadyRequestLocal;
        }
    ];
    _leaveButton ctrlAddEventHandler [
        "ButtonClick",
        {
            call Waldo_MG_fnc_submitLeaveRequestLocal;
        }
    ];
    [_display] call Waldo_MG_fnc_refreshLobbyLocal;
    [_display] spawn {
        disableSerialization;
        params ["_activeDisplay"];
        while {!isNull _activeDisplay} do {
            [_activeDisplay] call Waldo_MG_fnc_refreshLobbyLocal;
            uiSleep 0.25;
        };
    };
}; 
 

Waldo_MG_fnc_openCurrentTableScreenLocal = {
    params [["_table", objNull]];
    if (isNull _table) exitWith {};
    private _activeGame = [_table] call Waldo_MG_fnc_getTableActiveGameId;
    if (_activeGame == "battleship") exitWith {
        [_table] call Waldo_MG_fnc_openBattleshipLocal;
    };
    if (_activeGame == "whoswho") exitWith {
        [_table] call Waldo_MG_fnc_openWhosWhoLocal;
    };
    if (_activeGame == "shotgun") exitWith {
        [_table] call Waldo_MG_fnc_openShotgunLocal;
    };
    if (_activeGame == "checkers") exitWith {
        [_table] call Waldo_MG_fnc_openCheckersLocal;
    };
    if (_activeGame == "rps") exitWith {
        [_table] call Waldo_MG_fnc_openRPSLocal;
    };
    if (_activeGame == "blackjack") exitWith {
        [_table] call Waldo_MG_fnc_openBlackjackLocal;
    };
    if (_activeGame == "chess") exitWith {
        [_table] call Waldo_MG_fnc_openChessLocal;
    };
    if (_activeGame == "poker") exitWith {
        [_table] call Waldo_MG_fnc_openPokerLocal;
    };
    if (_activeGame == "drawpoker") exitWith {[_table] call Waldo_MG_fnc_openDrawPokerLocal;};
    if (_activeGame == "liarsdice") exitWith {[_table] call Waldo_MG_fnc_openLiarsDiceLocal;};
    if (_activeGame == "connectfour") exitWith {[_table] call Waldo_MG_fnc_openConnectFourLocal;};
    if (_activeGame == "uno") exitWith {
        [_table] call Waldo_MG_fnc_openUNOLocal;
    };
    [_table] call Waldo_MG_fnc_openLobbyLocal;
};

Waldo_MG_fnc_maintainGameTransitionLocal = {
    if (!hasInterface || {isNull player}) exitWith {};
    private _table = player getVariable ["Waldo_MG_SeatedTable", objNull];
    if (isNull _table) exitWith {};
    private _activeGame = [_table] call Waldo_MG_fnc_getTableActiveGameId;
    if (_activeGame == "battleship") then {
        private _gameId = _table getVariable ["Waldo_MG_BattleshipGameId", ""];
        if (_gameId != "" && {_gameId != (missionNamespace getVariable ["Waldo_MG_LastAutoOpenedBattleshipLocal", ""])}) then {
            missionNamespace setVariable ["Waldo_MG_LastAutoOpenedBattleshipLocal", _gameId];
            [_table] call Waldo_MG_fnc_openBattleshipLocal;
        };
    };
    if (_activeGame == "whoswho") then {
        private _gameId = _table getVariable ["Waldo_MG_WhosWhoGameId", ""];
        if (_gameId != "" && {_gameId != (missionNamespace getVariable ["Waldo_MG_LastAutoOpenedWhosWhoLocal", ""])}) then {
            missionNamespace setVariable ["Waldo_MG_LastAutoOpenedWhosWhoLocal", _gameId];
            [_table] call Waldo_MG_fnc_openWhosWhoLocal;
        };
    };
    if (_activeGame == "shotgun") then {
        private _gameId = _table getVariable ["Waldo_MG_ShotgunGameId", ""];
        if (_gameId != "" && {_gameId != (missionNamespace getVariable ["Waldo_MG_LastAutoOpenedShotgunLocal", ""])}) then {
            missionNamespace setVariable ["Waldo_MG_LastAutoOpenedShotgunLocal", _gameId];
            [_table] call Waldo_MG_fnc_openShotgunLocal;
        };
    };
    if (_activeGame == "checkers") then {
        private _gameId = _table getVariable ["Waldo_MG_CheckersGameId", ""];
        if (_gameId != "" && {_gameId != (missionNamespace getVariable ["Waldo_MG_LastAutoOpenedCheckersLocal", ""])}) then {
            missionNamespace setVariable ["Waldo_MG_LastAutoOpenedCheckersLocal", _gameId];
            [_table] call Waldo_MG_fnc_openCheckersLocal;
        };
    };
    if (_activeGame == "rps") then {
        private _gameId = _table getVariable ["Waldo_MG_RPSGameId", ""];
        if (_gameId != "" && {_gameId != (missionNamespace getVariable ["Waldo_MG_LastAutoOpenedRPSLocal", ""])}) then {
            missionNamespace setVariable ["Waldo_MG_LastAutoOpenedRPSLocal", _gameId];
            [_table] call Waldo_MG_fnc_openRPSLocal;
        };
    };
    if (_activeGame == "blackjack") then {
        private _gameId = _table getVariable ["Waldo_MG_BlackjackGameId", ""];
        if (_gameId != "" && {_gameId != (missionNamespace getVariable ["Waldo_MG_LastAutoOpenedBlackjackLocal", ""])}) then {
            missionNamespace setVariable ["Waldo_MG_LastAutoOpenedBlackjackLocal", _gameId];
            [_table] call Waldo_MG_fnc_openBlackjackLocal;
        };
    };
    if (_activeGame == "chess") then {
        private _gameId = _table getVariable ["Waldo_MG_ChessGameId", ""];
        if (_gameId != "" && {_gameId != (missionNamespace getVariable ["Waldo_MG_LastAutoOpenedChessLocal", ""])}) then {
            missionNamespace setVariable ["Waldo_MG_LastAutoOpenedChessLocal", _gameId];
            [_table] call Waldo_MG_fnc_openChessLocal;
        };
    };
    if (_activeGame == "poker") then {
        private _gameId = _table getVariable ["Waldo_MG_PokerGameId", ""];
        if (_gameId != "" && {_gameId != (missionNamespace getVariable ["Waldo_MG_LastAutoOpenedPokerLocal", ""])}) then {
            missionNamespace setVariable ["Waldo_MG_LastAutoOpenedPokerLocal", _gameId];
            [_table] call Waldo_MG_fnc_openPokerLocal;
        };
    };
    if (_activeGame == "drawpoker") then {
        private _gameId = _table getVariable ["Waldo_MG_DrawPokerGameId", ""];
        if (_gameId != "" && {_gameId != (missionNamespace getVariable ["Waldo_MG_LastAutoOpenedDrawPokerLocal", ""])}) then {missionNamespace setVariable ["Waldo_MG_LastAutoOpenedDrawPokerLocal", _gameId]; [_table] call Waldo_MG_fnc_openDrawPokerLocal;};
    };
    if (_activeGame == "liarsdice") then {
        private _gameId = _table getVariable ["Waldo_MG_LiarsDiceGameId", ""];
        if (_gameId != "" && {_gameId != (missionNamespace getVariable ["Waldo_MG_LastAutoOpenedLiarsDiceLocal", ""])}) then {missionNamespace setVariable ["Waldo_MG_LastAutoOpenedLiarsDiceLocal", _gameId]; [_table] call Waldo_MG_fnc_openLiarsDiceLocal;};
    };
    if (_activeGame == "connectfour") then {
        private _gameId = _table getVariable ["Waldo_MG_ConnectFourGameId", ""];
        if (_gameId != "" && {_gameId != (missionNamespace getVariable ["Waldo_MG_LastAutoOpenedConnectFourLocal", ""])}) then {missionNamespace setVariable ["Waldo_MG_LastAutoOpenedConnectFourLocal", _gameId]; [_table] call Waldo_MG_fnc_openConnectFourLocal;};
    };
    if (_activeGame == "uno") then {
        private _gameId = _table getVariable ["Waldo_MG_UNOGameId", ""];
        if (_gameId != "" && {_gameId != (missionNamespace getVariable ["Waldo_MG_LastAutoOpenedUNOLocal", ""])}) then {
            missionNamespace setVariable ["Waldo_MG_LastAutoOpenedUNOLocal", _gameId];
            [_table] call Waldo_MG_fnc_openUNOLocal;
        };
    };
};

Waldo_MG_fnc_startClientLoop = {
    if (!hasInterface) exitWith {};
    if (missionNamespace getVariable ["Waldo_MG_ClientLoopStarted", false]) exitWith {};
    missionNamespace setVariable ["Waldo_MG_ClientLoopStarted", true];
    [] spawn {
        private _nextDiscovery = 0;
        while {true} do {
            if (diag_tickTime >= _nextDiscovery) then {
                call Waldo_MG_fnc_discoverTaggedTablesLocal;
                _nextDiscovery = diag_tickTime + Waldo_MG_CFG_DISCOVERY_TICK;
            };
            call Waldo_MG_fnc_ensureTableActionsLocal;
            call Waldo_MG_fnc_ensurePlayerActionsLocal;
            call Waldo_MG_fnc_maintainSeatStateLocal;
            call Waldo_MG_fnc_maintainGameTransitionLocal;
            call Waldo_MG_fnc_maintainSpectatorStateLocal;
            call Waldo_MG_fnc_maintainSeatedScreenLocal;
            call Waldo_MG_fnc_showRequestResultLocal;
            uiSleep Waldo_MG_CFG_CLIENT_TICK;
        };
    };
}; 
 

Waldo_MG_fnc_bootstrap = {
    if (isServer) then {
        call Waldo_MG_fnc_initializeServerState;
        private _host = missionNamespace getVariable ["Waldo_MG_CompositionHostObject", objNull];
        if (!isNull _host) then {
            [_host, "Composition", "COMPOSITION"] call Waldo_MG_fnc_markTableServer;
        };
        {
            [_x] call Waldo_MG_fnc_initializePlayerServer;
        } forEach allPlayers;
        call Waldo_MG_fnc_reconcileRegistriesServer;
        call Waldo_MG_fnc_startAuthorityLoop;
    };
    if (hasInterface) then {
        call Waldo_MG_fnc_discoverTaggedTablesLocal;
        call Waldo_MG_fnc_startClientLoop;
    };
    missionNamespace setVariable ["Waldo_MG_SystemInitialized", true];
};

