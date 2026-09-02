/*
 * Author: WaldoTheWarfighter
 * Validates and profile-persists one player's WMP HUD presentation preferences. The choices only
 * remove mission-permitted icons/names or multiply mission scale/opacity, and cannot alter HUD
 * eligibility, information scope or mission restrictions. Repeated calls atomically replace the
 * local cache and are safe across respawn/JIP; HUD visibility is not changed.
 *
 * Arguments:
 * 0: show permitted icons <BOOL> (default true)
 * 1: show permitted names <BOOL> (default true)
 * 2: scale id <STRING> SMALL | MEDIUM | LARGE (default MEDIUM)
 * 3: opacity id <STRING> LOW | MEDIUM | HIGH (default MEDIUM)
 * 4: show confirmation <BOOL> (default true)
 * Return Value: BOOL - true when applied.
 * Current caller: WMP HUD Settings Apply button.
 * Example: [true, false, "SMALL", "HIGH", true] call Waldo_fnc_WmpHudSettingsApplyLocal;
 */

if (!hasInterface) exitWith {false};
params [["_showIcons", true, [true]], ["_showNames", true, [true]], ["_scaleId", "MEDIUM", [""]], ["_opacityId", "MEDIUM", [""]], ["_preview", true, [true]]];
_scaleId = toUpperANSI _scaleId;
_opacityId = toUpperANSI _opacityId;
if !(_scaleId in ["SMALL", "MEDIUM", "LARGE"] && {_opacityId in ["LOW", "MEDIUM", "HIGH"]}) exitWith {false};
profileNamespace setVariable ["Waldo_WmpHud_PlayerPreferences", [_showIcons, _showNames, _scaleId, _opacityId]];
saveProfileNamespace;
missionNamespace setVariable ["Waldo_WmpHud_PlayerPreferencesLocal", createHashMap];
[] call Waldo_fnc_WmpHudPreferences;
if (_preview) then {["WMP HUD", format ["Presentation saved: %1 scale, %2 opacity.", toLowerANSI _scaleId, toLowerANSI _opacityId], "INFO", "WMP_HUD_SETTINGS"] call Waldo_fnc_FeatureNotifyLocal;};
true
