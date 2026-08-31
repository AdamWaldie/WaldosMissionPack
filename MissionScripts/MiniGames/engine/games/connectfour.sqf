/*
 * Author: WaldoTheWarfighter
 * Waldos Mini Games - Connect Four
 * Server-authoritative best-of-three board with mouse/keyboard controls and spectators.
 * This original WMP game is included lazily and is not a standalone CfgFunctions entry.
 * Locality/authority: Server rules are authoritative; controls and presentation are interface-local.
 * Repeat/JIP: Compiled once per role; public state and named requests restore permitted JIP state.
 * Arguments: None; include fragment.
 * Return Value: Nothing; defines runtime functions.
 * Current callers: Waldo_fnc_MiniGamesEnsureRuntime.
 * Example: [this] call Waldo_fnc_MiniGamesRegisterTable;
 */

Waldo_MG_fnc_connectFourPublishRevisionServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    _table setVariable ["Waldo_MG_ConnectFourRevision", (_table getVariable ["Waldo_MG_ConnectFourRevision", 0]) + 1, true];
    _table setVariable ["Waldo_MG_TableRevision", (_table getVariable ["Waldo_MG_TableRevision", 0]) + 1, true];
};

Waldo_MG_fnc_connectFourEmptyBoard = {
    private _board = [];
    _board resize (Waldo_MG_CFG_CONNECTFOUR_COLUMNS * Waldo_MG_CFG_CONNECTFOUR_ROWS);
    for "_i" from 0 to ((count _board) - 1) do {_board set [_i, 0];};
    _board
};

Waldo_MG_fnc_connectFourWinningRole = {
    params [["_board", []]];
    private _winner = -1;
    for "_row" from 0 to (Waldo_MG_CFG_CONNECTFOUR_ROWS - 1) do {
        for "_column" from 0 to (Waldo_MG_CFG_CONNECTFOUR_COLUMNS - 1) do {
            private _piece = _board param [(_row * Waldo_MG_CFG_CONNECTFOUR_COLUMNS) + _column, 0];
            if (_winner < 0 && {_piece > 0}) then {
                {
                    _x params ["_dx", "_dy"];
                    private _endColumn = _column + (3 * _dx);
                    private _endRow = _row + (3 * _dy);
                    if (_endColumn >= 0 && {_endColumn < Waldo_MG_CFG_CONNECTFOUR_COLUMNS} && {_endRow >= 0} && {_endRow < Waldo_MG_CFG_CONNECTFOUR_ROWS}) then {
                        private _line = true;
                        for "_step" from 1 to 3 do {
                            if ((_board param [((_row + (_step * _dy)) * Waldo_MG_CFG_CONNECTFOUR_COLUMNS) + _column + (_step * _dx), 0]) != _piece) then {_line = false;};
                        };
                        if (_line) then {_winner = _piece - 1;};
                    };
                } forEach [[1,0], [0,1], [1,1], [1,-1]];
            };
        };
    };
    _winner
};

Waldo_MG_fnc_connectFourStartBoardServer = {
    params [["_table", objNull], ["_resetMatch", false]];
    if (!isServer || {isNull _table}) exitWith {false};
    if (_resetMatch) then {
        _table setVariable ["Waldo_MG_ConnectFourScores", [0,0], true];
        _table setVariable ["Waldo_MG_ConnectFourRound", 1, true];
    };
    private _round = _table getVariable ["Waldo_MG_ConnectFourRound", 1];
    _table setVariable ["Waldo_MG_ConnectFourBoard", call Waldo_MG_fnc_connectFourEmptyBoard, true];
    _table setVariable ["Waldo_MG_ConnectFourTurn", (_round - 1) mod 2, true];
    _table setVariable ["Waldo_MG_ConnectFourPhase", "PLAYING", true];
    _table setVariable ["Waldo_MG_ConnectFourWinner", -2, true];
    _table setVariable ["Waldo_MG_ConnectFourReady", [false,false], true];
    _table setVariable ["Waldo_MG_ConnectFourEpoch", (_table getVariable ["Waldo_MG_ConnectFourEpoch", 0]) + 1, true];
    _table setVariable ["Waldo_MG_ConnectFourLastColumn", -1, true];
    private _names = _table getVariable ["Waldo_MG_ConnectFourPlayerNames", ["Blue O", "Amber X"]];
    private _starter = _table getVariable ["Waldo_MG_ConnectFourTurn", 0];
    _table setVariable ["Waldo_MG_ConnectFourStatus", format ["Board %1: %2 opens. Select a column.", _round, _names param [_starter, "Player"]], true];
    _table setVariable ["Waldo_MG_TablePhase", "PLAYING", true];
    [_table] call Waldo_MG_fnc_connectFourPublishRevisionServer;
    true
};

Waldo_MG_fnc_connectFourClearServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    _table setVariable ["Waldo_MG_ConnectFourActive", false, true];
    _table setVariable ["Waldo_MG_ConnectFourFinished", false, true];
    _table setVariable ["Waldo_MG_ConnectFourGameId", "", true];
    _table setVariable ["Waldo_MG_ConnectFourPlayers", [objNull,objNull], true];
    _table setVariable ["Waldo_MG_ConnectFourPlayerNames", ["Blue O", "Amber X"], true];
    _table setVariable ["Waldo_MG_ConnectFourSeatIndices", [-1,-1], true];
    _table setVariable ["Waldo_MG_ConnectFourScores", [0,0], true];
    _table setVariable ["Waldo_MG_ConnectFourRound", 1, true];
    _table setVariable ["Waldo_MG_ConnectFourEpoch", 0, true];
    _table setVariable ["Waldo_MG_ConnectFourBoard", call Waldo_MG_fnc_connectFourEmptyBoard, true];
    _table setVariable ["Waldo_MG_ConnectFourTurn", 0, true];
    _table setVariable ["Waldo_MG_ConnectFourPhase", "PLAYING", true];
    _table setVariable ["Waldo_MG_ConnectFourWinner", -2, true];
    _table setVariable ["Waldo_MG_ConnectFourReady", [false,false], true];
    _table setVariable ["Waldo_MG_ConnectFourLastColumn", -1, true];
    _table setVariable ["Waldo_MG_ConnectFourStatus", "Waiting for a Connect Four match.", true];
    [_table] call Waldo_MG_fnc_connectFourPublishRevisionServer;
};

Waldo_MG_fnc_connectFourStartServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {false};
    if ([_table] call Waldo_MG_fnc_isTableGameActive) exitWith {false};
    if ((_table getVariable ["Waldo_MG_TableSelectedGame", ""]) != "connectfour") exitWith {false};
    if ((_table getVariable ["Waldo_MG_TablePhase", "LOBBY"]) != "READY") exitWith {false};
    private _seats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
    private _players = [];
    private _seatIndices = [];
    for "_i" from 0 to (Waldo_MG_CFG_SEAT_COUNT - 1) do {
        private _unit = _seats param [_i, objNull];
        if (!isNull _unit) then {_players pushBack _unit; _seatIndices pushBack _i;};
    };
    if ((count _players) != 2) exitWith {false};
    _table setVariable ["Waldo_MG_ConnectFourActive", true, true];
    _table setVariable ["Waldo_MG_ConnectFourFinished", false, true];
    _table setVariable ["Waldo_MG_ConnectFourGameId", format ["Waldo_MG_C4_%1_%2", floor (serverTime * 10), floor (random 1000000)], true];
    _table setVariable ["Waldo_MG_ConnectFourPlayers", _players, true];
    _table setVariable ["Waldo_MG_ConnectFourPlayerNames", [name (_players select 0), name (_players select 1)], true];
    _table setVariable ["Waldo_MG_ConnectFourSeatIndices", _seatIndices, true];
    _table setVariable ["Waldo_MG_ConnectFourScores", [0,0], true];
    _table setVariable ["Waldo_MG_ConnectFourRound", 1, true];
    _table setVariable ["Waldo_MG_ConnectFourEpoch", 0, true];
    [_table, true] call Waldo_MG_fnc_connectFourStartBoardServer
};

Waldo_MG_fnc_connectFourFinishForfeitServer = {
    params [["_table", objNull], ["_unit", objNull], ["_seat", -1]];
    if (!isServer || {isNull _table} || {!(_table getVariable ["Waldo_MG_ConnectFourActive", false])}) exitWith {};
    private _players = _table getVariable ["Waldo_MG_ConnectFourPlayers", [objNull,objNull]];
    private _seats = _table getVariable ["Waldo_MG_ConnectFourSeatIndices", [-1,-1]];
    private _role = if (!isNull _unit) then {_players find _unit} else {-1};
    if (_role < 0) then {_role = _seats find _seat;};
    if (_role < 0) exitWith {};
    [_table] call Waldo_MG_fnc_connectFourClearServer;
};

Waldo_MG_fnc_connectFourReconcilePlayersServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table} || {!(_table getVariable ["Waldo_MG_ConnectFourActive", false])}) exitWith {};
    private _seats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
    private _players = _table getVariable ["Waldo_MG_ConnectFourPlayers", [objNull,objNull]];
    private _seatIndices = _table getVariable ["Waldo_MG_ConnectFourSeatIndices", [-1,-1]];
    for "_role" from 0 to 1 do {
        private _unit = _players param [_role, objNull];
        private _seat = _seatIndices param [_role, -1];
        if (isNull _unit || {_seat < 0} || {_seats param [_seat, objNull] != _unit} || {!alive _unit}) exitWith {
            [_table, _unit, _seat] call Waldo_MG_fnc_connectFourFinishForfeitServer;
        };
    };
};

Waldo_MG_fnc_processConnectFourActionRequestServer = {
    params [["_unit", objNull], ["_request", []]];
    if (!isServer || {isNull _unit}) exitWith {};
    if ((count _request) < 6) exitWith {};
    private _token = _request param [0, ""];
    if (!([_token] call Waldo_MG_fnc_rememberHandledTokenServer)) exitWith {};
    private _table = objectFromNetId (_request param [1, ""]);
    private _gameId = _request param [2, ""];
    private _epoch = _request param [3, -1];
    private _action = toUpper (_request param [4, ""]);
    private _value = _request param [5, -1];
    if (isNull _table || {_table != (_unit getVariable ["Waldo_MG_SeatedTable", objNull])} || {!(_table getVariable ["Waldo_MG_ConnectFourActive", false])}) exitWith {
        [_unit, _token, "Connect Four request rejected: the table is stale."] call Waldo_MG_fnc_resultServer;
    };
    if (_gameId != (_table getVariable ["Waldo_MG_ConnectFourGameId", ""]) || {_epoch != (_table getVariable ["Waldo_MG_ConnectFourEpoch", -2])}) exitWith {
        [_unit, _token, "Connect Four request rejected: the board changed."] call Waldo_MG_fnc_resultServer;
    };
    private _role = (_table getVariable ["Waldo_MG_ConnectFourPlayers", []]) find _unit;
    if (_role < 0) exitWith {[_unit, _token, "Spectators cannot play a disc."] call Waldo_MG_fnc_resultServer;};
    private _phase = _table getVariable ["Waldo_MG_ConnectFourPhase", "PLAYING"];
    if (_action == "READY") exitWith {
        if !(_phase in ["ROUND_OVER", "FINISHED"]) exitWith {[_unit, _token, "Finish the current board first."] call Waldo_MG_fnc_resultServer;};
        private _ready = +(_table getVariable ["Waldo_MG_ConnectFourReady", [false,false]]);
        _ready set [_role, true];
        _table setVariable ["Waldo_MG_ConnectFourReady", _ready, true];
        if ((_ready param [0,false]) && {_ready param [1,false]}) then {
            private _reset = _phase == "FINISHED";
            if (!_reset) then {_table setVariable ["Waldo_MG_ConnectFourRound", (_table getVariable ["Waldo_MG_ConnectFourRound", 1]) + 1, true];};
            _table setVariable ["Waldo_MG_ConnectFourFinished", false, true];
            [_table, _reset] call Waldo_MG_fnc_connectFourStartBoardServer;
        } else {
            _table setVariable ["Waldo_MG_ConnectFourStatus", format ["%1 is ready. Waiting for the opponent.", name _unit], true];
            [_table] call Waldo_MG_fnc_connectFourPublishRevisionServer;
        };
        [_unit, _token, "Ready state recorded."] call Waldo_MG_fnc_resultServer;
    };
    if (_action != "MOVE" || {_phase != "PLAYING"}) exitWith {[_unit, _token, "That disc cannot be played now."] call Waldo_MG_fnc_resultServer;};
    if (_role != (_table getVariable ["Waldo_MG_ConnectFourTurn", -1])) exitWith {[_unit, _token, "Wait for your turn."] call Waldo_MG_fnc_resultServer;};
    if ((typeName _value) != "SCALAR") exitWith {[_unit, _token, "Malformed column selection."] call Waldo_MG_fnc_resultServer;};
    private _column = round _value;
    if (_column < 0 || {_column >= Waldo_MG_CFG_CONNECTFOUR_COLUMNS}) exitWith {[_unit, _token, "Select a valid column."] call Waldo_MG_fnc_resultServer;};
    private _board = +(_table getVariable ["Waldo_MG_ConnectFourBoard", []]);
    private _placed = -1;
    for "_row" from (Waldo_MG_CFG_CONNECTFOUR_ROWS - 1) to 0 step -1 do {
        private _index = (_row * Waldo_MG_CFG_CONNECTFOUR_COLUMNS) + _column;
        if (_placed < 0 && {(_board param [_index, 0]) == 0}) then {_placed = _index;};
    };
    if (_placed < 0) exitWith {[_unit, _token, "That column is full."] call Waldo_MG_fnc_resultServer;};
    _board set [_placed, _role + 1];
    _table setVariable ["Waldo_MG_ConnectFourBoard", _board, true];
    _table setVariable ["Waldo_MG_ConnectFourLastColumn", _column, true];
    private _winner = [_board] call Waldo_MG_fnc_connectFourWinningRole;
    private _full = ({_x == 0} count _board) == 0;
    private _names = _table getVariable ["Waldo_MG_ConnectFourPlayerNames", ["Blue O", "Amber X"]];
    if (_winner >= 0) then {
        private _scores = +(_table getVariable ["Waldo_MG_ConnectFourScores", [0,0]]);
        _scores set [_winner, (_scores param [_winner, 0]) + 1];
        _table setVariable ["Waldo_MG_ConnectFourScores", _scores, true];
        _table setVariable ["Waldo_MG_ConnectFourWinner", _winner, true];
        _table setVariable ["Waldo_MG_ConnectFourReady", [false,false], true];
        if ((_scores param [_winner, 0]) >= Waldo_MG_CFG_CONNECTFOUR_WINS_REQUIRED) then {
            _table setVariable ["Waldo_MG_ConnectFourFinished", true, true];
            _table setVariable ["Waldo_MG_ConnectFourPhase", "FINISHED", true];
            _table setVariable ["Waldo_MG_TablePhase", "FINISHED", true];
            _table setVariable ["Waldo_MG_ConnectFourStatus", format ["%1 wins the match %2-%3. Ready for a rematch.", _names param [_winner,"Player"], _scores param [_winner,0], _scores param [1-_winner,0]], true];
        } else {
            _table setVariable ["Waldo_MG_ConnectFourPhase", "ROUND_OVER", true];
            _table setVariable ["Waldo_MG_ConnectFourStatus", format ["%1 connects four and wins this board. Both players must ready the next board.", _names param [_winner,"Player"]], true];
        };
    } else {
        if (_full) then {
            _table setVariable ["Waldo_MG_ConnectFourWinner", -1, true];
            _table setVariable ["Waldo_MG_ConnectFourPhase", "ROUND_OVER", true];
            _table setVariable ["Waldo_MG_ConnectFourReady", [false,false], true];
            _table setVariable ["Waldo_MG_ConnectFourStatus", "The board is full: draw. Ready the replay.", true];
        } else {
            private _next = 1 - _role;
            _table setVariable ["Waldo_MG_ConnectFourTurn", _next, true];
            _table setVariable ["Waldo_MG_ConnectFourStatus", format ["%1 played column %2. %3 to move.", name _unit, _column + 1, _names param [_next,"Player"]], true];
        };
    };
    _table setVariable ["Waldo_MG_ConnectFourEpoch", _epoch + 1, true];
    [_table] call Waldo_MG_fnc_connectFourPublishRevisionServer;
    [_unit, _token, format ["Disc placed in column %1.", _column + 1]] call Waldo_MG_fnc_resultServer;
};

Waldo_MG_fnc_submitConnectFourActionLocal = {
    params [["_table", objNull], ["_action", "MOVE"], ["_value", -1]];
    if (!hasInterface || {isNull player} || {isNull _table}) exitWith {};
    private _token = ["CONNECTFOUR"] call Waldo_MG_fnc_makeToken;
    private _request = [_token, netId _table, _table getVariable ["Waldo_MG_ConnectFourGameId",""], _table getVariable ["Waldo_MG_ConnectFourEpoch",-1], _action, _value];
    ["CONNECTFOUR", _table, _token, _request param [3,-1], _request] call Waldo_MG_fnc_submitRequestLocal;
};

Waldo_MG_fnc_getConnectFourRoleLocal = {
    params [["_table", objNull]];
    if (isNull _table || {isNull player}) exitWith {-1};
    (_table getVariable ["Waldo_MG_ConnectFourPlayers", []]) find player
};

Waldo_MG_fnc_refreshConnectFourLocal = {
    disableSerialization;
    params [["_display", displayNull]];
    if (isNull _display) exitWith {};
    private _table = _display getVariable ["Waldo_MG_ConnectFourTable", objNull];
    if (isNull _table) exitWith {_display closeDisplay 1;};
    private _revision = _table getVariable ["Waldo_MG_ConnectFourRevision", 0];
    if (_revision == (_display getVariable ["Waldo_MG_ConnectFourLastRevision", -1])) exitWith {};
    _display setVariable ["Waldo_MG_ConnectFourLastRevision", _revision];
    private _board = _table getVariable ["Waldo_MG_ConnectFourBoard", []];
    private _previousBoard = _display getVariable ["Waldo_MG_ConnectFourRenderedBoard", []];
    private _accessibility = profileNamespace getVariable ["Waldo_IMG_Accessibility", createHashMap];
    private _reducedMotion = if ((typeName _accessibility) == "HASHMAP") then {_accessibility getOrDefault ["reducedMotion", false]} else {false};
    private _cells = _display getVariable ["Waldo_MG_ConnectFourCells", []];
    {
        private _piece = _board param [_forEachIndex, 0];
        _x ctrlSetText (["", "O", "X"] param [_piece, ""]);
        _x ctrlSetTextColor ([ [0.40,0.44,0.48,1], [0.25,0.72,1,1], [1,0.72,0.20,1] ] param [_piece, [1,1,1,1]]);
        _x ctrlSetBackgroundColor (if (_piece == 0) then {[0.035,0.05,0.07,1]} else {[0.08,0.11,0.14,1]});
        if (!_reducedMotion && {(count _previousBoard) == (count _board)} && {_piece > 0} && {(_previousBoard param [_forEachIndex, 0]) == 0}) then {
            private _targetPosition = ctrlPosition _x;
            _x ctrlSetPosition [_targetPosition select 0, safezoneY + 0.08 * safezoneH, _targetPosition select 2, _targetPosition select 3];
            _x ctrlCommit 0;
            _x ctrlSetPosition _targetPosition;
            _x ctrlCommit 0.22;
        } else {_x ctrlCommit 0;};
    } forEach _cells;
    _display setVariable ["Waldo_MG_ConnectFourRenderedBoard", +_board];
    private _names = _table getVariable ["Waldo_MG_ConnectFourPlayerNames", ["Blue O", "Amber X"]];
    private _scores = _table getVariable ["Waldo_MG_ConnectFourScores", [0,0]];
    private _turn = _table getVariable ["Waldo_MG_ConnectFourTurn", 0];
    private _phase = _table getVariable ["Waldo_MG_ConnectFourPhase", "PLAYING"];
    private _role = [_table] call Waldo_MG_fnc_getConnectFourRoleLocal;
    private _spectating = _display getVariable ["Waldo_MG_SpectatorMode", false];
    private _playerOne = _display getVariable ["Waldo_MG_ConnectFourPlayerOne", controlNull];
    private _playerTwo = _display getVariable ["Waldo_MG_ConnectFourPlayerTwo", controlNull];
    if (!isNull _playerOne) then {_playerOne ctrlSetText format ["BLUE O  %1   BOARDS %2", _names param [0,"Player"], _scores param [0,0]]; _playerOne ctrlSetBackgroundColor (if (_phase == "PLAYING" && {_turn == 0}) then {[0.05,0.25,0.42,1]} else {[0.03,0.08,0.12,1]});};
    if (!isNull _playerTwo) then {_playerTwo ctrlSetText format ["AMBER X  %1   BOARDS %2", _names param [1,"Player"], _scores param [1,0]]; _playerTwo ctrlSetBackgroundColor (if (_phase == "PLAYING" && {_turn == 1}) then {[0.35,0.22,0.04,1]} else {[0.12,0.08,0.03,1]});};
    private _status = _display getVariable ["Waldo_MG_ConnectFourStatusCtrl", controlNull];
    if (!isNull _status) then {_status ctrlSetText (_table getVariable ["Waldo_MG_ConnectFourStatus", "Connect Four in progress."]);};
    private _turnCtrl = _display getVariable ["Waldo_MG_ConnectFourTurnCtrl", controlNull];
    if (!isNull _turnCtrl) then {_turnCtrl ctrlSetText (if (_phase == "PLAYING") then {format ["TURN: %1  %2", ["BLUE O","AMBER X"] select _turn, _names select _turn]} else {if (_phase == "FINISHED") then {"MATCH COMPLETE"} else {"BOARD COMPLETE"};});};
    private _columnButtons = _display getVariable ["Waldo_MG_ConnectFourColumnButtons", []];
    {
        private _column = _forEachIndex;
        private _full = (_board param [_column, 0]) != 0;
        _x ctrlEnable (!_spectating && {_role == _turn} && {_phase == "PLAYING"} && {!_full});
        _x ctrlSetText format ["%1 %2", _column + 1, if (_full) then {"[FULL]"} else {"v"}];
        _x ctrlCommit 0;
    } forEach _columnButtons;
    private _readyButton = _display getVariable ["Waldo_MG_ConnectFourReadyButton", controlNull];
    if (!isNull _readyButton) then {
        private _ready = _table getVariable ["Waldo_MG_ConnectFourReady", [false,false]];
        _readyButton ctrlShow (!_spectating && {_role >= 0} && {_phase in ["ROUND_OVER","FINISHED"]});
        _readyButton ctrlEnable (_role >= 0 && {!(_ready param [_role,false])});
        _readyButton ctrlSetText (if (_role >= 0 && {_ready param [_role,false]}) then {"READY - WAITING"} else {if (_phase == "FINISHED") then {"READY REMATCH"} else {"READY NEXT BOARD"};});
        _readyButton ctrlCommit 0;
    };
};

Waldo_MG_fnc_openConnectFourLocal = {
    disableSerialization;
    params [["_table", objNull], ["_spectating", false]];
    if (!hasInterface || {isNull player} || {isNull _table}) exitWith {};
    if (!([_table, _spectating] call Waldo_MG_fnc_isValidGameViewerLocal) || {([_table] call Waldo_MG_fnc_getTableActiveGameId) != "connectfour"}) exitWith {["No active Connect Four match is available."] call Waldo_MG_fnc_notifyLocal;};
    private _parent = findDisplay 46;
    if (isNull _parent) exitWith {};
    call Waldo_MG_fnc_closeTableGameDisplaysLocal;
    private _display = _parent createDisplay "RscDisplayEmpty";
    uiNamespace setVariable ["Waldo_MG_ConnectFourDisplay", _display];
    _display setVariable ["Waldo_MG_TableGameDisplay", true];
    _display setVariable ["Waldo_MG_ConnectFourTable", _table];
    _display setVariable ["Waldo_MG_SpectatorMode", _spectating];
    _display setVariable ["Waldo_MG_ConnectFourLastRevision", -1];
    [_display] call Waldo_MG_fnc_installEscapeGuardLocal;
    private _bg = _display ctrlCreate ["RscText", -1];
    _bg ctrlSetPosition [safezoneX, safezoneY, safezoneW, safezoneH]; _bg ctrlSetBackgroundColor [0.008,0.012,0.020,0.99]; _bg ctrlCommit 0;
    private _bar = _display ctrlCreate ["RscText", -1];
    _bar ctrlSetPosition [safezoneX, safezoneY, safezoneW, 0.075 * safezoneH]; _bar ctrlSetBackgroundColor [0.045,0.17,0.29,1]; _bar ctrlCommit 0;
    private _title = _display ctrlCreate ["RscText", -1];
    _title ctrlSetPosition [safezoneX + 0.03 * safezoneW, safezoneY + 0.012 * safezoneH, 0.55 * safezoneW, 0.05 * safezoneH]; _title ctrlSetText "WALDOS MINI GAMES  /  CONNECT FOUR"; _title ctrlSetTextColor [0.84,0.94,1,1]; _title ctrlSetFontHeight (0.032 * safezoneH); _title ctrlCommit 0;
    private _subtitle = _display ctrlCreate ["RscText", -1];
    _subtitle ctrlSetPosition [safezoneX + 0.62 * safezoneW, safezoneY + 0.018 * safezoneH, 0.34 * safezoneW, 0.04 * safezoneH]; _subtitle ctrlSetText (if (_spectating) then {"SPECTATOR  /  READ ONLY"} else {"BEST OF THREE  /  KEYS 1-7"}); _subtitle ctrlSetTextColor [0.65,0.82,0.94,1]; _subtitle ctrlCommit 0;
    private _boardX = safezoneX + 0.08 * safezoneW;
    private _boardY = safezoneY + 0.16 * safezoneH;
    private _boardW = 0.58 * safezoneW;
    private _boardH = 0.68 * safezoneH;
    private _frame = _display ctrlCreate ["RscText", -1];
    _frame ctrlSetPosition [_boardX - 0.012 * safezoneW, _boardY - 0.012 * safezoneH, _boardW + 0.024 * safezoneW, _boardH + 0.024 * safezoneH]; _frame ctrlSetBackgroundColor [0.08,0.25,0.42,1]; _frame ctrlCommit 0;
    private _columnButtons = [];
    for "_column" from 0 to 6 do {
        private _button = _display ctrlCreate ["RscButton", -1];
        _button ctrlSetPosition [_boardX + (_column * _boardW / 7), _boardY - 0.065 * safezoneH, (_boardW / 7) - 0.003 * safezoneW, 0.052 * safezoneH];
        _button setVariable ["Waldo_MG_ConnectFourColumn", _column];
        _button ctrlAddEventHandler ["ButtonClick", {params ["_ctrl"]; private _display = ctrlParent _ctrl; [_display getVariable ["Waldo_MG_ConnectFourTable",objNull], "MOVE", _ctrl getVariable ["Waldo_MG_ConnectFourColumn",-1]] call Waldo_MG_fnc_submitConnectFourActionLocal;}];
        _button ctrlCommit 0; _columnButtons pushBack _button;
    };
    _display setVariable ["Waldo_MG_ConnectFourColumnButtons", _columnButtons];
    private _cells = [];
    for "_row" from 0 to 5 do {
        for "_column" from 0 to 6 do {
            private _cell = _display ctrlCreate ["RscText", -1];
            _cell ctrlSetPosition [_boardX + (_column * _boardW / 7) + 0.003 * safezoneW, _boardY + (_row * _boardH / 6) + 0.003 * safezoneH, (_boardW / 7) - 0.006 * safezoneW, (_boardH / 6) - 0.006 * safezoneH];
            _cell ctrlSetFontHeight (0.065 * safezoneH); _cell ctrlSetBackgroundColor [0.035,0.05,0.07,1]; _cell ctrlCommit 0; _cells pushBack _cell;
        };
    };
    _display setVariable ["Waldo_MG_ConnectFourCells", _cells];
    private _panelX = safezoneX + 0.70 * safezoneW;
    private _panel = _display ctrlCreate ["RscText", -1]; _panel ctrlSetPosition [_panelX, safezoneY + 0.13 * safezoneH, 0.26 * safezoneW, 0.71 * safezoneH]; _panel ctrlSetBackgroundColor [0.02,0.035,0.055,0.98]; _panel ctrlCommit 0;
    private _p1 = _display ctrlCreate ["RscText", -1]; _p1 ctrlSetPosition [_panelX + 0.018 * safezoneW, safezoneY + 0.17 * safezoneH, 0.224 * safezoneW, 0.065 * safezoneH]; _p1 ctrlSetTextColor [0.45,0.82,1,1]; _p1 ctrlSetFontHeight (0.021 * safezoneH); _p1 ctrlCommit 0;
    private _p2 = _display ctrlCreate ["RscText", -1]; _p2 ctrlSetPosition [_panelX + 0.018 * safezoneW, safezoneY + 0.25 * safezoneH, 0.224 * safezoneW, 0.065 * safezoneH]; _p2 ctrlSetTextColor [1,0.78,0.30,1]; _p2 ctrlSetFontHeight (0.021 * safezoneH); _p2 ctrlCommit 0;
    private _turn = _display ctrlCreate ["RscText", -1]; _turn ctrlSetPosition [_panelX + 0.018 * safezoneW, safezoneY + 0.35 * safezoneH, 0.224 * safezoneW, 0.055 * safezoneH]; _turn ctrlSetTextColor [0.95,0.95,0.88,1]; _turn ctrlSetFontHeight (0.023 * safezoneH); _turn ctrlCommit 0;
    private _rules = _display ctrlCreate ["RscStructuredText", -1]; _rules ctrlSetPosition [_panelX + 0.018 * safezoneW, safezoneY + 0.43 * safezoneH, 0.224 * safezoneW, 0.20 * safezoneH]; _rules ctrlSetStructuredText parseText "<t color='#8FCBEE'>FIELD RULES</t><br/><br/>Select a column or press 1-7.<br/>First to connect four wins the board.<br/>First to two boards wins the match.<br/><br/><t color='#F2BE55'>Blue uses O. Amber uses X.</t>"; _rules ctrlCommit 0;
    private _ready = _display ctrlCreate ["RscButtonMenu", -1]; _ready ctrlSetPosition [_panelX + 0.025 * safezoneW, safezoneY + 0.68 * safezoneH, 0.21 * safezoneW, 0.052 * safezoneH]; _ready ctrlAddEventHandler ["ButtonClick", {params ["_ctrl"]; private _d = ctrlParent _ctrl; [_d getVariable ["Waldo_MG_ConnectFourTable",objNull], "READY", 0] call Waldo_MG_fnc_submitConnectFourActionLocal;}]; _ready ctrlCommit 0;
    private _status = _display ctrlCreate ["RscText", -1]; _status ctrlSetPosition [safezoneX + 0.05 * safezoneW, safezoneY + 0.88 * safezoneH, 0.72 * safezoneW, 0.055 * safezoneH]; _status ctrlSetBackgroundColor [0.025,0.055,0.08,1]; _status ctrlSetTextColor [0.9,0.95,1,1]; _status ctrlSetFontHeight (0.019 * safezoneH); _status ctrlCommit 0;
    private _leave = _display ctrlCreate ["RscButtonMenu", -1]; _leave ctrlSetPosition [safezoneX + 0.79 * safezoneW, safezoneY + 0.88 * safezoneH, 0.17 * safezoneW, 0.055 * safezoneH]; _leave ctrlSetText (if (_spectating) then {"EXIT SPECTATE"} else {"LEAVE TABLE"}); _leave ctrlAddEventHandler ["ButtonClick", {params ["_ctrl"]; [_ctrl] call Waldo_MG_fnc_handleViewerExitButtonLocal;}]; _leave ctrlCommit 0;
    _display setVariable ["Waldo_MG_ConnectFourPlayerOne", _p1]; _display setVariable ["Waldo_MG_ConnectFourPlayerTwo", _p2]; _display setVariable ["Waldo_MG_ConnectFourTurnCtrl", _turn]; _display setVariable ["Waldo_MG_ConnectFourReadyButton", _ready]; _display setVariable ["Waldo_MG_ConnectFourStatusCtrl", _status];
    _display displayAddEventHandler ["KeyDown", {params ["_display","_key"]; private _column = [2,3,4,5,6,7,8] find _key; if (_column >= 0) then {[_display getVariable ["Waldo_MG_ConnectFourTable",objNull], "MOVE", _column] call Waldo_MG_fnc_submitConnectFourActionLocal; true} else {_key == 1};}];
    [_display] call Waldo_MG_fnc_refreshConnectFourLocal;
    [_display] spawn {disableSerialization; params ["_display"]; while {!isNull _display} do {[_display] call Waldo_MG_fnc_refreshConnectFourLocal; uiSleep Waldo_MG_CFG_CONNECTFOUR_UI_TICK;};};
};
