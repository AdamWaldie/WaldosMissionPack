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
private _add = {
    params ["_area", "_feature", "_state", ["_detail", ""]];
    _checks pushBack [_area, _feature, _state, _detail];
    [_area, _feature, if (_state == "ERROR") then {"ERROR"} else {"INFO"}, "CHECK", format ["state=%1 detail=%2", _state, _detail], _runId, format ["CLIENT:%1", clientOwner]] call Waldo_fnc_DiagnosticLog;
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
    ["dependencies", _label, if (_loaded) then {"LOADED"} else {if (_required) then {"ERROR"} else {"UNAVAILABLE"}}, format ["required=%1 patch=%2", _required, _patch]] call _add;
} forEach [
    ["cba_main", "CBA_A3", true],
    ["ace_main", "ACE3", true],
    ["zen_main", "ZEN", false],
    ["acre_main", "ACRE2", false],
    ["task_force_radio", "TFAR", false]
];

[call Waldo_fnc_SafeStartGetDiagnostics] call _consumeFeatureReport;
[call Waldo_fnc_ENDEXGetDiagnostics] call _consumeFeatureReport;
[call Waldo_fnc_EcoCore_getDiagnostics] call _consumeFeatureReport;

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
    ["radio", "acre-player-presetting", _state, format ["finding=%1 rawGroup='%2' normalized=%3 side=%4 planRevision=%5 sideMatch=%6 groupMatch=%7 inventoryRadios=%8 currentRadios=%9 unique=%10 acreReady=%11 edenRadioSetup=%12 loadoutGeneration=%13 restoredGeneration=%14 lastApplication=%15 readinessFailure=%16", _plainFinding, _rawGroup, _groupKey, _sideKey, if (_planValid) then {_plan select 1} else {-1}, _sideIndex >= 0, _groupIndex >= 0, _inventoryRadios, _radios, count _unique, _acreApiReady, _edenRadioSetup, missionNamespace getVariable ["Waldo_ACRE2_LoadoutGeneration", -1], missionNamespace getVariable ["Waldo_ACRE2_RestoredRadioGeneration", -1], _last, missionNamespace getVariable ["Waldo_ACRE2_LastReadinessFailure", []]]] call _add;
    if !(_edenRadioSetup isEqualTo "") then {
        ["radio", "acre-eden-radio-attribute", "ERROR", format ["This unit has an Eden ACRE Radio Setup attribute (%1). It can overwrite acreConfig.sqf during startup. Clear that unit attribute and let WMP own the initial assignment.", _edenRadioSetup]] call _add;
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
private _jamClientState = if (!_jamEnabled) then {"DISABLED"} else {
    if (!_jamHudOk || {!_jamLoopRunning}) then {"ERROR"} else {if (_jamFactor > 0) then {"ACTIVE"} else {"LOADED"}}
};
["electronic-warfare", "jamming-client", _jamClientState, format ["factor=%1 registry=%2 loop=%3 hud=%4", _jamFactor, count (missionNamespace getVariable ["Waldo_Jamming_Registry", []]), _jamLoopRunning, !isNull _jamCtrl && {ctrlShown _jamCtrl}]] call _add;

private _zenLoaded = isClass (configFile >> "CfgPatches" >> "zen_main");
["zeus", "core-modules", if (!_zenLoaded) then {"UNAVAILABLE"} else {if ((missionNamespace getVariable ["Waldo_ZenModuleCount", 0]) == 43) then {"LOADED"} else {"ERROR"}}, format ["registered=%1 expected=43", missionNamespace getVariable ["Waldo_ZenModuleCount", 0]]] call _add;
private _economyActive = missionNamespace getVariable ["WaldoEcoCore_ModuleActive", false];
["zeus", "economy-modules", if (!_economyActive) then {"DISABLED"} else {if ((missionNamespace getVariable ["WaldoEcoCore_ZenModuleCount", 0]) == 19) then {"LOADED"} else {"ERROR"}}, format ["registered=%1 expected=19", missionNamespace getVariable ["WaldoEcoCore_ZenModuleCount", 0]]] call _add;

private _markerHandler = missionNamespace getVariable ["Waldo_3DMarker_DrawHandler", -1];
["world-ui", "custom-3d-markers", if (_markerHandler >= 0) then {"LOADED"} else {"UNAVAILABLE"}, format ["drawHandler=%1 markers=%2", _markerHandler, count (missionNamespace getVariable ["Waldo_3DMarker_Registry", []])]] call _add;

private _interactionObjects = missionNamespace getVariable ["Waldo_QA_InteractionObjects", []];
[[_interactionObjects] call Waldo_fnc_MiniGameInteractionGetDiagnostics] call _consumeFeatureReport;

private _aceInteractLoaded = isClass (configFile >> "CfgPatches" >> "ace_interact_menu");
private _localObjects = allMissionObjects "All";
private _tacticalDisplays = _localObjects select {_x getVariable ["Waldo_TacticalDisplay_Registered", false]};
private _missingTacticalActions = _tacticalDisplays select {(_x getVariable ["Waldo_TacticalDisplay_LocalAction", -1]) < 0};
["interface", "tactical-display-actions", if (_tacticalDisplays isEqualTo []) then {"UNCONFIGURED"} else {if (_missingTacticalActions isEqualTo []) then {"LOADED"} else {"ERROR"}}, format ["registered=%1 missingLocalAction=%2", count _tacticalDisplays, count _missingTacticalActions]] call _add;
private _hazardEnabled = missionNamespace getVariable ["Waldo_Hazard_Enable", false];
private _hazardZones = missionNamespace getVariable ["Waldo_Hazard_Zones", []];
private _hazardClient = missionNamespace getVariable ["Waldo_Hazard_ClientStarted", false];
private _hazardEvaluation = missionNamespace getVariable ["Waldo_Hazard_LastEvaluation", []];
private _hazardFresh = count _hazardEvaluation >= 3 && {(diag_tickTime - (_hazardEvaluation select 0)) <= ((missionNamespace getVariable ["Waldo_Hazard_Interval", 1]) max 0.25) * 3};
["environment", "hazard-client", if (!_hazardEnabled) then {"DISABLED"} else {if (_hazardClient && {!(_hazardZones isEqualTo [])} && {_hazardFresh}) then {"ACTIVE"} else {"ERROR"}}, format ["enabled=%1 zones=%2 snapshot=%3 evaluator=%4 freshEvaluation=%5 lastEvaluation=%6", _hazardEnabled, count _hazardZones, missionNamespace getVariable ["Waldo_Hazard_SnapshotReceived", false], _hazardClient, _hazardFresh, _hazardEvaluation]] call _add;
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
    ["logistics", "mhq-actions", if (_mhqValid) then {"LOADED"} else {"ERROR"}, format ["objects=%1 expectedMode=%2", count _mhqObjects, if (_aceInteractLoaded) then {"ACE"} else {"VANILLA"}]] call _add;
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
    ["logistics", "vvd-actions", if (_vvdValid) then {"LOADED"} else {"ERROR"}, format ["terminals=%1 expectedMode=%2", count _vvdTerminals, if (_aceInteractLoaded) then {"ACE"} else {"VANILLA"}]] call _add;
};

private _warnings = {_x select 2 == "ERROR"} count _checks;
["core", "diagnostics", "INFO", "END", format ["checks=%1 errors=%2", count _checks, _warnings], _runId, format ["CLIENT:%1", clientOwner]] call Waldo_fnc_DiagnosticLog;
[_runId, clientOwner, name player, getPlayerUID player, _checks] remoteExecCall ["Waldo_fnc_DiagnosticsReceiveClient", 2];
true
