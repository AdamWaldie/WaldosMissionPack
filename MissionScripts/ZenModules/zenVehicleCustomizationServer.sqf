/*
 * Author: WaldoTheWarfighter
 * Authenticates a ZEN curator request before invoking the normal server vehicle weapon/pylon/appearance/
 * component APIs, once per Apply click - the consolidated replacement for the 5 retired per-feature
 * bridges (zenVehicleWeaponLoadoutServer.sqf, zenVehicleWeaponLoadoutCopyServer.sqf,
 * zenVehicleAppearanceTextureServer.sqf, zenVehicleComponentRegisterServer.sqf,
 * zenVehicleComponentRemoveServer.sqf), which each ran their own curator-auth check separately. The
 * vehicle's actual turret/pylon/texture/component state remains owned by
 * Waldo_fnc_VehicleWeaponLoadoutApply, Waldo_fnc_VehicleAppearanceApply, and
 * Waldo_fnc_VehicleComponentRemove; this bridge only checks the requester is an assigned curator, then
 * dispatches the Vehicle Customisation - Editor's whole Pending Changes list by row type in one call.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: Rows <ARRAY> - Array of [rowType, rowData]:
 *      rowType "TURRET"|"PYLON" -> rowData is a Waldo_fnc_VehicleWeaponLoadoutApply row.
 *      rowType "APPEARANCE"     -> rowData is a Waldo_fnc_VehicleAppearanceApply row.
 *      rowType "COMPONENT"      -> rowData is [selectionName, turretPath, hide].
 * 2: Requester <OBJECT>
 *
 * Return Value:
 * Array of [ok, detail] - one entry per row actually dispatched, in TURRET/PYLON, then APPEARANCE,
 * then COMPONENT order (not necessarily the caller's original row order); empty when the request was
 * rejected or no rows were given.
 *
 * Example:
 * [truck1, [["TURRET", ["TURRET", [-1], -1, "REPLACE", "arifle_MX_F", "30Rnd_65x39_caseless_mag", 30, 4]]], player]
 *     remoteExecCall ["Waldo_fnc_ZenVehicleCustomizationServer", 2];
 *
 * Current caller: MissionScripts/CombatSystems/VehicleCustomization/vehicleCustomizationPromptEditor.sqf
 * (Apply All Pending button).
 */

params [["_vehicle", objNull, [objNull]], ["_rows", [], [[]]], ["_requester", objNull, [objNull]]];
if (!isServer) exitWith {[]};

private _owner = remoteExecutedOwner;
if (_owner > 0 && {isNull _requester || {owner _requester != _owner} || {isNull getAssignedCuratorLogic _requester}}) exitWith {[]};
if (isNull _vehicle || {_rows isEqualTo []}) exitWith {[]};

private _turretPylonRows = (_rows select {(_x select 0) in ["TURRET", "PYLON"]}) apply {_x select 1};
private _appearanceRows = (_rows select {(_x select 0) == "APPEARANCE"}) apply {_x select 1};
private _componentRows = (_rows select {(_x select 0) == "COMPONENT"}) apply {_x select 1};

private _results = [];
if (count _turretPylonRows > 0) then {
    _results append ([_vehicle, _turretPylonRows] call Waldo_fnc_VehicleWeaponLoadoutApply);
};
if (count _appearanceRows > 0) then {
    _results append ([_vehicle, _appearanceRows] call Waldo_fnc_VehicleAppearanceApply);
};
{
    _x params [["_sel", ""], ["_tp", []], ["_hide", true]];
    _results pushBack (([_vehicle, _sel, _tp, _hide] call Waldo_fnc_VehicleComponentRemove) select 0);
} forEach _componentRows;

private _okCount = {_x select 0} count _results;

if (_owner > 2) then {
    private _state = "ERROR";
    private _message = "No changes were applied.";
    if (count _results > 0) then {
        _message = format ["%1/%2 change(s) applied to %3.", _okCount, count _results, typeOf _vehicle];
        private _failed = _results select {!(_x select 0)};
        if (count _failed > 0) then { _message = _message + format [" %1", (_failed select 0) select 1]; };
        _state = ["WARNING", "SUCCESS"] select (_okCount == count _results);
        if (_okCount == 0) then { _state = "ERROR"; };
    };
    ["VEHICLE CUSTOMISATION", _message, _state, "VEHCUST_ZEN", 8] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _owner];
};

_results
