/*
 * Author: WaldoTheWarfighter
 * Waldos Mini Games - Battleship
 * All Waldo_MG_fnc_* functions implementing the Battleship mini game (server logic + local UI).
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

Waldo_MG_fnc_battleshipShipName = {
    params [["_shipIndex", -1]];
    (Waldo_MG_CFG_BATTLESHIP_SHIPS param [_shipIndex, ["Ship", 0]]) param [0, "Ship"]
};

Waldo_MG_fnc_battleshipShipLength = {
    params [["_shipIndex", -1]];
    (Waldo_MG_CFG_BATTLESHIP_SHIPS param [_shipIndex, ["Ship", 0]]) param [1, 0]
};

Waldo_MG_fnc_battleshipCellLabel = {
    params [["_cell", -1]];
    private _grid = Waldo_MG_CFG_BATTLESHIP_GRID_SIZE;
    if ((typeName _cell) != "SCALAR" || {_cell != floor _cell} || {_cell < 0} || {_cell >= (_grid * _grid)}) exitWith {"?"};
    private _letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"];
    format ["%1%2", _letters param [_cell mod _grid, "?"], (floor (_cell / _grid)) + 1]
};

Waldo_MG_fnc_battleshipCreateEmptyFleet = {
    private _fleet = [];
    {
        _fleet pushBack [];
    } forEach Waldo_MG_CFG_BATTLESHIP_SHIPS;
    _fleet
};

Waldo_MG_fnc_battleshipCopyFleet = {
    params [["_fleet", []]];
    private _copy = [];
    {
        _copy pushBack (+_x);
    } forEach _fleet;
    _copy
};

Waldo_MG_fnc_battleshipCopyFleets = {
    params [["_fleets", []]];
    private _copy = [];
    {
        _copy pushBack ([_x] call Waldo_MG_fnc_battleshipCopyFleet);
    } forEach _fleets;
    _copy
};

Waldo_MG_fnc_battleshipGetPlacementCells = {
    params [
        ["_origin", -1],
        ["_length", 0],
        ["_orientation", 0]
    ];
    private _grid = Waldo_MG_CFG_BATTLESHIP_GRID_SIZE;
    if (
        (typeName _origin) != "SCALAR"
        || {(typeName _length) != "SCALAR"}
        || {(typeName _orientation) != "SCALAR"}
        || {_origin != floor _origin}
        || {_origin < 0}
        || {_origin >= (_grid * _grid)}
        || {_length != floor _length}
        || {_length <= 0}
        || {!(_orientation in [0, 1])}
    ) exitWith {[]};
    private _row = floor (_origin / _grid);
    private _column = _origin mod _grid;
    if (_orientation == 0 && {(_column + _length) > _grid}) exitWith {[]};
    if (_orientation == 1 && {(_row + _length) > _grid}) exitWith {[]};
    private _cells = [];
    for "_offset" from 0 to (_length - 1) do {
        _cells pushBack (_origin + (if (_orientation == 0) then {_offset} else {_offset * _grid}));
    };
    _cells
};

Waldo_MG_fnc_battleshipFleetComplete = {
    params [["_fleet", []]];
    if ((count _fleet) != (count Waldo_MG_CFG_BATTLESHIP_SHIPS)) exitWith {false};
    private _complete = true;
    for "_shipIndex" from 0 to ((count Waldo_MG_CFG_BATTLESHIP_SHIPS) - 1) do {
        if ((count (_fleet param [_shipIndex, []])) != ([_shipIndex] call Waldo_MG_fnc_battleshipShipLength)) then {
            _complete = false;
        };
    };
    _complete
}; 
 

Waldo_MG_fnc_battleshipCreateEmptySnapshot = {
    [
        "IDLE", -1, [false, false], [[], []], [5, 5], [[], []], -1,
        "Waiting for a Battleship match.", [-1, -1, -1, "", -1],
        ["Waiting", "Waiting"], 0, [0, 0], [[], []]
    ]
};

Waldo_MG_fnc_battleshipPublishRevisionServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    [_table, "Waldo_MG_BattleshipRevision", (_table getVariable ["Waldo_MG_BattleshipRevision", 0]) + 1] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_TableRevision", (_table getVariable ["Waldo_MG_TableRevision", 0]) + 1] call Waldo_MG_fnc_setPublicTableStateServer;
};

Waldo_MG_fnc_battleshipSetSnapshotServer = {
    params [["_table", objNull], ["_snapshot", []]];
    if (!isServer || {isNull _table}) exitWith {};
    _table setVariable ["Waldo_MG_BattleshipSnapshotServer", _snapshot];
    [_table, "Waldo_MG_BattleshipSnapshot", _snapshot] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table] call Waldo_MG_fnc_battleshipPublishRevisionServer;
};

Waldo_MG_fnc_battleshipSendPrivateFleetServer = {
    params [["_table", objNull], ["_role", -1]];
    if (!isServer || {isNull _table} || {_role < 0} || {_role > 1}) exitWith {};
    private _players = _table getVariable ["Waldo_MG_BattleshipPlayers", []];
    private _unit = _players param [_role, objNull];
    if (isNull _unit) exitWith {};
    private _fleets = _table getVariable ["Waldo_MG_BattleshipFleetsServer", []];
    private _fleet = [(_fleets param [_role, []])] call Waldo_MG_fnc_battleshipCopyFleet;
    private _snapshot = _table getVariable ["Waldo_MG_BattleshipSnapshotServer", []];
    private _versions = _snapshot param [11, [0, 0]];
    _unit setVariable [
        "Waldo_MG_BattleshipPrivateFleet",
        [_table getVariable ["Waldo_MG_BattleshipGameId", ""], _versions param [_role, -1], _fleet],
        owner _unit
    ];
};

Waldo_MG_fnc_battleshipClearServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    {
        if (!isNull _x) then {_x setVariable ["Waldo_MG_BattleshipPrivateFleet", [], owner _x];};
    } forEach (_table getVariable ["Waldo_MG_BattleshipPlayers", []]);
    [_table, "Waldo_MG_BattleshipActive", false] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BattleshipFinished", false] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BattleshipGameId", ""] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BattleshipPlayers", []] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BattleshipPlayerNames", []] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BattleshipSeatIndices", []] call Waldo_MG_fnc_setPublicTableStateServer;
    _table setVariable ["Waldo_MG_BattleshipFleetsServer", []];
    [_table, "Waldo_MG_BattleshipRevision", 0] call Waldo_MG_fnc_setPublicTableStateServer;
    private _empty = call Waldo_MG_fnc_battleshipCreateEmptySnapshot;
    _table setVariable ["Waldo_MG_BattleshipSnapshotServer", _empty];
    [_table, "Waldo_MG_BattleshipSnapshot", _empty] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table] call Waldo_MG_fnc_battleshipPublishRevisionServer;
};

Waldo_MG_fnc_battleshipStartServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {false};
    if ([_table] call Waldo_MG_fnc_isTableGameActive) exitWith {false};
    if ((_table getVariable ["Waldo_MG_TableSelectedGame", ""]) != "battleship") exitWith {false};
    if ((_table getVariable ["Waldo_MG_TablePhase", "LOBBY"]) != "READY") exitWith {false};
    private _seats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
    private _players = [];
    private _names = [];
    private _seatIndices = [];
    for "_seat" from 0 to (Waldo_MG_CFG_SEAT_COUNT - 1) do {
        private _unit = _seats param [_seat, objNull];
        if (!isNull _unit) then {
            _players pushBack _unit;
            _names pushBack (name _unit);
            _seatIndices pushBack _seat;
        };
    };
    if ((count _players) != 2) exitWith {false};
    private _snapshot = [
        "PLACEMENT", -1, [false, false], [[], []], [5, 5], [[], []], -1,
        "Both commanders are deploying five private ships.", [-1, -1, -1, "", -1],
        ["Deploying fleet", "Deploying fleet"], 0, [0, 0], [[], []]
    ];
    [_table, "Waldo_MG_BattleshipActive", true] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BattleshipFinished", false] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BattleshipGameId", format ["Waldo_MG_BATTLESHIP_%1_%2", floor (serverTime * 10), floor (random 1000000)]] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BattleshipPlayers", _players] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BattleshipPlayerNames", _names] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BattleshipSeatIndices", _seatIndices] call Waldo_MG_fnc_setPublicTableStateServer;
    _table setVariable ["Waldo_MG_BattleshipFleetsServer", [call Waldo_MG_fnc_battleshipCreateEmptyFleet, call Waldo_MG_fnc_battleshipCreateEmptyFleet]];
    [_table, "Waldo_MG_BattleshipRevision", 0] call Waldo_MG_fnc_setPublicTableStateServer;
    _table setVariable ["Waldo_MG_TablePhase", "PLAYING",true];
    [_table, _snapshot] call Waldo_MG_fnc_battleshipSetSnapshotServer;
    [_table, 0] call Waldo_MG_fnc_battleshipSendPrivateFleetServer;
    [_table, 1] call Waldo_MG_fnc_battleshipSendPrivateFleetServer;
    true
};

Waldo_MG_fnc_battleshipFinishServer = {
    params [
        ["_table", objNull],
        ["_snapshot", []],
        ["_winner", -1],
        ["_message", "Battleship is finished."]
    ];
    if (!isServer || {isNull _table}) exitWith {};
    private _state = +_snapshot;
    _state set [0, "FINISHED"];
    _state set [1, -1];
    _state set [6, _winner];
    _state set [7, _message];
    _state set [12, [(_table getVariable ["Waldo_MG_BattleshipFleetsServer", []])] call Waldo_MG_fnc_battleshipCopyFleets];
    [_table, "Waldo_MG_BattleshipFinished", true] call Waldo_MG_fnc_setPublicTableStateServer;
    _table setVariable ["Waldo_MG_TablePhase", "FINISHED",true];
    [_table, _state] call Waldo_MG_fnc_battleshipSetSnapshotServer;
};

Waldo_MG_fnc_battleshipResetServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    [_table] call Waldo_MG_fnc_battleshipClearServer;
    [_table, "Waldo_MG_TableReady", [false, false, false, false]] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table] call Waldo_MG_fnc_refreshTableConsensusServer;
};

Waldo_MG_fnc_battleshipHandleDepartureServer = {
    params [["_table", objNull], ["_unit", objNull], ["_seatIndex", -1]];
    if (!isServer || {isNull _table} || {!(_table getVariable ["Waldo_MG_BattleshipActive", false])}) exitWith {};
    private _players = _table getVariable ["Waldo_MG_BattleshipPlayers", []];
    private _seatIndices = _table getVariable ["Waldo_MG_BattleshipSeatIndices", []];
    private _role = if (isNull _unit) then {-1} else {_players find _unit};
    if (_role < 0 && {_seatIndex >= 0}) then {_role = _seatIndices find _seatIndex;};
    if (_role < 0) exitWith {};
    private _other = 1 - _role;
    private _state = +(_table getVariable ["Waldo_MG_BattleshipSnapshotServer", []]);
    private _seats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
    private _otherSeat = _seatIndices param [_other, -1];
    private _otherUnit = _players param [_other, objNull];
    private _otherValid = !isNull _otherUnit
        && {_otherSeat >= 0}
        && {_otherSeat < Waldo_MG_CFG_SEAT_COUNT}
        && {(_seats param [_otherSeat, objNull]) == _otherUnit}
        && {_otherUnit in allPlayers}
        && {alive _otherUnit}
        && {(lifeState _otherUnit) != "INCAPACITATED"};
    if (!_otherValid) exitWith {
        [_table] call Waldo_MG_fnc_battleshipClearServer;
        [_table, "Waldo_MG_TableReady", [false, false, false, false]] call Waldo_MG_fnc_setPublicTableStateServer;
        _table setVariable ["Waldo_MG_TablePhase", "LOBBY",true];
        [_table] call Waldo_MG_fnc_refreshTableConsensusServer;
    };
    if ((_state param [0, ""]) == "FINISHED") exitWith {};
    private _names = _table getVariable ["Waldo_MG_BattleshipPlayerNames", []];
    [_table, _state, _other, format ["%1 wins by forfeit after %2 leaves the table.", _names param [_other, "Player"], _names param [_role, "Player"]]] call Waldo_MG_fnc_battleshipFinishServer;
};

Waldo_MG_fnc_battleshipReconcilePlayersServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table} || {!(_table getVariable ["Waldo_MG_BattleshipActive", false])}) exitWith {};
    private _players = _table getVariable ["Waldo_MG_BattleshipPlayers", []];
    private _seatIndices = _table getVariable ["Waldo_MG_BattleshipSeatIndices", []];
    private _seats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
    for "_role" from 0 to 1 do {
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
            [_table, _unit, _seat] call Waldo_MG_fnc_battleshipHandleDepartureServer;
        };
    };
}; 
 

Waldo_MG_fnc_processBattleshipActionRequestServer = {
    params [["_unit", objNull], ["_request", []]];
    if (!isServer || {isNull _unit}) exitWith {};
    if ((count _request) < 6) exitWith {};
    private _token = _request param [0, ""];
    if (!([_token] call Waldo_MG_fnc_rememberHandledTokenServer)) exitWith {};
    private _tableNetId = _request param [1, ""];
    private _gameId = _request param [2, ""];
    private _expectedRevision = _request param [3, -1];
    private _action = _request param [4, ""];
    private _payload = _request param [5, []];
    if ((typeName _tableNetId) != "STRING" || {(typeName _gameId) != "STRING"} || {(typeName _expectedRevision) != "SCALAR"} || {(typeName _action) != "STRING"}) exitWith {
        [_unit, _token, "Battleship action rejected: malformed request data."] call Waldo_MG_fnc_resultServer;
    };
    private _table = objectFromNetId _tableNetId;
    if (isNull _table || {_table != (_unit getVariable ["Waldo_MG_SeatedTable", objNull])}) exitWith {
        [_unit, _token, "Battleship action rejected: you are no longer seated at that table."] call Waldo_MG_fnc_resultServer;
    };
    if (!(_table getVariable ["Waldo_MG_BattleshipActive", false])) exitWith {
        [_unit, _token, "There is no active Battleship match at this table."] call Waldo_MG_fnc_resultServer;
    };
    if (_gameId == "" || {_gameId != (_table getVariable ["Waldo_MG_BattleshipGameId", ""])}) exitWith {
        [_unit, _token, "That Battleship match is no longer current."] call Waldo_MG_fnc_resultServer;
    };
    private _players = _table getVariable ["Waldo_MG_BattleshipPlayers", []];
    private _role = _players find _unit;
    if (_role < 0) exitWith {
        [_unit, _token, "Only the two assigned commanders may act in Battleship."] call Waldo_MG_fnc_resultServer;
    };
    if (_action == "SYNC") exitWith {
        [_table, _role] call Waldo_MG_fnc_battleshipSendPrivateFleetServer;
        [_unit, _token, "Your private Battleship fleet was synchronized."] call Waldo_MG_fnc_resultServer;
    };
    private _state = +(_table getVariable ["Waldo_MG_BattleshipSnapshotServer", []]);
    private _phase = _state param [0, "IDLE"];
    if (_action == "RESET") exitWith {
        if (_phase != "FINISHED") then {
            [_unit, _token, "Finish the battle before returning to the lobby."] call Waldo_MG_fnc_resultServer;
        } else {
            [_table] call Waldo_MG_fnc_battleshipResetServer;
            [_unit, _token, "Battleship cleared. The table has returned to its lobby."] call Waldo_MG_fnc_resultServer;
        };
    };

    private _names = _table getVariable ["Waldo_MG_BattleshipPlayerNames", []];
    if (_phase == "PLACEMENT") exitWith {
        private _ready = +(_state param [2, [false, false]]);
        private _actions = +(_state param [9, ["Deploying fleet", "Deploying fleet"]]);
        private _versions = +(_state param [11, [0, 0]]);
        private _fleets = [(_table getVariable ["Waldo_MG_BattleshipFleetsServer", []])] call Waldo_MG_fnc_battleshipCopyFleets;
        private _fleet = [(_fleets param [_role, []])] call Waldo_MG_fnc_battleshipCopyFleet;

        if (_action == "UNREADY") exitWith {
            if (!(_ready param [_role, false])) then {
                [_unit, _token, "Your fleet is already unlocked."] call Waldo_MG_fnc_resultServer;
            } else {
                _ready set [_role, false];
                _actions set [_role, "Fleet unlocked for changes"];
                _state set [2, _ready];
                _state set [7, format ["%1 unlocked their fleet and may reposition ships.", _names param [_role, "Player"]]];
                _state set [9, _actions];
                [_table, _state] call Waldo_MG_fnc_battleshipSetSnapshotServer;
                [_unit, _token, "Fleet unlocked."] call Waldo_MG_fnc_resultServer;
            };
        };
        if (_ready param [_role, false]) exitWith {
            [_unit, _token, "Unlock your fleet before changing any ship placement."] call Waldo_MG_fnc_resultServer;
        };

        if (_action == "CLEAR") exitWith {
            _fleet = call Waldo_MG_fnc_battleshipCreateEmptyFleet;
            _fleets set [_role, _fleet];
            _versions set [_role, (_versions param [_role, 0]) + 1];
            _actions set [_role, "Cleared all ship placements"];
            _state set [2, _ready];
            _state set [7, format ["%1 cleared their private fleet and is redeploying.", _names param [_role, "Player"]]];
            _state set [9, _actions];
            _state set [11, _versions];
            _table setVariable ["Waldo_MG_BattleshipFleetsServer", _fleets];
            [_table, _state] call Waldo_MG_fnc_battleshipSetSnapshotServer;
            [_table, _role] call Waldo_MG_fnc_battleshipSendPrivateFleetServer;
            [_unit, _token, "All ship placements cleared."] call Waldo_MG_fnc_resultServer;
        };

        if (_action == "READY") exitWith {
            if (!([_fleet] call Waldo_MG_fnc_battleshipFleetComplete)) then {
                [_unit, _token, "Place all five ships before locking your fleet."] call Waldo_MG_fnc_resultServer;
            } else {
                _ready set [_role, true];
                _actions set [_role, "Fleet locked and ready"];
                _state set [2, _ready];
                _state set [9, _actions];
                if ((_ready param [0, false]) && {_ready param [1, false]}) then {
                    private _actor = floor (random 2);
                    _state set [0, "PLAYING"];
                    _state set [1, _actor];
                    _state set [7, format ["Both fleets are locked. %1 has the first shot.", _names param [_actor, "Player"]]];
                    _actions set [0, "Fleet deployed"];
                    _actions set [1, "Fleet deployed"];
                    _state set [9, _actions];
                } else {
                    _state set [7, format ["%1 locked their fleet. Waiting for the opposing commander.", _names param [_role, "Player"]]];
                };
                [_table, _state] call Waldo_MG_fnc_battleshipSetSnapshotServer;
                [_unit, _token, if ((_state param [0, ""]) == "PLAYING") then {"Both fleets locked. The battle has begun."} else {"Fleet locked. Waiting for your opponent."}] call Waldo_MG_fnc_resultServer;
            };
        };

        if (_action != "PLACE") exitWith {
            [_unit, _token, "Unknown Battleship placement action."] call Waldo_MG_fnc_resultServer;
        };
        if ((typeName _payload) != "ARRAY" || {(count _payload) < 3}) exitWith {
            [_unit, _token, "Choose a ship, orientation, and valid origin cell."] call Waldo_MG_fnc_resultServer;
        };
        private _shipIndex = _payload param [0, -1];
        private _origin = _payload param [1, -1];
        private _orientation = _payload param [2, -1];
        if (
            (typeName _shipIndex) != "SCALAR"
            || {(typeName _origin) != "SCALAR"}
            || {(typeName _orientation) != "SCALAR"}
            || {_shipIndex != floor _shipIndex}
            || {_shipIndex < 0}
            || {_shipIndex >= (count Waldo_MG_CFG_BATTLESHIP_SHIPS)}
            || {_orientation != floor _orientation}
            || {!(_orientation in [0, 1])}
        ) exitWith {
            [_unit, _token, "Battleship placement rejected: malformed ship data."] call Waldo_MG_fnc_resultServer;
        };
        private _cells = [_origin, [_shipIndex] call Waldo_MG_fnc_battleshipShipLength, _orientation] call Waldo_MG_fnc_battleshipGetPlacementCells;
        if ((count _cells) <= 0) exitWith {
            [_unit, _token, "That ship would extend beyond the 10x10 grid."] call Waldo_MG_fnc_resultServer;
        };
        private _occupied = [];
        for "_otherShip" from 0 to ((count Waldo_MG_CFG_BATTLESHIP_SHIPS) - 1) do {
            if (_otherShip != _shipIndex) then {
                {_occupied pushBackUnique _x;} forEach (_fleet param [_otherShip, []]);
            };
        };
        private _overlap = false;
        {
            if (_x in _occupied) then {_overlap = true;};
        } forEach _cells;
        if (_overlap) exitWith {
            [_unit, _token, "Ships may not overlap one another."] call Waldo_MG_fnc_resultServer;
        };
        _fleet set [_shipIndex, _cells];
        _fleets set [_role, _fleet];
        _versions set [_role, (_versions param [_role, 0]) + 1];
        private _shipName = [_shipIndex] call Waldo_MG_fnc_battleshipShipName;
        private _orientationName = if (_orientation == 0) then {"horizontal"} else {"vertical"};
        _actions set [_role, format ["Placed %1", _shipName]];
        _state set [7, format ["%1 positioned a private %2.", _names param [_role, "Player"], _shipName]];
        _state set [9, _actions];
        _state set [11, _versions];
        _table setVariable ["Waldo_MG_BattleshipFleetsServer", _fleets];
        [_table, _state] call Waldo_MG_fnc_battleshipSetSnapshotServer;
        [_table, _role] call Waldo_MG_fnc_battleshipSendPrivateFleetServer;
        [_unit, _token, format ["%1 placed %2 from %3.", _shipName, _orientationName, [_origin] call Waldo_MG_fnc_battleshipCellLabel]] call Waldo_MG_fnc_resultServer;
    };

    if (_phase != "PLAYING") exitWith {
        [_unit, _token, "Battleship is not accepting combat actions now."] call Waldo_MG_fnc_resultServer;
    };
    if (_expectedRevision != (_table getVariable ["Waldo_MG_BattleshipRevision", -1])) exitWith {
        [_unit, _token, "The Battleship turn changed before that shot arrived."] call Waldo_MG_fnc_resultServer;
    };
    if ((_state param [1, -1]) != _role) exitWith {
        [_unit, _token, "Wait for your Battleship turn."] call Waldo_MG_fnc_resultServer;
    };
    if (_action != "FIRE" || {(typeName _payload) != "SCALAR"} || {_payload != floor _payload} || {_payload < 0} || {_payload >= (Waldo_MG_CFG_BATTLESHIP_GRID_SIZE * Waldo_MG_CFG_BATTLESHIP_GRID_SIZE)}) exitWith {
        [_unit, _token, "Choose an unfired coordinate on the opposing grid."] call Waldo_MG_fnc_resultServer;
    };
    private _cell = floor _payload;
    private _target = 1 - _role;
    private _shots = [];
    {
        _shots pushBack (+_x);
    } forEach (_state param [3, [[], []]]);
    private _roleShots = +(_shots param [_role, []]);
    private _alreadyFired = false;
    {
        if ((_x param [0, -1]) == _cell) then {_alreadyFired = true;};
    } forEach _roleShots;
    if (_alreadyFired) exitWith {
        [_unit, _token, format ["You already fired at %1.", [_cell] call Waldo_MG_fnc_battleshipCellLabel]] call Waldo_MG_fnc_resultServer;
    };
    private _fleets = _table getVariable ["Waldo_MG_BattleshipFleetsServer", []];
    private _targetFleet = _fleets param [_target, []];
    private _hitShipIndex = -1;
    private _hitShipCells = [];
    for "_shipIndex" from 0 to ((count Waldo_MG_CFG_BATTLESHIP_SHIPS) - 1) do {
        private _shipCells = _targetFleet param [_shipIndex, []];
        if (_hitShipIndex < 0 && {_cell in _shipCells}) then {
            _hitShipIndex = _shipIndex;
            _hitShipCells = +_shipCells;
        };
    };
    private _result = if (_hitShipIndex >= 0) then {"HIT"} else {"MISS"};
    _roleShots pushBack [_cell, _result];
    private _sunk = false;
    if (_hitShipIndex >= 0) then {
        private _shotCells = [];
        {
            _shotCells pushBackUnique (_x param [0, -1]);
        } forEach _roleShots;
        _sunk = true;
        {
            if (!(_x in _shotCells)) then {_sunk = false;};
        } forEach _hitShipCells;
        if (_sunk) then {
            _result = "SUNK";
            _roleShots set [(count _roleShots) - 1, [_cell, _result]];
        };
    };
    _shots set [_role, _roleShots];
    private _remaining = +(_state param [4, [5, 5]]);
    private _sunkByOwner = [];
    {
        private _ownerSunk = [];
        {
            _ownerSunk pushBack [_x param [0, -1], +(_x param [1, []])];
        } forEach _x;
        _sunkByOwner pushBack _ownerSunk;
    } forEach (_state param [5, [[], []]]);
    if (_sunk) then {
        private _targetSunk = +(_sunkByOwner param [_target, []]);
        _targetSunk pushBack [_hitShipIndex, _hitShipCells];
        _sunkByOwner set [_target, _targetSunk];
        _remaining set [_target, 0 max ((_remaining param [_target, 5]) - 1)];
    };
    private _coordinate = [_cell] call Waldo_MG_fnc_battleshipCellLabel;
    private _actions = +(_state param [9, ["Waiting", "Waiting"]]);
    private _resultText = if (_result == "MISS") then {"MISS"} else {if (_result == "HIT") then {"HIT"} else {format ["SUNK %1", [_hitShipIndex] call Waldo_MG_fnc_battleshipShipName]}};
    _actions set [_role, format ["%1 at %2", _resultText, _coordinate]];
    _state set [3, _shots];
    _state set [4, _remaining];
    _state set [5, _sunkByOwner];
    _state set [8, [_role, _target, _cell, _result, if (_sunk) then {_hitShipIndex} else {-1}]];
    _state set [9, _actions];
    _state set [10, (_state param [10, 0]) + 1];
    if ((_remaining param [_target, 0]) <= 0) then {
        private _message = format ["%1 sank the final ship at %2 and wins Battleship! Both fleets are revealed.", _names param [_role, "Player"], _coordinate];
        [_table, _state, _role, _message] call Waldo_MG_fnc_battleshipFinishServer;
        [_unit, _token, format ["%1. Enemy fleet destroyed.", _resultText]] call Waldo_MG_fnc_resultServer;
    } else {
        _state set [1, _target];
        _state set [7, format ["%1 fires at %2: %3. %4 now has the shot.", _names param [_role, "Player"], _coordinate, _resultText, _names param [_target, "Player"]]];
        [_table, _state] call Waldo_MG_fnc_battleshipSetSnapshotServer;
        [_unit, _token, format ["%1: %2.", _coordinate, _resultText]] call Waldo_MG_fnc_resultServer;
    };
};

Waldo_MG_fnc_submitBattleshipActionRequestLocal = {
    params [["_table", objNull], ["_action", ""], ["_payload", []]];
    if (!hasInterface || {isNull player} || {isNull _table} || {_action == ""}) exitWith {false};
    private _pending = missionNamespace getVariable ["Waldo_MG_BattleshipPendingRequestLocal", []];
    if ((count _pending) >= 2 && {(diag_tickTime - (_pending param [1, -10])) < 1.5}) exitWith {
        ["Waiting for the table host to answer your previous Battleship action..."] call Waldo_MG_fnc_notifyLocal;
        false
    };
    private _token = ["BATTLESHIP_ACTION"] call Waldo_MG_fnc_makeToken;
    missionNamespace setVariable ["Waldo_MG_BattleshipPendingRequestLocal", [_token, diag_tickTime]];
    private _request = [
            _token,
            netId _table,
            _table getVariable ["Waldo_MG_BattleshipGameId", ""],
            _table getVariable ["Waldo_MG_BattleshipRevision", -1],
            _action,
            _payload
    ];
    ["BATTLESHIP", _table, _token, _request param [3, -1], _request] call Waldo_MG_fnc_submitRequestLocal;
    true
};

Waldo_MG_fnc_battleshipSafePositionLocal = {
    params [["_x", 0], ["_y", 0], ["_width", 0], ["_height", 0]];
    [
        safeZoneX + (safeZoneW * _x),
        safeZoneY + (safeZoneH * _y),
        safeZoneW * _width,
        safeZoneH * _height
    ]
};

Waldo_MG_fnc_getBattleshipPlayerRoleLocal = {
    params [["_table", objNull]];
    if (isNull _table || {isNull player}) exitWith {-1};
    (_table getVariable ["Waldo_MG_BattleshipPlayers", []]) find player
};

Waldo_MG_fnc_battleshipDefocusLocal = {
    disableSerialization;
    params [["_display", displayNull]];
    if (isNull _display) exitWith {};
    private _sink = _display getVariable ["Waldo_MG_BattleshipFocusSink", controlNull];
    if (!isNull _sink) then {ctrlSetFocus _sink;};
};

Waldo_MG_fnc_battleshipGetPlacementPreviewLocal = {
    params [
        ["_fleet", []],
        ["_shipIndex", -1],
        ["_origin", -1],
        ["_orientation", 0]
    ];
    private _length = [_shipIndex] call Waldo_MG_fnc_battleshipShipLength;
    private _grid = Waldo_MG_CFG_BATTLESHIP_GRID_SIZE;
    if (_length <= 0 || {_origin < 0} || {_origin >= (_grid * _grid)}) exitWith {[[], false]};
    private _strict = [_origin, _length, _orientation] call Waldo_MG_fnc_battleshipGetPlacementCells;
    private _preview = +_strict;
    private _valid = (count _strict) == _length;
    if ((count _preview) <= 0) then {
        private _row = floor (_origin / _grid);
        private _column = _origin mod _grid;
        for "_offset" from 0 to (_length - 1) do {
            private _candidateRow = _row + (if (_orientation == 1) then {_offset} else {0});
            private _candidateColumn = _column + (if (_orientation == 0) then {_offset} else {0});
            if (_candidateRow >= 0 && {_candidateRow < _grid} && {_candidateColumn >= 0} && {_candidateColumn < _grid}) then {
                _preview pushBack ((_candidateRow * _grid) + _candidateColumn);
            };
        };
    };
    private _occupied = [];
    for "_otherShip" from 0 to ((count Waldo_MG_CFG_BATTLESHIP_SHIPS) - 1) do {
        if (_otherShip != _shipIndex) then {
            {_occupied pushBackUnique _x;} forEach (_fleet param [_otherShip, []]);
        };
    };
    {
        if (_x in _occupied) then {_valid = false;};
    } forEach _preview;
    [_preview, _valid]
};

Waldo_MG_fnc_handleBattleshipCellEnterLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    if (isNull _display) exitWith {};
    private _kind = _control getVariable ["Waldo_MG_BattleshipGridKind", ""];
    private _cell = _control getVariable ["Waldo_MG_BattleshipCell", -1];
    if (_kind == "OWN") then {
        _display setVariable ["Waldo_MG_BattleshipHoverOwnLocal", _cell];
    } else {
        _display setVariable ["Waldo_MG_BattleshipHoverTargetLocal", _cell];
    };
    [_display] call Waldo_MG_fnc_refreshBattleshipLocal;
};

Waldo_MG_fnc_handleBattleshipCellClickLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    if (isNull _display) exitWith {};
    [_display] call Waldo_MG_fnc_battleshipDefocusLocal;
    if (_display getVariable ["Waldo_MG_SpectatorMode", false]) exitWith {};
    if (!(_control getVariable ["Waldo_MG_BattleshipCellUsable", false])) exitWith {};
    private _table = _display getVariable ["Waldo_MG_BattleshipTable", objNull];
    private _cell = _control getVariable ["Waldo_MG_BattleshipCell", -1];
    private _kind = _control getVariable ["Waldo_MG_BattleshipGridKind", ""];
    if (isNull _table || {_cell < 0}) exitWith {};
    private _snapshot = _table getVariable ["Waldo_MG_BattleshipSnapshot", []];
    private _phase = _snapshot param [0, "IDLE"];
    if (_kind == "OWN" && {_phase == "PLACEMENT"}) exitWith {
        private _shipIndex = _display getVariable ["Waldo_MG_BattleshipSelectedShipLocal", 0];
        private _orientation = _display getVariable ["Waldo_MG_BattleshipOrientationLocal", 0];
        private _privatePayload = player getVariable ["Waldo_MG_BattleshipPrivateFleet", []];
        private _fleet = _privatePayload param [2, []];
        private _preview = [_fleet, _shipIndex, _cell, _orientation] call Waldo_MG_fnc_battleshipGetPlacementPreviewLocal;
        if (!(_preview param [1, false])) then {
            ["Invalid placement: keep the ship on the grid and clear of every other ship."] call Waldo_MG_fnc_notifyLocal;
        } else {
            [_table, "PLACE", [_shipIndex, _cell, _orientation]] call Waldo_MG_fnc_submitBattleshipActionRequestLocal;
        };
    };
    if (_kind == "TARGET" && {_phase == "PLAYING"}) then {
        [_table, "FIRE", _cell] call Waldo_MG_fnc_submitBattleshipActionRequestLocal;
    };
};

Waldo_MG_fnc_handleBattleshipShipButtonLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    if (isNull _display) exitWith {};
    [_display] call Waldo_MG_fnc_battleshipDefocusLocal;
    _display setVariable ["Waldo_MG_BattleshipSelectedShipLocal", _control getVariable ["Waldo_MG_BattleshipShipIndex", 0]];
    [_display] call Waldo_MG_fnc_refreshBattleshipLocal;
};

Waldo_MG_fnc_handleBattleshipActionButtonLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    if (isNull _display) exitWith {};
    [_display] call Waldo_MG_fnc_battleshipDefocusLocal;
    private _action = _control getVariable ["Waldo_MG_BattleshipAction", ""];
    if (_action == "ROTATE") exitWith {
        private _orientation = _display getVariable ["Waldo_MG_BattleshipOrientationLocal", 0];
        _display setVariable ["Waldo_MG_BattleshipOrientationLocal", 1 - _orientation];
        [_display] call Waldo_MG_fnc_refreshBattleshipLocal;
    };
    private _table = _display getVariable ["Waldo_MG_BattleshipTable", objNull];
    if (!isNull _table && {_action != ""}) then {
        [_table, _action, []] call Waldo_MG_fnc_submitBattleshipActionRequestLocal;
    };
};

Waldo_MG_fnc_createBattleshipGridLocal = {
    disableSerialization;
    params [
        ["_display", displayNull],
        ["_originX", 0],
        ["_originY", 0],
        ["_kind", "OWN"]
    ];
    if (isNull _display) exitWith {[]};
    private _grid = Waldo_MG_CFG_BATTLESHIP_GRID_SIZE;
    private _cellWidth = 0.0392;
    private _cellHeight = 0.066;
    private _letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"];
    for "_column" from 0 to (_grid - 1) do {
        private _columnLabel = _display ctrlCreate ["RscText", -1];
        _columnLabel ctrlSetPosition ([_originX + (_column * _cellWidth), _originY - 0.033, _cellWidth - 0.0015, 0.028] call Waldo_MG_fnc_battleshipSafePositionLocal);
        _columnLabel ctrlSetText (_letters param [_column, "?"]);
        _columnLabel ctrlSetTextColor [0.60, 0.82, 0.94, 1];
        _columnLabel ctrlSetFontHeight 0.021;
        _columnLabel ctrlEnable false;
        _columnLabel ctrlCommit 0;
    };
    for "_row" from 0 to (_grid - 1) do {
        private _rowLabel = _display ctrlCreate ["RscText", -1];
        _rowLabel ctrlSetPosition ([_originX - 0.029, _originY + (_row * _cellHeight), 0.026, _cellHeight - 0.002] call Waldo_MG_fnc_battleshipSafePositionLocal);
        _rowLabel ctrlSetText str (_row + 1);
        _rowLabel ctrlSetTextColor [0.60, 0.82, 0.94, 1];
        _rowLabel ctrlSetFontHeight 0.020;
        _rowLabel ctrlEnable false;
        _rowLabel ctrlCommit 0;
    };
    private _controls = [];
    for "_row" from 0 to (_grid - 1) do {
        for "_column" from 0 to (_grid - 1) do {
            private _cell = (_row * _grid) + _column;
            private _button = _display ctrlCreate ["RscButton", -1];
            _button ctrlSetPosition ([_originX + (_column * _cellWidth), _originY + (_row * _cellHeight), _cellWidth - 0.0015, _cellHeight - 0.002] call Waldo_MG_fnc_battleshipSafePositionLocal);
            _button ctrlSetText "";
            _button ctrlSetBackgroundColor [0.018, 0.085, 0.135, 1];
            _button ctrlSetFontHeight 0.040;
            _button ctrlEnable true;
            _button setVariable ["Waldo_MG_BattleshipGridKind", _kind];
            _button setVariable ["Waldo_MG_BattleshipCell", _cell];
            _button setVariable ["Waldo_MG_BattleshipCellUsable", false];
            _button ctrlSetTooltip ([_cell] call Waldo_MG_fnc_battleshipCellLabel);
            _button ctrlAddEventHandler ["MouseEnter", {params ["_control"]; [_control] call Waldo_MG_fnc_handleBattleshipCellEnterLocal;}];
            _button ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_handleBattleshipCellClickLocal;}];
            _button ctrlCommit 0;
            _controls pushBack _button;
        };
    };
    _controls
};

Waldo_MG_fnc_refreshBattleshipGridLocal = {
    disableSerialization;
    params [
        ["_controls", []],
        ["_shots", []],
        ["_shipCells", []],
        ["_sunkEntries", []],
        ["_previewCells", []],
        ["_previewValid", false],
        ["_hoverCell", -1],
        ["_canUse", false],
        ["_previewMode", false]
    ];
    private _sunkCells = [];
    {
        {_sunkCells pushBackUnique _x;} forEach (_x param [1, []]);
    } forEach _sunkEntries;
    for "_cell" from 0 to ((count _controls) - 1) do {
        private _control = _controls param [_cell, controlNull];
        if (!isNull _control) then {
            private _background = [0.018, 0.085, 0.135, 1];
            private _text = "";
            private _textColour = [0.88, 0.96, 1, 1];
            private _tooltip = [_cell] call Waldo_MG_fnc_battleshipCellLabel;
            if (_cell in _shipCells) then {
                _background = [0.055, 0.30, 0.48, 1];
                _tooltip = _tooltip + " / SHIP";
            };
            private _shotResult = "";
            {
                if ((_x param [0, -1]) == _cell) exitWith {_shotResult = _x param [1, ""];};
            } forEach _shots;
            if (_shotResult == "MISS") then {
                _background = [0.20, 0.34, 0.40, 1];
                _text = "O";
                _tooltip = _tooltip + " / MISS";
            };
            if (_shotResult in ["HIT", "SUNK"]) then {
                _background = [0.70, 0.12, 0.055, 1];
                _text = "X";
                _textColour = [1, 0.90, 0.72, 1];
                _tooltip = _tooltip + " / HIT";
            };
            if (_cell in _sunkCells) then {
                _background = [0.46, 0.025, 0.025, 1];
                _text = "X";
                _tooltip = _tooltip + " / SUNK";
            };
            if (_previewMode && {_cell in _previewCells}) then {
                _background = if (_previewValid) then {[0.08, 0.52, 0.30, 1]} else {[0.62, 0.075, 0.045, 1]};
                _text = if (_previewValid) then {"+"} else {"!"};
                _tooltip = _tooltip + (if (_previewValid) then {" / VALID PLACEMENT"} else {" / INVALID PLACEMENT"});
            } else {
                if (!_previewMode && {_canUse} && {_cell == _hoverCell} && {_shotResult == ""}) then {
                    _background = [0.46, 0.33, 0.055, 1];
                    _tooltip = _tooltip + " / FIRE HERE";
                };
            };
            _control ctrlSetBackgroundColor _background;
            _control ctrlSetText _text;
            _control ctrlSetTextColor _textColour;
            _control ctrlSetTooltip _tooltip;

            _control ctrlEnable true;
            _control setVariable ["Waldo_MG_BattleshipCellUsable", _canUse && {_shotResult == ""}];
            _control ctrlCommit 0;
        };
    };
};

Waldo_MG_fnc_refreshBattleshipLocal = {
    disableSerialization;
    params [["_display", displayNull]];
    if (isNull _display || {_display getVariable ["Waldo_MG_BattleshipRefreshing", false]}) exitWith {};
    _display setVariable ["Waldo_MG_BattleshipRefreshing", true];
    private _table = _display getVariable ["Waldo_MG_BattleshipTable", objNull];
    private _spectating = _display getVariable ["Waldo_MG_SpectatorMode", false];
    if (isNull _table || {!([_table, _spectating] call Waldo_MG_fnc_isValidGameViewerLocal)} || {([_table] call Waldo_MG_fnc_getTableActiveGameId) != "battleship"}) exitWith {
        _display closeDisplay 1;
    };
    private _snapshot = _table getVariable ["Waldo_MG_BattleshipSnapshot", []];
    if ((count _snapshot) < 13) exitWith {_display setVariable ["Waldo_MG_BattleshipRefreshing", false];};
    private _phase = _snapshot param [0, "IDLE"];
    private _actor = _snapshot param [1, -1];
    private _ready = _snapshot param [2, [false, false]];
    private _shotsByAttacker = _snapshot param [3, [[], []]];
    private _remaining = _snapshot param [4, [5, 5]];
    private _sunkByOwner = _snapshot param [5, [[], []]];
    private _winner = _snapshot param [6, -1];
    private _status = _snapshot param [7, "Battleship in progress."];
    private _actions = _snapshot param [9, ["Waiting", "Waiting"]];
    private _versions = _snapshot param [11, [0, 0]];
    private _revealedFleets = _snapshot param [12, [[], []]];
    private _names = _table getVariable ["Waldo_MG_BattleshipPlayerNames", ["Player 1", "Player 2"]];
    private _gameId = _table getVariable ["Waldo_MG_BattleshipGameId", ""];
    private _role = if (_spectating) then {-1} else {[_table] call Waldo_MG_fnc_getBattleshipPlayerRoleLocal};
    if (!_spectating && {_role < 0}) exitWith {
        _display setVariable ["Waldo_MG_BattleshipRefreshing", false];
        _display closeDisplay 1;
    };
    private _privatePayload = if (_spectating || {isNull player}) then {[]} else {player getVariable ["Waldo_MG_BattleshipPrivateFleet", []]};
    private _privateValid = _role >= 0
        && {(_privatePayload param [0, ""]) == _gameId}
        && {(_privatePayload param [1, -1]) == (_versions param [_role, -2])};
    if (!_spectating && {_role >= 0} && {!_privateValid} && {_phase != "FINISHED"}) then {
        private _lastSync = _display getVariable ["Waldo_MG_BattleshipLastSyncLocal", -10];
        if ((diag_tickTime - _lastSync) >= 1.2) then {
            _display setVariable ["Waldo_MG_BattleshipLastSyncLocal", diag_tickTime];
            [_table, "SYNC", []] call Waldo_MG_fnc_submitBattleshipActionRequestLocal;
        };
    };
    private _fleet = if (_privateValid) then {[(_privatePayload param [2, []])] call Waldo_MG_fnc_battleshipCopyFleet} else {if (_phase == "FINISHED" && {_role >= 0}) then {[(_revealedFleets param [_role, []])] call Waldo_MG_fnc_battleshipCopyFleet} else {call Waldo_MG_fnc_battleshipCreateEmptyFleet}};

    private _turnLabel = _display getVariable ["Waldo_MG_BattleshipTurnLabel", controlNull];
    if (!isNull _turnLabel) then {
        private _turnText = if (_phase == "PLACEMENT") then {
            format ["DEPLOYMENT  /  %1 READY", {_x} count _ready]
        } else {
            if (_phase == "FINISHED") then {
                format ["WINNER  /  %1", _names param [_winner, "Forfeit"]]
            } else {
                format [
                    "SHOT %1  /  %2",
                    (_snapshot param [10, 0]) + 1,
                    if (_actor == _role && {!_spectating}) then {"YOUR TURN"} else {_names param [_actor, "Player"]}
                ]
            }
        };
        _turnLabel ctrlSetText _turnText;
        _turnLabel ctrlCommit 0;
    };
    private _statusLabel = _display getVariable ["Waldo_MG_BattleshipStatusLabel", controlNull];
    if (!isNull _statusLabel) then {_statusLabel ctrlSetText _status; _statusLabel ctrlCommit 0;};
    private _legendLabel = _display getVariable ["Waldo_MG_BattleshipLegendLabel", controlNull];
    if (!isNull _legendLabel) then {_legendLabel ctrlSetText "O MISS   /   X HIT   /   DARK RED SUNK"; _legendLabel ctrlCommit 0;};
    private _leftTitle = _display getVariable ["Waldo_MG_BattleshipLeftTitle", controlNull];
    private _rightTitle = _display getVariable ["Waldo_MG_BattleshipRightTitle", controlNull];
    if (_spectating) then {
        if (!isNull _leftTitle) then {_leftTitle ctrlSetText format ["%1 TARGETING %2  /  %3", _names param [0, "P1"], _names param [1, "P2"], _actions param [0, "Waiting"]]; _leftTitle ctrlCommit 0;};
        if (!isNull _rightTitle) then {_rightTitle ctrlSetText format ["%1 TARGETING %2  /  %3", _names param [1, "P2"], _names param [0, "P1"], _actions param [1, "Waiting"]]; _rightTitle ctrlCommit 0;};
    } else {
        private _other = 1 - _role;
        if (!isNull _leftTitle) then {_leftTitle ctrlSetText format ["YOUR FLEET  /  %1  /  %2 SHIPS AFLOAT", _names param [_role, "You"], _remaining param [_role, 5]]; _leftTitle ctrlCommit 0;};
        if (!isNull _rightTitle) then {_rightTitle ctrlSetText format ["TARGETING %1  /  %2 SHIPS AFLOAT", _names param [_other, "Opponent"], _remaining param [_other, 5]]; _rightTitle ctrlCommit 0;};
    };

    private _selectedShip = _display getVariable ["Waldo_MG_BattleshipSelectedShipLocal", 0];
    private _orientation = _display getVariable ["Waldo_MG_BattleshipOrientationLocal", 0];
    private _hoverOwn = _display getVariable ["Waldo_MG_BattleshipHoverOwnLocal", -1];
    private _hoverTarget = _display getVariable ["Waldo_MG_BattleshipHoverTargetLocal", -1];
    private _preview = if (!_spectating && {_phase == "PLACEMENT"} && {_role >= 0} && {!(_ready param [_role, false])}) then {[_fleet, _selectedShip, _hoverOwn, _orientation] call Waldo_MG_fnc_battleshipGetPlacementPreviewLocal} else {[[], false]};
    private _leftControls = _display getVariable ["Waldo_MG_BattleshipLeftCells", []];
    private _rightControls = _display getVariable ["Waldo_MG_BattleshipRightCells", []];

    if (_spectating) then {
        private _leftReveal = if (_phase == "FINISHED") then {[_revealedFleets param [1, []]] call Waldo_MG_fnc_battleshipCopyFleet} else {call Waldo_MG_fnc_battleshipCreateEmptyFleet};
        private _rightReveal = if (_phase == "FINISHED") then {[_revealedFleets param [0, []]] call Waldo_MG_fnc_battleshipCopyFleet} else {call Waldo_MG_fnc_battleshipCreateEmptyFleet};
        private _leftShips = [];
        {{_leftShips pushBackUnique _x;} forEach _x;} forEach _leftReveal;
        private _rightShips = [];
        {{_rightShips pushBackUnique _x;} forEach _x;} forEach _rightReveal;
        [_leftControls, _shotsByAttacker param [0, []], _leftShips, _sunkByOwner param [1, []], [], false, -1, false, false] call Waldo_MG_fnc_refreshBattleshipGridLocal;
        [_rightControls, _shotsByAttacker param [1, []], _rightShips, _sunkByOwner param [0, []], [], false, -1, false, false] call Waldo_MG_fnc_refreshBattleshipGridLocal;
    } else {
        private _other = 1 - _role;
        private _ownShipCells = [];
        {{_ownShipCells pushBackUnique _x;} forEach _x;} forEach _fleet;
        private _targetFleet = if (_phase == "FINISHED") then {[_revealedFleets param [_other, []]] call Waldo_MG_fnc_battleshipCopyFleet} else {call Waldo_MG_fnc_battleshipCreateEmptyFleet};
        private _targetShipCells = [];
        {{_targetShipCells pushBackUnique _x;} forEach _x;} forEach _targetFleet;
        private _canPlace = _phase == "PLACEMENT" && {_role >= 0} && {!(_ready param [_role, false])} && {_privateValid};
        private _roleShots = _shotsByAttacker param [_role, []];
        private _canFire = _phase == "PLAYING" && {_actor == _role};
        [_leftControls, _shotsByAttacker param [_other, []], _ownShipCells, _sunkByOwner param [_role, []], _preview param [0, []], _preview param [1, false], _hoverOwn, _canPlace, true] call Waldo_MG_fnc_refreshBattleshipGridLocal;
        [_rightControls, _roleShots, _targetShipCells, _sunkByOwner param [_other, []], [], false, _hoverTarget, _canFire, false] call Waldo_MG_fnc_refreshBattleshipGridLocal;
    };

    private _shipButtons = _display getVariable ["Waldo_MG_BattleshipShipButtons", []];
    for "_shipIndex" from 0 to ((count _shipButtons) - 1) do {
        private _button = _shipButtons param [_shipIndex, controlNull];
        if (!isNull _button) then {
            private _placed = (count (_fleet param [_shipIndex, []])) == ([_shipIndex] call Waldo_MG_fnc_battleshipShipLength);
            private _show = !_spectating && {_phase == "PLACEMENT"};
            _button ctrlShow _show;
            _button ctrlEnable (_show && {_role >= 0} && {!(_ready param [_role, false])});
            private _shortNames = ["CV 5", "BB 4", "CA 3", "SS 3", "DD 2"];
            private _shipName = [_shipIndex] call Waldo_MG_fnc_battleshipShipName;
            _button ctrlSetText (_shortNames param [_shipIndex, _shipName]);
            _button ctrlSetTooltip format ["%1 / LENGTH %2 / %3", _shipName, [_shipIndex] call Waldo_MG_fnc_battleshipShipLength, if (_placed) then {"PLACED"} else {"NOT PLACED"}];
            _button ctrlSetBackgroundColor (if (_shipIndex == _selectedShip) then {[0.08, 0.42, 0.62, 1]} else {if (_placed) then {[0.06, 0.30, 0.18, 1]} else {[0.08, 0.14, 0.18, 1]}});
            _button ctrlCommit 0;
        };
    };
    private _rotateButton = _display getVariable ["Waldo_MG_BattleshipRotateButton", controlNull];
    private _clearButton = _display getVariable ["Waldo_MG_BattleshipClearButton", controlNull];
    private _readyButton = _display getVariable ["Waldo_MG_BattleshipReadyButton", controlNull];
    private _resetButton = _display getVariable ["Waldo_MG_BattleshipResetButton", controlNull];
    private _helpLabel = _display getVariable ["Waldo_MG_BattleshipHelpLabel", controlNull];
    private _placementVisible = !_spectating && {_phase == "PLACEMENT"} && {_role >= 0};
    if (!isNull _rotateButton) then {_rotateButton ctrlShow _placementVisible; _rotateButton ctrlEnable (_placementVisible && {!(_ready param [_role, false])}); _rotateButton ctrlSetText (if (_orientation == 0) then {"ROTATE H"} else {"ROTATE V"}); _rotateButton ctrlSetTooltip (if (_orientation == 0) then {"Current orientation: horizontal"} else {"Current orientation: vertical"}); _rotateButton ctrlCommit 0;};
    if (!isNull _clearButton) then {_clearButton ctrlShow _placementVisible; _clearButton ctrlEnable (_placementVisible && {!(_ready param [_role, false])}); _clearButton ctrlCommit 0;};
    if (!isNull _readyButton) then {
        private _isReady = if (_role >= 0) then {_ready param [_role, false]} else {false};
        _readyButton ctrlShow _placementVisible;
        _readyButton ctrlEnable (_placementVisible && {_isReady || {[_fleet] call Waldo_MG_fnc_battleshipFleetComplete}});
        _readyButton ctrlSetText (if (_isReady) then {"UNLOCK"} else {"LOCK / READY"});
        _readyButton ctrlSetTooltip (if (_isReady) then {"Unlock your fleet to reposition ships"} else {"Lock the completed fleet and signal readiness"});
        _readyButton setVariable ["Waldo_MG_BattleshipAction", if (_isReady) then {"UNREADY"} else {"READY"}];
        _readyButton ctrlCommit 0;
    };
    if (!isNull _resetButton) then {_resetButton ctrlShow (!_spectating && {_phase == "FINISHED"}); _resetButton ctrlEnable (!_spectating && {_phase == "FINISHED"}); _resetButton ctrlCommit 0;};
    if (!isNull _helpLabel) then {
        _helpLabel ctrlShow (!_placementVisible);
        _helpLabel ctrlSetText (if (_spectating) then {"SPECTATOR VIEW  /  BOTH PUBLIC TARGETING GRIDS  /  PRIVATE FLEETS REMAIN HIDDEN UNTIL THE MATCH ENDS"} else {if (_phase == "PLAYING") then {if (_actor == _role) then {"YOUR TURN  /  HOVER AN UNFIRED ENEMY COORDINATE, THEN CLICK TO FIRE"} else {format ["%1 IS FIRING  /  REVIEW YOUR FLEET AND PREVIOUS SHOTS", _names param [_actor, "Opponent"]]} } else {"MATCH COMPLETE  /  BOTH FLEETS ARE REVEALED  /  RETURN TO THE LOBBY WHEN READY"}});
        _helpLabel ctrlCommit 0;
    };
    _display setVariable ["Waldo_MG_BattleshipRefreshing", false];
};

Waldo_MG_fnc_openBattleshipLocal = {
    disableSerialization;
    params [["_table", objNull], ["_spectating", false]];
    if (!hasInterface || {isNull player}) exitWith {};
    if (isNull _table || {!([_table, _spectating] call Waldo_MG_fnc_isValidGameViewerLocal)} || {([_table] call Waldo_MG_fnc_getTableActiveGameId) != "battleship"}) exitWith {
        ["No active Battleship match is available to this viewer."] call Waldo_MG_fnc_notifyLocal;
    };
    private _parent = findDisplay 46;
    if (isNull _parent) exitWith {["The Battleship display is unavailable."] call Waldo_MG_fnc_notifyLocal;};
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
    uiNamespace setVariable ["Waldo_MG_BattleshipDisplay", _display];
    _display setVariable ["Waldo_MG_BattleshipTable", _table];
    _display setVariable ["Waldo_MG_SpectatorMode", _spectating];
    _display setVariable ["Waldo_MG_BattleshipSelectedShipLocal", 0];
    _display setVariable ["Waldo_MG_BattleshipOrientationLocal", 0];
    _display setVariable ["Waldo_MG_BattleshipHoverOwnLocal", -1];
    _display setVariable ["Waldo_MG_BattleshipHoverTargetLocal", -1];
    _display setVariable ["Waldo_MG_BattleshipLastSyncLocal", -10];
    [_display] call Waldo_MG_fnc_installEscapeGuardLocal;
    private _focusSink = _display ctrlCreate ["RscButton", -1];
    _focusSink ctrlSetPosition [-10, -10, 0.001, 0.001];
    _focusSink ctrlSetText "";
    _focusSink ctrlCommit 0;
    _display setVariable ["Waldo_MG_BattleshipFocusSink", _focusSink];
    ctrlSetFocus _focusSink;

    private _background = _display ctrlCreate ["RscText", -1];
    _background ctrlSetPosition ([0.010, 0.015, 0.980, 0.970] call Waldo_MG_fnc_battleshipSafePositionLocal);
    _background ctrlSetBackgroundColor [0.006, 0.018, 0.030, 0.994];
    _background ctrlCommit 0;
    private _topBar = _display ctrlCreate ["RscText", -1];
    _topBar ctrlSetPosition ([0.010, 0.015, 0.980, 0.070] call Waldo_MG_fnc_battleshipSafePositionLocal);
    _topBar ctrlSetBackgroundColor [0.025, 0.22, 0.37, 1];
    _topBar ctrlCommit 0;
    private _title = _display ctrlCreate ["RscText", -1];
    _title ctrlSetPosition ([0.030, 0.026, 0.390, 0.045] call Waldo_MG_fnc_battleshipSafePositionLocal);
    _title ctrlSetText (if (_spectating) then {"PARTYGAMES  /  BATTLESHIP SPECTATOR"} else {"PARTYGAMES  /  BATTLESHIP"});
    _title ctrlSetTextColor [0.84, 0.95, 1, 1];
    _title ctrlSetFontHeight 0.040;
    _title ctrlCommit 0;
    private _turnLabel = _display ctrlCreate ["RscText", -1];
    _turnLabel ctrlSetPosition ([0.420, 0.028, 0.345, 0.040] call Waldo_MG_fnc_battleshipSafePositionLocal);
    _turnLabel ctrlSetTextColor [1, 0.83, 0.32, 1];
    _turnLabel ctrlSetFontHeight 0.025;
    _turnLabel ctrlCommit 0;
    private _exitButton = _display ctrlCreate ["RscButtonMenu", -1];
    _exitButton ctrlSetPosition ([0.785, 0.020, 0.185, 0.060] call Waldo_MG_fnc_battleshipSafePositionLocal);
    _exitButton ctrlSetText (if (_spectating) then {"Exit Spectate"} else {"Leave Table"});
    _exitButton ctrlSetFontHeight Waldo_MG_CFG_BATTLESHIP_BUTTON_FONT;
    _exitButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_handleViewerExitButtonLocal;}];
    _exitButton ctrlCommit 0;

    private _statusPanel = _display ctrlCreate ["RscText", -1];
    _statusPanel ctrlSetPosition ([0.015, 0.095, 0.970, 0.055] call Waldo_MG_fnc_battleshipSafePositionLocal);
    _statusPanel ctrlSetBackgroundColor [0.018, 0.060, 0.088, 1];
    _statusPanel ctrlCommit 0;
    private _statusLabel = _display ctrlCreate ["RscText", -1];
    _statusLabel ctrlSetPosition ([0.028, 0.105, 0.675, 0.035] call Waldo_MG_fnc_battleshipSafePositionLocal);
    _statusLabel ctrlSetTextColor [0.86, 0.93, 0.96, 1];
    _statusLabel ctrlSetFontHeight 0.021;
    _statusLabel ctrlCommit 0;
    private _legendLabel = _display ctrlCreate ["RscText", -1];
    _legendLabel ctrlSetPosition ([0.710, 0.105, 0.260, 0.035] call Waldo_MG_fnc_battleshipSafePositionLocal);
    _legendLabel ctrlSetTextColor [0.62, 0.80, 0.88, 1];
    _legendLabel ctrlSetFontHeight 0.019;
    _legendLabel ctrlCommit 0;

    private _leftPanel = _display ctrlCreate ["RscText", -1];
    _leftPanel ctrlSetPosition ([0.015, 0.165, 0.475, 0.735] call Waldo_MG_fnc_battleshipSafePositionLocal);
    _leftPanel ctrlSetBackgroundColor [0.012, 0.042, 0.064, 0.98];
    _leftPanel ctrlCommit 0;
    private _rightPanel = _display ctrlCreate ["RscText", -1];
    _rightPanel ctrlSetPosition ([0.510, 0.165, 0.475, 0.735] call Waldo_MG_fnc_battleshipSafePositionLocal);
    _rightPanel ctrlSetBackgroundColor [0.012, 0.042, 0.064, 0.98];
    _rightPanel ctrlCommit 0;
    private _leftTitle = _display ctrlCreate ["RscText", -1];
    _leftTitle ctrlSetPosition ([0.035, 0.173, 0.435, 0.030] call Waldo_MG_fnc_battleshipSafePositionLocal);
    _leftTitle ctrlSetTextColor [0.62, 0.88, 1, 1];
    _leftTitle ctrlSetFontHeight 0.020;
    _leftTitle ctrlCommit 0;
    private _rightTitle = _display ctrlCreate ["RscText", -1];
    _rightTitle ctrlSetPosition ([0.530, 0.173, 0.435, 0.030] call Waldo_MG_fnc_battleshipSafePositionLocal);
    _rightTitle ctrlSetTextColor [1, 0.68, 0.36, 1];
    _rightTitle ctrlSetFontHeight 0.020;
    _rightTitle ctrlCommit 0;
    private _leftCells = [_display, 0.075, 0.215, "OWN"] call Waldo_MG_fnc_createBattleshipGridLocal;
    private _rightCells = [_display, 0.570, 0.215, "TARGET"] call Waldo_MG_fnc_createBattleshipGridLocal;

    private _bottomPanel = _display ctrlCreate ["RscText", -1];
    _bottomPanel ctrlSetPosition ([0.015, 0.910, 0.970, 0.075] call Waldo_MG_fnc_battleshipSafePositionLocal);
    _bottomPanel ctrlSetBackgroundColor [0.012, 0.038, 0.052, 1];
    _bottomPanel ctrlCommit 0;
    private _shipButtons = [];
    for "_shipIndex" from 0 to ((count Waldo_MG_CFG_BATTLESHIP_SHIPS) - 1) do {
        private _button = _display ctrlCreate ["RscButtonMenu", -1];
        _button ctrlSetPosition ([0.022 + (_shipIndex * 0.103), 0.918, 0.098, 0.057] call Waldo_MG_fnc_battleshipSafePositionLocal);
        _button ctrlSetFontHeight Waldo_MG_CFG_BATTLESHIP_BUTTON_FONT;
        _button setVariable ["Waldo_MG_BattleshipShipIndex", _shipIndex];
        _button ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_handleBattleshipShipButtonLocal;}];
        _button ctrlCommit 0;
        _shipButtons pushBack _button;
    };
    private _rotateButton = _display ctrlCreate ["RscButtonMenu", -1];
    _rotateButton ctrlSetPosition ([0.545, 0.918, 0.130, 0.057] call Waldo_MG_fnc_battleshipSafePositionLocal);
    _rotateButton ctrlSetFontHeight Waldo_MG_CFG_BATTLESHIP_BUTTON_FONT;
    _rotateButton setVariable ["Waldo_MG_BattleshipAction", "ROTATE"];
    _rotateButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_handleBattleshipActionButtonLocal;}];
    _rotateButton ctrlCommit 0;
    private _clearButton = _display ctrlCreate ["RscButtonMenu", -1];
    _clearButton ctrlSetPosition ([0.685, 0.918, 0.105, 0.057] call Waldo_MG_fnc_battleshipSafePositionLocal);
    _clearButton ctrlSetText "CLEAR";
    _clearButton ctrlSetTooltip "Clear every ship placement";
    _clearButton ctrlSetFontHeight Waldo_MG_CFG_BATTLESHIP_BUTTON_FONT;
    _clearButton setVariable ["Waldo_MG_BattleshipAction", "CLEAR"];
    _clearButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_handleBattleshipActionButtonLocal;}];
    _clearButton ctrlCommit 0;
    private _readyButton = _display ctrlCreate ["RscButtonMenu", -1];
    _readyButton ctrlSetPosition ([0.800, 0.918, 0.170, 0.057] call Waldo_MG_fnc_battleshipSafePositionLocal);
    _readyButton ctrlSetFontHeight Waldo_MG_CFG_BATTLESHIP_BUTTON_FONT;
    _readyButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_handleBattleshipActionButtonLocal;}];
    _readyButton ctrlCommit 0;
    private _resetButton = _display ctrlCreate ["RscButtonMenu", -1];
    _resetButton ctrlSetPosition ([0.800, 0.918, 0.170, 0.057] call Waldo_MG_fnc_battleshipSafePositionLocal);
    _resetButton ctrlSetText "RETURN TO LOBBY";
    _resetButton ctrlSetFontHeight Waldo_MG_CFG_BATTLESHIP_BUTTON_FONT;
    _resetButton setVariable ["Waldo_MG_BattleshipAction", "RESET"];
    _resetButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_handleBattleshipActionButtonLocal;}];
    _resetButton ctrlCommit 0;
    private _helpLabel = _display ctrlCreate ["RscText", -1];
    _helpLabel ctrlSetPosition ([0.030, 0.923, 0.750, 0.045] call Waldo_MG_fnc_battleshipSafePositionLocal);
    _helpLabel ctrlSetTextColor [0.65, 0.80, 0.87, 1];
    _helpLabel ctrlSetFontHeight 0.021;
    _helpLabel ctrlCommit 0;

    _display setVariable ["Waldo_MG_BattleshipTurnLabel", _turnLabel];
    _display setVariable ["Waldo_MG_BattleshipStatusLabel", _statusLabel];
    _display setVariable ["Waldo_MG_BattleshipLegendLabel", _legendLabel];
    _display setVariable ["Waldo_MG_BattleshipLeftTitle", _leftTitle];
    _display setVariable ["Waldo_MG_BattleshipRightTitle", _rightTitle];
    _display setVariable ["Waldo_MG_BattleshipLeftCells", _leftCells];
    _display setVariable ["Waldo_MG_BattleshipRightCells", _rightCells];
    _display setVariable ["Waldo_MG_BattleshipShipButtons", _shipButtons];
    _display setVariable ["Waldo_MG_BattleshipRotateButton", _rotateButton];
    _display setVariable ["Waldo_MG_BattleshipClearButton", _clearButton];
    _display setVariable ["Waldo_MG_BattleshipReadyButton", _readyButton];
    _display setVariable ["Waldo_MG_BattleshipResetButton", _resetButton];
    _display setVariable ["Waldo_MG_BattleshipHelpLabel", _helpLabel];
    [_display] call Waldo_MG_fnc_refreshBattleshipLocal;
    [_display] spawn {
        disableSerialization;
        params ["_activeDisplay"];
        while {!isNull _activeDisplay} do {
            [_activeDisplay] call Waldo_MG_fnc_refreshBattleshipLocal;
            uiSleep Waldo_MG_CFG_BATTLESHIP_UI_TICK;
        };
    };
}; 
 

