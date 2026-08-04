/*
 * Waldos Mini Games - Rock Paper Scissors
 * All Waldo_MG_fnc_* functions implementing the Rock Paper Scissors mini game (server logic + local UI).
 *
 * Original engine: "Party Games Scripted" by |LorD|[Habilidade]Deus Ex.
 * Ported into WaldosMissionPack and rebranded to the Waldo_MG_ namespace; game
 * logic is preserved from the original composition. Do not claim original authorship.
 *
 * This file is an engine fragment: it defines a group of Waldo_MG_fnc_* runtime
 * functions and is #included by Waldo_fnc_MiniGamesInit (miniGamesInit.sqf).
 * It is not a standalone CfgFunctions entry and is not called directly.
 */

Waldo_MG_fnc_rpsPublishRevisionServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    _table setVariable [
        "Waldo_MG_RPSRevision",
        (_table getVariable ["Waldo_MG_RPSRevision", 0]) + 1,
        true
    ];
    _table setVariable [
        "Waldo_MG_TableRevision",
        (_table getVariable ["Waldo_MG_TableRevision", 0]) + 1,
        true
    ];
};

Waldo_MG_fnc_rpsClearServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    _table setVariable ["Waldo_MG_RPSActive", false, true];
    _table setVariable ["Waldo_MG_RPSFinished", false, true];
    _table setVariable ["Waldo_MG_RPSGameId", "", true];
    _table setVariable ["Waldo_MG_RPSPlayers", [objNull, objNull], true];
    _table setVariable ["Waldo_MG_RPSPlayerNames", ["Player One", "Player Two"], true];
    _table setVariable ["Waldo_MG_RPSSeatIndices", [-1, -1], true];
    _table setVariable ["Waldo_MG_RPSRound", 1, true];
    _table setVariable ["Waldo_MG_RPSEpoch", 0, true];
    _table setVariable ["Waldo_MG_RPSScores", [0, 0], true];
    _table setVariable ["Waldo_MG_RPSLocked", [false, false], true];
    _table setVariable ["Waldo_MG_RPSPhase", "CHOOSING", true];
    _table setVariable ["Waldo_MG_RPSCountdownEnd", 0, true];
    _table setVariable ["Waldo_MG_RPSRevealEnd", 0, true];
    _table setVariable ["Waldo_MG_RPSRevealedChoices", ["", ""], true];
    _table setVariable ["Waldo_MG_RPSRoundWinner", -2, true];
    _table setVariable ["Waldo_MG_RPSWinner", -1, true];
    _table setVariable ["Waldo_MG_RPSStatus", "Waiting for a Rock Paper Scissors match.", true];
    _table setVariable ["Waldo_MG_RPSChoicesServer", ["", ""]];
    [_table] call Waldo_MG_fnc_rpsPublishRevisionServer;
};

Waldo_MG_fnc_rpsStartServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {false};
    if ([_table] call Waldo_MG_fnc_isTableGameActive) exitWith {false};
    if ((_table getVariable ["Waldo_MG_TableSelectedGame", ""]) != "rps") exitWith {false};
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
    private _first = _players param [0, objNull];
    private _second = _players param [1, objNull];
    if (isNull _first || {isNull _second}) exitWith {false};
    _table setVariable ["Waldo_MG_RPSActive", true, true];
    _table setVariable ["Waldo_MG_RPSFinished", false, true];
    _table setVariable [
        "Waldo_MG_RPSGameId",
        format ["Waldo_MG_RPS_%1_%2", floor (serverTime * 10), floor (random 1000000)],
        true
    ];
    _table setVariable ["Waldo_MG_RPSPlayers", [_first, _second], true];
    _table setVariable ["Waldo_MG_RPSPlayerNames", [name _first, name _second], true];
    _table setVariable ["Waldo_MG_RPSSeatIndices", _seatIndices, true];
    _table setVariable ["Waldo_MG_RPSRound", 1, true];
    _table setVariable ["Waldo_MG_RPSEpoch", 1, true];
    _table setVariable ["Waldo_MG_RPSScores", [0, 0], true];
    _table setVariable ["Waldo_MG_RPSLocked", [false, false], true];
    _table setVariable ["Waldo_MG_RPSPhase", "CHOOSING", true];
    _table setVariable ["Waldo_MG_RPSCountdownEnd", 0, true];
    _table setVariable ["Waldo_MG_RPSRevealEnd", 0, true];
    _table setVariable ["Waldo_MG_RPSRevealedChoices", ["", ""], true];
    _table setVariable ["Waldo_MG_RPSRoundWinner", -2, true];
    _table setVariable ["Waldo_MG_RPSWinner", -1, true];
    _table setVariable ["Waldo_MG_RPSStatus", "Round 1: both players must lock a choice.", true];
    _table setVariable ["Waldo_MG_RPSChoicesServer", ["", ""]];
    _table setVariable ["Waldo_MG_TablePhase", "PLAYING", true];
    [_table] call Waldo_MG_fnc_rpsPublishRevisionServer;
    true
};

Waldo_MG_fnc_rpsFinishForfeitServer = {
    params [
        ["_table", objNull],
        ["_departingUnit", objNull],
        ["_departingSeat", -1]
    ];
    if (!isServer || {isNull _table}) exitWith {};
    if (!(_table getVariable ["Waldo_MG_RPSActive", false])) exitWith {};
    if (_table getVariable ["Waldo_MG_RPSFinished", false]) exitWith {};
    private _players = _table getVariable ["Waldo_MG_RPSPlayers", [objNull, objNull]];
    private _seatIndices = _table getVariable ["Waldo_MG_RPSSeatIndices", [-1, -1]];
    private _names = _table getVariable ["Waldo_MG_RPSPlayerNames", ["Player One", "Player Two"]];
    private _roleIndex = -1;
    if (!isNull _departingUnit) then {
        _roleIndex = _players find _departingUnit;
    };
    if (_roleIndex < 0 && {_departingSeat >= 0}) then {
        _roleIndex = _seatIndices find _departingSeat;
    };
    if (_roleIndex < 0) exitWith {};
    private _winnerRole = 1 - _roleIndex;
    private _winnerName = _names param [_winnerRole, "Opponent"];
    private _loserName = _names param [_roleIndex, "Opponent"];
    _table setVariable ["Waldo_MG_RPSFinished", true, true];
    _table setVariable ["Waldo_MG_RPSPhase", "FINISHED", true];
    _table setVariable ["Waldo_MG_RPSWinner", _winnerRole, true];
    _table setVariable ["Waldo_MG_RPSCountdownEnd", 0, true];
    _table setVariable ["Waldo_MG_RPSRevealEnd", 0, true];
    _table setVariable ["Waldo_MG_RPSStatus", format ["%1 wins the match by forfeit after %2 left.", _winnerName, _loserName], true];
    _table setVariable ["Waldo_MG_TablePhase", "FINISHED", true];
    [_table] call Waldo_MG_fnc_rpsPublishRevisionServer;
};

Waldo_MG_fnc_rpsProgressServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    if (!(_table getVariable ["Waldo_MG_RPSActive", false])) exitWith {};
    if (_table getVariable ["Waldo_MG_RPSFinished", false]) exitWith {};
    private _phase = _table getVariable ["Waldo_MG_RPSPhase", "CHOOSING"];
    if (_phase == "COUNTDOWN") exitWith {
        if (serverTime < (_table getVariable ["Waldo_MG_RPSCountdownEnd", 0])) exitWith {};
        private _choices = +(_table getVariable ["Waldo_MG_RPSChoicesServer", ["", ""]]);
        private _firstChoice = _choices param [0, ""];
        private _secondChoice = _choices param [1, ""];
        if (!(_firstChoice in ["ROCK", "PAPER", "SCISSORS"]) || {!(_secondChoice in ["ROCK", "PAPER", "SCISSORS"])}) exitWith {
            _table setVariable ["Waldo_MG_RPSChoicesServer", ["", ""]];
            _table setVariable ["Waldo_MG_RPSEpoch", (_table getVariable ["Waldo_MG_RPSEpoch", 0]) + 1, true];
            _table setVariable ["Waldo_MG_RPSLocked", [false, false], true];
            _table setVariable ["Waldo_MG_RPSPhase", "CHOOSING", true];
            _table setVariable ["Waldo_MG_RPSCountdownEnd", 0, true];
            _table setVariable ["Waldo_MG_RPSStatus", "The choices could not be verified. Both players must choose again.", true];
            [_table] call Waldo_MG_fnc_rpsPublishRevisionServer;
        };
        private _roundWinner = -1;
        if (_firstChoice != _secondChoice) then {
            _roundWinner = if (
                (_firstChoice == "ROCK" && {_secondChoice == "SCISSORS"})
                || {(_firstChoice == "SCISSORS" && {_secondChoice == "PAPER"})}
                || {(_firstChoice == "PAPER" && {_secondChoice == "ROCK"})}
            ) then {0} else {1};
        };
        private _round = _table getVariable ["Waldo_MG_RPSRound", 1];
        private _scores = +(_table getVariable ["Waldo_MG_RPSScores", [0, 0]]);
        private _names = _table getVariable ["Waldo_MG_RPSPlayerNames", ["Player One", "Player Two"]];
        private _status = format ["Round %1 is a draw. The round will replay.", _round];
        if (_roundWinner >= 0) then {
            _scores set [_roundWinner, (_scores param [_roundWinner, 0]) + 1];
            _status = format ["%1 wins round %2: %3 beats %4.", _names param [_roundWinner, "Player"], _round, _choices param [_roundWinner, ""], _choices param [1 - _roundWinner, ""]];
        };
        _table setVariable ["Waldo_MG_RPSScores", _scores, true];
        _table setVariable ["Waldo_MG_RPSRevealedChoices", _choices, true];
        _table setVariable ["Waldo_MG_RPSRoundWinner", _roundWinner, true];
        _table setVariable ["Waldo_MG_RPSCountdownEnd", 0, true];
        if (_roundWinner >= 0 && {(_scores param [_roundWinner, 0]) >= 2}) then {
            _table setVariable ["Waldo_MG_RPSFinished", true, true];
            _table setVariable ["Waldo_MG_RPSPhase", "FINISHED", true];
            _table setVariable ["Waldo_MG_RPSWinner", _roundWinner, true];
            _table setVariable ["Waldo_MG_RPSRevealEnd", 0, true];
            _table setVariable ["Waldo_MG_RPSStatus", format ["%1 wins the best-of-three match, %2 to %3.", _names param [_roundWinner, "Player"], _scores param [_roundWinner, 0], _scores param [1 - _roundWinner, 0]], true];
            _table setVariable ["Waldo_MG_TablePhase", "FINISHED", true];
        } else {
            _table setVariable ["Waldo_MG_RPSPhase", "REVEAL", true];
            _table setVariable ["Waldo_MG_RPSRevealEnd", serverTime + Waldo_MG_CFG_RPS_REVEAL_SECONDS, true];
            _table setVariable ["Waldo_MG_RPSStatus", _status, true];
        };
        [_table] call Waldo_MG_fnc_rpsPublishRevisionServer;
    };
    if (_phase == "REVEAL") exitWith {
        if (serverTime < (_table getVariable ["Waldo_MG_RPSRevealEnd", 0])) exitWith {};
        private _round = _table getVariable ["Waldo_MG_RPSRound", 1];
        if ((_table getVariable ["Waldo_MG_RPSRoundWinner", -2]) >= 0) then {
            _round = _round + 1;
        };
        _table setVariable ["Waldo_MG_RPSRound", _round, true];
        _table setVariable ["Waldo_MG_RPSEpoch", (_table getVariable ["Waldo_MG_RPSEpoch", 0]) + 1, true];
        _table setVariable ["Waldo_MG_RPSLocked", [false, false], true];
        _table setVariable ["Waldo_MG_RPSPhase", "CHOOSING", true];
        _table setVariable ["Waldo_MG_RPSRevealEnd", 0, true];
        _table setVariable ["Waldo_MG_RPSRevealedChoices", ["", ""], true];
        _table setVariable ["Waldo_MG_RPSRoundWinner", -2, true];
        _table setVariable ["Waldo_MG_RPSChoicesServer", ["", ""]];
        _table setVariable ["Waldo_MG_RPSStatus", format ["Round %1: both players must lock a choice.", _round], true];
        [_table] call Waldo_MG_fnc_rpsPublishRevisionServer;
    };
};

Waldo_MG_fnc_rpsReconcilePlayersServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    if (!(_table getVariable ["Waldo_MG_RPSActive", false])) exitWith {};
    private _seats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
    private _players = _table getVariable ["Waldo_MG_RPSPlayers", [objNull, objNull]];
    private _seatIndices = _table getVariable ["Waldo_MG_RPSSeatIndices", [-1, -1]];
    private _valid = [false, false];
    for "_role" from 0 to 1 do {
        private _unit = _players param [_role, objNull];
        private _seatIndex = _seatIndices param [_role, -1];
        _valid set [_role,
            !isNull _unit
                && {_seatIndex >= 0}
                && {_seatIndex < Waldo_MG_CFG_SEAT_COUNT}
                && {(_seats param [_seatIndex, objNull]) == _unit}
                && {_unit in allPlayers}
                && {alive _unit}
                && {(lifeState _unit) != "INCAPACITATED"}
        ];
    };
    if (!(_valid param [0, false]) && {!(_valid param [1, false])}) exitWith {
        [_table] call Waldo_MG_fnc_rpsClearServer;
        _table setVariable ["Waldo_MG_TableReady", [false, false, false, false], true];
        _table setVariable ["Waldo_MG_TablePhase", "LOBBY", true];
    };
    if (!(_table getVariable ["Waldo_MG_RPSFinished", false])) then {
        if (!(_valid param [0, false])) then {
            [_table, objNull, _seatIndices param [0, -1]] call Waldo_MG_fnc_rpsFinishForfeitServer;
        } else {
            if (!(_valid param [1, false])) then {
                [_table, objNull, _seatIndices param [1, -1]] call Waldo_MG_fnc_rpsFinishForfeitServer;
            };
        };
    };
};

Waldo_MG_fnc_rpsResetServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    [_table] call Waldo_MG_fnc_rpsClearServer;
    _table setVariable ["Waldo_MG_TableReady", [false, false, false, false], true];
    [_table] call Waldo_MG_fnc_refreshTableConsensusServer;
};

Waldo_MG_fnc_processRPSActionRequestServer = {
    params [
        ["_unit", objNull],
        ["_request", []]
    ];
    if (!isServer || {isNull _unit}) exitWith {};
    _unit setVariable ["Waldo_MG_RPSActionRequest", [], true];
    if ((count _request) < 6) exitWith {};
    private _token = _request param [0, ""];
    if (!([_token] call Waldo_MG_fnc_rememberHandledTokenServer)) exitWith {};
    private _tableNetId = _request param [1, ""];
    private _gameId = _request param [2, ""];
    private _expectedEpoch = _request param [3, -1];
    private _action = _request param [4, ""];
    private _payload = _request param [5, ""];
    if (
        (typeName _tableNetId) != "STRING"
        || {(typeName _gameId) != "STRING"}
        || {(typeName _expectedEpoch) != "SCALAR"}
        || {(typeName _action) != "STRING"}
    ) exitWith {
        [_unit, _token, "Rock Paper Scissors action rejected: malformed request data."] call Waldo_MG_fnc_resultServer;
    };
    private _table = objectFromNetId _tableNetId;
    if (isNull _table || {_table != (_unit getVariable ["Waldo_MG_SeatedTable", objNull])}) exitWith {
        [_unit, _token, "Rock Paper Scissors action rejected: you are no longer seated at that table."] call Waldo_MG_fnc_resultServer;
    };
    if (!(_table getVariable ["Waldo_MG_RPSActive", false])) exitWith {
        [_unit, _token, "There is no active Rock Paper Scissors match at this table."] call Waldo_MG_fnc_resultServer;
    };
    if (_gameId == "" || {_gameId != (_table getVariable ["Waldo_MG_RPSGameId", ""])}) exitWith {
        [_unit, _token, "That Rock Paper Scissors match is no longer current."] call Waldo_MG_fnc_resultServer;
    };
    if (_expectedEpoch != (_table getVariable ["Waldo_MG_RPSEpoch", -1])) exitWith {
        [_unit, _token, "That choice belongs to an older round. Please choose again."] call Waldo_MG_fnc_resultServer;
    };
    private _players = _table getVariable ["Waldo_MG_RPSPlayers", [objNull, objNull]];
    private _roleIndex = _players find _unit;
    if (_roleIndex < 0) exitWith {
        [_unit, _token, "Only the two assigned players may choose in this match."] call Waldo_MG_fnc_resultServer;
    };
    private _finished = _table getVariable ["Waldo_MG_RPSFinished", false];
    if (_action == "RESET") exitWith {
        if (!_finished) then {
            [_unit, _token, "Finish the match before returning the table to its lobby."] call Waldo_MG_fnc_resultServer;
        } else {
            [_table] call Waldo_MG_fnc_rpsResetServer;
            [_unit, _token, "Rock Paper Scissors cleared. The table has returned to its lobby."] call Waldo_MG_fnc_resultServer;
        };
    };
    if (_action != "CHOOSE") exitWith {
        [_unit, _token, "Unknown Rock Paper Scissors action."] call Waldo_MG_fnc_resultServer;
    };
    if (_finished) exitWith {
        [_unit, _token, "That Rock Paper Scissors match has already finished."] call Waldo_MG_fnc_resultServer;
    };
    if ((_table getVariable ["Waldo_MG_RPSPhase", "CHOOSING"]) != "CHOOSING") exitWith {
        [_unit, _token, "Choices are locked while the current round is being revealed."] call Waldo_MG_fnc_resultServer;
    };
    if ((typeName _payload) != "STRING" || {!(_payload in ["ROCK", "PAPER", "SCISSORS"])}) exitWith {
        [_unit, _token, "Choose ROCK, PAPER or SCISSORS."] call Waldo_MG_fnc_resultServer;
    };
    private _locked = +(_table getVariable ["Waldo_MG_RPSLocked", [false, false]]);
    if (_locked param [_roleIndex, false]) exitWith {
        [_unit, _token, "Your choice is already locked for this round."] call Waldo_MG_fnc_resultServer;
    };
    private _choices = +(_table getVariable ["Waldo_MG_RPSChoicesServer", ["", ""]]);
    _choices set [_roleIndex, _payload];
    _locked set [_roleIndex, true];
    _table setVariable ["Waldo_MG_RPSChoicesServer", _choices];
    _table setVariable ["Waldo_MG_RPSLocked", _locked, true];
    private _names = _table getVariable ["Waldo_MG_RPSPlayerNames", ["Player One", "Player Two"]];
    private _bothLocked = (_locked param [0, false]) && {(_locked param [1, false])};
    if (_bothLocked) then {
        _table setVariable ["Waldo_MG_RPSPhase", "COUNTDOWN", true];
        _table setVariable ["Waldo_MG_RPSCountdownEnd", serverTime + Waldo_MG_CFG_RPS_COUNTDOWN_SECONDS, true];
        _table setVariable ["Waldo_MG_RPSStatus", "Both choices are locked. Reveal incoming.", true];
    } else {
        _table setVariable ["Waldo_MG_RPSStatus", format ["%1 has locked a choice. Waiting for %2.", _names param [_roleIndex, "Player"], _names param [1 - _roleIndex, "Opponent"]], true];
    };
    [_table] call Waldo_MG_fnc_rpsPublishRevisionServer;
    [_unit, _token, if (_bothLocked) then {
        format ["%1 locked. The reveal countdown has started.", _payload]
    } else {
        format ["%1 locked. Waiting for your opponent.", _payload]
    }] call Waldo_MG_fnc_resultServer;
};

Waldo_MG_fnc_submitRPSActionRequestLocal = {
    params [
        ["_table", objNull],
        ["_action", ""],
        ["_payload", ""]
    ];
    if (!hasInterface || {isNull player} || {isNull _table} || {_action == ""}) exitWith {false};
    private _pending = missionNamespace getVariable ["Waldo_MG_RPSPendingRequestLocal", []];
    if ((count _pending) >= 2 && {(diag_tickTime - (_pending param [1, -10])) < 1.5}) exitWith {
        ["Waiting for the table host to answer your previous choice..."] call Waldo_MG_fnc_notifyLocal;
        false
    };
    private _token = ["RPS_ACTION"] call Waldo_MG_fnc_makeToken;
    missionNamespace setVariable ["Waldo_MG_RPSPendingRequestLocal", [_token, diag_tickTime]];
    player setVariable [
        "Waldo_MG_RPSActionRequest",
        [
            _token,
            netId _table,
            _table getVariable ["Waldo_MG_RPSGameId", ""],
            _table getVariable ["Waldo_MG_RPSEpoch", -1],
            _action,
            _payload
        ],
        2
    ];
    true
};

Waldo_MG_fnc_getRPSRoleLocal = {
    params [["_table", objNull]];
    if (isNull _table || {isNull player}) exitWith {-1};
    (_table getVariable ["Waldo_MG_RPSPlayers", [objNull, objNull]]) find player
};

Waldo_MG_fnc_handleRPSChoiceClickLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    if (isNull _display || {_display getVariable ["Waldo_MG_SpectatorMode", false]}) exitWith {};
    private _table = _display getVariable ["Waldo_MG_RPSTable", objNull];
    private _choice = _control getVariable ["Waldo_MG_RPSChoice", ""];
    if (_choice == "" || {isNull _table}) exitWith {};
    if ([_table, "CHOOSE", _choice] call Waldo_MG_fnc_submitRPSActionRequestLocal) then {
        _display setVariable ["Waldo_MG_RPSLocalChoice", _choice];
        [_display] call Waldo_MG_fnc_refreshRPSLocal;
    };
};

Waldo_MG_fnc_handleRPSResetClickLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    private _table = _display getVariable ["Waldo_MG_RPSTable", objNull];
    [_table, "RESET", ""] call Waldo_MG_fnc_submitRPSActionRequestLocal;
};

Waldo_MG_fnc_refreshRPSLocal = {
    disableSerialization;
    params [["_display", displayNull]];
    if (isNull _display) exitWith {};
    if (_display getVariable ["Waldo_MG_RPSRefreshing", false]) exitWith {};
    _display setVariable ["Waldo_MG_RPSRefreshing", true];
    private _table = _display getVariable ["Waldo_MG_RPSTable", objNull];
    private _spectating = _display getVariable ["Waldo_MG_SpectatorMode", false];
    if (
        isNull _table
        || {!([_table, _spectating] call Waldo_MG_fnc_isValidGameViewerLocal)}
        || {([_table] call Waldo_MG_fnc_getTableActiveGameId) != "rps"}
    ) exitWith {
        _display closeDisplay 1;
    };

    private _players = _table getVariable ["Waldo_MG_RPSPlayers", [objNull, objNull]];
    private _names = _table getVariable ["Waldo_MG_RPSPlayerNames", ["Player One", "Player Two"]];
    private _scores = _table getVariable ["Waldo_MG_RPSScores", [0, 0]];
    private _locked = _table getVariable ["Waldo_MG_RPSLocked", [false, false]];
    private _revealed = _table getVariable ["Waldo_MG_RPSRevealedChoices", ["", ""]];
    private _phase = _table getVariable ["Waldo_MG_RPSPhase", "CHOOSING"];
    private _round = _table getVariable ["Waldo_MG_RPSRound", 1];
    private _roundWinner = _table getVariable ["Waldo_MG_RPSRoundWinner", -2];
    private _winner = _table getVariable ["Waldo_MG_RPSWinner", -1];
    private _finished = _table getVariable ["Waldo_MG_RPSFinished", false];
    private _epoch = _table getVariable ["Waldo_MG_RPSEpoch", 0];
    private _role = if (_spectating) then {-1} else {_players find player};
    private _lastEpoch = _display getVariable ["Waldo_MG_RPSLastEpoch", -1];
    if (_epoch != _lastEpoch) then {
        _display setVariable ["Waldo_MG_RPSLastEpoch", _epoch];
        _display setVariable ["Waldo_MG_RPSLocalChoice", ""];
    };
    private _localChoice = _display getVariable ["Waldo_MG_RPSLocalChoice", ""];

    private _nameControls = _display getVariable ["Waldo_MG_RPSNameControls", []];
    private _scoreControls = _display getVariable ["Waldo_MG_RPSScoreControls", []];
    private _choiceControls = _display getVariable ["Waldo_MG_RPSChoiceControls", []];
    private _panelControls = _display getVariable ["Waldo_MG_RPSPanelControls", []];
    for "_index" from 0 to 1 do {
        private _nameControl = _nameControls param [_index, controlNull];
        private _scoreControl = _scoreControls param [_index, controlNull];
        private _choiceControl = _choiceControls param [_index, controlNull];
        private _panelControl = _panelControls param [_index, controlNull];
        if (!isNull _nameControl) then {
            _nameControl ctrlSetText format ["%1%2", _names param [_index, format ["Player %1", _index + 1]], if (_role == _index) then {"  /  YOU"} else {""}];
            _nameControl ctrlCommit 0;
        };
        if (!isNull _scoreControl) then {
            _scoreControl ctrlSetText format ["ROUND WINS  %1 / 2", _scores param [_index, 0]];
            _scoreControl ctrlCommit 0;
        };
        private _word = "CHOOSING";
        if (_phase in ["REVEAL", "FINISHED"]) then {
            _word = _revealed param [_index, ""];
            if (_word == "") then {_word = "NO REVEAL";};
        } else {
            if (_locked param [_index, false]) then {
                _word = if (!_spectating && {_role == _index} && {_localChoice != ""}) then {_localChoice} else {"LOCKED"};
            };
        };
        if (!isNull _choiceControl) then {
            _choiceControl ctrlSetText _word;
            _choiceControl ctrlSetTextColor (if (_word in ["LOCKED", "CHOOSING"]) then {[0.72, 0.78, 0.84, 1]} else {[1, 1, 1, 1]});
            _choiceControl ctrlCommit 0;
        };
        if (!isNull _panelControl) then {
            private _panelColour = if (_index == 0) then {[0.035, 0.125, 0.225, 1]} else {[0.235, 0.055, 0.055, 1]};
            if (_phase in ["REVEAL", "FINISHED"] && {_roundWinner == _index}) then {
                _panelColour = [0.075, 0.31, 0.15, 1];
            };
            _panelControl ctrlSetBackgroundColor _panelColour;
            _panelControl ctrlCommit 0;
        };
    };

    private _roundLabel = _display getVariable ["Waldo_MG_RPSRoundLabel", controlNull];
    private _phaseLabel = _display getVariable ["Waldo_MG_RPSPhaseLabel", controlNull];
    private _statusLabel = _display getVariable ["Waldo_MG_RPSStatusLabel", controlNull];
    private _instructionLabel = _display getVariable ["Waldo_MG_RPSInstructionLabel", controlNull];
    if (!isNull _roundLabel) then {
        _roundLabel ctrlSetText format ["ROUND %1  /  FIRST TO TWO", _round];
        _roundLabel ctrlCommit 0;
    };
    private _phaseText = "MAKE YOUR CHOICE";
    if (_phase == "COUNTDOWN") then {
        private _remaining = ceil (((_table getVariable ["Waldo_MG_RPSCountdownEnd", 0]) - serverTime) max 0);
        _phaseText = format ["REVEAL IN %1", _remaining];
    };
    if (_phase == "REVEAL") then {_phaseText = "REVEAL";};
    if (_phase == "FINISHED") then {_phaseText = "MATCH COMPLETE";};
    if (_phase == "CHOOSING" && {_spectating}) then {_phaseText = "PLAYERS ARE CHOOSING";};
    if (_phase == "CHOOSING" && {_role >= 0} && {_locked param [_role, false]}) then {_phaseText = "WAITING FOR OPPONENT";};
    if (!isNull _phaseLabel) then {
        _phaseLabel ctrlSetText _phaseText;
        _phaseLabel ctrlSetTextColor (if (_phase == "COUNTDOWN") then {[1, 0.82, 0.28, 1]} else {[0.88, 0.94, 1, 1]});
        _phaseLabel ctrlCommit 0;
    };
    if (!isNull _statusLabel) then {
        _statusLabel ctrlSetText (_table getVariable ["Waldo_MG_RPSStatus", "Rock Paper Scissors in progress."]);
        _statusLabel ctrlCommit 0;
    };
    if (!isNull _instructionLabel) then {
        _instructionLabel ctrlSetText (if (_spectating) then {
            "Spectator view keeps both choices hidden until the shared reveal."
        } else {
            if (_phase == "CHOOSING") then {"Choose once. Your opponent sees only LOCKED until the countdown ends."} else {"Rock beats Scissors. Scissors beats Paper. Paper beats Rock."}
        });
        _instructionLabel ctrlCommit 0;
    };

    private _choiceButtons = _display getVariable ["Waldo_MG_RPSChoiceButtons", []];
    private _canChoose = !_spectating
        && {_role >= 0}
        && {!_finished}
        && {_phase == "CHOOSING"}
        && {!(_locked param [_role, false])};
    {
        if (!isNull _x) then {
            _x ctrlShow !_spectating;
            _x ctrlEnable _canChoose;
            _x ctrlCommit 0;
        };
    } forEach _choiceButtons;
    private _resetButton = _display getVariable ["Waldo_MG_RPSResetButton", controlNull];
    if (!isNull _resetButton) then {
        _resetButton ctrlShow (!_spectating && {_finished});
        _resetButton ctrlEnable (!_spectating && {_finished} && {_winner >= 0});
        _resetButton ctrlCommit 0;
    };
    _display setVariable ["Waldo_MG_RPSRefreshing", false];
};

Waldo_MG_fnc_openRPSLocal = {
    disableSerialization;
    params [
        ["_table", objNull],
        ["_spectating", false]
    ];
    if (!hasInterface || {isNull player}) exitWith {};
    if (
        isNull _table
        || {!([_table, _spectating] call Waldo_MG_fnc_isValidGameViewerLocal)}
        || {([_table] call Waldo_MG_fnc_getTableActiveGameId) != "rps"}
    ) exitWith {
        ["No active Rock Paper Scissors match is available to this viewer."] call Waldo_MG_fnc_notifyLocal;
    };
    private _parent = findDisplay 46;
    if (isNull _parent) exitWith {
        ["The Rock Paper Scissors display is unavailable."] call Waldo_MG_fnc_notifyLocal;
    };
    {
        if (!isNull _x) then {_x closeDisplay 1;};
    } forEach [
        uiNamespace getVariable ["Waldo_MG_LobbyDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_BattleshipDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_WhosWhoDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_ShotgunDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_RPSDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_BlackjackDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_CheckersDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_ChessDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_PokerDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_UNODisplay", displayNull]
    ];
    private _display = _parent createDisplay "RscDisplayEmpty";
    if (isNull _display) exitWith {};
    uiNamespace setVariable ["Waldo_MG_RPSDisplay", _display];
    _display setVariable ["Waldo_MG_RPSTable", _table];
    _display setVariable ["Waldo_MG_SpectatorMode", _spectating];
    _display setVariable ["Waldo_MG_RPSLastEpoch", -1];
    _display setVariable ["Waldo_MG_RPSLocalChoice", ""];
    [_display] call Waldo_MG_fnc_installEscapeGuardLocal;

    private _background = _display ctrlCreate ["RscText", -1];
    _background ctrlSetPosition [0.015, 0.020, 1.15, 1.04];
    _background ctrlSetBackgroundColor [0.012, 0.016, 0.026, 0.985];
    _background ctrlCommit 0;
    private _topBar = _display ctrlCreate ["RscText", -1];
    _topBar ctrlSetPosition [0.015, 0.020, 1.15, 0.075];
    _topBar ctrlSetBackgroundColor [0.22, 0.11, 0.36, 1];
    _topBar ctrlCommit 0;
    private _title = _display ctrlCreate ["RscText", -1];
    _title ctrlSetPosition [0.045, 0.031, 0.60, 0.050];
    _title ctrlSetText "PARTYGAMES  /  ROCK PAPER SCISSORS";
    _title ctrlSetTextColor [0.94, 0.88, 1, 1];
    _title ctrlSetFontHeight 0.034;
    _title ctrlCommit 0;
    private _roundLabel = _display ctrlCreate ["RscText", -1];
    _roundLabel ctrlSetPosition [0.735, 0.036, 0.385, 0.038];
    _roundLabel ctrlSetTextColor [0.76, 0.84, 0.94, 1];
    _roundLabel ctrlSetFontHeight 0.024;
    _roundLabel ctrlCommit 0;

    private _panelControls = [];
    private _nameControls = [];
    private _scoreControls = [];
    private _choiceControls = [];
    private _panelData = [
        [0.045, [0.035, 0.125, 0.225, 1], [0.30, 0.72, 1, 1]],
        [0.625, [0.235, 0.055, 0.055, 1], [1, 0.38, 0.32, 1]]
    ];
    {
        private _left = _x param [0, 0.045];
        private _panel = _display ctrlCreate ["RscText", -1];
        _panel ctrlSetPosition [_left, 0.130, 0.510, 0.465];
        _panel ctrlSetBackgroundColor (_x param [1, [0.05, 0.05, 0.08, 1]]);
        _panel ctrlCommit 0;
        _panelControls pushBack _panel;
        private _nameLabel = _display ctrlCreate ["RscText", -1];
        _nameLabel ctrlSetPosition [_left + 0.025, 0.155, 0.460, 0.055];
        _nameLabel ctrlSetTextColor (_x param [2, [1, 1, 1, 1]]);
        _nameLabel ctrlSetFontHeight 0.031;
        _nameLabel ctrlCommit 0;
        _nameControls pushBack _nameLabel;
        private _scoreLabel = _display ctrlCreate ["RscText", -1];
        _scoreLabel ctrlSetPosition [_left + 0.025, 0.215, 0.460, 0.040];
        _scoreLabel ctrlSetTextColor [0.78, 0.84, 0.90, 1];
        _scoreLabel ctrlSetFontHeight 0.022;
        _scoreLabel ctrlCommit 0;
        _scoreControls pushBack _scoreLabel;
        private _choiceLabel = _display ctrlCreate ["RscText", -1];
        _choiceLabel ctrlSetPosition [_left + 0.025, 0.330, 0.460, 0.150];
        _choiceLabel ctrlSetTextColor [1, 1, 1, 1];
        _choiceLabel ctrlSetFontHeight 0.070;
        _choiceLabel ctrlCommit 0;
        _choiceControls pushBack _choiceLabel;
    } forEach _panelData;

    private _phaseLabel = _display ctrlCreate ["RscText", -1];
    _phaseLabel ctrlSetPosition [0.270, 0.615, 0.670, 0.070];
    _phaseLabel ctrlSetTextColor [0.88, 0.94, 1, 1];
    _phaseLabel ctrlSetFontHeight 0.045;
    _phaseLabel ctrlCommit 0;
    private _statusLabel = _display ctrlCreate ["RscText", -1];
    _statusLabel ctrlSetPosition [0.085, 0.680, 1.020, 0.045];
    _statusLabel ctrlSetTextColor [0.72, 0.82, 0.92, 1];
    _statusLabel ctrlSetFontHeight 0.024;
    _statusLabel ctrlCommit 0;

    private _choiceButtons = [];
    private _choiceData = [
        ["ROCK", 0.145, [0.18, 0.25, 0.34, 1]],
        ["PAPER", 0.455, [0.22, 0.18, 0.34, 1]],
        ["SCISSORS", 0.765, [0.34, 0.17, 0.18, 1]]
    ];
    {
        private _button = _display ctrlCreate ["RscButtonMenu", -1];
        _button ctrlSetPosition [_x param [1, 0.1], 0.750, 0.270, 0.085];
        _button ctrlSetText (_x param [0, "CHOICE"]);
        _button ctrlSetBackgroundColor (_x param [2, [0.2, 0.2, 0.2, 1]]);
        _button ctrlSetFontHeight 0.033;
        _button setVariable ["Waldo_MG_RPSChoice", _x param [0, ""]];
        _button ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_handleRPSChoiceClickLocal;}];
        _button ctrlCommit 0;
        _choiceButtons pushBack _button;
    } forEach _choiceData;
    private _instructionLabel = _display ctrlCreate ["RscText", -1];
    _instructionLabel ctrlSetPosition [0.085, 0.850, 1.020, 0.045];
    _instructionLabel ctrlSetTextColor [0.82, 0.84, 0.90, 1];
    _instructionLabel ctrlSetFontHeight 0.022;
    _instructionLabel ctrlCommit 0;
    private _rulesLabel = _display ctrlCreate ["RscText", -1];
    _rulesLabel ctrlSetPosition [0.085, 0.900, 1.020, 0.040];
    _rulesLabel ctrlSetText "ROCK BEATS SCISSORS    /    SCISSORS BEATS PAPER    /    PAPER BEATS ROCK";
    _rulesLabel ctrlSetTextColor [0.58, 0.68, 0.78, 1];
    _rulesLabel ctrlSetFontHeight 0.020;
    _rulesLabel ctrlCommit 0;
    private _footer = _display ctrlCreate ["RscText", -1];
    _footer ctrlSetPosition [0.045, 0.960, 1.070, 0.070];
    _footer ctrlSetBackgroundColor [0.025, 0.035, 0.055, 1];
    _footer ctrlCommit 0;
    private _exitButton = _display ctrlCreate ["RscButtonMenu", -1];
    _exitButton ctrlSetPosition [0.740, 0.970, 0.180, 0.050];
    _exitButton ctrlSetText (if (_spectating) then {"Exit Spectate"} else {"Leave Table"});
    _exitButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_handleViewerExitButtonLocal;}];
    _exitButton ctrlCommit 0;
    private _resetButton = _display ctrlCreate ["RscButtonMenu", -1];
    _resetButton ctrlSetPosition [0.935, 0.970, 0.165, 0.050];
    _resetButton ctrlSetText "Return to Lobby";
    _resetButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_handleRPSResetClickLocal;}];
    _resetButton ctrlCommit 0;

    _display setVariable ["Waldo_MG_RPSPanelControls", _panelControls];
    _display setVariable ["Waldo_MG_RPSNameControls", _nameControls];
    _display setVariable ["Waldo_MG_RPSScoreControls", _scoreControls];
    _display setVariable ["Waldo_MG_RPSChoiceControls", _choiceControls];
    _display setVariable ["Waldo_MG_RPSChoiceButtons", _choiceButtons];
    _display setVariable ["Waldo_MG_RPSRoundLabel", _roundLabel];
    _display setVariable ["Waldo_MG_RPSPhaseLabel", _phaseLabel];
    _display setVariable ["Waldo_MG_RPSStatusLabel", _statusLabel];
    _display setVariable ["Waldo_MG_RPSInstructionLabel", _instructionLabel];
    _display setVariable ["Waldo_MG_RPSResetButton", _resetButton];
    [_display] call Waldo_MG_fnc_refreshRPSLocal;
    [_display] spawn {
        disableSerialization;
        params ["_activeDisplay"];
        while {!isNull _activeDisplay} do {
            [_activeDisplay] call Waldo_MG_fnc_refreshRPSLocal;
            uiSleep Waldo_MG_CFG_RPS_UI_TICK;
        };
    };
};

