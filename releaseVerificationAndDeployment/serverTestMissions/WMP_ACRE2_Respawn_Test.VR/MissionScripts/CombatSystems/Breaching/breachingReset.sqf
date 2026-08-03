/*
 * Author: WaldoTheWarfighter
 * Restores one non-deleted breached object and optionally removes its replacement debris.
 *
 * Arguments:
 * 0: object <OBJECT>
 * 1: remove replacements <BOOLEAN>
 *
 * Return Value:
 * Boolean - true when reset was accepted
 */

params [["_object", objNull, [objNull]], ["_removeReplacements", true, [false]]];
if !(isServer) exitWith {[_object, _removeReplacements] remoteExecCall ["Waldo_fnc_BreachingReset", 2]; true};
if (isNull _object) exitWith {false};
if (remoteExecutedOwner > 0) then {
    private _callerIndex = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_callerIndex >= 0) then {allPlayers select _callerIndex} else {objNull};
    if (isNull _caller || {isNull (getAssignedCuratorLogic _caller)}) exitWith {false};
};
if (_removeReplacements) then {
    {if (!isNull _x) then {deleteVehicle _x}} forEach (_object getVariable ["Waldo_Breaching_Replacements", []]);
};
_object hideObjectGlobal false;
_object setDamage 0;
_object setVariable ["Waldo_Breaching_Processed", false, true];
_object setVariable ["Waldo_Breaching_AccumulatedStrength", 0, true];
_object setVariable ["Waldo_Breaching_Replacements", [], true];
true
