/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - purgeResourceZones
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_purgeResourceZones via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _zoneIds = (call Waldo_fnc_EcoResource_getResourceZones) apply {_x param [0, ""]};
    {
        if (_x isEqualTo "") then {continue;};
        [_x, true, "purged"] call Waldo_fnc_EcoResource_deleteResourceZone;
    } forEach _zoneIds;

    [[]] call Waldo_fnc_EcoResource_setResourceZones;
