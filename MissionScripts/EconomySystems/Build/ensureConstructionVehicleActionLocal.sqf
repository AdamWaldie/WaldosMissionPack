/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - ensureConstructionVehicleActionLocal
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_ensureConstructionVehicleActionLocal via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_vehicle", objNull]];

        if (!hasInterface) exitWith {-1};
        if (isNull _vehicle) exitWith {-1};
        if !(_vehicle getVariable ["WaldoEcoBuild_IsConstructionVehicle", false]) exitWith {-1};

        [
            _vehicle,
            "WaldoEcoBuild_PlayerConstructionActionAddedLocal",
            call Waldo_fnc_EcoBuild_getOfficialConstructionModeActionArgs
        ] call Waldo_fnc_EcoCore_publishPubZeusObjectAction

