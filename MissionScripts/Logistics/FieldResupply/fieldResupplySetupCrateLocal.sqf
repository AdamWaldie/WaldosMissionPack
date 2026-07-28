/*
 * Author: Waldo
 * Adds local inspect, replenish and salvage actions to one deployed resupply crate.
 *
 * Arguments: 0: crate <OBJECT>
 * Return Value: Boolean
 */

params [["_crate", objNull, [objNull]]];
if !(hasInterface) exitWith {false};
if (isNull _crate || {_crate getVariable ["Waldo_FieldResupply_LocalSetup", false]}) exitWith {false};
_crate setVariable ["Waldo_FieldResupply_LocalSetup", true];
_crate addAction ["Inspect Field Resupply", {
    params ["_target"];
    ["FIELD RESUPPLY", format ["Charges remaining: %1.", _target getVariable ["Waldo_FieldResupply_Charges", 0]], "INFO", "FIELD_RESUPPLY"] call Waldo_fnc_FeatureNotifyLocal;
}, [], 1.5, true, true, "", "_this distance _target <= 4", 4];
_crate addAction ["Take Compatible Ammunition", {
    params ["_target", "_caller"];
    [_caller, "TAKE", [_target]] remoteExecCall ["Waldo_fnc_FieldResupplyServerHandle", 2];
}, [], 1.5, true, true, "", "_this distance _target <= 4 && {_target getVariable ['Waldo_FieldResupply_Charges', 0] > 0}", 4];
_crate addAction ["Salvage Field Resupply", {
    params ["_target", "_caller"];
    [_caller, "SALVAGE", [_target]] remoteExecCall ["Waldo_fnc_FieldResupplyServerHandle", 2];
}, [], 1.4, true, true, "", "_this distance _target <= 4", 4];
true
