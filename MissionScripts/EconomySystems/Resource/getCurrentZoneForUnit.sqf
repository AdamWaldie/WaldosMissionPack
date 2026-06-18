/*
 * Author: Waldo
 * Get current zone for unit.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _unit <OBJECT> - unit (optional, default: objNull)
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_unit] call Waldo_fnc_EcoResource_getCurrentZoneForUnit;
 */

    params [["_unit", objNull]];

    if (isNull _unit) exitWith {[]};
    [getPosATL _unit] call Waldo_fnc_EcoResource_getZoneAtPos
