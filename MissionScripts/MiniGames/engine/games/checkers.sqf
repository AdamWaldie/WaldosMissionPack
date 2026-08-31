/*
 * Author: WaldoTheWarfighter
 * Waldos Mini Games - Checkers
 * All Waldo_MG_fnc_* functions implementing the Checkers mini game (server logic + local UI).
 *
 * Original engine: "Party Games Scripted" by |LorD|[Habilidade]Deus Ex.
 * Ported into WaldosMissionPack and rebranded to the Waldo_MG_ namespace; game
 * logic is maintained as part of the WMP party-game framework.
 *
 * This file is an engine fragment: it defines a group of Waldo_MG_fnc_* runtime
 * functions and is #included lazily by Waldo_fnc_MiniGamesEnsureRuntime.
 * It is not a standalone CfgFunctions entry and is not called directly.
 * Locality/authority: Server rule helpers and interface presentation helpers execute only in their
 * matching lazily compiled role; headless clients do not compile this fragment.
 * Repeat/JIP: The versioned role runtime compiles it once per machine. Named state requests provide
 * JIP replay without transmitting executable code.
 * Arguments: None; include fragment.
 * Return Value: Nothing; defines runtime values/functions.
 * Current callers: Waldo_fnc_MiniGamesEnsureRuntime during first explicit table registration.
 * Example: [this] call Waldo_fnc_MiniGamesRegisterTable;
 */

Waldo_MG_fnc_checkersNormalizeBoard = {
    params [["_source", []]];
    if ((typeName _source) != "ARRAY") then {
        _source = [];
    };
    private _board = [];
    _board resize 64;
    for "_index" from 0 to 63 do {
        private _piece = _source param [_index, 0];
        if ((typeName _piece) != "SCALAR" || {!(_piece in [-2, -1, 0, 1, 2])}) then {
            _piece = 0;
        };
        _board set [_index, _piece];
    };
    _board
};

Waldo_MG_fnc_checkersCreateBoard = {
    private _board = [];
    _board resize 64;
    for "_index" from 0 to 63 do {
        _board set [_index, 0];
    };
    for "_row" from 0 to 7 do {
        for "_column" from 0 to 7 do {
            if (((_row + _column) mod 2) == 1) then {
                private _index = (_row * 8) + _column;
                if (_row <= 2) then {
                    _board set [_index, -1];
                };
                if (_row >= 5) then {
                    _board set [_index, 1];
                };
            };
        };
    };
    _board
};

Waldo_MG_fnc_checkersPieceSide = {
    params [["_piece", 0]];
    if (_piece > 0) exitWith {1};
    if (_piece < 0) exitWith {-1};
    0
};

Waldo_MG_fnc_checkersSideName = {
    params [["_side", 0]];
    if (_side > 0) exitWith {"NATO Blue"};
    if (_side < 0) exitWith {"OPFOR Red"};
    "Neither side"
};

Waldo_MG_fnc_checkersGetDirections = {
    params [["_piece", 0]];
    if ((abs _piece) == 2) exitWith {
        [[-1, -1], [-1, 1], [1, -1], [1, 1]]
    };
    if (_piece > 0) exitWith {
        [[-1, -1], [-1, 1]]
    };
    if (_piece < 0) exitWith {
        [[1, -1], [1, 1]]
    };
    []
};

Waldo_MG_fnc_checkersGetCaptureMoves = {
    params [
        ["_source", []],
        ["_from", -1]
    ];
    if (_from < 0 || {_from > 63}) exitWith {[]};
    private _board = [_source] call Waldo_MG_fnc_checkersNormalizeBoard;
    private _piece = _board param [_from, 0];
    private _side = [_piece] call Waldo_MG_fnc_checkersPieceSide;
    if (_side == 0) exitWith {[]};
    private _row = floor (_from / 8);
    private _column = _from mod 8;
    private _moves = [];
    {
        private _rowDirection = _x param [0, 0];
        private _columnDirection = _x param [1, 0];
        private _middleRow = _row + _rowDirection;
        private _middleColumn = _column + _columnDirection;
        private _landingRow = _row + (2 * _rowDirection);
        private _landingColumn = _column + (2 * _columnDirection);
        if (
            _landingRow >= 0 && {_landingRow <= 7}
            && {_landingColumn >= 0} && {_landingColumn <= 7}
            && {_middleRow >= 0} && {_middleRow <= 7}
            && {_middleColumn >= 0} && {_middleColumn <= 7}
        ) then {
            private _middleIndex = (_middleRow * 8) + _middleColumn;
            private _landingIndex = (_landingRow * 8) + _landingColumn;
            private _middlePiece = _board param [_middleIndex, 0];
            if (
                ([_middlePiece] call Waldo_MG_fnc_checkersPieceSide) == (-_side)
                && {(_board param [_landingIndex, 0]) == 0}
            ) then {
                _moves pushBack [_landingIndex, _middleIndex];
            };
        };
    } forEach ([_piece] call Waldo_MG_fnc_checkersGetDirections);
    _moves
};

Waldo_MG_fnc_checkersGetStepMoves = {
    params [
        ["_source", []],
        ["_from", -1]
    ];
    if (_from < 0 || {_from > 63}) exitWith {[]};
    private _board = [_source] call Waldo_MG_fnc_checkersNormalizeBoard;
    private _piece = _board param [_from, 0];
    if (_piece == 0) exitWith {[]};
    private _row = floor (_from / 8);
    private _column = _from mod 8;
    private _moves = [];
    {
        private _landingRow = _row + (_x param [0, 0]);
        private _landingColumn = _column + (_x param [1, 0]);
        if (
            _landingRow >= 0 && {_landingRow <= 7}
            && {_landingColumn >= 0} && {_landingColumn <= 7}
        ) then {
            private _landingIndex = (_landingRow * 8) + _landingColumn;
            if ((_board param [_landingIndex, 0]) == 0) then {
                _moves pushBack [_landingIndex, -1];
            };
        };
    } forEach ([_piece] call Waldo_MG_fnc_checkersGetDirections);
    _moves
};

Waldo_MG_fnc_checkersSideHasCapture = {
    params [
        ["_source", []],
        ["_side", 0]
    ];
    private _board = [_source] call Waldo_MG_fnc_checkersNormalizeBoard;
    private _found = false;
    for "_index" from 0 to 63 do {
        if (
            !_found
            && {([_board param [_index, 0]] call Waldo_MG_fnc_checkersPieceSide) == _side}
            && {(count ([_board, _index] call Waldo_MG_fnc_checkersGetCaptureMoves)) > 0}
        ) then {
            _found = true;
        };
    };
    _found
};

Waldo_MG_fnc_checkersGetLegalMoves = {
    params [
        ["_source", []],
        ["_side", 0],
        ["_from", -1],
        ["_forcedFrom", -1]
    ];
    if (_side == 0 || {_from < 0} || {_from > 63}) exitWith {[]};
    private _board = [_source] call Waldo_MG_fnc_checkersNormalizeBoard;
    if (([_board param [_from, 0]] call Waldo_MG_fnc_checkersPieceSide) != _side) exitWith {[]};
    if (_forcedFrom >= 0 && {_from != _forcedFrom}) exitWith {[]};
    private _captures = [_board, _from] call Waldo_MG_fnc_checkersGetCaptureMoves;
    if (_forcedFrom >= 0 || {[_board, _side] call Waldo_MG_fnc_checkersSideHasCapture}) exitWith {
        _captures
    };
    [_board, _from] call Waldo_MG_fnc_checkersGetStepMoves
};

Waldo_MG_fnc_checkersSideHasLegalMove = {
    params [
        ["_source", []],
        ["_side", 0]
    ];
    private _board = [_source] call Waldo_MG_fnc_checkersNormalizeBoard;
    private _found = false;
    for "_index" from 0 to 63 do {
        if (
            !_found
            && {([_board param [_index, 0]] call Waldo_MG_fnc_checkersPieceSide) == _side}
            && {(count ([_board, _side, _index, -1] call Waldo_MG_fnc_checkersGetLegalMoves)) > 0}
        ) then {
            _found = true;
        };
    };
    _found
};

Waldo_MG_fnc_checkersCountSidePieces = {
    params [
        ["_source", []],
        ["_side", 0]
    ];
    private _board = [_source] call Waldo_MG_fnc_checkersNormalizeBoard;
    private _count = 0;
    {
        if (([_x] call Waldo_MG_fnc_checkersPieceSide) == _side) then {
            _count = _count + 1;
        };
    } forEach _board;
    _count
}; 
 

Waldo_MG_fnc_checkersPublishRevisionServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    _table setVariable [
        "Waldo_MG_CheckersRevision",
        (_table getVariable ["Waldo_MG_CheckersRevision", 0]) + 1,
        true
    ];
    _table setVariable [
        "Waldo_MG_TableRevision",
        (_table getVariable ["Waldo_MG_TableRevision", 0]) + 1,
        true
    ];
};

Waldo_MG_fnc_checkersClearServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    _table setVariable ["Waldo_MG_CheckersActive", false, true];
    _table setVariable ["Waldo_MG_CheckersGameId", "", true];
    _table setVariable ["Waldo_MG_CheckersPlayers", [objNull, objNull], true];
    _table setVariable ["Waldo_MG_CheckersPlayerNames", ["NATO Blue", "OPFOR Red"], true];
    _table setVariable ["Waldo_MG_CheckersSeatIndices", [-1, -1], true];
    _table setVariable ["Waldo_MG_CheckersBoard", [], true];
    _table setVariable ["Waldo_MG_CheckersTurn", 1, true];
    _table setVariable ["Waldo_MG_CheckersForcedFrom", -1, true];
    _table setVariable ["Waldo_MG_CheckersWinner", 0, true];
    _table setVariable ["Waldo_MG_CheckersMoveNumber", 0, true];
    _table setVariable ["Waldo_MG_CheckersLastMove", [], true];
    _table setVariable ["Waldo_MG_CheckersStatus", "Waiting for a Checkers match.", true];
    [_table] call Waldo_MG_fnc_checkersPublishRevisionServer;
};

Waldo_MG_fnc_checkersStartServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {false};
    if ([_table] call Waldo_MG_fnc_isTableGameActive) exitWith {false};
    if ((_table getVariable ["Waldo_MG_TableSelectedGame", ""]) != "checkers") exitWith {false};
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
    if ((count _players) != 2) exitWith {false};
    private _blue = _players param [0, objNull];
    private _red = _players param [1, objNull];
    if (isNull _blue || {isNull _red}) exitWith {false};
    _table setVariable ["Waldo_MG_CheckersActive", true, true];
    _table setVariable [
        "Waldo_MG_CheckersGameId",
        format ["Waldo_MG_CHECKERS_%1_%2", floor (serverTime * 10), floor (random 1000000)],
        true
    ];
    _table setVariable ["Waldo_MG_CheckersPlayers", [_blue, _red], true];
    _table setVariable ["Waldo_MG_CheckersPlayerNames", [name _blue, name _red], true];
    _table setVariable ["Waldo_MG_CheckersSeatIndices", _seatIndices, true];
    _table setVariable ["Waldo_MG_CheckersBoard", call Waldo_MG_fnc_checkersCreateBoard, true];
    _table setVariable ["Waldo_MG_CheckersTurn", 1, true];
    _table setVariable ["Waldo_MG_CheckersForcedFrom", -1, true];
    _table setVariable ["Waldo_MG_CheckersWinner", 0, true];
    _table setVariable ["Waldo_MG_CheckersMoveNumber", 0, true];
    _table setVariable ["Waldo_MG_CheckersLastMove", [], true];
    _table setVariable ["Waldo_MG_CheckersStatus", format ["%1 has the first move as NATO Blue.", name _blue], true];
    _table setVariable ["Waldo_MG_TablePhase", "PLAYING", true];
    [_table] call Waldo_MG_fnc_checkersPublishRevisionServer;
    true
};

Waldo_MG_fnc_checkersFinishForfeitServer = {
    params [
        ["_table", objNull],
        ["_departingUnit", objNull],
        ["_departingSeat", -1]
    ];
    if (!isServer || {isNull _table}) exitWith {};
    if (!(_table getVariable ["Waldo_MG_CheckersActive", false])) exitWith {};
    if ((_table getVariable ["Waldo_MG_CheckersWinner", 0]) != 0) exitWith {};
    private _players = _table getVariable ["Waldo_MG_CheckersPlayers", [objNull, objNull]];
    private _seatIndices = _table getVariable ["Waldo_MG_CheckersSeatIndices", [-1, -1]];
    private _names = _table getVariable ["Waldo_MG_CheckersPlayerNames", ["NATO Blue", "OPFOR Red"]];
    private _roleIndex = -1;
    if (!isNull _departingUnit) then {
        _roleIndex = _players find _departingUnit;
    };
    if (_roleIndex < 0 && {_departingSeat >= 0}) then {
        _roleIndex = _seatIndices find _departingSeat;
    };
    if (_roleIndex < 0) exitWith {};
    private _losingSide = if (_roleIndex == 0) then {1} else {-1};
    private _winner = -_losingSide;
    private _winnerName = _names param [if (_winner > 0) then {0} else {1}, "Opponent"];
    private _loserName = _names param [_roleIndex, "Opponent"];
    _table setVariable ["Waldo_MG_CheckersWinner", _winner, true];
    _table setVariable ["Waldo_MG_CheckersForcedFrom", -1, true];
    _table setVariable ["Waldo_MG_CheckersStatus", format ["%1 wins by forfeit after %2 left the table.", _winnerName, _loserName], true];
    _table setVariable ["Waldo_MG_TablePhase", "FINISHED", true];
    [_table] call Waldo_MG_fnc_checkersPublishRevisionServer;
};

Waldo_MG_fnc_checkersReconcilePlayersServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    if (!(_table getVariable ["Waldo_MG_CheckersActive", false])) exitWith {};
    private _seats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
    private _players = _table getVariable ["Waldo_MG_CheckersPlayers", [objNull, objNull]];
    private _seatIndices = _table getVariable ["Waldo_MG_CheckersSeatIndices", [-1, -1]];
    private _valid = [false, false];
    for "_role" from 0 to 1 do {
        private _unit = _players param [_role, objNull];
        private _seatIndex = _seatIndices param [_role, -1];
        private _isValid = !isNull _unit
            && {_seatIndex >= 0}
            && {_seatIndex < Waldo_MG_CFG_SEAT_COUNT}
            && {(_seats param [_seatIndex, objNull]) == _unit}
            && {_unit in allPlayers}
            && {alive _unit}
            && {(lifeState _unit) != "INCAPACITATED"};
        _valid set [_role, _isValid];
    };
    if ((_table getVariable ["Waldo_MG_CheckersWinner", 0]) == 0) then {
        if (!(_valid param [0, false]) && {!(_valid param [1, false])}) then {
            [_table] call Waldo_MG_fnc_checkersClearServer;
            _table setVariable ["Waldo_MG_TableReady", [false, false, false, false], true];
            _table setVariable ["Waldo_MG_TablePhase", "LOBBY", true];
        } else {
            if (!(_valid param [0, false])) then {
                [_table, objNull, _seatIndices param [0, -1]] call Waldo_MG_fnc_checkersFinishForfeitServer;
            } else {
                if (!(_valid param [1, false])) then {
                    [_table, objNull, _seatIndices param [1, -1]] call Waldo_MG_fnc_checkersFinishForfeitServer;
                };
            };
        };
    } else {
        if (!(_valid param [0, false]) && {!(_valid param [1, false])}) then {
            [_table] call Waldo_MG_fnc_checkersClearServer;
            _table setVariable ["Waldo_MG_TableReady", [false, false, false, false], true];
            _table setVariable ["Waldo_MG_TablePhase", "LOBBY", true];
        };
    };
};

Waldo_MG_fnc_checkersResetServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    [_table] call Waldo_MG_fnc_checkersClearServer;
    _table setVariable ["Waldo_MG_TableReady", [false, false, false, false], true];
    [_table] call Waldo_MG_fnc_refreshTableConsensusServer;
};

Waldo_MG_fnc_processCheckersMoveRequestServer = {
    params [
        ["_unit", objNull],
        ["_request", []]
    ];
    if (!isServer || {isNull _unit}) exitWith {};
    if ((count _request) < 5) exitWith {};
    private _token = _request param [0, ""];
    if (!([_token] call Waldo_MG_fnc_rememberHandledTokenServer)) exitWith {};
    private _tableNetId = _request param [1, ""];
    private _from = _request param [2, -1];
    private _to = _request param [3, -1];
    private _expectedRevision = _request param [4, -1];
    if (
        (typeName _tableNetId) != "STRING"
        || {(typeName _from) != "SCALAR"}
        || {(typeName _to) != "SCALAR"}
        || {(typeName _expectedRevision) != "SCALAR"}
    ) exitWith {
        [_unit, _token, "Checkers move rejected: malformed request data."] call Waldo_MG_fnc_resultServer;
    };
    if (_from != (floor _from) || {_to != (floor _to)} || {_expectedRevision != (floor _expectedRevision)}) exitWith {
        [_unit, _token, "Checkers move rejected: board coordinates must be whole numbers."] call Waldo_MG_fnc_resultServer;
    };
    private _table = objectFromNetId _tableNetId;
    if (isNull _table || {_table != (_unit getVariable ["Waldo_MG_SeatedTable", objNull])}) exitWith {
        [_unit, _token, "Checkers move rejected: you are no longer seated at that table."] call Waldo_MG_fnc_resultServer;
    };
    if (!alive _unit || {(lifeState _unit) == "INCAPACITATED"}) exitWith {
        [_unit, _token, "Checkers move rejected: you cannot play in your current state."] call Waldo_MG_fnc_resultServer;
    };
    if (([_table] call Waldo_MG_fnc_getTableActiveGameId) != "checkers") exitWith {
        [_unit, _token, "That Checkers match is no longer active."] call Waldo_MG_fnc_resultServer;
    };
    if ((_table getVariable ["Waldo_MG_CheckersWinner", 0]) != 0) exitWith {
        [_unit, _token, "That Checkers match has already ended."] call Waldo_MG_fnc_resultServer;
    };
    private _players = _table getVariable ["Waldo_MG_CheckersPlayers", [objNull, objNull]];
    private _roleIndex = _players find _unit;
    if (_roleIndex < 0) exitWith {
        [_unit, _token, "Only the two assigned players may move pieces."] call Waldo_MG_fnc_resultServer;
    };
    private _side = if (_roleIndex == 0) then {1} else {-1};
    private _turn = _table getVariable ["Waldo_MG_CheckersTurn", 1];
    if (_side != _turn) exitWith {
        [_unit, _token, "It is the other player's turn."] call Waldo_MG_fnc_resultServer;
    };
    private _revision = _table getVariable ["Waldo_MG_CheckersRevision", 0];
    if (_expectedRevision != _revision) exitWith {
        [_unit, _token, "The board changed before that move arrived. Please select again."] call Waldo_MG_fnc_resultServer;
    };
    if (_from < 0 || {_from > 63} || {_to < 0} || {_to > 63}) exitWith {
        [_unit, _token, "Checkers move rejected: square outside the board."] call Waldo_MG_fnc_resultServer;
    };
    private _board = [(_table getVariable ["Waldo_MG_CheckersBoard", []])] call Waldo_MG_fnc_checkersNormalizeBoard;
    private _forcedFrom = _table getVariable ["Waldo_MG_CheckersForcedFrom", -1];
    private _legalMoves = [_board, _side, _from, _forcedFrom] call Waldo_MG_fnc_checkersGetLegalMoves;
    private _capturedIndex = -2;
    {
        if ((_x param [0, -1]) == _to) exitWith {
            _capturedIndex = _x param [1, -1];
        };
    } forEach _legalMoves;
    if (_capturedIndex == -2) exitWith {
        private _reason = if ([_board, _side] call Waldo_MG_fnc_checkersSideHasCapture) then {
            "A capture is available and must be taken."
        } else {
            "That is not a legal diagonal move."
        };
        [_unit, _token, _reason] call Waldo_MG_fnc_resultServer;
    };

    private _piece = _board param [_from, 0];
    _board set [_from, 0];
    if (_capturedIndex >= 0) then {
        _board set [_capturedIndex, 0];
    };
    private _landingRow = floor (_to / 8);
    private _promoted = false;
    if ((abs _piece) == 1) then {
        if ((_side > 0 && {_landingRow == 0}) || {_side < 0 && {_landingRow == 7}}) then {
            _piece = 2 * _side;
            _promoted = true;
        };
    };
    _board set [_to, _piece];

    private _continueCapture = false;
    if (_capturedIndex >= 0 && {!_promoted}) then {
        _continueCapture = (count ([_board, _to] call Waldo_MG_fnc_checkersGetCaptureMoves)) > 0;
    };
    private _winner = 0;
    private _status = "";
    if (_continueCapture) then {
        _forcedFrom = _to;
        _status = format ["%1 must continue the capture chain with the selected piece.", name _unit];
    } else {
        _forcedFrom = -1;
        _turn = -_side;
        private _opponentPieces = [_board, _turn] call Waldo_MG_fnc_checkersCountSidePieces;
        if (_opponentPieces == 0 || {!([_board, _turn] call Waldo_MG_fnc_checkersSideHasLegalMove)}) then {
            _winner = _side;
            _status = format ["%1 wins for %2.", name _unit, [_side] call Waldo_MG_fnc_checkersSideName];
        } else {
            private _names = _table getVariable ["Waldo_MG_CheckersPlayerNames", ["NATO Blue", "OPFOR Red"]];
            private _nextName = _names param [if (_turn > 0) then {0} else {1}, "Opponent"];
            _status = format ["%1 to move as %2.", _nextName, [_turn] call Waldo_MG_fnc_checkersSideName];
            if (_promoted) then {
                _status = format ["King crowned. %1", _status];
            };
        };
    };

    _table setVariable ["Waldo_MG_CheckersBoard", _board, true];
    _table setVariable ["Waldo_MG_CheckersTurn", _turn, true];
    _table setVariable ["Waldo_MG_CheckersForcedFrom", _forcedFrom, true];
    _table setVariable ["Waldo_MG_CheckersWinner", _winner, true];
    _table setVariable ["Waldo_MG_CheckersMoveNumber", (_table getVariable ["Waldo_MG_CheckersMoveNumber", 0]) + 1, true];
    _table setVariable ["Waldo_MG_CheckersLastMove", [_from, _to, _capturedIndex, _promoted], true];
    _table setVariable ["Waldo_MG_CheckersStatus", _status, true];
    if (_winner != 0) then {
        _table setVariable ["Waldo_MG_TablePhase", "FINISHED", true];
    };
    [_table] call Waldo_MG_fnc_checkersPublishRevisionServer;
    [_unit, _token, if (_continueCapture) then {
        "Capture accepted. Continue jumping with the same piece."
    } else {
        if (_winner != 0) then {"Move accepted. You won the Checkers match."} else {"Move accepted."}
    }] call Waldo_MG_fnc_resultServer;
};

Waldo_MG_fnc_processCheckersResetRequestServer = {
    params [
        ["_unit", objNull],
        ["_request", []]
    ];
    if (!isServer || {isNull _unit}) exitWith {};
    if ((count _request) < 2) exitWith {};
    private _token = _request param [0, ""];
    if (!([_token] call Waldo_MG_fnc_rememberHandledTokenServer)) exitWith {};
    private _tableNetId = _request param [1, ""];
    if ((typeName _tableNetId) != "STRING") exitWith {
        [_unit, _token, "Reset rejected: malformed table data."] call Waldo_MG_fnc_resultServer;
    };
    private _table = objectFromNetId _tableNetId;
    if (isNull _table || {_table != (_unit getVariable ["Waldo_MG_SeatedTable", objNull])}) exitWith {
        [_unit, _token, "Reset rejected: you are no longer seated at that table."] call Waldo_MG_fnc_resultServer;
    };
    if (!(_table getVariable ["Waldo_MG_CheckersActive", false]) || {(_table getVariable ["Waldo_MG_CheckersWinner", 0]) == 0}) exitWith {
        [_unit, _token, "The Checkers match must be finished before returning the table to its lobby."] call Waldo_MG_fnc_resultServer;
    };
    [_table] call Waldo_MG_fnc_checkersResetServer;
    [_unit, _token, "Checkers cleared. The table has returned to its lobby."] call Waldo_MG_fnc_resultServer;
};

Waldo_MG_fnc_submitCheckersMoveRequestLocal = {
    params [
        ["_table", objNull],
        ["_from", -1],
        ["_to", -1],
        ["_revision", -1]
    ];
    if (!hasInterface || {isNull player} || {isNull _table}) exitWith {};
    private _token = ["CHECKERS_MOVE"] call Waldo_MG_fnc_makeToken;
    ["CHECKERS_MOVE", _table, _token, _revision, [_token, netId _table, _from, _to, _revision]] call Waldo_MG_fnc_submitRequestLocal;
};

Waldo_MG_fnc_submitCheckersResetRequestLocal = {
    params [["_table", objNull]];
    if (!hasInterface || {isNull player} || {isNull _table}) exitWith {};
    private _token = ["CHECKERS_RESET"] call Waldo_MG_fnc_makeToken;
    ["CHECKERS_RESET", _table, _token, _table getVariable ["Waldo_MG_CheckersRevision", -1], [_token, netId _table]] call Waldo_MG_fnc_submitRequestLocal;
    ["Returning the finished Checkers match to the lobby..."] call Waldo_MG_fnc_notifyLocal;
};

Waldo_MG_fnc_getCheckersPlayerSideLocal = {
    params [["_table", objNull]];
    if (isNull _table || {isNull player}) exitWith {0};
    private _players = _table getVariable ["Waldo_MG_CheckersPlayers", [objNull, objNull]];
    private _roleIndex = _players find player;
    if (_roleIndex == 0) exitWith {1};
    if (_roleIndex == 1) exitWith {-1};
    0
};

Waldo_MG_fnc_handleCheckersSquareClickLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    if (isNull _display) exitWith {};
    private _table = _display getVariable ["Waldo_MG_CheckersTable", objNull];
    private _index = _control getVariable ["Waldo_MG_CheckersSquareIndex", -1];
    if (isNull _table || {_index < 0} || {_index > 63}) exitWith {};
    if (([_table] call Waldo_MG_fnc_getTableActiveGameId) != "checkers") exitWith {
        ["That Checkers match is no longer active."] call Waldo_MG_fnc_notifyLocal;
    };
    if ((_table getVariable ["Waldo_MG_CheckersWinner", 0]) != 0) exitWith {
        ["The match is finished. Reset it to return to the lobby."] call Waldo_MG_fnc_notifyLocal;
    };
    private _side = [_table] call Waldo_MG_fnc_getCheckersPlayerSideLocal;
    if (_side == 0) exitWith {
        ["Only the two assigned players may move these pieces."] call Waldo_MG_fnc_notifyLocal;
    };
    if ((_table getVariable ["Waldo_MG_CheckersTurn", 1]) != _side) exitWith {
        ["It is the other player's turn."] call Waldo_MG_fnc_notifyLocal;
    };
    if (_display getVariable ["Waldo_MG_CheckersMovePending", false]) exitWith {
        ["Waiting for the table host to confirm your move..."] call Waldo_MG_fnc_notifyLocal;
    };
    private _revision = _table getVariable ["Waldo_MG_CheckersRevision", 0];
    private _board = [(_table getVariable ["Waldo_MG_CheckersBoard", []])] call Waldo_MG_fnc_checkersNormalizeBoard;
    private _forcedFrom = _table getVariable ["Waldo_MG_CheckersForcedFrom", -1];
    private _selected = _display getVariable ["Waldo_MG_CheckersSelectedFrom", -1];
    private _pieceSide = [_board param [_index, 0]] call Waldo_MG_fnc_checkersPieceSide;

    if (_pieceSide == _side) exitWith {
        if (_forcedFrom >= 0 && {_index != _forcedFrom}) then {
            ["Continue the capture chain with the highlighted piece."] call Waldo_MG_fnc_notifyLocal;
        } else {
            private _moves = [_board, _side, _index, _forcedFrom] call Waldo_MG_fnc_checkersGetLegalMoves;
            if ((count _moves) <= 0) then {
                if ([_board, _side] call Waldo_MG_fnc_checkersSideHasCapture) then {
                    ["Another piece has a compulsory capture."] call Waldo_MG_fnc_notifyLocal;
                } else {
                    ["That piece has no legal move."] call Waldo_MG_fnc_notifyLocal;
                };
            } else {
                _display setVariable ["Waldo_MG_CheckersSelectedFrom", _index];
                [_display] call Waldo_MG_fnc_refreshCheckersLocal;
            };
        };
    };

    if (_selected < 0) exitWith {
        ["Select one of your pieces first."] call Waldo_MG_fnc_notifyLocal;
    };
    private _legalMoves = [_board, _side, _selected, _forcedFrom] call Waldo_MG_fnc_checkersGetLegalMoves;
    private _isLegal = false;
    {
        if ((_x param [0, -1]) == _index) exitWith {
            _isLegal = true;
        };
    } forEach _legalMoves;
    if (!_isLegal) exitWith {
        ["Choose one of the highlighted destination squares."] call Waldo_MG_fnc_notifyLocal;
    };
    _display setVariable ["Waldo_MG_CheckersMovePending", true];
    _display setVariable ["Waldo_MG_CheckersSelectedFrom", -1];
    [_table, _selected, _index, _revision] call Waldo_MG_fnc_submitCheckersMoveRequestLocal;
};

Waldo_MG_fnc_refreshCheckersLocal = {
    disableSerialization;
    params [["_display", displayNull]];
    if (isNull _display) exitWith {};
    if (_display getVariable ["Waldo_MG_CheckersRefreshing", false]) exitWith {};
    _display setVariable ["Waldo_MG_CheckersRefreshing", true];
    private _table = _display getVariable ["Waldo_MG_CheckersTable", objNull];
    private _spectating = _display getVariable ["Waldo_MG_SpectatorMode", false];
    if (!([_table, _spectating] call Waldo_MG_fnc_isValidGameViewerLocal)) exitWith {
        _display closeDisplay 1;
    };
    if (([_table] call Waldo_MG_fnc_getTableActiveGameId) != "checkers") exitWith {
        if (_spectating) then {
            [true] call Waldo_MG_fnc_exitSpectatorLocal;
        } else {
            _display closeDisplay 1;
            [_table] spawn {
                params ["_lobbyTable"];
                uiSleep 0.1;
                if (!isNull _lobbyTable && {(_lobbyTable == (player getVariable ["Waldo_MG_SeatedTable", objNull]))}) then {
                    [_lobbyTable] call Waldo_MG_fnc_openLobbyLocal;
                };
            };
        };
    };

    private _side = [_table] call Waldo_MG_fnc_getCheckersPlayerSideLocal;
    private _board = [(_table getVariable ["Waldo_MG_CheckersBoard", []])] call Waldo_MG_fnc_checkersNormalizeBoard;
    private _turn = _table getVariable ["Waldo_MG_CheckersTurn", 1];
    private _forcedFrom = _table getVariable ["Waldo_MG_CheckersForcedFrom", -1];
    private _winner = _table getVariable ["Waldo_MG_CheckersWinner", 0];
    private _revision = _table getVariable ["Waldo_MG_CheckersRevision", 0];
    private _lastRevision = _display getVariable ["Waldo_MG_CheckersLastRevision", -1];
    private _selected = _display getVariable ["Waldo_MG_CheckersSelectedFrom", -1];
    if (_revision != _lastRevision) then {
        _display setVariable ["Waldo_MG_CheckersMovePending", false];
        if (_forcedFrom >= 0 && {_turn == _side}) then {
            _selected = _forcedFrom;
        } else {
            if (_selected >= 0 && {([_board param [_selected, 0]] call Waldo_MG_fnc_checkersPieceSide) != _side}) then {
                _selected = -1;
            };
        };
        _display setVariable ["Waldo_MG_CheckersSelectedFrom", _selected];
        private _captureSources = [];
        if (_winner == 0) then {
            if (_forcedFrom >= 0) then {
                if ((count ([_board, _forcedFrom] call Waldo_MG_fnc_checkersGetCaptureMoves)) > 0) then {
                    _captureSources pushBack _forcedFrom;
                };
            } else {
                for "_index" from 0 to 63 do {
                    if (
                        ([_board param [_index, 0]] call Waldo_MG_fnc_checkersPieceSide) == _turn
                        && {(count ([_board, _index] call Waldo_MG_fnc_checkersGetCaptureMoves)) > 0}
                    ) then {
                        _captureSources pushBack _index;
                    };
                };
            };
        };
        _display setVariable ["Waldo_MG_CheckersCaptureSources", _captureSources];
        _display setVariable ["Waldo_MG_CheckersLastRevision", _revision];
    };
    private _legalMoves = if (_selected >= 0 && {_turn == _side} && {_winner == 0}) then {
        [_board, _side, _selected, _forcedFrom] call Waldo_MG_fnc_checkersGetLegalMoves
    } else {
        []
    };
    private _legalDestinations = [];
    {
        _legalDestinations pushBack (_x param [0, -1]);
    } forEach _legalMoves;
    private _captureSources = _display getVariable ["Waldo_MG_CheckersCaptureSources", []];
    private _lastMove = _table getVariable ["Waldo_MG_CheckersLastMove", []];
    private _lastFrom = _lastMove param [0, -1];
    private _lastTo = _lastMove param [1, -1];
    private _controls = _display getVariable ["Waldo_MG_CheckersSquareControls", []];
    {
        private _control = _x;
        if (!isNull _control) then {
            private _index = _control getVariable ["Waldo_MG_CheckersSquareIndex", -1];
            private _row = floor (_index / 8);
            private _column = _index mod 8;
            private _dark = ((_row + _column) mod 2) == 1;
            private _background = if (_dark) then {
                [0.075, 0.085, 0.105, 1]
            } else {
                [0.78, 0.79, 0.74, 1]
            };
            if (_index == _lastFrom || {_index == _lastTo}) then {
                _background = [0.22, 0.32, 0.40, 1];
            };
            if (_index in _captureSources) then {
                _background = [0.68, 0.34, 0.06, 1];
            };
            if (_index == _selected) then {
                _background = [0.88, 0.63, 0.12, 1];
            };
            if (_index in _legalDestinations) then {
                _background = [0.16, 0.58, 0.30, 1];
            };
            _control ctrlSetBackgroundColor _background;
            private _piece = _board param [_index, 0];
            private _pieceText = "";
            if (_piece != 0) then {
                _pieceText = if ((abs _piece) == 2) then {"O+"} else {"O"};
            };
            _control ctrlSetText _pieceText;
            _control ctrlSetTextColor (if (_piece > 0) then {
                [0.18, 0.58, 1, 1]
            } else {
                if (_piece < 0) then {[1, 0.20, 0.16, 1]} else {[1, 1, 1, 1]}
            });
            _control ctrlSetTooltip (if (_piece == 0) then {
                if (_index in _legalDestinations) then {"Legal destination"} else {"Empty square"}
            } else {
                if (_index in _captureSources) then {
                    "Compulsory capture available - select this piece"
                } else {
                    format [
                        "%1 %2",
                        [[_piece] call Waldo_MG_fnc_checkersPieceSide] call Waldo_MG_fnc_checkersSideName,
                        if ((abs _piece) == 2) then {"king (+)"} else {"piece"}
                    ]
                }
            });
            _control ctrlCommit 0;
        };
    } forEach _controls;

    private _names = _table getVariable ["Waldo_MG_CheckersPlayerNames", ["NATO Blue", "OPFOR Red"]];
    private _blueName = _names param [0, "NATO Blue"];
    private _redName = _names param [1, "OPFOR Red"];
    private _blueCount = [_board, 1] call Waldo_MG_fnc_checkersCountSidePieces;
    private _redCount = [_board, -1] call Waldo_MG_fnc_checkersCountSidePieces;
    private _blueLabel = _display getVariable ["Waldo_MG_CheckersBlueLabel", controlNull];
    private _redLabel = _display getVariable ["Waldo_MG_CheckersRedLabel", controlNull];
    private _turnLabel = _display getVariable ["Waldo_MG_CheckersTurnLabel", controlNull];
    private _statusOne = _display getVariable ["Waldo_MG_CheckersStatusOne", controlNull];
    private _statusTwo = _display getVariable ["Waldo_MG_CheckersStatusTwo", controlNull];
    private _resetButton = _display getVariable ["Waldo_MG_CheckersResetButton", controlNull];
    if (!isNull _blueLabel) then {
        _blueLabel ctrlSetText format ["NATO BLUE  %1", _blueName];
        _blueLabel ctrlCommit 0;
    };
    if (!isNull _redLabel) then {
        _redLabel ctrlSetText format ["OPFOR RED  %1", _redName];
        _redLabel ctrlCommit 0;
    };
    if (!isNull _turnLabel) then {
        _turnLabel ctrlSetText (if (_winner == 0) then {
            format ["TURN: %1", [_turn] call Waldo_MG_fnc_checkersSideName]
        } else {
            format ["WINNER: %1", [_winner] call Waldo_MG_fnc_checkersSideName]
        });
        _turnLabel ctrlSetTextColor (if (_winner != 0) then {
            [0.98, 0.80, 0.22, 1]
        } else {
            if (_turn > 0) then {[0.22, 0.66, 1, 1]} else {[1, 0.28, 0.22, 1]}
        });
        _turnLabel ctrlCommit 0;
    };
    if (!isNull _statusOne) then {
        _statusOne ctrlSetText (_table getVariable ["Waldo_MG_CheckersStatus", "Checkers in progress."]);
        _statusOne ctrlCommit 0;
    };
    if (!isNull _statusTwo) then {
        private _yourRole = if (_side == 0) then {"Observer"} else {[_side] call Waldo_MG_fnc_checkersSideName};
        private _forcedText = if (_forcedFrom >= 0 && {_winner == 0}) then {
            "  CHAINED CAPTURE REQUIRED"
        } else {
            if ((count _captureSources) > 0 && {_winner == 0}) then {"  COMPULSORY CAPTURE AVAILABLE"} else {""}
        };
        _statusTwo ctrlSetText format ["You: %1   Pieces: Blue %2 / Red %3%4", _yourRole, _blueCount, _redCount, _forcedText];
        _statusTwo ctrlCommit 0;
    };
    if (!isNull _resetButton) then {
        _resetButton ctrlShow !_spectating;
        _resetButton ctrlEnable (!_spectating && {_winner != 0});
        _resetButton ctrlSetText (if (_winner != 0) then {"Reset to Lobby"} else {"Finish Match First"});
        _resetButton ctrlCommit 0;
    };
    _display setVariable ["Waldo_MG_CheckersRefreshing", false];
};

Waldo_MG_fnc_openCheckersLocal = {
    disableSerialization;
    params [
        ["_table", objNull],
        ["_spectating", false]
    ];
    if (!hasInterface || {isNull player}) exitWith {};
    if (
        isNull _table
        || {!([_table, _spectating] call Waldo_MG_fnc_isValidGameViewerLocal)}
        || {([_table] call Waldo_MG_fnc_getTableActiveGameId) != "checkers"}
    ) exitWith {
        ["No active Checkers match is available to this viewer."] call Waldo_MG_fnc_notifyLocal;
    };
    private _parent = findDisplay 46;
    if (isNull _parent) exitWith {
        ["The Checkers display is unavailable."] call Waldo_MG_fnc_notifyLocal;
    };
    private _lobby = uiNamespace getVariable ["Waldo_MG_LobbyDisplay", displayNull];
    if (!isNull _lobby) then {
        _lobby closeDisplay 1;
    };
    private _existing = uiNamespace getVariable ["Waldo_MG_CheckersDisplay", displayNull];
    if (!isNull _existing) then {
        _existing closeDisplay 1;
    };
    private _battleship = uiNamespace getVariable ["Waldo_MG_BattleshipDisplay", displayNull];
    if (!isNull _battleship) then {_battleship closeDisplay 1;};
    private _whosWho = uiNamespace getVariable ["Waldo_MG_WhosWhoDisplay", displayNull];
    if (!isNull _whosWho) then {_whosWho closeDisplay 1;};
    private _shotgun = uiNamespace getVariable ["Waldo_MG_ShotgunDisplay", displayNull];
    if (!isNull _shotgun) then {_shotgun closeDisplay 1;};
    private _rps = uiNamespace getVariable ["Waldo_MG_RPSDisplay", displayNull];
    if (!isNull _rps) then {_rps closeDisplay 1;};
    private _blackjack = uiNamespace getVariable ["Waldo_MG_BlackjackDisplay", displayNull];
    if (!isNull _blackjack) then {_blackjack closeDisplay 1;};
    private _poker = uiNamespace getVariable ["Waldo_MG_PokerDisplay", displayNull];
    if (!isNull _poker) then {_poker closeDisplay 1;};
    private _uno = uiNamespace getVariable ["Waldo_MG_UNODisplay", displayNull];
    if (!isNull _uno) then {_uno closeDisplay 1;};
    private _display = _parent createDisplay "RscDisplayEmpty";
    if (isNull _display) exitWith {};
    uiNamespace setVariable ["Waldo_MG_CheckersDisplay", _display];
    _display setVariable ["Waldo_MG_CheckersTable", _table];
    _display setVariable ["Waldo_MG_SpectatorMode", _spectating];
    _display setVariable ["Waldo_MG_CheckersLastRevision", -1];
    _display setVariable ["Waldo_MG_CheckersSelectedFrom", -1];
    _display setVariable ["Waldo_MG_CheckersMovePending", false];
    [_display] call Waldo_MG_fnc_installEscapeGuardLocal;
    private _background = _display ctrlCreate ["RscText", -1];
    _background ctrlSetPosition [0.005, 0.015, 1.17, 1.055];
    _background ctrlSetBackgroundColor [0.010, 0.014, 0.022, 0.98];
    _background ctrlCommit 0;
    private _topBar = _display ctrlCreate ["RscText", -1];
    _topBar ctrlSetPosition [0.005, 0.015, 1.17, 0.075];
    _topBar ctrlSetBackgroundColor [0.055, 0.18, 0.30, 1];
    _topBar ctrlCommit 0;
    private _title = _display ctrlCreate ["RscText", -1];
    _title ctrlSetPosition [0.035, 0.026, 0.55, 0.052];
    _title ctrlSetText "PARTYGAMES  /  CHECKERS";
    _title ctrlSetTextColor [0.84, 0.94, 1, 1];
    _title ctrlSetFontHeight 0.038;
    _title ctrlCommit 0;
    private _subtitle = _display ctrlCreate ["RscText", -1];
    _subtitle ctrlSetPosition [0.64, 0.035, 0.49, 0.038];
    _subtitle ctrlSetText (if (_spectating) then {"SPECTATOR VIEW  /  Blue moves first"} else {"Blue moves first  /  O+ marks a king"});
    _subtitle ctrlSetTextColor [0.70, 0.84, 0.94, 1];
    _subtitle ctrlSetFontHeight 0.022;
    _subtitle ctrlCommit 0;

    private _boardFrame = _display ctrlCreate ["RscText", -1];
    _boardFrame ctrlSetPosition [0.030, 0.115, 0.836, 0.836];
    _boardFrame ctrlSetBackgroundColor [0.26, 0.28, 0.31, 1];
    _boardFrame ctrlCommit 0;
    private _side = [_table] call Waldo_MG_fnc_getCheckersPlayerSideLocal;
    private _squareControls = [];
    for "_visualRow" from 0 to 7 do {
        for "_visualColumn" from 0 to 7 do {
            private _logicalRow = if (_side < 0) then {7 - _visualRow} else {_visualRow};
            private _logicalColumn = if (_side < 0) then {7 - _visualColumn} else {_visualColumn};
            private _index = (_logicalRow * 8) + _logicalColumn;
            private _square = _display ctrlCreate ["RscButton", -1];
            _square ctrlSetPosition [
                0.034 + (_visualColumn * 0.1035),
                0.119 + (_visualRow * 0.1035),
                0.1015,
                0.1015
            ];
            _square ctrlSetFontHeight 0.072;
            _square ctrlSetTextColor [1, 1, 1, 1];
            _square setVariable ["Waldo_MG_CheckersSquareIndex", _index];
            _square ctrlAddEventHandler [
                "ButtonClick",
                {
                    params ["_control"];
                    [_control] call Waldo_MG_fnc_handleCheckersSquareClickLocal;
                }
            ];
            _square ctrlCommit 0;
            _squareControls pushBack _square;
        };
    };
    _display setVariable ["Waldo_MG_CheckersSquareControls", _squareControls];

    private _panel = _display ctrlCreate ["RscText", -1];
    _panel ctrlSetPosition [0.895, 0.115, 0.245, 0.836];
    _panel ctrlSetBackgroundColor [0.025, 0.040, 0.060, 0.98];
    _panel ctrlCommit 0;
    private _blueLabel = _display ctrlCreate ["RscText", -1];
    _blueLabel ctrlSetPosition [0.915, 0.145, 0.205, 0.052];
    _blueLabel ctrlSetTextColor [0.20, 0.62, 1, 1];
    _blueLabel ctrlSetFontHeight 0.023;
    _blueLabel ctrlCommit 0;
    private _versus = _display ctrlCreate ["RscText", -1];
    _versus ctrlSetPosition [0.915, 0.205, 0.205, 0.032];
    _versus ctrlSetText "VERSUS";
    _versus ctrlSetTextColor [0.62, 0.68, 0.74, 1];
    _versus ctrlSetFontHeight 0.018;
    _versus ctrlCommit 0;
    private _redLabel = _display ctrlCreate ["RscText", -1];
    _redLabel ctrlSetPosition [0.915, 0.245, 0.205, 0.052];
    _redLabel ctrlSetTextColor [1, 0.28, 0.22, 1];
    _redLabel ctrlSetFontHeight 0.023;
    _redLabel ctrlCommit 0;
    private _turnLabel = _display ctrlCreate ["RscText", -1];
    _turnLabel ctrlSetPosition [0.915, 0.335, 0.205, 0.060];
    _turnLabel ctrlSetFontHeight 0.027;
    _turnLabel ctrlCommit 0;
    private _rulesTitle = _display ctrlCreate ["RscText", -1];
    _rulesTitle ctrlSetPosition [0.915, 0.435, 0.205, 0.040];
    _rulesTitle ctrlSetText "FIELD RULES";
    _rulesTitle ctrlSetTextColor [0.80, 0.84, 0.88, 1];
    _rulesTitle ctrlSetFontHeight 0.021;
    _rulesTitle ctrlCommit 0;
    private _ruleOne = _display ctrlCreate ["RscText", -1];
    _ruleOne ctrlSetPosition [0.915, 0.485, 0.205, 0.038];
    _ruleOne ctrlSetText "Captures are compulsory.";
    _ruleOne ctrlSetTextColor [0.68, 0.74, 0.80, 1];
    _ruleOne ctrlSetFontHeight 0.018;
    _ruleOne ctrlCommit 0;
    private _ruleTwo = _display ctrlCreate ["RscText", -1];
    _ruleTwo ctrlSetPosition [0.915, 0.530, 0.205, 0.038];
    _ruleTwo ctrlSetText "Continue every chained jump.";
    _ruleTwo ctrlSetTextColor [0.68, 0.74, 0.80, 1];
    _ruleTwo ctrlSetFontHeight 0.018;
    _ruleTwo ctrlCommit 0;
    private _ruleThree = _display ctrlCreate ["RscText", -1];
    _ruleThree ctrlSetPosition [0.915, 0.575, 0.205, 0.038];
    _ruleThree ctrlSetText "Kings may move both ways.";
    _ruleThree ctrlSetTextColor [0.68, 0.74, 0.80, 1];
    _ruleThree ctrlSetFontHeight 0.018;
    _ruleThree ctrlCommit 0;
    private _ruleFour = _display ctrlCreate ["RscText", -1];
    _ruleFour ctrlSetPosition [0.915, 0.620, 0.205, 0.038];
    _ruleFour ctrlSetText (if (_spectating) then {"Read-only spectator board."} else {"Leave Table forfeits match."});
    _ruleFour ctrlSetTextColor [0.92, 0.63, 0.36, 1];
    _ruleFour ctrlSetFontHeight 0.018;
    _ruleFour ctrlCommit 0;

    private _statusBackground = _display ctrlCreate ["RscText", -1];
    _statusBackground ctrlSetPosition [0.030, 0.972, 1.110, 0.070];
    _statusBackground ctrlSetBackgroundColor [0.035, 0.055, 0.075, 1];
    _statusBackground ctrlCommit 0;
    private _statusOne = _display ctrlCreate ["RscText", -1];
    _statusOne ctrlSetPosition [0.050, 0.978, 0.70, 0.030];
    _statusOne ctrlSetTextColor [0.90, 0.94, 1, 1];
    _statusOne ctrlSetFontHeight 0.019;
    _statusOne ctrlCommit 0;
    private _statusTwo = _display ctrlCreate ["RscText", -1];
    _statusTwo ctrlSetPosition [0.050, 1.008, 0.70, 0.026];
    _statusTwo ctrlSetTextColor [0.62, 0.78, 0.90, 1];
    _statusTwo ctrlSetFontHeight 0.016;
    _statusTwo ctrlCommit 0;
    private _leaveButton = _display ctrlCreate ["RscButtonMenu", -1];
    _leaveButton ctrlSetPosition [0.815, 0.982, 0.180, 0.050];
    _leaveButton ctrlSetText (if (_spectating) then {"Exit Spectate"} else {"Leave Table"});
    _leaveButton ctrlCommit 0;
    private _resetButton = _display ctrlCreate ["RscButtonMenu", -1];
    _resetButton ctrlSetPosition [1.010, 0.982, 0.115, 0.050];
    _resetButton ctrlCommit 0;

    _display setVariable ["Waldo_MG_CheckersBlueLabel", _blueLabel];
    _display setVariable ["Waldo_MG_CheckersRedLabel", _redLabel];
    _display setVariable ["Waldo_MG_CheckersTurnLabel", _turnLabel];
    _display setVariable ["Waldo_MG_CheckersStatusOne", _statusOne];
    _display setVariable ["Waldo_MG_CheckersStatusTwo", _statusTwo];
    _display setVariable ["Waldo_MG_CheckersResetButton", _resetButton];
    _leaveButton ctrlAddEventHandler [
        "ButtonClick",
        {
            params ["_control"];
            [_control] call Waldo_MG_fnc_handleViewerExitButtonLocal;
        }
    ];
    _resetButton ctrlAddEventHandler [
        "ButtonClick",
        {
            params ["_control"];
            private _display = ctrlParent _control;
            private _table = _display getVariable ["Waldo_MG_CheckersTable", objNull];
            [_table] call Waldo_MG_fnc_submitCheckersResetRequestLocal;
        }
    ];
    [_display] call Waldo_MG_fnc_refreshCheckersLocal;
    [_display] spawn {
        disableSerialization;
        params ["_activeDisplay"];
        while {!isNull _activeDisplay} do {
            [_activeDisplay] call Waldo_MG_fnc_refreshCheckersLocal;
            uiSleep Waldo_MG_CFG_CHECKERS_UI_TICK;
        };
    };
}; 
 

