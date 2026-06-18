/*
 * Author: Waldo
 * Get placement pos.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [] call Waldo_fnc_EcoBuy_getPlacementPos;
 */

        if (!isNil "Waldo_fnc_EcoResource_getResourceCratePlacementPos") exitWith {
            [] call Waldo_fnc_EcoResource_getResourceCratePlacementPos
        };

        screenToWorld [0.5, 0.5]

