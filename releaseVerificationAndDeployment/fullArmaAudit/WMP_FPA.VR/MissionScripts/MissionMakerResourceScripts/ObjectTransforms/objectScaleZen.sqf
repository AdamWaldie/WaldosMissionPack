/*
 * Author: Waldo
 * ZEN handler that scales the nearest object to the placed module with validation on the server.
 *
 * Arguments:
 * 0: modulePosition <ARRAY>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_modulePos] call Waldo_fnc_ObjectScaleZen;
 */

params [["_modulePos", [], [[]]]];
if !(hasInterface) exitWith {};

private _objects = nearestObjects [_modulePos, [], 25, true];
private _target = _objects param [0, objNull];
if (isNull _target) exitWith {systemChat "[WMP] Object Scaling: no object found within 25 metres."};

[
    "Scale Object",
    [
        ["SLIDER", ["Scale", "Scale multiplier; server limits still apply."], [0.1, 10, 1, 2], false],
        ["CHECKBOX", ["Convert to simple object", "Improves performance but removes simulation and interactions."], false]
    ],
    {
        params ["_args", "_target"];
        _args params ["_scale", "_asSimple"];
        [_target, _scale, _asSimple] remoteExecCall ["Waldo_fnc_ObjectScale", 2];
    },
    {},
    _target
] call zen_dialog_fnc_create;
