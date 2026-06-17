/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - createResourceZone
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_createResourceZone via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_pos", "_name", "_radius", "_resourceRows", "_ownerSideKey", "_interval"];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _zoneId = format ["zone_%1_%2", floor serverTime, floor (random 100000)];
    private _safeName = [_name] call Waldo_fnc_EcoResource_normalizeResourceName;
    if (_safeName isEqualTo "") then {
        _safeName = "Resource Zone";
    };

    private _safeRadius = 5 max (floor _radius);
    private _safeRows = if (_resourceRows isEqualType []) then {
        [_resourceRows] call Waldo_fnc_EcoResource_normalizeZoneResourceRows
    } else {
        [[[_resourceRows] call Waldo_fnc_EcoResource_normalizeResourceName, 1, -1, -1]] call Waldo_fnc_EcoResource_normalizeZoneResourceRows
    };
    if ((count _safeRows) <= 0) then {
        _safeRows = [["Resource", 1, -1, -1]];
    };

    private _safeOwner = toUpper _ownerSideKey;
    if !(_safeOwner in ["WEST", "EAST", "GUER", "NONE"]) then {
        _safeOwner = "NONE";
    };

    private _safeInterval = 10 max (floor _interval);

    private _zone = [_zoneId, _safeName, _pos, _safeRadius, _safeRows, _safeOwner, [], _safeInterval, serverTime, "", objNull, [], ""];
    private _zones = call Waldo_fnc_EcoResource_getResourceZones;
    _zones pushBack _zone;
    [_zones] call Waldo_fnc_EcoResource_setResourceZones;
    [_zoneId] call Waldo_fnc_EcoResource_createZoneAnchor;
    [_zoneId] call Waldo_fnc_EcoResource_createZoneMarker;
