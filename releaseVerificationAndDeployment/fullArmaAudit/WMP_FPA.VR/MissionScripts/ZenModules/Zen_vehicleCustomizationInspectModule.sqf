/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: reports the exact weapon/magazine/pylon/texture/selection state of the vehicle
 * the module was placed directly on, via Waldo_fnc_VehicleCustomizationInspect - merges what the
 * retired "Vehicle Weapon Loadout - Inspect" and "Vehicle Appearance - Inspect" modules each reported
 * separately into one hint and one clipboard copy. No dialog - acts immediately, same pattern as the
 * modules it replaces. Purely read-only, so it runs entirely on the curator's own client with no
 * server round-trip and no curator-authentication bridge - nothing here is more sensitive than looking
 * at the vehicle in Eden already would tell you.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module (unused).
 * 1: objectPos <OBJECT> - the vehicle the module was dropped on.
 *
 * Return Value:
 * Nothing - copies the combined report to the curator's clipboard, logs it to RPT, confirms with a
 * fast notification, and shows a full-screen hint with the combined report.
 *
 * Example:
 * [_modulePos, _objectPos] call Waldo_fnc_ZenVehicleCustomizationInspect;
 *
 * Current caller: the ZEN "Vehicle Customisation - Inspect" module registered by
 * Waldo_fnc_ZenInitModules under category "WMP Vehicle Customisation".
 */

if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};

params ["_modulePos", ["_objectPos", objNull]];

if (isNull _objectPos || {!(_objectPos isKindOf "AllVehicles")} || {_objectPos isKindOf "Man"}) exitWith {
    ["VEHICLE CUSTOMISATION", "Place this module directly on the vehicle you want to inspect.", "WARNING", "VEHCUST_ZEN", 8]
        call Waldo_fnc_FeatureNotifyLocal;
};

private _report = [_objectPos] call Waldo_fnc_VehicleCustomizationInspect;
_report params [["_reportText", ""], ["_pasteReadyClipboard", ""]];
diag_log format ["[WMP VEHCUST INSPECT] curator=%1 vehicle=%2%3%4", name player, typeOf _objectPos, endl, _reportText];

if (_pasteReadyClipboard != "") then {
    copyToClipboard _pasteReadyClipboard;
    ["VEHICLE CUSTOMISATION", "Combined weapon/pylon/appearance report copied to clipboard and logged to RPT.", "SUCCESS", "VEHCUST_ZEN", 6] call Waldo_fnc_FeatureNotifyLocal;
} else {
    ["VEHICLE CUSTOMISATION", "This vehicle has no non-horn weapons, loaded pylons, or named model selections to copy. Report logged to RPT.", "WARNING", "VEHCUST_ZEN", 6] call Waldo_fnc_FeatureNotifyLocal;
};

hint format [
    "%1\n\nReady-to-paste rows and selection names have been copied to this client's clipboard where available. Also logged to RPT under [WMP VEHCUST INSPECT].",
    _reportText
];
