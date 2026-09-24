/*
 * Author: WaldoTheWarfighter
 * Purpose: Restores a released mount's local physics flag and detaches it on its owner.
 * Locality / Authority: Server-dispatched to all machines; only the object owner detaches.
 * Repeat / JIP: Repeated restore is harmless; a later mount's public state or
 *   revision blocks stale restores. Removes the local mount row on every client.
 * Arguments: cargo <OBJECT>, former vehicle <OBJECT>, prior collision flag <BOOL>,
 *            clear AGL point <ARRAY> ([]), restore token <NUMBER> (-1),
 *            physics-only acknowledgement <BOOL> (false), server revision <NUMBER> (0).
 * Return Value: <BOOL> handled. Current caller: Waldo_fnc_PhysicalCargoClearServer.
 * Example: [crate, truck, true] remoteExecCall ["Waldo_fnc_PhysicalCargoRestoreLocal", 0];
 */
params [["_cargo", objNull, [objNull]], ["_vehicle", objNull, [objNull]],
    ["_prior", true, [true]], ["_dropPosition", [], [[]]],
    ["_restoreToken", -1, [0]], ["_physicsOnly", false, [true]],
    ["_revision", 0, [0]]];
if (isNull _cargo) exitWith {false};
if (!isServer && {(!isRemoteExecuted || {remoteExecutedOwner isNotEqualTo 2})}) exitWith {false};
if (_physicsOnly) exitWith {
    if (!isNull (_cargo getVariable ["Waldo_PhysicalCargo_AttachedVehicle", objNull])) exitWith {false};
    _cargo setPhysicsCollisionFlag _prior;
    true
};
if (_revision < (_cargo getVariable ["Waldo_PhysicalCargo_LocalMountRevision", 0])) exitWith {false};
if (!isNull (_cargo getVariable ["Waldo_PhysicalCargo_AttachedVehicle", objNull])) exitWith {false};
_cargo setVariable ["Waldo_PhysicalCargo_LocalMountRevision", _revision];
missionNamespace setVariable ["Waldo_PhysicalCargo_LocalRevision",
    _revision max (missionNamespace getVariable ["Waldo_PhysicalCargo_LocalRevision", 0])];
private _mounts = +(missionNamespace getVariable ["Waldo_PhysicalCargo_Mounts", []]);
missionNamespace setVariable ["Waldo_PhysicalCargo_Mounts",
    _mounts select {(_x select 0) isNotEqualTo _cargo}];
if (_restoreToken < 0) then {_cargo setPhysicsCollisionFlag _prior};
if (local _cargo) then {
    private _aceLoaded = !isNull _vehicle && {_cargo in (_vehicle getVariable ["ace_cargo_loaded", []])};
    if (!_aceLoaded && {isNull _vehicle || {attachedTo _cargo isEqualTo _vehicle}}) then {detach _cargo};
    if (count _dropPosition == 3) then {
        _cargo setPosATL _dropPosition;
        if (_restoreToken >= 0) then {
            if (isServer) then {
                [_cargo, _restoreToken] call Waldo_fnc_PhysicalCargoRestoreAckServer;
            } else {
                [_cargo, _restoreToken] remoteExecCall ["Waldo_fnc_PhysicalCargoRestoreAckServer", 2];
            };
        };
    };
};
true
