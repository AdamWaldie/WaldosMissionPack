/*
 * Author: Waldo
 * ZEN handler that scales the nearest object to the placed module with validation on the server.
 *
 * Arguments:
 * 0: modulePosition <ARRAY>
 * 1: object under the module <OBJECT>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_modulePos] call Waldo_fnc_ObjectScaleZen;
 */

params [["_modulePos", [], [[]]], ["_objectPos", objNull, [objNull]]];
if !(hasInterface) exitWith {};

private _target = _objectPos;
if (isNull _target) then {_target = (nearestObjects [_modulePos, [], 5, true]) param [0, objNull]};
if (isNull _target) exitWith {systemChat "[WMP] Object Scaling: place the module on an object."};

[
    "Scale Object",
    [
        ["SLIDER", ["Scale", "Scale multiplier; server limits still apply."], [0.1, 10, 1, 2], false]
    ],
    {
        params ["_args", "_target"];
        _args params ["_scale"];
        [_target, _scale, false] remoteExecCall ["Waldo_fnc_ObjectScale", 2];
    },
    {},
    _target
] call zen_dialog_fnc_create;
