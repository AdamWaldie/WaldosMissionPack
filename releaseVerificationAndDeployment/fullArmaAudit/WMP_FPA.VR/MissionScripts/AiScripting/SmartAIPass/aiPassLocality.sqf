/*
 * Author: WaldoTheWarfighter
 * Invalidates old jobs and restores interrupted transient behaviour after WMP or ACE migration.
 * Locality/authority: current group owner unless stated otherwise below.
 * Repeat/JIP: durable restoration data is public; local jobs are never replayed verbatim.
 * Arguments: 0: group <GROUP>, default grpNull; 1: gained locality <BOOL>, default false.
 * Return Value: Nothing unless a value is explicitly returned below.
 * Current callers: group Local handler and discovery.
 * Example: [_group, local _group] call Waldo_fnc_AIPassLocality;
 */
params [["_group", grpNull, [grpNull]], ["_gained", false, [true]]];
if (isNull _group) exitWith {};
[_group,true] call Waldo_fnc_AIPassHearingLocal;
{
        private _unit = _x;
        {_unit removeEventHandler _x} forEach (_unit getVariable ["Waldo_AIPass_GarrisonHandlerIds", []]);
        _unit setVariable ["Waldo_AIPass_GarrisonHandlerIds", nil];
        _unit setVariable ["Waldo_AIPass_GarrisonHandlers", nil];
        _unit setVariable ["Waldo_AIPass_DuckUntil", nil];
} forEach units _group;
_group setVariable ["Waldo_AIPass_Epoch", (_group getVariable ["Waldo_AIPass_Epoch", 0]) + 1];
_group setVariable ["Waldo_AIPass_State", nil];
_group setVariable ["Waldo_AIPass_Managed", nil];
{_group setVariable [_x, nil]} forEach ["Waldo_AIPass_GarrisonApplied", "Waldo_AIPass_DefendApplied", "Waldo_AIPass_ClearApplied"];
_group setVariable ["Waldo_AIPass_Adopted", _gained];
if (!_gained || {!local _group}) exitWith {};
private _restore = createHashMapFromArray (_group getVariable ["Waldo_AIPass_Checkpoint", []]);
{
    _x params ["_unit", "_feature"];
    if (local _unit) then {_unit enableAI _feature};
} forEach (_restore getOrDefault ["restoreDisabled", []]);
{
    if (alive _x && {local _x} && {group _x == _group}) then {_x doFollow leader _group};
} forEach (_restore getOrDefault ["restoreMovers", []]);
[_group, _restore, false] call Waldo_fnc_AIPassRestoreCalm;
_group setVariable ["Waldo_AIPass_Checkpoint", [], true];
// Clear stale remnant reservations and airborne jobs; the normal discovery path reassesses them.
_group setVariable ["Waldo_AIPass_RegroupQueued", nil];
_group setVariable ["Waldo_AIPass_RegroupHost", nil];
_group setVariable ["Waldo_AIPass_Dropping", nil];
