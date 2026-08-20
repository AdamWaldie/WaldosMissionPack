/*
 * Author: WaldoTheWarfighter
 * Validation-gated reader for the ZEN "Vehicle Customisation - Editor" dialog's Pylon tab. Reads the
 * currently selected pylon/action/classname controls and returns a ready-to-queue
 * Waldo_fnc_VehicleWeaponLoadoutApply row, or an empty array on ANY invalid or incomplete input -
 * same "never let a blank/garbage row reach the pending list" contract as
 * Waldo_fnc_VehCust_collectTurretRow.
 *
 * Never mutates anything and never touches the pending list itself - purely reads controls off _disp.
 *
 * Arguments:
 * 0: Display <DISPLAY> - the open Vehicle Customisation - Editor display (optional, default: displayNull)
 *
 * Return Value:
 * Array - a Waldo_fnc_VehicleWeaponLoadoutApply PYLON row
 * [ "PYLON", [-1], pylonIndex, action, "", magazineClass, ammoOverride ], or [] when the current Pylon
 * tab selection/fields are invalid or incomplete.
 *
 * Example:
 * private _row = [_disp] call Waldo_fnc_VehCust_collectPylonRow;
 * if (_row isEqualTo []) exitWith {};
 *
 * Current callers: MissionScripts/CombatSystems/VehicleCustomization/vehicleCustomizationPromptEditor.sqf
 * (Pylon tab's Add Pylon Row button).
 */

params [["_disp", displayNull]];
if (isNull _disp) exitWith {[]};

private _pylonCombo = _disp getVariable ["WaldoVehCust_PylonCombo", controlNull];
private _actionCombo = _disp getVariable ["WaldoVehCust_PylonActionCombo", controlNull];
private _magEdit = _disp getVariable ["WaldoVehCust_PylonMagazineEdit", controlNull];
private _ammoEdit = _disp getVariable ["WaldoVehCust_PylonAmmoEdit", controlNull];
if (isNull _pylonCombo || {isNull _actionCombo} || {isNull _magEdit} || {isNull _ammoEdit}) exitWith {[]};

private _pylonIndexSel = lbCurSel _pylonCombo;
if (_pylonIndexSel < 0) exitWith {[]};
private _pylonIndex = parseNumber (_pylonCombo lbData _pylonIndexSel);
if (_pylonIndex <= 0) exitWith {[]};

private _actionIndex = lbCurSel _actionCombo;
if (_actionIndex < 0) exitWith {[]};
private _action = ["SET", "CLEAR"] param [_actionIndex, ""];
if (_action == "") exitWith {[]};

if (_action == "CLEAR") exitWith {
    ["PYLON", [-1], _pylonIndex, "CLEAR", "", "", 0]
};

private _magazineClass = trim (ctrlText _magEdit);
if (_magazineClass == "" || {!(isClass (configFile >> "CfgMagazines" >> _magazineClass))}) exitWith {[]};

private _ammo = parseNumber (ctrlText _ammoEdit);
if (_ammo < 0) then {_ammo = 0;};

["PYLON", [-1], _pylonIndex, "SET", "", _magazineClass, round _ammo]
