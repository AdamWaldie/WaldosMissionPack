/*
 * Author: WaldoTheWarfighter
 * Spawns and registers a Construction Vehicle of the requested class.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _pos <ARRAY> - world position
 * 1: _className <STRING> - class name (optional, default: "B_Truck_01_box_F")
 *
 * Return Value:
 * <OBJECT> created vehicle on authority; client calls forward without a local result.
 *
 * Example:
 * [_pos, _className] call Waldo_fnc_EcoBuild_spawnConstructionVehicle;
 * Locality/Authority: Server creates the vehicle; client/ZEN calls forward there.
 * Repeat/JIP Behaviour: Each call creates a new vehicle; published tag/registry support JIP.
 * Current Callers: Construction ZEN placement and exported mission setup calls.
 * Result: Players receive Construction actions on the spawned vehicle.
 */

        params ["_pos", ["_className", "B_Truck_01_box_F"]];

        // Authority-only creation; forward to the server when called on a client (dedicated-safe).
        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {
            _this remoteExec ["Waldo_fnc_EcoBuild_spawnConstructionVehicle", 2];
        };

        private _vehicle = createVehicle [_className, _pos, [], 0, "NONE"];
        _vehicle setVehiclePosition [_pos, [], 0, "NONE"];
        clearWeaponCargoGlobal _vehicle;
        clearMagazineCargoGlobal _vehicle;
        clearItemCargoGlobal _vehicle;
        clearBackpackCargoGlobal _vehicle;
        _vehicle lockInventory true;
        _vehicle setVariable ["WaldoEcoBuild_IsConstructionVehicle", true, true];
        [_vehicle, "CONSTRUCTION_VEHICLES"] call Waldo_fnc_EcoCore_registerRuntimeObject;

        [[_vehicle], true] call Waldo_fnc_EcoCore_registerCuratorEditableObjects;

        if (hasInterface) then {
            [_vehicle] call Waldo_fnc_EcoBuild_ensureConstructionVehicleActionLocal;
        };
        diag_log format ["[WMP ECO] Construction vehicle created object=%1 class=%2 position=%3 authority=%4", netId _vehicle, typeOf _vehicle, getPosATL _vehicle, clientOwner];
        _vehicle

