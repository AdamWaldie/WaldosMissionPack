/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - spawnConstructionVehicle
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_spawnConstructionVehicle via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

