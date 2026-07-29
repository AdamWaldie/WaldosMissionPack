/* Collects one interface client's diagnostic state and returns it to server authority. */
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
["zeus", "core-modules", if (!_zenLoaded) then {"UNAVAILABLE"} else {if ((missionNamespace getVariable ["Waldo_ZenModuleCount", 0]) == 36) then {"LOADED"} else {"ERROR"}}, format ["registered=%1 expected=36", missionNamespace getVariable ["Waldo_ZenModuleCount", 0]]] call _add;
private _economyActive = missionNamespace getVariable ["WaldoEcoCore_ModuleActive", false];
["zeus", "economy-modules", if (!_economyActive) then {"DISABLED"} else {if ((missionNamespace getVariable ["WaldoEcoCore_ZenModuleCount", 0]) == 19) then {"LOADED"} else {"ERROR"}}, format ["registered=%1 expected=19", missionNamespace getVariable ["WaldoEcoCore_ZenModuleCount", 0]]] call _add;

private _markerHandler = missionNamespace getVariable ["Waldo_3DMarker_DrawHandler", -1];
["world-ui", "custom-3d-markers", if (_markerHandler >= 0) then {"LOADED"} else {"UNAVAILABLE"}, format ["drawHandler=%1 markers=%2", _markerHandler, count (missionNamespace getVariable ["Waldo_3DMarker_Registry", []])]] call _add;

private _interactionObjects = missionNamespace getVariable ["Waldo_QA_InteractionObjects", []];
[[_interactionObjects] call Waldo_fnc_MiniGameInteractionGetDiagnostics] call _consumeFeatureReport;

private _aceInteractLoaded = isClass (configFile >> "CfgPatches" >> "ace_interact_menu");
private _localObjects = allMissionObjects "All";
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
