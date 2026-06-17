/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - deleteConstructionSite
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_deleteConstructionSite via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_items", []]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

        {
            if (!isNull _x) then {
                deleteVehicle _x;
            };
        } forEach _items;

