/*
 * Author: WaldoTheWarfighter
 * Authenticates a ZEN curator request before invoking the server vehicle weapon/ammo loadout copy
 * API. The source and target vehicles' actual turret/pylon state remains owned by
 * Waldo_fnc_VehicleWeaponLoadoutCopy; this bridge only checks the requester is an assigned curator
 * and reports the outcome back to them.
 *
 * Arguments:
 * 0: Source <OBJECT>
 * 1: Target <OBJECT>
 * 2: Options <ARRAY> - see Waldo_fnc_VehicleWeaponLoadoutCopy
 * 3: Requester <OBJECT>
 *
 * Return Value:
 * Array [copiedTurretPaths, copiedPylonIndices, applyResults] - same shape
 * Waldo_fnc_VehicleWeaponLoadoutCopy returns; empty entries when the request was rejected.
 *
 * Example:
 * [referenceVehicle, myJeep, [["copyTurrets", true], ["copyPylons", true]], player]
 *     remoteExecCall ["Waldo_fnc_ZenVehicleWeaponLoadoutCopyServer", 2];
 *
 * Current caller: Waldo_fnc_ZenVehicleWeaponLoadoutCopy.
 */

params [["_source", objNull, [objNull]], ["_target", objNull, [objNull]], ["_options", [], [[]]], ["_requester", objNull, [objNull]]];
if (!isServer) exitWith {[[], [], []]};

private _owner = remoteExecutedOwner;
if (_owner > 0 && {isNull _requester || {owner _requester != _owner} || {isNull getAssignedCuratorLogic _requester}}) exitWith {[[], [], []]};
if (isNull _source || {isNull _target}) exitWith {[[], [], []]};

private _report = [_source, _target, _options] call Waldo_fnc_VehicleWeaponLoadoutCopy;
_report params ["_copiedTurrets", "_copiedPylons", "_applyResults"];
private _okCount = {_x select 0} count _applyResults;

if (_owner > 2) then {
    private _state = "ERROR";
    private _message = format ["Nothing to copy - %1 shares no matching turret path or pylon slot with %2.", typeOf _target, typeOf _source];
    if (count _applyResults > 0) then {
        _message = format ["%1/%2 change(s) copied from %3 to %4.", _okCount, count _applyResults, typeOf _source, typeOf _target];
        _state = ["WARNING", "SUCCESS"] select (_okCount == count _applyResults);
        if (_okCount == 0) then { _state = "ERROR"; };
    };
    ["VEHICLE WEAPON LOADOUT", _message, _state, "VEHWPN_ZEN", 8] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _owner];
};

_report
