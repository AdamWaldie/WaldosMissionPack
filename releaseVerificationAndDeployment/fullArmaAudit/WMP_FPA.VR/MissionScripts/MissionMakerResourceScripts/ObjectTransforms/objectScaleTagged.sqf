/*
 * Author: WaldoTheWarfighter
 * Applies editor-provided scale variables to all matching mission objects exactly once per call.
 * Locality and authority: The server scans and applies the tagged scales. A client forwards its
 * request and receives 0 immediately, not the eventual server count.
 * Repeat/JIP: Calling again scans again; it does not install a loop. Shared object scale state
 * reaches JIP, and there is no separate client action to replay.
 *
 * The server scans authored mission objects and delegates each change to Waldo_fnc_ObjectScale.
 * Conversion is opt-in because Simple Objects lose simulation and interactions. This is currently
 * called directly by mission makers after object creation or from server startup code; it is also
 * inventoried by the full-pack function station.
 *
 * Arguments:
 * 0: variableName <STRING> - object variable containing the numeric scale (default: Waldo_ObjectScale)
 * 1: asSimpleObject <BOOLEAN> - convert tagged objects to simple objects (default: false)
 *
 * Return Value:
 * Number - scaled object count
 *
 * Example:
 * ["Waldo_ObjectScale", true] call Waldo_fnc_ObjectScaleTagged;
 * Result: The server returns the number of objects scaled during this scan.
 * Current callers: Mission-maker startup scripts and the full-pack audit station.
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
