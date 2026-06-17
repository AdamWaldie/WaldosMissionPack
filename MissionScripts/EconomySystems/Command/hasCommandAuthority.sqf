/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCommand system - hasCommandAuthority
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCommand_hasCommandAuthority via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_unit", objNull]];

    if !((call Waldo_fnc_EcoCommand_hasAnyGroundCommand)) exitWith {true};
    if (isNull _unit) exitWith {false};
    [_unit] call Waldo_fnc_EcoCommand_isGroundCommandUnit
