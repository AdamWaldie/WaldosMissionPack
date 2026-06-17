/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - spawnResearchCenter
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_spawnResearchCenter via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_pos", [0, 0, 0]]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {objNull};

        private _researchCenter = createVehicle ["Land_Research_HQ_F", _pos, [], 0, "CAN_COLLIDE"];
        _researchCenter setVehiclePosition [_pos, [], 0, "CAN_COLLIDE"];
        _researchCenter setVariable ["WaldoEcoResearch_IsResearchCenter", true, true];

        if (!isNil "Waldo_fnc_EcoResource_registerCuratorEditableObject") then {
            [_researchCenter, true] call Waldo_fnc_EcoResource_registerCuratorEditableObject;
        };

        if (hasInterface) then {
            [_researchCenter] call Waldo_fnc_EcoResearch_ensureResearchCenterActionsLocal;
        };

        _researchCenter

