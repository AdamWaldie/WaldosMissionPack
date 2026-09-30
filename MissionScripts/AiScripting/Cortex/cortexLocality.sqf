/*
 * Author: WaldoTheWarfighter
 * Passenger restoration intent survives migration without issuing immediate boarding orders.
 * Invalidates old jobs and restores interrupted transient behaviour after WMP or ACE migration.
 * Locality/authority: current group owner unless stated otherwise below.
 * Repeat/JIP: durable restoration data is public; local jobs are never replayed verbatim.
 * Combat-mode restoration checks the applied value before restoring, preserving newer ROE changes.
 * Arguments: 0: group <GROUP>, default grpNull; 1: gained locality <BOOL>, default false.
 * Return Value: Nothing unless a value is explicitly returned below.
 * Current callers: group Local handler and discovery.
 * Example: [_group, local _group] call Waldo_fnc_CortexLocality;
 */
params [["_group", grpNull, [grpNull]], ["_gained", false, [true]]];
if (isNull _group) exitWith {};
[_group,true] call Waldo_fnc_CortexHearingLocal;
{
        private _unit = _x;
        // Event-handler IDs are machine-local. Retire this owner's listener on both
        // loss and gain; the old drill is cancelled, never replayed on the new owner.
        private _fragHandler = _unit getVariable ["Waldo_Cortex_FragHandler",-1];
        if (_fragHandler >= 0) then {_unit removeEventHandler ["FiredMan",_fragHandler]};
        _unit setVariable ["Waldo_Cortex_FragHandler",-1];
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
// Recovery is cancelled by adoption, not silently resumed from stale diagnostics.
if ((_group getVariable ["Waldo_Cortex_DrillRecovery",[]]) isNotEqualTo []) then {
    _group setVariable ["Waldo_Cortex_DrillRecovery",["MIGRATED",[],-1],true];
};
private _restore = createHashMapFromArray (_group getVariable ["Waldo_AIPass_Checkpoint", []]);
private _groupModeLease = _restore getOrDefault ["restoreGroupCombatMode",[]];
if (count _groupModeLease == 2 && {combatMode _group == (_groupModeLease select 1)}) then {
    _group setCombatMode (_groupModeLease select 0);
};
{
    _x params ["_unit", "_feature"];
    if (local _unit) then {_unit enableAI _feature};
} forEach (_restore getOrDefault ["restoreDisabled", []]);
{
    if (alive _x && {local _x} && {group _x == _group}) then {_x doFollow leader _group};
} forEach (_restore getOrDefault ["restoreMovers", []]);
{
    _x params ["_unit","_mode",["_ownedMode","BLUE"]];
    if (local _unit && {unitCombatMode _unit == _ownedMode}) then {_unit setUnitCombatMode _mode};
} forEach (_restore getOrDefault ["restoreCombatModes",[]]);
{
    _x params ["_unit","_previous","_owned"];
    if (local _unit && {behaviour _unit == _owned}) then {_unit setCombatBehaviour _previous};
} forEach (_restore getOrDefault ["restoreCombatBehaviours",[]]);
// Keep restoration intent, not engine commands, across HC ownership changes.
// A new assignment or Zeus takeover invalidates the old passenger episode.
private _passengers=(_restore getOrDefault ["dismounted",[]]) select {
    _x params ["_unit","_vehicle"];
    alive _unit && {group _unit == _group} && {alive _vehicle} && {vehicle _unit == _unit}
        && {isNull assignedVehicle _unit || {assignedVehicle _unit == _vehicle}}
};
[_group, _restore, false] call Waldo_fnc_CortexRestoreCalm;
if (_passengers isNotEqualTo [] && {[_group] call Waldo_fnc_CortexIsEligible}) then {
    private _adopted=[_group] call Waldo_fnc_CortexGroupState;
    _adopted set ["dismounted",_passengers];
    _adopted set ["onboardContactUntil",serverTime+30];
};
// A pending shoot-and-scoot request is durable, but its queued callback belonged to the old owner.
// Resume it only after calm restoration has removed the old owner's waypoint and transient state;
// otherwise that cleanup would immediately delete the newly resumed relocation.
private _scootVehicles = [];
{
    private _vehicle = vehicle _x;
    if (_vehicle != _x && {!(_vehicle in _scootVehicles)}) then {
        _scootVehicles pushBack _vehicle;
        private _scootToken = _vehicle getVariable ["Waldo_Cortex_ArtilleryScootToken",""];
        if (_scootToken != "") then {[_vehicle,_scootToken] call Waldo_fnc_CortexArtilleryScoot};
    };
} forEach units _group;
_group setVariable ["Waldo_AIPass_Checkpoint", [], true];
// Clear stale remnant reservations and airborne jobs; the normal discovery path reassesses them.
_group setVariable ["Waldo_AIPass_RegroupQueued", nil];
_group setVariable ["Waldo_AIPass_RegroupHost", nil];
_group setVariable ["Waldo_AIPass_Dropping", nil];
