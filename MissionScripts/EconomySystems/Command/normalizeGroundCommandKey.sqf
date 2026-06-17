/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCommand system - normalizeGroundCommandKey
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCommand_normalizeGroundCommandKey via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_key", ""]];

    if !(_key isEqualType "") then {
        _key = str _key;
    };

    _key
