/*
 * Author: WaldoTheWarfighter
 * Applies a validated WMP UI theme id on one machine and optionally renders a three-lane preview.
 * It changes presentation state only. Existing service-driven panels restyle on their next update;
 * newly opened displays resolve the theme immediately.
 *
 * Arguments:
 * 0: theme id <STRING>
 * 1: show local preview <BOOL> (default false)
 *
 * Return Value: BOOL - true when the theme id was accepted.
 *
 * Example: ["SCIFI", true] call Waldo_fnc_UiThemeApplyLocal;
 * Current caller: UiThemeSetServer after a curator changes the global QA theme.
 */

params [["_themeId", "DEFAULT", [""]], ["_preview", false, [true]]];
private _resolved = [_themeId] call Waldo_fnc_UiTheme;
if ((_resolved getOrDefault ["id", "DEFAULT"]) != toUpperANSI _themeId) exitWith {false};
missionNamespace setVariable ["Waldo_UI_Theme", toUpperANSI _themeId];
uiNamespace setVariable ["Waldo_UI_ResolvedTheme", _resolved];
{
    if (!isNull _x && {_x getVariable ["Waldo_UI_ThemedDisplay", false]}) then {
        [_x, true] call Waldo_fnc_UiThemeApplyDisplayLocal;
    };
} forEach allDisplays;
if (_preview && {hasInterface}) then {
    private _label = _resolved getOrDefault ["label", _themeId];
    ["THEME ACTIVE", format ["%1 presentation is now active.", _label], "INFO", 10, "TOP_RIGHT", "UI_THEME_QA_1", "WMP UI QA", "REPLACE"] call Waldo_fnc_ShowUiNotification;
    ["SEMANTIC SUCCESS", "Layout and feature behavior remain unchanged.", "SUCCESS", 10, "TOP_RIGHT", "UI_THEME_QA_2", "WMP UI QA", "REPLACE"] call Waldo_fnc_ShowUiNotification;
    ["SEMANTIC WARNING", "Check contrast, font readability and three-lane stacking.", "WARNING", 10, "TOP_RIGHT", "UI_THEME_QA_3", "WMP UI QA", "REPLACE"] call Waldo_fnc_ShowUiNotification;
};
true
