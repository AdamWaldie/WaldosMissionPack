/*
 * Author: WaldoTheWarfighter, Val
 * Registers or replaces a named hazardous-environment zone.
 * Profiles are hash maps so mission makers can extend them without changing the API.
 *
 * The server/runtime path broadcasts definitions and replays them to JIP clients; pre-planned calls
 * may also run consistently on each client. Unauthorized client remote execution is rejected. This
 * is currently called by preset/emitter adapters, ZEN runtime creation and mission scripts.
 * Locality and authority: Server-authoritative. Direct client execution is rejected; approved ZEN
 * requests route through the server wrapper. Accepted changes are published for current/JIP clients.
 *
 * Arguments:
 * 0: key <STRING> - stable unique zone name
 * 1: area <OBJECT|STRING|ARRAY> - trigger, marker, moving emitter, [position, radius], or [position, a, b, angle, rectangle]
 * 2: profile <HASHMAP> - hazard settings and optional onTick callback
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
if !(isServer) exitWith {
    diag_log format ["[WMP HAZARD] Zone '%1' rejected locally: shared zones must be registered by initServer.sqf or the ZEN module.", _key];
    false
};
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
true
