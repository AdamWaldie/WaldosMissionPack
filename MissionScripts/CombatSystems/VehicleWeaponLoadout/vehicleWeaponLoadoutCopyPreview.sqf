/*
 * Author: WaldoTheWarfighter
 * Read-only counterpart to Waldo_fnc_VehicleWeaponLoadoutCopy: builds the exact turret/pylon rows a
 * Copy would apply, without applying anything. Purely client-local, no server round-trip - safe to
 * call from any interface client at any time. Shares its read/build logic with
 * Waldo_fnc_VehicleWeaponLoadoutCopy via Waldo_fnc_VehicleWeaponLoadoutCopyBuildRows.
 *
 * Built for the ZEN "Vehicle Customisation - Editor" dialog's "Copy From Nearby Vehicle" action: the
 * curator picks a source vehicle, this returns the rows that would apply its loadout, and the Editor
 * pushes each one into its pending-changes list individually (fully populated, zero typing) rather
 * than applying immediately - so the curator can still remove/edit individual copied rows before
 * committing, and can combine a copy with other turret/pylon/appearance/component changes in the
 * same session.
 *
 * Arguments:
 * 0: Source <OBJECT> - the vehicle to read the loadout from. Never modified.
 * 1: Target <OBJECT> - the vehicle the rows would be applied onto (used only to check which turret
 *    paths/pylon count the target actually has - never modified here).
 * 2: Options <ARRAY or HASHMAP> - optional named settings: copyTurrets <BOOL> (default true),
 *    copyPylons <BOOL> (default true).
 *
 * Return Value:
 * Array [rows, copiedTurretPaths, copiedPylonIndices] - rows is a Waldo_fnc_VehicleWeaponLoadoutApply-
 * ready row array, one entry per turret/pylon that genuinely matched between the two vehicles.
 *
 * Current callers: MissionScripts/CombatSystems/VehicleCustomization/vehicleCustomizationPromptEditor.sqf.
 *
 * Example:
 * private _preview = [donorVehicle, targetVehicle] call Waldo_fnc_VehicleWeaponLoadoutCopyPreview;
 * _preview params ["_rows", "_copiedTurretPaths", "_copiedPylonIndices"];
 */

params [
    ["_source", objNull, [objNull]],
    ["_target", objNull, [objNull]],
    ["_options", [], [[], createHashMap]]
];

if !(hasInterface) exitWith {[[], [], []]};

private _isValidVehicle = {
    !(isNull _this) && {_this isKindOf "AllVehicles"} && {!(_this isKindOf "Man")}
};
if !(_source call _isValidVehicle && {_target call _isValidVehicle}) exitWith {[[], [], []]};

[_source, _target, _options] call Waldo_fnc_VehicleWeaponLoadoutCopyBuildRows
