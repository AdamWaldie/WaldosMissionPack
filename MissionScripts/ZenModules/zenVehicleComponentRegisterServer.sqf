/*
 * Author: WaldoTheWarfighter
 * Authenticates a ZEN curator request before invoking Waldo_fnc_VehicleComponentCatalogRegister. This
 * bridge only checks the requester is an assigned curator and reports the outcome back to them.
 *
 * Arguments:
 * 0: Classes <ARRAY of STRING>
 * 1: Label <STRING>
 * 2: SelectionName <STRING>
 * 3: TurretPath <ARRAY>
 * 4: Requester <OBJECT>
 *
 * Return Value:
 * Nothing.
 *
 * Current caller: Waldo_fnc_ZenVehicleComponentRegister.
 */

params [
    ["_classes", [], [[]]],
    ["_label", "", [""]],
    ["_selectionName", "", [""]],
    ["_turretPath", [], [[]]],
    ["_requester", objNull, [objNull]]
];
if (!isServer) exitWith {};

private _owner = remoteExecutedOwner;
if (_owner > 0 && {isNull _requester || {owner _requester != _owner} || {isNull getAssignedCuratorLogic _requester}}) exitWith {};

private _ok = [_classes, _label, _selectionName, _turretPath] call Waldo_fnc_VehicleComponentCatalogRegister;

if (_owner > 2) then {
    private _message = if (_ok) then {
        format ["'%1' registered for %2 - it now appears in Remove/Restore Component's picker for those classes.", _label, (_classes joinString ", ")]
    } else {
        "Registration failed - a class, label, and selection name are all required."
    };
    ["VEHICLE APPEARANCE", _message, ["ERROR", "SUCCESS"] select _ok, "VEHAPP_ZEN", 8] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _owner];
};
