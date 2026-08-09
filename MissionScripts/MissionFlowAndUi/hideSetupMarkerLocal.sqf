/*
 * Author: WaldoTheWarfighter
 * Hides one Eden setup/designation marker on an interface client throughout the multiplayer
 * briefing-to-mission transition. A dedicated server may consume a marker before a client finishes
 * loading mission.sqm; the client can then recreate its local editor copy after the server's global
 * deleteMarker has already happened. This repeat-safe local watcher removes every such late copy
 * until mission time starts, then performs a short final reconciliation pass.
 *
 * Locality and authority: interface-local presentation only. The authoritative feature still reads
 * and globally deletes the marker on the server. This function is sent with a persistent remoteExec
 * JIP key by paradrop and gunship registration, so current briefing clients and later JIP clients
 * receive the same hidden state. Repeated calls for one marker replace no state and share one watcher.
 *
 * Arguments:
 * 0: marker name <STRING> - the Eden-only source marker to hide (not the WMP operational marker).
 *
 * Return Value: Boolean - true when ignored on a non-interface machine, already watched, or queued.
 * Current callers: Waldo_fnc_ParadropQuickFlightSetup and Waldo_fnc_GunshipRegister.
 * Example: ["gunshipOrbit"] call Waldo_fnc_HideSetupMarkerLocal;
 * Result: gunshipOrbit cannot reappear in the dedicated briefing map while SPECTRE's live marker remains.
 */

params [["_markerName", "", [""]]];
if (_markerName == "" || {!hasInterface}) exitWith {true};

private _watchers = missionNamespace getVariable ["Waldo_SetupMarkerWatchersLocal", createHashMap];
if (_watchers getOrDefault [_markerName, false]) exitWith {true};
_watchers set [_markerName, true];
missionNamespace setVariable ["Waldo_SetupMarkerWatchersLocal", _watchers];

[_markerName] spawn {
    params ["_markerName"];
    // During the briefing, time remains at zero. Keep removing any mission.sqm copy recreated after
    // an earlier network delete; once simulation starts, cover another two seconds of late startup.
    waitUntil {
        if (markerShape _markerName != "" || {markerType _markerName != ""}) then {
            deleteMarkerLocal _markerName;
        };
        uiSleep 0.1;
        time > 0
    };
    private _finalUntil = diag_tickTime + 2;
    while {diag_tickTime < _finalUntil} do {
        if (markerShape _markerName != "" || {markerType _markerName != ""}) then {
            deleteMarkerLocal _markerName;
        };
        uiSleep 0.1;
    };
};
true
