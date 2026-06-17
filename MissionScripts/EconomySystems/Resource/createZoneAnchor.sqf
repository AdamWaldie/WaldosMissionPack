/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - createZoneAnchor
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_createZoneAnchor via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_zoneId"];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {objNull};

    private _index = [_zoneId] call Waldo_fnc_EcoResource_findResourceZoneIndex;
    if (_index < 0) exitWith {objNull};

    private _zones = call Waldo_fnc_EcoResource_getResourceZones;
    private _zone = _zones select _index;
    private _pos = _zone param [2, [0, 0, 0]];

    private _anchor = createVehicle ["PortableHelipadLight_01_red_F", _pos, [], 0, "CAN_COLLIDE"];
    _anchor setPosATL _pos;
    _anchor allowDamage false;
    _anchor enableSimulationGlobal false;
    _anchor setVariable ["WaldoEcoResource_ZoneId", _zoneId, true];
    _anchor setVariable ["WaldoEcoResource_IsZoneAnchor", true, true];

    [_anchor, true] call Waldo_fnc_EcoResource_registerCuratorEditableObject;

    _anchor addEventHandler ["Deleted", {
        params ["_entity"];
        if (_entity getVariable ["WaldoEcoResource_ZoneDeleting", false]) exitWith {};
        private _zoneId = _entity getVariable ["WaldoEcoResource_ZoneId", ""];
        if (_zoneId isEqualTo "") exitWith {};
        [_zoneId, false, "was deleted"] call Waldo_fnc_EcoResource_deleteResourceZone;
    }];

    _zone set [10, _anchor];
    _zones set [_index, _zone];
    [_zones] call Waldo_fnc_EcoResource_setResourceZones;

    _anchor
