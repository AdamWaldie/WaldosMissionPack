/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - canUnitCaptureCurrentZone
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_canUnitCaptureCurrentZone via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_unit", objNull]];

    if (isNull _unit) exitWith {false};
    private _zone = [_unit] call Waldo_fnc_EcoResource_getCurrentZoneForUnit;
    private _zoneId = _zone param [0, ""];
    if (_zoneId isEqualTo "") exitWith {false};

    private _sideKey = [side group _unit] call Waldo_fnc_EcoResource_getSideKeyFromSide;
    private _ownerSideKey = _zone param [5, "NONE"];
    (_sideKey in ["WEST", "EAST", "GUER"]) && {_ownerSideKey isNotEqualTo _sideKey}
