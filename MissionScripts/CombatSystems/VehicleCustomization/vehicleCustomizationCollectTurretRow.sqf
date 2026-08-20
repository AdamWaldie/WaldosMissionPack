/*
 * Author: WaldoTheWarfighter
 * Validation-gated reader for the ZEN "Vehicle Customisation - Editor" dialog's Turret tab. Reads the
 * currently selected turret/action/classname controls and returns a ready-to-queue
 * Waldo_fnc_VehicleWeaponLoadoutApply row, or an empty array on ANY invalid or incomplete input.
 *
 * This is the direct fix for the confirmed root-cause bug in the retired "Vehicle Weapon Loadout -
 * Configure" module's Session Action queue, which always rebuilt a row from whatever was currently in
 * the form fields, even when blank - silently smuggling a garbage
 * [false, "Unknown weapon class: "] row into the queue alongside real ones. This collector never
 * returns a row unless every field it needs for the selected action is genuinely present and valid;
 * the caller (vehicleCustomizationPromptEditor.sqf's Add Turret Row handler) checks for [] and refuses
 * to push anything onto the pending list when it sees one.
 *
 * Never mutates anything and never touches the pending list itself - purely reads controls off _disp.
 *
 * Arguments:
 * 0: Display <DISPLAY> - the open Vehicle Customisation - Editor display (optional, default: displayNull)
 *
 * Return Value:
 * Array - a Waldo_fnc_VehicleWeaponLoadoutApply TURRET row
 * [ "TURRET", turretPath, -1, action, weaponClass, magazineClass, magazineCount, magazineQuantity ],
 * or [] when the current Turret tab selection/fields are invalid or incomplete.
 *
 * Example:
 * private _row = [_disp] call Waldo_fnc_VehCust_collectTurretRow;
 * if (_row isEqualTo []) exitWith {};
 *
 * Current callers: MissionScripts/CombatSystems/VehicleCustomization/vehicleCustomizationPromptEditor.sqf
 * (Turret tab's Add Turret Row button).
 */

params [["_disp", displayNull]];
if (isNull _disp) exitWith {[]};

private _turretCombo = _disp getVariable ["WaldoVehCust_TurretCombo", controlNull];
private _actionCombo = _disp getVariable ["WaldoVehCust_TurretActionCombo", controlNull];
private _weaponEdit = _disp getVariable ["WaldoVehCust_TurretWeaponEdit", controlNull];
private _magEdit = _disp getVariable ["WaldoVehCust_TurretMagazineEdit", controlNull];
private _countEdit = _disp getVariable ["WaldoVehCust_TurretCountEdit", controlNull];
private _qtyEdit = _disp getVariable ["WaldoVehCust_TurretQuantityEdit", controlNull];
if (isNull _turretCombo || {isNull _actionCombo} || {isNull _weaponEdit} || {isNull _magEdit} || {isNull _countEdit} || {isNull _qtyEdit}) exitWith {[]};

private _turretIndex = lbCurSel _turretCombo;
if (_turretIndex < 0) exitWith {[]};
private _turretPath = parseSimpleArray (_turretCombo lbData _turretIndex);
if !(_turretPath isEqualType []) exitWith {[]};

private _actionIndex = lbCurSel _actionCombo;
if (_actionIndex < 0) exitWith {[]};
private _action = ["ADD", "REPLACE", "REMOVE", "CLEAR"] param [_actionIndex, ""];
if (_action == "") exitWith {[]};

if (_action == "CLEAR") exitWith {
    ["TURRET", _turretPath, -1, "CLEAR", "", "", 0, 1]
};

private _weaponClass = trim (ctrlText _weaponEdit);

if (_action == "REMOVE") exitWith {
    if (_weaponClass == "" || {!(isClass (configFile >> "CfgWeapons" >> _weaponClass))}) exitWith {[]};
    ["TURRET", _turretPath, -1, "REMOVE", _weaponClass, "", 0, 1]
};

// ADD / REPLACE - require a real CfgWeapons class; a blank or unknown classname is exactly the
// confirmed bug this collector exists to prevent from ever reaching the pending list.
if (_weaponClass == "" || {!(isClass (configFile >> "CfgWeapons" >> _weaponClass))}) exitWith {[]};

private _magazineClass = trim (ctrlText _magEdit);
if (_magazineClass != "" && {!(isClass (configFile >> "CfgMagazines" >> _magazineClass))}) exitWith {[]};

private _count = parseNumber (ctrlText _countEdit);
if (_count <= 0) then {_count = 1;};
private _qty = parseNumber (ctrlText _qtyEdit);
if (_qty <= 0) then {_qty = 1;};

["TURRET", _turretPath, -1, _action, _weaponClass, _magazineClass, round _count, round _qty]
