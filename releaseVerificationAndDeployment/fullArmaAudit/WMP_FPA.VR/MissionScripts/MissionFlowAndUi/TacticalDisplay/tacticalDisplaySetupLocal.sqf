/*
 * Author: Waldo
 * Adds the local access action to one tactical display object.
 *
 * Arguments: 0: object <OBJECT>
 * Return Value: Boolean
 */

params [["_object", objNull, [objNull]]];
if !(hasInterface) exitWith {false};
if (isNull _object || {_object getVariable ["Waldo_TacticalDisplay_LocalAction", -1] >= 0}) exitWith {false};
private _action = _object addAction [
    "Access Tactical Display",
    {params ["_target"]; [_target] call Waldo_fnc_TacticalDisplayOpenLocal},
    [], 1.5, true, true, "",
    "_this distance _target <= (missionNamespace getVariable ['Waldo_TacticalDisplay_AccessDistance', 4]) && {[player, 'VIEW'] checkVisibility [eyePos player, aimPos _target] > 0.2}", 5
];
_object setVariable ["Waldo_TacticalDisplay_LocalAction", _action];
true
