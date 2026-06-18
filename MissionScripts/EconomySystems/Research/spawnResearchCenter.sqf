/*
 * Author: Waldo
 * Spawn research center.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _pos <ARRAY> - pos (optional, default: [0, 0, 0])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_pos] call Waldo_fnc_EcoResearch_spawnResearchCenter;
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

