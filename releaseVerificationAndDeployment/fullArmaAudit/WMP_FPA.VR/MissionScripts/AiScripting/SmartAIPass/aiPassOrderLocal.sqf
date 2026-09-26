/*
 * Author: WaldoTheWarfighter
 * Executes an authenticated Zeus order only when the selected group is still local, then acknowledges its result.
 * Locality/authority: server authenticates dispatch; the current owner executes group commands.
 * Repeat/JIP: request tokens are consumed once; no stale order is replayed for JIP.
 * Arguments: 0: token <STRING>; 1: settings <ARRAY> of named pairs.
 * Return Value: Nothing; reports actual owner acceptance.
 * Current callers: AIPassOrderDispatch.
 * Example: [_token, _pairs] remoteExecCall ["Waldo_fnc_AIPassOrderLocal", groupOwner _group];
 */
params ["_token", "_pairs"];
if (remoteExecutedOwner != 2) exitWith {};
private _settings = createHashMapFromArray _pairs;
private _group = _settings getOrDefault ["group", grpNull];
if (isNull _group || {!local _group} || {(units _group) findIf {isPlayer _x} >= 0}) exitWith {
    [_token, false] remoteExecCall ["Waldo_fnc_AIPassOrderResult", 2];
};
private _order = _settings getOrDefault ["order", ""];
private _position = _settings getOrDefault ["position", []];
private _radius = _settings getOrDefault ["radius", 50];
private _building = _settings getOrDefault ["building", objNull];
private _facing = _settings getOrDefault ["facing", 0];
if (_order in ["GARRISON", "DEFEND", "CLEAR", "AIRBORNE"]) then {
    _group setVariable ["Waldo_AIPass_ZeusWaypoints", false, true];
    _group setVariable ["Waldo_AIPass_ZeusHold", [random 1e6, 0], true];
};
if (_order in ["GARRISON", "DEFEND"]) then {[_group] call Waldo_fnc_AIPassClearRelease};
    private _accepted = switch (_order) do {
        case "GARRISON": {[_group, _position, (_radius max 15) min 150] call Waldo_fnc_AIPassGarrison};
        case "DEFEND": {[_group, _position, _facing, (_radius max 15) min 150] call Waldo_fnc_AIPassDefend};
        case "RELEASE": {
            private _released = [_group] call Waldo_fnc_AIPassClearRelease;
            if ((_group getVariable ["Waldo_AIPass_Garrison", []]) isNotEqualTo []) then {_released = [_group] call Waldo_fnc_AIPassGarrisonRelease};
            if ((_group getVariable ["Waldo_AIPass_Defend", []]) isNotEqualTo []) then {_released = [_group] call Waldo_fnc_AIPassDefendRelease};
            _released
        };
        case "EXCLUDE": {
            if (isNull _group) exitWith {false};
            _group setVariable ["Waldo_AIPass_Exclude", true, true];
            true
        };
        case "RETURN": {
            if (isNull _group) exitWith {false};
            _group setVariable ["Waldo_AIPass_Exclude", nil, true];
            _group setVariable ["Waldo_AIPass_ZeusWaypoints", false, true];
            // A zero-length token cancels any remaining Zeus hold on every machine.
            _group setVariable ["Waldo_AIPass_ZeusHold", [random 1e6, 0], true];
            true
        };
        case "CLEAR": {[_group, _building] call Waldo_fnc_AIPassClearBuilding};
        case "AIRBORNE": {[_group] call Waldo_fnc_AIPassAirborneDrop};
        default {false};
    };

[_token, _accepted] remoteExecCall ["Waldo_fnc_AIPassOrderResult", 2];
