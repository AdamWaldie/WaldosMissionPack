/*
 * Author: WaldoTheWarfighter
 * Resolves the mission-wide WMP era theme and overlays the current player's colour-vision profile.
 * DEFAULT, WW2, VIETNAM, SCIFI and PARCHMENT have distinct typography, materials, rails, control
 * chrome and copy motifs while retaining identical feature behavior. Missions may extend Waldo_UI_CustomThemes
 * and Waldo_UI_ThemeOverrides; accessibility semantic overrides are applied last and locally.
 *
 * Arguments:
 * 0: theme id <STRING> (default missionNamespace Waldo_UI_Theme)
 * 1: colour-vision profile id <STRING> (default local/profile-persistent selection)
 *
 * Return Value: HASHMAP - complete presentation tokens for WMP UI consumers.
 *
 * Example:
 * private _theme = ["VIETNAM", "RED_GREEN"] call Waldo_fnc_UiTheme;
 * Current callers: all theme-aware WMP notifications, displays, interaction equipment, SafeStart,
 * electronic warfare, tactical-display, economy and QA presentation paths.
 */

params [
    ["_requested", missionNamespace getVariable ["Waldo_UI_Theme", "DEFAULT"], [""]],
    ["_visionRequested", missionNamespace getVariable ["Waldo_UI_ColourVisionProfileLocal", profileNamespace getVariable ["Waldo_UI_ColourVisionProfile", "STANDARD"]], [""]]
];
private _id = toUpperANSI _requested;
private _themes = createHashMapFromArray [
    ["DEFAULT", createHashMapFromArray [
        ["id", "DEFAULT"], ["label", "Default / Modern"], ["font", "RobotoCondensed"], ["fontBold", "RobotoCondensedBold"],
        ["shade", [0, 0, 0, 0.72]], ["panel", [0.008, 0.018, 0.030, 0.95]], ["panelAlt", [0.035, 0.065, 0.095, 0.99]],
        ["header", [0.018, 0.19, 0.34, 1]], ["button", [0.035, 0.14, 0.23, 1]], ["buttonActive", [0.08, 0.45, 0.75, 1]],
        ["edit", [0.015, 0.045, 0.070, 1]], ["list", [0.018, 0.035, 0.052, 1]], ["casing", [0.12, 0.15, 0.18, 1]],
        ["accent", [0.10, 0.46, 0.76, 1]], ["accentActive", [0.18, 0.66, 0.94, 1]], ["trim", [0.42, 0.72, 0.92, 0.85]],
        ["text", [1, 1, 1, 1]], ["muted", [0.62, 0.72, 0.82, 1]], ["success", [0.18, 0.66, 0.45, 1]],
        ["warning", [0.88, 0.60, 0.12, 1]], ["danger", [0.78, 0.15, 0.20, 1]], ["railMode", "TOP"],
        ["sourcePrefix", "WMP // "], ["sourceSuffix", ""], ["titlePrefix", ""], ["titleSuffix", ""], ["motif", "TACTICAL INTERFACE"],
        ["textHex", "#FFFFFF"], ["mutedHex", "#9FB8D1"], ["accentHex", "#79C7FF"],
        ["successHex", "#6CE5A8"], ["warningHex", "#FFD166"], ["dangerHex", "#FF6161"]
    ]],
    ["WW2", createHashMapFromArray [
        ["id", "WW2"], ["label", "Second World War"], ["font", "EtelkaMonospacePro"], ["fontBold", "EtelkaMonospaceProBold"],
        ["shade", [0.055, 0.045, 0.025, 0.82]], ["panel", [0.23, 0.215, 0.145, 0.985]], ["panelAlt", [0.32, 0.295, 0.19, 1]],
        ["header", [0.27, 0.29, 0.17, 1]], ["button", [0.31, 0.32, 0.19, 1]], ["buttonActive", [0.69, 0.56, 0.27, 1]],
        ["edit", [0.16, 0.15, 0.095, 1]], ["list", [0.19, 0.18, 0.12, 1]], ["casing", [0.20, 0.22, 0.13, 1]],
        ["accent", [0.72, 0.56, 0.25, 1]], ["accentActive", [0.91, 0.75, 0.38, 1]], ["trim", [0.13, 0.14, 0.075, 1]],
        ["text", [0.98, 0.93, 0.72, 1]], ["muted", [0.79, 0.75, 0.57, 1]], ["success", [0.46, 0.68, 0.35, 1]],
        ["warning", [0.90, 0.70, 0.30, 1]], ["danger", [0.75, 0.28, 0.18, 1]], ["railMode", "BOTTOM"],
        ["sourcePrefix", "WAR DEPARTMENT // "], ["sourceSuffix", " // FIELD COPY"], ["titlePrefix", "ORDER: "], ["titleSuffix", ""], ["motif", "FIELD SIGNAL"],
        ["textHex", "#FAEDB8"], ["mutedHex", "#C9BF91"], ["accentHex", "#DAB45E"],
        ["successHex", "#9AC97C"], ["warningHex", "#E8C06B"], ["dangerHex", "#E17A5E"]
    ]],
    ["VIETNAM", createHashMapFromArray [
        ["id", "VIETNAM"], ["label", "Vietnam / Cold War"], ["font", "EtelkaMonospacePro"], ["fontBold", "EtelkaMonospaceProBold"],
        ["shade", [0.005, 0.022, 0.008, 0.84]], ["panel", [0.018, 0.075, 0.035, 0.985]], ["panelAlt", [0.055, 0.12, 0.055, 1]],
        ["header", [0.085, 0.18, 0.075, 1]], ["button", [0.075, 0.16, 0.07, 1]], ["buttonActive", [0.88, 0.54, 0.12, 1]],
        ["edit", [0.008, 0.045, 0.018, 1]], ["list", [0.012, 0.055, 0.022, 1]], ["casing", [0.07, 0.12, 0.055, 1]],
        ["accent", [0.92, 0.54, 0.12, 1]], ["accentActive", [1, 0.70, 0.23, 1]], ["trim", [0.34, 0.74, 0.30, 0.9]],
        ["text", [0.78, 0.94, 0.62, 1]], ["muted", [0.52, 0.72, 0.40, 1]], ["success", [0.38, 0.78, 0.34, 1]],
        ["warning", [0.96, 0.62, 0.16, 1]], ["danger", [0.90, 0.27, 0.16, 1]], ["railMode", "DOUBLE"],
        ["sourcePrefix", "FIELD NET // "], ["sourceSuffix", " // RX"], ["titlePrefix", "> "], ["titleSuffix", " _"], ["motif", "AN/PRC FIELD DISPLAY"],
        ["textHex", "#C7F09E"], ["mutedHex", "#85B866"], ["accentHex", "#F29A2E"],
        ["successHex", "#77D76A"], ["warningHex", "#F3B24A"], ["dangerHex", "#EF6548"]
    ]],
    ["SCIFI", createHashMapFromArray [
        ["id", "SCIFI"], ["label", "Science Fiction"], ["font", "PuristaMedium"], ["fontBold", "PuristaSemibold"],
        ["shade", [0.001, 0.004, 0.018, 0.88]], ["panel", [0.004, 0.018, 0.052, 0.975]], ["panelAlt", [0.012, 0.055, 0.092, 1]],
        ["header", [0.012, 0.12, 0.22, 1]], ["button", [0.015, 0.10, 0.17, 1]], ["buttonActive", [0.08, 0.72, 0.90, 1]],
        ["edit", [0.003, 0.035, 0.070, 1]], ["list", [0.006, 0.028, 0.060, 1]], ["casing", [0.012, 0.045, 0.082, 1]],
        ["accent", [0.05, 0.80, 0.96, 1]], ["accentActive", [0.35, 0.96, 1, 1]], ["trim", [0.95, 0.16, 0.68, 0.9]],
        ["text", [0.82, 0.98, 1, 1]], ["muted", [0.40, 0.72, 0.82, 1]], ["success", [0.10, 0.90, 0.66, 1]],
        ["warning", [0.98, 0.66, 0.14, 1]], ["danger", [0.98, 0.16, 0.52, 1]], ["railMode", "SIDE"],
        ["sourcePrefix", "SYS::"], ["sourceSuffix", " // ONLINE"], ["titlePrefix", "[ "], ["titleSuffix", " ]"], ["motif", "TACTICAL NODE"],
        ["textHex", "#D1FAFF"], ["mutedHex", "#66B8D1"], ["accentHex", "#35DCF6"],
        ["successHex", "#35EDA5"], ["warningHex", "#FFB93A"], ["dangerHex", "#FF3B83"]
    ]],
    ["PARCHMENT", createHashMapFromArray [
        ["id", "PARCHMENT"], ["label", "Parchment / Fantasy"], ["font", "PuristaMedium"], ["fontBold", "PuristaSemibold"],
        ["shade", [0.10, 0.07, 0.03, 0.75]], ["panel", [0.82, 0.72, 0.52, 0.97]], ["panelAlt", [0.74, 0.63, 0.42, 1]],
        ["header", [0.42, 0.28, 0.14, 1]], ["button", [0.70, 0.60, 0.40, 1]], ["buttonActive", [0.60, 0.14, 0.12, 1]],
        ["edit", [0.88, 0.80, 0.62, 1]], ["list", [0.80, 0.70, 0.50, 1]], ["casing", [0.28, 0.19, 0.10, 1]],
        ["accent", [0.60, 0.14, 0.12, 1]], ["accentActive", [0.78, 0.22, 0.16, 1]], ["trim", [0.46, 0.34, 0.12, 0.9]],
        ["text", [0.18, 0.11, 0.05, 1]], ["muted", [0.38, 0.30, 0.18, 1]], ["success", [0.24, 0.42, 0.16, 1]],
        ["warning", [0.62, 0.42, 0.08, 1]], ["danger", [0.58, 0.12, 0.10, 1]], ["railMode", "DOUBLE"],
        ["sourcePrefix", "ROYAL CHANCERY // "], ["sourceSuffix", " // SEALED"], ["titlePrefix", "PROCLAMATION: "], ["titleSuffix", ""], ["motif", "ILLUMINATED SCROLL"],
        ["textHex", "#2E1C0D"], ["mutedHex", "#614D2E"], ["accentHex", "#99241F"],
        ["successHex", "#3D6B29"], ["warningHex", "#9E6B14"], ["dangerHex", "#941F1A"]
    ]]
];
private _custom = missionNamespace getVariable ["Waldo_UI_CustomThemes", createHashMap];
if (typeName _custom == "HASHMAP") then {
    {private _value = _custom get _x; if (typeName _value == "HASHMAP") then {_themes set [toUpperANSI _x, _value];};} forEach keys _custom;
};
if (isNil {_themes get _id}) then {_id = "DEFAULT";};
private _resolved = createHashMap;
private _base = _themes get _id;
{_resolved set [_x, _base get _x];} forEach keys _base;
_resolved set ["id", _id];
private _overrides = missionNamespace getVariable ["Waldo_UI_ThemeOverrides", createHashMap];
if (typeName _overrides == "HASHMAP") then {
    {if !(isNil {_resolved get _x}) then {private _candidate = _overrides get _x; if (typeName _candidate == typeName (_resolved get _x)) then {_resolved set [_x, _candidate];};};} forEach keys _overrides;
};
private _vision = [_visionRequested] call Waldo_fnc_UiColourVisionProfile;
private _visionOverrides = _vision getOrDefault ["overrides", createHashMap];
if (typeName _visionOverrides == "HASHMAP") then {{_resolved set [_x, _visionOverrides get _x];} forEach keys _visionOverrides;};
_resolved set ["colourVision", _vision getOrDefault ["id", "STANDARD"]];
_resolved set ["colourVisionLabel", _vision getOrDefault ["label", "Standard colour"]];
_resolved
