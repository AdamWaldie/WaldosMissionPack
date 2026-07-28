/*
 * Author: Waldo
 * Registers or replaces a named hazardous-environment zone.
 * Profiles are hash maps so mission makers can extend them without changing the API.
 *
 * Arguments:
 * 0: key <STRING> - stable unique zone name
 * 1: area <OBJECT|STRING|ARRAY> - trigger, marker, moving emitter, [position, radius], or [position, a, b, angle, rectangle]
 * 2: profile <HASHMAP> - hazard settings and optional onTick callback
 *
 * Return Value:
 * Boolean - true when the zone was accepted
 *
 * Example:
 * ["reactor", haz1, createHashMapFromArray [["type", "RADIATION"], ["rate", 0.5]]] call Waldo_fnc_HazardRegisterZone;
 */

params [
    ["_key", "", [""]],
    ["_area", objNull, [objNull, "", []]],
    ["_profile", createHashMap, [createHashMap]]
];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
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
missionNamespace setVariable ["Waldo_Hazard_Zones", _zones, isServer];
true
