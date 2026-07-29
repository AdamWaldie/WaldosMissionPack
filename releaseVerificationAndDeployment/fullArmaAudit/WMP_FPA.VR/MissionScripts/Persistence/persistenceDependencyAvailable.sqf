/*
 * Author: Waldo
 * Loads and validates the optional INIDBI2 runtime used by WMP persistence.
 * The probe runs only on the server and supports alternate init paths and patch names.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Boolean - true when the server can call the INIDBI2 native extension
 *
 * Example:
 * [] call Waldo_fnc_PersistenceDependencyAvailable;
 */

if !(isServer) exitWith {false};

private _customProbe = missionNamespace getVariable ["Waldo_Persistence_DependencyProbe", {false}];
if (_customProbe isEqualType {}) then {call _customProbe};

private _patchNames = missionNamespace getVariable [
    "Waldo_Persistence_PatchNames",
    ["inidbi2", "inidbi2_main", "inidbi2_core", "inidbi"]
];
private _patchFound = _patchNames findIf {isClass (configFile >> "CfgPatches" >> _x)} >= 0;
private _initPath = missionNamespace getVariable ["Waldo_Persistence_InitPath", "\inidbi2\init.sqf"];

if (isNil "OO_INIDBI" && {_initPath != ""} && {_patchFound || {missionNamespace getVariable ["Waldo_Persistence_ForceInitPath", false]}}) then {
    call compile preprocessFileLineNumbers _initPath;
};

if (isNil "OO_INIDBI") exitWith {false};

// A loaded SQF wrapper or client-visible CfgPatches entry does not prove that the
// dedicated server loaded the DLL. getVersion performs a harmless native call.
private _probeName = missionNamespace getVariable ["Waldo_Persistence_ProbeDatabaseName", "WMP_RUNTIME_PROBE"];
private _probeDb = ["new", _probeName] call OO_INIDBI;
if !(_probeDb isEqualType {}) exitWith {false};
private _version = "getVersion" call _probeDb;
["delete", _probeDb] call OO_INIDBI;
private _versionText = if (_version isEqualType "") then {toLowerANSI _version} else {""};
private _dllIndex = _versionText find "dll:";
private _dllVersion = if (_dllIndex >= 0) then {[(_versionText select [_dllIndex + 4])] call BIS_fnc_trimString} else {""};
_versionText != ""
    && {_versionText find "error" < 0}
    && {_versionText find "not found" < 0}
    && {_versionText find "inidbi" >= 0}
    && {_dllVersion != ""}
