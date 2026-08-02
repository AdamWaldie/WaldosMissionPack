/*
 * Author: WaldoTheWarfighter
 * Resolves the active visual-only WMP UI theme. The built-in DEFAULT, WW2, VIETNAM and SCIFI
 * variants share the same control geometry and behavior; only fonts, colours and surface treatment
 * change. Missions may extend the catalogue with Waldo_UI_CustomThemes and adjust the selected
 * theme through Waldo_UI_ThemeOverrides without editing feature UI functions.
 *
 * Arguments:
 * 0: theme id <STRING> (default missionNamespace Waldo_UI_Theme)
 *
 * Return Value: HASHMAP - validated presentation tokens used by WMP UI consumers.
 *
 * Example:
 * private _theme = ["VIETNAM"] call Waldo_fnc_UiTheme;
 * Current callers: notification, SafeStart, EW, tactical-display, interaction-equipment and
 * Economy UI constructors, plus the live QA theme switch.
 */

params [["_requested", missionNamespace getVariable ["Waldo_UI_Theme", "DEFAULT"], [""]]];
private _id = toUpperANSI _requested;
private _themes = createHashMapFromArray [
    ["DEFAULT", createHashMapFromArray [
        ["id", "DEFAULT"], ["label", "Default / Modern"], ["font", "RobotoCondensed"], ["fontBold", "RobotoCondensedBold"],
        ["shade", [0, 0, 0, 0.72]], ["panel", [0.012, 0.020, 0.028, 0.94]], ["panelAlt", [0.045, 0.050, 0.045, 0.99]],
        ["header", [0.025, 0.20, 0.36, 0.99]], ["casing", [0.16, 0.17, 0.15, 1]], ["accent", [0.10, 0.38, 0.66, 1]],
        ["accentActive", [0.10, 0.48, 0.76, 1]], ["text", [1, 1, 1, 1]], ["muted", [0.62, 0.70, 0.78, 1]],
        ["success", [0.18, 0.66, 0.45, 1]], ["warning", [0.88, 0.60, 0.12, 1]], ["danger", [0.78, 0.15, 0.20, 1]],
        ["textHex", "#FFFFFF"], ["mutedHex", "#9FB3C8"], ["accentHex", "#79C7FF"],
        ["successHex", "#6CE5A8"], ["warningHex", "#FFD166"], ["dangerHex", "#FF6161"]
    ]],
    ["WW2", createHashMapFromArray [
        ["id", "WW2"], ["label", "Second World War"], ["font", "EtelkaMonospacePro"], ["fontBold", "EtelkaMonospaceProBold"],
        ["shade", [0.025, 0.022, 0.014, 0.78]], ["panel", [0.105, 0.098, 0.064, 0.97]], ["panelAlt", [0.16, 0.15, 0.10, 0.99]],
        ["header", [0.25, 0.23, 0.13, 1]], ["casing", [0.18, 0.19, 0.12, 1]], ["accent", [0.70, 0.53, 0.21, 1]],
        ["accentActive", [0.86, 0.69, 0.31, 1]], ["text", [0.94, 0.90, 0.72, 1]], ["muted", [0.72, 0.69, 0.54, 1]],
        ["success", [0.40, 0.62, 0.32, 1]], ["warning", [0.82, 0.62, 0.22, 1]], ["danger", [0.68, 0.22, 0.16, 1]],
        ["textHex", "#F0E6B8"], ["mutedHex", "#B8B08A"], ["accentHex", "#D5B35A"],
        ["successHex", "#8FC776"], ["warningHex", "#E8BB54"], ["dangerHex", "#E66C54"]
    ]],
    ["VIETNAM", createHashMapFromArray [
        ["id", "VIETNAM"], ["label", "Vietnam / Cold War"], ["font", "RobotoCondensed"], ["fontBold", "RobotoCondensedBold"],
        ["shade", [0.008, 0.025, 0.012, 0.76]], ["panel", [0.035, 0.075, 0.040, 0.97]], ["panelAlt", [0.075, 0.105, 0.055, 0.99]],
        ["header", [0.12, 0.20, 0.09, 1]], ["casing", [0.10, 0.14, 0.075, 1]], ["accent", [0.76, 0.48, 0.14, 1]],
        ["accentActive", [0.92, 0.62, 0.20, 1]], ["text", [0.91, 0.87, 0.68, 1]], ["muted", [0.64, 0.68, 0.47, 1]],
        ["success", [0.36, 0.68, 0.32, 1]], ["warning", [0.90, 0.62, 0.18, 1]], ["danger", [0.78, 0.20, 0.15, 1]],
        ["textHex", "#E8DEAD"], ["mutedHex", "#A4AD78"], ["accentHex", "#E09A36"],
        ["successHex", "#79D16B"], ["warningHex", "#F0B143"], ["dangerHex", "#EF5D49"]
    ]],
    ["SCIFI", createHashMapFromArray [
        ["id", "SCIFI"], ["label", "Science Fiction"], ["font", "PuristaMedium"], ["fontBold", "PuristaSemibold"],
        ["shade", [0.002, 0.008, 0.022, 0.80]], ["panel", [0.006, 0.025, 0.055, 0.96]], ["panelAlt", [0.015, 0.055, 0.085, 0.99]],
        ["header", [0.025, 0.16, 0.25, 1]], ["casing", [0.018, 0.055, 0.085, 1]], ["accent", [0.08, 0.72, 0.90, 1]],
        ["accentActive", [0.25, 0.92, 1, 1]], ["text", [0.82, 0.96, 1, 1]], ["muted", [0.42, 0.70, 0.78, 1]],
        ["success", [0.12, 0.88, 0.62, 1]], ["warning", [0.96, 0.65, 0.12, 1]], ["danger", [0.96, 0.18, 0.48, 1]],
        ["textHex", "#D1F5FF"], ["mutedHex", "#6BB3C7"], ["accentHex", "#35D9F4"],
        ["successHex", "#35EDA5"], ["warningHex", "#FFB93A"], ["dangerHex", "#FF3B83"]
    ]]
];

private _custom = missionNamespace getVariable ["Waldo_UI_CustomThemes", createHashMap];
if (typeName _custom == "HASHMAP") then {
    {
        private _value = _custom get _x;
        if (typeName _value == "HASHMAP") then {_themes set [toUpperANSI _x, _value];};
    } forEach keys _custom;
};
if (isNil {_themes get _id}) then {_id = "DEFAULT";};
private _resolved = createHashMap;
private _base = _themes get _id;
{_resolved set [_x, _base get _x];} forEach keys _base;
_resolved set ["id", _id];

private _overrides = missionNamespace getVariable ["Waldo_UI_ThemeOverrides", createHashMap];
if (typeName _overrides == "HASHMAP") then {
    {
        if !(isNil {_resolved get _x}) then {
            private _current = _resolved get _x;
            private _candidate = _overrides get _x;
            if (typeName _candidate == typeName _current) then {_resolved set [_x, _candidate];};
        };
    } forEach keys _overrides;
};
_resolved
