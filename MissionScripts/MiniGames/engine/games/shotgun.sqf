/*
 * Waldos Mini Games - Shotgun Roulette
 * All Waldo_MG_fnc_* functions implementing the Shotgun Roulette mini game (server logic + local UI).
 *
 * Original engine: "Party Games Scripted" by |LorD|[Habilidade]Deus Ex.
 * Ported into WaldosMissionPack and rebranded to the Waldo_MG_ namespace; game
 * logic is preserved from the original composition. Do not claim original authorship.
 *
 * This file is an engine fragment: it defines a group of Waldo_MG_fnc_* runtime
 * functions and is #included by Waldo_fnc_MiniGamesInit (miniGamesInit.sqf).
 * It is not a standalone CfgFunctions entry and is not called directly.
 */

Waldo_MG_fnc_shotgunItemLabel = {
    params [["_itemId", ""]];
    switch (_itemId) do {
        case "BLADE": {"Serrated Blade"};
        case "BEER": {"Beer"};
        case "CIGAR": {"Cigar"};
        case "SPYGLASS": {"Spyglass"};
        case "CUFFS": {"Handcuffs"};
        case "INVERTER": {"Inverter"};
        default {"Unknown Item"};
    }
};

Waldo_MG_fnc_shotgunCreateEmptySnapshot = {
    params [["_count", 0]];
    private _lives = [];
    private _alive = [];
    private _inventories = [];
    private _cuffs = [];
    private _blades = [];
    private _actions = [];
    if (_count > 0) then {
        for "_role" from 0 to (_count - 1) do {
            _lives pushBack Waldo_MG_CFG_SHOTGUN_STARTING_LIVES;
            _alive pushBack true;
            _inventories pushBack [];
            _cuffs pushBack false;
            _blades pushBack false;
            _actions pushBack "Waiting for the first load";
        };
    };
    [
        "IDLE", 0, -1, _lives, _alive, _inventories, _cuffs, _blades,
        0, 0, 0, true, -1, -1, -1, _actions, -1,
        "Waiting for Shotgun Roulette.", 0, 0
    ]
};

Waldo_MG_fnc_shotgunPublishRevisionServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    _table setVariable [
        "Waldo_MG_ShotgunRevision",
        (_table getVariable ["Waldo_MG_ShotgunRevision", 0]) + 1,
        true
    ];
    _table setVariable [
        "Waldo_MG_TableRevision",
        (_table getVariable ["Waldo_MG_TableRevision", 0]) + 1,
        true
    ];
};

Waldo_MG_fnc_shotgunSetSnapshotServer = {
    params [
        ["_table", objNull],
        ["_snapshot", []]
    ];
    if (!isServer || {isNull _table} || {(typeName _snapshot) != "ARRAY"}) exitWith {};
    _table setVariable ["Waldo_MG_ShotgunSnapshotServer", _snapshot];
    _table setVariable ["Waldo_MG_ShotgunSnapshot", _snapshot, true];
    [_table] call Waldo_MG_fnc_shotgunPublishRevisionServer;
};

Waldo_MG_fnc_shotgunClearPrivatePeeksServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    {
        if (!isNull _x) then {
            _x setVariable ["Waldo_MG_ShotgunPrivatePeek", [], owner _x];
        };
    } forEach (_table getVariable ["Waldo_MG_ShotgunPlayers", []]);
};

Waldo_MG_fnc_shotgunClearServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    [_table] call Waldo_MG_fnc_shotgunClearPrivatePeeksServer;
    _table setVariable ["Waldo_MG_ShotgunActive", false, true];
    _table setVariable ["Waldo_MG_ShotgunFinished", false, true];
    _table setVariable ["Waldo_MG_ShotgunGameId", "", true];
    _table setVariable ["Waldo_MG_ShotgunPlayers", [], true];
    _table setVariable ["Waldo_MG_ShotgunPlayerNames", [], true];
    _table setVariable ["Waldo_MG_ShotgunSeatIndices", [], true];
    _table setVariable ["Waldo_MG_ShotgunRevision", 0, true];
    _table setVariable ["Waldo_MG_ShotgunChamberServer", []];
    _table setVariable ["Waldo_MG_ShotgunPendingActorServer", -1];
    _table setVariable ["Waldo_MG_ShotgunPendingReloadServer", false];
    private _empty = [] call Waldo_MG_fnc_shotgunCreateEmptySnapshot;
    _table setVariable ["Waldo_MG_ShotgunSnapshotServer", _empty];
    _table setVariable ["Waldo_MG_ShotgunSnapshot", _empty, true];
    [_table] call Waldo_MG_fnc_shotgunPublishRevisionServer;
};

Waldo_MG_fnc_shotgunGetNextAliveRole = {
    params [
        ["_after", -1],
        ["_alive", []]
    ];
    private _count = count _alive;
    if (_count <= 0) exitWith {-1};
    private _found = -1;
    for "_offset" from 1 to _count do {
        private _candidate = (_after + _offset) mod _count;
        if (_found < 0 && {_alive param [_candidate, false]}) then {
            _found = _candidate;
        };
    };
    _found
};

Waldo_MG_fnc_shotgunResolveCuffsServer = {
    params [
        ["_table", objNull],
        ["_snapshot", []],
        ["_desired", -1]
    ];
    private _alive = _snapshot param [4, []];
    private _cuffs = +(_snapshot param [6, []]);
    private _actions = +(_snapshot param [15, []]);
    private _names = if (isNull _table) then {[]} else {_table getVariable ["Waldo_MG_ShotgunPlayerNames", []]};
    private _count = count _alive;
    private _candidate = _desired;
    private _found = -1;
    private _skipped = [];
    if (_candidate < 0 || {_candidate >= _count} || {!(_alive param [_candidate, false])}) then {
        _candidate = [_candidate, _alive] call Waldo_MG_fnc_shotgunGetNextAliveRole;
    };
    if (_count > 0) then {
        for "_attempt" from 0 to (_count - 1) do {
            if (_found < 0 && {_candidate >= 0} && {_alive param [_candidate, false]}) then {
                if (_cuffs param [_candidate, false]) then {
                    _cuffs set [_candidate, false];
                    _actions set [_candidate, "Turn skipped by Handcuffs"];
                    _skipped pushBack (_names param [_candidate, "Player"]);
                    _candidate = [_candidate, _alive] call Waldo_MG_fnc_shotgunGetNextAliveRole;
                } else {
                    _found = _candidate;
                };
            };
        };
    };
    if (_found < 0) then {
        _found = [-1, _alive] call Waldo_MG_fnc_shotgunGetNextAliveRole;
    };
    [_found, _cuffs, _actions, _skipped]
};

Waldo_MG_fnc_shotgunCreateLoadServer = {
    params [
        ["_table", objNull],
        ["_snapshot", []],
        ["_actor", -1]
    ];
    if (!isServer || {isNull _table}) exitWith {false};
    private _state = +_snapshot;
    private _alive = _state param [4, []];
    if (_actor < 0 || {!(_alive param [_actor, false])}) then {
        _actor = [-1, _alive] call Waldo_MG_fnc_shotgunGetNextAliveRole;
    };
    if (_actor < 0) exitWith {false};
    private _shellCount = Waldo_MG_CFG_SHOTGUN_MIN_SHELLS + floor (random ((Waldo_MG_CFG_SHOTGUN_MAX_SHELLS - Waldo_MG_CFG_SHOTGUN_MIN_SHELLS) + 1));
    private _liveCount = 1 + floor (random (_shellCount - 1));
    private _blankCount = _shellCount - _liveCount;
    private _source = [];
    for "_index" from 1 to _liveCount do {_source pushBack 1;};
    for "_index" from 1 to _blankCount do {_source pushBack 0;};
    private _chamber = [];
    while {(count _source) > 0} do {
        private _pick = floor (random (count _source));
        _chamber pushBack (_source deleteAt _pick);
    };
    private _itemCatalog = ["BLADE", "BEER", "CIGAR", "SPYGLASS", "CUFFS", "INVERTER"];
    private _oldInventories = _state param [5, []];
    private _inventories = [];
    private _actions = +(_state param [15, []]);
    for "_role" from 0 to ((count _alive) - 1) do {
        private _inventory = +(_oldInventories param [_role, []]);
        if (_alive param [_role, false]) then {
            private _slots = (Waldo_MG_CFG_SHOTGUN_INVENTORY_LIMIT - (count _inventory)) max 0;
            private _dealCount = Waldo_MG_CFG_SHOTGUN_ITEMS_PER_LOAD min _slots;
            if (_dealCount > 0) then {
                for "_deal" from 1 to _dealCount do {
                    _inventory pushBack (_itemCatalog param [floor (random (count _itemCatalog)), "BEER"]);
                };
            };
            _actions set [_role, format ["Load %1 ready - %2 item%3 carried", (_state param [1, 0]) + 1, count _inventory, if ((count _inventory) == 1) then {""} else {"s"}]];
        };
        _inventories pushBack _inventory;
    };
    private _load = (_state param [1, 0]) + 1;
    private _version = (_state param [18, 0]) + 1;
    _state set [0, "LOADING"];
    _state set [1, _load];
    _state set [2, -1];
    _state set [5, _inventories];
    _state set [8, _liveCount];
    _state set [9, _blankCount];
    _state set [10, _shellCount];
    _state set [11, true];
    _state set [12, -1];
    _state set [13, -1];
    _state set [14, -1];
    _state set [15, _actions];
    _state set [17, format ["Load %1: memorize %2 LIVE and %3 BLANK shell%4. The colour ledger will now be hidden.", _load, _liveCount, _blankCount, if (_blankCount == 1) then {""} else {"s"}]];
    _state set [18, _version];
    _state set [19, serverTime + Waldo_MG_CFG_SHOTGUN_LOAD_REVEAL_SECONDS];
    _table setVariable ["Waldo_MG_ShotgunChamberServer", _chamber];
    _table setVariable ["Waldo_MG_ShotgunPendingActorServer", _actor];
    _table setVariable ["Waldo_MG_ShotgunPendingReloadServer", false];
    [_table] call Waldo_MG_fnc_shotgunClearPrivatePeeksServer;
    [_table, _state] call Waldo_MG_fnc_shotgunSetSnapshotServer;
    true
};

Waldo_MG_fnc_shotgunStartServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {false};
    if ([_table] call Waldo_MG_fnc_isTableGameActive) exitWith {false};
    if ((_table getVariable ["Waldo_MG_TableSelectedGame", ""]) != "shotgun") exitWith {false};
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
    private _count = count _players;
    if (_count < 2 || {_count > 4}) exitWith {false};
    private _state = [_count] call Waldo_MG_fnc_shotgunCreateEmptySnapshot;
    private _firstActor = floor (random _count);
    _table setVariable ["Waldo_MG_ShotgunActive", true, true];
    _table setVariable ["Waldo_MG_ShotgunFinished", false, true];
    _table setVariable [
        "Waldo_MG_ShotgunGameId",
        format ["Waldo_MG_SHOTGUN_%1_%2", floor (serverTime * 10), floor (random 1000000)],
        true
    ];
    _table setVariable ["Waldo_MG_ShotgunPlayers", _players, true];
    _table setVariable ["Waldo_MG_ShotgunPlayerNames", _names, true];
    _table setVariable ["Waldo_MG_ShotgunSeatIndices", _seatIndices, true];
    _table setVariable ["Waldo_MG_ShotgunRevision", 0, true];
    _table setVariable ["Waldo_MG_ShotgunSnapshotServer", _state];
    _table setVariable ["Waldo_MG_TablePhase", "PLAYING", true];
    [_table, _state, _firstActor] call Waldo_MG_fnc_shotgunCreateLoadServer
};

Waldo_MG_fnc_shotgunFinishServer = {
    params [
        ["_table", objNull],
        ["_snapshot", []],
        ["_winner", -1],
        ["_message", "Shotgun Roulette is finished."]
    ];
    if (!isServer || {isNull _table}) exitWith {};
    private _state = +_snapshot;
    _state set [0, "FINISHED"];
    _state set [2, -1];
    _state set [16, _winner];
    _state set [17, _message];
    _state set [19, 0];
    _table setVariable ["Waldo_MG_ShotgunFinished", true, true];
    _table setVariable ["Waldo_MG_TablePhase", "FINISHED", true];
    _table setVariable ["Waldo_MG_ShotgunPendingActorServer", -1];
    _table setVariable ["Waldo_MG_ShotgunPendingReloadServer", false];
    [_table, _state] call Waldo_MG_fnc_shotgunSetSnapshotServer;
};

Waldo_MG_fnc_shotgunProgressServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table} || {!(_table getVariable ["Waldo_MG_ShotgunActive", false])}) exitWith {};
    private _state = +(_table getVariable ["Waldo_MG_ShotgunSnapshotServer", []]);
    private _phase = _state param [0, ""];
    if (_phase == "LOADING") exitWith {
        if (serverTime >= (_state param [19, 0])) then {
            private _pendingActor = _table getVariable ["Waldo_MG_ShotgunPendingActorServer", -1];
            private _resolved = [_table, _state, _pendingActor] call Waldo_MG_fnc_shotgunResolveCuffsServer;
            private _actor = _resolved param [0, -1];
            private _names = _table getVariable ["Waldo_MG_ShotgunPlayerNames", []];
            _state set [0, "PLAYING"];
            _state set [2, _actor];
            _state set [6, _resolved param [1, _state param [6, []]]];
            _state set [8, -1];
            _state set [9, -1];
            _state set [15, _resolved param [2, _state param [15, []]]];
            _state set [17, format ["The colour ledger is hidden. %1 holds the shotgun; track every reveal.", _names param [_actor, "Player"]]];
            _state set [19, 0];
            _table setVariable ["Waldo_MG_ShotgunPendingActorServer", -1];
            [_table, _state] call Waldo_MG_fnc_shotgunSetSnapshotServer;
        };
    };
    if (_phase != "REVEAL") exitWith {};
    if (serverTime < (_state param [19, 0])) exitWith {};
    private _alive = _state param [4, []];
    private _living = {_x} count _alive;
    if (_living <= 1) exitWith {
        private _winner = [-1, _alive] call Waldo_MG_fnc_shotgunGetNextAliveRole;
        private _names = _table getVariable ["Waldo_MG_ShotgunPlayerNames", []];
        [_table, _state, _winner, format ["%1 is the last player standing.", _names param [_winner, "Player"]]] call Waldo_MG_fnc_shotgunFinishServer;
    };
    private _pendingActor = _table getVariable ["Waldo_MG_ShotgunPendingActorServer", -1];
    private _resolved = [_table, _state, _pendingActor] call Waldo_MG_fnc_shotgunResolveCuffsServer;
    private _actor = _resolved param [0, -1];
    _state set [6, _resolved param [1, _state param [6, []]]];
    _state set [15, _resolved param [2, _state param [15, []]]];
    private _skipped = _resolved param [3, []];
    private _reload = _table getVariable ["Waldo_MG_ShotgunPendingReloadServer", false];
    if (_reload || {(count (_table getVariable ["Waldo_MG_ShotgunChamberServer", []])) <= 0}) then {
        [_table, _state, _actor] call Waldo_MG_fnc_shotgunCreateLoadServer;
    } else {
        private _names = _table getVariable ["Waldo_MG_ShotgunPlayerNames", []];
        _state set [0, "PLAYING"];
        _state set [2, _actor];
        _state set [17, if ((count _skipped) > 0) then {
            format ["%1 skipped by Handcuffs. %2 now holds the shotgun.", _skipped joinString ", ", _names param [_actor, "Player"]]
        } else {
            format ["%1 now holds the shotgun.", _names param [_actor, "Player"]]
        }];
        _state set [19, 0];
        _table setVariable ["Waldo_MG_ShotgunPendingActorServer", -1];
        _table setVariable ["Waldo_MG_ShotgunPendingReloadServer", false];
        [_table, _state] call Waldo_MG_fnc_shotgunSetSnapshotServer;
    };
};

Waldo_MG_fnc_shotgunResetServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    [_table] call Waldo_MG_fnc_shotgunClearServer;
    _table setVariable ["Waldo_MG_TableReady", [false, false, false, false], true];
    [_table] call Waldo_MG_fnc_refreshTableConsensusServer;
};

Waldo_MG_fnc_shotgunHandleDepartureServer = {
    params [
        ["_table", objNull],
        ["_unit", objNull],
        ["_seatIndex", -1]
    ];
    if (!isServer || {isNull _table} || {!(_table getVariable ["Waldo_MG_ShotgunActive", false])}) exitWith {};
    private _players = _table getVariable ["Waldo_MG_ShotgunPlayers", []];
    private _seatIndices = _table getVariable ["Waldo_MG_ShotgunSeatIndices", []];
    private _role = if (isNull _unit) then {-1} else {_players find _unit};
    if (_role < 0 && {_seatIndex >= 0}) then {_role = _seatIndices find _seatIndex;};
    if (_role < 0) exitWith {};
    private _state = +(_table getVariable ["Waldo_MG_ShotgunSnapshotServer", []]);
    private _alive = +(_state param [4, []]);
    if (!(_alive param [_role, false])) exitWith {};
    private _lives = +(_state param [3, []]);
    private _actions = +(_state param [15, []]);
    private _names = _table getVariable ["Waldo_MG_ShotgunPlayerNames", []];
    _alive set [_role, false];
    _lives set [_role, 0];
    _actions set [_role, "Left the table - eliminated"];
    _state set [3, _lives];
    _state set [4, _alive];
    _state set [15, _actions];
    private _living = {_x} count _alive;
    if (_living <= 0) exitWith {
        [_table] call Waldo_MG_fnc_shotgunClearServer;
        _table setVariable ["Waldo_MG_TableReady", [false, false, false, false], true];
        _table setVariable ["Waldo_MG_TablePhase", "LOBBY", true];
    };
    if (_living == 1) exitWith {
        private _winner = [-1, _alive] call Waldo_MG_fnc_shotgunGetNextAliveRole;
        [_table, _state, _winner, format ["%1 wins after %2 leaves the table.", _names param [_winner, "Player"], _names param [_role, "Player"]]] call Waldo_MG_fnc_shotgunFinishServer;
    };
    private _phase = _state param [0, "PLAYING"];
    if (_phase == "PLAYING" && {(_state param [2, -1]) == _role}) then {
        private _next = [_role, _alive] call Waldo_MG_fnc_shotgunGetNextAliveRole;
        private _resolved = [_table, _state, _next] call Waldo_MG_fnc_shotgunResolveCuffsServer;
        _state set [2, _resolved param [0, _next]];
        _state set [6, _resolved param [1, _state param [6, []]]];
        _state set [15, _resolved param [2, _actions]];
    };
    if (_phase in ["LOADING", "REVEAL"] && {(_table getVariable ["Waldo_MG_ShotgunPendingActorServer", -1]) == _role}) then {
        _table setVariable ["Waldo_MG_ShotgunPendingActorServer", [_role, _alive] call Waldo_MG_fnc_shotgunGetNextAliveRole];
    };
    _state set [17, format ["%1 left the match and was eliminated.", _names param [_role, "Player"]]];
    [_table, _state] call Waldo_MG_fnc_shotgunSetSnapshotServer;
};

Waldo_MG_fnc_shotgunReconcilePlayersServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table} || {!(_table getVariable ["Waldo_MG_ShotgunActive", false])}) exitWith {};
    private _players = _table getVariable ["Waldo_MG_ShotgunPlayers", []];
    private _seatIndices = _table getVariable ["Waldo_MG_ShotgunSeatIndices", []];
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
            [_table, _unit, _seat] call Waldo_MG_fnc_shotgunHandleDepartureServer;
        };
    };
}; 
 

Waldo_MG_fnc_processShotgunActionRequestServer = {
    params [
        ["_unit", objNull],
        ["_request", []]
    ];
    if (!isServer || {isNull _unit}) exitWith {};
    _unit setVariable ["Waldo_MG_ShotgunActionRequest", [], true];
    if ((count _request) < 6) exitWith {};
    private _token = _request param [0, ""];
    if (!([_token] call Waldo_MG_fnc_rememberHandledTokenServer)) exitWith {};
    private _tableNetId = _request param [1, ""];
    private _gameId = _request param [2, ""];
    private _expectedRevision = _request param [3, -1];
    private _action = _request param [4, ""];
    private _payload = _request param [5, -1];
    if (
        (typeName _tableNetId) != "STRING"
        || {(typeName _gameId) != "STRING"}
        || {(typeName _expectedRevision) != "SCALAR"}
        || {(typeName _action) != "STRING"}
    ) exitWith {
        [_unit, _token, "Shotgun Roulette action rejected: malformed request data."] call Waldo_MG_fnc_resultServer;
    };
    private _table = objectFromNetId _tableNetId;
    if (isNull _table || {_table != (_unit getVariable ["Waldo_MG_SeatedTable", objNull])}) exitWith {
        [_unit, _token, "Shotgun Roulette action rejected: you are no longer seated at that table."] call Waldo_MG_fnc_resultServer;
    };
    if (!(_table getVariable ["Waldo_MG_ShotgunActive", false])) exitWith {
        [_unit, _token, "There is no active Shotgun Roulette match at this table."] call Waldo_MG_fnc_resultServer;
    };
    if (_gameId == "" || {_gameId != (_table getVariable ["Waldo_MG_ShotgunGameId", ""])}) exitWith {
        [_unit, _token, "That Shotgun Roulette match is no longer current."] call Waldo_MG_fnc_resultServer;
    };
    private _players = _table getVariable ["Waldo_MG_ShotgunPlayers", []];
    private _role = _players find _unit;
    if (_role < 0) exitWith {
        [_unit, _token, "Only assigned Shotgun Roulette players may act."] call Waldo_MG_fnc_resultServer;
    };
    private _state = +(_table getVariable ["Waldo_MG_ShotgunSnapshotServer", []]);
    private _phase = _state param [0, "IDLE"];
    if (_action == "RESET") exitWith {
        if (_phase != "FINISHED") then {
            [_unit, _token, "The match must finish before returning to the lobby."] call Waldo_MG_fnc_resultServer;
        } else {
            [_table] call Waldo_MG_fnc_shotgunResetServer;
            [_unit, _token, "Shotgun Roulette cleared. The table has returned to its lobby."] call Waldo_MG_fnc_resultServer;
        };
    };
    if (_expectedRevision != (_table getVariable ["Waldo_MG_ShotgunRevision", -1])) exitWith {
        [_unit, _token, "The shotgun state changed before that action arrived."] call Waldo_MG_fnc_resultServer;
    };
    private _alive = +(_state param [4, []]);
    if (!(_alive param [_role, false])) exitWith {
        [_unit, _token, "Eliminated players cannot use the shotgun or items."] call Waldo_MG_fnc_resultServer;
    };
    if (_phase != "PLAYING" || {(_state param [2, -1]) != _role}) exitWith {
        [_unit, _token, if (_phase == "REVEAL") then {"Wait for the shell reveal to finish."} else {"It is not your turn."}] call Waldo_MG_fnc_resultServer;
    };
    private _names = _table getVariable ["Waldo_MG_ShotgunPlayerNames", []];
    private _actions = +(_state param [15, []]);
    if (_action == "FIRE") exitWith {
        if ((typeName _payload) != "SCALAR" || {_payload != floor _payload}) then {
            [_unit, _token, "Choose a valid player target."] call Waldo_MG_fnc_resultServer;
        } else {
            private _target = floor _payload;
            if (_target < 0 || {_target >= (count _alive)} || {!(_alive param [_target, false])}) then {
                [_unit, _token, "That firing target is not alive and available."] call Waldo_MG_fnc_resultServer;
            } else {
                private _chamber = +(_table getVariable ["Waldo_MG_ShotgunChamberServer", []]);
                if ((count _chamber) <= 0) then {
                    [_unit, _token, "The chamber is empty and awaiting a reload."] call Waldo_MG_fnc_resultServer;
                } else {
                    private _shell = _chamber deleteAt ((count _chamber) - 1);
                    private _lives = +(_state param [3, []]);
                    private _blades = +(_state param [7, []]);
                    private _bladeUsed = _blades param [_role, false];
                    private _damage = if (_bladeUsed) then {2} else {1};
                    if (_bladeUsed) then {_blades set [_role, false];};
                    private _shooterName = _names param [_role, "Player"];
                    private _targetName = _names param [_target, "Player"];
                    private _shellWord = if (_shell == 1) then {"LIVE"} else {"BLANK"};
                    if (_shell == 1) then {
                        private _remainingLife = ((_lives param [_target, 0]) - _damage) max 0;
                        _lives set [_target, _remainingLife];
                        if (_remainingLife <= 0) then {
                            _alive set [_target, false];
                            _actions set [_target, format ["Eliminated by %1", _shooterName]];
                        };
                    };
                    _actions set [_role, format ["Fired at %1 - %2%3", if (_target == _role) then {"self"} else {_targetName}, _shellWord, if (_shell == 1 && {_bladeUsed}) then {" / 2 DAMAGE"} else {""}]];
                    private _version = (_state param [18, 0]) + 1;
                    _state set [3, _lives];
                    _state set [4, _alive];
                    _state set [7, _blades];
                    _state set [10, count _chamber];
                    _state set [12, _shell];
                    _state set [13, _role];
                    _state set [14, _target];
                    _state set [15, _actions];
                    _state set [18, _version];
                    _table setVariable ["Waldo_MG_ShotgunChamberServer", _chamber];
                    [_table] call Waldo_MG_fnc_shotgunClearPrivatePeeksServer;
                    private _living = {_x} count _alive;
                    if (_living <= 1) then {
                        private _winner = [-1, _alive] call Waldo_MG_fnc_shotgunGetNextAliveRole;
                        [_table, _state, _winner, format ["%1 fired %2 at %3. %4 is the last player standing.", _shooterName, _shellWord, if (_target == _role) then {"themselves"} else {_targetName}, _names param [_winner, "Player"]]] call Waldo_MG_fnc_shotgunFinishServer;
                    } else {
                        private _nextActor = if (_target == _role && {_shell == 0}) then {
                            _role
                        } else {
                            [_role, _alive] call Waldo_MG_fnc_shotgunGetNextAliveRole
                        };
                        _state set [0, "REVEAL"];
                        _state set [17, format ["%1 aimed at %2: %3%4", _shooterName, if (_target == _role) then {"themselves"} else {_targetName}, _shellWord, if (_shell == 1) then {format [" - %1 damage", _damage]} else {""}]];
                        _state set [19, serverTime + Waldo_MG_CFG_SHOTGUN_REVEAL_SECONDS];
                        _table setVariable ["Waldo_MG_ShotgunPendingActorServer", _nextActor];
                        _table setVariable ["Waldo_MG_ShotgunPendingReloadServer", (count _chamber) <= 0];
                        [_table, _state] call Waldo_MG_fnc_shotgunSetSnapshotServer;
                    };
                    [_unit, _token, format ["Trigger pulled: %1.", _shellWord]] call Waldo_MG_fnc_resultServer;
                };
            };
        };
    };
    if (_action != "USE_ITEM") exitWith {
        [_unit, _token, "Unknown Shotgun Roulette action."] call Waldo_MG_fnc_resultServer;
    };
    if ((typeName _payload) != "ARRAY" || {(count _payload) < 1}) exitWith {
        [_unit, _token, "Item request rejected: malformed selection."] call Waldo_MG_fnc_resultServer;
    };
    private _slot = _payload param [0, -1];
    private _target = _payload param [1, -1];
    if ((typeName _slot) != "SCALAR" || {_slot != floor _slot}) exitWith {
        [_unit, _token, "Choose a valid item slot."] call Waldo_MG_fnc_resultServer;
    };
    _slot = floor _slot;
    private _oldInventories = _state param [5, []];
    private _inventories = [];
    {
        _inventories pushBack (+_x);
    } forEach _oldInventories;
    private _inventory = +(_inventories param [_role, []]);
    if (_slot < 0 || {_slot >= (count _inventory)}) exitWith {
        [_unit, _token, "That item slot is empty or stale."] call Waldo_MG_fnc_resultServer;
    };
    private _item = _inventory param [_slot, ""];
    private _itemLabel = [_item] call Waldo_MG_fnc_shotgunItemLabel;
    private _error = "";
    private _resultMessage = format ["Used %1.", _itemLabel];
    private _statusMessage = format ["%1 used %2 and keeps the shotgun.", _names param [_role, "Player"], _itemLabel];
    private _lives = +(_state param [3, []]);
    private _cuffs = +(_state param [6, []]);
    private _blades = +(_state param [7, []]);
    private _chamber = +(_table getVariable ["Waldo_MG_ShotgunChamberServer", []]);
    private _beerShell = -1;
    switch (_item) do {
        case "BLADE": {
            if (_blades param [_role, false]) then {
                _error = "A Serrated Blade is already armed for your next trigger pull.";
            } else {
                _blades set [_role, true];
                _actions set [_role, "Armed Serrated Blade - next pull can deal 2 damage"];
            };
        };
        case "BEER": {
            if ((count _chamber) <= 0) then {
                _error = "There is no shell to eject.";
            } else {
                _beerShell = _chamber deleteAt ((count _chamber) - 1);
                private _word = if (_beerShell == 1) then {"LIVE"} else {"BLANK"};
                _actions set [_role, format ["Drank Beer - ejected %1", _word]];
                _resultMessage = format ["Beer ejected a %1 shell.", _word];
                _statusMessage = format ["%1 racks the shotgun and ejects a %2 shell.", _names param [_role, "Player"], _word];
            };
        };
        case "CIGAR": {
            if ((_lives param [_role, 0]) >= Waldo_MG_CFG_SHOTGUN_MAX_LIVES) then {
                _error = format ["Cigar cannot raise you above %1 lives.", Waldo_MG_CFG_SHOTGUN_MAX_LIVES];
            } else {
                _lives set [_role, (_lives param [_role, 0]) + 1];
                _actions set [_role, "Smoked Cigar - restored 1 life"];
            };
        };
        case "SPYGLASS": {
            if ((count _chamber) <= 0) then {
                _error = "There is no shell to inspect.";
            } else {
                private _peekedShell = _chamber param [(count _chamber) - 1, -1];
                private _version = _state param [18, 0];
                _unit setVariable ["Waldo_MG_ShotgunPrivatePeek", [_gameId, _version, _peekedShell], owner _unit];
                _actions set [_role, "Used Spyglass - result kept private"];
                _resultMessage = format ["Spyglass: the current shell is %1.", if (_peekedShell == 1) then {"LIVE"} else {"BLANK"}];
            };
        };
        case "CUFFS": {
            if ((typeName _target) != "SCALAR" || {_target != floor _target}) then {
                _error = "Choose a valid Handcuffs target.";
            } else {
                _target = floor _target;
                if (_target < 0 || {_target >= (count _alive)} || {_target == _role} || {!(_alive param [_target, false])}) then {
                    _error = "Handcuffs require another living player.";
                } else {
                    if (_cuffs param [_target, false]) then {
                        _error = "That player is already waiting to lose a turn.";
                    } else {
                        _cuffs set [_target, true];
                        _actions set [_role, format ["Handcuffed %1", _names param [_target, "Player"]]];
                        _resultMessage = format ["%1 will lose their next eligible turn.", _names param [_target, "Player"]];
                        _statusMessage = format ["%1 handcuffed %2.", _names param [_role, "Player"], _names param [_target, "Player"]];
                    };
                };
            };
        };
        case "INVERTER": {
            if ((count _chamber) <= 0) then {
                _error = "There is no shell to invert.";
            } else {
                private _currentIndex = (count _chamber) - 1;
                _chamber set [_currentIndex, 1 - (_chamber param [_currentIndex, 0])];
                _state set [8, -1];
                _state set [9, -1];
                _state set [11, false];
                _state set [18, (_state param [18, 0]) + 1];
                _actions set [_role, "Used Inverter - shell ledger disrupted"];
                _statusMessage = format ["%1 used an Inverter. The remaining shell colours are now uncertain.", _names param [_role, "Player"]];
                [_table] call Waldo_MG_fnc_shotgunClearPrivatePeeksServer;
            };
        };
        default {
            _error = "That item is not recognized by the table.";
        };
    };
    if (_error != "") exitWith {
        [_unit, _token, _error] call Waldo_MG_fnc_resultServer;
    };
    _inventory deleteAt _slot;
    _inventories set [_role, _inventory];
    _state set [3, _lives];
    _state set [5, _inventories];
    _state set [6, _cuffs];
    _state set [7, _blades];
    _state set [15, _actions];
    _state set [17, _statusMessage];
    if (_beerShell >= 0) then {
        _state set [0, "REVEAL"];
        _state set [10, count _chamber];
        _state set [12, _beerShell];
        _state set [13, _role];
        _state set [14, -1];
        _state set [18, (_state param [18, 0]) + 1];
        _state set [19, serverTime + Waldo_MG_CFG_SHOTGUN_REVEAL_SECONDS];
        _table setVariable ["Waldo_MG_ShotgunChamberServer", _chamber];
        _table setVariable ["Waldo_MG_ShotgunPendingActorServer", _role];
        _table setVariable ["Waldo_MG_ShotgunPendingReloadServer", (count _chamber) <= 0];
        [_table] call Waldo_MG_fnc_shotgunClearPrivatePeeksServer;
    } else {
        _state set [19, 0];
        if (_item == "INVERTER") then {
            _table setVariable ["Waldo_MG_ShotgunChamberServer", _chamber];
        };
    };
    [_table, _state] call Waldo_MG_fnc_shotgunSetSnapshotServer;
    [_unit, _token, _resultMessage] call Waldo_MG_fnc_resultServer;
};

Waldo_MG_fnc_submitShotgunActionRequestLocal = {
    params [
        ["_table", objNull],
        ["_action", ""],
        ["_payload", -1]
    ];
    if (!hasInterface || {isNull player} || {isNull _table} || {_action == ""}) exitWith {false};
    private _pending = missionNamespace getVariable ["Waldo_MG_ShotgunPendingRequestLocal", []];
    if ((count _pending) >= 2 && {(diag_tickTime - (_pending param [1, -10])) < 1.5}) exitWith {
        hintSilent "Waiting for the table host to answer your previous Shotgun Roulette action...";
        false
    };
    private _token = ["SHOTGUN_ACTION"] call Waldo_MG_fnc_makeToken;
    missionNamespace setVariable ["Waldo_MG_ShotgunPendingRequestLocal", [_token, diag_tickTime]];
    player setVariable [
        "Waldo_MG_ShotgunActionRequest",
        [
            _token,
            netId _table,
            _table getVariable ["Waldo_MG_ShotgunGameId", ""],
            _table getVariable ["Waldo_MG_ShotgunRevision", -1],
            _action,
            _payload
        ],
        true
    ];
    true
};

Waldo_MG_fnc_getShotgunPlayerRoleLocal = {
    params [["_table", objNull]];
    if (isNull _table || {isNull player}) exitWith {-1};
    (_table getVariable ["Waldo_MG_ShotgunPlayers", []]) find player
};

Waldo_MG_fnc_handleShotgunTargetClickLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    if (isNull _display || {_display getVariable ["Waldo_MG_SpectatorMode", false]}) exitWith {};
    private _table = _display getVariable ["Waldo_MG_ShotgunTable", objNull];
    private _target = _control getVariable ["Waldo_MG_ShotgunTargetRole", -1];
    private _cuffSlot = _display getVariable ["Waldo_MG_ShotgunCuffSlotLocal", -1];
    if (_cuffSlot >= 0) then {
        _display setVariable ["Waldo_MG_ShotgunCuffSlotLocal", -1];
        [_table, "USE_ITEM", [_cuffSlot, _target]] call Waldo_MG_fnc_submitShotgunActionRequestLocal;
    } else {
        [_table, "FIRE", _target] call Waldo_MG_fnc_submitShotgunActionRequestLocal;
    };
    [_display] call Waldo_MG_fnc_refreshShotgunLocal;
};

Waldo_MG_fnc_handleShotgunItemClickLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    if (isNull _display || {_display getVariable ["Waldo_MG_SpectatorMode", false]}) exitWith {};
    private _table = _display getVariable ["Waldo_MG_ShotgunTable", objNull];
    private _slot = _control getVariable ["Waldo_MG_ShotgunItemSlot", -1];
    private _item = _control getVariable ["Waldo_MG_ShotgunItemId", ""];
    if (_item == "CUFFS") then {
        private _oldSlot = _display getVariable ["Waldo_MG_ShotgunCuffSlotLocal", -1];
        _display setVariable ["Waldo_MG_ShotgunCuffSlotLocal", if (_oldSlot == _slot) then {-1} else {_slot}];
        [_display] call Waldo_MG_fnc_refreshShotgunLocal;
    } else {
        _display setVariable ["Waldo_MG_ShotgunCuffSlotLocal", -1];
        [_table, "USE_ITEM", [_slot, -1]] call Waldo_MG_fnc_submitShotgunActionRequestLocal;
    };
};

Waldo_MG_fnc_handleShotgunResetClickLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    private _table = if (isNull _display) then {objNull} else {_display getVariable ["Waldo_MG_ShotgunTable", objNull]};
    [_table, "RESET", -1] call Waldo_MG_fnc_submitShotgunActionRequestLocal;
};

Waldo_MG_fnc_scaleShotgunDisplayLocal = {
    disableSerialization;
    params [["_display", displayNull]];
    if (isNull _display || {_display getVariable ["Waldo_MG_ShotgunScaleApplied", false]}) exitWith {};
    private _scale = Waldo_MG_CFG_SHOTGUN_UI_SCALE max 0.5;
    private _centerX = Waldo_MG_CFG_SHOTGUN_UI_CENTER param [0, 0.590];
    private _centerY = Waldo_MG_CFG_SHOTGUN_UI_CENTER param [1, 0.5425];
    {
        private _position = ctrlPosition _x;
        private _oldX = _position param [0, -10];
        private _oldY = _position param [1, -10];
        if (_oldX > -5 && {_oldY > -5}) then {
            _x ctrlSetPosition [
                _centerX + ((_oldX - _centerX) * _scale),
                _centerY + ((_oldY - _centerY) * _scale),
                _position param [2, 0],
                _position param [3, 0]
            ];
            _x ctrlSetScale _scale;
            _x ctrlCommit 0;
        };
    } forEach (allControls _display);
    _display setVariable ["Waldo_MG_ShotgunScaleApplied", true];
};

Waldo_MG_fnc_refreshShotgunLocal = {
    disableSerialization;
    params [["_display", displayNull]];
    if (isNull _display) exitWith {};
    if (_display getVariable ["Waldo_MG_ShotgunRefreshing", false]) exitWith {};
    _display setVariable ["Waldo_MG_ShotgunRefreshing", true];
    private _table = _display getVariable ["Waldo_MG_ShotgunTable", objNull];
    private _spectating = _display getVariable ["Waldo_MG_SpectatorMode", false];
    if (
        isNull _table
        || {!([_table, _spectating] call Waldo_MG_fnc_isValidGameViewerLocal)}
        || {([_table] call Waldo_MG_fnc_getTableActiveGameId) != "shotgun"}
    ) exitWith {
        _display closeDisplay 1;
    };
    private _state = _table getVariable ["Waldo_MG_ShotgunSnapshot", []];
    if ((count _state) < 20) exitWith {
        _display setVariable ["Waldo_MG_ShotgunRefreshing", false];
    };
    private _phase = _state param [0, "IDLE"];
    private _load = _state param [1, 0];
    private _actor = _state param [2, -1];
    private _lives = _state param [3, []];
    private _alive = _state param [4, []];
    private _inventories = _state param [5, []];
    private _cuffs = _state param [6, []];
    private _blades = _state param [7, []];
    private _remainingLive = _state param [8, 0];
    private _remainingBlank = _state param [9, 0];
    private _chamberCount = _state param [10, 0];
    private _ledgerTrusted = _state param [11, true];
    private _lastShell = _state param [12, -1];
    private _lastTarget = _state param [14, -1];
    private _actions = _state param [15, []];
    private _winner = _state param [16, -1];
    private _status = _state param [17, "Shotgun Roulette in progress."];
    private _chamberVersion = _state param [18, 0];
    private _phaseDeadline = _state param [19, 0];
    private _names = _table getVariable ["Waldo_MG_ShotgunPlayerNames", []];
    private _role = if (_spectating) then {-1} else {[_table] call Waldo_MG_fnc_getShotgunPlayerRoleLocal};

    private _loadLabel = _display getVariable ["Waldo_MG_ShotgunLoadLabel", controlNull];
    private _phaseLabel = _display getVariable ["Waldo_MG_ShotgunPhaseLabel", controlNull];
    private _ledgerLabel = _display getVariable ["Waldo_MG_ShotgunLedgerLabel", controlNull];
    private _statusLabel = _display getVariable ["Waldo_MG_ShotgunStatusLabel", controlNull];
    private _instructionLabel = _display getVariable ["Waldo_MG_ShotgunInstructionLabel", controlNull];
    private _peekLabel = _display getVariable ["Waldo_MG_ShotgunPeekLabel", controlNull];
    if (!isNull _loadLabel) then {
        _loadLabel ctrlSetText format ["LOAD %1  /  %2 SHELL%3", _load, _chamberCount, if (_chamberCount == 1) then {""} else {"S"}];
        _loadLabel ctrlCommit 0;
    };
    if (!isNull _phaseLabel) then {
        private _actorName = if (_actor >= 0) then {_names param [_actor, "Player"]} else {"NO ACTIVE SHOOTER"};
        _phaseLabel ctrlSetText (if (_phase == "FINISHED") then {
            format ["WINNER  /  %1", _names param [_winner, "Player"]]
        } else {
            if (_phase == "LOADING") then {
                format ["MEMORIZE LOAD  /  %1", ceil ((_phaseDeadline - serverTime) max 0)]
            } else {
                if (_phase == "REVEAL") then {"SHELL REVEAL"} else {format ["SHOTGUN  /  %1", _actorName]}
            }
        });
        _phaseLabel ctrlSetTextColor (if (_phase in ["LOADING", "REVEAL"]) then {[1, 0.78, 0.25, 1]} else {[0.88, 0.94, 1, 1]});
        _phaseLabel ctrlCommit 0;
    };
    if (!isNull _ledgerLabel) then {
        _ledgerLabel ctrlSetText (if (_phase == "LOADING") then {
            format ["MEMORIZE  /  %1 LIVE  /  %2 BLANK", _remainingLive, _remainingBlank]
        } else {
            if (_ledgerTrusted) then {
                format ["COLOUR LEDGER HIDDEN  /  TRACK REVEALS  /  %1 SHELL%2 REMAIN", _chamberCount, if (_chamberCount == 1) then {""} else {"S"}]
            } else {
                format ["INVERTER USED  /  MIX IS UNCERTAIN  /  %1 SHELL%2 REMAIN", _chamberCount, if (_chamberCount == 1) then {""} else {"S"}]
            }
        });
        _ledgerLabel ctrlSetTextColor (if (_phase == "LOADING") then {[1, 0.82, 0.35, 1]} else {if (_ledgerTrusted) then {[0.65, 0.75, 0.82, 1]} else {[1, 0.69, 0.25, 1]}});
        _ledgerLabel ctrlCommit 0;
    };
    if (!isNull _statusLabel) then {
        _statusLabel ctrlSetText _status;
        _statusLabel ctrlSetTooltip _status;
        _statusLabel ctrlCommit 0;
    };

    private _playerPanels = _display getVariable ["Waldo_MG_ShotgunPlayerPanels", []];
    for "_index" from 0 to ((count _playerPanels) - 1) do {
        private _bundle = _playerPanels param [_index, []];
        private _panel = _bundle param [0, controlNull];
        private _nameControl = _bundle param [1, controlNull];
        private _livesControl = _bundle param [2, controlNull];
        private _inventoryControl = _bundle param [3, controlNull];
        private _actionControl = _bundle param [4, controlNull];
        private _exists = _index < (count _names);
        {
            if (!isNull _x) then {_x ctrlShow _exists;};
        } forEach _bundle;
        if (_exists) then {
            private _isAlive = _alive param [_index, false];
            private _isActor = _phase == "PLAYING" && {_actor == _index};
            private _wasTarget = _phase == "REVEAL" && {_lastTarget == _index};
            if (!isNull _panel) then {
                _panel ctrlSetBackgroundColor (if (!_isAlive) then {
                    [0.055, 0.055, 0.060, 0.97]
                } else {
                    if (_wasTarget) then {[0.34, 0.065, 0.045, 0.98]} else {if (_isActor) then {[0.30, 0.205, 0.050, 0.98]} else {[0.025, 0.080, 0.110, 0.97]}}
                });
                _panel ctrlCommit 0;
            };
            if (!isNull _nameControl) then {
                _nameControl ctrlSetText format ["P%1  /  %2%3", _index + 1, _names param [_index, "Player"], if (_index == _role) then {"  /  YOU"} else {""}];
                _nameControl ctrlSetTooltip (_names param [_index, "Player"]);
                _nameControl ctrlCommit 0;
            };
            if (!isNull _livesControl) then {
                private _tags = [];
                if (_cuffs param [_index, false]) then {_tags pushBack "CUFFED";};
                if (_blades param [_index, false]) then {_tags pushBack "BLADE ARMED";};
                _livesControl ctrlSetText format ["%1  /  LIVES %2%3", if (_isAlive) then {if (_isActor) then {"HAS SHOTGUN"} else {"STANDING"}} else {"ELIMINATED"}, _lives param [_index, 0], if ((count _tags) > 0) then {format ["  /  %1", _tags joinString " + "]} else {""}];
                _livesControl ctrlCommit 0;
            };
            if (!isNull _inventoryControl) then {
                private _itemWords = [];
                {
                    _itemWords pushBack ([_x] call Waldo_MG_fnc_shotgunItemLabel);
                } forEach (_inventories param [_index, []]);
                _inventoryControl ctrlSetText format ["ITEMS  /  %1", if ((count _itemWords) > 0) then {_itemWords joinString " | "} else {"NONE"}];
                _inventoryControl ctrlSetTooltip (_itemWords joinString ", ");
                _inventoryControl ctrlCommit 0;
            };
            if (!isNull _actionControl) then {
                _actionControl ctrlSetText (_actions param [_index, "Waiting"]);
                _actionControl ctrlSetTooltip (_actions param [_index, "Waiting"]);
                _actionControl ctrlCommit 0;
            };
        };
    };

    private _shellControls = _display getVariable ["Waldo_MG_ShotgunShellControls", []];
    for "_slot" from 0 to ((count _shellControls) - 1) do {
        private _control = _shellControls param [_slot, controlNull];
        if (!isNull _control) then {
            private _visible = _phase == "LOADING" && {_slot < _chamberCount};
            _control ctrlShow _visible;
            if (_visible) then {
                if (_ledgerTrusted) then {
                    private _live = _slot < _remainingLive;
                    _control ctrlSetText (if (_live) then {"12G"} else {"BLANK"});
                    _control ctrlSetBackgroundColor (if (_live) then {[0.56, 0.045, 0.035, 1]} else {[0.035, 0.25, 0.48, 1]});
                } else {
                    _control ctrlSetText "?";
                    _control ctrlSetBackgroundColor [0.18, 0.18, 0.20, 1];
                };
            };
            _control ctrlCommit 0;
        };
    };
    private _revealControl = _display getVariable ["Waldo_MG_ShotgunRevealControl", controlNull];
    if (!isNull _revealControl) then {
        private _showReveal = _phase == "REVEAL" && {_lastShell in [0, 1]};
        _revealControl ctrlShow _showReveal;
        if (_showReveal) then {
            _revealControl ctrlSetText (if (_lastShell == 1) then {"LIVE"} else {"BLANK"});
            _revealControl ctrlSetBackgroundColor (if (_lastShell == 1) then {[0.62, 0.035, 0.025, 1]} else {[0.025, 0.28, 0.58, 1]});
        };
        _revealControl ctrlCommit 0;
    };

    private _peek = if (_spectating || {isNull player}) then {[]} else {player getVariable ["Waldo_MG_ShotgunPrivatePeek", []]};
    private _peekValid = (count _peek) >= 3
        && {(_peek param [0, ""]) == (_table getVariable ["Waldo_MG_ShotgunGameId", ""])}
        && {(_peek param [1, -1]) == _chamberVersion};
    if (!isNull _peekLabel) then {
        _peekLabel ctrlShow (!_spectating && {_role >= 0});
        _peekLabel ctrlSetText (if (_peekValid) then {
            format ["SPYGLASS  /  CURRENT SHELL IS %1", if ((_peek param [2, -1]) == 1) then {"LIVE"} else {"BLANK"}]
        } else {
            "SPYGLASS  /  NO CURRENT PRIVATE PEEK"
        });
        _peekLabel ctrlSetTextColor (if (_peekValid) then {if ((_peek param [2, -1]) == 1) then {[1, 0.45, 0.38, 1]} else {[0.43, 0.72, 1, 1]}} else {[0.52, 0.61, 0.67, 1]});
        _peekLabel ctrlCommit 0;
    };

    private _cuffSlot = _display getVariable ["Waldo_MG_ShotgunCuffSlotLocal", -1];
    private _yourInventory = if (_role >= 0) then {_inventories param [_role, []]} else {[]};
    if (_cuffSlot >= (count _yourInventory) || {_cuffSlot >= 0 && {(_yourInventory param [_cuffSlot, ""]) != "CUFFS"}}) then {
        _cuffSlot = -1;
        _display setVariable ["Waldo_MG_ShotgunCuffSlotLocal", -1];
    };
    private _canAct = !_spectating && {_phase == "PLAYING"} && {_role >= 0} && {_actor == _role} && {_alive param [_role, false]};
    private _targetButtons = _display getVariable ["Waldo_MG_ShotgunTargetButtons", []];
    for "_index" from 0 to ((count _targetButtons) - 1) do {
        private _button = _targetButtons param [_index, controlNull];
        if (!isNull _button) then {
            private _exists = _index < (count _names);
            private _validTarget = _exists && {_alive param [_index, false]};
            if (_cuffSlot >= 0) then {_validTarget = _validTarget && {_index != _role} && {!(_cuffs param [_index, false])};};
            _button ctrlShow (!_spectating && {_phase != "FINISHED"} && {_exists});
            _button ctrlEnable (_canAct && {_validTarget});
            _button ctrlSetText (if (_cuffSlot >= 0) then {
                format ["CUFF P%1  /  %2", _index + 1, _names param [_index, "Player"]]
            } else {
                format ["FIRE %1  /  %2", if (_index == _role) then {"AT SELF"} else {format ["AT P%1", _index + 1]}, _names param [_index, "Player"]]
            });
            _button ctrlCommit 0;
        };
    };
    private _itemButtons = _display getVariable ["Waldo_MG_ShotgunItemButtons", []];
    for "_slot" from 0 to ((count _itemButtons) - 1) do {
        private _button = _itemButtons param [_slot, controlNull];
        if (!isNull _button) then {
            private _item = _yourInventory param [_slot, ""];
            _button setVariable ["Waldo_MG_ShotgunItemId", _item];
            _button ctrlShow (!_spectating && {_phase != "FINISHED"} && {_role >= 0});
            _button ctrlEnable (_canAct && {_item != ""});
            _button ctrlSetText (if (_item == "") then {format ["ITEM %1  /  EMPTY", _slot + 1]} else {format ["%1%2", [_item] call Waldo_MG_fnc_shotgunItemLabel, if (_cuffSlot == _slot) then {"  /  SELECT TARGET"} else {""}]});
            _button ctrlSetBackgroundColor (if (_cuffSlot == _slot) then {[0.42, 0.22, 0.045, 1]} else {[0.10, 0.15, 0.18, 1]});
            _button ctrlCommit 0;
        };
    };
    if (!isNull _instructionLabel) then {
        _instructionLabel ctrlSetText (if (_phase == "LOADING") then {
            "MEMORIZE THE INITIAL LIVE / BLANK MIX  /  THE COLOUR LEDGER DISAPPEARS WHEN THE LOAD BEGINS"
        } else {if (_spectating) then {
            "SPECTATOR VIEW  /  PRIVATE SPYGLASS RESULTS AND CHAMBER ORDER REMAIN HIDDEN"
        } else {
            if (_phase == "FINISHED") then {"MATCH COMPLETE  /  RETURN TO THE LOBBY WHEN THE TABLE IS READY"} else {if (_cuffSlot >= 0) then {"HANDCUFFS ARMED  /  SELECT ANOTHER LIVING PLAYER ABOVE  /  PRESS THE ITEM AGAIN TO CANCEL"} else {if (_canAct) then {"YOUR TURN  /  CHOOSE A TARGET OR USE AN ITEM  /  ITEMS DO NOT END YOUR TURN"} else {"WAIT FOR THE SHOTGUN  /  SELF + BLANK RETAINS THE TURN  /  EVERY OTHER SHOT PASSES IT"}}}
        }});
        _instructionLabel ctrlCommit 0;
    };
    private _resetButton = _display getVariable ["Waldo_MG_ShotgunResetButton", controlNull];
    if (!isNull _resetButton) then {
        _resetButton ctrlShow (!_spectating && {_phase == "FINISHED"});
        _resetButton ctrlEnable (!_spectating && {_phase == "FINISHED"});
        _resetButton ctrlCommit 0;
    };
    _display setVariable ["Waldo_MG_ShotgunRefreshing", false];
};

Waldo_MG_fnc_openShotgunLocal = {
    disableSerialization;
    params [
        ["_table", objNull],
        ["_spectating", false]
    ];
    if (!hasInterface || {isNull player}) exitWith {};
    if (
        isNull _table
        || {!([_table, _spectating] call Waldo_MG_fnc_isValidGameViewerLocal)}
        || {([_table] call Waldo_MG_fnc_getTableActiveGameId) != "shotgun"}
    ) exitWith {
        hintSilent "No active Shotgun Roulette table is available to this viewer.";
    };
    private _parent = findDisplay 46;
    if (isNull _parent) exitWith {hintSilent "The Shotgun Roulette display is unavailable.";};
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
    uiNamespace setVariable ["Waldo_MG_ShotgunDisplay", _display];
    _display setVariable ["Waldo_MG_ShotgunTable", _table];
    _display setVariable ["Waldo_MG_SpectatorMode", _spectating];
    _display setVariable ["Waldo_MG_ShotgunCuffSlotLocal", -1];
    [_display] call Waldo_MG_fnc_installEscapeGuardLocal;

    private _background = _display ctrlCreate ["RscText", -1];
    _background ctrlSetPosition [0.005, 0.015, 1.17, 1.055];
    _background ctrlSetBackgroundColor [0.010, 0.014, 0.018, 0.992];
    _background ctrlCommit 0;
    private _topBar = _display ctrlCreate ["RscText", -1];
    _topBar ctrlSetPosition [0.005, 0.015, 1.17, 0.073];
    _topBar ctrlSetBackgroundColor [0.24, 0.055, 0.035, 1];
    _topBar ctrlCommit 0;
    private _title = _display ctrlCreate ["RscText", -1];
    _title ctrlSetPosition [0.035, 0.026, 0.420, 0.048];
    _title ctrlSetText "PARTYGAMES  /  SHOTGUN ROULETTE";
    _title ctrlSetTextColor [1, 0.88, 0.78, 1];
    _title ctrlSetFontHeight 0.0375;
    _title ctrlCommit 0;
    private _loadLabel = _display ctrlCreate ["RscText", -1];
    _loadLabel ctrlSetPosition [0.465, 0.029, 0.245, 0.040];
    _loadLabel ctrlSetTextColor [0.88, 0.86, 0.82, 1];
    _loadLabel ctrlSetFontHeight 0.0245;
    _loadLabel ctrlCommit 0;
    private _phaseLabel = _display ctrlCreate ["RscText", -1];
    _phaseLabel ctrlSetPosition [0.710, 0.029, 0.275, 0.040];
    _phaseLabel ctrlSetFontHeight 0.0245;
    _phaseLabel ctrlCommit 0;
    private _exitButton = _display ctrlCreate ["RscButtonMenu", -1];
    _exitButton ctrlSetPosition [0.985, 0.025, 0.165, 0.048];
    _exitButton ctrlSetText (if (_spectating) then {"Exit Spectate"} else {"Leave Table"});
    _exitButton ctrlSetFontHeight 0.022;
    _exitButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_handleViewerExitButtonLocal;}];
    _exitButton ctrlCommit 0;

    private _playerPanels = [];
    {
        private _xPos = _x param [0, 0.025];
        private _yPos = _x param [1, 0.105];
        private _panel = _display ctrlCreate ["RscText", -1];
        _panel ctrlSetPosition [_xPos, _yPos, 0.350, 0.205];
        _panel ctrlSetBackgroundColor [0.025, 0.080, 0.110, 0.97];
        _panel ctrlCommit 0;
        private _name = _display ctrlCreate ["RscText", -1];
        _name ctrlSetPosition [_xPos + 0.015, _yPos + 0.010, 0.320, 0.045];
        _name ctrlSetTextColor [0.80, 0.91, 1, 1];
        _name ctrlSetFontHeight 0.030;
        _name ctrlCommit 0;
        private _livesText = _display ctrlCreate ["RscText", -1];
        _livesText ctrlSetPosition [_xPos + 0.015, _yPos + 0.057, 0.320, 0.040];
        _livesText ctrlSetTextColor [1, 0.80, 0.40, 1];
        _livesText ctrlSetFontHeight 0.0235;
        _livesText ctrlCommit 0;
        private _inventory = _display ctrlCreate ["RscText", -1];
        _inventory ctrlSetPosition [_xPos + 0.015, _yPos + 0.101, 0.320, 0.040];
        _inventory ctrlSetTextColor [0.70, 0.80, 0.85, 1];
        _inventory ctrlSetFontHeight 0.019;
        _inventory ctrlCommit 0;
        private _action = _display ctrlCreate ["RscText", -1];
        _action ctrlSetPosition [_xPos + 0.015, _yPos + 0.145, 0.320, 0.045];
        _action ctrlSetTextColor [0.62, 0.72, 0.78, 1];
        _action ctrlSetFontHeight 0.019;
        _action ctrlCommit 0;
        _playerPanels pushBack [_panel, _name, _livesText, _inventory, _action];
    } forEach [[0.025, 0.105], [0.805, 0.105], [0.025, 0.325], [0.805, 0.325]];

    private _shotgunPanel = _display ctrlCreate ["RscText", -1];
    _shotgunPanel ctrlSetPosition [0.390, 0.105, 0.400, 0.425];
    _shotgunPanel ctrlSetBackgroundColor [0.040, 0.045, 0.050, 0.99];
    _shotgunPanel ctrlCommit 0;
    private _shotgunTitle = _display ctrlCreate ["RscText", -1];
    _shotgunTitle ctrlSetPosition [0.415, 0.125, 0.350, 0.070];
    _shotgunTitle ctrlSetText "SHOTGUN";
    _shotgunTitle ctrlSetTextColor [0.92, 0.90, 0.84, 1];
    _shotgunTitle ctrlSetFontHeight 0.055;
    _shotgunTitle ctrlCommit 0;
    private _ledgerLabel = _display ctrlCreate ["RscText", -1];
    _ledgerLabel ctrlSetPosition [0.415, 0.195, 0.350, 0.045];
    _ledgerLabel ctrlSetFontHeight 0.022;
    _ledgerLabel ctrlCommit 0;
    private _shellControls = [];
    for "_slot" from 0 to 7 do {
        private _column = _slot mod 4;
        private _row = floor (_slot / 4);
        private _shell = _display ctrlCreate ["RscText", -1];
        _shell ctrlSetPosition [0.415 + (_column * 0.087), 0.250 + (_row * 0.070), 0.075, 0.058];
        _shell ctrlSetTextColor [1, 1, 1, 1];
        _shell ctrlSetFontHeight 0.020;
        _shell ctrlCommit 0;
        _shellControls pushBack _shell;
    };
    private _revealControl = _display ctrlCreate ["RscText", -1];
    _revealControl ctrlSetPosition [0.445, 0.400, 0.290, 0.080];
    _revealControl ctrlSetTextColor [1, 1, 1, 1];
    _revealControl ctrlSetFontHeight 0.055;
    _revealControl ctrlShow false;
    _revealControl ctrlCommit 0;
    private _peekLabel = _display ctrlCreate ["RscText", -1];
    _peekLabel ctrlSetPosition [0.410, 0.492, 0.360, 0.027];
    _peekLabel ctrlSetFontHeight 0.019;
    _peekLabel ctrlCommit 0;

    private _statusPanel = _display ctrlCreate ["RscText", -1];
    _statusPanel ctrlSetPosition [0.025, 0.548, 1.130, 0.105];
    _statusPanel ctrlSetBackgroundColor [0.055, 0.030, 0.025, 0.98];
    _statusPanel ctrlCommit 0;
    private _statusLabel = _display ctrlCreate ["RscText", -1];
    _statusLabel ctrlSetPosition [0.045, 0.560, 1.090, 0.042];
    _statusLabel ctrlSetTextColor [0.95, 0.91, 0.86, 1];
    _statusLabel ctrlSetFontHeight 0.0245;
    _statusLabel ctrlCommit 0;
    private _instructionLabel = _display ctrlCreate ["RscText", -1];
    _instructionLabel ctrlSetPosition [0.045, 0.607, 1.090, 0.033];
    _instructionLabel ctrlSetTextColor [0.67, 0.72, 0.75, 1];
    _instructionLabel ctrlSetFontHeight 0.020;
    _instructionLabel ctrlCommit 0;

    private _targetButtons = [];
    for "_index" from 0 to 3 do {
        private _button = _display ctrlCreate ["RscButtonMenu", -1];
        _button ctrlSetPosition [0.025 + (_index * 0.285), 0.670, 0.265, 0.075];
        _button ctrlSetFontHeight 0.0235;
        _button setVariable ["Waldo_MG_ShotgunTargetRole", _index];
        _button ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_handleShotgunTargetClickLocal;}];
        _button ctrlCommit 0;
        _targetButtons pushBack _button;
    };
    private _itemButtons = [];
    for "_slot" from 0 to (Waldo_MG_CFG_SHOTGUN_INVENTORY_LIMIT - 1) do {
        private _button = _display ctrlCreate ["RscButtonMenu", -1];
        _button ctrlSetPosition [0.025 + (_slot * 0.285), 0.765, 0.265, 0.070];
        _button ctrlSetFontHeight 0.022;
        _button setVariable ["Waldo_MG_ShotgunItemSlot", _slot];
        _button ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_handleShotgunItemClickLocal;}];
        _button ctrlCommit 0;
        _itemButtons pushBack _button;
    };
    private _itemHelpOne = _display ctrlCreate ["RscText", -1];
    _itemHelpOne ctrlSetPosition [0.045, 0.850, 1.090, 0.034];
    _itemHelpOne ctrlSetText "BLADE: NEXT SHOT DEALS 2  /  BEER: EJECT SHELL  /  CIGAR: +1 LIFE  /  SPYGLASS: PRIVATE PEEK";
    _itemHelpOne ctrlSetTextColor [0.66, 0.72, 0.75, 1];
    _itemHelpOne ctrlSetFontHeight 0.020;
    _itemHelpOne ctrlCommit 0;
    private _itemHelpTwo = _display ctrlCreate ["RscText", -1];
    _itemHelpTwo ctrlSetPosition [0.045, 0.886, 1.090, 0.034];
    _itemHelpTwo ctrlSetText "HANDCUFFS: SKIP A PLAYER'S NEXT TURN  /  INVERTER: FLIP CURRENT SHELL  /  ITEMS KEEP YOUR TURN";
    _itemHelpTwo ctrlSetTextColor [0.56, 0.64, 0.68, 1];
    _itemHelpTwo ctrlSetFontHeight 0.020;
    _itemHelpTwo ctrlCommit 0;
    private _resetButton = _display ctrlCreate ["RscButtonMenu", -1];
    _resetButton ctrlSetPosition [0.390, 0.936, 0.400, 0.070];
    _resetButton ctrlSetText "Return to Lobby";
    _resetButton ctrlSetFontHeight 0.0265;
    _resetButton ctrlSetBackgroundColor [0.30, 0.15, 0.055, 1];
    _resetButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_handleShotgunResetClickLocal;}];
    _resetButton ctrlCommit 0;
    private _rules = _display ctrlCreate ["RscText", -1];
    _rules ctrlSetPosition [0.045, 1.015, 1.090, 0.030];
    _rules ctrlSetText "LAST PLAYER STANDING WINS  /  SELF + BLANK RETAINS TURN  /  LIVE OR FIRING AT ANOTHER PLAYER PASSES TURN";
    _rules ctrlSetTextColor [0.50, 0.56, 0.59, 1];
    _rules ctrlSetFontHeight 0.018;
    _rules ctrlCommit 0;

    _display setVariable ["Waldo_MG_ShotgunLoadLabel", _loadLabel];
    _display setVariable ["Waldo_MG_ShotgunPhaseLabel", _phaseLabel];
    _display setVariable ["Waldo_MG_ShotgunLedgerLabel", _ledgerLabel];
    _display setVariable ["Waldo_MG_ShotgunPlayerPanels", _playerPanels];
    _display setVariable ["Waldo_MG_ShotgunShellControls", _shellControls];
    _display setVariable ["Waldo_MG_ShotgunRevealControl", _revealControl];
    _display setVariable ["Waldo_MG_ShotgunPeekLabel", _peekLabel];
    _display setVariable ["Waldo_MG_ShotgunStatusLabel", _statusLabel];
    _display setVariable ["Waldo_MG_ShotgunInstructionLabel", _instructionLabel];
    _display setVariable ["Waldo_MG_ShotgunTargetButtons", _targetButtons];
    _display setVariable ["Waldo_MG_ShotgunItemButtons", _itemButtons];
    _display setVariable ["Waldo_MG_ShotgunResetButton", _resetButton];
    [_display] call Waldo_MG_fnc_scaleShotgunDisplayLocal;
    [_display] call Waldo_MG_fnc_refreshShotgunLocal;
    [_display] spawn {
        disableSerialization;
        params ["_activeDisplay"];
        while {!isNull _activeDisplay} do {
            [_activeDisplay] call Waldo_MG_fnc_refreshShotgunLocal;
            uiSleep Waldo_MG_CFG_SHOTGUN_UI_TICK;
        };
    };
}; 
 

