/*
 * Author: Waldo
 * Delete construction site.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _items <ARRAY> - items (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_items] call Waldo_fnc_EcoBuild_deleteConstructionSite;
 */

        params [["_items", []]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

        {
            if (!isNull _x) then {
                deleteVehicle _x;
            };
        } forEach _items;

