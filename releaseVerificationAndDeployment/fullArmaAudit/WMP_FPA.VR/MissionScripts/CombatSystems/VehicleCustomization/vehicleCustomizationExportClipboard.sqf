/*
 * Author: WaldoTheWarfighter
 * Builds one combined, ready-to-paste Eden-init-field snippet from whatever is currently sitting in
 * the ZEN "Vehicle Customisation - Editor" dialog's Pending Changes list, and copies it to this
 * client's clipboard. Purely client-local - no server call, works standalone without ever pressing
 * Apply, and never clears or mutates the pending list. Only emits a
 * Waldo_fnc_VehicleWeaponLoadoutApply / Waldo_fnc_VehicleAppearanceApply / Waldo_fnc_VehicleComponentRemove
 * statement for the row-types actually present in pending - a session with only Appearance rows queued
 * never gets an empty weapon-loadout call in the pasted text.
 *
 * Follows the established convention already proven in Waldo_fnc_VehicleWeaponLoadoutInspect's
 * pasteReadyCall and MissionScripts/ZenModules/RuntimeControl/featureRuntimeZen.sqf: build via
 * format, copyToClipboard the exact comment-free string, diag_log the same string, and let the caller
 * confirm separately via hint/Waldo_fnc_FeatureNotifyLocal - never combine the confirmation text with
 * the clipboard payload itself.
 *
 * Arguments:
 * 0: Display <DISPLAY> - the open Vehicle Customisation - Editor display (optional, default: displayNull)
 *
 * Return Value:
 * Boolean - true when something was pending and copied to the clipboard, false when the pending list
 * was empty (nothing copied).
 *
 * Example:
 * private _ok = [_disp] call Waldo_fnc_VehCust_exportClipboard;
 *
 * Current callers: MissionScripts/CombatSystems/VehicleCustomization/vehicleCustomizationPromptEditor.sqf
 * (Export All Pending To Clipboard button).
 */

params [["_disp", displayNull]];
if (isNull _disp) exitWith {false};

private _rows = _disp getVariable ["WaldoVehCust_PendingRows", []];
if (_rows isEqualTo []) exitWith {false};

private _turretPylonRows = (_rows select {(_x select 1) in ["TURRET", "PYLON"]}) apply {_x select 2};
private _appearanceRows = (_rows select {(_x select 1) == "APPEARANCE"}) apply {_x select 2};
private _componentRows = (_rows select {(_x select 1) == "COMPONENT"}) apply {_x select 2};

private _statements = [];

if (count _turretPylonRows > 0) then {
    private _rowLines = _turretPylonRows apply {format ["    %1", str _x]};
    _statements pushBack format ["[this, [%1%2%3]] call Waldo_fnc_VehicleWeaponLoadoutApply;", endl, _rowLines joinString ("," + endl), endl];
};

if (count _appearanceRows > 0) then {
    private _rowLines = _appearanceRows apply {format ["    %1", str _x]};
    _statements pushBack format ["[this, [%1%2%3]] call Waldo_fnc_VehicleAppearanceApply;", endl, _rowLines joinString ("," + endl), endl];
};

{
    _x params [["_sel", ""], ["_tp", []], ["_hide", true]];
    _statements pushBack format ["[this, %1, %2, %3] call Waldo_fnc_VehicleComponentRemove;", str _sel, str _tp, str _hide];
} forEach _componentRows;

if (_statements isEqualTo []) exitWith {false};

private _pasteText = _statements joinString (endl + endl);
copyToClipboard _pasteText;
diag_log format ["[WMP VEHCUST EXPORT] %1", _pasteText];
true
