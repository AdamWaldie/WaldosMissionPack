/*
 * Author: WaldoTheWarfighter
 * Waldos Mini Games - Who's Who: Vehicles
 * All Waldo_MG_fnc_* functions implementing the Who's Who: Vehicles mini game (server logic + local UI).
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

Waldo_MG_fnc_whosWhoFriendlyName = {
    params [["_displayName", "Vehicle"]];
    private _lower = toLower _displayName;
    private _friendly = "";
    {
        if (_friendly == "" && {(_lower find (_x param [0, ""])) >= 0}) then {
            _friendly = _x param [1, "Vehicle"];
        };
    } forEach [
        ["blackfish", "Blackfish"], ["blackfoot", "Blackfoot"],
        ["ghost hawk", "Ghost Hawk"], ["hummingbird", "Hummingbird"],
        ["pawnee", "Pawnee"], ["huron", "Huron"], ["wipeout", "Wipeout"],
        ["greyhawk", "Greyhawk"], ["sentinel", "Sentinel"],
        ["panther", "Panther"], ["marshall", "Marshall"],
        ["slammer", "Slammer"], ["cheetah", "Cheetah"],
        ["bobcat", "Bobcat"], ["scorcher", "Scorcher"],
        ["sandstorm", "Sandstorm"], ["hunter", "Hunter"],
        ["rhino", "Rhino"], ["prowler", "Prowler"],
        ["stomper", "Stomper"], ["darter", "Darter"],
        ["pelican", "Pelican"], ["falcon", "Falcon"],
        ["kajman", "Kajman"], ["varsuk", "Varsuk"],
        ["marid", "Marid"], ["kamysh", "Kamysh"], ["tigris", "Tigris"],
        ["ifrit", "Ifrit"], ["tempest", "Tempest"], ["qilin", "Qilin"],
        ["xi'an", "Xi'an"], ["xian", "Xi'an"], ["orca", "Orca"],
        ["taru", "Taru"], ["neophron", "Neophron"], ["shikra", "Shikra"],
        ["ababil", "Ababil"], ["saif", "Saif"],
        ["gorgon", "Gorgon"], ["strider", "Strider"], ["mora", "Mora"],
        ["kuma", "Kuma"], ["nyx", "Nyx"], ["buzzard", "Buzzard"],
        ["hellcat", "Hellcat"], ["mohawk", "Mohawk"], ["zamak", "Zamak"],
        ["caesar", "Caesar"], ["m-900", "M-900"], ["m900", "M-900"],
        ["water scooter", "Water Scooter"], ["rescue boat", "Rescue Boat"],
        ["speedboat", "Speedboat"], ["motorboat", "Motorboat"],
        ["assault boat", "Assault Boat"], ["submersible", "SDV"],
        ["sdv", "SDV"], ["quad bike", "Quad Bike"], ["quadbike", "Quad Bike"],
        ["hatchback", "Hatchback"], ["offroad", "Offroad"],
        ["sport hatch", "Hatchback Sport"], ["suv", "SUV"],
        ["minivan", "Van"], ["van", "Van"], ["kart", "Kart"],
        ["tractor", "Tractor"], ["truck", "Truck"]
    ];
    if (_friendly == "") then {
        private _parts = _displayName splitString "(";
        _friendly = _parts param [0, _displayName];
    };
    _friendly
};

Waldo_MG_fnc_whosWhoBuildCatalogServer = {
    if (!isServer) exitWith {[]};
    private _cached = missionNamespace getVariable ["Waldo_MG_WhosWhoCatalogServer", []];
    if ((count _cached) == 4) exitWith {_cached};
    private _groups = [[], [], [], []];
    private _keys = [[], [], [], []];
    private _root = configFile >> "CfgVehicles";
    for "_index" from 0 to ((count _root) - 1) do {
        private _entry = _root select _index;
        if (isClass _entry && {(getNumber (_entry >> "scope")) == 2}) then {
            private _className = configName _entry;
            private _preview = getText (_entry >> "editorPreview");
            private _displayName = getText (_entry >> "displayName");
            private _faction = toLower (getText (_entry >> "faction"));
            private _group = -1;
            if (_faction in ["blu_f", "blu_t_f", "blu_w_f", "blu_ctrg_f"]) then {_group = 0;};
            if (_faction in ["opf_f", "opf_t_f", "opf_r_f"]) then {_group = 1;};
            if (_faction == "ind_f") then {_group = 2;};
            if (_faction in ["civ_f", "civ_idap_f"]) then {_group = 3;};
            private _vehicleKind = (_className isKindOf "LandVehicle")
                || {_className isKindOf "Air"}
                || {_className isKindOf "Ship"}
                || {_className isKindOf "Submarine"};
            private _excluded = (_className isKindOf "Man") || {_className isKindOf "StaticWeapon"};
            if (_group >= 0 && {_preview != ""} && {_displayName != ""} && {_vehicleKind} && {!_excluded}) then {
                private _friendly = [_displayName] call Waldo_MG_fnc_whosWhoFriendlyName;
                private _key = toLower _friendly;
                private _groupKeys = _keys param [_group, []];
                if (!(_key in _groupKeys)) then {
                    _groupKeys pushBack _key;
                    _keys set [_group, _groupKeys];
                    private _groupEntries = _groups param [_group, []];
                    _groupEntries pushBack [_className, _friendly, _preview];
                    _groups set [_group, _groupEntries];
                };
            };
        };
    };
    missionNamespace setVariable ["Waldo_MG_WhosWhoCatalogServer", _groups];
    _groups
};

Waldo_MG_fnc_whosWhoShuffleServer = {
    params [["_source", []]];
    private _pool = +_source;
    private _result = [];
    while {(count _pool) > 0} do {
        _result pushBack (_pool deleteAt (floor (random (count _pool))));
    };
    _result
};

Waldo_MG_fnc_whosWhoCreateBoardServer = {
    if (!isServer) exitWith {[]};
    private _catalog = call Waldo_MG_fnc_whosWhoBuildCatalogServer;
    if ((count _catalog) != 4) exitWith {[]};
    private _rowOrder = [[0, 1, 2, 3]] call Waldo_MG_fnc_whosWhoShuffleServer;
    private _board = [];
    {
        private _available = _catalog param [_x, []];
        if ((count _available) < Waldo_MG_CFG_WHOSWHO_PER_FACTION) exitWith {
            _board = [];
        };
        private _shuffled = [_available] call Waldo_MG_fnc_whosWhoShuffleServer;
        private _row = [];
        for "_column" from 0 to (Waldo_MG_CFG_WHOSWHO_PER_FACTION - 1) do {
            _row pushBack (+(_shuffled param [_column, []]));
        };
        _board pushBack _row;
    } forEach _rowOrder;
    _board
};

Waldo_MG_fnc_whosWhoCreateEmptySnapshot = {
    ["IDLE", -1, ["Waiting", "Waiting"], -1, "Waiting for Who's Who: Vehicles.", -1, -1, false, [], 0]
};

Waldo_MG_fnc_whosWhoPublishRevisionServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    _table setVariable ["Waldo_MG_WhosWhoRevision", (_table getVariable ["Waldo_MG_WhosWhoRevision", 0]) + 1, true];
    _table setVariable ["Waldo_MG_TableRevision", (_table getVariable ["Waldo_MG_TableRevision", 0]) + 1, true];
};

Waldo_MG_fnc_whosWhoSetSnapshotServer = {
    params [["_table", objNull], ["_snapshot", []]];
    if (!isServer || {isNull _table}) exitWith {};
    _table setVariable ["Waldo_MG_WhosWhoSnapshotServer", _snapshot];
    _table setVariable ["Waldo_MG_WhosWhoSnapshot", _snapshot, true];
    [_table] call Waldo_MG_fnc_whosWhoPublishRevisionServer;
};

Waldo_MG_fnc_whosWhoSendPrivateTargetServer = {
    params [["_table", objNull], ["_role", -1]];
    if (!isServer || {isNull _table}) exitWith {};
    private _players = _table getVariable ["Waldo_MG_WhosWhoPlayers", []];
    private _targets = _table getVariable ["Waldo_MG_WhosWhoTargetsServer", []];
    private _unit = _players param [_role, objNull];
    if (!isNull _unit && {_role >= 0} && {_role < (count _targets)}) then {
        _unit setVariable [
            "Waldo_MG_WhosWhoPrivateTarget",
            [_table getVariable ["Waldo_MG_WhosWhoGameId", ""], _targets param [_role, -1]],
            owner _unit
        ];
    };
};

Waldo_MG_fnc_whosWhoClearServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    {
        if (!isNull _x) then {_x setVariable ["Waldo_MG_WhosWhoPrivateTarget", [], owner _x];};
    } forEach (_table getVariable ["Waldo_MG_WhosWhoPlayers", []]);
    _table setVariable ["Waldo_MG_WhosWhoActive", false, true];
    _table setVariable ["Waldo_MG_WhosWhoFinished", false, true];
    _table setVariable ["Waldo_MG_WhosWhoGameId", "", true];
    _table setVariable ["Waldo_MG_WhosWhoPlayers", [], true];
    _table setVariable ["Waldo_MG_WhosWhoPlayerNames", [], true];
    _table setVariable ["Waldo_MG_WhosWhoSeatIndices", [], true];
    _table setVariable ["Waldo_MG_WhosWhoBoard", [], true];
    _table setVariable ["Waldo_MG_WhosWhoTargetsServer", []];
    _table setVariable ["Waldo_MG_WhosWhoRevision", 0, true];
    private _empty = call Waldo_MG_fnc_whosWhoCreateEmptySnapshot;
    _table setVariable ["Waldo_MG_WhosWhoSnapshotServer", _empty];
    _table setVariable ["Waldo_MG_WhosWhoSnapshot", _empty, true];
    [_table] call Waldo_MG_fnc_whosWhoPublishRevisionServer;
};

Waldo_MG_fnc_whosWhoStartServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {false};
    if ([_table] call Waldo_MG_fnc_isTableGameActive) exitWith {false};
    if ((_table getVariable ["Waldo_MG_TableSelectedGame", ""]) != "whoswho") exitWith {false};
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
    private _board = call Waldo_MG_fnc_whosWhoCreateBoardServer;
    if ((count _board) != 4) exitWith {false};
    private _total = Waldo_MG_CFG_WHOSWHO_PER_FACTION * 4;
    private _firstTarget = floor (random _total);
    private _secondTarget = floor (random (_total - 1));
    if (_secondTarget >= _firstTarget) then {_secondTarget = _secondTarget + 1;};
    private _actor = floor (random 2);
    private _snapshot = [
        "PLAYING", _actor, ["Asking questions", "Asking questions"], -1,
        format ["%1 asks the first yes-or-no question.", _names param [_actor, "Player"]],
        -1, -1, false, [], 0
    ];
    _table setVariable ["Waldo_MG_WhosWhoActive", true, true];
    _table setVariable ["Waldo_MG_WhosWhoFinished", false, true];
    _table setVariable ["Waldo_MG_WhosWhoGameId", format ["Waldo_MG_WHOSWHO_%1_%2", floor (serverTime * 10), floor (random 1000000)], true];
    _table setVariable ["Waldo_MG_WhosWhoPlayers", _players, true];
    _table setVariable ["Waldo_MG_WhosWhoPlayerNames", _names, true];
    _table setVariable ["Waldo_MG_WhosWhoSeatIndices", _seatIndices, true];
    _table setVariable ["Waldo_MG_WhosWhoBoard", _board, true];
    _table setVariable ["Waldo_MG_WhosWhoTargetsServer", [_firstTarget, _secondTarget]];
    _table setVariable ["Waldo_MG_WhosWhoRevision", 0, true];
    _table setVariable ["Waldo_MG_TablePhase", "PLAYING", true];
    [_table, _snapshot] call Waldo_MG_fnc_whosWhoSetSnapshotServer;
    [_table, 0] call Waldo_MG_fnc_whosWhoSendPrivateTargetServer;
    [_table, 1] call Waldo_MG_fnc_whosWhoSendPrivateTargetServer;
    true
};

Waldo_MG_fnc_whosWhoFinishServer = {
    params [["_table", objNull], ["_snapshot", []], ["_winner", -1], ["_message", "Who's Who is finished."]];
    if (!isServer || {isNull _table}) exitWith {};
    private _state = +_snapshot;
    _state set [0, "FINISHED"];
    _state set [1, -1];
    _state set [3, _winner];
    _state set [4, _message];
    _state set [8, +(_table getVariable ["Waldo_MG_WhosWhoTargetsServer", []])];
    _table setVariable ["Waldo_MG_WhosWhoFinished", true, true];
    _table setVariable ["Waldo_MG_TablePhase", "FINISHED", true];
    [_table, _state] call Waldo_MG_fnc_whosWhoSetSnapshotServer;
};

Waldo_MG_fnc_whosWhoResetServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    [_table] call Waldo_MG_fnc_whosWhoClearServer;
    _table setVariable ["Waldo_MG_TableReady", [false, false, false, false], true];
    [_table] call Waldo_MG_fnc_refreshTableConsensusServer;
};

Waldo_MG_fnc_whosWhoHandleDepartureServer = {
    params [["_table", objNull], ["_unit", objNull], ["_seatIndex", -1]];
    if (!isServer || {isNull _table} || {!(_table getVariable ["Waldo_MG_WhosWhoActive", false])}) exitWith {};
    private _players = _table getVariable ["Waldo_MG_WhosWhoPlayers", []];
    private _seatIndices = _table getVariable ["Waldo_MG_WhosWhoSeatIndices", []];
    private _role = if (isNull _unit) then {-1} else {_players find _unit};
    if (_role < 0 && {_seatIndex >= 0}) then {_role = _seatIndices find _seatIndex;};
    if (_role < 0) exitWith {};
    private _other = 1 - _role;
    private _state = +(_table getVariable ["Waldo_MG_WhosWhoSnapshotServer", []]);
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
        [_table] call Waldo_MG_fnc_whosWhoClearServer;
        _table setVariable ["Waldo_MG_TableReady", [false, false, false, false], true];
        _table setVariable ["Waldo_MG_TablePhase", "LOBBY", true];
        [_table] call Waldo_MG_fnc_refreshTableConsensusServer;
    };
    if ((_state param [0, ""]) == "FINISHED") exitWith {};
    private _names = _table getVariable ["Waldo_MG_WhosWhoPlayerNames", []];
    [_table, _state, _other, format ["%1 wins after %2 leaves the table.", _names param [_other, "Player"], _names param [_role, "Player"]]] call Waldo_MG_fnc_whosWhoFinishServer;
};

Waldo_MG_fnc_whosWhoReconcilePlayersServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table} || {!(_table getVariable ["Waldo_MG_WhosWhoActive", false])}) exitWith {};
    private _players = _table getVariable ["Waldo_MG_WhosWhoPlayers", []];
    private _seatIndices = _table getVariable ["Waldo_MG_WhosWhoSeatIndices", []];
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
            [_table, _unit, _seat] call Waldo_MG_fnc_whosWhoHandleDepartureServer;
        };
    };
}; 
 

Waldo_MG_fnc_processWhosWhoActionRequestServer = {
    params [["_unit", objNull], ["_request", []]];
    if (!isServer || {isNull _unit}) exitWith {};
    if ((count _request) < 6) exitWith {};
    private _token = _request param [0, ""];
    if (!([_token] call Waldo_MG_fnc_rememberHandledTokenServer)) exitWith {};
    private _tableNetId = _request param [1, ""];
    private _gameId = _request param [2, ""];
    private _expectedRevision = _request param [3, -1];
    private _action = _request param [4, ""];
    private _payload = _request param [5, -1];
    if ((typeName _tableNetId) != "STRING" || {(typeName _gameId) != "STRING"} || {(typeName _expectedRevision) != "SCALAR"} || {(typeName _action) != "STRING"}) exitWith {
        [_unit, _token, "Who's Who action rejected: malformed request data."] call Waldo_MG_fnc_resultServer;
    };
    private _table = objectFromNetId _tableNetId;
    if (isNull _table || {_table != (_unit getVariable ["Waldo_MG_SeatedTable", objNull])}) exitWith {
        [_unit, _token, "Who's Who action rejected: you are no longer seated at that table."] call Waldo_MG_fnc_resultServer;
    };
    if (!(_table getVariable ["Waldo_MG_WhosWhoActive", false])) exitWith {
        [_unit, _token, "There is no active Who's Who match at this table."] call Waldo_MG_fnc_resultServer;
    };
    if (_gameId == "" || {_gameId != (_table getVariable ["Waldo_MG_WhosWhoGameId", ""])}) exitWith {
        [_unit, _token, "That Who's Who match is no longer current."] call Waldo_MG_fnc_resultServer;
    };
    private _players = _table getVariable ["Waldo_MG_WhosWhoPlayers", []];
    private _role = _players find _unit;
    if (_role < 0) exitWith {
        [_unit, _token, "Only the two assigned players may act in Who's Who."] call Waldo_MG_fnc_resultServer;
    };
    if (_action == "SYNC") exitWith {
        [_table, _role] call Waldo_MG_fnc_whosWhoSendPrivateTargetServer;
        [_unit, _token, "Your private vehicle target was synchronized."] call Waldo_MG_fnc_resultServer;
    };
    private _state = +(_table getVariable ["Waldo_MG_WhosWhoSnapshotServer", []]);
    private _phase = _state param [0, "IDLE"];
    if (_action == "RESET") exitWith {
        if (_phase != "FINISHED") then {
            [_unit, _token, "Finish the match before returning to the lobby."] call Waldo_MG_fnc_resultServer;
        } else {
            [_table] call Waldo_MG_fnc_whosWhoResetServer;
            [_unit, _token, "Who's Who cleared. The table has returned to its lobby."] call Waldo_MG_fnc_resultServer;
        };
    };
    if (_expectedRevision != (_table getVariable ["Waldo_MG_WhosWhoRevision", -1])) exitWith {
        [_unit, _token, "The Who's Who turn changed before that action arrived."] call Waldo_MG_fnc_resultServer;
    };
    if (_phase != "PLAYING" || {(_state param [1, -1]) != _role}) exitWith {
        [_unit, _token, "It is not your Who's Who turn."] call Waldo_MG_fnc_resultServer;
    };
    private _names = _table getVariable ["Waldo_MG_WhosWhoPlayerNames", []];
    private _actions = +(_state param [2, ["Waiting", "Waiting"]]);
    private _other = 1 - _role;
    if (_action == "PASS") exitWith {
        _actions set [_role, "Asked a question and passed"];
        _state set [1, _other];
        _state set [2, _actions];
        _state set [4, format ["%1 passed the turn. %2 may ask the next question.", _names param [_role, "Player"], _names param [_other, "Player"]]];
        _state set [5, -1];
        _state set [6, -1];
        _state set [7, false];
        _state set [9, (_state param [9, 0]) + 1];
        [_table, _state] call Waldo_MG_fnc_whosWhoSetSnapshotServer;
        [_unit, _token, "Turn passed."] call Waldo_MG_fnc_resultServer;
    };
    if (_action != "GUESS") exitWith {
        [_unit, _token, "Unknown Who's Who action."] call Waldo_MG_fnc_resultServer;
    };
    private _total = Waldo_MG_CFG_WHOSWHO_PER_FACTION * 4;
    if ((typeName _payload) != "SCALAR" || {_payload != floor _payload} || {_payload < 0} || {_payload >= _total}) exitWith {
        [_unit, _token, "Choose a valid vehicle portrait for your guess."] call Waldo_MG_fnc_resultServer;
    };
    private _guess = floor _payload;
    private _targets = _table getVariable ["Waldo_MG_WhosWhoTargetsServer", []];
    private _correct = _guess == (_targets param [_other, -1]);
    private _board = _table getVariable ["Waldo_MG_WhosWhoBoard", []];
    private _row = floor (_guess / Waldo_MG_CFG_WHOSWHO_PER_FACTION);
    private _column = _guess mod Waldo_MG_CFG_WHOSWHO_PER_FACTION;
    private _entry = (_board param [_row, []]) param [_column, []];
    private _label = _entry param [1, "Vehicle"];
    _actions set [_role, format ["Guessed %1 - %2", _label, if (_correct) then {"CORRECT"} else {"WRONG"}]];
    _state set [2, _actions];
    _state set [5, _role];
    _state set [6, _guess];
    _state set [7, _correct];
    _state set [9, (_state param [9, 0]) + 1];
    if (_correct) then {
        [_table, _state, _role, format ["%1 correctly identified %2 and wins Who's Who! Both hidden vehicles are revealed.", _names param [_role, "Player"], _label]] call Waldo_MG_fnc_whosWhoFinishServer;
        [_unit, _token, format ["Correct: %1 was the opposing vehicle.", _label]] call Waldo_MG_fnc_resultServer;
    } else {
        _state set [1, _other];
        _state set [4, format ["%1 guessed %2 incorrectly. It is crossed out locally; %3 takes the turn.", _names param [_role, "Player"], _label, _names param [_other, "Player"]]];
        [_table, _state] call Waldo_MG_fnc_whosWhoSetSnapshotServer;
        [_unit, _token, format ["Wrong guess: %1 was crossed out on your board.", _label]] call Waldo_MG_fnc_resultServer;
    };
};

Waldo_MG_fnc_submitWhosWhoActionRequestLocal = {
    params [["_table", objNull], ["_action", ""], ["_payload", -1]];
    if (!hasInterface || {isNull player} || {isNull _table} || {_action == ""}) exitWith {false};
    private _pending = missionNamespace getVariable ["Waldo_MG_WhosWhoPendingRequestLocal", []];
    if ((count _pending) >= 2 && {(diag_tickTime - (_pending param [1, -10])) < 1.5}) exitWith {
        ["Waiting for the table host to answer your previous Who's Who action..."] call Waldo_MG_fnc_notifyLocal;
        false
    };
    private _token = ["WHOSWHO_ACTION"] call Waldo_MG_fnc_makeToken;
    missionNamespace setVariable ["Waldo_MG_WhosWhoPendingRequestLocal", [_token, diag_tickTime]];
    private _request = [_token, netId _table, _table getVariable ["Waldo_MG_WhosWhoGameId", ""], _table getVariable ["Waldo_MG_WhosWhoRevision", -1], _action, _payload];
    ["WHOSWHO", _table, _token, _request param [3, -1], _request] call Waldo_MG_fnc_submitRequestLocal;
    true
};

Waldo_MG_fnc_getWhosWhoPlayerRoleLocal = {
    params [["_table", objNull]];
    if (isNull _table || {isNull player}) exitWith {-1};
    (_table getVariable ["Waldo_MG_WhosWhoPlayers", []]) find player
};

Waldo_MG_fnc_whosWhoGetEntryLocal = {
    params [["_board", []], ["_index", -1]];
    if (_index < 0 || {_index >= (Waldo_MG_CFG_WHOSWHO_PER_FACTION * 4)}) exitWith {[]};
    private _row = floor (_index / Waldo_MG_CFG_WHOSWHO_PER_FACTION);
    private _column = _index mod Waldo_MG_CFG_WHOSWHO_PER_FACTION;
    (_board param [_row, []]) param [_column, []]
};

Waldo_MG_fnc_whosWhoGetEliminatedLocal = {
    params [["_gameId", ""]];
    private _state = missionNamespace getVariable ["Waldo_MG_WhosWhoEliminatedStateLocal", []];
    if ((_state param [0, ""]) != _gameId) exitWith {[]};
    +(_state param [1, []])
};

Waldo_MG_fnc_whosWhoSetEliminatedLocal = {
    params [["_gameId", ""], ["_indices", []]];
    missionNamespace setVariable ["Waldo_MG_WhosWhoEliminatedStateLocal", [_gameId, +_indices]];
};

Waldo_MG_fnc_whosWhoSafePositionLocal = {
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

Waldo_MG_fnc_whosWhoDefocusLocal = {
    disableSerialization;
    params [["_display", displayNull]];
    if (isNull _display) exitWith {};
    private _sink = _display getVariable ["Waldo_MG_WhosWhoFocusSink", controlNull];
    if (!isNull _sink) then {ctrlSetFocus _sink;};
};

Waldo_MG_fnc_handleWhosWhoTileClickLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    if (isNull _display || {_display getVariable ["Waldo_MG_SpectatorMode", false]}) exitWith {};
    [_display] call Waldo_MG_fnc_whosWhoDefocusLocal;
    if (!(_control getVariable ["Waldo_MG_WhosWhoTileUsable", false])) exitWith {};
    private _table = _display getVariable ["Waldo_MG_WhosWhoTable", objNull];
    private _index = _control getVariable ["Waldo_MG_WhosWhoTileIndex", -1];
    if (isNull _table || {_index < 0}) exitWith {};
    private _snapshot = _table getVariable ["Waldo_MG_WhosWhoSnapshot", []];
    if ((_snapshot param [0, ""]) != "PLAYING") exitWith {};
    if (_display getVariable ["Waldo_MG_WhosWhoGuessArmedLocal", false]) then {
        private _role = [_table] call Waldo_MG_fnc_getWhosWhoPlayerRoleLocal;
        if ((_snapshot param [1, -1]) == _role) then {
            _display setVariable ["Waldo_MG_WhosWhoGuessArmedLocal", false];
            [_table, "GUESS", _index] call Waldo_MG_fnc_submitWhosWhoActionRequestLocal;
        };
    } else {
        private _gameId = _table getVariable ["Waldo_MG_WhosWhoGameId", ""];
        private _eliminated = [_gameId] call Waldo_MG_fnc_whosWhoGetEliminatedLocal;
        if (_index in _eliminated) then {
            _eliminated deleteAt (_eliminated find _index);
        } else {
            _eliminated pushBack _index;
        };
        [_gameId, _eliminated] call Waldo_MG_fnc_whosWhoSetEliminatedLocal;
    };
    [_display] call Waldo_MG_fnc_refreshWhosWhoLocal;
};

Waldo_MG_fnc_handleWhosWhoGuessButtonLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    if (isNull _display) exitWith {};
    [_display] call Waldo_MG_fnc_whosWhoDefocusLocal;
    _display setVariable ["Waldo_MG_WhosWhoGuessArmedLocal", !(_display getVariable ["Waldo_MG_WhosWhoGuessArmedLocal", false])];
    [_display] call Waldo_MG_fnc_refreshWhosWhoLocal;
};

Waldo_MG_fnc_handleWhosWhoActionButtonLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    [_display] call Waldo_MG_fnc_whosWhoDefocusLocal;
    private _table = if (isNull _display) then {objNull} else {_display getVariable ["Waldo_MG_WhosWhoTable", objNull]};
    [_table, _control getVariable ["Waldo_MG_WhosWhoAction", ""], -1] call Waldo_MG_fnc_submitWhosWhoActionRequestLocal;
};

Waldo_MG_fnc_refreshWhosWhoLocal = {
    disableSerialization;
    params [["_display", displayNull]];
    if (isNull _display) exitWith {};
    if (_display getVariable ["Waldo_MG_WhosWhoRefreshing", false]) exitWith {};
    _display setVariable ["Waldo_MG_WhosWhoRefreshing", true];
    private _table = _display getVariable ["Waldo_MG_WhosWhoTable", objNull];
    private _spectating = _display getVariable ["Waldo_MG_SpectatorMode", false];
    if (isNull _table || {!([_table, _spectating] call Waldo_MG_fnc_isValidGameViewerLocal)} || {([_table] call Waldo_MG_fnc_getTableActiveGameId) != "whoswho"}) exitWith {
        _display closeDisplay 1;
    };
    private _snapshot = _table getVariable ["Waldo_MG_WhosWhoSnapshot", []];
    private _board = _table getVariable ["Waldo_MG_WhosWhoBoard", []];
    if ((count _snapshot) < 10 || {(count _board) != 4}) exitWith {
        _display setVariable ["Waldo_MG_WhosWhoRefreshing", false];
    };
    private _phase = _snapshot param [0, "IDLE"];
    private _actor = _snapshot param [1, -1];
    private _actions = _snapshot param [2, []];
    private _winner = _snapshot param [3, -1];
    private _status = _snapshot param [4, "Who's Who in progress."];
    private _lastGuessRole = _snapshot param [5, -1];
    private _lastGuessIndex = _snapshot param [6, -1];
    private _lastGuessCorrect = _snapshot param [7, false];
    private _revealedTargets = _snapshot param [8, []];
    private _moveNumber = _snapshot param [9, 0];
    private _names = _table getVariable ["Waldo_MG_WhosWhoPlayerNames", []];
    private _gameId = _table getVariable ["Waldo_MG_WhosWhoGameId", ""];
    private _role = if (_spectating) then {-1} else {[_table] call Waldo_MG_fnc_getWhosWhoPlayerRoleLocal};
    private _yourTurn = !_spectating && {_phase == "PLAYING"} && {_role >= 0} && {_actor == _role};

    private _privatePayload = if (_spectating || {isNull player}) then {[]} else {player getVariable ["Waldo_MG_WhosWhoPrivateTarget", []]};
    private _privateValid = (count _privatePayload) >= 2 && {(_privatePayload param [0, ""]) == _gameId};
    private _privateIndex = if (_privateValid) then {_privatePayload param [1, -1]} else {-1};
    if (!_spectating && {_role >= 0} && {!_privateValid}) then {
        private _lastSync = _display getVariable ["Waldo_MG_WhosWhoLastSyncLocal", -10];
        if ((diag_tickTime - _lastSync) >= 3) then {
            _display setVariable ["Waldo_MG_WhosWhoLastSyncLocal", diag_tickTime];
            [_table, "SYNC", -1] call Waldo_MG_fnc_submitWhosWhoActionRequestLocal;
        };
    };

    private _lastAutoMove = _display getVariable ["Waldo_MG_WhosWhoLastAutoMoveLocal", -1];
    if (!_spectating && {_role == _lastGuessRole} && {!_lastGuessCorrect} && {_lastGuessIndex >= 0} && {_moveNumber != _lastAutoMove}) then {
        private _eliminated = [_gameId] call Waldo_MG_fnc_whosWhoGetEliminatedLocal;
        _eliminated pushBackUnique _lastGuessIndex;
        [_gameId, _eliminated] call Waldo_MG_fnc_whosWhoSetEliminatedLocal;
    };
    _display setVariable ["Waldo_MG_WhosWhoLastAutoMoveLocal", _moveNumber];
    private _eliminated = if (_spectating) then {[]} else {[_gameId] call Waldo_MG_fnc_whosWhoGetEliminatedLocal};

    private _turnLabel = _display getVariable ["Waldo_MG_WhosWhoTurnLabel", controlNull];
    private _statusLabel = _display getVariable ["Waldo_MG_WhosWhoStatusLabel", controlNull];
    private _actionLabel = _display getVariable ["Waldo_MG_WhosWhoActionLabel", controlNull];
    if (!isNull _turnLabel) then {
        _turnLabel ctrlSetText (if (_phase == "FINISHED") then {format ["WINNER  /  %1", _names param [_winner, "Player"]]} else {format ["QUESTION TURN  /  %1", _names param [_actor, "Player"]]});
        _turnLabel ctrlSetTextColor (if (_yourTurn) then {[1, 0.82, 0.28, 1]} else {[0.80, 0.90, 0.96, 1]});
        _turnLabel ctrlCommit 0;
    };
    if (!isNull _statusLabel) then {_statusLabel ctrlSetText _status; _statusLabel ctrlSetTooltip _status; _statusLabel ctrlCommit 0;};
    if (!isNull _actionLabel) then {
        _actionLabel ctrlSetText format ["%1: %2     /     %3: %4", _names param [0, "Player 1"], _actions param [0, "Waiting"], _names param [1, "Player 2"], _actions param [1, "Waiting"]];
        _actionLabel ctrlCommit 0;
    };

    private _targetPicture = _display getVariable ["Waldo_MG_WhosWhoTargetPicture", controlNull];
    private _targetLabel = _display getVariable ["Waldo_MG_WhosWhoTargetLabel", controlNull];
    if (_phase == "FINISHED") then {
        private _firstEntry = [_board, _revealedTargets param [0, -1]] call Waldo_MG_fnc_whosWhoGetEntryLocal;
        private _secondEntry = [_board, _revealedTargets param [1, -1]] call Waldo_MG_fnc_whosWhoGetEntryLocal;
        if (!isNull _targetPicture) then {_targetPicture ctrlShow false;};
        if (!isNull _targetLabel) then {
            _targetLabel ctrlSetText format ["REVEALED  /  %1: %2  /  %3: %4", _names param [0, "P1"], _firstEntry param [1, "Vehicle"], _names param [1, "P2"], _secondEntry param [1, "Vehicle"]];
            _targetLabel ctrlSetTextColor [0.55, 1, 0.68, 1];
            _targetLabel ctrlCommit 0;
        };
    } else {
        if (!isNull _targetPicture) then {
            _targetPicture ctrlShow (_privateValid && {!_spectating});
            _targetPicture ctrlSetText (([_board, _privateIndex] call Waldo_MG_fnc_whosWhoGetEntryLocal) param [2, ""]);
            _targetPicture ctrlCommit 0;
        };
        if (!isNull _targetLabel) then {
            private _entry = [_board, _privateIndex] call Waldo_MG_fnc_whosWhoGetEntryLocal;
            _targetLabel ctrlSetText (if (_spectating) then {"PRIVATE TARGETS HIDDEN"} else {if (_privateValid) then {format ["YOUR HIDDEN VEHICLE  /  %1", _entry param [1, "Vehicle"]]} else {"SYNCHRONIZING YOUR HIDDEN VEHICLE..."}});
            _targetLabel ctrlSetTextColor [0.62, 0.88, 1, 1];
            _targetLabel ctrlCommit 0;
        };
    };

    private _tileBundles = _display getVariable ["Waldo_MG_WhosWhoTileBundles", []];
    private _renderedGame = _display getVariable ["Waldo_MG_WhosWhoRenderedGameLocal", ""];
    for "_index" from 0 to ((count _tileBundles) - 1) do {
        private _bundle = _tileBundles param [_index, []];
        private _frame = _bundle param [0, controlNull];
        private _button = _bundle param [1, controlNull];
        private _picture = _bundle param [2, controlNull];
        private _label = _bundle param [3, controlNull];
        private _cross = _bundle param [4, controlNull];
        private _entry = [_board, _index] call Waldo_MG_fnc_whosWhoGetEntryLocal;
        if (_renderedGame != _gameId) then {
            if (!isNull _picture) then {_picture ctrlSetText (_entry param [2, ""]); _picture ctrlCommit 0;};
            if (!isNull _label) then {_label ctrlSetText (_entry param [1, "Vehicle"]); _label ctrlSetTooltip (_entry param [1, "Vehicle"]); _label ctrlCommit 0;};
            if (!isNull _button) then {_button setVariable ["Waldo_MG_WhosWhoTileIndex", _index]; _button ctrlSetTooltip (_entry param [1, "Vehicle"]);};
        };
        private _isEliminated = _index in _eliminated;
        private _isRevealed = _phase == "FINISHED" && {_index in _revealedTargets};
        if (!isNull _frame) then {
            _frame ctrlSetBackgroundColor (if (_isRevealed) then {[0.08, 0.42, 0.20, 1]} else {if (_index == _lastGuessIndex) then {if (_lastGuessCorrect) then {[0.08, 0.42, 0.20, 1]} else {[0.42, 0.18, 0.035, 1]}} else {if (_isEliminated) then {[0.25, 0.025, 0.025, 1]} else {[0.055, 0.085, 0.105, 1]}}});
            _frame ctrlCommit 0;
        };
        if (!isNull _cross) then {_cross ctrlShow _isEliminated; _cross ctrlCommit 0;};
        if (!isNull _button) then { 
 
            _button ctrlEnable true;
            _button setVariable ["Waldo_MG_WhosWhoTileUsable", (!_spectating && {_phase == "PLAYING"})];
            _button ctrlCommit 0;
        };
    };
    if (_renderedGame != _gameId) then {_display setVariable ["Waldo_MG_WhosWhoRenderedGameLocal", _gameId];};

    private _guessButton = _display getVariable ["Waldo_MG_WhosWhoGuessButton", controlNull];
    private _passButton = _display getVariable ["Waldo_MG_WhosWhoPassButton", controlNull];
    private _resetButton = _display getVariable ["Waldo_MG_WhosWhoResetButton", controlNull];
    private _guessArmed = _display getVariable ["Waldo_MG_WhosWhoGuessArmedLocal", false];
    if (!_yourTurn && {_guessArmed}) then {_guessArmed = false; _display setVariable ["Waldo_MG_WhosWhoGuessArmedLocal", false];};
    if (!isNull _guessButton) then {
        _guessButton ctrlShow (!_spectating && {_phase == "PLAYING"});
        _guessButton ctrlEnable _yourTurn;
        _guessButton ctrlSetText (if (_guessArmed) then {"CANCEL GUESS"} else {"MAKE A GUESS"});
        _guessButton ctrlSetBackgroundColor (if (_guessArmed) then {[0.48, 0.17, 0.035, 1]} else {[0.10, 0.27, 0.38, 1]});
        _guessButton ctrlCommit 0;
    };
    if (!isNull _passButton) then {_passButton ctrlShow (!_spectating && {_phase == "PLAYING"}); _passButton ctrlEnable _yourTurn; _passButton ctrlCommit 0;};
    if (!isNull _resetButton) then {_resetButton ctrlShow (!_spectating && {_phase == "FINISHED"}); _resetButton ctrlEnable (!_spectating && {_phase == "FINISHED"}); _resetButton ctrlCommit 0;};
    private _helpLabel = _display getVariable ["Waldo_MG_WhosWhoHelpLabel", controlNull];
    if (!isNull _helpLabel) then {
        _helpLabel ctrlSetText (if (_spectating) then {"SPECTATOR VIEW  /  PRIVATE TARGETS AND EACH PLAYER'S RED-X NOTES REMAIN HIDDEN"} else {if (_guessArmed) then {"GUESS ARMED  /  YOUR NEXT VEHICLE CLICK IS AUTHORITATIVE  /  A WRONG GUESS IS CROSSED OUT AND PASSES THE TURN"} else {"CLICK VEHICLES TO TOGGLE LOCAL RED X MARKS  /  ASK QUESTIONS ALOUD  /  PASS TURN WHEN YOUR QUESTION IS COMPLETE"}});
        _helpLabel ctrlCommit 0;
    };
    _display setVariable ["Waldo_MG_WhosWhoRefreshing", false];
};

Waldo_MG_fnc_openWhosWhoLocal = {
    disableSerialization;
    params [["_table", objNull], ["_spectating", false]];
    if (!hasInterface || {isNull player}) exitWith {};
    if (isNull _table || {!([_table, _spectating] call Waldo_MG_fnc_isValidGameViewerLocal)} || {([_table] call Waldo_MG_fnc_getTableActiveGameId) != "whoswho"}) exitWith {
        ["No active Who's Who: Vehicles match is available to this viewer."] call Waldo_MG_fnc_notifyLocal;
    };
    private _parent = findDisplay 46;
    if (isNull _parent) exitWith {["The Who's Who display is unavailable."] call Waldo_MG_fnc_notifyLocal;};
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
    uiNamespace setVariable ["Waldo_MG_WhosWhoDisplay", _display];
    _display setVariable ["Waldo_MG_WhosWhoTable", _table];
    _display setVariable ["Waldo_MG_SpectatorMode", _spectating];
    _display setVariable ["Waldo_MG_WhosWhoGuessArmedLocal", false];
    _display setVariable ["Waldo_MG_WhosWhoLastAutoMoveLocal", -1];
    [_display] call Waldo_MG_fnc_installEscapeGuardLocal;
    private _focusSink = _display ctrlCreate ["RscButton", -1];
    _focusSink ctrlSetPosition [-10, -10, 0.001, 0.001];
    _focusSink ctrlSetText "";
    _focusSink ctrlCommit 0;
    _display setVariable ["Waldo_MG_WhosWhoFocusSink", _focusSink];
    ctrlSetFocus _focusSink;

    private _background = _display ctrlCreate ["RscText", -1];
    _background ctrlSetPosition ([0.010, 0.015, 0.980, 0.970] call Waldo_MG_fnc_whosWhoSafePositionLocal);
    _background ctrlSetBackgroundColor [0.008, 0.018, 0.026, 0.993];
    _background ctrlCommit 0;
    private _topBar = _display ctrlCreate ["RscText", -1];
    _topBar ctrlSetPosition ([0.010, 0.015, 0.980, 0.070] call Waldo_MG_fnc_whosWhoSafePositionLocal);
    _topBar ctrlSetBackgroundColor [0.055, 0.23, 0.34, 1];
    _topBar ctrlCommit 0;
    private _title = _display ctrlCreate ["RscText", -1];
    _title ctrlSetPosition ([0.030, 0.026, 0.390, 0.045] call Waldo_MG_fnc_whosWhoSafePositionLocal);
    _title ctrlSetText "PARTYGAMES  /  WHO'S WHO: VEHICLES";
    _title ctrlSetTextColor [0.87, 0.96, 1, 1];
    _title ctrlSetFontHeight 0.040;
    _title ctrlCommit 0;
    private _turnLabel = _display ctrlCreate ["RscText", -1];
    _turnLabel ctrlSetPosition ([0.410, 0.028, 0.390, 0.040] call Waldo_MG_fnc_whosWhoSafePositionLocal);
    _turnLabel ctrlSetFontHeight 0.025;
    _turnLabel ctrlCommit 0;
    private _exitButton = _display ctrlCreate ["RscButtonMenu", -1];
    _exitButton ctrlSetPosition ([0.815, 0.028, 0.155, 0.042] call Waldo_MG_fnc_whosWhoSafePositionLocal);
    _exitButton ctrlSetText (if (_spectating) then {"Exit Spectate"} else {"Leave Table"});
    _exitButton ctrlSetFontHeight 0.022;
    _exitButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_handleViewerExitButtonLocal;}];
    _exitButton ctrlCommit 0;

    private _infoPanel = _display ctrlCreate ["RscText", -1];
    _infoPanel ctrlSetPosition ([0.015, 0.095, 0.970, 0.102] call Waldo_MG_fnc_whosWhoSafePositionLocal);
    _infoPanel ctrlSetBackgroundColor [0.020, 0.055, 0.075, 0.98];
    _infoPanel ctrlCommit 0;
    private _targetPicture = _display ctrlCreate ["RscPictureKeepAspect", -1];
    _targetPicture ctrlSetPosition ([0.025, 0.101, 0.120, 0.088] call Waldo_MG_fnc_whosWhoSafePositionLocal);
    _targetPicture ctrlEnable false;
    _targetPicture ctrlCommit 0;
    private _targetLabel = _display ctrlCreate ["RscText", -1];
    _targetLabel ctrlSetPosition ([0.152, 0.105, 0.370, 0.036] call Waldo_MG_fnc_whosWhoSafePositionLocal);
    _targetLabel ctrlSetFontHeight 0.024;
    _targetLabel ctrlCommit 0;
    private _statusLabel = _display ctrlCreate ["RscText", -1];
    _statusLabel ctrlSetPosition ([0.152, 0.148, 0.813, 0.034] call Waldo_MG_fnc_whosWhoSafePositionLocal);
    _statusLabel ctrlSetTextColor [0.83, 0.89, 0.92, 1];
    _statusLabel ctrlSetFontHeight 0.020;
    _statusLabel ctrlCommit 0;
    private _actionLabel = _display ctrlCreate ["RscText", -1];
    _actionLabel ctrlSetPosition ([0.535, 0.105, 0.430, 0.036] call Waldo_MG_fnc_whosWhoSafePositionLocal);
    _actionLabel ctrlSetTextColor [0.63, 0.76, 0.82, 1];
    _actionLabel ctrlSetFontHeight 0.020;
    _actionLabel ctrlCommit 0;

    private _tileBundles = [];
    for "_row" from 0 to 3 do {
        for "_column" from 0 to (Waldo_MG_CFG_WHOSWHO_PER_FACTION - 1) do {
            private _index = (_row * Waldo_MG_CFG_WHOSWHO_PER_FACTION) + _column;
            private _x = 0.014 + (_column * 0.0812);
            private _y = 0.210 + (_row * 0.165);
            private _frame = _display ctrlCreate ["RscText", -1];
            _frame ctrlSetPosition ([_x, _y, 0.078, 0.157] call Waldo_MG_fnc_whosWhoSafePositionLocal);
            _frame ctrlSetBackgroundColor [0.055, 0.085, 0.105, 1];
            _frame ctrlCommit 0;
            private _button = _display ctrlCreate ["RscButton", -1];
            _button ctrlSetPosition ([_x + 0.002, _y + 0.002, 0.074, 0.153] call Waldo_MG_fnc_whosWhoSafePositionLocal);
            _button ctrlSetText "";
            _button ctrlSetBackgroundColor [0, 0, 0, 0];
            _button ctrlEnable true;
            _button setVariable ["Waldo_MG_WhosWhoTileIndex", _index];
            _button setVariable ["Waldo_MG_WhosWhoTileUsable", false];
            _button ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_handleWhosWhoTileClickLocal;}];
            _button ctrlCommit 0;
            private _picture = _display ctrlCreate ["RscPictureKeepAspect", -1];
            _picture ctrlSetPosition ([_x + 0.004, _y + 0.004, 0.070, 0.116] call Waldo_MG_fnc_whosWhoSafePositionLocal);
            _picture ctrlEnable false;
            _picture ctrlCommit 0;
            private _label = _display ctrlCreate ["RscText", -1];
            _label ctrlSetPosition ([_x + 0.003, _y + 0.122, 0.072, 0.030] call Waldo_MG_fnc_whosWhoSafePositionLocal);
            _label ctrlSetTextColor [0.86, 0.91, 0.94, 1];
            _label ctrlSetFontHeight 0.018;
            _label ctrlEnable false;
            _label ctrlCommit 0;
            private _cross = _display ctrlCreate ["RscText", -1];
            _cross ctrlSetPosition ([_x + 0.023, _y + 0.025, 0.045, 0.084] call Waldo_MG_fnc_whosWhoSafePositionLocal);
            _cross ctrlSetText "X";
            _cross ctrlSetTextColor [1, 0.06, 0.04, 0.96];
            _cross ctrlSetFontHeight 0.080;
            _cross ctrlEnable false;
            _cross ctrlShow false;
            _cross ctrlCommit 0;
            _tileBundles pushBack [_frame, _button, _picture, _label, _cross];
        };
    };

    private _controlPanel = _display ctrlCreate ["RscText", -1];
    _controlPanel ctrlSetPosition ([0.015, 0.874, 0.970, 0.111] call Waldo_MG_fnc_whosWhoSafePositionLocal);
    _controlPanel ctrlSetBackgroundColor [0.014, 0.040, 0.055, 1];
    _controlPanel ctrlCommit 0;
    private _guessButton = _display ctrlCreate ["RscButtonMenu", -1];
    _guessButton ctrlSetPosition ([0.030, 0.888, 0.200, 0.050] call Waldo_MG_fnc_whosWhoSafePositionLocal);
    _guessButton ctrlSetText "MAKE A GUESS";
    _guessButton ctrlSetFontHeight 0.025;
    _guessButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_handleWhosWhoGuessButtonLocal;}];
    _guessButton ctrlCommit 0;
    private _passButton = _display ctrlCreate ["RscButtonMenu", -1];
    _passButton ctrlSetPosition ([0.245, 0.888, 0.170, 0.050] call Waldo_MG_fnc_whosWhoSafePositionLocal);
    _passButton ctrlSetText "PASS TURN";
    _passButton ctrlSetFontHeight 0.025;
    _passButton setVariable ["Waldo_MG_WhosWhoAction", "PASS"];
    _passButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_handleWhosWhoActionButtonLocal;}];
    _passButton ctrlCommit 0;
    private _resetButton = _display ctrlCreate ["RscButtonMenu", -1];
    _resetButton ctrlSetPosition ([0.030, 0.888, 0.260, 0.050] call Waldo_MG_fnc_whosWhoSafePositionLocal);
    _resetButton ctrlSetText "RETURN TO LOBBY";
    _resetButton ctrlSetFontHeight 0.025;
    _resetButton setVariable ["Waldo_MG_WhosWhoAction", "RESET"];
    _resetButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_handleWhosWhoActionButtonLocal;}];
    _resetButton ctrlCommit 0;
    private _helpLabel = _display ctrlCreate ["RscText", -1];
    _helpLabel ctrlSetPosition ([0.430, 0.884, 0.540, 0.054] call Waldo_MG_fnc_whosWhoSafePositionLocal);
    _helpLabel ctrlSetTextColor [0.60, 0.72, 0.78, 1];
    _helpLabel ctrlSetFontHeight 0.019;
    _helpLabel ctrlCommit 0;
    private _ruleLabel = _display ctrlCreate ["RscText", -1];
    _ruleLabel ctrlSetPosition ([0.030, 0.948, 0.940, 0.026] call Waldo_MG_fnc_whosWhoSafePositionLocal);
    _ruleLabel ctrlSetText "FOUR UNLABELED FACTION ROWS  /  RED X MARKS ARE PRIVATE NOTES  /  WRONG GUESSES PASS THE TURN  /  CORRECT GUESS WINS";
    _ruleLabel ctrlSetTextColor [0.45, 0.56, 0.62, 1];
    _ruleLabel ctrlSetFontHeight 0.016;
    _ruleLabel ctrlCommit 0;

    _display setVariable ["Waldo_MG_WhosWhoTurnLabel", _turnLabel];
    _display setVariable ["Waldo_MG_WhosWhoStatusLabel", _statusLabel];
    _display setVariable ["Waldo_MG_WhosWhoActionLabel", _actionLabel];
    _display setVariable ["Waldo_MG_WhosWhoTargetPicture", _targetPicture];
    _display setVariable ["Waldo_MG_WhosWhoTargetLabel", _targetLabel];
    _display setVariable ["Waldo_MG_WhosWhoTileBundles", _tileBundles];
    _display setVariable ["Waldo_MG_WhosWhoGuessButton", _guessButton];
    _display setVariable ["Waldo_MG_WhosWhoPassButton", _passButton];
    _display setVariable ["Waldo_MG_WhosWhoResetButton", _resetButton];
    _display setVariable ["Waldo_MG_WhosWhoHelpLabel", _helpLabel];
    [_display] call Waldo_MG_fnc_refreshWhosWhoLocal;
    [_display] spawn {
        disableSerialization;
        params ["_activeDisplay"];
        while {!isNull _activeDisplay} do {
            [_activeDisplay] call Waldo_MG_fnc_refreshWhosWhoLocal;
            uiSleep Waldo_MG_CFG_WHOSWHO_UI_TICK;
        };
    };
}; 
 

