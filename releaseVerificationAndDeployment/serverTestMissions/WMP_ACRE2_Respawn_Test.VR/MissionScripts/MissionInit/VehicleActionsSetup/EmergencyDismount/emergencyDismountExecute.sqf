/*
 * Author: WaldoTheWarfighter
 * Purpose: Throws one local occupant clear of a destroyed or overturned vehicle. Exit direction is
 * derived from seat position, live angular velocity and the last observed direction of the flip.
 * Locality / Authority: Client-local and rejects remote execution. The unit must be local; vehicle
 * motion is sampled read-only before applying position and velocity to the local unit.
 * Repeat / JIP: One execution is transient. A local cooldown prevents duplicate extraction; JIP has
 * no durable state to replay.
 *
 * Arguments:
 * 0: unit <OBJECT> - local occupant to extract.
 * 1: vehicle <OBJECT> - vehicle currently containing the unit.
 * 2: destroyed <BOOLEAN> (default: false) - selects the completion message.
 * 3: flip direction <ARRAY> (default: [0,0,0]) - last reliable horizontal roof direction.
 * 4: flip angular speed <NUMBER> (default: 0) - peak angular speed observed while overturning.
 *
 * Return Value:
 * Nothing.
 *
 * Current Callers:
 * Waldo_fnc_EmergencyDismountInit on the owning client.
 *
 * Example:
 * [player, vehicle player, false, [1, 0, 0], 2.4] spawn Waldo_fnc_EmergencyDismountExecute;
 */

params [
    ["_unit", objNull, [objNull]],
    ["_vehicle", objNull, [objNull]],
    ["_destroyed", false, [false]],
    ["_flipDirection", [0, 0, 0], [[]]],
    ["_flipAngularSpeed", 0, [0]]
];
if (remoteExecutedOwner > 0) exitWith {};
if !(hasInterface && {local _unit}) exitWith {};
if (isNull _vehicle || {_vehicle == _unit}) exitWith {};

private _profile = _unit getVariable ["Waldo_EmergencyDismount_ActiveProfile", createHashMap];
private _setting = {
    params ["_name", "_fallback"];
    _profile getOrDefault [_name, missionNamespace getVariable [format ["Waldo_EmergencyDismount_%1", _name], _fallback]]
};

_unit setVariable ["Waldo_EmergencyDismount_Next", diag_tickTime + (["Cooldown", 8] call _setting)];
private _vehicleVelocity = velocity _vehicle;
private _angularVelocity = angularVelocity _vehicle;
private _seatOffset = (getPosWorld _unit) vectorDiff (getPosWorld _vehicle);
private _tangentialVelocity = _angularVelocity vectorCrossProduct _seatOffset;
_tangentialVelocity set [2, 0];
private _tangentialSpeed = vectorMagnitude _tangentialVelocity;

private _throwDirection = +_flipDirection;
_throwDirection set [2, 0];
if (_tangentialSpeed > 0.25) then {
    _throwDirection = vectorNormalized _tangentialVelocity;
};
if (vectorMagnitude _throwDirection < 0.05) then {
    _throwDirection = vectorUp _vehicle;
    _throwDirection set [2, 0];
};
if (vectorMagnitude _throwDirection < 0.05) then {
    _throwDirection = +_seatOffset;
    _throwDirection set [2, 0];
};
if (vectorMagnitude _throwDirection < 0.05) then {
    _throwDirection = (vectorDir _vehicle) vectorCrossProduct (vectorUp _vehicle);
    _throwDirection set [2, 0];
};
_throwDirection = vectorNormalized _throwDirection;

private _baseThrowSpeed = (["ThrowBaseVelocity", 4.5] call _setting) max 0;
private _angularFactor = (["ThrowAngularFactor", 1.25] call _setting) max 0;
private _maximumThrowSpeed = (["ThrowMaximumVelocity", 14] call _setting) max _baseThrowSpeed;
private _dynamicThrowSpeed = (_tangentialSpeed max _flipAngularSpeed) * _angularFactor;
private _throwSpeed = (_baseThrowSpeed + _dynamicThrowSpeed) min _maximumThrowSpeed;
private _upwardSpeed = ((["UpwardVelocity", 3] call _setting) + (_dynamicThrowSpeed * 0.2)) min (_maximumThrowSpeed * 0.6);
private _throwImpulse = _throwDirection vectorMultiply _throwSpeed;
_throwImpulse set [2, _upwardSpeed];
private _damageWasAllowed = isDamageAllowed _unit;
if (["ProtectDuringExit", true] call _setting) then {
    _unit allowDamage false;
};

unassignVehicle _unit;
if (["UseEject", false] call _setting) then {
    _unit action ["Eject", _vehicle];
} else {
    moveOut _unit;
};
sleep 0.1;
if (_vehicle isKindOf "LandVehicle") then {
    private _clearRadius = ["ClearPositionRadius", 6] call _setting;
    private _searchCentre = (getPosATL _vehicle) vectorAdd (_throwDirection vectorMultiply _clearRadius);
    private _clearPosition = _searchCentre findEmptyPosition [0, 3, "CAManBase"];
    if (count _clearPosition > 0) then {_unit setPosATL _clearPosition};
};
private _exitVelocity = if (["PreserveVelocity", true] call _setting) then {_vehicleVelocity} else {[0, 0, 0]};
_unit setVelocity (_exitVelocity vectorAdd _throwImpulse);

private _timeout = diag_tickTime + ((["ProtectionSeconds", 4] call _setting) max 0.5);
waitUntil {
    sleep 0.05;
    isTouchingGround _unit || {underwater _unit} || {diag_tickTime >= _timeout}
};
if (_damageWasAllowed) then {_unit allowDamage true};
if (["RecoverUnconscious", false] call _setting) then {
    _unit setUnconscious false;
};
private _damageOnExit = ["DamageOnExit", 0] call _setting;
if (_damageOnExit > 0) then {_unit setDamage ((damage _unit + _damageOnExit) min 1)};
_unit setVariable ["Waldo_EmergencyDismount_ActiveProfile", nil];
["EMERGENCY DISMOUNT", if (_destroyed) then {"Extracted from a destroyed vehicle."} else {"Extracted from an overturned vehicle."}, "WARNING", "EMERGENCY_DISMOUNT"] call Waldo_fnc_FeatureNotifyLocal;
