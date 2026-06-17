/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCommand system - isGroundCommandUnit
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCommand_isGroundCommandUnit via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_unit", objNull]];

    if (isNull _unit) exitWith {false};

    private _unitKey = [_unit] call Waldo_fnc_EcoCommand_getGroundCommandKey;
    if (_unitKey isEqualTo "") exitWith {false};

    ((call Waldo_fnc_EcoCommand_getGroundCommandUIDs) find _unitKey) >= 0
