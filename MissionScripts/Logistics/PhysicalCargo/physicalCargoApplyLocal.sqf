/*
 * Author: WaldoTheWarfighter
 * Purpose: Applies a server-approved attachment and local physics flag to a physical mount.
 * Locality / Authority: Server-dispatched to all clients; only the cargo owner runs attachTo.
 * Repeat / JIP: Idempotent for the current mount; locality EH reapplies after owner migration.
 *   Records an incremental local mount row and ignores an older event for this object.
 *
 * Arguments: 0: crate <OBJECT>; 1: vehicle <OBJECT>; 2: model offset <ARRAY>;
 *            3: model forward <ARRAY>; 4: model up <ARRAY>; 5: server revision <NUMBER> (0).
 * Return Value: BOOLEAN - true if applied on the crate owner.
 * Current caller: Waldo_fnc_PhysicalCargoAttachServer via object-owner remote execution.
 * Example: [crate, truck, [0,-1,1], [0,1,0], [0,0,1], 4] remoteExec ["Waldo_fnc_PhysicalCargoApplyLocal", 0];
 * Result: The cargo owner attaches and orients the crate at the accepted vehicle-relative pose.
 */
params [
    ["_cargo", objNull, [objNull]],
    ["_vehicle", objNull, [objNull]],
    ["_offset", [], [[]]],
    ["_relativeDir", [], [[]]],
    ["_relativeUp", [], [[]]],
    ["_revision", 0, [0]]
];
if (isNull _cargo || {isNull _vehicle}) exitWith {false};
if (!isServer && {isRemoteExecuted && {remoteExecutedOwner isNotEqualTo 2}}) exitWith {false};
if (_revision < (_cargo getVariable ["Waldo_PhysicalCargo_LocalMountRevision", 0])) exitWith {false};
// JIP snapshot delivery may be unscheduled, and a remote call can beat its public variable.
// Defer only that race; never sleep in this function's unscheduled caller.
if ((_cargo getVariable ["Waldo_PhysicalCargo_AttachedVehicle", objNull]) isNotEqualTo _vehicle) exitWith {
    [_cargo, _vehicle, _offset, _relativeDir, _relativeUp, _revision] spawn {
        params ["_cargo", "_vehicle", "_offset", "_relativeDir", "_relativeUp", "_revision"];
        private _deadline = diag_tickTime + 1;
        waitUntil {
            sleep 0.01;
            isNull _cargo || {(_cargo getVariable ["Waldo_PhysicalCargo_AttachedVehicle", objNull]) isEqualTo _vehicle}
                || {diag_tickTime >= _deadline}
        };
        if (!isNull _cargo && {(_cargo getVariable ["Waldo_PhysicalCargo_AttachedVehicle", objNull]) isEqualTo _vehicle}) then {
            [_cargo, _vehicle, _offset, _relativeDir, _relativeUp, _revision] call Waldo_fnc_PhysicalCargoApplyLocal;
        };
    };
    false
};
_cargo setVariable ["Waldo_PhysicalCargo_LocalMountRevision", _revision];
missionNamespace setVariable ["Waldo_PhysicalCargo_LocalRevision",
    _revision max (missionNamespace getVariable ["Waldo_PhysicalCargo_LocalRevision", 0])];
private _mounts = +(missionNamespace getVariable ["Waldo_PhysicalCargo_Mounts", []]);
private _row = [_cargo, _vehicle, _offset, _relativeDir, _relativeUp];
private _index = _mounts findIf {(_x select 0) isEqualTo _cargo};
if (_index < 0) then {_mounts pushBack _row} else {_mounts set [_index, _row]};
missionNamespace setVariable ["Waldo_PhysicalCargo_Mounts", _mounts];
_cargo setPhysicsCollisionFlag false;
if (local _cargo) then {
    _cargo attachTo [_vehicle, _offset];
    // The object is already attached. Arma interprets direction changes relative to
    // the carrier's model space, which is exactly how the saved axes were measured.
    _cargo setVectorDirAndUp [vectorNormalized _relativeDir, vectorNormalized _relativeUp];
};
if (isNil {_cargo getVariable "Waldo_PhysicalCargo_LocalityEH"}) then {
    private _id = _cargo addEventHandler ["Local", {
        params ["_object", "_isLocal"];
        if (_isLocal) then {
            private _vehicle = _object getVariable ["Waldo_PhysicalCargo_AttachedVehicle", objNull];
            private _row = (missionNamespace getVariable ["Waldo_PhysicalCargo_Mounts", []])
                select {(_x select 0) isEqualTo _object};
            if (!isNull _vehicle && {_row isNotEqualTo []}) then {
                ((_row select 0) + [_object getVariable ["Waldo_PhysicalCargo_LocalMountRevision", 0]])
                    call Waldo_fnc_PhysicalCargoApplyLocal;
            };
        };
    }];
    _cargo setVariable ["Waldo_PhysicalCargo_LocalityEH", _id];
};
true
