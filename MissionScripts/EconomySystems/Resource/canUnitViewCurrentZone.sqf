/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - canUnitViewCurrentZone
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_canUnitViewCurrentZone via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_unit", objNull]];

    if (isNull _unit) exitWith {false};
    private _zone = [_unit] call Waldo_fnc_EcoResource_getCurrentZoneForUnit;
    (_zone param [0, ""]) isNotEqualTo ""
