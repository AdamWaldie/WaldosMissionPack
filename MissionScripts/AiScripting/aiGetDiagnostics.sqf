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
private _includedSides = missionNamespace getVariable ["Waldo_AI_IncludedSides", []];
private _includedSideKeys = (_includedSides select {_x isEqualType ""}) apply {toUpperANSI _x};
private _includedFactions = missionNamespace getVariable ["Waldo_AI_IncludedFactions", []];
private _excludedFactions = missionNamespace getVariable ["Waldo_AI_ExcludedFactions", []];
private _excludedClasses = missionNamespace getVariable ["Waldo_AI_ExcludedClasses", []];
private _eligibleAI = {
    params ["_unit"];
    private _sideKey = switch (side group _unit) do {
        case west: {"WEST"}; case east: {"EAST"}; case independent: {"GUER"}; default {"CIV"};
    };
    !isPlayer _unit
    && {!(_unit getVariable ["Waldo_ServerOwnedFeature", false])}
    && {!(_unit getVariable ["Waldo_AI_Exclude", false])}
    && {count _includedSides == 0 || {_sideKey in _includedSideKeys}}
    && {count _includedFactions == 0 || {faction _unit in _includedFactions}}
    && {!(faction _unit in _excludedFactions)}
    && {!(typeOf _unit in _excludedClasses)}
};
private _missing = _hcGroups select {
    private _owner = groupOwner _x;
    private _aceResult = _x getVariable ["Waldo_AI_LastHeadlessAdoption", []];
    private _wmpResult = _x getVariable ["Waldo_Headless_LastAdoption", []];
    private _eligibleCount = {_x call _eligibleAI} count units _x;
    private _aceValid = count _aceResult >= 2
        && {(_aceResult select 0) == _owner}
        && {(_aceResult select 1) >= _eligibleCount};
    private _wmpValid = count _wmpResult >= 4
        && {(_wmpResult select 1) == _owner}
        && {_wmpResult select 2}
        && {(!_enabled) || {(_wmpResult select 3) >= _eligibleCount}};
    !(_aceValid || {_wmpValid})
};
private _helicopters = (allMissionObjects "Helicopter") select {alive _x};
private _activeLanding = _helicopters select {_x getVariable ["Waldo_ImprovedHelicopterLanding_Active", false]};
private _orphanedMovementControl = _helicopters select {
    (_x getVariable ["Waldo_ImprovedHelicopterLanding_GroundAnchored", false])
    || {_x getVariable ["Waldo_ImprovedHelicopterLanding_Active", false]}
};
private _staleLanding = _helicopters select {
    _x getVariable ["Waldo_ImprovedHelicopterLanding_GroundAnchored", false]
    && {!(_x getVariable ["Waldo_ImprovedHelicopterLanding_Active", false])}
};
private _groupedLanding = _activeLanding select {
    private _aircraft = _x;
    private _pilot = currentPilot _aircraft;
    if (isNull _pilot) exitWith {false};
    private _aircraftInGroup = [];
    {
        private _vehicle = vehicle _x;
        if (_vehicle isKindOf "Helicopter") then {_aircraftInGroup pushBackUnique _vehicle};
    } forEach (units (group _pilot));
    count _aircraftInGroup > 1
};
private _checks = [
    ["ai", "ai-profile", if (_enabled) then {"ACTIVE"} else {"DISABLED"}, format ["profile=%1 mode=%2 serverActive=%3", missionNamespace getVariable ["Waldo_AIRebalance_Profile", "LINE"], missionNamespace getVariable ["Waldo_AIRebalance_Mode", "DAY"], missionNamespace getVariable ["Waldo_AI_RebalanceActive", false]]],
    ["ai", "ai-headless-adoption", if (!_enabled) then {"DISABLED"} else {if (count _missing > 0) then {"ERROR"} else {if (count _hcGroups > 0) then {"ACTIVE"} else {"UNCONFIGURED"}}}, format ["connectedHCs=%1 hcOwnedGroups=%2 missingVerifiedAdoption=%3", count _hcOwners, count _hcGroups, count _missing]],
    ["ai", "improved-helicopter-landing", if !(missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_Enable", true]) then {"DISABLED"} else {if (count _staleLanding > 0 || {count _groupedLanding > 0}) then {"ERROR"} else {if (count _activeLanding > 0) then {"ACTIVE"} else {"LOADED"}}}, format ["helicopters=%1 movementOwned=%2 activeControllers=%3 staleGroundAnchors=%4 groupedControllers=%5", count _helicopters, count _orphanedMovementControl, count _activeLanding, count _staleLanding, count _groupedLanding]]
];
["ai", _checks] call Waldo_fnc_DiagnosticFeatureReport
