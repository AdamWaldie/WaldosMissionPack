/*
 * Author: WaldoTheWarfighter
 * Cancels a clearing order immediately and resumes formation after doStop. Clearance does not own
 * group behaviour or combat mode, so release preserves any contact or Zeus change made during it.
 * Locality/authority: server authenticates dispatch; the current owner executes group commands.
 * Repeat/JIP: request tokens are consumed once; no stale order is replayed for JIP.
 * Arguments: 0: group <GROUP>, default grpNull; 1: restore formation <BOOL>, default true. Pass
 * false when Zeus has already supplied a replacement order so cleanup cannot overwrite it.
 * Return Value: Boolean, a clearing order existed.
 * Current callers: AI Orders, replacement orders, Zeus release and stop.
 * Example: [_group] call Waldo_fnc_CortexClearRelease;
 */
params [["_group", grpNull, [grpNull]],["_restore",true,[true]]];
if (isNull _group || {!local _group} || {remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}}) exitWith {false};
private _delegated=_group getVariable ["Waldo_Cortex_BuildingBackend",[]];
if (count _delegated >= 2 && {(_delegated select 0) == "LAMBS"} && {(_delegated select 1) == "CQB"}) exitWith {
    [_group,_restore] call Waldo_fnc_CortexLambsBuildingRelease
};
private _order = _group getVariable ["Waldo_AIPass_ClearOrder", []];
if (_order isEqualTo []) exitWith {false};
_group setVariable ["Waldo_AIPass_ClearGeneration", (_group getVariable ["Waldo_AIPass_ClearGeneration", 0]) + 1];
_group setVariable ["Waldo_Cortex_ClearResult",["CANCELLED",count (_order select 1),count ((_order select 0) buildingPos -1)],true];
_group setVariable ["Waldo_Cortex_ClearEvidence",[+(_order param [1,[]]),+(_order param [4,[]]),+(_order param [5,[]]),+(_order param [6,[]]),_order param [2,serverTime],_order param [7,serverTime]],true];
_group setVariable ["Waldo_AIPass_ClearOrder", nil, true];
_group setVariable ["Waldo_AIPass_ClearBuilding", nil, true];
_group setVariable ["Waldo_Cortex_ClearEgress",nil,true];
_group setVariable ["Waldo_AIPass_ClearApplied", nil];
private _leader=leader _group;
{
    if (local _x && {!isPlayer _x}) then {
        if (alive _x && {lifeState _x != "INCAPACITATED"}) then {
            if (unitPos _x == "UP" && {!isNil {_x getVariable "Waldo_Cortex_ClearStance"}}) then {
                _x setUnitPos (_x getVariable ["Waldo_Cortex_ClearStance","AUTO"]);
            };
            if (getForcedSpeed _x == 4 && {!isNil {_x getVariable "Waldo_Cortex_ClearForcedSpeed"}}) then {
                _x forceSpeed (_x getVariable ["Waldo_Cortex_ClearForcedSpeed",-1]);
            };
            if (_restore) then {_x doFollow _leader};
        };
        _x setVariable ["Waldo_Cortex_ClearStance",nil];
        _x setVariable ["Waldo_Cortex_ClearForcedSpeed",nil];
    };
} forEach units _group;
true
