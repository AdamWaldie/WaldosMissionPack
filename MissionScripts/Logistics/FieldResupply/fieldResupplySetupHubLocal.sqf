/*
 * Author: Waldo
 * Adds the local refill action to one registered supply hub.
 *
 * Arguments: 0: hub <OBJECT>
 * Return Value: Boolean
 */

params [["_hub", objNull, [objNull]]];
if !(hasInterface) exitWith {false};
if (isNull _hub || {_hub getVariable ["Waldo_FieldResupply_LocalAction", -1] >= 0}) exitWith {false};
private _action = _hub addAction [
    "Refill Field Resupply Carrier",
    {params ["_target", "_caller"]; [_caller, "REFILL", [_target]] remoteExecCall ["Waldo_fnc_FieldResupplyServerHandle", 2]},
    [], 1.5, true, true, "", "_this distance _target <= 4", 4
];
_hub setVariable ["Waldo_FieldResupply_LocalAction", _action];
true
