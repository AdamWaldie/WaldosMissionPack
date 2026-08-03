/*
 * Author: WaldoTheWarfighter
 * Finds a clear position beside a recovery carrier for materialising one virtual package.
 *
 * Candidate rings begin outside the combined real bounds of the carrier and package. Ordinary
 * objects, terrain objects and incompatible water surfaces reject a candidate, so virtual cargo
 * never falls back to the carrier origin or appears inside the transporting vehicle.
 *
 * Arguments:
 * 0: carrier <OBJECT>
 * 1: package <OBJECT>
 * 2: ignored objects <ARRAY> (default [])
 *
 * Return Value:
 * Array - clear ATL position, or [] when no complete package footprint is available.
 *
 * Example:
 * [_carrier, _package, [_carrier, _package]] call Waldo_fnc_RecoveryResolveUnloadPosition;
 *
 * Current caller: Waldo_fnc_RecoveryRequestServer for virtual package unloading.
 */

params [
    ["_carrier", objNull, [objNull]],
    ["_package", objNull, [objNull]],
    ["_ignored", [], [[]]]
];
if (isNull _carrier || {isNull _package}) exitWith {[]};

private _radiusFor = {
    params ["_object"];
    private _bounds = boundingBoxReal _object;
    private _minimum = _bounds param [0, [-1, -1, -1]];
    private _maximum = _bounds param [1, [1, 1, 1]];
    sqrt (
        (((abs (_minimum select 0)) max (abs (_maximum select 0))) ^ 2)
        + (((abs (_minimum select 1)) max (abs (_maximum select 1))) ^ 2)
    )
};
private _clearance = (missionNamespace getVariable ["Waldo_Recovery_PlacementClearance", 3]) max 0.5;
private _carrierRadius = [_carrier] call _radiusFor;
private _packageRadius = ([_package] call _radiusFor) max 1;
private _minimumRadius = _carrierRadius + _packageRadius + _clearance;
private _maximumRadius = _minimumRadius + ((missionNamespace getVariable ["Waldo_Recovery_VirtualUnloadSearchRange", 20]) max 5);
private _origin = getPosATL _carrier;
private _packageClass = typeOf _package;
private _result = [];

for "_ring" from 0 to 3 do {
    if !(_result isEqualTo []) exitWith {};
    private _radius = _minimumRadius + ((_maximumRadius - _minimumRadius) * (_ring / 3));
    for "_sample" from 0 to 11 do {
        if !(_result isEqualTo []) exitWith {};
        private _angle = (getDir _carrier + 180 + (_sample * 30) + ((_ring mod 2) * 15)) mod 360;
        private _candidate = _origin getPos [_radius, _angle];
        _candidate set [2, 0];
        private _exact = _candidate findEmptyPosition [0, _packageRadius, _packageClass];
        if !(_exact isEqualTo []) then {
            _exact set [2, 0];
            private _objectBlockers = (nearestObjects [_exact, [], _packageRadius + _clearance, true]) select {
                !isNull _x && {!(_x in _ignored)}
            };
            private _terrainBlockers = nearestTerrainObjects [
                _exact,
                ["TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS", "BUILDING", "HOUSE", "FENCE", "WALL"],
                _packageRadius + _clearance,
                false,
                true
            ];
            private _waterCompatible = if (_package isKindOf "Ship") then {surfaceIsWater _exact} else {!surfaceIsWater _exact};
            if (_objectBlockers isEqualTo [] && {_terrainBlockers isEqualTo []} && {_waterCompatible}) then {
                _result = _exact;
            };
        };
    };
};
_result
