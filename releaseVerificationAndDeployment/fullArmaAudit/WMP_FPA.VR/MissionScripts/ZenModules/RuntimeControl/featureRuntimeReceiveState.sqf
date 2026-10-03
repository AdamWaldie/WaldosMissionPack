/*
 * Author: WaldoTheWarfighter
 * Applies one ordered server runtime-setting snapshot on a joining client or headless client.
 * Locality and authority: Receives only server remote execution; each receiving machine applies
 * the server-owned names locally before dependent client features activate.
 * Repeat/JIP: A complete snapshot sets the local readiness sentinel. Later broadcasts can update
 * individual settings without discarding that initial readiness.
 *
 * Arguments:
 * 0: name/value pairs <ARRAY>
 * 1: complete initial snapshot <BOOLEAN>
 * Return Value: Boolean - true when accepted
 *
 * Example: [[["Waldo_UI_Theme", "WW2"]], true] call Waldo_fnc_FeatureRuntimeReceiveState;
 * Current callers: server JIP snapshot response and live runtime-setting broadcasts.
 * Result: The receiving machine has the new settings and, for a complete snapshot, is ready.
 */

params [["_snapshot", [], [[]]], ["_complete", false, [false]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};

private _incoming = createHashMapFromArray _snapshot;
private _aiRevision = _incoming getOrDefault ["Waldo_AIPass_SettingsRevision",-1];
private _staleAI = _aiRevision < (missionNamespace getVariable ["Waldo_AIPass_SettingsApplied",-1]);
private _aiNames = ([] call Waldo_fnc_CortexTuningSpec) apply {_x select 0};
_aiNames append ["Waldo_AIPass_SettingsRevision","Waldo_AIPass_AmmoCapabilityOverrides"];

{
    _x params [["_name", "", [""]], ["_value", nil]];
    if (_name != "" && {!isNil "_value"} && {!(_staleAI && {_name in _aiNames})}) then {
        missionNamespace setVariable [_name, _value];
    };
} forEach _snapshot;
if (!isNil "Waldo_fnc_UiThemeApplyLocal") then {
    [missionNamespace getVariable ["Waldo_UI_Theme", "DEFAULT"], false] call Waldo_fnc_UiThemeApplyLocal;
};
if (_complete) then {
    missionNamespace setVariable ["Waldo_FeatureRuntimeSnapshotFailed", false];
    missionNamespace setVariable ["Waldo_FeatureRuntimeRequestInFlight", false];
    missionNamespace setVariable ["Waldo_FeatureRuntimeSnapshotReceived", true];
};
true
