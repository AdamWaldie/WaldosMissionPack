/*
 * Author: WaldoTheWarfighter, Val
 * Applies one server-authored hazardous-environment snapshot and reconciles the local evaluator.
 *
 * Arguments:
 * 0: enabled <BOOLEAN>
 * 1: zones <ARRAY> - complete sanitised registry
 *
 * Return Value: BOOLEAN - true when the server snapshot was accepted.
 * Example: Internal JIP call from Waldo_fnc_HazardPublishState.
 * Current caller: Waldo_fnc_HazardPublishState through one replaceable remote-exec JIP key.
 */

params [["_enabled", false, [false]], ["_zones", [], [[]]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};

// A hosted server retains its authoritative registry (including mission-local CODE callbacks), but
// its player interface still reconciles against the same enable/start decision as remote clients.
if !(isServer) then {missionNamespace setVariable ["Waldo_Hazard_Zones", _zones]};
missionNamespace setVariable ["Waldo_Hazard_Enable", _enabled];
missionNamespace setVariable ["Waldo_Hazard_SnapshotReceived", true];
if (hasInterface) then {
    if (_enabled) then {[] call Waldo_fnc_HazardInit} else {[] call Waldo_fnc_HazardStop};
};
diag_log format ["[WMP HAZARD] Ordered snapshot received: enabled=%1 zones=%2 interface=%3.", _enabled, count _zones, hasInterface];
true
