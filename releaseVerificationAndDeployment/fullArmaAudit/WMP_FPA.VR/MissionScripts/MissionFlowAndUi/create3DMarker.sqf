/*
 * Author: WaldoTheWarfighter
 * Creates or updates a custom, broadcast 3D world marker rendered through one shared
 * Draw3D handler. The anchor may be an object or an ATL position. Colour is never
 * required for meaning because every marker can carry icon and text together.
 *
 * Arguments: [id, anchor, options]
 * Options: text, icon, colour, offset, width, height, angle, shadow, textSize,
 * font, align, sideArrows, distance, sides, enabled.
 *
 * Example:
 * ["generator", generator_1, createHashMapFromArray [
 *     ["text", "GENERATOR ALPHA | OFFLINE"],
 *     ["icon", "\a3\ui_f\data\map\markers\military\warning_CA.paa"],
 *     ["colour", [1, 0.75, 0.2, 1]], ["offset", [0,0,2.5]], ["distance", 80]
 * ]] call Waldo_fnc_Create3DMarker;
 */
params [
    ["_id", "", [""]],
    ["_anchor", [0, 0, 0], [objNull, []]],
    ["_options", [], [[], createHashMap]]
];
if (_id isEqualTo "") then {_id = format ["WMP3D_%1_%2", clientOwner, floor (diag_tickTime * 1000)];};
if (!isServer) exitWith {
    [_id, _anchor, _options] remoteExecCall ["Waldo_fnc_Create3DMarker", 2];
    _id
};
if (_anchor isEqualType objNull && {isNull _anchor}) exitWith {""};
if (_anchor isEqualType [] && {(count _anchor) < 2}) exitWith {""};

private _pairs = if (_options isEqualType createHashMap) then {
    private _result = [];
    {_result pushBack [_x, _options get _x];} forEach keys _options;
    _result
} else {+_options};
private _get = {
    params ["_key", "_default"];
    private _value = _default;
    {if ((_x param [0, ""]) isEqualTo _key) exitWith {_value = _x param [1, _default];};} forEach _pairs;
    _value
};
private _row = [
    _id,
    _anchor,
    ["offset", [0, 0, 0]] call _get,
    ["icon", "\a3\ui_f\data\map\markers\military\dot_CA.paa"] call _get,
    ["colour", [0.49, 0.78, 1, 0.95]] call _get,
    ["width", 0.8] call _get,
    ["height", 0.8] call _get,
    ["angle", 0] call _get,
    ["text", ""] call _get,
    ["shadow", 2] call _get,
    ["textSize", 0.032] call _get,
    ["font", "RobotoCondensedBold"] call _get,
    ["align", "center"] call _get,
    ["sideArrows", true] call _get,
    ["distance", 75] call _get,
    ["sides", ["ALL"]] call _get,
    ["enabled", true] call _get
];
private _registry = +(missionNamespace getVariable ["Waldo_3DMarker_Registry", []]);
private _index = _registry findIf {(_x param [0, ""]) isEqualTo _id};
if (_index < 0) then {_registry pushBack _row;} else {_registry set [_index, _row];};
missionNamespace setVariable ["Waldo_3DMarker_Registry", _registry, true];
_id
