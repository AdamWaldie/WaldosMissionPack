/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - findResourceZoneIndex
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_findResourceZoneIndex via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_zoneId"];

    private _zones = call Waldo_fnc_EcoResource_getResourceZones;
    _zones findIf {
        ((_x param [0, ""]) isEqualTo _zoneId)
    }
