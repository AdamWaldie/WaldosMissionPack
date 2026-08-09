/*
 * Author: WaldoTheWarfighter
 * Applies a validated WMP UI theme id on one machine and optionally renders a three-lane preview.
 * It changes presentation state only. Active notifications are re-rendered in place; tagged
 * interaction, party-game and Economy displays receive refreshed cached theme tokens and generic
 * control styling. Service-driven HUD panels resolve the new theme on their next update.
 *
 * Arguments:
 * 0: theme id <STRING>
 * 1: show local preview <BOOL> (default false)
 *
 * Return Value: BOOL - true when the theme id was accepted.
 *
 * Example: ["SCIFI", true] call Waldo_fnc_UiThemeApplyLocal;
 * Current callers: UiThemeSetServer and local colour-vision profile changes.
 */

params [["_themeId", "DEFAULT", [""]], ["_preview", false, [true]]];
private _resolved = [_themeId] call Waldo_fnc_UiTheme;
if ((_resolved getOrDefault ["id", "DEFAULT"]) != toUpperANSI _themeId) exitWith {false};
missionNamespace setVariable ["Waldo_UI_Theme", toUpperANSI _themeId];
uiNamespace setVariable ["Waldo_UI_ResolvedTheme", _resolved];
{
    if (!isNull _x && {_x getVariable ["Waldo_UI_ThemedDisplay", false]}) then {
        private _equipmentProfile = _x getVariable ["Waldo_IMG_Profile", createHashMap];
        if (typeName _equipmentProfile == "HASHMAP") then {
            _equipmentProfile set ["uiTheme", _resolved];
            private _accessibility = _equipmentProfile getOrDefault ["accessibility", createHashMap];
            if (_accessibility getOrDefault ["highContrast", false]) then {
                _equipmentProfile set ["casing", [0.035, 0.04, 0.04, 1]];
                _equipmentProfile set ["accent", [0.96, 0.78, 0.20, 1]];
            } else {
                _equipmentProfile set ["casing", _resolved getOrDefault ["casing", [0.16, 0.17, 0.14, 1]]];
                _equipmentProfile set ["accent", _resolved getOrDefault ["accent", [0.76, 0.55, 0.16, 1]]];
            };
            _x setVariable ["Waldo_IMG_Profile", _equipmentProfile];
        };
        _x setVariable ["Waldo_IMG_PickerTheme", _resolved];
        _x setVariable ["WaldoEcoCore_PromptTheme", _resolved];
        [_x, true] call Waldo_fnc_UiThemeApplyDisplayLocal;
    };
} forEach allDisplays;
if (!isNil "Waldo_fnc_RestyleUiNotificationsLocal") then {[] call Waldo_fnc_RestyleUiNotificationsLocal;};
if (_preview && {hasInterface}) then {
    private _label = _resolved getOrDefault ["label", _themeId];
    ["THEME ACTIVE", format ["%1 presentation is now active.", _label], "INFO", 10, "TOP_RIGHT", "UI_THEME_QA_1", "WMP UI QA", "REPLACE"] call Waldo_fnc_ShowUiNotification;
    ["SEMANTIC SUCCESS", "Layout and feature behavior remain unchanged.", "SUCCESS", 10, "TOP_RIGHT", "UI_THEME_QA_2", "WMP UI QA", "REPLACE"] call Waldo_fnc_ShowUiNotification;
    ["SEMANTIC WARNING", "Check contrast, font readability and three-lane stacking.", "WARNING", 10, "TOP_RIGHT", "UI_THEME_QA_3", "WMP UI QA", "REPLACE"] call Waldo_fnc_ShowUiNotification;
};
diag_log format [
    "[WMP UI] Visual theme applied locally: theme=%1 revision=%2 owner=%3 preview=%4.",
    toUpperANSI _themeId, missionNamespace getVariable ["Waldo_UI_ThemeRevision", 0], clientOwner, _preview
];
true
