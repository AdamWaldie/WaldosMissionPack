/*
 * Author: WaldoTheWarfighter
 * Creates or updates a custom, broadcast 3D world marker rendered through one shared Draw3D
 * handler. The anchor may be an object or an ATL position. For an object, offset is relative to its
 * model: `[sideways, forwards, up]`; for a fixed position it is `[east, north, up]` in metres.
 * Colour is never required for meaning because every marker can carry icon and text together.
 *
 * Locality and repeat/JIP behaviour:
 * May be called anywhere. Non-server callers forward once to the server. The server owns the
 * registry, sends one-row revisioned deltas to current clients, and answers an explicit full-state
 * request from each joining client. Reusing an ID updates its existing marker instead of
 * duplicating it; missed or out-of-order deltas trigger a fresh snapshot request.
 * An Eden Init field runs again on every joining client and forwards the same call. The server
 * therefore ignores a forwarded call that would not change an existing marker, and one for an ID
 * already removed with Waldo_fnc_Remove3DMarker, so joiners neither rebroadcast nor restore
 * markers. A server-side call (Eden Init on the server, scripts, ZEN) always applies.
 *
 * Arguments:
 * 0: stable marker ID <STRING> (default auto-generated)
 * 1: object anchor or ATL position <OBJECT or ARRAY> (default [0,0,0])
 * 2: named options <HASHMAP or ARRAY of [key,value]> (default [])
 *    Common keys: text, icon, colour RGBA, offset, width, height, angle, shadow, textSize,
 *    font, align, sideArrows, distance, sides and enabled.
 * 3: forwarded from a client <BOOL> (default false) - set only by this function's own client
 *    forward; callers never pass it.
 *
 * Return Value: String - marker ID, or an empty string when rejected.
 * Current callers: scripts/compositions and the Create Custom 3D Marker ZEN server bridge.
 *
 * Example:
 * ["generator", generator_1, createHashMapFromArray [
 *     ["text", "GENERATOR ALPHA | OFFLINE"],
 *     ["icon", "\a3\ui_f\data\map\markers\military\warning_CA.paa"],
 *     ["colour", [1, 0.75, 0.2, 1]], ["offset", [0,0,0]], ["distance", 80]
 * ]] call Waldo_fnc_Create3DMarker;
 */
params [
    ["_id", "", [""]],
    ["_anchor", [0, 0, 0], [objNull, []]],
    ["_options", [], [[], createHashMap]],
    ["_forwarded", false, [false]]
];
if (_id isEqualTo "") then {_id = format ["WMP3D_%1_%2", clientOwner, floor (diag_tickTime * 1000)];};
if (!isServer) exitWith {
    // Init-field replay on a joining client: the server already ran this Init line, and forwarding
    // it again would recreate state removed since. Later script/action calls still forward.
    if !(missionNamespace getVariable ["Waldo_ClientInitPhaseDone", false]) exitWith {
        diag_log format ["[WMP JIP] Skipped Init-field replay of %1 on client %2.", "Waldo_fnc_Create3DMarker", clientOwner];
        _id
    };
    [_id, _anchor, _options, true] remoteExecCall ["Waldo_fnc_Create3DMarker", 2];
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
private _removed = missionNamespace getVariable ["Waldo_3DMarker_RemovedIds", createHashMap];
if (_forwarded && {_id in _removed}) exitWith {
    diag_log format ["[WMP 3D MARKER] Ignored forwarded create for removed id=%1 owner=%2.", _id, remoteExecutedOwner];
    ""
};
if (_index >= 0 && {(_registry select _index) isEqualTo _row}) exitWith {_id};
_removed deleteAt _id;
if (_index < 0) then {_registry pushBack _row;} else {_registry set [_index, _row];};
missionNamespace setVariable ["Waldo_3DMarker_Registry", _registry];
private _revision = (missionNamespace getVariable ["Waldo_3DMarker_Revision", 0]) + 1;
missionNamespace setVariable ["Waldo_3DMarker_Revision", _revision];
[_revision, "UPSERT", _row] remoteExecCall ["Waldo_fnc_Marker3DApplyDeltaLocal", -2];
_id
