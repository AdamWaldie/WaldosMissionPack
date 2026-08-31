/*
 * Author: WaldoTheWarfighter
 * Publishes network-safe airborne-gunship summaries and refreshes local actions/markers.
 *
 * The server strips private hash-map state into a public array, broadcasts it for current/JIP
 * clients, then asks interface machines to reconcile markers and controller actions. It is called
 * after registration and every state/controller/orbit/service transition.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Array - published gunship summaries
 *
 * Example:
 * private _summaries = [] call Waldo_fnc_GunshipPublishState;
 */

if !(isServer) exitWith {[]};
private _registry = missionNamespace getVariable ["Waldo_Gunship_Registry", createHashMap];
private _summaries = [];
{
    private _state = _registry get _x;
    private _config = _state get "config";
    // Tuple order is a shared contract read positionally by GunshipSetupLocal, GunshipUpdateMarkersLocal
    // and GunshipPromptOrbitConfig - append new fields at the end only, never insert/reorder.
    _summaries pushBack [
        _x,
        _state getOrDefault ["aircraft", objNull],
        _state getOrDefault ["controller", objNull],
        _state getOrDefault ["status", "UNAVAILABLE"],
        _state getOrDefault ["orbit", []],
        _config getOrDefault ["home", []],
        _config getOrDefault ["side", sideUnknown],
        _config getOrDefault ["callsign", _x],
        _config getOrDefault ["turretProfiles", []],
        _config getOrDefault ["showMarkers", true],
        _state getOrDefault ["serviceCompleteAt", -1],
        _config getOrDefault ["serviceDuration", 0],
        _config getOrDefault ["radius", 1500],
        _config getOrDefault ["altitude", 700],
        _state getOrDefault ["offStationReason", ""]
    ];
} forEach keys _registry;
missionNamespace setVariable ["Waldo_Gunship_PublicSystems", _summaries, true];
[
    [
        ["Waldo_Gunship_Enable", missionNamespace getVariable ["Waldo_Gunship_Enable", false]],
        ["Waldo_Gunship_PublicSystems", _summaries]
    ],
    false
] remoteExecCall ["Waldo_fnc_FeatureRuntimeReceiveState", -2];
// Target 0 (all machines), not -2 ("all clients except owner 2"): a listen server's host shares
// owner 2 with the embedded server, so -2 silently never reconciled controller actions/markers on
// the hosting player's own client. Waldo_fnc_GunshipSetupLocal already guards on hasInterface, so
// target 0 stays a safe no-op on a pure dedicated server.
if (_summaries isEqualTo []) then {
    // Current clients must reconcile removal immediately, but a future joiner has no marker/action
    // side effect to reconstruct. Remove the obsolete JIP call after dispatching empty-state cleanup.
    [] remoteExecCall ["Waldo_fnc_GunshipSetupLocal", 0];
    [] remoteExecCall ["", "Waldo_Gunship_LocalSetup"];
} else {
    [] remoteExecCall ["Waldo_fnc_GunshipSetupLocal", 0, "Waldo_Gunship_LocalSetup"];
};
_summaries
