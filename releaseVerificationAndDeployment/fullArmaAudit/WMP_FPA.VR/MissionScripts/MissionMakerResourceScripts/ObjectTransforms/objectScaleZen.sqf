/*
 * Author: WaldoTheWarfighter
 * Opens the ZEN dialog for server-authoritative scaling of the object under the module.
 *
 * Runtime scaling requires a Simple Object or attached object. The dialog therefore offers explicit
 * conversion for grounded decorative props and enables it by default; conversion removes simulation,
 * damage, inventory, crew and object-bound actions. The module is registered as "Scale Object" by
 * MissionScripts/ZenModules/Zen_initModules.sqf and calls Waldo_fnc_ObjectScale on the server.
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
        ["SLIDER", ["Scale", "Uniform render multiplier; mission server limits still apply."], [0.1, 10, getObjectScale _target, 2], true],
        ["CHECKBOX", ["Convert decorative object", "Required for ordinary free-standing objects. Replaces the target with a non-simulated Simple Object; do not use on functional objects."], !isSimpleObject _target && {isNull (attachedTo _target)}]
    ],
    {
        params ["_args", "_target"];
        _args params ["_scale", "_asSimple"];
        if (!_asSimple && {!isSimpleObject _target && {isNull (attachedTo _target)}}) exitWith {
            systemChat "[WMP] Scaling requires a Simple Object, an attached object, or decorative-object conversion.";
        };
        if (_asSimple && {count (crew _target) > 0 || {(getPosATL _target select 2) > 0.5}}) exitWith {
            systemChat "[WMP] Only empty decorative objects placed on the ground can be converted for scaling.";
        };
        [_target, _scale, _asSimple] remoteExecCall ["Waldo_fnc_ObjectScale", 2];
    },
    {},
    _target
] call zen_dialog_fnc_create;
