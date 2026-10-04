/*
 * Author: WaldoTheWarfighter
 * Moves a mobile battery after the last shell flight and warning interval have elapsed. If another
 * Cortex movement owner is active, the relocation waits in five-second steps for at most two minutes
 * instead of replacing that route. Once acquired, the shared movement lease prevents contact,
 * investigation, vehicle standoff or infantry manoeuvre from replacing the scoot waypoint.
 * Locality/authority: the server publishes the mission token; the current vehicle owner executes.
 * Repeat/JIP: the public token and deadline reject stale work and locality gain resumes a pending
 * request. Six bounded candidate positions are scored once for usable vehicle slopes, dry ground,
 * screening and roads; Arma remains responsible for the actual route. The public purpose selects the
 * owning support/counter-battery feature and live scoot switch; closing either cancels the delayed
 * relocation. The physical move is not replayed after completion.
 * Arguments: 0: battery <OBJECT>, default objNull; 1: mission token <STRING>, default "".
 * Return Value: Boolean - true when relocation started or remains pending.
 * Current callers: ArtilleryMissionStep and CortexLocality.
 * Example: [_gun,_token] remoteExecCall ["Waldo_fnc_CortexArtilleryScoot", owner _gun];
 */
params [["_battery", objNull, [objNull]],["_token","",[""]]];
if (isNull _battery || {_token == ""} || {_battery getVariable ["Waldo_Cortex_ArtilleryScootToken",""] != _token}
    || {remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}}) exitWith {false};
if (!local _battery) exitWith {false};
private _clear = {
    _battery setVariable ["Waldo_Cortex_ArtilleryScootToken",nil,true];
    _battery setVariable ["Waldo_Cortex_ArtilleryScootDeadline",nil,true];
    _battery setVariable ["Waldo_Cortex_ArtilleryScootPurpose",nil,true];
};
private _purpose=_battery getVariable ["Waldo_Cortex_ArtilleryScootPurpose",""];
private _counter=_purpose == "COUNTER";
private _feature=["Waldo_AIPass_Artillery_Enable","Waldo_AIPass_CounterBattery_Enable"] select _counter;
private _scootSetting=["Waldo_AIPass_Artillery_ShootAndScoot","Waldo_AIPass_CounterBattery_ShootAndScoot"] select _counter;
if (!canMove _battery || {isNull driver _battery} || {!([group driver _battery] call Waldo_fnc_CortexIsEligible)}
    || {!(missionNamespace getVariable ["Waldo_AIPass_Active", false])} || {[] call Waldo_fnc_CortexIsPaused}) exitWith {call _clear; false};
if !(_purpose in ["SUPPORT","COUNTER"]
    && {missionNamespace getVariable [_scootSetting,true]}
    && {[group driver _battery,_feature,false] call Waldo_fnc_CortexFeatureEnabled}) exitWith {call _clear; false};
private _group = group driver _battery;
private _state = [_group] call Waldo_fnc_CortexGroupState;
private _activeWaypoint = (waypoints _group) findIf {
    (_x select 1) >= currentWaypoint _group && {waypointDescription _x == "WMP AI PASS"}
} >= 0;
private _busy = _activeWaypoint || {count (_state getOrDefault ["drill",createHashMap]) > 0}
    || {_state getOrDefault ["responding",false]} || {_state getOrDefault ["assaulting",false]}
    || {(_group getVariable ["Waldo_AIPass_Garrison",[]]) isNotEqualTo []}
    || {(_group getVariable ["Waldo_AIPass_Defend",[]]) isNotEqualTo []}
    || {_group getVariable ["Waldo_AIPass_ClearBuilding",false]};
if (_busy) exitWith {
    if (serverTime < (_battery getVariable ["Waldo_Cortex_ArtilleryScootDeadline",0])) then {
        [{_this call Waldo_fnc_CortexArtilleryScoot},[_battery,_token],5] call CBA_fnc_waitAndExecute;
        true
    } else {call _clear; false}
};
private _origin=getPosATL _battery;
private _candidates=[];
for "_attempt" from 0 to 5 do {
    _candidates pushBack [_origin getPos [200+random 150,random 360]];
};
private _selected=[_origin,_candidates,_origin,[],objNull,"VEHICLE"] call Waldo_fnc_CortexSelectAvenue;
private _spot=if (_selected isEqualTo []) then {[]} else {_selected select ((count _selected)-1)};
if (_spot isEqualTo []) exitWith {call _clear; false};
if !([_group,"ARTILLERY_SCOOT",true,serverTime+120] call Waldo_fnc_CortexLambsLease) exitWith {
    if (serverTime < (_battery getVariable ["Waldo_Cortex_ArtilleryScootDeadline",0])) then {
        [{_this call Waldo_fnc_CortexArtilleryScoot},[_battery,_token],5] call CBA_fnc_waitAndExecute;
        true
    } else {call _clear; false}
};
[_group, _spot, 30] call Waldo_fnc_CortexGroupMove;
_state set ["movementLease",["ARTILLERY_SCOOT",time+120]];
call _clear;
true
