/*
 * Author: WaldoTheWarfighter
 * Install the construction-mode action on a registered vehicle for this client.
 *
 * Locality / Authority: Interface client only; the shared publisher owns the local action.
 * Repeat/JIP: The action key prevents duplicate local installs; local world
 * action refresh calls this again for JIP or rebuilt client state.
 * Current Callers: EcoCore_refreshLocalWorldActions,
 * EcoBuild_spawnConstructionVehicle and EcoBuild_registerConstructionVehicle.
 *
 * Arguments:
 * 0: _vehicle <OBJECT> - vehicle (optional, default: objNull)
 *
 * Return Value:
 * NUMBER - shared action publisher's identifier, or -1 if ineligible.
 * Result: Adds or refreshes the vehicle's construction action locally.
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
        ] call Waldo_fnc_EcoCore_publishZeusObjectAction

