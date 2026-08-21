/*
 * Author: WaldoTheWarfighter
 * Removes WMP custom 3D world markers by stable ID, object anchor, or nearest fixed position.
 * This affects only Waldo_fnc_Create3DMarker entries and never deletes Eden/map markers or anchors.
 *
 * Locality and authority:
 * May be called from mission script on any machine. Non-server calls forward the selector once;
 * the server owns the registry, sends a compact removal delta to current clients, and supplies a
 * revisioned full snapshot only when a joining or out-of-date client requests one.
 *
 * Repeat/JIP behaviour:
 * Repeat-safe. Missing selectors return false and the broadcast registry remains unchanged.
 * Removing an object anchor removes every WMP 3D marker attached to that exact object.
 *
 * Arguments:
 * 0: marker selector <STRING|OBJECT|ARRAY> - exact ID, anchor object, or ATL position
 * 1: nearest-position radius <NUMBER> (default 25 m; used only for an ARRAY selector)
 *
 * Return Value: BOOL - true when one or more markers were removed or a client request was queued.
 * Current callers: mission scripts, hazard cleanup, audit cases and the ZEN removal bridge.
 *
 * Example: ["generator_alpha"] call Waldo_fnc_Remove3DMarker;
 * Example: [generator_1] call Waldo_fnc_Remove3DMarker;
 * Example: [[1200, 800, 0], 50] call Waldo_fnc_Remove3DMarker;
 */
params [
    ["_selector", "", ["", objNull, []]],
    ["_radius", 25, [0]]
];
if (_selector isEqualType "" && {_selector == ""}) exitWith {false};
if (_selector isEqualType objNull && {isNull _selector}) exitWith {false};
if (_selector isEqualType [] && {count _selector < 2}) exitWith {false};
_radius = (_radius max 0) min 10000;

if (!isServer) exitWith {
    [_selector, _radius] remoteExecCall ["Waldo_fnc_Remove3DMarker", 2];
    true
};

private _registry = +(missionNamespace getVariable ["Waldo_3DMarker_Registry", []]);
private _indices = [];
if (_selector isEqualType "") then {
    private _index = _registry findIf {(_x param [0, ""]) isEqualTo _selector};
    if (_index >= 0) then {_indices pushBack _index};
};
if (_selector isEqualType objNull) then {
    {
        if ((_x param [1, objNull, [objNull, []]]) isEqualTo _selector) then {_indices pushBack _forEachIndex};
    } forEach _registry;
};
if (_selector isEqualType []) then {
    private _nearestIndex = -1;
    private _nearestDistance = 1e10;
    {
        private _anchor = _x param [1, [], [objNull, []]];
        private _position = if (_anchor isEqualType objNull) then {
            if (isNull _anchor) then {[]} else {getPosATL _anchor}
        } else {
            [_anchor param [0, 0], _anchor param [1, 0], _anchor param [2, 0]]
        };
        if (count _position >= 2) then {
            private _distance = _selector distance2D _position;
            if (_distance <= _radius && {_distance < _nearestDistance}) then {
                _nearestIndex = _forEachIndex;
                _nearestDistance = _distance;
            };
        };
    } forEach _registry;
    if (_nearestIndex >= 0) then {_indices pushBack _nearestIndex};
};

if (_indices isEqualTo []) exitWith {false};
private _removedIds = _indices apply {(_registry select _x) param [0, ""]};
_indices sort false;
{_registry deleteAt _x} forEach _indices;
missionNamespace setVariable ["Waldo_3DMarker_Registry", _registry];
private _revision = (missionNamespace getVariable ["Waldo_3DMarker_Revision", 0]) + 1;
missionNamespace setVariable ["Waldo_3DMarker_Revision", _revision];
[_revision, "REMOVE", _removedIds] remoteExecCall ["Waldo_fnc_Marker3DApplyDeltaLocal", -2];
true
