/*
 * Author: Waldo
 * Can unit view current zone.
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
 * [_unit] call Waldo_fnc_EcoResource_canUnitViewCurrentZone;
 */

    params [["_unit", objNull]];

    if (isNull _unit) exitWith {false};
    private _zone = [_unit] call Waldo_fnc_EcoResource_getCurrentZoneForUnit;
    (_zone param [0, ""]) isNotEqualTo ""
