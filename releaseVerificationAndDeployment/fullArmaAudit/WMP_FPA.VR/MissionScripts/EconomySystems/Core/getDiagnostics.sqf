/* Author: WaldoTheWarfighter. Returns normalized Economy diagnostics. */
private _enabled = missionNamespace getVariable ["Waldo_Economy_Enable", false];
private _active = missionNamespace getVariable ["WaldoEcoCore_ModuleActive", false];
private _checks = [
    ["economy", "core", if (!_enabled) then {"DISABLED"} else {if (_active) then {"ACTIVE"} else {"ERROR"}}, format ["configured=%1 active=%2 commitment=%3", _enabled, _active, missionNamespace getVariable ["WaldoEcoCore_CommitmentMode", false]]]
];

{
    _x params ["_name", "_variable"];
    private _loaded = missionNamespace getVariable [_variable, false];
    _checks pushBack ["economy", _name, if (!_enabled) then {"DISABLED"} else {if (_loaded) then {"LOADED"} else {"ERROR"}}, format ["initialised=%1 variable=%2", _loaded, _variable]];
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
_checks pushBack ["economy", "economy-build-classes", if (!(_invalidBuild isEqualTo [])) then {"ERROR"} else {if (_build isEqualTo []) then {"UNCONFIGURED"} else {"LOADED"}}, format ["entries=%1 invalidCfgVehicles=%2", count _build, _invalidBuild apply {_x param [0, "UNNAMED"]}]];
_checks pushBack ["economy", "economy-purchase-classes", if (!(_invalidBuy isEqualTo [])) then {"ERROR"} else {if (_buy isEqualTo []) then {"UNCONFIGURED"} else {"LOADED"}}, format ["entries=%1 invalidCfgVehicles=%2", count _buy, _invalidBuy apply {_x param [0, "UNNAMED"]}]];
_checks pushBack ["economy", "runtime-registries", if (!_active) then {"DISABLED"} else {"LOADED"}, format ["zones=%1 buildings=%2 dropPoints=%3", count (missionNamespace getVariable ["WaldoEcoResource_ResourceZones", []]), count (missionNamespace getVariable ["WaldoEcoBuild_SpawnedBuildings", []]), count (missionNamespace getVariable ["WaldoEcoBuy_DropPoints", []])]];

if (hasInterface) then {
    private _display = uiNamespace getVariable ["WaldoEcoCore_ActiveZeusPromptDisplay", displayNull];
    private _findings = if (isNull _display) then {[]} else {_display getVariable ["WaldoEcoCore_FitFindings", []]};
    _checks pushBack ["world-ui", "economy-authoring-prompt", if (!(_findings isEqualTo [])) then {"ERROR"} else {if (isNull _display) then {"LOADED"} else {"ACTIVE"}}, format ["open=%1 fitComplete=%2 findings=%3", !isNull _display, !isNull _display && {_display getVariable ["WaldoEcoCore_FitComplete", false]}, _findings]];
};

["economy", _checks] call Waldo_fnc_DiagnosticFeatureReport
