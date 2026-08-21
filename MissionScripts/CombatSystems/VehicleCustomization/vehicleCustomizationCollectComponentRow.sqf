/*
 * Author: WaldoTheWarfighter
 * Validation-gated reader for the ZEN "Vehicle Customisation - Editor" dialog's Component tab. Reads
 * the currently populated selection-name/turret-path/action controls (either typed manually or
 * auto-filled by picking a Waldo_fnc_VehicleComponentHeuristicScan candidate from the Component
 * picker) and returns a ready-to-queue row for Waldo_fnc_VehicleComponentRemove, or an empty array on
 * ANY invalid or incomplete input - same "never let a blank/garbage row reach the pending list"
 * contract as Waldo_fnc_VehCust_collectTurretRow.
 *
 * Never mutates anything and never touches the pending list itself - purely reads controls off _disp.
 *
 * Arguments:
 * 0: Display <DISPLAY> - the open Vehicle Customisation - Editor display (optional, default: displayNull)
 *
 * Return Value:
 * Array - [selectionName <STRING>, turretPath <ARRAY>, hide <BOOL>] ready to spread into
 * Waldo_fnc_VehicleComponentRemove as [vehicle, selectionName, turretPath, hide], or [] when the
 * current Component tab selection/fields are invalid or incomplete.
 *
 * Example:
 * private _row = [_disp] call Waldo_fnc_VehCust_collectComponentRow;
 * if (_row isEqualTo []) exitWith {};
 *
 * Current callers: MissionScripts/CombatSystems/VehicleCustomization/vehicleCustomizationPromptEditor.sqf
 * (Component tab's Add Component Row button).
 */

params [["_disp", displayNull]];
if (isNull _disp) exitWith {[]};

private _selEdit = _disp getVariable ["WaldoVehCust_ComponentSelectionEdit", controlNull];
private _turretEdit = _disp getVariable ["WaldoVehCust_ComponentTurretEdit", controlNull];
private _actionCombo = _disp getVariable ["WaldoVehCust_ComponentActionCombo", controlNull];
if (isNull _selEdit || {isNull _turretEdit} || {isNull _actionCombo}) exitWith {[]};

private _selectionName = trim (ctrlText _selEdit);
if (_selectionName == "") exitWith {[]};

private _turretPath = parseSimpleArray (ctrlText _turretEdit);
if !(_turretPath isEqualType []) then {_turretPath = [];};

private _actionIndex = lbCurSel _actionCombo;
if (_actionIndex < 0) exitWith {[]};
private _hide = _actionIndex == 0;

[_selectionName, _turretPath, _hide]
