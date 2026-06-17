/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - deleteResourceZone
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_deleteResourceZone via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_zoneId", ["_deleteAnchor", true], ["_reason", "removed"]];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _index = [_zoneId] call Waldo_fnc_EcoResource_findResourceZoneIndex;
    if (_index < 0) exitWith {};

    private _zones = call Waldo_fnc_EcoResource_getResourceZones;
    private _zone = _zones select _index;
    private _zoneName = _zone param [1, "Resource Zone"];
    private _anchor = _zone param [10, objNull];

    [_zoneId] call Waldo_fnc_EcoResource_deleteZoneMarker;

    if (_deleteAnchor && {!isNull _anchor}) then {
        _anchor setVariable ["WaldoEcoResource_ZoneDeleting", true];
        deleteVehicle _anchor;
    };

    _zones = call Waldo_fnc_EcoResource_getResourceZones;
    _index = [_zoneId] call Waldo_fnc_EcoResource_findResourceZoneIndex;
    if (_index < 0) exitWith {};

    _zones deleteAt _index;
    [_zones] call Waldo_fnc_EcoResource_setResourceZones;
