/*
 * Author: WaldoTheWarfighter
 * Authenticates a ZEN curator request before invoking the normal server vehicle appearance API. The
 * vehicle's actual texture state remains owned by Waldo_fnc_VehicleAppearanceApply; this bridge only
 * checks the requester is an assigned curator and reports the outcome back to them.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: Rows <ARRAY> - see Waldo_fnc_VehicleAppearanceApply
 * 2: Requester <OBJECT>
 *
 * Return Value:
 * Array of [ok, detail] - same shape Waldo_fnc_VehicleAppearanceApply returns; empty when rejected.
 *
 * Current caller: Waldo_fnc_ZenVehicleAppearanceTexture.
 */

params [["_vehicle", objNull, [objNull]], ["_rows", [], [[]]], ["_requester", objNull, [objNull]]];
if (!isServer) exitWith {[]};

private _owner = remoteExecutedOwner;
if (_owner > 0 && {isNull _requester || {owner _requester != _owner} || {isNull getAssignedCuratorLogic _requester}}) exitWith {[]};
if (isNull _vehicle) exitWith {[]};

private _results = [_vehicle, _rows] call Waldo_fnc_VehicleAppearanceApply;
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
    ["VEHICLE APPEARANCE", _message, _state, "VEHAPP_ZEN", 8] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _owner];
};

_results
