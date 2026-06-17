/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - getPlacementPos
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_getPlacementPos via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        if (!isNil "Waldo_fnc_EcoResource_getResourceCratePlacementPos") exitWith {
            [] call Waldo_fnc_EcoResource_getResourceCratePlacementPos
        };

        screenToWorld [0.5, 0.5]

