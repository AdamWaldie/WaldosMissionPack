/*
 * Author: Waldo
 * Ensure construction vehicle action local.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _vehicle <OBJECT> - vehicle (optional, default: objNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_vehicle] call Waldo_fnc_EcoBuild_ensureConstructionVehicleActionLocal;
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

