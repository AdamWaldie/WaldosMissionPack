/*
 * Author: WaldoTheWarfighter
 * Purpose: Converts a carried object's default click into a traced physical mount or ground drop.
 * Locality / Authority: Carrier-local ACE cleanup; the server validates the requested mount.
 * Repeat / JIP: One release per click; no durable local state, server publishes accepted mounts.
 *
 * Arguments: 0: carrier <OBJECT>; 1: carried object <OBJECT>; 2: target vehicle <OBJECT>
 *            (default cursor hit).
 * Return Value: BOOLEAN - true when an ACE release was processed.
 * Current caller: the DefaultAction handler installed by Waldo_fnc_PhysicalCargoInitLocal.
 * Example: [player, player getVariable ["ace_dragging_carriedObject", objNull]] call Waldo_fnc_PhysicalCargoReleaseLocal;
 * Result: A valid vehicle click submits a physical mount; other releases follow ACE's drop path.
 */
params [
    ["_carrier", objNull, [objNull]],
    ["_cargo", objNull, [objNull]],
    ["_requestedVehicle", objNull, [objNull]]
];
if (isNull _carrier || {isNull _cargo} || {!local _carrier}) exitWith {false};
if (_cargo isKindOf "StaticWeapon") exitWith {false};
if (_cargo isNotEqualTo (_carrier getVariable ["ace_dragging_carriedObject", objNull])) exitWith {false};

private _rayStart = positionCameraToWorld [0, 0, 0];
private _rayEnd = positionCameraToWorld [0, 0, 7];
private _hits = lineIntersectsSurfaces [AGLToASL _rayStart, AGLToASL _rayEnd, _cargo, _carrier, true, 1, "GEOM", "FIRE"];
private _hit = _hits param [0, []];
private _hitObject = _hit param [2, objNull];
private _hitParent = _hit param [3, objNull];
private _resolvedVehicle = if (_hitObject isKindOf "LandVehicle" || {_hitObject isKindOf "Air"}
    || {_hitObject isKindOf "Ship"}) then {_hitObject} else {_hitParent};
private _vehicle = if (isNull _requestedVehicle) then {_resolvedVehicle} else {_requestedVehicle};
private _surface = _hit param [0, []];
private _normal = _hit param [1, []];
if (!isNull _requestedVehicle && {_vehicle isNotEqualTo _resolvedVehicle}) then {
    // ACE action selected a vehicle, but the actual camera ray does not hit that vehicle.
    _vehicle = objNull;
};
private _validVehicle = !isNull _vehicle
    && {_vehicle isKindOf "LandVehicle" || {_vehicle isKindOf "Air"} || {_vehicle isKindOf "Ship"}}
    && {_vehicle isNotEqualTo _cargo}
    && {alive _vehicle}
    && {abs speed _vehicle < 5}
    && {count _surface == 3} && {count _normal == 3}
    && {(_normal select 2) > -0.25}
    && {_carrier distance (ASLToAGL _surface) <= 5};
private _offset = [];
private _relativeDir = [];
private _relativeUp = [];
if (_validVehicle) then {
    // Preserve ACE's visible carried pose at the instant of release. Moving the
    // centre to a hit plane via model bounds made cargo jump and float on large
    // or irregular objects. The ray only chooses the vehicle, not a new pose.
    private _heldPosition = ASLToAGL getPosWorld _cargo;
    _offset = _vehicle worldToModel _heldPosition;
    _relativeDir = _vehicle vectorWorldToModel (vectorDir _cargo);
    _relativeUp = _vehicle vectorWorldToModel (vectorUp _cargo);
};

// This is ACE's own full cleanup path. The false argument prevents its automatic cargo-load
// attempt; physical mounting is requested only for the vehicle captured before release.
[_carrier, _cargo, false] call ace_dragging_fnc_dropObject_carry;

if (_validVehicle) then {
    [_carrier, _cargo, _vehicle, _offset, _relativeDir, _relativeUp]
        remoteExecCall ["Waldo_fnc_PhysicalCargoAttachServer", 2];
};
true
