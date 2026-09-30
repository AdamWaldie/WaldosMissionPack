/*
 * Author: WaldoTheWarfighter
 * Runs one reserved squad bound as two successive fire-team movements.
 * Locality/authority: group owner consumes the current server role and matching lease.
 * Repeat/JIP: sequence prevents duplicate starts; migration restores mover leases before
 * the new owner consumes the durable role. Uses the existing bounded movement scheduler.
 * Arguments: 0: group <GROUP>; 1: state <HASHMAP>; 2: role <ARRAY>, required.
 * Return: Boolean, true if a finite bound starts. Current caller: CortexSupportMaintain.
 * Example: [_group,_state,_role] call Waldo_fnc_CortexSupportBoundStart;
 */
params ["_group","_state","_role"];
if (!local _group || {count _role != 5} || {count (_state getOrDefault ["drill",createHashMap]) > 0}) exitWith {false};
_role params ["_leaseToken","_sequence","_roleName","_point","_enemy"];
if (_roleName != "MOVE" || {_role isNotEqualTo (_group getVariable ["Waldo_Cortex_SupportRole",[]])}) exitWith {false};
private _lease=_group getVariable ["Waldo_AIPass_SupportLease",[]];
if (count _lease != 6 || {(_lease select 0) != _leaseToken} || {serverTime >= (_lease select 2)}) exitWith {false};
private _final=_point distance2D (_lease select 5) < 2;
private _fit=(units _group) select {local _x && {[_x] call Waldo_fnc_CortexCombatEffective} && {vehicle _x == _x} && {_x checkAIFeature "PATH"} && {_x checkAIFeature "MOVE"}};
if (count _fit < 4) exitWith {false};
private _riflemen=_fit select {_x != leader _group && {!(([_x] call Waldo_fnc_CortexUnitRole) in ["MG","AT","LEADER"])}};
private _first=_riflemen select [0,(floor (count _fit/2)) min count _riflemen];
if (count _first < 2) exitWith {false};
private _second=_fit-_first;
private _token=format ["SUPPORT:%1:%2:%3",_leaseToken,_sequence,clientOwner];
_state set ["drill",createHashMapFromArray [
    ["token",_token],["supportToken",_leaseToken],["supportSequence",_sequence],
    ["type","ADVANCE"],["teams",[_first,_second]],["teamSizes",[count _first,count _second]],["teamTurn",0],["units",_fit],["desiredStrength",count _fit],
    ["points",[[+_point,["SUPPORT_BOUND","FINAL"] select _final]]],["index",0],["stage","START"],
    ["enemyPos",+_enemy],["disabled",[]],["spots",[]],["started",time],
    ["boundStart",time],["pauseUntil",0]
]];
_state set ["supportBoundSequence",_sequence];
_group setVariable ["Waldo_Cortex_SupportBoundResult",[],true];
_group setVariable ["Waldo_Cortex_DrillReinforcements",[],true];
[Waldo_fnc_CortexFlankStep,createHashMapFromArray [["group",_group],["drillToken",_token]],0] call Waldo_fnc_CortexQueueJob;
true
