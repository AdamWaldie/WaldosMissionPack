/*
 * Author: WaldoTheWarfighter
 * Collects one interface client's dependency, module, UI and feature diagnostic state and returns
 * it to the server-owned diagnostic run. The function is read-only and safe for current or JIP
 * clients; every result carries the run id and client owner for correlation.
 *
 * Arguments:
 * 0: diagnostic run id <STRING>
 *
 * Return Value:
 * Boolean - false when no interface/run id is available, otherwise the report is sent to server
 *
 * Called by:
 * Waldo_fnc_RunDiagnostics during its per-client collection phase.
 *
 * Example:
 * ["diag_01"] call Waldo_fnc_RunDiagnosticsClient;
 * Wiki: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Mission-Diagnostics
 */
if (!hasInterface) exitWith {false};
params [["_runId", "", [""]]];
if (_runId isEqualTo "") exitWith {false};

private _checks = [];
// _hint mirrors Waldo_fnc_RunDiagnostics' server-side _status helper: an optional, plain-language
// remediation step folded into the same detail text via the shared Waldo_fnc_DiagnosticFoldHint, so
// a client-local failure is just as assistive as a server one instead of only carrying a terse
// state=/detail= pair.
private _add = {
    params ["_area", "_feature", "_state", ["_detail", ""], ["_hint", ""]];
    private _fullDetail = [_detail, _hint] call Waldo_fnc_DiagnosticFoldHint;
    _checks pushBack [_area, _feature, _state, _fullDetail];
    [_area, _feature, if (_state == "ERROR") then {"ERROR"} else {"INFO"}, "CHECK", format ["state=%1 detail=%2", _state, _fullDetail], _runId, format ["CLIENT:%1", clientOwner]] call Waldo_fnc_DiagnosticLog;
};
private _consumeFeatureReport = {
    params ["_featureReport"];
    {
        _x params ["_area", "_feature", "_state", ["_detail", ""]];
        [_area, _feature, _state, _detail] call _add;
    } forEach (_featureReport getOrDefault ["checks", []]);
};

["core", "diagnostics", "INFO", "BEGIN", format ["player=%1 uid=%2", name player, getPlayerUID player], _runId, format ["CLIENT:%1", clientOwner]] call Waldo_fnc_DiagnosticLog;

{
    _x params ["_patch", "_label", "_required"];
    private _loaded = isClass (configFile >> "CfgPatches" >> _patch);
    ["dependencies", _label, if (_loaded) then {"LOADED"} else {if (_required) then {"ERROR"} else {"UNAVAILABLE"}}, format ["required=%1 patch=%2", _required, _patch], if (_loaded || {!_required}) then {""} else {format ["%1 is required by WMP but is not loaded on this client - add it to this client's mod list.", _label]}] call _add;
} forEach [
    ["cba_main", "CBA_A3", true],
    ["ace_main", "ACE3", true],
    ["zen_main", "ZEN", false],
    ["acre_main", "ACRE2", false],
    ["task_force_radio", "TFAR", false]
];

private _runtimeSnapshotReceived = missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false];
private _runtimeSnapshotFailed = missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotFailed", false];
["runtime-control", "runtime-control-snapshot", if (_runtimeSnapshotReceived) then {"ACTIVE"} else {if (_runtimeSnapshotFailed) then {"ERROR"} else {"LOADED"}}, format ["received=%1 failed=%2 requestInFlight=%3", _runtimeSnapshotReceived, _runtimeSnapshotFailed, missionNamespace getVariable ["Waldo_FeatureRuntimeRequestInFlight", false]], if (!_runtimeSnapshotFailed) then {""} else {"This client did not receive the authoritative runtime snapshot after repeated attempts - check this client's connection, and check the server RPT for [WMP RUNTIME] entries."}] call _add;

// Waldo_fnc_FeatureRuntimeReceiveState calls UiThemeApplyLocal on every machine as part of the
// runtime snapshot handshake, so Waldo_UI_ResolvedTheme should already match the authoritative
// Waldo_UI_Theme by the time that snapshot has arrived. Before it arrives, no local application has
// been attempted yet, which is expected and not an error.
private _themeId = toUpperANSI (missionNamespace getVariable ["Waldo_UI_Theme", "DEFAULT"]);
private _resolvedTheme = uiNamespace getVariable ["Waldo_UI_ResolvedTheme", createHashMap];
private _themeAppliedId = toUpperANSI (_resolvedTheme getOrDefault ["id", ""]);
private _themeState = if (_themeAppliedId == "") then {if (_runtimeSnapshotReceived) then {"ERROR"} else {"LOADED"}} else {if (_themeAppliedId == _themeId) then {"LOADED"} else {"ERROR"}};
["interface", "ui-theme", _themeState, format ["theme=%1 locallyApplied=%2 revision=%3", _themeId, if (_themeAppliedId == "") then {"NONE"} else {_themeAppliedId}, missionNamespace getVariable ["Waldo_UI_ThemeRevision", 0]], if (_themeState != "ERROR") then {""} else {"This client's applied theme does not match the authoritative Waldo_UI_Theme - reopen a WMP display or rejoin; if it persists, check the RPT for errors from Waldo_fnc_UiThemeApplyLocal."}] call _add;

[call Waldo_fnc_SafeStartGetDiagnostics] call _consumeFeatureReport;
[call Waldo_fnc_ENDEXGetDiagnostics] call _consumeFeatureReport;
[call Waldo_fnc_EcoCore_getDiagnostics] call _consumeFeatureReport;
[call Waldo_fnc_ObituaryGetDiagnostics] call _consumeFeatureReport;

private _acreLoaded = isClass (configFile >> "CfgPatches" >> "acre_main");
private _acreConfig = missionNamespace getVariable ["Waldo_ACRE2_Config", createHashMap];
private _acreEnabled = _acreLoaded && {_acreConfig getOrDefault ["enabled", false]};
if (_acreEnabled) then {
    private _plan = missionNamespace getVariable ["Waldo_ACRE2_Plan", []];
    private _configValidation = missionNamespace getVariable ["Waldo_ACRE2_ConfigValidation", [false, ["ACRE configuration was not validated."], []]];
    private _planValid = count _plan >= 4 && {(_plan select 0) == 5};
    private _rawGroup = groupId group player;
    private _groupKey = toUpperANSI (((_rawGroup splitString " -_.") joinString ""));
    private _sideKey = switch (side player) do {case west: {"WEST"}; case east: {"EAST"}; case independent: {"GUER"}; default {"CIV"}};
    private _sideIndex = if (_planValid) then {(_plan select 2) findIf {(_x select 0) == _sideKey}} else {-1};
    private _groups = if (_sideIndex >= 0) then {((_plan select 2) select _sideIndex) param [3, []]} else {[]};
    private _groupIndex = _groups findIf {(_x select 0) == _groupKey};
    private _radios = if (isNil "acre_api_fnc_getCurrentRadioList") then {[]} else {[] call acre_api_fnc_getCurrentRadioList};
    private _unique = _radios select {"_ID_" in toUpper _x};
    private _profiles = [_acreConfig] call Waldo_fnc_ACRE2GetRadioProfiles;
    private _profileClasses = _profiles apply {toUpperANSI (_x select 0)};
    private _inventoryRadios = (items player + assignedItems player) select {
        private _item = toUpperANSI _x;
        (_profileClasses findIf {_item == _x || {_item find (_x + "_ID_") == 0}}) >= 0
    };
    private _acreApiReady = !isNil "acre_api_fnc_isInitialized" && {[] call acre_api_fnc_isInitialized};
    private _edenRadioSetup = player getVariable ["acre_sys_radio_setup", ""];
    private _last = missionNamespace getVariable ["Waldo_ACRE2_LastApplication", []];
    private _lastOk = count _last > 0 && {_last select 0};
    private _expectsRadios = !(_inventoryRadios isEqualTo []);
    private _state = if (!(_configValidation select 0) || {!_planValid} || {_sideIndex < 0} || {_groupIndex < 0} || {_expectsRadios && {(_radios isEqualTo [] || {!_lastOk})}}) then {"ERROR"} else {if (_expectsRadios) then {"ACTIVE"} else {"UNCONFIGURED"}};
    private _plainFinding = if !(_configValidation select 0) then {format ["ACRE configuration errors: %1", _configValidation select 1]} else {if (!_planValid) then {"The server did not publish a valid ACRE plan."} else {
        if (_sideIndex < 0) then {format ["No ACRE side block matches %1.", _sideKey]} else {
            if (_groupIndex < 0) then {format ["Group '%1' is not listed in acreConfig.sqf.", _rawGroup]} else {
                if (_expectsRadios && {!_acreApiReady}) then {"ACRE has not finished converting the player's carried radios to unique IDs."} else {
                    if (_expectsRadios && {_radios isEqualTo []}) then {"Supported radio items exist in the inventory, but ACRE returned no current radios."} else {
                        if (_expectsRadios && {!_lastOk}) then {format ["The radio plan was not applied successfully: %1", _last param [5, []]]} else {
                            if (_expectsRadios) then {"Carried radios and the configured group plan were applied."} else {"This player carries no supported ACRE radio; no assignment is required."}
                        }
                    }
                }
            }
        }
    }};
    private _presetHint = if (_state != "ERROR") then {""} else {
        if !(_configValidation select 0) then {"Fix the listed acreConfig.sqf validation error(s)."} else {
            if (!_planValid) then {"Confirm initServer.sqf calls Waldo_fnc_ACRE2Init and that MissionConfig\acreConfig.sqf is well-formed."} else {
                if (_sideIndex < 0) then {"Add a matching side block for this player's side to MissionConfig\acreConfig.sqf."} else {
                    if (_groupIndex < 0) then {format ["Add group '%1' to MissionConfig\acreConfig.sqf, or fix its callsign so it matches the Eden editor group ID exactly.", _rawGroup]} else {
                        "ACRE has not finished converting radios to unique IDs, or the last apply attempt failed - check readinessFailure/lastApplication above and the RPT for [WMP ACRE] entries."
                    }
                }
            }
        }
    };
    ["radio", "acre-player-presetting", _state, format ["finding=%1 rawGroup='%2' normalized=%3 side=%4 planRevision=%5 sideMatch=%6 groupMatch=%7 inventoryRadios=%8 currentRadios=%9 unique=%10 acreReady=%11 edenRadioSetup=%12 loadoutGeneration=%13 restoredGeneration=%14 lastApplication=%15 readinessFailure=%16", _plainFinding, _rawGroup, _groupKey, _sideKey, if (_planValid) then {_plan select 1} else {-1}, _sideIndex >= 0, _groupIndex >= 0, _inventoryRadios, _radios, count _unique, _acreApiReady, _edenRadioSetup, missionNamespace getVariable ["Waldo_ACRE2_LoadoutGeneration", -1], missionNamespace getVariable ["Waldo_ACRE2_RestoredRadioGeneration", -1], _last, missionNamespace getVariable ["Waldo_ACRE2_LastReadinessFailure", []]], _presetHint] call _add;
    if !(_edenRadioSetup isEqualTo "") then {
        ["radio", "acre-eden-radio-attribute", "ERROR", format ["This unit still has an Eden ACRE Radio Setup attribute (%1) after Waldo_fnc_ACRE2Init already tries to clear acre_sys_radio_setup at client-init time - either ACRE2 re-populated/read it before that clear ran, or ACRE2Init did not run for this player. It can overwrite acreConfig.sqf during startup. Clear that unit's ACRE Radio Setup attribute in Eden directly so nothing has to race it. WMP's own overwrite still runs automatically once ACRE is ready (see [WMP ACRE] RPT entries for the retry, and Waldo_ACRE2_Config's readinessTimeoutSeconds in MissionConfig\\acreConfig.sqf to tune how long that takes on a heavy modset), but clearing the attribute at the source is the reliable fix.", _edenRadioSetup]] call _add;
    } else {
        ["radio", "acre-eden-radio-attribute", "LOADED", "No conflicting Eden ACRE Radio Setup attribute is present."] call _add;
    };
} else {
    ["radio", "acre-player-presetting", if (_acreLoaded) then {"DISABLED"} else {"UNAVAILABLE"}, format ["loaded=%1 configEnabled=%2", _acreLoaded, _acreConfig getOrDefault ["enabled", false]]] call _add;
};

private _jamEnabled = missionNamespace getVariable ["Waldo_Jamming_Enable", false];
private _jamFactor = 0;
if (_jamEnabled && {!isNil "Waldo_fnc_JammingFactor"} && {alive player}) then {
    _jamFactor = [getPosASL player, side player, -1] call Waldo_fnc_JammingFactor;
};
private _jamCtrl = (findDisplay 46) displayCtrl 5310;
private _jamHudOk = _jamFactor <= 0 || {!isNull _jamCtrl && {ctrlShown _jamCtrl}};
private _jamLoopRunning = missionNamespace getVariable ["Waldo_Jamming_UiRunning", false];
private _jamUiReady = missionNamespace getVariable ["Waldo_Jamming_UiReady", false];
private _jamClientState = if (!_jamEnabled) then {"DISABLED"} else {
    if (!_jamLoopRunning) then {"ERROR"} else {
        if (!_jamUiReady) then {"LOADED"} else {
            if (!_jamHudOk) then {"ERROR"} else {if (_jamFactor > 0) then {"ACTIVE"} else {"LOADED"}}
        }
    }
};
private _jamHint = if (_jamClientState != "ERROR") then {""} else {
    if (!_jamLoopRunning) then {
        "Waldo_fnc_JammingInit did not start on this client - check the RPT for jamming-related errors during initPlayerLocal.sqf."
    } else {
        "The jamming HUD panel (IDC 5310) failed to show while this player is inside a jammer field - try the ACE self-action 'Clear Stuck WMP UI' (Waldo_fnc_ClearUiPanels)."
    }
};
["electronic-warfare", "jamming-client", _jamClientState, format ["factor=%1 registry=%2 loop=%3 uiReady=%4 hud=%5", _jamFactor, count (missionNamespace getVariable ["Waldo_Jamming_Registry", []]), _jamLoopRunning, _jamUiReady, !isNull _jamCtrl && {ctrlShown _jamCtrl}], _jamHint] call _add;

private _jumpCapableClasses = ["RHS_Mi24_base", "RHS_Mi8_base", "Heli_Transport_02_base_F", "RHS_C130J_Base", "B_T_VTOL_01_infantry_F"];
private _jumpAircraft = (allMissionObjects "Air") select {
    private _aircraft = _x;
    _jumpCapableClasses findIf {_aircraft isKindOf _x} >= 0
};
if (_jumpAircraft isEqualTo []) then {
    ["paradrop", "jump-actions-local", "UNCONFIGURED", "No jump-capable aircraft are present on this client."] call _add;
} else {
    // Use explicit numeric accumulators. Arma has returned the final BOOL predicate from both the
    // filtered-array and predicate-count forms in live diagnostics, so neither overloaded form is
    // safe here. This diagnostic must always leave both values as NUMBERs.
    private _pendingJumpCount = 0;
    private _missingJumpCount = 0;
    {
        private _aircraft = _x;
        private _ready = _aircraft getVariable ["Waldo_Paradrop_LocalSetupComplete", false];
        if (!_ready) then {
            _pendingJumpCount = _pendingJumpCount + 1;
        } else {
            private _expected = _aircraft getVariable ["Waldo_Paradrop_ConfiguredJumpTypes", []];
            if !(_expected isEqualType []) then {_expected = []};
            if (count _expected != 2) then {
                _expected = [
                    true,
                    _aircraft isKindOf "RHS_C130J_Base" || {_aircraft isKindOf "B_T_VTOL_01_infantry_F"}
                ];
            };
            private _missingStatic = (_expected select 0) && {(_aircraft getVariable ["Waldo_Static_Jump_ActionId", -1]) < 0};
            private _missingHalo = (_expected select 1) && {(_aircraft getVariable ["Waldo_Halo_Jump_ActionId", -1]) < 0};
            if (_missingStatic || {_missingHalo}) then {
                _missingJumpCount = _missingJumpCount + 1;
            };
        };
    } forEach _jumpAircraft;
    private _jumpState = if (_missingJumpCount > 0) then {"ERROR"} else {
        if (_pendingJumpCount > 0) then {"LOADED"} else {"ACTIVE"}
    };
    ["paradrop", "jump-actions-local", _jumpState, format [
        "aircraft=%1 ready=%2 pending=%3 missingExpectedActions=%4",
        count _jumpAircraft, (count _jumpAircraft) - _pendingJumpCount, _pendingJumpCount, _missingJumpCount
    ], if (_missingJumpCount == 0) then {""} else {"An aircraft finished local jump setup but is still missing an expected static-line/HALO hold-action on this client - check the RPT for [WMP PARADROP] entries, and confirm the jump envelope thresholds (WALDO_STATIC_MIN/MAXALTITUDE, WALDO_STATIC_MAXSPEED, WALDO_PARA_HALOALTITUDE) aren't excluding both jump types."}] call _add;
};

private _zenLoaded = isClass (configFile >> "CfgPatches" >> "zen_main");
// 45 always-registered modules; +3 headless-client control modules only when Waldo_Headless_Enable is
// true, and only once that conditional registration block (a bounded async wait on
// Waldo_SharedFeatureConfigReady in Waldo_fnc_ZenInitModules) has actually finished - a diagnostics
// run that lands inside that window legitimately reads 45 even on a headless-enabled mission, so both
// counts are accepted rather than racing a false ERROR.
private _zenCount = missionNamespace getVariable ["Waldo_ZenModuleCount", 0];
private _zenOk = _zenCount in [45, 48];
["zeus", "core-modules", if (!_zenLoaded) then {"UNAVAILABLE"} else {if (_zenOk) then {"LOADED"} else {"ERROR"}}, format ["registered=%1 expected=45 (48 with Headless Client Support enabled)", _zenCount], if (!_zenLoaded || _zenOk) then {""} else {"Zeus Enhanced module registration count does not match the expected 45 (or 48 with Headless Client Support enabled) - check the RPT for ZEN registration errors from Waldo_fnc_ZenInitModules, or confirm this client's WMP copy matches the server's."}] call _add;
private _economyActive = missionNamespace getVariable ["WaldoEcoCore_ModuleActive", false];
["zeus", "economy-modules", if (!_economyActive) then {"DISABLED"} else {if ((missionNamespace getVariable ["WaldoEcoCore_ZenModuleCount", 0]) == 19) then {"LOADED"} else {"ERROR"}}, format ["registered=%1 expected=19", missionNamespace getVariable ["WaldoEcoCore_ZenModuleCount", 0]], if (!_economyActive || {(missionNamespace getVariable ["WaldoEcoCore_ZenModuleCount", 0]) == 19}) then {""} else {"Waldos Economy Systems is active but its 19 ZEN modules did not fully register - check the RPT for errors from Waldo_fnc_EcoCore_registerZenModules."}] call _add;

private _markerHandler = missionNamespace getVariable ["Waldo_3DMarker_DrawHandler", -1];
["world-ui", "custom-3d-markers", if (_markerHandler >= 0) then {"LOADED"} else {"UNAVAILABLE"}, format ["drawHandler=%1 markers=%2", _markerHandler, count (missionNamespace getVariable ["Waldo_3DMarker_Registry", []])]] call _add;

private _interactionObjects = missionNamespace getVariable ["Waldo_QA_InteractionObjects", []];
[[_interactionObjects] call Waldo_fnc_MiniGameInteractionGetDiagnostics] call _consumeFeatureReport;

private _aceInteractLoaded = isClass (configFile >> "CfgPatches" >> "ace_interact_menu");
private _localObjects = allMissionObjects "All";
private _tacticalDisplays = _localObjects select {_x getVariable ["Waldo_TacticalDisplay_Registered", false]};
private _missingTacticalActions = _tacticalDisplays select {(_x getVariable ["Waldo_TacticalDisplay_LocalAction", -1]) < 0};
["interface", "tactical-display-actions", if (_tacticalDisplays isEqualTo []) then {"UNCONFIGURED"} else {if (_missingTacticalActions isEqualTo []) then {"LOADED"} else {"ERROR"}}, format ["registered=%1 missingLocalAction=%2", count _tacticalDisplays, count _missingTacticalActions], if (_missingTacticalActions isEqualTo []) then {""} else {"A registered Tactical Display is missing its local action on this client - reconnect, or check the RPT for errors from Waldo_fnc_TacticalDisplayRegister."}] call _add;
private _hazardEnabled = missionNamespace getVariable ["Waldo_Hazard_Enable", false];
private _hazardZones = missionNamespace getVariable ["Waldo_Hazard_Zones", []];
private _hazardClient = missionNamespace getVariable ["Waldo_Hazard_ClientStarted", false];
private _hazardEvaluation = missionNamespace getVariable ["Waldo_Hazard_LastEvaluation", []];
private _hazardFresh = count _hazardEvaluation >= 3 && {(diag_tickTime - (_hazardEvaluation select 0)) <= ((missionNamespace getVariable ["Waldo_Hazard_Interval", 1]) max 0.25) * 3};
["environment", "hazard-client", if (!_hazardEnabled) then {"DISABLED"} else {if (_hazardClient && {!(_hazardZones isEqualTo [])} && {_hazardFresh}) then {"ACTIVE"} else {"ERROR"}}, format ["enabled=%1 zones=%2 snapshot=%3 evaluator=%4 freshEvaluation=%5 lastEvaluation=%6", _hazardEnabled, count _hazardZones, missionNamespace getVariable ["Waldo_Hazard_SnapshotReceived", false], _hazardClient, _hazardFresh, _hazardEvaluation], if (!_hazardEnabled || {_hazardClient && {!(_hazardZones isEqualTo [])} && {_hazardFresh}}) then {""} else {"Waldo_Hazard_Enable is true but this client's evaluator loop isn't producing fresh evaluations - check the RPT for hazard-related errors, and confirm the server actually published a zone snapshot."}] call _add;
private _dismountEnabled = missionNamespace getVariable ["Waldo_EmergencyDismount_Enable", false];
private _dismountStarted = missionNamespace getVariable ["Waldo_EmergencyDismount_ClientStarted", false];
private _dismountHandle = missionNamespace getVariable ["Waldo_EmergencyDismount_ClientLoop", scriptNull];
private _dismountRunning = _dismountStarted && {!(scriptDone _dismountHandle)};
["interface", "emergency-dismount-client", if (!_dismountEnabled) then {"DISABLED"} else {if (_dismountRunning) then {"LOADED"} else {"ERROR"}}, format ["enabled=%1 started=%2 loopRunning=%3 interval=%4", _dismountEnabled, _dismountStarted, !(scriptDone _dismountHandle), missionNamespace getVariable ["Waldo_EmergencyDismount_Interval", 0.5]], if (!_dismountEnabled || {_dismountRunning}) then {""} else {"Waldo_EmergencyDismount_Enable is true but the local monitor loop isn't running - check the RPT for errors from Waldo_fnc_EmergencyDismountInit, or confirm the Feature Runtime Control snapshot actually reached this client."}] call _add;

private _accessibilityInstalled = player getVariable ["Waldo_Accessibility_SelfInteractionInstalled", false];
private _accessibilityMode = player getVariable ["Waldo_Accessibility_InteractionMode", ""];
private _colourVisionId = profileNamespace getVariable ["Waldo_UI_ColourVisionProfile", "STANDARD"];
private _colourVisionResolved = ([_colourVisionId] call Waldo_fnc_UiColourVisionProfile) getOrDefault ["id", "STANDARD"];
["interface", "accessibility-self-interaction", if (_accessibilityInstalled) then {"LOADED"} else {"ERROR"}, format ["installed=%1 mode=%2 colourVisionProfile=%3", _accessibilityInstalled, _accessibilityMode, toUpperANSI _colourVisionResolved], if (_accessibilityInstalled) then {""} else {"The Accessibility self-interaction menu failed to install on this client - check the RPT for errors from Waldo_fnc_AccessibilitySelfInteractionInit."}] call _add;

private _hudEnabled = missionNamespace getVariable ["Waldo_WmpHud_Enable", false];
private _hudEligible = if (_hudEnabled) then {[player] call Waldo_fnc_WmpHudEligible} else {false};
private _hudStarted = missionNamespace getVariable ["Waldo_WmpHud_ClientStarted", false];
["interface", "wmp-hud", if (!_hudEnabled) then {"DISABLED"} else {if (!_hudEligible) then {"UNCONFIGURED"} else {if (_hudStarted) then {"ACTIVE"} else {"ERROR"}}}, format ["enabled=%1 eligible=%2 clientStarted=%3 visible=%4", _hudEnabled, _hudEligible, _hudStarted, missionNamespace getVariable ["Waldo_WmpHud_Visible", false]], if (!_hudEnabled || {!_hudEligible} || {_hudStarted}) then {""} else {"Waldo_WmpHud_Enable is true and this player is eligible, but the HUD client loop never started - check the RPT for errors from Waldo_fnc_WmpHudInit."}] call _add;
private _transportInstalled = player getVariable ["Waldo_Transport_InteractionsInstalled", false];
private _transportAvailable = missionNamespace getVariable ["Waldo_HeliTransport_Available", false] || {missionNamespace getVariable ["Waldo_GroundTransport_Available", false]};
["logistics", "transport-client-actions", if (!_transportAvailable) then {"UNCONFIGURED"} else {if (_transportInstalled) then {"LOADED"} else {"ERROR"}}, format ["available=%1 interactionsInstalled=%2", _transportAvailable, _transportInstalled], if (!_transportAvailable || {_transportInstalled}) then {""} else {"A transport service is available but this client's interaction menu wasn't installed - reconnect, or check the RPT for errors from the Transport Services client setup."}] call _add;
private _mhqObjects = _localObjects select {_x getVariable ["Waldo_MHQ_ServerConfigured", false]};
if (_mhqObjects isEqualTo []) then {
    ["logistics", "mhq-actions", "UNCONFIGURED", "No configured MHQ is present"] call _add;
} else {
    private _mhqValid = (_mhqObjects findIf {
        !(_x getVariable ["Waldo_MHQ_LocalActionsInstalled", false])
        || {if (_aceInteractLoaded) then {
            !(_x getVariable ["Waldo_MHQ_ACEActionsInstalled", false]) || {_x getVariable ["Waldo_MHQ_VanillaActionsInstalled", false]}
        } else {
            !(_x getVariable ["Waldo_MHQ_VanillaActionsInstalled", false])
        }}
    }) < 0;
    ["logistics", "mhq-actions", if (_mhqValid) then {"LOADED"} else {"ERROR"}, format ["objects=%1 expectedMode=%2", count _mhqObjects, if (_aceInteractLoaded) then {"ACE"} else {"VANILLA"}], if (_mhqValid) then {""} else {"A configured MHQ is missing its expected local action on this client - check the RPT for errors from Waldo_fnc_MHQSetupLocal, and confirm ACE Interact Menu is loaded if expectedMode=ACE."}] call _add;
};

private _vvdTerminals = _localObjects select {_x getVariable ["Waldo_VVD_TerminalConfigured", false]};
if (_vvdTerminals isEqualTo []) then {
    ["logistics", "vvd-actions", "UNCONFIGURED", "No configured VVD terminal is present"] call _add;
} else {
    private _vvdValid = (_vvdTerminals findIf {
        !(_x getVariable ["Waldo_VVD_LocalActionsInstalled", false])
        || {if (_aceInteractLoaded) then {
            !(_x getVariable ["Waldo_VVD_ACEActionsInstalled", false]) || {_x getVariable ["Waldo_VVD_VanillaActionsInstalled", false]}
        } else {
            !(_x getVariable ["Waldo_VVD_VanillaActionsInstalled", false])
        }}
    }) < 0;
    ["logistics", "vvd-actions", if (_vvdValid) then {"LOADED"} else {"ERROR"}, format ["terminals=%1 expectedMode=%2", count _vvdTerminals, if (_aceInteractLoaded) then {"ACE"} else {"VANILLA"}], if (_vvdValid) then {""} else {"A configured VVD terminal is missing its expected local action on this client - check the RPT for errors from the VVD local setup, and confirm ACE Interact Menu is loaded if expectedMode=ACE."}] call _add;
};

private _corpseTrapEnabled = missionNamespace getVariable ["Waldo_CorpseTraps_Enable", false];
private _corpseTrapInstalled = missionNamespace getVariable ["Waldo_CorpseTrap_Installed", false];
["interactions", "corpse-trap-actions", if (!_corpseTrapEnabled) then {"DISABLED"} else {if (!_aceInteractLoaded) then {"UNAVAILABLE"} else {if (_corpseTrapInstalled) then {"LOADED"} else {"ERROR"}}}, format ["enabled=%1 aceInteractMenu=%2 installed=%3", _corpseTrapEnabled, _aceInteractLoaded, _corpseTrapInstalled], if (!_corpseTrapEnabled || {!_aceInteractLoaded} || {_corpseTrapInstalled}) then {""} else {"Waldo_CorpseTraps_Enable is true and ACE Interact Menu is loaded, but the 'Rig Corpse' action failed to install on this client - check the RPT for [WMP CORPSE TRAPS] entries."}] call _add;

private _fieldHospitals = _localObjects select {_x getVariable ["ace_medical_isMedicalFacility", false]};
if (_fieldHospitals isEqualTo []) then {
    ["logistics", "field-hospital-actions", "UNCONFIGURED", "No field hospital crate is present"] call _add;
} else {
    // Waldo_fnc_MedicalCrateFacilityActionLocal installs the vanilla addAction unconditionally and
    // the ACE action only when ACE Interact is loaded (both together, not one as a fallback for the
    // other) - a crate missing either the expected ACE path or its vanilla action id means the
    // install call never reached that crate on this client.
    private _fieldHospitalsMissingAction = _fieldHospitals select {
        (_x getVariable ["Waldo_FieldHospital_VanillaActionId", -1]) < 0
        || {_aceInteractLoaded && {(_x getVariable ["Waldo_FieldHospital_AceActionPath", []]) isEqualTo []}}
    };
    ["logistics", "field-hospital-actions", if (_fieldHospitalsMissingAction isEqualTo []) then {"LOADED"} else {"ERROR"}, format ["crates=%1 missingAction=%2 expectedMode=%3", count _fieldHospitals, count _fieldHospitalsMissingAction, if (_aceInteractLoaded) then {"ACE+VANILLA"} else {"VANILLA"}], if (_fieldHospitalsMissingAction isEqualTo []) then {""} else {"A field hospital crate is missing its expected action on this client - check the RPT for errors from Waldo_fnc_MedicalCrateFacilityActionLocal."}] call _add;
};

private _lastRestore = missionNamespace getVariable ["Waldo_Player_LastRespawnRestore", []];
if (count _lastRestore < 3) then {
    ["respawn", "loadout-restore", "UNCONFIGURED", "This client has not respawned yet this session; nothing to report."] call _add;
} else {
    _lastRestore params ["_restoreIdentityMatched", "_restoreCount", "_restoreTickTime"];
    ["respawn", "loadout-restore", if (_restoreIdentityMatched) then {"ACTIVE"} else {"ERROR"}, format ["identityMatched=%1 restoredEntries=%2 secondsAgo=%3", _restoreIdentityMatched, _restoreCount, round (diag_tickTime - _restoreTickTime)], if (_restoreIdentityMatched) then {""} else {"The last respawn's saved-loadout identity (UID+side) did not match this player - the mission-start baseline was applied instead. Check the RPT for the matching [WMP LOADOUT] line, and confirm Waldo_Player_LoadoutIdentity/Waldo_Player_Inventory are being set by Waldo_fnc_SaveLoadout."}] call _add;
};

// Known upstream ACE3 issue, not a WMP defect: ace_nametags/ace_dogtags' own config-based "respawn"
// event handler (CfgEventHandlers.hpp: respawn = QUOTE(call FUNC(setName));) forwards the engine's
// [unit, corpse] respawn params wholesale into ace_common_fnc_setName, whose second parameter
// (_forceSet) has no type guard - the corpse Object lands there and the function throws "Type
// Object, expected Bool" on every scripted respawn. This is informational only: WMP calls neither
// ace_common_fnc_setName nor sets ace_setCustomName anywhere, and there is no mission-side fix short
// of overriding ACE's own config event handler, so this check never carries a "fix" hint.
private _nametagsLoaded = isClass (configFile >> "CfgPatches" >> "ace_nametags");
private _dogtagsLoaded = isClass (configFile >> "CfgPatches" >> "ace_dogtags");
if (_nametagsLoaded || _dogtagsLoaded) then {
    ["dependencies", "ace-nametags-respawn-compat", "LOADED", format ["nametags=%1 dogtags=%2 - a harmless 'Type Object, expected Bool' error from ace/addons/common/functions/fnc_setName.sqf on respawn is a known upstream ACE3 issue in its own config-based respawn handler, not a WMP defect; ACE's separate PlayerChanged hook still names the unit correctly.", _nametagsLoaded, _dogtagsLoaded]] call _add;
};

private _warnings = {_x select 2 == "ERROR"} count _checks;
["core", "diagnostics", "INFO", "END", format ["checks=%1 errors=%2", count _checks, _warnings], _runId, format ["CLIENT:%1", clientOwner]] call Waldo_fnc_DiagnosticLog;
[_runId, clientOwner, name player, getPlayerUID player, _checks] remoteExecCall ["Waldo_fnc_DiagnosticsReceiveClient", 2];
true
