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
        ["sourcePrefix", "WAR DEPT // "], ["sourceSuffix", " // FIELD"], ["titlePrefix", "ORDER: "], ["titleSuffix", ""], ["motif", "FIELD SIGNAL"],
        ["copyMode", "DOSSIER"], ["widthScale", 0.94],
        ["chromeMode", "DOCUMENT"], ["chromePrimary", [0.13, 0.12, 0.075, 0.96]], ["chromeSecondary", [0.62, 0.52, 0.26, 0.82]], ["chromeTertiary", [0.30, 0.28, 0.16, 0.78]],
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
        ["sourcePrefix", "FIELD NET // "], ["sourceSuffix", " // RX"], ["titlePrefix", "> "], ["titleSuffix", " _"], ["motif", "AN/PRC DISPLAY"],
        ["copyMode", "TERMINAL"], ["widthScale", 0.92],
        ["chromeMode", "FIELD"], ["chromePrimary", [0.008, 0.035, 0.014, 0.98]], ["chromeSecondary", [0.22, 0.58, 0.24, 0.78]], ["chromeTertiary", [0.72, 0.58, 0.18, 0.78]],
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
        ["copyMode", "TERMINAL"], ["widthScale", 0.96],
        ["chromeMode", "HUD"], ["chromePrimary", [0.002, 0.012, 0.050, 0.98]], ["chromeSecondary", [0.08, 0.68, 0.80, 0.82]], ["chromeTertiary", [0.40, 0.28, 0.72, 0.72]],
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
        ["sourcePrefix", "CHANCERY // "], ["sourceSuffix", " // SEALED"], ["titlePrefix", "PROCLAMATION: "], ["titleSuffix", ""], ["motif", "ROYAL DECREE"],
        ["copyMode", "HERALDIC"], ["widthScale", 0.94],
        ["chromeMode", "SCROLL"], ["chromePrimary", [0.74, 0.63, 0.42, 0.96]], ["chromeSecondary", [0.24, 0.16, 0.075, 0.88]], ["chromeTertiary", [0.76, 0.56, 0.16, 0.82]],
        ["textHex", "#24180C"], ["mutedHex", "#765B32"], ["accentHex", "#57388C"],
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
        ["sourcePrefix", "CIC // "], ["sourceSuffix", " // TRACK"], ["titlePrefix", "CONTACT: "], ["titleSuffix", ""], ["motif", "CONTACT BOARD"],
        ["copyMode", "TERMINAL"], ["widthScale", 0.94],
        ["chromeMode", "CIC"], ["chromePrimary", [0.003, 0.018, 0.034, 0.98]], ["chromeSecondary", [0.08, 0.56, 0.66, 0.78]], ["chromeTertiary", [0.34, 0.72, 0.58, 0.74]],
        ["textHex", "#DDF8EF"], ["mutedHex", "#9BCBC3"], ["accentHex", "#29AE9C"],
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
        ["sourcePrefix", "CENTCOM // "], ["sourceSuffix", " // SITREP"], ["titlePrefix", "TASKING: "], ["titleSuffix", ""], ["motif", "THEATRE NET"],
        ["copyMode", "DOSSIER"], ["widthScale", 0.92],
        ["chromeMode", "SITREP"], ["chromePrimary", [0.045, 0.038, 0.020, 0.98]], ["chromeSecondary", [0.62, 0.52, 0.25, 0.76]], ["chromeTertiary", [0.86, 0.58, 0.16, 0.84]],
        ["textHex", "#F5E6B8"], ["mutedHex", "#B8A87D"], ["accentHex", "#DB942E"],
        ["successHex", "#77B65E"], ["warningHex", "#F2AD33"], ["dangerHex", "#804DB3"]
    ]],
    ["INDUSTRIAL", createHashMapFromArray [
        ["id", "INDUSTRIAL"], ["label", "Operations / Field Board"], ["font", "RobotoCondensed"], ["fontBold", "RobotoCondensedBold"],
        ["shade", [0.012, 0.020, 0.018, 0.84]], ["panel", [0.025, 0.034, 0.032, 0.98]], ["panelAlt", [0.075, 0.12, 0.105, 1]],
        ["header", [0.09, 0.15, 0.135, 1]], ["button", [0.08, 0.13, 0.12, 1]], ["buttonActive", [0.82, 0.66, 0.06, 1]],
        ["edit", [0.035, 0.065, 0.058, 1]], ["list", [0.045, 0.075, 0.068, 1]], ["casing", [0.15, 0.18, 0.16, 1]],
        ["accent", [0.82, 0.66, 0.06, 1]], ["accentActive", [0.96, 0.82, 0.18, 1]], ["trim", [0.42, 0.48, 0.44, 0.96]],
        ["text", [0.91, 0.93, 0.87, 1]], ["muted", [0.60, 0.66, 0.61, 1]], ["success", [0.22, 0.68, 0.38, 1]],
        ["warning", [0.90, 0.64, 0.10, 1]], ["danger", [0.52, 0.28, 0.72, 1]], ["railMode", "DOUBLE"],
        ["sourcePrefix", "OPS BOARD // "], ["sourceSuffix", " // LIVE"], ["titlePrefix", "WORK ORDER: "], ["titleSuffix", ""], ["motif", "FIELD OPERATIONS"],
        ["copyMode", "DOSSIER"], ["widthScale", 0.90],
        ["chromeMode", "GRID"], ["chromePrimary", [0.075, 0.12, 0.105, 0.98]], ["chromeSecondary", [0.82, 0.66, 0.06, 0.98]], ["chromeTertiary", [0.42, 0.48, 0.44, 0.92]],
        ["textHex", "#E8EDE0"], ["mutedHex", "#99A89C"], ["accentHex", "#D1A80F"],
        ["successHex", "#38AD61"], ["warningHex", "#E6A31A"], ["dangerHex", "#8547B8"]
    ]],
    ["EASTERN_BLOC", createHashMapFromArray [
        ["id", "EASTERN_BLOC"], ["label", "Eastern Bloc / Sector Control"], ["font", "EtelkaMonospacePro"], ["fontBold", "EtelkaMonospaceProBold"],
        ["shade", [0.025, 0.022, 0.020, 0.86]], ["panel", [0.075, 0.078, 0.068, 0.98]], ["panelAlt", [0.13, 0.13, 0.105, 1]],
        ["header", [0.22, 0.20, 0.10, 1]], ["button", [0.17, 0.15, 0.115, 1]], ["buttonActive", [0.22, 0.48, 0.64, 1]],
        ["edit", [0.050, 0.052, 0.044, 1]], ["list", [0.060, 0.062, 0.052, 1]], ["casing", [0.15, 0.16, 0.13, 1]],
        ["accent", [0.30, 0.58, 0.72, 1]], ["accentActive", [0.42, 0.72, 0.86, 1]], ["trim", [0.67, 0.62, 0.45, 0.88]],
        ["text", [0.91, 0.87, 0.69, 1]], ["muted", [0.65, 0.62, 0.48, 1]], ["success", [0.40, 0.66, 0.31, 1]],
        ["warning", [0.88, 0.65, 0.17, 1]], ["danger", [0.55, 0.28, 0.72, 1]], ["railMode", "BOTTOM"],
        ["sourcePrefix", "SECTOR // "], ["sourceSuffix", " // FIELD"], ["titlePrefix", "DIRECTIVE: "], ["titleSuffix", ""], ["motif", "COMMAND CIRCUIT"],
        ["copyMode", "DOSSIER"], ["widthScale", 0.92],
        ["chromeMode", "SECTOR"], ["chromePrimary", [0.024, 0.030, 0.026, 0.98]], ["chromeSecondary", [0.48, 0.48, 0.34, 0.82]], ["chromeTertiary", [0.12, 0.44, 0.58, 0.78]],
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
        ["sourcePrefix", "J2 // "], ["sourceSuffix", " // RESTRICTED"], ["titlePrefix", "ASSESSMENT: "], ["titleSuffix", ""], ["motif", "EYES ONLY"],
        ["copyMode", "DOSSIER"], ["widthScale", 0.90],
        ["chromeMode", "CLASSIFIED"], ["chromePrimary", [0.010, 0.014, 0.016, 0.98]], ["chromeSecondary", [0.42, 0.48, 0.48, 0.56]], ["chromeTertiary", [0.10, 0.46, 0.44, 0.78]],
        ["textHex", "#F0F7F2"], ["mutedHex", "#B3C4BE"], ["accentHex", "#2EADA6"],
        ["successHex", "#40B87A"], ["warningHex", "#EBA82E"], ["dangerHex", "#8A47BD"]
    ]],
    ["GRIMDARK", createHashMapFromArray [
        ["id", "GRIMDARK"], ["label", "Grimdark / Gothic Warfront"], ["font", "EtelkaMonospacePro"], ["fontBold", "EtelkaMonospaceProBold"],
        ["shade", [0.004, 0.020, 0.008, 0.90]], ["panel", [0.010, 0.052, 0.022, 0.985]], ["panelAlt", [0.040, 0.105, 0.042, 1]],
        ["header", [0.060, 0.145, 0.055, 1]], ["button", [0.050, 0.125, 0.045, 1]], ["buttonActive", [0.90, 0.55, 0.10, 1]],
        ["edit", [0.006, 0.034, 0.013, 1]], ["list", [0.010, 0.044, 0.017, 1]], ["casing", [0.10, 0.15, 0.065, 1]],
        ["accent", [0.92, 0.54, 0.12, 1]], ["accentActive", [1, 0.70, 0.23, 1]], ["trim", [0.34, 0.70, 0.28, 0.92]],
        ["text", [0.80, 0.94, 0.61, 1]], ["muted", [0.52, 0.70, 0.39, 1]], ["success", [0.38, 0.76, 0.34, 1]],
        ["warning", [0.94, 0.68, 0.16, 1]], ["danger", [0.52, 0.28, 0.72, 1]], ["railMode", "DOUBLE"],
        ["sourcePrefix", "VOXCASTER // "], ["sourceSuffix", " // RECEIVED"], ["titlePrefix", "TRANSMISSION: "], ["titleSuffix", ""], ["motif", "IMPERIAL VOX-NET"],
        ["copyMode", "TERMINAL"], ["widthScale", 0.90],
        ["chromeMode", "GOTHIC"], ["chromePrimary", [0.006, 0.034, 0.012, 0.98]], ["chromeSecondary", [0.92, 0.54, 0.12, 1]], ["chromeTertiary", [0.28, 0.60, 0.24, 0.78]], ["source", [0.50, 0.70, 0.38, 1]], ["sourceHex", "#80B363"],
        ["infoSymbol", "[VOX]"], ["successSymbol", "[ACK]"], ["warningSymbol", "[PRIORITY]"], ["dangerSymbol", "[SIGNAL LOST]"],
        ["textHex", "#CCF09C"], ["mutedHex", "#85B866"], ["accentHex", "#F29A2E"],
        ["successHex", "#71D466"], ["warningHex", "#F3B24A"], ["dangerHex", "#8547B8"]
    ]],
    ["ATOMIC_AGE", createHashMapFromArray [
        ["id", "ATOMIC_AGE"], ["label", "Atomic Age / Civil Defence"], ["font", "PuristaMedium"], ["fontBold", "PuristaSemibold"],
        ["shade", [0.035, 0.060, 0.060, 0.78]], ["panel", [0.76, 0.84, 0.75, 0.91]], ["panelAlt", [0.66, 0.76, 0.68, 1]],
        ["header", [0.055, 0.30, 0.32, 1]], ["button", [0.50, 0.66, 0.60, 1]], ["buttonActive", [0.10, 0.56, 0.60, 1]],
        ["edit", [0.86, 0.90, 0.78, 1]], ["list", [0.72, 0.81, 0.72, 1]], ["casing", [0.16, 0.34, 0.34, 1]],
        ["accent", [0.08, 0.50, 0.55, 1]], ["accentActive", [0.14, 0.69, 0.72, 1]], ["trim", [0.92, 0.66, 0.16, 0.92]],
        ["text", [0.055, 0.12, 0.14, 1]], ["muted", [0.22, 0.34, 0.32, 1]], ["success", [0.20, 0.55, 0.32, 1]],
        ["warning", [0.86, 0.58, 0.10, 1]], ["danger", [0.48, 0.26, 0.68, 1]], ["railMode", "BOTTOM"],
        ["sourcePrefix", "CIVDEF // "], ["sourceSuffix", " // CLEAR"], ["titlePrefix", "BULLETIN: "], ["titleSuffix", ""], ["motif", "PUBLIC INFORMATION"],
        ["copyMode", "BULLETIN"], ["widthScale", 0.92],
        ["chromeMode", "ATOMIC"], ["chromePrimary", [0.055, 0.30, 0.32, 0.94]], ["chromeSecondary", [0.86, 0.90, 0.78, 0.82]], ["chromeTertiary", [0.92, 0.66, 0.16, 0.92]], ["source", [0.92, 0.96, 0.84, 1]], ["sourceHex", "#EBF5D6"],
        ["textHex", "#0E1F24"], ["mutedHex", "#385752"], ["accentHex", "#14808C"],
        ["successHex", "#338C52"], ["warningHex", "#DB941A"], ["dangerHex", "#7A42AD"]
    ]],
    ["WASTELAND", createHashMapFromArray [
        ["id", "WASTELAND"], ["label", "Wasteland / Retro Apocalypse"], ["font", "EtelkaMonospacePro"], ["fontBold", "EtelkaMonospaceProBold"],
        ["shade", [0.018, 0.030, 0.070, 0.90]], ["panel", [0.035, 0.11, 0.25, 0.95]], ["panelAlt", [0.06, 0.18, 0.34, 1]],
        ["header", [0.05, 0.16, 0.32, 1]], ["button", [0.07, 0.20, 0.38, 1]], ["buttonActive", [0.84, 0.55, 0.11, 1]],
        ["edit", [0.025, 0.075, 0.17, 1]], ["list", [0.04, 0.11, 0.23, 1]], ["casing", [0.17, 0.22, 0.28, 1]],
        ["accent", [0.88, 0.58, 0.12, 1]], ["accentActive", [1, 0.76, 0.28, 1]], ["trim", [0.45, 0.72, 0.78, 0.90]],
        ["text", [0.88, 0.92, 0.78, 1]], ["muted", [0.48, 0.70, 0.72, 1]], ["success", [0.30, 0.72, 0.42, 1]],
        ["warning", [0.94, 0.65, 0.14, 1]], ["danger", [0.55, 0.30, 0.70, 1]], ["railMode", "DOUBLE"],
        ["sourcePrefix", "SHELTER NET // "], ["sourceSuffix", ""], ["titlePrefix", "NOTICE: "], ["titleSuffix", ""], ["motif", "SHELTER CONTROL"],
        ["copyMode", "TERMINAL"], ["widthScale", 0.94],
        ["chromeMode", "SCRAP"], ["chromePrimary", [0.025, 0.075, 0.17, 0.98]], ["chromeSecondary", [0.42, 0.70, 0.76, 0.74]], ["chromeTertiary", [0.88, 0.58, 0.12, 0.94]], ["source", [0.54, 0.76, 0.78, 1]], ["sourceHex", "#8AC2C7"],
        ["textHex", "#E0EBC7"], ["mutedHex", "#7AB3B8"], ["accentHex", "#E0941F"],
        ["successHex", "#4DB86B"], ["warningHex", "#F0A624"], ["dangerHex", "#8C4DB3"]
    ]],
    ["PMC", createHashMapFromArray [
        ["id", "PMC"], ["label", "PMC / Corporate Operations"], ["font", "RobotoCondensed"], ["fontBold", "RobotoCondensedBold"],
        ["shade", [0.006, 0.016, 0.026, 0.78]], ["panel", [0.018, 0.035, 0.050, 0.91]], ["panelAlt", [0.04, 0.075, 0.095, 0.94]],
        ["header", [0.025, 0.10, 0.15, 1]], ["button", [0.06, 0.12, 0.16, 1]], ["buttonActive", [0.00, 0.48, 0.67, 1]],
        ["edit", [0.018, 0.040, 0.055, 1]], ["list", [0.025, 0.055, 0.072, 1]], ["casing", [0.08, 0.13, 0.16, 1]],
        ["accent", [0.00, 0.42, 0.60, 1]], ["accentActive", [0.04, 0.64, 0.82, 1]], ["trim", [0.30, 0.38, 0.43, 0.88]],
        ["text", [0.90, 0.94, 0.96, 1]], ["muted", [0.54, 0.66, 0.72, 1]], ["success", [0.10, 0.58, 0.38, 1]],
        ["warning", [0.93, 0.67, 0.16, 1]], ["danger", [0.52, 0.28, 0.74, 1]], ["railMode", "TOP"],
        ["sourcePrefix", "OPS // "], ["sourceSuffix", " // VERIFIED"], ["titlePrefix", "TASKING: "], ["titleSuffix", ""], ["motif", "CONTRACTOR NETWORK"],
        ["copyMode", "DOSSIER"], ["widthScale", 0.84],
        ["chromeMode", "CORPORATE"], ["chromePrimary", [0.025, 0.10, 0.15, 0.96]], ["chromeSecondary", [0.20, 0.32, 0.38, 0.32]], ["chromeTertiary", [0.00, 0.42, 0.60, 0.86]], ["source", [0.54, 0.70, 0.76, 1]], ["sourceHex", "#8AB3C2"],
        ["textHex", "#E6F0F5"], ["mutedHex", "#8AA8B8"], ["accentHex", "#00A1CC"],
        ["successHex", "#1A7A4D"], ["warningHex", "#EDAB29"], ["dangerHex", "#8547BD"]
    ]],
    ["RETRO_COMMAND", createHashMapFromArray [
        ["id", "RETRO_COMMAND"], ["label", "Retro Command / CRT"], ["font", "EtelkaMonospacePro"], ["fontBold", "EtelkaMonospaceProBold"],
        ["shade", [0.018, 0.009, 0.002, 0.92]], ["panel", [0.035, 0.018, 0.004, 0.96]], ["panelAlt", [0.090, 0.045, 0.010, 0.98]],
        ["header", [0.16, 0.085, 0.015, 1]], ["button", [0.12, 0.060, 0.010, 1]], ["buttonActive", [0.20, 0.70, 0.74, 1]],
        ["edit", [0.025, 0.012, 0.002, 1]], ["list", [0.030, 0.015, 0.003, 1]], ["casing", [0.18, 0.12, 0.060, 1]],
        ["accent", [0.20, 0.70, 0.74, 1]], ["accentActive", [0.38, 0.90, 0.90, 1]], ["trim", [0.88, 0.58, 0.12, 0.90]],
        ["text", [0.98, 0.70, 0.28, 1]], ["muted", [0.70, 0.45, 0.14, 1]], ["success", [0.28, 0.76, 0.34, 1]],
        ["warning", [0.92, 0.65, 0.14, 1]], ["danger", [0.57, 0.29, 0.76, 1]], ["railMode", "DOUBLE"],
        ["sourcePrefix", "CMD> "], ["sourceSuffix", ""], ["titlePrefix", "MSG: "], ["titleSuffix", " _"], ["motif", "TERMINAL READY"],
        ["copyMode", "TERMINAL"], ["widthScale", 0.92],
        ["chromeMode", "CRT"], ["chromePrimary", [0.012, 0.006, 0.001, 0.98]], ["chromeSecondary", [0.88, 0.58, 0.12, 0.52]], ["chromeTertiary", [0.20, 0.70, 0.74, 0.62]], ["source", [0.70, 0.45, 0.14, 1]], ["sourceHex", "#B37324"],
        ["textHex", "#FAB347"], ["mutedHex", "#B37324"], ["accentHex", "#33B3BD"],
        ["successHex", "#47C257"], ["warningHex", "#EBA624"], ["dangerHex", "#914AC2"]
    ]],
    ["DIESELPUNK", createHashMapFromArray [
        ["id", "DIESELPUNK"], ["label", "Dieselpunk / Ministry Engine"], ["font", "PuristaMedium"], ["fontBold", "PuristaSemibold"],
        ["shade", [0.018, 0.016, 0.012, 0.90]], ["panel", [0.030, 0.032, 0.030, 0.98]], ["panelAlt", [0.11, 0.095, 0.065, 1]],
        ["header", [0.30, 0.22, 0.11, 1]], ["button", [0.16, 0.13, 0.085, 1]], ["buttonActive", [0.68, 0.48, 0.18, 1]],
        ["edit", [0.050, 0.052, 0.048, 1]], ["list", [0.060, 0.062, 0.056, 1]], ["casing", [0.30, 0.27, 0.20, 1]],
        ["accent", [0.72, 0.50, 0.18, 1]], ["accentActive", [0.90, 0.70, 0.32, 1]], ["trim", [0.34, 0.39, 0.36, 0.94]],
        ["text", [0.91, 0.84, 0.65, 1]], ["muted", [0.62, 0.56, 0.42, 1]], ["success", [0.36, 0.66, 0.30, 1]],
        ["warning", [0.88, 0.62, 0.14, 1]], ["danger", [0.52, 0.30, 0.70, 1]], ["railMode", "DOUBLE"],
        ["sourcePrefix", "MINISTRY // "], ["sourceSuffix", " // ENGINE"], ["titlePrefix", "DIRECTIVE: "], ["titleSuffix", ""], ["motif", "HEAVY INDUSTRY"],
        ["copyMode", "HERALDIC"], ["widthScale", 0.88],
        ["chromeMode", "DIESEL"], ["chromePrimary", [0.48, 0.34, 0.16, 0.98]], ["chromeSecondary", [0.035, 0.040, 0.038, 0.99]], ["chromeTertiary", [0.30, 0.35, 0.32, 0.94]], ["source", [0.68, 0.61, 0.45, 1]], ["sourceHex", "#AD9C73"],
        ["textHex", "#E8D6A6"], ["mutedHex", "#9E8F6B"], ["accentHex", "#B8802E"],
        ["successHex", "#5CA84D"], ["warningHex", "#E09E24"], ["dangerHex", "#854DB3"]
    ]],
    ["MERCENARY", createHashMapFromArray [
        ["id", "MERCENARY"], ["label", "Mercenary / Field Contract"], ["font", "RobotoCondensed"], ["fontBold", "RobotoCondensedBold"],
        ["shade", [0.040, 0.040, 0.025, 0.78]], ["panel", [0.60, 0.56, 0.38, 0.90]], ["panelAlt", [0.48, 0.46, 0.30, 0.94]],
        ["header", [0.16, 0.24, 0.18, 1]], ["button", [0.35, 0.36, 0.22, 1]], ["buttonActive", [0.05, 0.38, 0.34, 1]],
        ["edit", [0.70, 0.66, 0.46, 1]], ["list", [0.55, 0.52, 0.34, 1]], ["casing", [0.15, 0.18, 0.14, 1]],
        ["accent", [0.05, 0.38, 0.34, 1]], ["accentActive", [0.08, 0.56, 0.50, 1]], ["trim", [0.14, 0.25, 0.20, 0.88]],
        ["text", [0.060, 0.080, 0.060, 1]], ["muted", [0.20, 0.24, 0.18, 1]], ["success", [0.12, 0.48, 0.26, 1]],
        ["warning", [0.91, 0.67, 0.18, 1]], ["danger", [0.54, 0.30, 0.72, 1]], ["railMode", "BOTTOM"],
        ["sourcePrefix", "FIELD JOB // "], ["sourceSuffix", " // PAID"], ["titlePrefix", "JOB: "], ["titleSuffix", ""], ["motif", "CONTRACT COPY"],
        ["copyMode", "DOSSIER"], ["widthScale", 0.86],
        ["chromeMode", "CONTRACT"], ["chromePrimary", [0.16, 0.24, 0.18, 0.96]], ["chromeSecondary", [0.70, 0.66, 0.46, 0.58]], ["chromeTertiary", [0.05, 0.38, 0.34, 0.86]], ["source", [0.92, 0.90, 0.72, 1]], ["sourceHex", "#EBE6B8"],
        ["textHex", "#0F140F"], ["mutedHex", "#333D2E"], ["accentHex", "#0D6157"],
        ["successHex", "#1F7A42"], ["warningHex", "#A36B0F"], ["dangerHex", "#8A4DB8"]
    ]],
    ["PROPAGANDA", createHashMapFromArray [
        ["id", "PROPAGANDA"], ["label", "Propaganda / Central Broadcast"], ["font", "PuristaMedium"], ["fontBold", "PuristaBold"],
        ["shade", [0.006, 0.012, 0.040, 0.90]], ["panel", [0.025, 0.080, 0.24, 0.94]], ["panelAlt", [0.060, 0.14, 0.36, 0.98]],
        ["header", [0.080, 0.18, 0.48, 1]], ["button", [0.055, 0.13, 0.34, 1]], ["buttonActive", [0.76, 0.58, 0.16, 1]],
        ["edit", [0.015, 0.055, 0.18, 1]], ["list", [0.020, 0.065, 0.20, 1]], ["casing", [0.12, 0.18, 0.34, 1]],
        ["accent", [0.78, 0.60, 0.20, 1]], ["accentActive", [0.96, 0.78, 0.36, 1]], ["trim", [0.78, 0.76, 0.66, 0.90]],
        ["text", [0.95, 0.92, 0.78, 1]], ["muted", [0.70, 0.68, 0.57, 1]], ["success", [0.30, 0.68, 0.47, 1]],
        ["warning", [0.93, 0.68, 0.18, 1]], ["danger", [0.55, 0.28, 0.74, 1]], ["railMode", "DOUBLE"],
        ["sourcePrefix", "STATE WIRE // "], ["sourceSuffix", ""], ["titlePrefix", "DIRECTIVE: "], ["titleSuffix", ""], ["motif", "OFFICIAL BULLETIN"],
        ["copyMode", "BROADCAST"], ["widthScale", 1.02],
        ["chromeMode", "BROADCAST"], ["chromePrimary", [0.080, 0.18, 0.48, 0.96]], ["chromeSecondary", [0.78, 0.60, 0.20, 0.96]], ["chromeTertiary", [0.78, 0.76, 0.66, 0.82]], ["source", [0.95, 0.92, 0.78, 1]], ["sourceHex", "#F2EBC7"],
        ["textHex", "#F2EBC7"], ["mutedHex", "#B3AD91"], ["accentHex", "#C79933"],
        ["successHex", "#4DAD78"], ["warningHex", "#EDAD2E"], ["dangerHex", "#8C47BD"]
    ]],
    ["EMERGENCY", createHashMapFromArray [
        ["id", "EMERGENCY"], ["label", "Emergency / Incident Command"], ["font", "RobotoCondensed"], ["fontBold", "RobotoCondensedBold"],
        ["shade", [0.012, 0.014, 0.018, 0.86]], ["panel", [0.035, 0.043, 0.052, 0.98]], ["panelAlt", [0.075, 0.086, 0.095, 1]],
        ["header", [0.20, 0.14, 0.055, 1]], ["button", [0.14, 0.105, 0.060, 1]], ["buttonActive", [0.90, 0.46, 0.06, 1]],
        ["edit", [0.028, 0.038, 0.044, 1]], ["list", [0.032, 0.042, 0.050, 1]], ["casing", [0.12, 0.13, 0.14, 1]],
        ["accent", [0.94, 0.48, 0.06, 1]], ["accentActive", [1, 0.64, 0.16, 1]], ["trim", [0.30, 0.72, 0.86, 0.90]],
        ["text", [0.96, 0.96, 0.94, 1]], ["muted", [0.67, 0.71, 0.73, 1]], ["success", [0.22, 0.72, 0.42, 1]],
        ["warning", [0.98, 0.70, 0.10, 1]], ["danger", [0.58, 0.26, 0.78, 1]], ["railMode", "DOUBLE"],
        ["sourcePrefix", "INCIDENT // "], ["sourceSuffix", " // ACTIVE"], ["titlePrefix", "ALERT: "], ["titleSuffix", ""], ["motif", "OPERATIONS"],
        ["copyMode", "DOSSIER"], ["widthScale", 0.92],
        ["chromeMode", "INCIDENT"], ["chromePrimary", [0.018, 0.024, 0.030, 0.98]], ["chromeSecondary", [0.82, 0.58, 0.16, 0.92]], ["chromeTertiary", [0.24, 0.34, 0.40, 0.76]],
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
    "casing", "accent", "accentActive", "trim", "text", "muted", "success", "warning", "danger",
    "chromePrimary", "chromeSecondary", "chromeTertiary", "source"
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
if (isNil {_resolved get "source"}) then {
    _resolved set ["source", _resolved getOrDefault ["muted", [0.62, 0.72, 0.82, 1]]];
};
{
    _x params ["_arrayToken", "_hexToken"];
    _resolved set [_hexToken, [_resolved getOrDefault [_arrayToken, [1, 1, 1, 1]]] call _colourToHex];
} forEach [
    ["text", "textHex"], ["muted", "mutedHex"], ["source", "sourceHex"], ["accent", "accentHex"],
    ["success", "successHex"], ["warning", "warningHex"], ["danger", "dangerHex"]
];
_resolved set ["colourVision", _vision getOrDefault ["id", "STANDARD"]];
_resolved set ["colourVisionLabel", _vision getOrDefault ["label", "Standard colour"]];
_resolved
