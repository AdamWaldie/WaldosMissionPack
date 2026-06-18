/*
 * Author: Waldo
 * Find resource zone index.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _zoneId <ANY> - zone id
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_zoneId] call Waldo_fnc_EcoResource_findResourceZoneIndex;
 */

    params ["_zoneId"];

    private _zones = call Waldo_fnc_EcoResource_getResourceZones;
    _zones findIf {
        ((_x param [0, ""]) isEqualTo _zoneId)
    }
