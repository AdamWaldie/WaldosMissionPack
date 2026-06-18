/*
 * Author: Waldo
 * Purge resource zones.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_purgeResourceZones;
 */

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _zoneIds = (call Waldo_fnc_EcoResource_getResourceZones) apply {_x param [0, ""]};
    {
        if (_x isEqualTo "") then {continue;};
        [_x, true, "purged"] call Waldo_fnc_EcoResource_deleteResourceZone;
    } forEach _zoneIds;

    [[]] call Waldo_fnc_EcoResource_setResourceZones;
