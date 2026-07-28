/*
 * Author: Waldo
 * Applies one scale to server-known mission objects in a bounded area with optional classname filtering.
 *
 * Arguments:
 * 0: centre <ARRAY>
 * 1: radius <NUMBER>
 * 2: scale <NUMBER>
 * 3: classnames <ARRAY> - empty accepts all mission objects
 *
 * Return Value:
 * Number - scaled object count
 */

params ["_centre", ["_radius", 10, [0]], ["_scale", 1, [0]], ["_classes", [], [[]]]];
if !(isServer) exitWith {[_centre, _radius, _scale, _classes] remoteExecCall ["Waldo_fnc_ObjectScaleArea", 2]; 0};
private _count = 0;
{
    if (_classes isEqualTo [] || {typeOf _x in _classes}) then {
        if (!isNull ([_x, _scale, false] call Waldo_fnc_ObjectScale)) then {_count = _count + 1};
    };
} forEach nearestObjects [_centre, [], _radius max 0, true];
_count
