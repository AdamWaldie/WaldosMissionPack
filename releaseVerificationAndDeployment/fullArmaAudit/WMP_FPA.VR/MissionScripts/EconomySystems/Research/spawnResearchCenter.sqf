/*
 * Author: WaldoTheWarfighter
 * Spawns and registers an interactive Research Center at a supplied map position.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _pos <ARRAY> - pos (optional, default: [0, 0, 0])
 *
 * Return Value:
 * <OBJECT> created centre on the authority machine; objNull when forwarded from a client.
 *
 * Example:
 * [_pos] call Waldo_fnc_EcoResearch_spawnResearchCenter;
 * Locality/Authority: Server creates the object; client/ZEN calls forward their request there.
 * Repeat/JIP Behaviour: Each call creates a new centre. Its public tag and registry let joining
 * clients install local actions; do not call repeatedly for the same intended placement.
 * Current Callers: Research ZEN placement and exported mission setup calls.
 * Result: A registered Land_Research_HQ_F appears at the requested position.
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
        [_researchCenter, "RESEARCH_CENTERS"] call Waldo_fnc_EcoCore_registerRuntimeObject;

        if (!isNil "Waldo_fnc_EcoResource_registerCuratorEditableObject") then {
            [_researchCenter, true] call Waldo_fnc_EcoResource_registerCuratorEditableObject;
        };

        if (hasInterface) then {
            [_researchCenter] call Waldo_fnc_EcoResearch_ensureResearchCenterActionsLocal;
        };

        diag_log format ["[WMP ECO] Research center created object=%1 position=%2 authority=%3", netId _researchCenter, getPosATL _researchCenter, clientOwner];
        _researchCenter

