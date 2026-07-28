/*
 * Author: Waldo
 * Applies editor-provided scale variables to all matching mission objects exactly once per call.
 *
 * Arguments:
 * 0: variableName <STRING> - object variable containing the numeric scale (default: Waldo_ObjectScale)
 * 1: asSimpleObject <BOOLEAN> - convert tagged objects to simple objects (default: false)
 *
 * Return Value:
 * Number - scaled object count
 *
 * Example:
 * ["Waldo_ObjectScale", false] call Waldo_fnc_ObjectScaleTagged;
 */

params [
    ["_variableName", "Waldo_ObjectScale", [""]],
    ["_asSimple", false, [false]]
];
if !(isServer) exitWith {
    [_variableName, _asSimple] remoteExecCall ["Waldo_fnc_ObjectScaleTagged", 2];
    0
};

private _count = 0;
{
    private _scale = _x getVariable [_variableName, -1];
    if (_scale isEqualType 0 && {_scale > 0}) then {
        [_x, _scale, _asSimple] call Waldo_fnc_ObjectScale;
        _count = _count + 1;
    };
} forEach allMissionObjects "";
_count
