/*
 * Author: WaldoTheWarfighter
 * Reports whether the WMP AI profile is active and whether ordinary AI groups currently owned by
 * headless clients have acknowledged profile adoption. This is independent of which scheduler moved
 * the groups: ACE Headless may be active while WMP's optional HC distributor is disabled.
 *
 * Locality and authority:
 * Read-only and server-only. It compares engine HeadlessClient_F owners with current groupOwner and
 * authenticated adoption records. No state is changed or broadcast; repeat/JIP behaviour is not
 * applicable. The shared diagnostics runner publishes the resulting report normally.
 *
 * Arguments: None.
 * Return Value: HashMap - Waldo_fnc_DiagnosticFeatureReport shape for area "ai".
 *
 * Example:
 * [] call Waldo_fnc_AIGetDiagnostics;
 * Result: reports active profile/mode and any HC-owned groups lacking verified adoption.
 *
 * Current caller: Waldo_fnc_RunDiagnostics.
 */

if !(isServer) exitWith {["ai", []] call Waldo_fnc_DiagnosticFeatureReport};
private _enabled = missionNamespace getVariable ["Waldo_AIRebalance_Enable", false];
private _hcOwners = (entities "HeadlessClient_F") apply {owner _x};
private _hcGroups = allGroups select {
    groupOwner _x in _hcOwners
    && {(units _x) findIf {isPlayer _x} < 0}
    && {!(_x getVariable ["Waldo_ServerOwnedFeature", false])}
};
private _missing = _hcGroups select {
    private _owner = groupOwner _x;
    private _aceResult = _x getVariable ["Waldo_AI_LastHeadlessAdoption", []];
    private _wmpResult = _x getVariable ["Waldo_Headless_LastAdoption", []];
    !((count _aceResult >= 1 && {(_aceResult select 0) == _owner})
        || {count _wmpResult >= 3 && {(_wmpResult select 1) == _owner} && {_wmpResult select 2}})
};
private _checks = [
    ["ai", "ai-profile", if (_enabled) then {"ACTIVE"} else {"DISABLED"}, format ["profile=%1 mode=%2 serverActive=%3", missionNamespace getVariable ["Waldo_AIRebalance_Profile", "LINE"], missionNamespace getVariable ["Waldo_AIRebalance_Mode", "DAY"], missionNamespace getVariable ["Waldo_AI_RebalanceActive", false]]],
    ["ai", "ai-headless-adoption", if (!_enabled) then {"DISABLED"} else {if (count _missing > 0) then {"ERROR"} else {if (count _hcGroups > 0) then {"ACTIVE"} else {"UNCONFIGURED"}}}, format ["connectedHCs=%1 hcOwnedGroups=%2 missingVerifiedAdoption=%3", count _hcOwners, count _hcGroups, count _missing]]
];
["ai", _checks] call Waldo_fnc_DiagnosticFeatureReport
