/*
 * Author: WaldoTheWarfighter
 * Delete the temporary objects that represent a construction site.
 *
 * Locality / Authority: Economy authority only; the server removes the supplied objects.
 * Repeat/JIP: Null entries are skipped, so cleanup can run after earlier
 * deletion; deleted objects have no JIP state to replay.
 * Current Callers: EcoBuild_progressConstructionJobs and EcoCore_purgeBuildingValues.
 *
 * Arguments:
 * 0: _items <ARRAY> - items (optional, default: [])
 *
 * Return Value:
 * Nothing
 * Result: Deletes each still-existing object in the array.
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

