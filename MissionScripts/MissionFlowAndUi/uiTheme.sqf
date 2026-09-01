/*
 * Author: WaldoTheWarfighter
 * Resolves the mission-wide WMP era theme and overlays the current player's colour-vision profile.
 * All built-in themes have distinct typography, materials, rails, control
 * chrome and copy motifs while retaining identical feature behavior. Red hues are reserved for
 * Arma's hostile/enemy language and are normalised out of every resolved theme token, including
 * mission custom themes and overrides. Accessibility semantic overrides are applied last and locally.
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
// The built-in theme entries below are static literals with no runtime dependency - rebuilding
// their nested keys from scratch on every call (this function is invoked at least once per
// notification card and once per tick by every specialist HUD - hazard, jamming, SafeStart - while
// visible) was pure waste. Build the catalogue once per client session and reuse it; only the merge
// below (custom themes, mission overrides, colour-vision profile) still runs fresh every call, so
// live theme changes and accessibility selection remain immediate.
private _themes = uiNamespace getVariable ["Waldo_UI_BaseThemeCatalogue", createHashMap];
if (count _themes == 0) then {
_themes = createHashMapFromArray [
    ["DEFAULT", createHashMapFromArray [
        ["id", "DEFAULT"], ["label", "Default / Modern"], ["font", "RobotoCondensed"], ["fontBold", "RobotoCondensedBold"],
        ["shade", [0, 0, 0, 0.72]], ["panel", [0.008, 0.018, 0.030, 0.95]], ["panelAlt", [0.035, 0.065, 0.095, 0.99]],
        ["header", [0.018, 0.19, 0.34, 1]], ["button", [0.035, 0.14, 0.23, 1]], ["buttonActive", [0.08, 0.45, 0.75, 1]],
        ["edit", [0.015, 0.045, 0.070, 1]], ["list", [0.018, 0.035, 0.052, 1]], ["casing", [0.12, 0.15, 0.18, 1]],
        ["accent", [0.10, 0.46, 0.76, 1]], ["accentActive", [0.18, 0.66, 0.94, 1]], ["trim", [0.42, 0.72, 0.92, 0.85]],
        ["text", [1, 1, 1, 1]], ["muted", [0.62, 0.72, 0.82, 1]], ["success", [0.18, 0.66, 0.45, 1]],
        ["warning", [0.88, 0.60, 0.12, 1]], ["danger", [0.50, 0.28, 0.78, 1]], ["railMode", "TOP"],
        ["sourcePrefix", "WMP // "], ["sourceSuffix", ""], ["titlePrefix", ""], ["titleSuffix", ""], ["motif", "TACTICAL INTERFACE"],
        ["textHex", "#FFFFFF"], ["mutedHex", "#9FB8D1"], ["accentHex", "#79C7FF"],
        ["successHex", "#6CE5A8"], ["warningHex", "#FFD166"], ["dangerHex", "#8047C7"]
    ]],
    ["WW2", createHashMapFromArray [
        ["id", "WW2"], ["label", "Second World War"], ["font", "EtelkaMonospacePro"], ["fontBold", "EtelkaMonospaceProBold"],
        ["shade", [0.055, 0.045, 0.025, 0.82]], ["panel", [0.23, 0.215, 0.145, 0.985]], ["panelAlt", [0.32, 0.295, 0.19, 1]],
        ["header", [0.27, 0.29, 0.17, 1]], ["button", [0.31, 0.32, 0.19, 1]], ["buttonActive", [0.69, 0.56, 0.27, 1]],
        ["edit", [0.16, 0.15, 0.095, 1]], ["list", [0.19, 0.18, 0.12, 1]], ["casing", [0.20, 0.22, 0.13, 1]],
        ["accent", [0.72, 0.56, 0.25, 1]], ["accentActive", [0.91, 0.75, 0.38, 1]], ["trim", [0.13, 0.14, 0.075, 1]],
        ["text", [0.98, 0.93, 0.72, 1]], ["muted", [0.79, 0.75, 0.57, 1]], ["success", [0.46, 0.68, 0.35, 1]],
        ["warning", [0.90, 0.70, 0.30, 1]], ["danger", [0.42, 0.34, 0.62, 1]], ["railMode", "BOTTOM"],
        ["sourcePrefix", "WAR DEPARTMENT // "], ["sourceSuffix", " // FIELD COPY"], ["titlePrefix", "ORDER: "], ["titleSuffix", ""], ["motif", "FIELD SIGNAL"],
        ["textHex", "#FAEDB8"], ["mutedHex", "#C9BF91"], ["accentHex", "#DAB45E"],
        ["successHex", "#9AC97C"], ["warningHex", "#E8C06B"], ["dangerHex", "#6B579E"]
    ]],
    ["VIETNAM", createHashMapFromArray [
        ["id", "VIETNAM"], ["label", "Vietnam / Cold War"], ["font", "EtelkaMonospacePro"], ["fontBold", "EtelkaMonospaceProBold"],
        ["shade", [0.005, 0.022, 0.008, 0.84]], ["panel", [0.018, 0.075, 0.035, 0.985]], ["panelAlt", [0.055, 0.12, 0.055, 1]],
        ["header", [0.085, 0.18, 0.075, 1]], ["button", [0.075, 0.16, 0.07, 1]], ["buttonActive", [0.88, 0.54, 0.12, 1]],
        ["edit", [0.008, 0.045, 0.018, 1]], ["list", [0.012, 0.055, 0.022, 1]], ["casing", [0.07, 0.12, 0.055, 1]],
        ["accent", [0.92, 0.54, 0.12, 1]], ["accentActive", [1, 0.70, 0.23, 1]], ["trim", [0.34, 0.74, 0.30, 0.9]],
        ["text", [0.78, 0.94, 0.62, 1]], ["muted", [0.52, 0.72, 0.40, 1]], ["success", [0.38, 0.78, 0.34, 1]],
        ["warning", [0.96, 0.62, 0.16, 1]], ["danger", [0.58, 0.28, 0.76, 1]], ["railMode", "DOUBLE"],
        ["sourcePrefix", "FIELD NET // "], ["sourceSuffix", " // RX"], ["titlePrefix", "> "], ["titleSuffix", " _"], ["motif", "AN/PRC FIELD DISPLAY"],
        ["textHex", "#C7F09E"], ["mutedHex", "#85B866"], ["accentHex", "#F29A2E"],
        ["successHex", "#77D76A"], ["warningHex", "#F3B24A"], ["dangerHex", "#9447C2"]
    ]],
    ["SCIFI", createHashMapFromArray [
        ["id", "SCIFI"], ["label", "Science Fiction"], ["font", "PuristaMedium"], ["fontBold", "PuristaSemibold"],
        ["shade", [0.001, 0.004, 0.018, 0.88]], ["panel", [0.004, 0.018, 0.052, 0.975]], ["panelAlt", [0.012, 0.055, 0.092, 1]],
        ["header", [0.012, 0.12, 0.22, 1]], ["button", [0.015, 0.10, 0.17, 1]], ["buttonActive", [0.08, 0.72, 0.90, 1]],
        ["edit", [0.003, 0.035, 0.070, 1]], ["list", [0.006, 0.028, 0.060, 1]], ["casing", [0.012, 0.045, 0.082, 1]],
        ["accent", [0.05, 0.80, 0.96, 1]], ["accentActive", [0.35, 0.96, 1, 1]], ["trim", [0.95, 0.16, 0.68, 0.9]],
        ["text", [0.82, 0.98, 1, 1]], ["muted", [0.40, 0.72, 0.82, 1]], ["success", [0.10, 0.90, 0.66, 1]],
        ["warning", [0.98, 0.66, 0.14, 1]], ["danger", [0.63, 0.20, 0.92, 1]], ["railMode", "SIDE"],
        ["sourcePrefix", "SYS::"], ["sourceSuffix", " // ONLINE"], ["titlePrefix", "[ "], ["titleSuffix", " ]"], ["motif", "TACTICAL NODE"],
        ["textHex", "#D1FAFF"], ["mutedHex", "#66B8D1"], ["accentHex", "#35DCF6"],
        ["successHex", "#35EDA5"], ["warningHex", "#FFB93A"], ["dangerHex", "#A133EB"]
    ]],
    ["PARCHMENT", createHashMapFromArray [
        ["id", "PARCHMENT"], ["label", "Parchment / Fantasy"], ["font", "PuristaLight"], ["fontBold", "PuristaBold"],
        ["shade", [0.10, 0.07, 0.03, 0.75]], ["panel", [0.82, 0.72, 0.52, 0.97]], ["panelAlt", [0.74, 0.63, 0.42, 1]],
        ["header", [0.42, 0.28, 0.14, 1]], ["button", [0.70, 0.60, 0.40, 1]], ["buttonActive", [0.34, 0.22, 0.55, 1]],
        ["edit", [0.88, 0.80, 0.62, 1]], ["list", [0.80, 0.70, 0.50, 1]], ["casing", [0.28, 0.19, 0.10, 1]],
        ["accent", [0.34, 0.22, 0.55, 1]], ["accentActive", [0.50, 0.32, 0.72, 1]], ["trim", [0.46, 0.34, 0.12, 0.9]],
        ["text", [0.18, 0.11, 0.05, 1]], ["muted", [0.38, 0.30, 0.18, 1]], ["success", [0.24, 0.42, 0.16, 1]],
        ["warning", [0.62, 0.42, 0.08, 1]], ["danger", [0.42, 0.24, 0.60, 1]], ["railMode", "DOUBLE"],
        ["sourcePrefix", "ROYAL CHANCERY // "], ["sourceSuffix", " // SEALED"], ["titlePrefix", "PROCLAMATION: "], ["titleSuffix", ""], ["motif", "ILLUMINATED SCROLL"],
        ["textHex", "#2E1C0D"], ["mutedHex", "#614D2E"], ["accentHex", "#57388C"],
        ["successHex", "#3D6B29"], ["warningHex", "#9E6B14"], ["dangerHex", "#6B3D99"]
    ]],
    ["MINIMAL", createHashMapFromArray [
        ["id", "MINIMAL"], ["label", "Minimal / Low Profile"], ["font", "RobotoCondensed"], ["fontBold", "RobotoCondensedBold"],
        ["shade", [0, 0, 0, 0.32]], ["panel", [0.03, 0.03, 0.035, 0.55]], ["panelAlt", [0.06, 0.06, 0.07, 0.6]],
        ["header", [0.05, 0.05, 0.06, 0.5]], ["button", [0.08, 0.08, 0.09, 0.6]], ["buttonActive", [0.30, 0.55, 0.78, 0.85]],
        ["edit", [0.04, 0.04, 0.05, 0.6]], ["list", [0.045, 0.045, 0.055, 0.55]], ["casing", [0.10, 0.10, 0.11, 0.5]],
        ["accent", [0.45, 0.62, 0.78, 0.9]], ["accentActive", [0.60, 0.78, 0.92, 1]], ["trim", [0.45, 0.62, 0.78, 0.55]],
        ["text", [0.95, 0.95, 0.96, 1]], ["muted", [0.68, 0.70, 0.73, 1]], ["success", [0.40, 0.72, 0.55, 0.9]],
        ["warning", [0.85, 0.68, 0.30, 0.9]], ["danger", [0.50, 0.38, 0.72, 0.9]], ["railMode", "TOP"],
        ["sourcePrefix", ""], ["sourceSuffix", ""], ["titlePrefix", ""], ["titleSuffix", ""], ["motif", "NOTICE"],
        ["compact", true],
        ["textHex", "#F2F3F5"], ["mutedHex", "#AEB4BA"], ["accentHex", "#73B3E0"],
        ["successHex", "#6BC48C"], ["warningHex", "#D9AD4C"], ["dangerHex", "#8061B8"]
    ]],
    ["NAVAL", createHashMapFromArray [
        ["id", "NAVAL"], ["label", "Naval / Combat Information Centre"], ["font", "EtelkaMonospacePro"], ["fontBold", "EtelkaMonospaceProBold"],
        ["shade", [0.002, 0.012, 0.024, 0.86]], ["panel", [0.006, 0.026, 0.046, 0.98]], ["panelAlt", [0.018, 0.060, 0.078, 1]],
        ["header", [0.018, 0.125, 0.165, 1]], ["button", [0.020, 0.090, 0.115, 1]], ["buttonActive", [0.10, 0.58, 0.54, 1]],
        ["edit", [0.006, 0.042, 0.052, 1]], ["list", [0.008, 0.035, 0.052, 1]], ["casing", [0.055, 0.105, 0.125, 1]],
        ["accent", [0.16, 0.68, 0.61, 1]], ["accentActive", [0.28, 0.88, 0.76, 1]], ["trim", [0.50, 0.76, 0.82, 0.88]],
        ["text", [0.84, 0.96, 0.92, 1]], ["muted", [0.48, 0.68, 0.67, 1]], ["success", [0.24, 0.76, 0.50, 1]],
        ["warning", [0.94, 0.66, 0.18, 1]], ["danger", [0.54, 0.30, 0.76, 1]], ["railMode", "SIDE"],
        ["sourcePrefix", "CIC // "], ["sourceSuffix", " // TRACK"], ["titlePrefix", "CONTACT: "], ["titleSuffix", ""], ["motif", "COMBAT INFORMATION CENTRE"],
        ["textHex", "#D6F5EB"], ["mutedHex", "#7AAEAB"], ["accentHex", "#29AE9C"],
        ["successHex", "#55D68D"], ["warningHex", "#F0A82E"], ["dangerHex", "#8A4CC2"]
    ]],
    ["DESERT_STORM", createHashMapFromArray [
        ["id", "DESERT_STORM"], ["label", "Desert Storm / CENTCOM"], ["font", "EtelkaMonospacePro"], ["fontBold", "EtelkaMonospaceProBold"],
        ["shade", [0.045, 0.032, 0.014, 0.84]], ["panel", [0.105, 0.088, 0.052, 0.98]], ["panelAlt", [0.17, 0.145, 0.085, 1]],
        ["header", [0.24, 0.205, 0.115, 1]], ["button", [0.18, 0.155, 0.09, 1]], ["buttonActive", [0.78, 0.50, 0.14, 1]],
        ["edit", [0.075, 0.064, 0.038, 1]], ["list", [0.090, 0.076, 0.045, 1]], ["casing", [0.20, 0.19, 0.125, 1]],
        ["accent", [0.86, 0.58, 0.18, 1]], ["accentActive", [1, 0.74, 0.28, 1]], ["trim", [0.63, 0.56, 0.35, 0.9]],
        ["text", [0.96, 0.90, 0.72, 1]], ["muted", [0.72, 0.66, 0.49, 1]], ["success", [0.43, 0.68, 0.34, 1]],
        ["warning", [0.95, 0.68, 0.20, 1]], ["danger", [0.50, 0.30, 0.70, 1]], ["railMode", "BOTTOM"],
        ["sourcePrefix", "CENTCOM // "], ["sourceSuffix", " // SITREP"], ["titlePrefix", "TASKING: "], ["titleSuffix", ""], ["motif", "THEATRE COMMAND NET"],
        ["textHex", "#F5E6B8"], ["mutedHex", "#B8A87D"], ["accentHex", "#DB942E"],
        ["successHex", "#77B65E"], ["warningHex", "#F2AD33"], ["dangerHex", "#804DB3"]
    ]],
    ["INDUSTRIAL", createHashMapFromArray [
        ["id", "INDUSTRIAL"], ["label", "Industrial / Operations Control"], ["font", "RobotoCondensed"], ["fontBold", "RobotoCondensedBold"],
        ["shade", [0.015, 0.016, 0.016, 0.86]], ["panel", [0.055, 0.060, 0.060, 0.98]], ["panelAlt", [0.105, 0.11, 0.105, 1]],
        ["header", [0.18, 0.18, 0.16, 1]], ["button", [0.14, 0.145, 0.135, 1]], ["buttonActive", [0.78, 0.64, 0.08, 1]],
        ["edit", [0.035, 0.040, 0.038, 1]], ["list", [0.045, 0.050, 0.048, 1]], ["casing", [0.16, 0.17, 0.16, 1]],
        ["accent", [0.88, 0.72, 0.10, 1]], ["accentActive", [1, 0.88, 0.24, 1]], ["trim", [0.64, 0.65, 0.58, 0.9]],
        ["text", [0.94, 0.94, 0.88, 1]], ["muted", [0.66, 0.67, 0.62, 1]], ["success", [0.32, 0.72, 0.40, 1]],
        ["warning", [0.95, 0.68, 0.10, 1]], ["danger", [0.56, 0.26, 0.76, 1]], ["railMode", "DOUBLE"],
        ["sourcePrefix", "PLANT OPS // "], ["sourceSuffix", " // CONTROL"], ["titlePrefix", "WORK ORDER: "], ["titleSuffix", ""], ["motif", "INDUSTRIAL CONTROL"],
        ["textHex", "#F0F0E0"], ["mutedHex", "#A8AB9E"], ["accentHex", "#E0B81A"],
        ["successHex", "#52B866"], ["warningHex", "#F2AD1A"], ["dangerHex", "#8F42C2"]
    ]],
    ["EASTERN_BLOC", createHashMapFromArray [
        ["id", "EASTERN_BLOC"], ["label", "Eastern Bloc / Sector Control"], ["font", "EtelkaMonospacePro"], ["fontBold", "EtelkaMonospaceProBold"],
        ["shade", [0.025, 0.022, 0.020, 0.86]], ["panel", [0.075, 0.078, 0.068, 0.98]], ["panelAlt", [0.13, 0.13, 0.105, 1]],
        ["header", [0.22, 0.20, 0.10, 1]], ["button", [0.17, 0.15, 0.115, 1]], ["buttonActive", [0.22, 0.48, 0.64, 1]],
        ["edit", [0.050, 0.052, 0.044, 1]], ["list", [0.060, 0.062, 0.052, 1]], ["casing", [0.15, 0.16, 0.13, 1]],
        ["accent", [0.30, 0.58, 0.72, 1]], ["accentActive", [0.42, 0.72, 0.86, 1]], ["trim", [0.67, 0.62, 0.45, 0.88]],
        ["text", [0.91, 0.87, 0.69, 1]], ["muted", [0.65, 0.62, 0.48, 1]], ["success", [0.40, 0.66, 0.31, 1]],
        ["warning", [0.88, 0.65, 0.17, 1]], ["danger", [0.55, 0.28, 0.72, 1]], ["railMode", "BOTTOM"],
        ["sourcePrefix", "SECTOR CONTROL // "], ["sourceSuffix", " // FIELD CIRCUIT"], ["titlePrefix", "DIRECTIVE: "], ["titleSuffix", ""], ["motif", "COMMAND APPARATUS"],
        ["textHex", "#E8DEB0"], ["mutedHex", "#A69E7A"], ["accentHex", "#4D94B8"],
        ["successHex", "#66A84F"], ["warningHex", "#E0A62B"], ["dangerHex", "#8C47B8"]
    ]],
    ["INTELLIGENCE", createHashMapFromArray [
        ["id", "INTELLIGENCE"], ["label", "Intelligence / Restricted"], ["font", "RobotoCondensed"], ["fontBold", "RobotoCondensedBold"],
        ["shade", [0.006, 0.008, 0.010, 0.88]], ["panel", [0.025, 0.032, 0.036, 0.98]], ["panelAlt", [0.060, 0.072, 0.076, 1]],
        ["header", [0.075, 0.16, 0.17, 1]], ["button", [0.055, 0.12, 0.125, 1]], ["buttonActive", [0.12, 0.60, 0.58, 1]],
        ["edit", [0.018, 0.045, 0.047, 1]], ["list", [0.022, 0.040, 0.044, 1]], ["casing", [0.08, 0.095, 0.095, 1]],
        ["accent", [0.18, 0.68, 0.65, 1]], ["accentActive", [0.34, 0.88, 0.82, 1]], ["trim", [0.48, 0.30, 0.72, 0.90]],
        ["text", [0.91, 0.94, 0.91, 1]], ["muted", [0.57, 0.65, 0.63, 1]], ["success", [0.25, 0.72, 0.48, 1]],
        ["warning", [0.92, 0.66, 0.18, 1]], ["danger", [0.54, 0.28, 0.74, 1]], ["railMode", "SIDE"],
        ["sourcePrefix", "JOINT INTEL // "], ["sourceSuffix", " // RESTRICTED"], ["titlePrefix", "ASSESSMENT: "], ["titleSuffix", ""], ["motif", "EYES ONLY"],
        ["textHex", "#E8EFE8"], ["mutedHex", "#91A6A1"], ["accentHex", "#2EADA6"],
        ["successHex", "#40B87A"], ["warningHex", "#EBA82E"], ["dangerHex", "#8A47BD"]
    ]],
    ["EMERGENCY", createHashMapFromArray [
        ["id", "EMERGENCY"], ["label", "Emergency / Incident Command"], ["font", "RobotoCondensed"], ["fontBold", "RobotoCondensedBold"],
        ["shade", [0.012, 0.014, 0.018, 0.86]], ["panel", [0.035, 0.043, 0.052, 0.98]], ["panelAlt", [0.075, 0.086, 0.095, 1]],
        ["header", [0.20, 0.14, 0.055, 1]], ["button", [0.14, 0.105, 0.060, 1]], ["buttonActive", [0.90, 0.46, 0.06, 1]],
        ["edit", [0.028, 0.038, 0.044, 1]], ["list", [0.032, 0.042, 0.050, 1]], ["casing", [0.12, 0.13, 0.14, 1]],
        ["accent", [0.94, 0.48, 0.06, 1]], ["accentActive", [1, 0.64, 0.16, 1]], ["trim", [0.30, 0.72, 0.86, 0.90]],
        ["text", [0.96, 0.96, 0.94, 1]], ["muted", [0.67, 0.71, 0.73, 1]], ["success", [0.22, 0.72, 0.42, 1]],
        ["warning", [0.98, 0.70, 0.10, 1]], ["danger", [0.58, 0.26, 0.78, 1]], ["railMode", "DOUBLE"],
        ["sourcePrefix", "INCIDENT COMMAND // "], ["sourceSuffix", " // ACTIVE"], ["titlePrefix", "ALERT: "], ["titleSuffix", ""], ["motif", "EMERGENCY OPERATIONS"],
        ["textHex", "#F5F5F0"], ["mutedHex", "#ABB5BA"], ["accentHex", "#F0780F"],
        ["successHex", "#38B86B"], ["warningHex", "#FAB31A"], ["dangerHex", "#9442C7"]
    ]]
];
uiNamespace setVariable ["Waldo_UI_BaseThemeCatalogue", _themes];
};
// A mission-defined custom theme can reuse a built-in id to override it. Looking that up here
// (rather than merging every custom entry into the cached catalogue, as before) means the shared
// cache above is never mutated by mission-supplied data - it stays a pure, reusable copy of the
// built-in literal themes across the whole client session.
private _custom = missionNamespace getVariable ["Waldo_UI_CustomThemes", createHashMap];
private _base = if (typeName _custom == "HASHMAP") then {_custom get _id} else {nil};
if (isNil "_base" || {typeName _base != "HASHMAP"}) then {
    _base = _themes get _id;
    if (isNil "_base") then {_id = "DEFAULT"; _base = _themes get _id;};
};
private _resolved = createHashMap;
{_resolved set [_x, _base get _x];} forEach keys _base;
_resolved set ["id", _id];
private _overrides = missionNamespace getVariable ["Waldo_UI_ThemeOverrides", createHashMap];
if (typeName _overrides == "HASHMAP") then {
    {if !(isNil {_resolved get _x}) then {private _candidate = _overrides get _x; if (typeName _candidate == typeName (_resolved get _x)) then {_resolved set [_x, _candidate];};};} forEach keys _overrides;
};
private _vision = [_visionRequested] call Waldo_fnc_UiColourVisionProfile;
private _visionOverrides = _vision getOrDefault ["overrides", createHashMap];
if (typeName _visionOverrides == "HASHMAP") then {{_resolved set [_x, _visionOverrides get _x];} forEach keys _visionOverrides;};

// Red is an engine/gameplay allegiance cue, never WMP presentation chrome. Enforce this after
// mission overrides and personal accessibility overlays so a custom theme cannot accidentally
// produce a hostile-looking WMP panel. Amber, magenta and violet remain available; only the narrow
// red hue sector is normalised. Hex tokens are rebuilt from the accepted array values so the two
// representations cannot disagree or bypass the rule.
private _isRedThemeColour = {
    params [["_colour", [], [[]]]];
    if (count _colour < 3) exitWith {false};
    _colour params ["_r", "_g", "_b"];
    private _maximum = (_r max _g) max _b;
    private _minimum = (_r min _g) min _b;
    private _delta = _maximum - _minimum;
    if (_delta <= 0.08) exitWith {false};
    private _hue = if (_maximum isEqualTo _r) then {
        60 * ((_g - _b) / _delta)
    } else {
        if (_maximum isEqualTo _g) then {
            60 * (((_b - _r) / _delta) + 2)
        } else {
            60 * (((_r - _g) / _delta) + 4)
        }
    };
    if (_hue < 0) then {_hue = _hue + 360;};
    _hue < 20 || {_hue > 340}
};
{
    private _token = _x;
    private _candidate = _resolved getOrDefault [_token, []];
    if ([_candidate] call _isRedThemeColour) then {
        private _alpha = _candidate param [3, 1, [0]];
        private _replacement = switch (_token) do {
            case "danger": {[0.58, 0.30, 0.78, _alpha]};
            case "warning": {[0.95, 0.68, 0.12, _alpha]};
            case "success": {[0.22, 0.72, 0.44, _alpha]};
            default {[0.18, 0.62, 0.82, _alpha]};
        };
        _resolved set [_token, _replacement];
        diag_log format ["[WMP UI] Red theme colour normalised: theme=%1 token=%2.", _id, _token];
    };
} forEach [
    "shade", "panel", "panelAlt", "header", "button", "buttonActive", "edit", "list",
    "casing", "accent", "accentActive", "trim", "text", "muted", "success", "warning", "danger"
];
private _hexDigits = "0123456789ABCDEF";
private _componentToHex = {
    params [["_component", 0, [0]]];
    private _byte = round (((_component max 0) min 1) * 255);
    (_hexDigits select [floor (_byte / 16), 1]) + (_hexDigits select [_byte mod 16, 1])
};
private _colourToHex = {
    params [["_colour", [1, 1, 1, 1], [[]]]];
    "#" + ([_colour select 0] call _componentToHex)
        + ([_colour select 1] call _componentToHex)
        + ([_colour select 2] call _componentToHex)
};
{
    _x params ["_arrayToken", "_hexToken"];
    _resolved set [_hexToken, [_resolved getOrDefault [_arrayToken, [1, 1, 1, 1]]] call _colourToHex];
} forEach [
    ["text", "textHex"], ["muted", "mutedHex"], ["accent", "accentHex"],
    ["success", "successHex"], ["warning", "warningHex"], ["danger", "dangerHex"]
];
_resolved set ["colourVision", _vision getOrDefault ["id", "STANDARD"]];
_resolved set ["colourVisionLabel", _vision getOrDefault ["label", "Standard colour"]];
_resolved
