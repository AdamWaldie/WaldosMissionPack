/*
 * Author: WaldoTheWarfighter
 * Removes a planted signal tracker from the registry. Server-authoritative - calling on a client
 * forwards to the server, which re-broadcasts so the marker disappears on every tracking client.
 * Locality/authority: mutation and JIP publication run on the server; a listen host explicitly wakes
 * its local renderer because engine publication is not replayed to the publisher.
 * Repeat/JIP behaviour: returns false when already absent. The updated registry is persistent for JIP;
 * removing the final entry lets each client renderer clean its markers and become idle.
 *
 * Arguments:
 * 0: Reference <OBJECT or NUMBER> - the tracked object, or the tracker id from Waldo_fnc_Tracker
 *
 * Return Value:
 * Bool <BOOL> - true if a matching tracker was found and removed (server side)
 *
 * Current Callers: Public script API, tracker ZEN controls and mission-maker integrations.
 *
 * Example:
 * [enemyTruck] call Waldo_fnc_TrackerRemove;
 * [2] call Waldo_fnc_TrackerRemove;
 */

params [["_ref", objNull]];

if (!isServer) exitWith {
    _this remoteExec ["Waldo_fnc_TrackerRemove", 2];
    false
};

private _registry = missionNamespace getVariable ["Waldo_Tracker_Registry", []];
private _idx = -1;
if (_ref isEqualType objNull) then {
    _idx = _registry findIf { (_x select 1) == _ref };
} else {
    if (_ref isEqualType 0) then { _idx = _registry findIf { (_x select 0) == _ref }; };
};
if (_idx < 0) exitWith { false };

_registry deleteAt _idx;
missionNamespace setVariable ["Waldo_Tracker_Registry", _registry, true];
if (hasInterface) then {[] call Waldo_fnc_TrackerRender;};
true
