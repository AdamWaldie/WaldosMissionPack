/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getPrimaryResourceType
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getPrimaryResourceType via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_rows", []]];
    if ((count _rows) <= 0) exitWith {"Resource"};
    (_rows select 0) param [0, "Resource"]
