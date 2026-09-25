/*
 * Author: WaldoTheWarfighter
 * Reports whether the WMP AI profile is active and whether ordinary AI groups currently owned by
 * headless clients have acknowledged profile adoption. Also reports the Smart AI Pass scheduler and
 * survivor-regroup counters for the server (headless-client counters stay on those machines). This is independent of which scheduler moved
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
private _decelerationEnabled = missionNamespace getVariable ["Waldo_HelicopterDeceleration_Enable", false];
private _decelerationAircraft = vehicles select {
    _x getVariable ["Waldo_HelicopterDeceleration_LocalHandlerInstalled", false]
};
private _decelerationActive = _decelerationAircraft select {
    _x getVariable ["Waldo_HelicopterDeceleration_Active", false]
};
private _decelerationLandingConflict = _decelerationActive select {
    _x getVariable ["Waldo_ImprovedHelicopterLanding_Active", false]
};
private _passEnabled = missionNamespace getVariable ["Waldo_AIPass_Enable", false];
private _passActive = missionNamespace getVariable ["Waldo_AIPass_Active", false];
private _passJobs = count (missionNamespace getVariable ["Waldo_AIPass_Jobs", []]) + count (missionNamespace getVariable ["Waldo_AIPass_PendingJobs", []]);
private _passState = if (!_passEnabled) then {"DISABLED"} else {if (_passActive && {!isNil {missionNamespace getVariable "Waldo_AIPass_SchedulerHandle"}}) then {"ACTIVE"} else {"ERROR"}};
private _passHint = if (_passState == "ERROR") then {"Waldo_AIPass_Enable is true but the server scheduler is not running; check RPT for [WMP AI PASS] and that CBA is loaded."} else {""};
private _regroupEnabled = missionNamespace getVariable ["Waldo_AIPass_Regroup_Enable", true];
private _checks = [
    ["ai", "smart-ai-pass", _passState, [format ["enabled=%1 serverActive=%2 serverJobs=%3 paused=%4 includedSides=%5", _passEnabled, _passActive, _passJobs, [] call Waldo_fnc_AIPassIsPaused, missionNamespace getVariable ["Waldo_AIPass_IncludedSides", []]], _passHint] call Waldo_fnc_DiagnosticFoldHint],
    ["ai", "smart-ai-pass-regroup", if (_passEnabled && {_regroupEnabled}) then {"ACTIVE"} else {"DISABLED"}, format ["enabled=%1 serverRegroupsCompleted=%2 serverUnitsJoined=%3", _regroupEnabled, missionNamespace getVariable ["Waldo_AIPass_RegroupsCompleted", 0], missionNamespace getVariable ["Waldo_AIPass_RegroupJoined", 0]]],
    ["ai", "smart-ai-pass-groups", if (!_passEnabled) then {"DISABLED"} else {"ACTIVE"}, format ["serverManaged=%1 inContact=%2 retreating=%3 garrisons=%4 flanksCompleted=%5 retreats=%6 surrenders=%7 reinforcementsSent=%8 grenadeReactions=%9",
        {local _x && {_x getVariable ["Waldo_AIPass_Managed", false]}} count allGroups,
        {((_x getVariable ["Waldo_AIPass_State", createHashMap]) getOrDefault ["phase", ""]) == "CONTACT"} count allGroups,
        {((_x getVariable ["Waldo_AIPass_State", createHashMap]) getOrDefault ["phase", ""]) == "RETREAT"} count allGroups,
        {(_x getVariable ["Waldo_AIPass_Garrison", []]) isNotEqualTo []} count allGroups,
        missionNamespace getVariable ["Waldo_AIPass_FlanksCompleted", 0], missionNamespace getVariable ["Waldo_AIPass_Retreats", 0],
        missionNamespace getVariable ["Waldo_AIPass_Surrenders", 0], missionNamespace getVariable ["Waldo_AIPass_ReinforcementsSent", 0],
        missionNamespace getVariable ["Waldo_AIPass_GrenadeReactions", 0]]],
    ["ai", "smart-ai-pass-drills", if (!_passEnabled) then {"DISABLED"} else {"ACTIVE"}, format ["assaults=%1 advances=%2 investigations=%3 coordinatedAssaults=%4 magazinesShared=%5 defences=%6",
        missionNamespace getVariable ["Waldo_AIPass_Assaults", 0], missionNamespace getVariable ["Waldo_AIPass_AdvancesCompleted", 0],
        missionNamespace getVariable ["Waldo_AIPass_Investigations", 0], missionNamespace getVariable ["Waldo_AIPass_CoordinatedAssaults", 0],
        missionNamespace getVariable ["Waldo_AIPass_MagazinesShared", 0],
        {(_x getVariable ["Waldo_AIPass_Defend", []]) isNotEqualTo []} count allGroups]],
    ["ai", "smart-ai-pass-zeus", if (!_passEnabled) then {"DISABLED"} else {"ACTIVE"}, format ["heldByZeus=%1 zeusWaypointGroups=%2 excluded=%3 holdSeconds=%4",
        {local _x && {[_x] call Waldo_fnc_AIPassZeusHeld}} count allGroups,
        {_x getVariable ["Waldo_AIPass_ZeusWaypoints", false]} count allGroups,
        {_x getVariable ["Waldo_AIPass_Exclude", false]} count allGroups,
        missionNamespace getVariable ["Waldo_AIPass_ZeusHoldSeconds", 120]]],
    ["ai", "smart-ai-pass-support", if (!_passEnabled) then {"DISABLED"} else {"ACTIVE"}, format ["artillery=%1 counterBattery=%2 serverBatteries=%3 missions=%4 radars=%5 airborne=%6 auto=%7 drops=%8 flares=%9",
        missionNamespace getVariable ["Waldo_AIPass_Artillery_Enable", false], missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Enable", false],
        count (missionNamespace getVariable ["Waldo_AIPass_LocalArtillery", []]), missionNamespace getVariable ["Waldo_AIPass_ArtilleryMissions", 0],
        count (missionNamespace getVariable ["Waldo_AIPass_CounterBatteryRadars", []]), missionNamespace getVariable ["Waldo_AIPass_Airborne_Enable", false],
        missionNamespace getVariable ["Waldo_AIPass_Airborne_Auto", false], missionNamespace getVariable ["Waldo_AIPass_AirborneDrops", 0],
        missionNamespace getVariable ["Waldo_AIPass_AircraftFlares_Enable", false]]],
    ["ai", "smart-ai-pass-lambs", if (!(missionNamespace getVariable ["Waldo_AIPass_LambsDangerLoaded", isClass (configFile >> "CfgPatches" >> "lambs_danger")])) then {"UNAVAILABLE"} else {"ACTIVE"}, format ["lambsDanger=%1 lambsWaypoints=%2 mode=%3", isClass (configFile >> "CfgPatches" >> "lambs_danger"), isClass (configFile >> "CfgPatches" >> "lambs_wp"), missionNamespace getVariable ["Waldo_AIPass_LambsMode", "SPLIT"]]],
    ["ai", "ai-profile", if (_enabled) then {"ACTIVE"} else {"DISABLED"}, format ["profile=%1 mode=%2 serverActive=%3", missionNamespace getVariable ["Waldo_AIRebalance_Profile", "LINE"], missionNamespace getVariable ["Waldo_AIRebalance_Mode", "DAY"], missionNamespace getVariable ["Waldo_AI_RebalanceActive", false]]],
    ["ai", "ai-headless-adoption", if (!_enabled) then {"DISABLED"} else {if (count _missing > 0) then {"ERROR"} else {if (count _hcGroups > 0) then {"ACTIVE"} else {"UNCONFIGURED"}}}, format ["connectedHCs=%1 hcOwnedGroups=%2 missingVerifiedAdoption=%3", count _hcOwners, count _hcGroups, count _missing]],
    ["ai", "improved-helicopter-landing", if !(missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_Enable", true]) then {"DISABLED"} else {if (count _staleLanding > 0 || {count _groupedLanding > 0}) then {"ERROR"} else {if (count _activeLanding > 0) then {"ACTIVE"} else {"LOADED"}}}, format ["helicopters=%1 movementOwned=%2 activeControllers=%3 staleGroundAnchors=%4 groupedControllers=%5", count _helicopters, count _orphanedMovementControl, count _activeLanding, count _staleLanding, count _groupedLanding]],
    ["ai", "helicopter-deceleration", if (!_decelerationEnabled) then {"DISABLED"} else {if (count _decelerationLandingConflict > 0) then {"ERROR"} else {"ACTIVE"}}, format ["enabled=%1 tracked=%2 activelyCorrecting=%3 landingConflicts=%4 includeVTOL=%5", _decelerationEnabled, count _decelerationAircraft, count _decelerationActive, count _decelerationLandingConflict, missionNamespace getVariable ["Waldo_HelicopterDeceleration_IncludeVTOL", false]]]
];
["ai", _checks] call Waldo_fnc_DiagnosticFeatureReport
