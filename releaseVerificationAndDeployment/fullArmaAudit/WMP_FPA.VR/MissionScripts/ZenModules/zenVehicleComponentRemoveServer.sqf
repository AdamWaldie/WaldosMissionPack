/*
 * Author: WaldoTheWarfighter
 * Authenticates a ZEN curator request before invoking Waldo_fnc_VehicleComponentRemove. This bridge
 * only checks the requester is an assigned curator and reports the outcome back to them.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: SelectionName <STRING>
 * 2: TurretPath <ARRAY>
 * 3: Hide <BOOL>
 * 4: Requester <OBJECT>
 *
 * Return Value:
 * Array [appearanceResult, weaponResult] - same shape Waldo_fnc_VehicleComponentRemove returns;
 * [[], []] when rejected.
 *
 * Current caller: Waldo_fnc_ZenVehicleComponentRemove.
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_selectionName", "", [""]],
    ["_turretPath", [], [[]]],
    ["_hide", true, [true]],
    ["_requester", objNull, [objNull]]
];
if (!isServer) exitWith {[[], []]};

private _owner = remoteExecutedOwner;
if (_owner > 0 && {isNull _requester || {owner _requester != _owner} || {isNull getAssignedCuratorLogic _requester}}) exitWith {[[], []]};
if (isNull _vehicle) exitWith {[[], []]};

private _result = [_vehicle, _selectionName, _turretPath, _hide] call Waldo_fnc_VehicleComponentRemove;
_result params [["_appearanceResult", [false, ""]], ["_weaponResult", []]];

if (_owner > 2) then {
    private _verb = if (_hide) then {"removed"} else {"restored"};
    private _state = if (_appearanceResult select 0) then {"SUCCESS"} else {"ERROR"};
    private _message = format ["%1 (%2): %3", _verb, _selectionName, _appearanceResult select 1];
    if (count _weaponResult > 0) then {
        _message = _message + format [" | weapon: %1", _weaponResult select 1];
        if (!(_weaponResult select 0)) then { _state = "WARNING"; };
    };
    ["VEHICLE APPEARANCE", _message, _state, "VEHAPP_ZEN", 8] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _owner];
};

[_appearanceResult, _weaponResult]
