/*
 * Author: WaldoTheWarfighter
 * Server-side pack diagnostics. Reports dependency and subsystem state as
 * LOADED, ACTIVE, DISABLED, UNCONFIGURED, UNAVAILABLE or ERROR. The structured
 * report is broadcast in Waldo_Diagnostics_LastReport for audit tools/JIP.
 * Existing callers still receive the number of warnings.
 * Locality and authority: Server-only and scheduled. Unschedulable calls spawn one server run;
 * concurrent runs are rejected. Clients supply bounded local reports, but the server owns output.
 *
 * Arguments: None
 * Return Value: Number <NUMBER> - count of warnings raised
 * Example: [] spawn Waldo_fnc_RunDiagnostics;
 * Result: Publishes one structured diagnostic report and returns its warning count.
 * Current callers: initServer.sqf startup diagnostics, ZEN diagnostics and audit tooling.
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
// Broadcasts an in-game chat line to whichever machines can actually show one: locally when the
// calling machine has an interface (a listen-server host sees it directly), and to every currently
// assigned curator's client (allCurators/getAssignedCuratorUnit) otherwise - a genuine dedicated
// server has no console of its own to show systemChat on, so without this an admin running one had
// no in-game visibility into diagnostics at all short of tailing RPT by hand. Mirrors the legacy
// WerthlesHeadless.sqf's own approach of remote-executing its debug hint onto a specific connected
// player rather than only ever running a local-only call gated on the executing machine's interface.
private _notifyAdmins = {
    params ["_text"];
    if (hasInterface) then {systemChat _text;};
    private _curatorUnits = (allCurators apply {getAssignedCuratorUnit _x}) select {!isNull _x};
    if (count _curatorUnits > 0) then {[_text] remoteExec ["systemChat", _curatorUnits];};
};
private _log = {
    params ["_level", "_area", "_feature", "_event", "_message"];
    [_area, _feature, _level, _event, _message, _runId, "SERVER"] call Waldo_fnc_DiagnosticLog;
    if (_level in ["WARN", "ERROR"]) then {
        [format ["[WMP DIAG] %1", _message]] call _notifyAdmins;
    };
};
private _section = {
    params ["_area", "_title"];
    ["INFO", _area, "section", "SECTION", _title] call _log;
};
// _hint is an optional, plain-language remediation step (what to actually go and change) attached
// to a failing or unconfigured-but-likely-wanted check. It is folded into the same detail text
// (so the [area,feature,state,detail] report shape every consumer already reads stays unchanged)
// rather than adding a new field, and it is what actually reaches the hosted-server systemChat line
// a mission maker sees in the moment - the terse state=/detail= pair alone tells you *that*
// something is wrong, a hint tells you *what to do about it*.
private _status = {
    params ["_category", "_name", "_state", ["_detail", ""], ["_warn", false], ["_hint", ""]];
    private _fullDetail = [_detail, _hint] call Waldo_fnc_DiagnosticFoldHint;
    _report pushBack [_category, _name, _state, _fullDetail];
    [if (_warn) then {"ERROR"} else {"INFO"}, _category, _name, "CHECK", format ["state=%1 detail=%2", _state, _fullDetail]] call _log;
    if (_warn) then {_warnings = _warnings + 1;};
};
private _consumeFeatureReport = {
    params ["_featureReport"];
    if !(_featureReport isEqualType createHashMap) exitWith {
        ["diagnostics", "feature-report", "ERROR", format ["A diagnostics provider returned %1 instead of a HashMap report", typeName _featureReport], true, "The mission may contain an incomplete or stale MissionScripts copy. Re-extract the current pack before testing again."] call _status;
    };
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
    [_area, _feature, if (_available) then {"LOADED"} else {"ERROR"}, format ["function=%1", _function], !_available, if (_available) then {""} else {format ["%1 is missing from this mission's copy of WMP - re-extract WaldosMissionPack\MissionScripts over this mission (or confirm WaldosFunctions.sqf wasn't edited) so it registers again.", _function]}] call _status;
} forEach [
    ["mission-flow", "safestart-api", "Waldo_fnc_SafeStart"],
    ["mission-flow", "aar-endex-api", "Waldo_fnc_ENDEX"],
    ["mission-flow", "objectives-api", "Waldo_fnc_CreateObjective"],
    ["world-ui", "custom-3d-marker-api", "Waldo_fnc_Create3DMarker"],
    ["interface", "ui-theme-api", "Waldo_fnc_UiTheme"],
    ["interface", "accessibility-api", "Waldo_fnc_AccessibilitySelfInteractionInit"],
    ["logistics", "mhq-api", "Waldo_fnc_MHQSetup"],
    ["logistics", "vvd-api", "Waldo_fnc_VVDInit"],
    ["object-transforms", "object-scaling-api", "Waldo_fnc_ObjectScale"],
    ["runtime-control", "feature-runtime-api", "Waldo_fnc_FeatureRuntimeApply"],
    ["electronic-warfare", "jammer-api", "Waldo_fnc_Jammer"],
    ["electronic-warfare", "emp-api", "Waldo_fnc_EMP"],
    ["electronic-warfare", "tracker-api", "Waldo_fnc_Tracker"],
    ["party-games", "party-table-api", "Waldo_fnc_MiniGamesInit"],
    ["interactions", "equipment-api", "Waldo_fnc_MiniGameInteractionSetup"],
    ["economy", "economy-api", "Waldo_fnc_EcoInit"],
    ["medical", "obituary-api", "Waldo_fnc_ObituaryPronounce"],
    ["mission-flow", "safestart-diagnostics-api", "Waldo_fnc_SafeStartGetDiagnostics"],
    ["mission-flow", "endex-diagnostics-api", "Waldo_fnc_ENDEXGetDiagnostics"],
    ["interactions", "equipment-diagnostics-api", "Waldo_fnc_MiniGameInteractionGetDiagnostics"],
    ["economy", "economy-diagnostics-api", "Waldo_fnc_EcoCore_getDiagnostics"],
    ["headless", "headless-diagnostics-api", "Waldo_fnc_HeadlessGetDiagnostics"],
    ["ai", "ai-diagnostics-api", "Waldo_fnc_AIGetDiagnostics"],
    ["medical", "obituary-diagnostics-api", "Waldo_fnc_ObituaryGetDiagnostics"]
];

// Required and optional dependencies are deliberately distinct. Optional
// absence is not a warning unless an enabled subsystem requires that mod.
["dependencies", "Loaded mod patches"] call _section;
{
    _x params ["_patch", "_label", "_required"];
    private _loaded = isClass (configFile >> "CfgPatches" >> _patch);
    ["dependency", _label, if (_loaded) then {"LOADED"} else {if (_required) then {"ERROR"} else {"UNAVAILABLE"}}, format ["CfgPatches >> %1", _patch], _required && {!_loaded}, if (_loaded || {!_required}) then {""} else {format ["%1 is required by WMP but is not loaded - add it to this mission's mod list and launch parameters.", _label]}] call _status;
} forEach [
    ["cba_main", "CBA_A3", true],
    ["ace_main", "ACE3", true],
    ["zen_main", "ZEN", false],
    ["acre_main", "ACRE2", false],
    ["task_force_radio", "TFAR", false]
];

// The ordered runtime-feature snapshot (Waldo_fnc_FeatureRuntimeRequestState/ReceiveState) is the
// handshake JIP and headless clients use before activating locality-sensitive optional features
// (Obituary, Emergency Dismount, Treatment Feedback, Rally Points, Tree Felling, Persistence, ...)
// against the server's actual current settings instead of local defaults. If initServer.sqf never
// published readiness, every one of those client-side installers is stuck waiting indefinitely.
private _runtimeControlReady = missionNamespace getVariable ["Waldo_FeatureRuntimeStateReady", false];
["runtime-control", "runtime-control-authority", if (_runtimeControlReady) then {"ACTIVE"} else {"ERROR"}, format ["ready=%1", _runtimeControlReady], !_runtimeControlReady, if (_runtimeControlReady) then {""} else {"initServer.sqf did not publish Waldo_FeatureRuntimeStateReady - JIP and headless clients cannot request the authoritative runtime snapshot, so locality-sensitive optional features gated on it will never activate for them."}] call _status;

// Loadout scan: do not wait forever when the subsystem was not loaded.
["logistics", "Loadouts and configured logistics classes"] call _section;
private _scanDeadline = diag_tickTime + 10;
waitUntil {
    uiSleep 0.1;
    missionNamespace getVariable ["Logi_MissionScanComplete", false] || {diag_tickTime >= _scanDeadline}
};
private _scanComplete = missionNamespace getVariable ["Logi_MissionScanComplete", false];
["logistics", "mission-loadout-scan", if (_scanComplete) then {"LOADED"} else {"UNAVAILABLE"}, if (_scanComplete) then {"Mission loadout arrays published"} else {"Loadout scan did not complete within 10 seconds"}, !_scanComplete, if (_scanComplete) then {""} else {"Waldo_fnc_SideBaseLoadoutSetup did not finish - check the RPT for errors, and confirm mission.sqm is not binarized (Eden Editor > mission Properties > uncheck Binarize)."}] call _status;

private _flattenReal = {
    params ["_array"];
    private _flat = [];
    {if (_x isEqualType []) then {_flat append _x} else {_flat pushBack _x};} forEach _array;
    _flat select {_x isEqualType "" && {_x != "" && {_x != "EMPTY"}}}
};
private _configuredLoadoutSides = 0;
private _countConfiguredSlots = {
    params ["_entity", "_sideName"];
    private _count = 0;
    if (getText (_entity >> "dataType") == "Object") then {
        private _attributes = _entity >> "Attributes";
        if (getText (_entity >> "side") == _sideName && {(getNumber (_attributes >> "isPlayer")) == 1 || {(getNumber (_attributes >> "isPlayable")) == 1}}) then {
            _count = 1;
        };
    };
    private _children = _entity >> "Entities";
    {_count = _count + ([_x, _sideName] call _countConfiguredSlots)} forEach (configProperties [_children, "isClass _x", true]);
    _count
};
private _loadoutRoot = missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities";
{
    _x params ["_sideName", "_suffix", "_label"];
    private _slotCount = 0;
    {_slotCount = _slotCount + ([_x, _sideName] call _countConfiguredSlots)} forEach (configProperties [_loadoutRoot, "isClass _x", true]);
    private _items = [missionNamespace getVariable [format ["Logi_MissionSQMArray_%1", _suffix], []]] call _flattenReal;
    private _count = count _items;
    if (_slotCount == 0 && {_count == 0}) then {
        ["logistics", format ["%1-loadout", _label], "UNCONFIGURED", "No authored mission-config playable slots use this side", false] call _status;
    } else {
        if (_count > 0) then {_configuredLoadoutSides = _configuredLoadoutSides + 1};
        ["logistics", format ["%1-loadout", _label], if (_count > 0) then {"LOADED"} else {"ERROR"}, format ["%1 authored playable slot(s), %2 unique mission-scraped item(s)", _slotCount, _count], _count == 0, if (_count > 0) then {""} else {format ["%1 has playable units placed but no scanned loadout items - open each of this side's playable units in ACE Arsenal at least once and save; a vanilla default loadout produces empty crates.", _label]}] call _status;
    };
} forEach [["West", "West", "BLUFOR"], ["East", "East", "OPFOR"], ["Independent", "Ind", "INDEP"], ["Civilian", "Civ", "CIV"]];
if (_configuredLoadoutSides == 0) then {
    ["logistics", "playable-slots", "ERROR", "No authored playable inventories were found in mission configuration; logistics crates cannot derive mission equipment", true, "Place at least one playable unit per side you want logistics support for, and configure its loadout in ACE Arsenal (not vanilla defaults)."] call _status;
};

// Configured classes. Blank values are unconfigured; bad non-blank values are errors.
["configuration", "Mission-maker class and threshold settings"] call _section;
{
    _x params ["_variable", "_label", ["_hint", ""]];
    private _class = missionNamespace getVariable [_variable, ""];
    if (_class == "") then {
        ["configuration", _label, "UNCONFIGURED", _variable, false] call _status;
    } else {
        private _valid = isClass (configFile >> "CfgVehicles" >> _class);
        // A known real gotcha: this exact class only exists when RHS is loaded, and the check
        // above already fails it as ERROR on a non-RHS mission - surface the actual fix, not just
        // "class not found". No longer the shipped default (WALDO_STATIC_STATICCHUTE now defaults
        // to vanilla), but the wiki still shows this as the example RHS override, so it remains a
        // realistic mission-maker mistake.
        private _resolvedHint = if (!_valid && {_class == "rhs_d6_Parachute"}) then {
            format ["%1 defaults to the RHS class rhs_d6_Parachute; either load RHS or set %2 to the vanilla NonSteerable_Parachute_F.", _variable, _variable]
        } else {_hint};
        ["configuration", _label, if (_valid) then {"LOADED"} else {"ERROR"}, format ["%1 = %2", _variable, _class], !_valid, _resolvedHint] call _status;
    };
} forEach [
    ["Logi_SupplyBoxClass", "supply-box", "Set Logi_SupplyBoxClass in initServer.sqf to a real CfgVehicles crate class, e.g. ""B_supplyCrate_F""."],
    ["Logi_MedicalBoxClass", "medical-box", "Set Logi_MedicalBoxClass in initServer.sqf to a real CfgVehicles crate class, e.g. ""ACE_medicalSupplyCrate_advanced""."],
    ["WALDO_STATIC_STATICCHUTE", "static-line-parachute", "Set WALDO_STATIC_STATICCHUTE in MissionConfig\airOperationsConfig.sqf to a real parachute class, e.g. the vanilla ""NonSteerable_Parachute_F""."],
    ["WALDO_PARA_HALOCHUTE", "halo-parachute", "Set WALDO_PARA_HALOCHUTE in MissionConfig\airOperationsConfig.sqf to a real parachute class, e.g. the vanilla ""B_Parachute""."]
];

private _minAltitude = missionNamespace getVariable ["WALDO_STATIC_MINALTITUDE", 180];
private _maxAltitude = missionNamespace getVariable ["WALDO_STATIC_MAXALTITUDE", 350];
private _maxSpeed = missionNamespace getVariable ["WALDO_STATIC_MAXSPEED", 310];
private _thresholdsValid = _minAltitude < _maxAltitude && {_maxSpeed > 0};
["configuration", "static-line-thresholds", if (_thresholdsValid) then {"LOADED"} else {"ERROR"}, format ["min=%1 max=%2 maxSpeed=%3", _minAltitude, _maxAltitude, _maxSpeed], !_thresholdsValid, if (_thresholdsValid) then {""} else {"WALDO_STATIC_MINALTITUDE must be lower than WALDO_STATIC_MAXALTITUDE, and WALDO_STATIC_MAXSPEED must be positive - a jump hold-action condition that can never be true is the usual symptom."}] call _status;

// HALO has no equivalent threshold check anywhere else in diagnostics - a nonsensical altitude
// (negative, or below the static-line window, or absurdly high) silently produces a HALO jump
// action that never becomes available, with nothing pointing a mission maker at the actual cause.
private _haloAltitude = missionNamespace getVariable ["WALDO_PARA_HALOALTITUDE", 1000];
private _haloAltitudeValid = _haloAltitude > 0 && {_haloAltitude <= 15000};
["configuration", "halo-altitude-threshold", if (_haloAltitudeValid) then {"LOADED"} else {"ERROR"}, format ["WALDO_PARA_HALOALTITUDE=%1", _haloAltitude], !_haloAltitudeValid, if (_haloAltitudeValid) then {""} else {"Set WALDO_PARA_HALOALTITUDE to a positive, realistic HALO release altitude in metres AGL (1000 is the shipped default)."}] call _status;

private _acreLoaded = isClass (configFile >> "CfgPatches" >> "acre_main");
["radio", "Radio configuration"] call _section;
if (_acreLoaded) then {
    private _acreConfig = missionNamespace getVariable ["Waldo_ACRE2_Config", createHashMap];
    private _acreEnabled = _acreConfig getOrDefault ["enabled", false];
    private _acrePlan = missionNamespace getVariable ["Waldo_ACRE2_Plan", []];
    private _planValid = count _acrePlan >= 4 && {(_acrePlan select 0) == 5};
    private _revision = if (_planValid) then {_acrePlan select 1} else {-1};
    private _sidePlans = if (_planValid) then {_acrePlan select 2} else {[]};
    private _groupCount = 0;
    {_groupCount = _groupCount + count (_x param [3, []]);} forEach _sidePlans;
    ["radio", "acre-config", if (!_acreEnabled) then {"DISABLED"} else {if (count _acreConfig == 0) then {"ERROR"} else {"LOADED"}}, format ["enabled=%1 strict=%2 presetPolicy=%3 namedDisplays=%4", _acreEnabled, _acreConfig getOrDefault ["strict", true], _acreConfig getOrDefault ["prc343PresetPolicy", "MISSING"], _acreConfig getOrDefault ["namedDisplays", false]], _acreEnabled && {count _acreConfig == 0}, if (!_acreEnabled || {count _acreConfig > 0}) then {""} else {"Waldo_ACRE2_Config is empty even though ACRE2 presetting is enabled - confirm MissionConfig\acreConfig.sqf actually defines a config and initServer.sqf calls Waldo_fnc_ACRE2Init."}] call _status;
    ["radio", "acre-authoritative-plan", if (!_acreEnabled) then {"DISABLED"} else {if (_planValid && {_groupCount > 0}) then {"LOADED"} else {"ERROR"}}, format ["schema=%1 revision=%2 sides=%3 groups=%4 diagnostics=%5", if (count _acrePlan > 0) then {_acrePlan select 0} else {-1}, _revision, count _sidePlans, _groupCount, if (_planValid) then {_acrePlan select 3} else {[]}], _acreEnabled && {!_planValid || {_groupCount == 0}}, if (!_acreEnabled || {_planValid && {_groupCount > 0}}) then {""} else {"The server has not published a valid ACRE radio plan, or it has zero groups - check that MissionConfig\acreConfig.sqf's group callsigns match the Eden editor group IDs exactly (an @Callsign leader-role suffix is reconciled first)."}] call _status;
    private _babel = _acreConfig getOrDefault ["babel", createHashMap];
    ["radio", "acre-babel", if !(_babel getOrDefault ["enabled", false]) then {"DISABLED"} else {if (count (_babel getOrDefault ["languages", []]) > 0) then {"LOADED"} else {"ERROR"}}, format ["enabled=%1 languages=%2", _babel getOrDefault ["enabled", false], count (_babel getOrDefault ["languages", []])], (_babel getOrDefault ["enabled", false]) && {count (_babel getOrDefault ["languages", []]) == 0}, if !((_babel getOrDefault ["enabled", false]) && {count (_babel getOrDefault ["languages", []]) == 0}) then {""} else {"Babel is enabled in MissionConfig\acreConfig.sqf but defines no languages - add at least one entry to its babel languages array."}] call _status;

    // Vehicle radio racks appear only after Waldo_fnc_ACRE2RackSetup has been called. The redesigned
    // state field distinguishes a healthy dedicated-server lobby wait from an actual setup failure.
    private _rackVehicles = (allMissionObjects "All") select {(_x getVariable ["Waldo_ACRE2_RackSetupSignature", ""]) != ""};
    if (_rackVehicles isEqualTo []) then {
        ["radio", "acre-vehicle-racks", "UNCONFIGURED", "No vehicle has had Waldo_fnc_ACRE2RackSetup called on it", false] call _status;
    } else {
        private _waiting = _rackVehicles select {(_x getVariable ["Waldo_ACRE2_RackSetupState", "STARTING"]) in ["WAITING_FOR_PLAYER", "WAITING_FOR_ACRE_CLIENT"]};
        private _pending = _rackVehicles select {
            private _rackState = _x getVariable ["Waldo_ACRE2_RackSetupState", "STARTING"];
            _rackState in ["STARTING", "APPLYING"]
        };
        private _problemVehicles = _rackVehicles select {
            private _result = _x getVariable ["Waldo_ACRE2_RackSetupResult", [0, 0, []]];
            private _problems = _result param [2, []];
            !(_problems isEqualTo []) && {
                (_problems findIf {_x == "WAITING_FOR_ACRE_PLAYER" || {_x find "NO_ACRE_READY_CLIENT_WITHIN_" == 0}}) < 0
            }
        };
        private _state = if (count _problemVehicles > 0) then {"ERROR"} else {if (count _pending > 0 || {count _waiting > 0}) then {"LOADED"} else {"ACTIVE"}};
        ["radio", "acre-vehicle-racks", _state, format ["configured=%1 waitingForPlayer=%2 applying=%3 withProblems=%4", count _rackVehicles, count _waiting, count _pending, count _problemVehicles], count _problemVehicles > 0, if (_problemVehicles isEqualTo []) then {""} else {"Check [WMP ACRE RACK] RPT entries for the affected vehicle(s); each failed rack now includes a specific reason."}] call _status;
        {
            private _rackState = _x getVariable ["Waldo_ACRE2_RackSetupState", "STARTING"];
            private _profile = _x getVariable ["Waldo_ACRE2_RackProfile", "INLINE"];
            private _result = _x getVariable ["Waldo_ACRE2_RackSetupResult", [0, 0, []]];
            private _snapshot = _x getVariable ["Waldo_ACRE2_RackDiagnosticSnapshot", []];
            private _problems = _result param [2, []];
            private _onlyWaiting = !(_problems isEqualTo []) && {(_problems findIf {_x == "WAITING_FOR_ACRE_PLAYER" || {_x find "NO_ACRE_READY_CLIENT_WITHIN_" == 0}}) < 0};
            private _isBad = _rackState == "FAILED" || {!(_problems isEqualTo []) && {!_onlyWaiting}};
            ["radio", format ["acre-rack-%1", netId _x], if (_isBad) then {"ERROR"} else {_rackState}, format ["object=%1 class=%2 profile=%3 owner=%4 result=%5 snapshot=%6", _x, typeOf _x, _profile, owner _x, _result, _snapshot], _isBad, if (_isBad) then {"Confirm the profile exists, the selected rack/radio pair is compatible, its named net exists for netSide, and an ACRE-ready player is connected. The snapshot lists the actual racks, each requested job and its read-back channel."} else {""}] call _status;
        } forEach _rackVehicles;
    };
} else {
    ["radio", "acre-runtime", "UNAVAILABLE", "ACRE2 is not loaded; WMP radio presetting is inactive", false] call _status;
};

// Dedicated Paradrop coverage - previously this system had no runtime section of its own at all,
// only the generic class-validity checks above. The single most useful thing diagnostics can add
// here is visibility into the split between Waldo_fnc_AddVehicleFunctions' automatic jump-action
// detection and a mission maker's own explicit setup (Waldo_fnc_ParadropQuickFlightSetup /
// Waldo_fnc_VehicleJumpSetup / Waldo_fnc_ParadropCreateDropZone) - the two used to silently fight
// over the same aircraft; Waldo_Paradrop_ManuallyConfigured is how that's resolved now, and a
// mission maker has no other way to see which of their aircraft ended up in which group.
["paradrop", "Paradrop jump-capable aircraft"] call _section;
private _jumpCapableClasses = ["RHS_Mi24_base", "RHS_Mi8_base", "Heli_Transport_02_base_F", "RHS_C130J_Base", "B_T_VTOL_01_infantry_F"];
private _jumpCapableAircraft = (allMissionObjects "Air") select {
    private _type = typeOf _x;
    _jumpCapableClasses findIf {_type isKindOf _x} >= 0
};
private _manuallyConfigured = _jumpCapableAircraft select {_x getVariable ["Waldo_Paradrop_ManuallyConfigured", false]};
if (_jumpCapableAircraft isEqualTo []) then {
    ["paradrop", "jump-capable-aircraft", "UNCONFIGURED", "No auto-detected jump-capable aircraft (Blackfish/C130J/Mi8/Mi24/Heli_Transport_02) are present in the mission", false] call _status;
} else {
    private _autoDetected = count _jumpCapableAircraft - count _manuallyConfigured;
    private _pending = _manuallyConfigured select {
        _x getVariable ["Waldo_Paradrop_QuickSetupStarted", false]
        && {!(_x getVariable ["Waldo_Paradrop_QuickSetupComplete", false])}
        && {(_x getVariable ["Waldo_Paradrop_QuickSetupFailure", ""]) isEqualTo ""}
    };
    private _failed = _manuallyConfigured select {
        !((_x getVariable ["Waldo_Paradrop_QuickSetupFailure", ""]) isEqualTo "")
    };
    private _configured = _manuallyConfigured select {
        private _types = _x getVariable ["Waldo_Paradrop_ConfiguredJumpTypes", []];
        count _types == 2 && {(_types select 0) || {_types select 1}}
    };
    private _unresolved = _manuallyConfigured select {
        !(_x in _pending) && {!(_x in _failed)} && {!(_x in _configured)}
    };
    private _state = if (!(_failed isEqualTo []) || {!(_unresolved isEqualTo [])}) then {
        "ERROR"
    } else {
        if !(_pending isEqualTo []) then {"LOADED"} else {"ACTIVE"}
    };
    // Hold-action IDs are intentionally client-local. The server reports authoritative setup
    // intent/progress; each interface client's diagnostics verifies the actual local action IDs.
    ["paradrop", "jump-capable-aircraft", _state, format [
        "total=%1 manuallyConfigured=%2 autoDetected=%3 configuredProfiles=%4 pending=%5 failed=%6 unresolved=%7; local action installation is reported by each client",
        count _jumpCapableAircraft, count _manuallyConfigured, _autoDetected, count _configured,
        count _pending, count _failed, count _unresolved
    ], _state == "ERROR", if (_failed isEqualTo [] && {_unresolved isEqualTo []}) then {""} else {
        format ["Failed aircraft=%1 unresolved aircraft=%2. Check [WMP PARADROP] RPT entries.", _failed apply {typeOf _x}, _unresolved apply {typeOf _x}]
    }] call _status;
};

private _dropZoneRegistry = missionNamespace getVariable ["Waldo_Paradrop_DropZones", createHashMap];
private _dropZonePublic = missionNamespace getVariable ["Waldo_Paradrop_PublicDropZones", []];
if (count (keys _dropZoneRegistry) == 0) then {
    ["paradrop", "dynamic-drop-zones", "UNCONFIGURED", "No Waldo_fnc_ParadropCreateDropZone operations are registered", false] call _status;
} else {
    private _zoneConsistent = count (keys _dropZoneRegistry) == count _dropZonePublic;
    ["paradrop", "dynamic-drop-zones", if (_zoneConsistent) then {"ACTIVE"} else {"ERROR"}, format ["registered=%1 publicJip=%2 ids=%3", count (keys _dropZoneRegistry), count _dropZonePublic, keys _dropZoneRegistry], !_zoneConsistent, if (_zoneConsistent) then {""} else {"The server registry and the broadcast JIP list have drifted apart - a JIP client may see a stale or missing drop zone. This usually means a custom script mutated the registry directly instead of going through Waldo_fnc_ParadropCreateDropZone/Waldo_fnc_ParadropRemoveDropZone."}] call _status;
};

["systems", "Feature runtime state"] call _section;
[call Waldo_fnc_EcoCore_getDiagnostics] call _consumeFeatureReport;
[call Waldo_fnc_SafeStartGetDiagnostics] call _consumeFeatureReport;
[call Waldo_fnc_ENDEXGetDiagnostics] call _consumeFeatureReport;
[call Waldo_fnc_MiniGameInteractionGetDiagnostics] call _consumeFeatureReport;
[call Waldo_fnc_HeadlessGetDiagnostics] call _consumeFeatureReport;
if (!isNil "Waldo_fnc_AIGetDiagnostics") then {
    [call Waldo_fnc_AIGetDiagnostics] call _consumeFeatureReport;
};
[call Waldo_fnc_ObituaryGetDiagnostics] call _consumeFeatureReport;

private _partyEnabled = missionNamespace getVariable ["Waldo_MiniGames_Enable", false];
private _partyLoaded = missionNamespace getVariable ["Waldo_MG_SystemInitialized", false];
["system", "party-games", if (_partyLoaded) then {"ACTIVE"} else {if (_partyEnabled) then {"ERROR"} else {"DISABLED"}}, format ["configured=%1 catalogue=%2", _partyEnabled, count (missionNamespace getVariable ["Waldo_MG_Games", []])], _partyEnabled && {!_partyLoaded}, if (!_partyEnabled || {_partyLoaded}) then {""} else {"Waldo_MiniGames_Enable is true but Waldo_fnc_MiniGamesInit never completed - confirm init.sqf actually calls it, and check the RPT for errors from the party-games engine install."}] call _status;

private _jammingEnabled = missionNamespace getVariable ["Waldo_Jamming_Enable", false];
private _tfarLoaded = isClass (configFile >> "CfgPatches" >> "task_force_radio") || {isClass (configFile >> "CfgPatches" >> "tfar_core")};
private _jammingUsable = _acreLoaded || {_tfarLoaded};
private _jammerCount = count (missionNamespace getVariable ["Waldo_Jamming_Registry", []]);
private _jammingState = if (!_jammingEnabled) then {"DISABLED"} else {
    if (!_jammingUsable) then {"ERROR"} else {if (_jammerCount > 0) then {"ACTIVE"} else {"LOADED"}}
};
["system", "radio-jamming", _jammingState, format ["ACRE2=%1 TFAR=%2 registeredJammers=%3", _acreLoaded, _tfarLoaded, _jammerCount], _jammingEnabled && {!_jammingUsable}, if (!_jammingEnabled || {_jammingUsable}) then {""} else {"Waldo_Jamming_Enable is true but neither ACRE2 nor TFAR is loaded, so jamming has no radio engine to act on - load one of those mods, or set Waldo_Jamming_Enable to false."}] call _status;

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

// Object scaling is callable and server-validated with no background initializer of its own, so
// there is no "enabled" state to report - only whether the configured bounds are sane and how many
// objects in the mission currently carry a non-default scale.
private _scaleMinimum = missionNamespace getVariable ["Waldo_ObjectScaling_Minimum", 0.1];
private _scaleMaximum = missionNamespace getVariable ["Waldo_ObjectScaling_Maximum", 10];
private _scaleBoundsValid = _scaleMinimum > 0 && {_scaleMaximum > _scaleMinimum};
private _scaledObjects = _missionObjects select {!isNil {_x getVariable "Waldo_ObjectScale"}};
["object-transforms", "object-scaling", if (!_scaleBoundsValid) then {"ERROR"} else {if (count _scaledObjects > 0) then {"ACTIVE"} else {"LOADED"}}, format ["min=%1 max=%2 allowClientRequests=%3 scaledObjects=%4", _scaleMinimum, _scaleMaximum, missionNamespace getVariable ["Waldo_ObjectScaling_AllowClientRequests", false], count _scaledObjects], !_scaleBoundsValid, if (_scaleBoundsValid) then {""} else {"Waldo_ObjectScaling_Minimum must be greater than 0 and lower than Waldo_ObjectScaling_Maximum."}] call _status;
private _aceMedicalLoaded = isClass (configFile >> "CfgPatches" >> "ace_medical");
private _fieldHospitals = _missionObjects select {_x getVariable ["ace_medical_isMedicalFacility", false]};
if (_fieldHospitals isEqualTo []) then {
    ["logistics", "field-hospital-runtime", "UNCONFIGURED", "No crate has ace_medical_isMedicalFacility set; Waldo_fnc_MedicalCratePopulate was never called with _isFacility true", false] call _status;
} else {
    ["logistics", "field-hospital-runtime", if (_aceMedicalLoaded) then {"ACTIVE"} else {"ERROR"}, format ["facilityCrates=%1; per-object action installation is reported by the client audit", count _fieldHospitals], !_aceMedicalLoaded, if (_aceMedicalLoaded) then {""} else {"ACE medical is not loaded, so this locational treatment boost cannot take effect - load ace_medical or stop marking crates as facilities."}] call _status;
};
private _recoveryWorkshops = _missionObjects select {_x getVariable ["Waldo_Recovery_Workshop", false]};
private _recoveryVehicles = _missionObjects select {_x getVariable ["Waldo_Recovery_Registered", false]};
private _recoveryPackages = (missionNamespace getVariable ["Waldo_Recovery_Packages", []]) select {!isNull _x};
private _recoveryCarriers = _missionObjects select {_x getVariable ["Waldo_Recovery_Carrier", false]};
private _attachedPackages = 0;
private _virtualPackages = 0;
{_attachedPackages = _attachedPackages + count ((_x getVariable ["Waldo_Recovery_AttachedPackages", []]) select {!isNull _x}); _virtualPackages = _virtualPackages + count ((_x getVariable ["Waldo_Recovery_VirtualPackages", []]) select {!isNull _x});} forEach _recoveryCarriers;
private _recoveryConfigured = !(_recoveryWorkshops isEqualTo []) || {!(_recoveryVehicles isEqualTo [])};
private _recoveryBroken = !(_recoveryPackages isEqualTo []) && {_recoveryWorkshops isEqualTo []};
["logistics", "vehicle-recovery", if (!_recoveryConfigured) then {"UNCONFIGURED"} else {if (_recoveryBroken) then {"ERROR"} else {if (_recoveryPackages isEqualTo []) then {"LOADED"} else {"ACTIVE"}}}, format ["workshops=%1 vehicles=%2 carriers=%3 packages=%4 attached=%5 virtual=%6 monitor=%7", count _recoveryWorkshops, count _recoveryVehicles, count _recoveryCarriers, count _recoveryPackages, _attachedPackages, _virtualPackages, missionNamespace getVariable ["Waldo_Recovery_MonitorRunning", false]], _recoveryBroken, if (!_recoveryBroken) then {""} else {"Recovery packages exist but no workshop is registered - call Waldo_fnc_RecoveryRegisterWorkshop (or place the Vehicle Recovery Workshop composition) so recovered vehicles have somewhere to return to."}] call _status;
private _workshopKeys = _recoveryWorkshops apply {_x getVariable ["Waldo_Recovery_WorkshopKey", ""]};
private _orphanVehicles = _recoveryVehicles select {
    private _config = _x getVariable ["Waldo_Recovery_Config", []];
    count _config < 7 || {!((_config param [0, ""]) in _workshopKeys)}
};
private _invalidPackages = _recoveryPackages select {
    !(_x getVariable ["Waldo_Recovery_Package", false]) || {count (_x getVariable ["Waldo_Recovery_State", []]) < 7}
};
private _recoveryIntegrityBroken = !(_orphanVehicles isEqualTo []) || {!(_invalidPackages isEqualTo [])};
["logistics", "vehicle-recovery-integrity", if (!_recoveryConfigured) then {"UNCONFIGURED"} else {if (_recoveryIntegrityBroken) then {"ERROR"} else {"LOADED"}}, format ["workshopKeys=%1 orphanVehicles=%2 invalidPackages=%3", _workshopKeys, _orphanVehicles apply {netId _x}, _invalidPackages apply {netId _x}], _recoveryIntegrityBroken, if (!_recoveryIntegrityBroken) then {""} else {"A registered vehicle references no active workshop, or a package is missing its recovery state. Re-register the named vehicle with the ZEN Vehicle Recovery module and inspect [WMP RECOVERY] RPT lines."}] call _status;

private _tacticalDisplays = _missionObjects select {_x getVariable ["Waldo_TacticalDisplay_Registered", false]};
["interface", "tactical-displays", if (_tacticalDisplays isEqualTo []) then {"UNCONFIGURED"} else {"LOADED"}, format ["registered=%1", count _tacticalDisplays], false] call _status;
private _hazardZones = missionNamespace getVariable ["Waldo_Hazard_Zones", []];
private _hazardEnabled = missionNamespace getVariable ["Waldo_Hazard_Enable", false];
["environment", "hazard-zones", if (!_hazardEnabled) then {"DISABLED"} else {if (_hazardZones isEqualTo []) then {"ERROR"} else {"ACTIVE"}}, format ["enabled=%1 zones=%2", _hazardEnabled, count _hazardZones], _hazardEnabled && {_hazardZones isEqualTo []}, if (!_hazardEnabled || {!(_hazardZones isEqualTo [])}) then {""} else {"Waldo_Hazard_Enable is true but no zone is registered - call Waldo_fnc_HazardRegisterZone/RegisterPresetZone/RegisterEmitter (or place a Hazard composition), or set Waldo_Hazard_Enable to false if this mission doesn't use hazards."}] call _status;
private _transportEnabled = missionNamespace getVariable ["Waldo_TransportServices_Enable", false];
private _transportServices = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
private _transportPools = missionNamespace getVariable ["Waldo_Transport_Pools", createHashMapFromArray [["HELICOPTER", []], ["GROUND", []], ["BOAT", []]]];
private _transportIssues = [];
{
    private _entry = _transportServices get _x;
    private _vehicle = _entry getOrDefault ["vehicle", objNull];
    private _type = _entry getOrDefault ["type", ""];
    if (isNull _vehicle) then {_transportIssues pushBack format ["%1 has no vehicle", _x]};
    if !(_type in ["HELICOPTER", "GROUND", "BOAT"]) then {_transportIssues pushBack format ["%1 has invalid type %2", _x, _type]};
    if !(_x in (_transportPools getOrDefault [_type, []])) then {_transportIssues pushBack format ["%1 is absent from its typed pool", _x]};
} forEach keys _transportServices;
private _transportBroken = !(_transportIssues isEqualTo []);
["logistics", "transport-services", if (!_transportEnabled) then {"DISABLED"} else {if (_transportBroken) then {"ERROR"} else {if (count (keys _transportServices) == 0) then {"UNCONFIGURED"} else {"ACTIVE"}}}, format ["registered=%1 helicopters=%2 ground=%3 boats=%4 issues=%5", count (keys _transportServices), count (_transportPools getOrDefault ["HELICOPTER", []]), count (_transportPools getOrDefault ["GROUND", []]), count (_transportPools getOrDefault ["BOAT", []]), _transportIssues], _transportBroken, if (!_transportBroken) then {""} else {"A registered transport service is inconsistent with its typed pool - this usually means something mutated Waldo_Transport_Services directly instead of going through Waldo_fnc_TransportRegister; re-register the affected vehicle(s) instead of editing the registry by hand."}] call _status;
private _resupplyHubs = _missionObjects select {_x getVariable ["Waldo_FieldResupply_Hub", false]};
// Waldo_FieldResupply_MaxCrates > 0 is the real "is this player an assigned carrier" predicate used
// throughout the feature (Waldo_fnc_FieldResupplyServerHandle's own _isCarrier, Waldo_fnc_FieldResupplyInit's
// _isCarrier/_canDeploy) - Waldo_FieldResupply_Carrier is never actually set anywhere and previously
// made this row always report zero carriers regardless of real assignments.
private _resupplyCarriers = allPlayers select {(_x getVariable ["Waldo_FieldResupply_MaxCrates", 0]) > 0};
["logistics", "field-resupply-runtime", if (_resupplyHubs isEqualTo [] && {_resupplyCarriers isEqualTo []}) then {"UNCONFIGURED"} else {"LOADED"}, format ["hubs=%1 carriers=%2", count _resupplyHubs, count _resupplyCarriers], false] call _status;

{
    _x params ["_feature", "_serverVariable", "_publicVariable"];
    private _serverRegistry = missionNamespace getVariable [_serverVariable, createHashMap];
    private _publicSystems = missionNamespace getVariable [_publicVariable, []];
    private _serverCount = count (keys _serverRegistry);
    private _publicCount = count _publicSystems;
    private _consistent = _serverCount == _publicCount;
    ["runtime-system", _feature, if (_serverCount == 0) then {"UNCONFIGURED"} else {if (_consistent) then {"ACTIVE"} else {"ERROR"}}, format ["server=%1 publicJip=%2", _serverCount, _publicCount], !_consistent, if (_consistent) then {""} else {format ["The %1 server registry and its broadcast JIP list have drifted apart, so a JIP client may not see every system - this usually means something mutated the registry directly instead of going through the feature's own create/destroy functions.", _feature]}] call _status;
} forEach [
    // paradrop-drop-zones is intentionally not repeated here - the dedicated Paradrop section above
    // already reports Waldo_Paradrop_DropZones/PublicDropZones with a specific remediation hint.
    ["dynamic-aa", "Waldo_DynamicAA_Registry", "Waldo_DynamicAA_PublicSystems"],
    ["dynamic-ao", "Waldo_DynamicAO_Registry", "Waldo_DynamicAO_PublicSystems"],
    ["airborne-gunship", "Waldo_Gunship_Registry", "Waldo_Gunship_PublicSystems"]
];

private _zenLoaded = isClass (configFile >> "CfgPatches" >> "zen_main");
["integration", "ACE and Zeus integration"] call _section;
private _zenApi = !(isNil "zen_custom_modules_fnc_register");
["integration", "zen-modules", if (!_zenLoaded) then {"UNAVAILABLE"} else {if (_zenApi) then {"LOADED"} else {"ERROR"}}, format ["ZEN loaded=%1 registration API=%2", _zenLoaded, _zenApi], _zenLoaded && {!_zenApi}, if (!_zenLoaded || {_zenApi}) then {""} else {"ZEN is loaded but zen_custom_modules_fnc_register is unavailable - this usually means Zeus Enhanced failed to fully initialise; check the RPT for ZEN errors or an incompatible ZEN version."}] call _status;
["integration", "ace-actions", if (isClass (configFile >> "CfgPatches" >> "ace_main")) then {"LOADED"} else {"ERROR"}, "Dependency state only; object action installation is checked by the client audit", !(isClass (configFile >> "CfgPatches" >> "ace_main")), if (isClass (configFile >> "CfgPatches" >> "ace_main")) then {""} else {"ACE3 is required by WMP but is not loaded - see the ace_main dependency check above."}] call _status;

["optional-features", "Optional feature configuration"] call _section;
private _persistenceEnabled = missionNamespace getVariable ["Waldo_Persistence_Enable", false];
private _persistencePatches = missionNamespace getVariable ["Waldo_Persistence_PatchNames", ["inidbi2", "inidbi2_main", "inidbi2_core", "inidbi"]];
private _persistenceRuntime = [] call Waldo_fnc_PersistenceDependencyAvailable;
["optional-feature", "persistence-runtime", if (!_persistenceEnabled) then {"DISABLED"} else {if (_persistenceRuntime) then {"LOADED"} else {"ERROR"}}, format ["enabled=%1 runtimeDetected=%2", _persistenceEnabled, _persistenceRuntime], _persistenceEnabled && {!_persistenceRuntime}, if (!_persistenceEnabled || {_persistenceRuntime}) then {""} else {"Waldo_Persistence_Enable is true but the server did not detect a loaded INIDBI2 extension - install/enable INIDBI2 on the server, or set Waldo_Persistence_Enable to false in MissionConfig\persistenceConfig.sqf if you don't need persistence."}] call _status;

private _breachingEnabled = missionNamespace getVariable ["Waldo_Breaching_Enable", false];
private _breachingDependency = isClass (configFile >> "CfgPatches" >> "ace_explosives");
private _breachingProfiles = missionNamespace getVariable ["Waldo_Breaching_Profiles", createHashMap];
private _breachingStrengths = missionNamespace getVariable ["Waldo_Breaching_ExplosiveStrengths", createHashMap];
private _breachingIssues = [];
if !(_breachingProfiles isEqualType createHashMap) then {
    _breachingIssues pushBack "Waldo_Breaching_Profiles is not a HashMap";
    _breachingProfiles = createHashMap;
};
if !(_breachingStrengths isEqualType createHashMap) then {
    _breachingIssues pushBack "Waldo_Breaching_ExplosiveStrengths is not a HashMap";
    _breachingStrengths = createHashMap;
};
{
    private _targetClass = _x;
    private _profile = _breachingProfiles get _targetClass;
    if !(isClass (configFile >> "CfgVehicles" >> _targetClass)) then {
        _breachingIssues pushBack format ["unknown target CfgVehicles class %1", _targetClass];
    };
    if !(_profile isEqualType createHashMap) then {
        _breachingIssues pushBack format ["profile for %1 is not a HashMap", _targetClass];
    } else {
        private _radius = _profile getOrDefault ["radius", 6];
        private _requiredStrength = _profile getOrDefault ["requiredStrength", 1];
        if !(_radius isEqualType 0) then {_breachingIssues pushBack format ["%1 radius is not a number", _targetClass]};
        if !(_requiredStrength isEqualType 0) then {_breachingIssues pushBack format ["%1 requiredStrength is not a number", _targetClass]};
        private _explosives = _profile getOrDefault ["explosives", []];
        if !(_explosives isEqualType []) then {
            _breachingIssues pushBack format ["%1 explosives is not an array", _targetClass];
        } else {
            {
                if !(_x isEqualType "" && {isClass (configFile >> "CfgAmmo" >> _x)}) then {
                    _breachingIssues pushBack format ["%1 has unknown CfgAmmo class %2", _targetClass, _x];
                };
            } forEach _explosives;
        };
        private _replacements = _profile getOrDefault ["replacements", []];
        if !(_replacements isEqualType []) then {_breachingIssues pushBack format ["%1 replacements is not an array", _targetClass]};
    };
} forEach keys _breachingProfiles;
{
    private _strength = _breachingStrengths get _x;
    if !(isClass (configFile >> "CfgAmmo" >> _x)) then {_breachingIssues pushBack format ["unknown strength CfgAmmo class %1", _x]};
    if !(_strength isEqualType 0 && {_strength > 0}) then {_breachingIssues pushBack format ["%1 strength must be a positive number", _x]};
} forEach keys _breachingStrengths;
private _breachingProfileCount = count (keys _breachingProfiles);
private _breachingValid = _breachingDependency && {_breachingProfileCount > 0} && {_breachingIssues isEqualTo []};
private _breachingDetail = format ["enabled=%1 aceExplosives=%2 profiles=%3", _breachingEnabled, _breachingDependency, _breachingProfileCount];
if !(_breachingIssues isEqualTo []) then {_breachingDetail = _breachingDetail + "; " + (_breachingIssues joinString "; ")};
["optional-feature", "explosive-breaching", if (!_breachingEnabled) then {"DISABLED"} else {if (_breachingValid) then {"LOADED"} else {"ERROR"}}, _breachingDetail, _breachingEnabled && {!_breachingValid}, if (!_breachingEnabled || {_breachingValid}) then {""} else {"Fix the listed issue(s) in Waldo_Breaching_Profiles / Waldo_Breaching_ExplosiveStrengths (usually set from MissionConfig or a ZEN Breaching module), or confirm ace_explosives is loaded."}] call _status;

private _treatmentEnabled = missionNamespace getVariable ["Waldo_TreatmentFeedback_Enable", false];
private _treatmentDependency = isClass (configFile >> "CfgPatches" >> "ace_medical");
["optional-feature", "treatment-feedback", if (!_treatmentEnabled) then {"DISABLED"} else {if (_treatmentDependency) then {"LOADED"} else {"ERROR"}}, format ["enabled=%1 aceMedical=%2", _treatmentEnabled, _treatmentDependency], _treatmentEnabled && {!_treatmentDependency}, if (!_treatmentEnabled || {_treatmentDependency}) then {""} else {"Waldo_TreatmentFeedback_Enable is true but ace_medical is not loaded - load ACE medical, or set Waldo_TreatmentFeedback_Enable to false."}] call _status;

private _resupplyEnabled = missionNamespace getVariable ["Waldo_FieldResupply_Enable", false];
private _resupplyClass = missionNamespace getVariable ["Waldo_FieldResupply_CrateClass", "Box_NATO_Ammo_F"];
private _resupplyValid = isClass (configFile >> "CfgVehicles" >> _resupplyClass);
["optional-feature", "field-resupply", if (!_resupplyEnabled) then {"DISABLED"} else {if (_resupplyValid) then {"LOADED"} else {"ERROR"}}, format ["enabled=%1 crateClass=%2", _resupplyEnabled, _resupplyClass], _resupplyEnabled && {!_resupplyValid}, if (!_resupplyEnabled || {_resupplyValid}) then {""} else {"Waldo_FieldResupply_CrateClass does not resolve to a real CfgVehicles class - fix it in MissionConfig\logisticsConfig.sqf, or leave it unset to use the default Box_NATO_Ammo_F."}] call _status;

private _rallyEnabled = missionNamespace getVariable ["Waldo_Rally_Enable", false];
private _rallyClass = missionNamespace getVariable ["Waldo_Rally_ObjectClass", "Land_SatelliteAntenna_01_F"];
private _rallyClassValid = isClass (configFile >> "CfgVehicles" >> _rallyClass);
private _activeRallies = {_x getVariable ["Waldo_Rally_Active", false]} count allGroups;
["optional-feature", "squad-rally-points", if (!_rallyEnabled) then {"DISABLED"} else {if (!_rallyClassValid) then {"ERROR"} else {if (_activeRallies > 0) then {"ACTIVE"} else {"LOADED"}}}, format ["enabled=%1 objectClass=%2 activeGroups=%3", _rallyEnabled, _rallyClass, _activeRallies], _rallyEnabled && {!_rallyClassValid}, if (!_rallyEnabled || {_rallyClassValid}) then {""} else {"Waldo_Rally_ObjectClass does not resolve to a real CfgVehicles class - fix it wherever Rally Points was configured (RALLY_CONFIG via Feature Runtime Control, or MissionConfig), or leave it unset to use the default Land_SatelliteAntenna_01_F."}] call _status;

private _gunshipEnabled = missionNamespace getVariable ["Waldo_Gunship_Enable", false];
private _gunshipAltitude = missionNamespace getVariable ["Waldo_Gunship_DefaultAltitude", 700];
private _gunshipRadius = missionNamespace getVariable ["Waldo_Gunship_DefaultRadius", 1500];
private _gunshipBoundsValid = _gunshipAltitude >= 100 && {_gunshipAltitude <= (missionNamespace getVariable ["Waldo_Gunship_MaximumAltitude", 5000])} && {_gunshipRadius >= 200} && {_gunshipRadius <= (missionNamespace getVariable ["Waldo_Gunship_MaximumRadius", 10000])};
private _invalidGunshipClasses = [];
private _gunshipPools = missionNamespace getVariable ["Waldo_Gunship_SideAircraftPools", createHashMap];
{{if !(isClass (configFile >> "CfgVehicles" >> _x) && {_x isKindOf "Air"}) then {_invalidGunshipClasses pushBackUnique _x;};} forEach (_gunshipPools get _x);} forEach keys _gunshipPools;
private _gunshipValid = _gunshipBoundsValid && {_invalidGunshipClasses isEqualTo []};
["optional-feature", "airborne-gunship", if (!_gunshipEnabled) then {"DISABLED"} else {if (_gunshipValid) then {"LOADED"} else {"ERROR"}}, format ["enabled=%1 altitude=%2 radius=%3 invalidClasses=%4", _gunshipEnabled, _gunshipAltitude, _gunshipRadius, _invalidGunshipClasses], _gunshipEnabled && {!_gunshipValid}, if (!_gunshipEnabled || {_gunshipValid}) then {""} else {"Check that Waldo_Gunship_DefaultAltitude/Radius sit within Waldo_Gunship_MaximumAltitude/Radius, and that every class listed in Waldo_Gunship_SideAircraftPools is a real Air-kind CfgVehicles class."}] call _status;

{
    private _aaPool = [createHashMap, _x] call Waldo_fnc_DynamicAAResolveAssetPool;
    private _emptyCategories = ["radarClasses", "staticSitePools", "mobileClasses", "fighterClasses"] select {count (_aaPool getOrDefault [_x, []]) == 0};
    ["optional-feature", format ["dynamic-aa-%1", _x], if (_emptyCategories isEqualTo []) then {"LOADED"} else {"ERROR"}, format ["source=%1 emptyCategories=%2", _aaPool getOrDefault ["source", str _x], _emptyCategories], !(_emptyCategories isEqualTo []), if (_emptyCategories isEqualTo []) then {""} else {format ["Waldo_fnc_DynamicAAResolveAssetPool found no %1 for this side - add classes to that side's Dynamic AA asset pool in MissionConfig\airOperationsConfig.sqf, or load the mod that provides them.", _emptyCategories joinString ", "]}] call _status;
} forEach [west, east, independent];

private _treeEnabled = missionNamespace getVariable ["Waldo_TreeFelling_Enable", false];
private _treeIssues = [];
private _treePatterns = missionNamespace getVariable ["Waldo_TreeFelling_WeaponPatterns", []];
private _treeAllowedClasses = missionNamespace getVariable ["Waldo_TreeFelling_AllowedClasses", []];
private _treeReplacementLists = [
    ["FallenClasses", missionNamespace getVariable ["Waldo_TreeFelling_FallenClasses", []]],
    ["FallenClassesSmall", missionNamespace getVariable ["Waldo_TreeFelling_FallenClassesSmall", []]],
    ["FallenClassesMedium", missionNamespace getVariable ["Waldo_TreeFelling_FallenClassesMedium", []]],
    ["FallenClassesLarge", missionNamespace getVariable ["Waldo_TreeFelling_FallenClassesLarge", []]]
];
if !(_treePatterns isEqualType [] && {_treePatterns findIf {!(_x isEqualType "") || {_x == ""}} < 0}) then {
    _treeIssues pushBack "WeaponPatterns must be a list of non-empty text fragments";
};
if !(_treeAllowedClasses isEqualType []) then {
    _treeIssues pushBack "AllowedClasses must be an array";
    _treeAllowedClasses = [];
};
{
    if !(isClass (configFile >> "CfgVehicles" >> _x)) then {_treeIssues pushBack format ["unknown allowed CfgVehicles class %1", _x]};
} forEach _treeAllowedClasses;
{
    _x params ["_settingName", "_classes"];
    if !(_classes isEqualType []) then {
        _treeIssues pushBack format ["%1 must be an array", _settingName];
    } else {
        {
            if !(isClass (configFile >> "CfgVehicles" >> _x)) then {_treeIssues pushBack format ["%1 has unknown CfgVehicles class %2", _settingName, _x]};
        } forEach _classes;
    };
} forEach _treeReplacementLists;
private _treeThresholds = missionNamespace getVariable ["Waldo_TreeFelling_SizeThresholds", [7, 15]];
if !(_treeThresholds isEqualType [] && {count _treeThresholds >= 2} && {(_treeThresholds select 0) isEqualType 0} && {(_treeThresholds select 1) isEqualType 0} && {(_treeThresholds select 0) < (_treeThresholds select 1)}) then {
    _treeIssues pushBack "SizeThresholds must contain two increasing numbers, for example [7, 15]";
};
private _treeDirectionSetting = missionNamespace getVariable ["Waldo_TreeFelling_DirectionMode", "RANDOM"];
private _treeDirection = if (_treeDirectionSetting isEqualType "") then {toUpperANSI _treeDirectionSetting} else {"INVALID"};
if !(_treeDirection in ["RANDOM", "STRIKE", "ORIGINAL"]) then {_treeIssues pushBack "DirectionMode must be RANDOM, STRIKE or ORIGINAL"};
private _treeEfficiencies = missionNamespace getVariable ["Waldo_TreeFelling_ToolEfficiency", createHashMap];
if !(_treeEfficiencies isEqualType createHashMap) then {
    _treeIssues pushBack "ToolEfficiency must be a HashMap";
} else {
    {
        private _value = _treeEfficiencies get _x;
        if (_x == "" || {!(_value isEqualType 0 && {_value > 0})}) then {_treeIssues pushBack format ["ToolEfficiency row %1 must use a non-empty fragment and positive number", _x]};
    } forEach keys _treeEfficiencies;
};
private _treeValid = _treeIssues isEqualTo [];
private _treeDetail = format ["enabled=%1 patterns=%2 direction=%3", _treeEnabled, _treePatterns, _treeDirection];
if (!_treeValid) then {_treeDetail = _treeDetail + "; " + (_treeIssues joinString "; ")};
["optional-feature", "tree-felling", if (!_treeEnabled) then {"DISABLED"} else {if (_treeValid) then {"LOADED"} else {"ERROR"}}, _treeDetail, _treeEnabled && {!_treeValid}, if (!_treeEnabled || {_treeValid}) then {""} else {"Fix the listed configuration issue(s) in the Tree Felling settings (Waldo_TreeFelling_* variables, usually set via the Feature Runtime Control TREE_CONFIG bridge or MissionConfig)."}] call _status;

private _corpseTrapEnabled = missionNamespace getVariable ["Waldo_CorpseTraps_Enable", false];
private _corpseTrapDependency = isClass (configFile >> "CfgPatches" >> "ace_interact_menu");
private _corpseTrapRigged = _missionObjects select {(_x getVariable ["Waldo_CorpseTrap_State", ""]) != ""};
["optional-feature", "corpse-traps", if (!_corpseTrapEnabled) then {"DISABLED"} else {if (!_corpseTrapDependency) then {"ERROR"} else {if (count _corpseTrapRigged > 0) then {"ACTIVE"} else {"LOADED"}}}, format ["enabled=%1 aceInteractMenu=%2 rigged=%3", _corpseTrapEnabled, _corpseTrapDependency, count _corpseTrapRigged], _corpseTrapEnabled && {!_corpseTrapDependency}, if (!_corpseTrapEnabled || {_corpseTrapDependency}) then {""} else {"Waldo_CorpseTraps_Enable is true but ace_interact_menu is not loaded - load ACE interaction menu, or set Waldo_CorpseTraps_Enable to false in MissionConfig\missionSystemsConfig.sqf."}] call _status;

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
[format ["[WMP DIAG] %1", _summary]] call _notifyAdmins;
missionNamespace setVariable ["Waldo_Diagnostics_Running", false];
_warnings
