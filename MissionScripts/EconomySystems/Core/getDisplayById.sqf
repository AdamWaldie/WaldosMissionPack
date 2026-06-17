/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - getDisplayById
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_getDisplayById via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_idd", -1]];
    if (_idd < 0) exitWith {displayNull};
    findDisplay _idd
