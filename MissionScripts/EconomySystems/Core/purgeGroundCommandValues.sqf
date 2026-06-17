/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - purgeGroundCommandValues
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_purgeGroundCommandValues via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if (!isNil "Waldo_fnc_EcoCommand_setGroundCommandUIDs") then {
        [[]] call Waldo_fnc_EcoCommand_setGroundCommandUIDs;
    };
