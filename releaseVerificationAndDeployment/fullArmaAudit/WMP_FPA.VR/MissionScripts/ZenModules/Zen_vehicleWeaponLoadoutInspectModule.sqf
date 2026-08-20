/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: reports the exact weapon/magazine/pylon classnames currently on the vehicle
 * the module was placed directly on, via Waldo_fnc_VehicleWeaponLoadoutInspect - the beginner-friendly
 * answer to "how do I find the exact classname to use with Vehicle Weapon Loadout - Configure". No
 * dialog - acts immediately, same pattern as Waldo_fnc_ZenHeadlessForceRebalance. Purely read-only,
 * so unlike Configure it runs entirely on the curator's own client with no server round-trip and no
 * curator-authentication bridge - nothing here is more sensitive than looking at the vehicle in Eden
 * already would tell you.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module (unused).
 * 1: objectPos <OBJECT> - the vehicle the module was dropped on.
 *
 * Return Value:
 * Nothing - copies the report to the curator's clipboard, logs it to RPT, and shows a full-screen
 * hint with the report and copy-paste-ready rows plus a fast confirmation that the clipboard copy
 * happened.
 *
 * Example:
 * [_modulePos, _objectPos] call Waldo_fnc_ZenVehicleWeaponLoadoutInspect;
 *
 * Current caller: the ZEN "Vehicle Weapon Loadout - Inspect" module registered by
 * Waldo_fnc_ZenInitModules.
 */

if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};

params ["_modulePos", ["_objectPos", objNull]];

if (isNull _objectPos || {!(_objectPos isKindOf "AllVehicles")} || {_objectPos isKindOf "Man"}) exitWith {
    ["VEHICLE WEAPON LOADOUT", "Place this module directly on the vehicle you want to inspect.", "WARNING", "VEHWPN_ZEN", 8]
        call Waldo_fnc_FeatureNotifyLocal;
};

private _report = [_objectPos] call Waldo_fnc_VehicleWeaponLoadoutInspect;
_report params [["_turretReport", []], ["_pylonReport", []], ["_reportText", ""], ["_pasteReadyCall", ""]];
diag_log format ["[WMP VEHWPN INSPECT] curator=%1 vehicle=%2%3%4", name player, typeOf _objectPos, endl, _reportText];
// The clipboard gets the single, comment-free, already-combined call - never the full prose report.
// Pasting the whole human-readable report (with its "Turret X: weapon=... magazines=..." lines and
// individual comma-terminated rows) directly into an Eden init field is exactly the kind of paste a
// beginner would attempt, and a stray inline comment in a manually-adapted version of it is a
// confirmed real-world failure mode ("Invalid number in expression") if the paste doesn't keep real
// line breaks - this field is built to be safe to paste as-is, nothing else needed.
if (_pasteReadyCall != "") then {
    copyToClipboard _pasteReadyCall;
    ["VEHICLE WEAPON LOADOUT", "Ready-to-paste call copied to clipboard (paste directly into a unit's Eden init field) and logged to RPT.", "SUCCESS", "VEHWPN_ZEN", 6] call Waldo_fnc_FeatureNotifyLocal;
} else {
    ["VEHICLE WEAPON LOADOUT", "Nothing to copy - this vehicle has no non-horn weapons or loaded pylons. Report logged to RPT.", "WARNING", "VEHWPN_ZEN", 6] call Waldo_fnc_FeatureNotifyLocal;
};
hint format [
    "%1\n\nA single ready-to-paste call combining every row above has been copied to this client's clipboard - paste it directly into a unit's Eden init field. Also logged to RPT under [WMP VEHWPN INSPECT].",
    _reportText
];
