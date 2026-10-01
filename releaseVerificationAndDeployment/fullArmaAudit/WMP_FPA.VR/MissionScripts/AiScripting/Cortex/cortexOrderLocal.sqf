/*
 * Author: WaldoTheWarfighter
 * Executes an authenticated Zeus order only when the selected group is still local, then acknowledges its result.
 * Locality/authority: server authenticates dispatch; the current owner executes group commands.
 * Repeat/JIP: request tokens are consumed once; no stale order is replayed for JIP.
 * Arguments: 0: token <STRING>; 1: settings <ARRAY> of named pairs.
 * Return Value: Nothing; reports actual owner acceptance.
 * Current callers: AIPassOrderDispatch.
 * Example: [_token, _pairs] remoteExecCall ["Waldo_fnc_CortexOrderLocal", groupOwner _group];
 */
params ["_token", "_pairs"];
if (remoteExecutedOwner != 2) exitWith {};
private _settings = createHashMapFromArray _pairs;
private _group = _settings getOrDefault ["group", grpNull];
if (isNull _group || {!local _group} || {(units _group) findIf {isPlayer _x} >= 0}) exitWith {
    [_token, false, false, clientOwner, "The squad changed owner or now contains a player."] remoteExecCall ["Waldo_fnc_CortexOrderResult", 2];
};
private _order = _settings getOrDefault ["order", ""];
private _position = _settings getOrDefault ["position", []];
private _radius = _settings getOrDefault ["radius", 50];
private _building = _settings getOrDefault ["building", objNull];
private _facing = _settings getOrDefault ["facing", 0];
private _reason = [_group,_order,_building] call Waldo_fnc_CortexOrderReason;
if (_reason != "") exitWith {[_token,false,false,clientOwner,_reason] remoteExecCall ["Waldo_fnc_CortexOrderResult",2]};
private _oldHold = _group getVariable ["Waldo_AIPass_ZeusHold",[]];
private _oldWaypoints = _group getVariable ["Waldo_AIPass_ZeusWaypoints",false];
if (_order in ["GARRISON", "DEFEND", "CLEAR", "AIRBORNE"]) then {
    _group setVariable ["Waldo_AIPass_ZeusWaypoints", false, true];
    _group setVariable ["Waldo_AIPass_ZeusHold", [random 1e6, 0], true];
};

    private _accepted = switch (_order) do {
        case "GARRISON": {[_group, _position, (_radius max 15) min 150] call Waldo_fnc_CortexGarrison};
        case "DEFEND": {[_group, _position, _facing, (_radius max 15) min 150] call Waldo_fnc_CortexDefend};
        case "RELEASE": {
            private _released = [_group] call Waldo_fnc_CortexLambsBuildingRelease;
            if ([_group] call Waldo_fnc_CortexClearRelease) then {_released=true};
            if ((_group getVariable ["Waldo_AIPass_Garrison", []]) isNotEqualTo []) then {_released = [_group] call Waldo_fnc_CortexGarrisonRelease};
            if ((_group getVariable ["Waldo_AIPass_Defend", []]) isNotEqualTo []) then {_released = [_group] call Waldo_fnc_CortexDefendRelease};
            _released
        };
        case "EXCLUDE": {
            if (isNull _group) exitWith {false};
            [_group] call Waldo_fnc_CortexLambsBuildingRelease;
            [_group] call Waldo_fnc_CortexClearRelease;
            [_group] call Waldo_fnc_CortexGarrisonRelease;
            [_group] call Waldo_fnc_CortexDefendRelease;
            [_group] call Waldo_fnc_CortexReleaseGroup;
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
        case "CLEAR": {[_group, _building] call Waldo_fnc_CortexClearBuilding};
        case "AIRBORNE": {[_group] call Waldo_fnc_CortexAirborneDrop};
        default {false};
    };

if (!_accepted && {_order in ["GARRISON","DEFEND","CLEAR","AIRBORNE"]}) then {
    _group setVariable ["Waldo_AIPass_ZeusHold",_oldHold,true];
    _group setVariable ["Waldo_AIPass_ZeusWaypoints",_oldWaypoints,true];
};
[_token, _accepted, false, clientOwner, if (_accepted) then {""} else {"No valid positions or eligible passengers were available. The order was not started."}] remoteExecCall ["Waldo_fnc_CortexOrderResult", 2];
