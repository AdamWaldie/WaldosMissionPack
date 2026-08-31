/*
 * Author: WaldoTheWarfighter, Val
 * Registers or replaces a named hazardous-environment zone.
 * Profiles are hash maps so mission makers can extend them without changing the API.
 *
 * The server/runtime path broadcasts definitions and replays them to JIP clients. Eden init fields
 * execute on every machine, so their expected non-server copies return false without logging; only
 * the server copy registers the zone. Unauthorized client remote execution is rejected. This is
 * currently called by preset/emitter adapters, ZEN runtime creation and mission scripts.
 * Locality and authority: Server-authoritative. Approved ZEN requests route through the server
 * wrapper. Accepted changes are published for current/JIP clients.
 *
 * Arguments:
 * 0: key <STRING> - stable unique zone name
 * 1: area <OBJECT|STRING|ARRAY> - trigger, marker, moving emitter, [position, radius], or [position, a, b, angle, rectangle]
 * 2: profile <HASHMAP> - hazard settings and optional onTick callback. Set ["markerEnabled", true] to
 *    tie a broadcast Waldo_fnc_Create3DMarker world marker to this zone's own area/object - anchored
 *    directly to the source object for a moving emitter, so every player can see where the hazard is
 *    without depending on the per-player exposure HUD. Optional ["marker", HASHMAP] supplies
 *    Waldo_fnc_Create3DMarker options (icon/colour/text/offset/distance/sides); unset keys fall back
 *    to a warning icon, the profile's label, and a 200 m view distance. The marker is created once at
 *    registration and removed automatically when the zone is unregistered - it is not part of the
 *    per-tick evaluation loop.
 * 3: authorised runtime request <BOOLEAN> - internal server-wrapper proof (default false)
 *
 * Return Value:
 * Boolean - true when the zone was accepted
 *
 * Example:
 * ["reactor", haz1, createHashMapFromArray [["type", "RADIATION"], ["rate", 0.5]]] call Waldo_fnc_HazardRegisterZone;
 * Result: Registers or replaces the server zone named `reactor` and republishes the ordered snapshot.
 * Current callers: preset/emitter adapters, ZEN runtime creation and server mission scripts.
 */

params [
    ["_key", "", [""]],
    ["_area", objNull, [objNull, "", []]],
    ["_profile", createHashMap, [createHashMap]],
    ["_authorisedRuntime", false, [false]]
];
// Eden object init fields execute on every machine. The server copy performs the authoritative
// registration; expected client copies are silent no-ops rather than one misleading rejection per
// zone and joining client.
if !(isServer) exitWith {false};
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2} && {!_authorisedRuntime}) exitWith {false};
if (_key == "") exitWith {false};
if (_area isEqualType objNull && {isNull _area}) exitWith {false};
if (_area isEqualType "" && {_area == ""}) exitWith {false};
if (_area isEqualType [] && {count _area < 2 || {count _area > 2 && {count _area < 5}}}) exitWith {false};

private _zones = missionNamespace getVariable ["Waldo_Hazard_Zones", []];
private _index = _zones findIf {(_x select 0) == _key};
private _entry = [_key, _area, _profile];
if (_index >= 0) then {
    _zones set [_index, _entry];
} else {
    _zones pushBack _entry;
};
missionNamespace setVariable ["Waldo_Hazard_Zones", _zones];
missionNamespace setVariable ["Waldo_Hazard_Enable", true, true];
[] call Waldo_fnc_HazardPublishState;
diag_log format ["[WMP HAZARD] Registered zone '%1'; authoritative zone count=%2.", _key, count _zones];

if (_profile getOrDefault ["markerEnabled", false]) then {
    // Resolve one marker anchor from this zone's own area definition - an object anchor (including a
    // moving emitter) is passed straight through so Waldo_fnc_Create3DMarker's Draw3D renderer tracks
    // it live; marker/array areas resolve to their static centre position instead.
    private _anchor = objNull;
    if (_area isEqualType objNull) then {
        _anchor = _area;
    } else {
        if (_area isEqualType "") then {
            private _pos = getMarkerPos _area;
            _anchor = [_pos select 0, _pos select 1, 0];
        } else {
            if (_area isEqualType [] && {count _area > 0}) then {_anchor = _area select 0;};
        };
    };
    private _markerValid = if (_anchor isEqualType objNull) then {!isNull _anchor} else {_anchor isEqualType [] && {count _anchor >= 2}};
    if (_markerValid) then {
        private _markerOptions = _profile getOrDefault ["marker", createHashMap];
        if (typeName _markerOptions != "HASHMAP") then {_markerOptions = createHashMap;};
        private _defaults = createHashMapFromArray [
            ["text", _profile getOrDefault ["label", _key]],
            ["icon", "\a3\ui_f\data\map\markers\military\warning_CA.paa"],
            ["colour", [0.95, 0.35, 0.1, 0.95]],
            ["distance", 200],
            ["offset", [0, 0, 2]]
        ];
        {if (isNil {_markerOptions get _x}) then {_markerOptions set [_x, _defaults get _x];};} forEach keys _defaults;
        [format ["WMP_HAZARD_%1", _key], _anchor, _markerOptions] call Waldo_fnc_Create3DMarker;
    };
};
true
