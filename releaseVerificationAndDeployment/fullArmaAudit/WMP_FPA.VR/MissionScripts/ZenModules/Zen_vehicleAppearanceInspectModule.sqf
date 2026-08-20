/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: reports the exact texture-slot indices/current textures and every named model
 * selection on the vehicle the module was placed directly on, via Waldo_fnc_VehicleAppearanceInspect -
 * the beginner-friendly answer to "what selection name do I hide to visually remove this vehicle's
 * turret?" and "which slot do I recolor?". No dialog - acts immediately, same pattern as
 * Waldo_fnc_ZenVehicleWeaponLoadoutInspect. Purely read-only, so it runs entirely on the curator's own
 * client with no server round-trip and no curator-authentication bridge.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module (unused).
 * 1: objectPos <OBJECT> - the vehicle the module was dropped on.
 *
 * Return Value:
 * Nothing - copies the report to the curator's clipboard, logs it to RPT, confirms both with a fast
 * notification, and shows a full-screen hint with the report.
 *
 * Current caller: the ZEN "Vehicle Appearance - Inspect" module registered by Waldo_fnc_ZenInitModules.
 */

if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};

params ["_modulePos", ["_objectPos", objNull]];

if (isNull _objectPos || {!(_objectPos isKindOf "AllVehicles")} || {_objectPos isKindOf "Man"}) exitWith {
    ["VEHICLE APPEARANCE", "Place this module directly on the vehicle you want to inspect.", "WARNING", "VEHAPP_ZEN", 8]
        call Waldo_fnc_FeatureNotifyLocal;
};

private _report = [_objectPos] call Waldo_fnc_VehicleAppearanceInspect;
_report params [["_textureSlots", []], ["_selectionNames", []], ["_reportText", ""], ["_pasteReadyText", ""]];
diag_log format ["[WMP VEHAPP INSPECT] curator=%1 vehicle=%2%3%4", name player, typeOf _objectPos, endl, _reportText];
// The clipboard gets just the comma-joined selection names - comment-free and safe to paste anywhere
// (e.g. Register Component's Selection Name field). The full prose report (which also carries an
// illustrative, not-necessarily-wanted pink texture example per slot) stays in the hint only, never
// the clipboard - matching the same paste-safety fix applied to Vehicle Weapon Loadout - Inspect.
if (_pasteReadyText != "") then {
    copyToClipboard _pasteReadyText;
    ["VEHICLE APPEARANCE", "Model selection names copied to clipboard and logged to RPT.", "SUCCESS", "VEHAPP_ZEN", 6] call Waldo_fnc_FeatureNotifyLocal;
} else {
    ["VEHICLE APPEARANCE", "This vehicle has no named model selections. Report logged to RPT.", "WARNING", "VEHAPP_ZEN", 6] call Waldo_fnc_FeatureNotifyLocal;
};
hint format [
    "%1\n\nThe model selection names above have been copied to this client's clipboard - paste one into Vehicle Appearance - Register Component or Remove/Restore Component. Use a texture slot's index with Vehicle Appearance - Set Texture. Also logged to RPT under [WMP VEHAPP INSPECT].",
    _reportText
];
