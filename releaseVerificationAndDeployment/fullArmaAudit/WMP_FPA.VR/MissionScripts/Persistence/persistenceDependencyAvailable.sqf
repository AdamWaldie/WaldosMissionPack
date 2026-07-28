/*
 * Author: Waldo
 * Loads and validates the optional INIDBI2 runtime used by WMP persistence.
 * The probe runs only on the server and supports alternate init paths and patch names.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Boolean - true when OO_INIDBI is callable
 *
 * Example:
 * [] call Waldo_fnc_PersistenceDependencyAvailable;
 */

if !(isServer) exitWith {false};
if !(isNil "OO_INIDBI") exitWith {true};

private _customProbe = missionNamespace getVariable ["Waldo_Persistence_DependencyProbe", {false}];
if (_customProbe isEqualType {} && {call _customProbe} && {!(isNil "OO_INIDBI")}) exitWith {true};

private _patchNames = missionNamespace getVariable [
    "Waldo_Persistence_PatchNames",
    ["inidbi2", "inidbi2_main", "inidbi2_core", "inidbi"]
];
private _patchFound = _patchNames findIf {isClass (configFile >> "CfgPatches" >> _x)} >= 0;
private _initPath = missionNamespace getVariable ["Waldo_Persistence_InitPath", "\inidbi2\init.sqf"];

if (_initPath != "" && {_patchFound || {missionNamespace getVariable ["Waldo_Persistence_ForceInitPath", false]}}) then {
    call compile preprocessFileLineNumbers _initPath;
};

!(isNil "OO_INIDBI")
