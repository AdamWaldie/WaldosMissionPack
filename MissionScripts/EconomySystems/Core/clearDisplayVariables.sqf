/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - clearDisplayVariables
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_clearDisplayVariables via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_disp", displayNull], ["_varNames", []]];
    if (isNull _disp) exitWith {};

    {
        _disp setVariable [_x, nil];
    } forEach _varNames;
