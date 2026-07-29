/*
 * Server-side pack diagnostics. Reports dependency and subsystem state as
 * LOADED, ACTIVE, DISABLED, UNCONFIGURED, UNAVAILABLE or ERROR. The structured
 * report is broadcast in Waldo_Diagnostics_LastReport for audit tools/JIP.
 * Existing callers still receive the number of warnings.
 *
 * Arguments: None
 * Return Value: Number <NUMBER> - count of warnings raised
 * Example: [] spawn Waldo_fnc_RunDiagnostics;
 */
if (!isServer) exitWith {0};
if (!canSuspend) exitWith {_this spawn Waldo_fnc_RunDiagnostics; 0};
if (missionNamespace getVariable ["Waldo_Diagnostics_Running", false]) exitWith {
    ["core", "diagnostics", "WARN", "REJECT", "reason=run-already-active", missionNamespace getVariable ["Waldo_Diagnostics_ActiveRun", "NONE"], "SERVER"] call Waldo_fnc_DiagnosticLog;
    -1
};
missionNamespace setVariable ["Waldo_Diagnostics_Running", true];

private _warnings = 0;
private _report = [];
private _runId = format ["%1-%2", floor serverTime, floor (random 1000000)];
missionNamespace setVariable ["Waldo_Diagnostics_ActiveRun", _runId, true];
missionNamespace setVariable ["Waldo_Diagnostics_ClientReports", []];
private _log = {
    params ["_level", "_area", "_feature", "_event", "_message"];
    [_area, _feature, _level, _event, _message, _runId, "SERVER"] call Waldo_fnc_DiagnosticLog;
    if (_level in ["WARN", "ERROR"] && {hasInterface}) then {
        systemChat format ["[WMP DIAG] %1", _message];
    };
};
private _section = {
    params ["_area", "_title"];
    ["INFO", _area, "section", "SECTION", _title] call _log;
};
private _status = {
    params ["_category", "_name", "_state", ["_detail", ""], ["_warn", false]];
    _report pushBack [_category, _name, _state, _detail];
    [if (_warn) then {"ERROR"} else {"INFO"}, _category, _name, "CHECK", format ["state=%1 detail=%2", _state, _detail]] call _log;
    if (_warn) then {_warnings = _warnings + 1;};
};
private _consumeFeatureReport = {
    params ["_featureReport"];
    {
        _x params ["_area", "_feature", "_state", ["_detail", ""]];
        [_area, _feature, _state, _detail, _state == "ERROR"] call _status;
    } forEach (_featureReport getOrDefault ["checks", []]);
};

["INFO", "core", "diagnostics", "BEGIN", format ["mission=%1 world=%2 multiplayer=%3 dedicated=%4 players=%5", missionName, worldName, isMultiplayer, isDedicated, count allPlayers]] call _log;

// Representative public APIs catch incomplete or stale mission-pack copies before runtime
// state is interpreted. These checks do not activate any feature.
["code", "Public API availability"] call _section;
{
    _x params ["_area", "_feature", "_function"];
    private _available = !(isNil _function);
    [_area, _feature, if (_available) then {"LOADED"} else {"ERROR"}, format ["function=%1", _function], !_available] call _status;
} forEach [
    ["mission-flow", "safestart-api", "Waldo_fnc_SafeStart"],
    ["mission-flow", "aar-endex-api", "Waldo_fnc_ENDEX"],
    ["mission-flow", "objectives-api", "Waldo_fnc_CreateObjective"],
    ["world-ui", "custom-3d-marker-api", "Waldo_fnc_Create3DMarker"],
    ["logistics", "mhq-api", "Waldo_fnc_MHQSetup"],
    ["logistics", "vvd-api", "Waldo_fnc_VVDInit"],
    ["electronic-warfare", "jammer-api", "Waldo_fnc_Jammer"],
    ["electronic-warfare", "emp-api", "Waldo_fnc_EMP"],
    ["electronic-warfare", "tracker-api", "Waldo_fnc_Tracker"],
    ["party-games", "party-table-api", "Waldo_fnc_MiniGamesInit"],
    ["interactions", "equipment-api", "Waldo_fnc_MiniGameInteractionSetup"],
    ["economy", "economy-api", "Waldo_fnc_EcoInit"],
    ["mission-flow", "safestart-diagnostics-api", "Waldo_fnc_SafeStartGetDiagnostics"],
    ["mission-flow", "endex-diagnostics-api", "Waldo_fnc_ENDEXGetDiagnostics"],
    ["interactions", "equipment-diagnostics-api", "Waldo_fnc_MiniGameInteractionGetDiagnostics"],
    ["economy", "economy-diagnostics-api", "Waldo_fnc_EcoCore_getDiagnostics"]
];

// Required and optional dependencies are deliberately distinct. Optional
// absence is not a warning unless an enabled subsystem requires that mod.
["dependencies", "Loaded mod patches"] call _section;
{
    _x params ["_patch", "_label", "_required"];
    private _loaded = isClass (configFile >> "CfgPatches" >> _patch);
    ["dependency", _label, if (_loaded) then {"LOADED"} else {if (_required) then {"ERROR"} else {"UNAVAILABLE"}}, format ["CfgPatches >> %1", _patch], _required && {!_loaded}] call _status;
} forEach [
    ["cba_main", "CBA_A3", true],
    ["ace_main", "ACE3", true],
    ["zen_main", "ZEN", false],
    ["acre_main", "ACRE2", false],
    ["task_force_radio", "TFAR", false]
];

// Loadout scan: do not wait forever when the subsystem was not loaded.
["logistics", "Loadouts and configured logistics classes"] call _section;
private _scanDeadline = diag_tickTime + 10;
waitUntil {
    uiSleep 0.1;
    missionNamespace getVariable ["Logi_MissionScanComplete", false] || {diag_tickTime >= _scanDeadline}
};
private _scanComplete = missionNamespace getVariable ["Logi_MissionScanComplete", false];
["logistics", "mission-loadout-scan", if (_scanComplete) then {"LOADED"} else {"UNAVAILABLE"}, if (_scanComplete) then {"Mission loadout arrays published"} else {"Loadout scan did not complete within 10 seconds"}, !_scanComplete] call _status;

private _flattenReal = {
    params ["_array"];
    private _flat = [];
    {if (_x isEqualType []) then {_flat append _x} else {_flat pushBack _x};} forEach _array;
    _flat select {_x isEqualType "" && {_x != "" && {_x != "EMPTY"}}}
};
{
    _x params ["_side", "_suffix", "_label"];
    private _slotCount = {side group _x == _side} count playableUnits;
    private _items = [missionNamespace getVariable [format ["Logi_MissionSQMArray_%1", _suffix], []]] call _flattenReal;
    private _count = count _items;
    if (_slotCount == 0) then {
        ["logistics", format ["%1-loadout", _label], "UNCONFIGURED", "No playable slots use this side", false] call _status;
    } else {
        ["logistics", format ["%1-loadout", _label], if (_count > 0) then {"LOADED"} else {"ERROR"}, format ["%1 playable slot(s), %2 unique scraped item(s)", _slotCount, _count], _count == 0] call _status;
    };
} forEach [[west, "West", "BLUFOR"], [east, "East", "OPFOR"], [independent, "Ind", "INDEP"], [civilian, "Civ", "CIV"]];
if ((count playableUnits) == 0) then {
    ["logistics", "playable-slots", "ERROR", "No playable units; logistics crates cannot derive mission equipment", true] call _status;
};

// Configured classes. Blank values are unconfigured; bad non-blank values are errors.
["configuration", "Mission-maker class and threshold settings"] call _section;
{
    _x params ["_variable", "_label"];
    private _class = missionNamespace getVariable [_variable, ""];
    if (_class == "") then {
        ["configuration", _label, "UNCONFIGURED", _variable, false] call _status;
    } else {
        private _valid = isClass (configFile >> "CfgVehicles" >> _class);
        ["configuration", _label, if (_valid) then {"LOADED"} else {"ERROR"}, format ["%1 = %2", _variable, _class], !_valid] call _status;
    };
} forEach [
    ["Logi_SupplyBoxClass", "supply-box"],
    ["Logi_MedicalBoxClass", "medical-box"],
    ["WALDO_STATIC_STATICCHUTE", "static-line-parachute"],
    ["WALDO_PARA_HALOCHUTE", "halo-parachute"]
];

private _minAltitude = missionNamespace getVariable ["WALDO_STATIC_MINALTITUDE", 180];
private _maxAltitude = missionNamespace getVariable ["WALDO_STATIC_MAXALTITUDE", 350];
private _maxSpeed = missionNamespace getVariable ["WALDO_STATIC_MAXSPEED", 310];
private _thresholdsValid = _minAltitude < _maxAltitude && {_maxSpeed > 0};
["configuration", "static-line-thresholds", if (_thresholdsValid) then {"LOADED"} else {"ERROR"}, format ["min=%1 max=%2 maxSpeed=%3", _minAltitude, _maxAltitude, _maxSpeed], !_thresholdsValid] call _status;

private _acreLoaded = isClass (configFile >> "CfgPatches" >> "acre_main");
["radio", "Radio configuration"] call _section;
if (_acreLoaded) then {
    {
        _x params ["_variable", "_label"];
        private _channels = missionNamespace getVariable [_variable, []];
        ["radio", format ["%1-lr-channels", _label], if (_channels isEqualTo []) then {"UNCONFIGURED"} else {"LOADED"}, format ["%1 channel assignment(s)", count _channels], false] call _status;
    } forEach [["Waldo_ACRE2Setup_LRChannels_BLUFOR", "BLUFOR"], ["Waldo_ACRE2Setup_LRChannels_OPFOR", "OPFOR"], ["Waldo_ACRE2Setup_LRChannels_IND", "INDEP"], ["Waldo_ACRE2Setup_LRChannels_CIV", "CIV"]];
};

["systems", "Feature runtime state"] call _section;
[call Waldo_fnc_EcoCore_getDiagnostics] call _consumeFeatureReport;
[call Waldo_fnc_SafeStartGetDiagnostics] call _consumeFeatureReport;
[call Waldo_fnc_ENDEXGetDiagnostics] call _consumeFeatureReport;
[call Waldo_fnc_MiniGameInteractionGetDiagnostics] call _consumeFeatureReport;

private _partyEnabled = missionNamespace getVariable ["Waldo_MiniGames_Enable", false];
private _partyLoaded = missionNamespace getVariable ["Waldo_MG_SystemInitialized", false];
["system", "party-games", if (_partyLoaded) then {"ACTIVE"} else {if (_partyEnabled) then {"ERROR"} else {"DISABLED"}}, format ["configured=%1 catalogue=%2", _partyEnabled, count (missionNamespace getVariable ["Waldo_MG_Games", []])], _partyEnabled && {!_partyLoaded}] call _status;

private _jammingEnabled = missionNamespace getVariable ["Waldo_Jamming_Enable", false];
private _tfarLoaded = isClass (configFile >> "CfgPatches" >> "task_force_radio") || {isClass (configFile >> "CfgPatches" >> "tfar_core")};
private _jammingUsable = _acreLoaded || {_tfarLoaded};
private _jammerCount = count (missionNamespace getVariable ["Waldo_Jamming_Registry", []]);
private _jammingState = if (!_jammingEnabled) then {"DISABLED"} else {
    if (!_jammingUsable) then {"ERROR"} else {if (_jammerCount > 0) then {"ACTIVE"} else {"LOADED"}}
};
["system", "radio-jamming", _jammingState, format ["ACRE2=%1 TFAR=%2 registeredJammers=%3", _acreLoaded, _tfarLoaded, _jammerCount], _jammingEnabled && {!_jammingUsable}] call _status;

private _markerCount = count (missionNamespace getVariable ["Waldo_3DMarker_Registry", []]);
["system", "custom-3d-markers", if (_markerCount > 0) then {"ACTIVE"} else {"LOADED"}, format ["%1 registered marker(s); client renderer state is reported by client audit", _markerCount], false] call _status;

// One-time object inspection distinguishes an available API from equipment configured in the
// current mission. It runs only when diagnostics are explicitly invoked.
["logistics", "Configured mission equipment"] call _section;
private _missionObjects = allMissionObjects "All";
private _mhqObjects = _missionObjects select {_x getVariable ["Waldo_MHQ_ServerConfigured", false]};
private _deployedMhqs = {_x getVariable ["Waldo_MHQ_Status", false]} count _mhqObjects;
["logistics", "mhq-runtime", if (_mhqObjects isEqualTo []) then {"UNCONFIGURED"} else {if (_deployedMhqs > 0) then {"ACTIVE"} else {"LOADED"}}, format ["configured=%1 deployed=%2", count _mhqObjects, _deployedMhqs], false] call _status;
private _vvdPads = _missionObjects select {_x getVariable ["Waldo_VVD_ServerConfigured", false]};
["logistics", "vvd-runtime", if (_vvdPads isEqualTo []) then {"UNCONFIGURED"} else {"LOADED"}, format ["configuredSpawnPads=%1", count _vvdPads], false] call _status;
private _recoveryWorkshops = _missionObjects select {_x getVariable ["Waldo_Recovery_Workshop", false]};
private _recoveryVehicles = _missionObjects select {_x getVariable ["Waldo_Recovery_Registered", false]};
private _recoveryPackages = (missionNamespace getVariable ["Waldo_Recovery_Packages", []]) select {!isNull _x};
private _recoveryConfigured = !(_recoveryWorkshops isEqualTo []) || {!(_recoveryVehicles isEqualTo [])};
private _recoveryBroken = !(_recoveryPackages isEqualTo []) && {_recoveryWorkshops isEqualTo []};
["logistics", "vehicle-recovery", if (!_recoveryConfigured) then {"UNCONFIGURED"} else {if (_recoveryBroken) then {"ERROR"} else {if (_recoveryPackages isEqualTo []) then {"LOADED"} else {"ACTIVE"}}}, format ["workshops=%1 vehicles=%2 packages=%3 monitor=%4", count _recoveryWorkshops, count _recoveryVehicles, count _recoveryPackages, missionNamespace getVariable ["Waldo_Recovery_MonitorRunning", false]], _recoveryBroken] call _status;

private _zenLoaded = isClass (configFile >> "CfgPatches" >> "zen_main");
["integration", "ACE and Zeus integration"] call _section;
private _zenApi = !(isNil "zen_custom_modules_fnc_register");
["integration", "zen-modules", if (!_zenLoaded) then {"UNAVAILABLE"} else {if (_zenApi) then {"LOADED"} else {"ERROR"}}, format ["ZEN loaded=%1 registration API=%2", _zenLoaded, _zenApi], _zenLoaded && {!_zenApi}] call _status;
["integration", "ace-actions", if (isClass (configFile >> "CfgPatches" >> "ace_main")) then {"LOADED"} else {"ERROR"}, "Dependency state only; object action installation is checked by the client audit", !(isClass (configFile >> "CfgPatches" >> "ace_main"))] call _status;

["optional-features", "Optional feature configuration"] call _section;
private _persistenceEnabled = missionNamespace getVariable ["Waldo_Persistence_Enable", false];
private _persistencePatches = missionNamespace getVariable ["Waldo_Persistence_PatchNames", ["inidbi2", "inidbi2_main", "inidbi2_core", "inidbi"]];
private _persistenceRuntime = [] call Waldo_fnc_PersistenceDependencyAvailable;
["optional-feature", "persistence-runtime", if (!_persistenceEnabled) then {"DISABLED"} else {if (_persistenceRuntime) then {"LOADED"} else {"ERROR"}}, format ["enabled=%1 runtimeDetected=%2", _persistenceEnabled, _persistenceRuntime], _persistenceEnabled && {!_persistenceRuntime}] call _status;

private _breachingEnabled = missionNamespace getVariable ["Waldo_Breaching_Enable", false];
private _breachingDependency = isClass (configFile >> "CfgPatches" >> "ace_explosives");
private _breachingProfileCount = count (keys (missionNamespace getVariable ["Waldo_Breaching_Profiles", createHashMap]));
private _breachingValid = _breachingDependency && {_breachingProfileCount > 0};
["optional-feature", "explosive-breaching", if (!_breachingEnabled) then {"DISABLED"} else {if (_breachingValid) then {"LOADED"} else {"ERROR"}}, format ["enabled=%1 aceExplosives=%2 profiles=%3", _breachingEnabled, _breachingDependency, _breachingProfileCount], _breachingEnabled && {!_breachingValid}] call _status;

private _treatmentEnabled = missionNamespace getVariable ["Waldo_TreatmentFeedback_Enable", false];
private _treatmentDependency = isClass (configFile >> "CfgPatches" >> "ace_medical");
["optional-feature", "treatment-feedback", if (!_treatmentEnabled) then {"DISABLED"} else {if (_treatmentDependency) then {"LOADED"} else {"ERROR"}}, format ["enabled=%1 aceMedical=%2", _treatmentEnabled, _treatmentDependency], _treatmentEnabled && {!_treatmentDependency}] call _status;

private _resupplyEnabled = missionNamespace getVariable ["Waldo_FieldResupply_Enable", false];
private _resupplyClass = missionNamespace getVariable ["Waldo_FieldResupply_CrateClass", "Box_NATO_Ammo_F"];
private _resupplyValid = isClass (configFile >> "CfgVehicles" >> _resupplyClass);
["optional-feature", "field-resupply", if (!_resupplyEnabled) then {"DISABLED"} else {if (_resupplyValid) then {"LOADED"} else {"ERROR"}}, format ["enabled=%1 crateClass=%2", _resupplyEnabled, _resupplyClass], _resupplyEnabled && {!_resupplyValid}] call _status;

private _rallyEnabled = missionNamespace getVariable ["Waldo_Rally_Enable", false];
private _rallyClass = missionNamespace getVariable ["Waldo_Rally_ObjectClass", "Land_SatelliteAntenna_01_F"];
private _rallyClassValid = isClass (configFile >> "CfgVehicles" >> _rallyClass);
private _activeRallies = {_x getVariable ["Waldo_Rally_Active", false]} count allGroups;
["optional-feature", "squad-rally-points", if (!_rallyEnabled) then {"DISABLED"} else {if (!_rallyClassValid) then {"ERROR"} else {if (_activeRallies > 0) then {"ACTIVE"} else {"LOADED"}}}, format ["enabled=%1 objectClass=%2 activeGroups=%3", _rallyEnabled, _rallyClass, _activeRallies], _rallyEnabled && {!_rallyClassValid}] call _status;

private _gunshipEnabled = missionNamespace getVariable ["Waldo_Gunship_Enable", false];
private _gunshipAltitude = missionNamespace getVariable ["Waldo_Gunship_DefaultAltitude", 700];
private _gunshipRadius = missionNamespace getVariable ["Waldo_Gunship_DefaultRadius", 1500];
private _gunshipBoundsValid = _gunshipAltitude >= 100 && {_gunshipAltitude <= (missionNamespace getVariable ["Waldo_Gunship_MaximumAltitude", 5000])} && {_gunshipRadius >= 200} && {_gunshipRadius <= (missionNamespace getVariable ["Waldo_Gunship_MaximumRadius", 10000])};
private _invalidGunshipClasses = [];
private _gunshipPools = missionNamespace getVariable ["Waldo_Gunship_SideAircraftPools", createHashMap];
{{if !(isClass (configFile >> "CfgVehicles" >> _x) && {_x isKindOf "Air"}) then {_invalidGunshipClasses pushBackUnique _x;};} forEach (_gunshipPools get _x);} forEach keys _gunshipPools;
private _gunshipValid = _gunshipBoundsValid && {_invalidGunshipClasses isEqualTo []};
["optional-feature", "airborne-gunship", if (!_gunshipEnabled) then {"DISABLED"} else {if (_gunshipValid) then {"LOADED"} else {"ERROR"}}, format ["enabled=%1 altitude=%2 radius=%3 invalidClasses=%4", _gunshipEnabled, _gunshipAltitude, _gunshipRadius, _invalidGunshipClasses], _gunshipEnabled && {!_gunshipValid}] call _status;

{
    private _aaPool = [createHashMap, _x] call Waldo_fnc_DynamicAAResolveAssetPool;
    private _emptyCategories = ["radarClasses", "staticSitePools", "mobileClasses", "fighterClasses"] select {count (_aaPool getOrDefault [_x, []]) == 0};
    ["optional-feature", format ["dynamic-aa-%1", _x], if (_emptyCategories isEqualTo []) then {"LOADED"} else {"ERROR"}, format ["source=%1 emptyCategories=%2", _aaPool getOrDefault ["source", str _x], _emptyCategories], !(_emptyCategories isEqualTo [])] call _status;
} forEach [west, east, independent];

private _invalidTreeClasses = (missionNamespace getVariable ["Waldo_TreeFelling_FallenClasses", []]) select {!(isClass (configFile >> "CfgVehicles" >> _x))};
["optional-feature", "tree-felling-replacements", if (_invalidTreeClasses isEqualTo []) then {"LOADED"} else {"ERROR"}, format ["invalidClasses=%1", _invalidTreeClasses], !(_invalidTreeClasses isEqualTo [])] call _status;

// Ask every interface client for local UI, mod and action state. The server retains authority over
// the final report and accepts a response only from its claimed network owner.
["clients", "Per-client runtime state"] call _section;
private _expectedOwners = [];
{_expectedOwners pushBackUnique (owner _x);} forEach allPlayers;
[_runId] remoteExecCall ["Waldo_fnc_RunDiagnosticsClient", 0];
private _clientDeadline = diag_tickTime + 4;
waitUntil {
    uiSleep 0.1;
    private _receivedOwners = (missionNamespace getVariable ["Waldo_Diagnostics_ClientReports", []]) apply {_x select 0};
    ({!(_x in _receivedOwners)} count _expectedOwners) == 0 || {diag_tickTime >= _clientDeadline}
};
private _clientReports = missionNamespace getVariable ["Waldo_Diagnostics_ClientReports", []];
private _receivedOwners = _clientReports apply {_x select 0};
private _missingOwners = _expectedOwners select {!(_x in _receivedOwners)};
if !(_missingOwners isEqualTo []) then {
    _warnings = _warnings + count _missingOwners;
    ["WARN", "clients", "response", "TIMEOUT", format ["No diagnostic response from network owner(s): %1", _missingOwners]] call _log;
};
{
    _x params ["_ownerId", "_playerName", "_uid", "_checks"];
    private _clientErrors = {_x select 2 == "ERROR"} count _checks;
    _warnings = _warnings + _clientErrors;
    [if (_clientErrors > 0) then {"WARN"} else {"INFO"}, "clients", "report", "SUMMARY", format ["owner=%1 player=%2 checks=%3 errors=%4", _ownerId, _playerName, count _checks, _clientErrors]] call _log;
} forEach _clientReports;

missionNamespace setVariable ["Waldo_Diagnostics_LastReport", [_warnings, serverTime, _report, _clientReports, _runId], true];
private _summary = if (_warnings == 0) then {
    format ["Diagnostics complete: %1 checks, no warnings. Disabled/unconfigured optional systems are listed separately.", count _report]
} else {
    format ["Diagnostics complete: %1 checks, %2 warning(s). See [WMP DIAG] RPT entries.", count _report, _warnings]
};
[if (_warnings > 0) then {"WARN"} else {"INFO"}, "core", "diagnostics", "SUMMARY", _summary] call _log;
["INFO", "core", "diagnostics", "END", format ["serverChecks=%1 clientReports=%2 warnings=%3", count _report, count _clientReports, _warnings]] call _log;
if (hasInterface) then {systemChat format ["[WMP DIAG] %1", _summary];};
missionNamespace setVariable ["Waldo_Diagnostics_Running", false];
_warnings
