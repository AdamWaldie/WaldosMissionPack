/*
 * Author: WaldoTheWarfighter
 * Read-only helper behind the ZEN "Vehicle Customisation - Inspect" module: merges
 * Waldo_fnc_VehicleWeaponLoadoutInspect's and Waldo_fnc_VehicleAppearanceInspect's reports for one
 * vehicle into a single combined report and a single combined clipboard payload, so a curator gets
 * one hint and one clipboard copy instead of needing two separate Inspect modules. Neither underlying
 * function is reimplemented here - both are called unchanged and their output is concatenated. Never
 * mutates anything; safe to call on any machine, no server hop, no authorisation needed (nothing here
 * is more sensitive than looking at the vehicle in Eden already would tell you).
 *
 * Arguments:
 * 0: Vehicle <OBJECT> - the vehicle to inspect.
 *
 * Return Value:
 * Array [reportText, pasteReadyClipboard]:
 *   reportText: STRING - the weapon-loadout report followed by the appearance report, separated by a
 *     clear section header - for reading (hint), not for pasting whole into an Eden init field.
 *   pasteReadyClipboard: STRING - Waldo_fnc_VehicleWeaponLoadoutInspect's ready-to-paste call and
 *     Waldo_fnc_VehicleAppearanceInspect's comma-joined selection names, joined by a blank line - this
 *     is what gets copied to the clipboard, not reportText. Either half is omitted when that
 *     underlying function had nothing to offer (e.g. a vehicle with no non-horn weapons still reports
 *     its texture slots).
 *
 * Example:
 * private _report = [cursorObject] call Waldo_fnc_VehicleCustomizationInspect;
 * hint (_report select 0);
 *
 * Current caller: the ZEN "Vehicle Customisation - Inspect" module (Zen_vehicleCustomizationInspectModule.sqf).
 */

params [["_vehicle", objNull, [objNull]]];

if (isNull _vehicle || {!(_vehicle isKindOf "AllVehicles")} || {_vehicle isKindOf "Man"}) exitWith {
    ["Not a valid vehicle to inspect.", ""]
};

private _weaponReport = [_vehicle] call Waldo_fnc_VehicleWeaponLoadoutInspect;
_weaponReport params [["_turretReport", []], ["_pylonReport", []], ["_weaponReportText", ""], ["_weaponPasteReady", ""]];

private _appearanceReport = [_vehicle] call Waldo_fnc_VehicleAppearanceInspect;
_appearanceReport params [["_textureSlots", []], ["_selectionNames", []], ["_appearanceReportText", ""], ["_appearancePasteReady", ""]];

private _combinedText = format [
    "%1%2%3--- APPEARANCE ---%4%5",
    _weaponReportText, endl, endl, endl, _appearanceReportText
];

private _clipboardParts = [];
if (_weaponPasteReady != "") then {_clipboardParts pushBack _weaponPasteReady;};
if (_appearancePasteReady != "") then {_clipboardParts pushBack _appearancePasteReady;};
private _combinedClipboard = _clipboardParts joinString (endl + endl);

[_combinedText, _combinedClipboard]
