/*
 * Author: WaldoTheWarfighter
 * Applies one scale to server-known mission objects in a bounded area with optional classname filtering.
 *
 * Area conversion is disabled by default because replacing many multiplayer objects is destructive
 * and can remove interactions or simulation. Without conversion, only existing Simple Objects and
 * attached objects are changed. Currently exposed as Waldo_fnc_ObjectScaleArea to mission scripts
 * and inventoried by the full-pack function station.
 *
 * Arguments:
 * 0: centre <ARRAY>
 * 1: radius <NUMBER>
 * 2: scale <NUMBER>
 * 3: classnames <ARRAY> - empty accepts all mission objects
 * 4: convertToSimpleObjects <BOOLEAN> - grounded decorative props only (default: false)
 *
 * Return Value:
 * Number - scaled object count
 *
 * Example:
 * [[100, 100, 0], 25, 1.5, ["Land_CampingChair_V2_F"], true] call Waldo_fnc_ObjectScaleArea;
 */

params ["_centre", ["_radius", 10, [0]], ["_scale", 1, [0]], ["_classes", [], [[]]], ["_asSimple", false, [false]]];
if !(isServer) exitWith {[_centre, _radius, _scale, _classes, _asSimple] remoteExecCall ["Waldo_fnc_ObjectScaleArea", 2]; 0};
private _count = 0;
{
    if (_classes isEqualTo [] || {typeOf _x in _classes}) then {
        if (!isNull ([_x, _scale, _asSimple] call Waldo_fnc_ObjectScale)) then {_count = _count + 1};
    };
} forEach nearestObjects [_centre, [], _radius max 0, true];
_count
