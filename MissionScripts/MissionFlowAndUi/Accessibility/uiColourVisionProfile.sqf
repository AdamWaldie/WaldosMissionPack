/*
 * Author: WaldoTheWarfighter
 * Resolves one local colour-vision accessibility profile. Profiles override only semantic and
 * focus colours; the selected era theme continues to own typography, materials and neutral chrome.
 * WMP UI also retains state words, icons and symbols so colour is never the sole state indicator.
 *
 * Arguments:
 * 0: profile id <STRING> (default profileNamespace Waldo_UI_ColourVisionProfile)
 *
 * Return Value: HASHMAP - id, label, description and colour-token overrides.
 *
 * Example:
 * private _profile = ["RED_GREEN"] call Waldo_fnc_UiColourVisionProfile;
 * Current callers: UiTheme, UiColourVisionApplyLocal and UiColourVisionOpenLocal.
 */

params [["_requested", profileNamespace getVariable ["Waldo_UI_ColourVisionProfile", "STANDARD"], [""]]];
private _id = toUpperANSI _requested;
private _profiles = createHashMapFromArray [
    ["STANDARD", createHashMapFromArray [
        ["id", "STANDARD"], ["label", "Standard colour"],
        ["description", "Use the selected era theme's original semantic palette."],
        ["overrides", createHashMap]
    ]],
    ["RED_GREEN", createHashMapFromArray [
        ["id", "RED_GREEN"], ["label", "Red-green aware"],
        ["description", "Blue, cyan, amber and violet states with stronger luminance separation."],
        ["overrides", createHashMapFromArray [
            ["accent", [0.15, 0.68, 0.95, 1]], ["accentActive", [0.35, 0.84, 1, 1]],
            ["success", [0.00, 0.55, 0.78, 1]], ["warning", [0.95, 0.68, 0.08, 1]],
            ["danger", [0.72, 0.34, 0.88, 1]], ["accentHex", "#4CC9F0"],
            ["successHex", "#0096C7"], ["warningHex", "#F2AD14"], ["dangerHex", "#B75AE0"]
        ]]
    ]],
    ["PROTAN", createHashMapFromArray [
        ["id", "PROTAN"], ["label", "Protan aware"],
        ["description", "Avoids dark red cues and separates states with cyan, blue, gold and magenta."],
        ["overrides", createHashMapFromArray [
            ["accent", [0.05, 0.72, 0.88, 1]], ["accentActive", [0.25, 0.90, 1, 1]],
            ["success", [0.12, 0.48, 0.88, 1]], ["warning", [0.98, 0.73, 0.12, 1]],
            ["danger", [0.88, 0.30, 0.68, 1]], ["accentHex", "#20C5E5"],
            ["successHex", "#3B82E6"], ["warningHex", "#F5BE2A"], ["dangerHex", "#E052A8"]
        ]]
    ]],
    ["TRITAN", createHashMapFromArray [
        ["id", "TRITAN"], ["label", "Blue-yellow aware"],
        ["description", "Uses turquoise, green, vermilion and magenta with explicit state symbols."],
        ["overrides", createHashMapFromArray [
            ["accent", [0.08, 0.78, 0.68, 1]], ["accentActive", [0.28, 0.95, 0.84, 1]],
            ["success", [0.14, 0.68, 0.38, 1]], ["warning", [0.92, 0.43, 0.16, 1]],
            ["danger", [0.86, 0.22, 0.55, 1]], ["accentHex", "#35D6B8"],
            ["successHex", "#42B96B"], ["warningHex", "#ED7130"], ["dangerHex", "#DD3D8C"]
        ]]
    ]],
    ["HIGH_CONTRAST", createHashMapFromArray [
        ["id", "HIGH_CONTRAST"], ["label", "High-contrast monochrome"],
        ["description", "Near-monochrome presentation with maximum text contrast and symbol-led states."],
        ["overrides", createHashMapFromArray [
            ["shade", [0, 0, 0, 0.88]], ["panel", [0.01, 0.01, 0.01, 0.99]],
            ["panelAlt", [0.10, 0.10, 0.10, 1]], ["header", [0.16, 0.16, 0.16, 1]],
            ["casing", [0.04, 0.04, 0.04, 1]], ["button", [0.14, 0.14, 0.14, 1]],
            ["edit", [0.02, 0.02, 0.02, 1]], ["list", [0.02, 0.02, 0.02, 1]], ["text", [1, 1, 1, 1]],
            ["muted", [0.78, 0.78, 0.78, 1]], ["accent", [1, 1, 1, 1]],
            ["accentActive", [0.82, 0.82, 0.82, 1]], ["success", [0.88, 0.88, 0.88, 1]],
            ["warning", [0.68, 0.68, 0.68, 1]], ["danger", [1, 1, 1, 1]],
            ["textHex", "#FFFFFF"], ["mutedHex", "#C8C8C8"], ["accentHex", "#FFFFFF"],
            ["successHex", "#E0E0E0"], ["warningHex", "#ADADAD"], ["dangerHex", "#FFFFFF"]
        ]]
    ]]
];
if (isNil {_profiles get _id}) then {_id = "STANDARD";};
_profiles get _id
