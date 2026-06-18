/*
 * Author: Waldo
 * Get zone at pos.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _pos <ANY> - pos
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_pos] call Waldo_fnc_EcoResource_getZoneAtPos;
 */

    params ["_pos"];

    private _zones = call Waldo_fnc_EcoResource_getResourceZones;
    private _index = _zones findIf {
        private _zonePos = _x param [2, [0, 0, 0]];
        private _zoneRadius = _x param [3, 0];
        ((_pos distance2D _zonePos) <= _zoneRadius)
    };

    if (_index < 0) exitWith {[]};
    +(_zones select _index)
