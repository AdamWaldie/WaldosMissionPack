/*
 * Author: Waldo
 * Capture resource zone for side key.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _zoneId <STRING> - zone id (optional, default: "")
 * 1: _sideKey <STRING> - side key (optional, default: "NONE")
 * 2: _capturePos <ARRAY> - capture pos (optional, default: [])
 * 3: _actorName <STRING> - actor name (optional, default: "")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_zoneId, _sideKey, _capturePos, _actorName] call Waldo_fnc_EcoResource_captureResourceZoneForSideKey;
 */

    params [
        ["_zoneId", ""],
        ["_sideKey", "NONE"],
        ["_capturePos", []],
        ["_actorName", ""]
    ];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _safeSideKey = toUpper _sideKey;
    if !(_safeSideKey in ["WEST", "EAST", "GUER"]) exitWith {};

    private _index = [_zoneId] call Waldo_fnc_EcoResource_findResourceZoneIndex;
    if (_index < 0) exitWith {};

    private _zones = call Waldo_fnc_EcoResource_getResourceZones;
    private _zone = _zones select _index;

    private _withinCaptureDistance = true;
    if (_capturePos isEqualType [] && {(count _capturePos) >= 2}) then {
        private _zonePos = _zone param [2, [0, 0, 0]];
        private _radius = _zone param [3, 0];
        _withinCaptureDistance = (_capturePos distance2D _zonePos) <= (_radius + 8);
    };
    if (!_withinCaptureDistance) exitWith {};

    if ((_zone param [5, "NONE"]) isEqualTo _safeSideKey) exitWith {};

    _zone set [5, _safeSideKey];
    _zone set [8, serverTime];
    _zones set [_index, _zone];
    [_zones] call Waldo_fnc_EcoResource_setResourceZones;
    [_zoneId] call Waldo_fnc_EcoResource_refreshZoneMarker;
