/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCommand system - isGroundCommandStoredKey
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCommand_isGroundCommandStoredKey via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_key", ""]];

    if !(_key isEqualType "") then {
        _key = str _key;
    };

    ((_key find "UID|") isEqualTo 0) || {(_key find "LOCAL|") isEqualTo 0}
