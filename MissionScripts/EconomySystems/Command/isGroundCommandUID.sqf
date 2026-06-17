/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCommand system - isGroundCommandUID
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCommand_isGroundCommandUID via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_uid", ""]];

    _uid = [_uid] call Waldo_fnc_EcoCommand_normalizeGroundCommandKey;
    if (_uid isEqualTo "") exitWith {false};

    ((call Waldo_fnc_EcoCommand_getGroundCommandUIDs) find _uid) >= 0
