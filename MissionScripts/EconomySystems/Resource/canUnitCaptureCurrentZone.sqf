/*
 * Author: Waldo
 * Can unit capture current zone.
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
 * [_unit] call Waldo_fnc_EcoResource_canUnitCaptureCurrentZone;
 */

    params [["_unit", objNull]];

    if (isNull _unit) exitWith {false};
    private _zone = [_unit] call Waldo_fnc_EcoResource_getCurrentZoneForUnit;
    private _zoneId = _zone param [0, ""];
    if (_zoneId isEqualTo "") exitWith {false};

    private _sideKey = [side group _unit] call Waldo_fnc_EcoResource_getSideKeyFromSide;
    private _ownerSideKey = _zone param [5, "NONE"];
    (_sideKey in ["WEST", "EAST", "GUER"]) && {_ownerSideKey isNotEqualTo _sideKey}
