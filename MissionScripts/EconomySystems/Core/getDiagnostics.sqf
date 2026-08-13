/*
 * Author: WaldoTheWarfighter
 * Returns normalized Economy diagnostics for the core runtime, catalogues and placed registries.
 * Read-only and repeat-safe. Runs wherever diagnostics request it; it does not change economy state.
 *
 * Arguments: None.
 * Return Value: ARRAY of WMP diagnostic rows.
 * Current caller: Waldo_fnc_RunDiagnostics.
 *
 * Example:
 * private _rows = [] call Waldo_fnc_EcoCore_getDiagnostics;
 * Result: `_rows` describes disabled, active, unconfigured and invalid economy state.
 */
private _enabled = missionNamespace getVariable ["Waldo_Economy_Enable", false];
private _active = missionNamespace getVariable ["WaldoEcoCore_ModuleActive", false];
private _coreDetail = format ["configured=%1 active=%2 commitment=%3", _enabled, _active, missionNamespace getVariable ["WaldoEcoCore_CommitmentMode", false]];
if (_enabled && {!_active}) then {_coreDetail = [_coreDetail, "Waldo_Economy_Enable is true but Waldo_fnc_EcoInit never completed - confirm MissionConfig\missionSystemsConfig.sqf enables it, then check the RPT for [WMP ECO] errors."] call Waldo_fnc_DiagnosticFoldHint;};
private _checks = [
    ["economy", "core", if (!_enabled) then {"DISABLED"} else {if (_active) then {"ACTIVE"} else {"ERROR"}}, _coreDetail]
];

{
    _x params ["_name", "_variable"];
    private _loaded = missionNamespace getVariable [_variable, false];
    private _subDetail = format ["initialised=%1 variable=%2", _loaded, _variable];
    if (_enabled && {!_loaded}) then {_subDetail = [_subDetail, format ["The %1 sub-system did not finish initialising - check the RPT for [WMP ECO] errors during Waldo_fnc_EcoInit's startup.", _name]] call Waldo_fnc_DiagnosticFoldHint;};
    _checks pushBack ["economy", _name, if (!_enabled) then {"DISABLED"} else {if (_loaded) then {"LOADED"} else {"ERROR"}}, _subDetail];
} forEach [
    ["resources", "WaldoEcoResource_SystemInitialized"],
    ["research", "WaldoEcoResearch_SystemInitialized"],
    ["construction", "WaldoEcoBuild_SystemInitialized"],
    ["purchases", "WaldoEcoBuy_SystemInitialized"]
];

private _resources = missionNamespace getVariable ["WaldoEcoResource_ResourceCatalog", []];
private _research = missionNamespace getVariable ["WaldoEcoResearch_ResearchCatalog", []];
private _build = missionNamespace getVariable ["WaldoEcoBuild_BuildCatalog", []];
private _buy = missionNamespace getVariable ["WaldoEcoBuy_PurchaseCatalog", []];
private _invalidBuild = _build select {
    private _className = _x param [8, ""];
    _className isEqualTo "" || {!(isClass (configFile >> "CfgVehicles" >> _className))}
};
private _invalidBuy = _buy select {
    private _className = _x param [4, ""];
    _className isEqualTo "" || {!(isClass (configFile >> "CfgVehicles" >> _className))}
};
_checks pushBack ["economy", "catalogs", if (_resources isEqualTo [] && {_research isEqualTo [] && {_build isEqualTo [] && {_buy isEqualTo []}}}) then {"UNCONFIGURED"} else {"LOADED"}, format ["resources=%1 research=%2 build=%3 purchases=%4", count _resources, count _research, count _build, count _buy]];
private _buildDetail = format ["entries=%1 invalidCfgVehicles=%2", count _build, _invalidBuild apply {_x param [0, "UNNAMED"]}];
if !(_invalidBuild isEqualTo []) then {_buildDetail = [_buildDetail, "One or more build catalogue entries reference a CfgVehicles class that doesn't exist - fix the classname in that entry's build definition (MissionConfig\economyConfig.sqf or the ZEN Build Setup Builder)."] call Waldo_fnc_DiagnosticFoldHint;};
_checks pushBack ["economy", "economy-build-classes", if (!(_invalidBuild isEqualTo [])) then {"ERROR"} else {if (_build isEqualTo []) then {"UNCONFIGURED"} else {"LOADED"}}, _buildDetail];
private _buyDetail = format ["entries=%1 invalidCfgVehicles=%2", count _buy, _invalidBuy apply {_x param [0, "UNNAMED"]}];
if !(_invalidBuy isEqualTo []) then {_buyDetail = [_buyDetail, "One or more purchase catalogue entries reference a CfgVehicles class that doesn't exist - fix the classname in that entry's purchase definition (MissionConfig\economyConfig.sqf or the ZEN Purchasing Setup Builder)."] call Waldo_fnc_DiagnosticFoldHint;};
_checks pushBack ["economy", "economy-purchase-classes", if (!(_invalidBuy isEqualTo [])) then {"ERROR"} else {if (_buy isEqualTo []) then {"UNCONFIGURED"} else {"LOADED"}}, _buyDetail];
_checks pushBack ["economy", "runtime-registries", if (!_active) then {"DISABLED"} else {"LOADED"}, format ["zones=%1 buildings=%2 dropPoints=%3", count (missionNamespace getVariable ["WaldoEcoResource_ResourceZones", []]), count (missionNamespace getVariable ["WaldoEcoBuild_SpawnedBuildings", []]), count (missionNamespace getVariable ["WaldoEcoBuy_DropPoints", []])]];

if (hasInterface) then {
    private _display = uiNamespace getVariable ["WaldoEcoCore_ActiveZeusPromptDisplay", displayNull];
    private _findings = if (isNull _display) then {[]} else {_display getVariable ["WaldoEcoCore_FitFindings", []]};
    private _promptDetail = format ["open=%1 fitComplete=%2 findings=%3", !isNull _display, !isNull _display && {_display getVariable ["WaldoEcoCore_FitComplete", false]}, _findings];
    if !(_findings isEqualTo []) then {_promptDetail = [_promptDetail, "The open Economy authoring dialog reported layout findings - close and reopen it; if this persists, check the RPT for Waldo_fnc_EcoCore_fitPromptDisplay errors."] call Waldo_fnc_DiagnosticFoldHint;};
    _checks pushBack ["world-ui", "economy-authoring-prompt", if (!(_findings isEqualTo [])) then {"ERROR"} else {if (isNull _display) then {"LOADED"} else {"ACTIVE"}}, _promptDetail];
};

["economy", _checks] call Waldo_fnc_DiagnosticFeatureReport
