/*
 * Author: Waldo
 * Registers an object-bound live tactical map console.
 *
 * Arguments: 0: object <OBJECT>; 1: side <SIDE>; 2: map radius <NUMBER>; 3: known enemies <BOOLEAN>
 * Return Value: Boolean
 */

params [["_object", objNull, [objNull]], ["_side", sideUnknown, [sideUnknown]], ["_radius", 2000, [0]], ["_knownEnemies", true, [false]]];
if !(isServer) exitWith {[_object, _side, _radius, _knownEnemies] remoteExecCall ["Waldo_fnc_TacticalDisplayRegister", 2]; true};
if (isNull _object) exitWith {false};
if (remoteExecutedOwner > 0) then {
    private _index = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_index >= 0) then {allPlayers select _index} else {objNull};
    if (isNull _caller || {isNull (getAssignedCuratorLogic _caller)}) exitWith {false};
};
_object setVariable ["Waldo_TacticalDisplay_Registered", true, true];
_object setVariable ["Waldo_TacticalDisplay_Side", _side, true];
_object setVariable ["Waldo_TacticalDisplay_Radius", _radius max 100, true];
_object setVariable ["Waldo_TacticalDisplay_ShowKnownEnemies", _knownEnemies, true];
[_object] remoteExecCall ["Waldo_fnc_TacticalDisplaySetupLocal", -2, format ["Waldo_TacticalDisplay_%1", netId _object]];
true
