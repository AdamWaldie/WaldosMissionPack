/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getCurrentZoneForUnit
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getCurrentZoneForUnit via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_unit", objNull]];

    if (isNull _unit) exitWith {[]};
    [getPosATL _unit] call Waldo_fnc_EcoResource_getZoneAtPos
