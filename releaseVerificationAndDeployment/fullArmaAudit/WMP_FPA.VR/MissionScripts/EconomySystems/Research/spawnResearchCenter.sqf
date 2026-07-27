/*
 * Author: WaldoTheWarfighter
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

        // Authority-only creation. Called from client-side ZEN module / dialog code too,
        // so forward to the server when not the authority instead of no-opping (dedicated-safe).
        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {
            _this remoteExec ["Waldo_fnc_EcoResearch_spawnResearchCenter", 2];
            objNull
        };

        private _researchCenter = createVehicle ["Land_Research_HQ_F", _pos, [], 0, "CAN_COLLIDE"];
        _researchCenter setVehiclePosition [_pos, [], 0, "CAN_COLLIDE"];
        _researchCenter setVariable ["WaldoEcoResearch_IsResearchCenter", true, true];

        if (!isNil "Waldo_fnc_EcoResource_registerCuratorEditableObject") then {
            [_researchCenter, true] call Waldo_fnc_EcoResource_registerCuratorEditableObject;
        };

        if (hasInterface) then {
            [_researchCenter] call Waldo_fnc_EcoResearch_ensureResearchCenterActionsLocal;
        };

        diag_log format ["[WMP ECO] Research center created object=%1 position=%2 authority=%3", netId _researchCenter, getPosATL _researchCenter, clientOwner];
        _researchCenter

