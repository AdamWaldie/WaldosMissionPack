/*
 * Author: WaldoTheWarfighter
 * Opens the user-facing ZEN QA selector for changing the global WMP visual theme during play.
 * The selector exposes named variants only and delegates authority, broadcast and JIP state to the
 * server. It is intended for visual QA and mission-author verification, not feature configuration.
 *
 * Arguments:
 * None (ZEN module position/object payload is intentionally ignored).
 *
 * Return Value: Nothing.
 *
 * Example: [] call Waldo_fnc_UiThemeZen;
 * Current caller: UI QA - Set Visual Theme in Zen_initModules.sqf.
 */

if !(hasInterface && {isClass (configFile >> "CfgPatches" >> "zen_dialog")}) exitWith {};
private _ids = ["DEFAULT", "WW2", "VIETNAM", "SCIFI", "PARCHMENT", "MINIMAL", "NAVAL", "DESERT_STORM", "INDUSTRIAL", "EASTERN_BLOC", "INTELLIGENCE", "EMERGENCY"];
private _labels = ["Default / Modern", "Second World War", "Vietnam / Cold War", "Science Fiction", "Parchment / Fantasy", "Minimal / Low Profile", "Naval / Combat Information Centre", "Desert Storm / CENTCOM", "Industrial / Operations Control", "Eastern Bloc / Sector Control", "Intelligence / Restricted", "Emergency / Incident Command"];
private _current = toUpperANSI (missionNamespace getVariable ["Waldo_UI_Theme", "DEFAULT"]);
private _defaultIndex = _ids find _current;
if (_defaultIndex < 0) then {_defaultIndex = 0;};
[
    "UI QA - Set Visual Theme",
    [
        ["COMBO", ["Visual style", "Changes presentation globally without changing feature behavior."], [_ids, _labels, _defaultIndex]],
        ["CHECKBOX", ["Show preview cards", "Show the requesting curator semantic colours and three-lane stacking."], true]
    ],
    {
        params ["_values"];
        _values params ["_themeId", "_preview"];
        [_themeId, _preview] remoteExecCall ["Waldo_fnc_UiThemeSetServer", 2];
    },
    {}
] call zen_dialog_fnc_create;
