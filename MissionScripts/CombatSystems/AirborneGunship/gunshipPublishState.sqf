/*
 * Author: Waldo
 * Publishes network-safe airborne-gunship summaries and refreshes local actions/markers.
 * Arguments: None
 * Return Value: Array
 */

if !(isServer) exitWith {[]};
private _registry = missionNamespace getVariable ["Waldo_Gunship_Registry", createHashMap];
private _summaries = [];
{
    private _state = _registry get _x;
    private _config = _state get "config";
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
        _config getOrDefault ["showMarkers", true]
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
[] remoteExecCall ["Waldo_fnc_GunshipSetupLocal", -2, "Waldo_Gunship_LocalSetup"];
_summaries
