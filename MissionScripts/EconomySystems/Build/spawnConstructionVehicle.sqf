/*
 * Author: Waldo
 * Spawn construction vehicle.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _pos <ANY> - pos
 * 1: _className <STRING> - class name (optional, default: "B_Truck_01_box_F")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_pos, _className] call Waldo_fnc_EcoBuild_spawnConstructionVehicle;
 */

        params ["_pos", ["_className", "B_Truck_01_box_F"]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

        private _vehicle = createVehicle [_className, _pos, [], 0, "NONE"];
        _vehicle setVehiclePosition [_pos, [], 0, "NONE"];
        clearWeaponCargoGlobal _vehicle;
        clearMagazineCargoGlobal _vehicle;
        clearItemCargoGlobal _vehicle;
        clearBackpackCargoGlobal _vehicle;
        _vehicle lockInventory true;
        _vehicle setVariable ["WaldoEcoBuild_IsConstructionVehicle", true, true];

        [[_vehicle], true] call Waldo_fnc_EcoCore_registerCuratorEditableObjects;

        if (hasInterface) then {
            [_vehicle] call Waldo_fnc_EcoBuild_ensureConstructionVehicleActionLocal;
        };

