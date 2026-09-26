/*
 * Author: WaldoTheWarfighter
 * Assigns an existing AI soldier as an identifiable artillery observer; never spawns or equips units.
 * Locality/authority: documented guards enforce server coordination and owner-local execution.
 * Repeat/JIP: assignment is public and repeat-safe. It survives ownership changes and pass stop/restart.
 * Arguments: 0: unit <OBJECT>, default objNull; 1: enabled <BOOL>, default true.
 * Return Value: Boolean, assignment accepted.
 * Current callers: server mission scripts and AI Orders.
 * Example: if (isServer) then {[spotter1, true] call Waldo_fnc_AIPassSetSpotter;};
 */
params [["_unit", objNull, [objNull]], ["_enabled", true, [true]]];
if (!isServer || {remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}}) exitWith {false};
if (isNull _unit || {!(_unit isKindOf "CAManBase")} || {isPlayer _unit}) exitWith {false};
_unit setVariable ["Waldo_AIPass_Spotter", _enabled, true];
true
