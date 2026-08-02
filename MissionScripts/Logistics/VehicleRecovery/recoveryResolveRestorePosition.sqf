/*
 * Author: WaldoTheWarfighter
 * Finds a terrain-snapped, obstruction-free vehicle restoration position outside a workshop's
 * physical footprint. Candidate rings begin beyond the combined workshop/vehicle bounds and are
 * bounded by the workshop delivery radius. Both ordinary mission objects and terrain objects are
 * treated as blockers; the packaged and retained hidden vehicle may be ignored by the caller.
 *
 * Arguments:
 * 0: workshop <OBJECT>
 * 1: vehicle class <STRING>
 * 2: vehicle footprint radius <NUMBER>
 * 3: ignored objects <ARRAY> (default [])
 *
 * Return Value: ARRAY - ATL position, or [] when no complete safe footprint is available.
 *
 * Example:
 * [_workshop, _class, _footprint, [_package, _retained]] call Waldo_fnc_RecoveryResolveRestorePosition;
 * Current caller: RecoveryRestoreServer before an existing or replacement vehicle is restored.
 */

params [
    ["_workshop", objNull, [objNull]],
    ["_class", "", [""]],
    ["_vehicleRadius", 3, [0]],
    ["_ignored", [], [[]]]
];
if (isNull _workshop || {_class == ""} || {!isClass (configFile >> "CfgVehicles" >> _class)}) exitWith {[]};

private _clearance = (missionNamespace getVariable ["Waldo_Recovery_PlacementClearance", 3]) max 0.5;
_vehicleRadius = _vehicleRadius max _clearance;
private _bounds = boundingBoxReal _workshop;
private _minimum = _bounds param [0, [-1, -1, -1]];
private _maximum = _bounds param [1, [1, 1, 1]];
private _workshopRadius = sqrt (
    (((abs (_minimum select 0)) max (abs (_maximum select 0))) ^ 2)
    + (((abs (_minimum select 1)) max (abs (_maximum select 1))) ^ 2)
);
private _minimumRadius = _workshopRadius + _vehicleRadius + _clearance;
private _maximumRadius = (_workshop getVariable ["Waldo_Recovery_Radius", 50]) max _minimumRadius;
private _origin = getPosATL _workshop;
private _result = [];
private _ringStep = (_vehicleRadius * 1.5) max 3;
private _rings = ceil (((_maximumRadius - _minimumRadius) max 0) / _ringStep);

for "_ring" from 0 to _rings do {
    if !(_result isEqualTo []) exitWith {};
    private _radius = (_minimumRadius + (_ring * _ringStep)) min _maximumRadius;
    private _samples = (ceil ((2 * pi * _radius) / ((_vehicleRadius * 2) max 4))) max 12 min 36;
    for "_sample" from 0 to (_samples - 1) do {
        if !(_result isEqualTo []) exitWith {};
        private _angle = (_sample * (360 / _samples)) + ((_ring mod 2) * (180 / _samples));
        private _candidate = _origin getPos [_radius, _angle];
        _candidate set [2, 0];
        private _exact = _candidate findEmptyPosition [0, _vehicleRadius, _class];
        if !(_exact isEqualTo []) then {
            _exact set [2, 0];
            private _outsideWorkshop = (_exact distance2D _origin) >= _minimumRadius;
            private _objectBlockers = (nearestObjects [_exact, [], _vehicleRadius + _clearance, true]) select {
                !isNull _x && {_x != _workshop} && {!(_x in _ignored)}
            };
            private _terrainBlockers = nearestTerrainObjects [_exact, ["TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS", "BUILDING", "HOUSE", "FENCE", "WALL"], _vehicleRadius + _clearance, false, true];
            private _waterCompatible = if (_class isKindOf "Ship") then {surfaceIsWater _exact} else {!surfaceIsWater _exact};
            if (_outsideWorkshop && {_objectBlockers isEqualTo []} && {_terrainBlockers isEqualTo []} && {_waterCompatible}) then {
                _result = _exact;
            };
        };
    };
};
_result
