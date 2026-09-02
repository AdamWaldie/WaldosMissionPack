/*
 * Author: WaldoTheWarfighter
 * Resolves validated local WMP HUD presentation preferences. These values can only suppress an
 * already mission-permitted element or multiply mission-authored scale/opacity; they never widen
 * ranges, reveal restricted units, bypass LOS, equipment, UID exclusions or other eligibility.
 * Cached local state is repeat/JIP safe and is rebuilt from profile defaults when absent.
 *
 * Arguments: None.
 * Return Value: HASHMAP with showIcons, showNames, scale and opacity presentation values.
 * Current callers: WmpHudInit Draw3D handler and WMP HUD settings screen.
 * Example: private _preferences = [] call Waldo_fnc_WmpHudPreferences;
 */

private _cached = missionNamespace getVariable ["Waldo_WmpHud_PlayerPreferencesLocal", createHashMap];
if (typeName _cached == "HASHMAP" && {count _cached > 0}) exitWith {_cached};
private _saved = profileNamespace getVariable ["Waldo_WmpHud_PlayerPreferences", [true, true, "MEDIUM", "MEDIUM"]];
if !(_saved isEqualType []) then {_saved = [true, true, "MEDIUM", "MEDIUM"];};
private _showIcons = _saved param [0, true, [true]];
private _showNames = _saved param [1, true, [true]];
private _scaleId = toUpperANSI (_saved param [2, "MEDIUM", [""]]);
private _opacityId = toUpperANSI (_saved param [3, "MEDIUM", [""]]);
if !(_scaleId in ["SMALL", "MEDIUM", "LARGE"]) then {_scaleId = "MEDIUM";};
if !(_opacityId in ["LOW", "MEDIUM", "HIGH"]) then {_opacityId = "MEDIUM";};
private _resolved = createHashMapFromArray [
    ["showIcons", _showIcons], ["showNames", _showNames], ["scaleId", _scaleId], ["opacityId", _opacityId],
    ["scale", switch (_scaleId) do {case "SMALL": {0.82}; case "LARGE": {1.18}; default {1};}],
    ["opacity", switch (_opacityId) do {case "LOW": {0.55}; case "HIGH": {1}; default {0.82};}]
];
missionNamespace setVariable ["Waldo_WmpHud_PlayerPreferencesLocal", _resolved];
_resolved
