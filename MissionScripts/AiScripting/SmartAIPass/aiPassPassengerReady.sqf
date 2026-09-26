/*
 * Author: WaldoTheWarfighter
 * Checks shared passenger safety before routine unloading or boarding; emergency engine bailouts remain independent.
 * Locality/authority: read-only on the requesting owner unless stated below.
 * Repeat/JIP: no side effects; runtime gates are read again on every call.
 * Arguments: 0: soldier <OBJECT>, objNull; 1: vehicle <OBJECT>, objNull; 2: boarding <BOOL>, false.
 * Return Value: Boolean.
 * Current callers: ConvoyCrewLocal, Vehicles and RestoreCalm.
 * Example: [_unit, _vehicle] call Waldo_fnc_AIPassPassengerReady;
 */
params [["_unit", objNull, [objNull]], ["_vehicle", objNull, [objNull]], ["_boarding", false, [true]]];
if (isNull _vehicle || {!alive _vehicle} || {!local _unit} || {isPlayer _unit}
    || {!([_unit] call Waldo_fnc_AIPassCombatEffective)} || {isPlayer leader group _unit}
    || {[group _unit] call Waldo_fnc_AIPassZeusHeld} || {(group _unit) getVariable ["Waldo_AI_ExternalControl", false]}
    || {"ALL" in ((group _unit) getVariable ["Waldo_AIPass_DisabledFeatures", []])}
    || {!isNull (_unit getVariable ["bis_fnc_moduleRemoteControl_owner", objNull])}
    || {abs speed _vehicle >= 1}) exitWith {false};
// A ground-level bridge deck is allowed only when a short downward geometry ray actually hits it.
private _position = getPosASL _vehicle;
private _wet = surfaceIsWater _position;
if (_wet) then {
    private _deck = lineIntersectsSurfaces [_position vectorAdd [0,0,0.5], _position vectorAdd [0,0,-3], _vehicle, _unit, true, 1, "GEOM", "NONE"];
    if (_deck isEqualTo []) exitWith {};
    _wet = (((_deck select 0) select 0) select 2) <= 0.5;
};
if (_wet) exitWith {false};
if (_boarding) exitWith {vehicle _unit == _unit && {canMove _vehicle} && {_vehicle emptyPositions "cargo" > 0}};
vehicle _unit == _vehicle && {(fullCrew [_vehicle, "", false]) findIf {
    (_x select 0) == _unit && {(_x select 1) == "cargo" || {_x select 4}}
} >= 0}
