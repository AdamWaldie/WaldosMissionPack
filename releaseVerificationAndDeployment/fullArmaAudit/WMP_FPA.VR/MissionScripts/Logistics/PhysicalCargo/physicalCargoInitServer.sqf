/*
 * Author: WaldoTheWarfighter
 * Purpose: Registers placed crates for ACE Drag/Carry, then installs ACE Cargo
 * and deletion listeners plus a fallback monitor to release obsolete mounts.
 * Locality / Authority: Server only; it owns the mount registry and cleanup.
 * Repeat / JIP: Scans placed crates once; ACE replays their actions to JIP.
 * Idempotent installation; ordered mount snapshots answer explicit JIP requests.
 * ACE Cargo loads clear mounts on the next server frame, after ACE has updated
 * its loaded list and outside the remote-event context. EntityDeleted handles
 * normal crate deletion immediately. The monitor catches
 * deletion paths for which the engine does not emit that mission event.
 *
 * Arguments: None.
 * Return Value: BOOLEAN - true when installed or already present.
 * Current caller: initServer.sqf after feature configuration.
 * Example: [] call Waldo_fnc_PhysicalCargoInitServer;
 * Result: The server has the mount lifecycle handlers needed for cleanup and state replay.
 */
if (!isServer) exitWith {false};
if (missionNamespace getVariable ["Waldo_PhysicalCargo_ServerInstalled", false]) exitWith {true};
if (isNil "CBA_fnc_addEventHandler") exitWith {false};
// Eden objects exist before initServer. Later WMP-issued crates use the same
// register function at spawn, so this startup scan has no polling cost. An
// explicit false eligibility flag on a placed crate remains an opt-out.
[] spawn {
    // Eden starter-crate setup may still be running during pre-play init.
    waitUntil {sleep 0.1; time > 0};
    {
        if (_x getVariable ["Waldo_PhysicalCargo_Eligible", true]
            && {!(_x getVariable ["Waldo_Logistics_StarterCrate", false])}) then {
            [_x] call Waldo_fnc_PhysicalCargoRegister;
        };
    } forEach (entities "ReammoBox_F");
};
private _id = ["ace_cargoLoaded", {
    params ["_cargo", ["_holder", objNull]];
    if (_cargo isEqualType objNull && {!isNull _cargo}) then {
        [{
            params ["_cargo", "_holder"];
            if (isNull _cargo) exitWith {};
            // Do not touch ordinary ACE loads. Only WMP's mounted objects own
            // seat locks and physical-cargo state to release.
            if (isNull (_cargo getVariable ["Waldo_PhysicalCargo_AttachedVehicle", objNull])) exitWith {};
            private _cleared = [_cargo] call Waldo_fnc_PhysicalCargoClearServer;
            diag_log format ["[WMP PHYSICAL CARGO] ACE load cleanup cargo=%1 holder=%2 cleared=%3 remote=%4",
                netId _cargo, netId _holder, _cleared, isRemoteExecuted];
        }, [_cargo, _holder]] call CBA_fnc_execNextFrame;
    };
}] call CBA_fnc_addEventHandler;
missionNamespace setVariable ["Waldo_PhysicalCargo_CargoLoadedEH", _id];
private _deletedId = addMissionEventHandler ["EntityDeleted", {
    params ["_entity"];
    private _mounts = +(missionNamespace getVariable ["Waldo_PhysicalCargo_Mounts", []]);
    private _removed = _mounts select {
        (_x select 0) isEqualTo _entity || {isNull (_x select 0)}
    };
    if (_removed isEqualTo []) exitWith {};
    {
        _x params ["_cargo", "_vehicle"];
        [_cargo, _vehicle, false] call Waldo_fnc_PhysicalCargoSeatsServer;
    } forEach _removed;
    _mounts = _mounts select {
        !((_x select 0) isEqualTo _entity) && {!isNull (_x select 0)}
    };
    missionNamespace setVariable ["Waldo_PhysicalCargo_Mounts", _mounts];
    private _revision = (missionNamespace getVariable ["Waldo_PhysicalCargo_MountRevision", 0]) + 1;
    missionNamespace setVariable ["Waldo_PhysicalCargo_MountRevision", _revision];
    [_mounts, _revision] remoteExecCall ["Waldo_fnc_PhysicalCargoReceiveStateLocal", 0];
    diag_log format ["[WMP PHYSICAL CARGO] Deleted cargo cleanup: %1 mount(s), revision %2.",
        count _removed, _revision];
}];
missionNamespace setVariable ["Waldo_PhysicalCargo_DeletedEH", _deletedId];
missionNamespace setVariable ["Waldo_PhysicalCargo_ServerInstalled", true];
private _monitor = [{
    private _mounts = +(missionNamespace getVariable ["Waldo_PhysicalCargo_Mounts", []]);
    {
        _x params ["_cargo", "_vehicle"];
        if (isNull _cargo) then {
            [_cargo, _vehicle, false] call Waldo_fnc_PhysicalCargoSeatsServer;
        } else {if (isNull _vehicle || {!alive _vehicle}) then {
            [_cargo] call Waldo_fnc_PhysicalCargoClearServer;
        }};
    } forEach _mounts;
    // A lock command can race a vehicle locality transfer. Check only active
    // mounts at this existing 3 s cadence, with at most three retries per owner.
    private _attempts = +(missionNamespace getVariable ["Waldo_PhysicalCargo_SeatAttempts", []]);
    private _vehicles = (_mounts apply {_x select 1});
    _vehicles = _vehicles arrayIntersect _vehicles;
    {
        private _vehicle = _x;
        if (!isNull _vehicle && {alive _vehicle}) then {
            private _vehicleOwner = owner _vehicle;
            {
                _x params ["_kind", "_locks"];
                {
                    private _key = _x select 0;
                    private _engineLocked = if (_kind isEqualTo "CARGO") then {
                        _vehicle lockedCargo _key
                    } else {
                        _vehicle lockedTurret _key
                    };
                    private _index = _attempts findIf {
                        (_x select 0) isEqualTo _vehicle && {(_x select 1) isEqualTo _kind}
                            && {(_x select 2) isEqualTo _key}
                    };
                    if (_engineLocked) then {
                        if (_index >= 0) then {_attempts deleteAt _index};
                    } else {
                        private _tries = 0;
                        if (_index >= 0) then {
                            private _prior = _attempts select _index;
                            if ((_prior select 3) isEqualTo _vehicleOwner) then {_tries = _prior select 4};
                        };
                        if (_tries < 3) then {
                            [_vehicle, _kind, _key, true]
                                remoteExecCall ["Waldo_fnc_PhysicalCargoSeatLockLocal", _vehicle];
                            private _row = [_vehicle, _kind, _key, _vehicleOwner, _tries + 1];
                            if (_index < 0) then {_attempts pushBack _row} else {_attempts set [_index, _row]};
                            diag_log format ["[WMP PHYSICAL CARGO SEATS] retry %1/3 %2 %3 owner=%4",
                                _tries + 1, _kind, _key, _vehicleOwner];
                        };
                    };
                } forEach _locks;
            } forEach [["CARGO", _vehicle getVariable ["Waldo_PhysicalCargo_SeatLocks", []]],
                ["TURRET", _vehicle getVariable ["Waldo_PhysicalCargo_TurretLocks", []]]];
        };
    } forEach _vehicles;
    missionNamespace setVariable ["Waldo_PhysicalCargo_SeatAttempts", _attempts];
    private _current = +(missionNamespace getVariable ["Waldo_PhysicalCargo_Mounts", []]);
    private _clean = _current select {!isNull (_x select 0)};
    if (count _clean isNotEqualTo count _current) then {
        missionNamespace setVariable ["Waldo_PhysicalCargo_Mounts", _clean];
        private _revision = (missionNamespace getVariable ["Waldo_PhysicalCargo_MountRevision", 0]) + 1;
        missionNamespace setVariable ["Waldo_PhysicalCargo_MountRevision", _revision];
        // A deleted object has no reliable delta identity. This rare cleanup sends
        // one replacement snapshot instead of broadcasting the list on every mount.
        [_clean, _revision] remoteExecCall ["Waldo_fnc_PhysicalCargoReceiveStateLocal", 0];
    };
}, 3] call CBA_fnc_addPerFrameHandler;
missionNamespace setVariable ["Waldo_PhysicalCargo_MonitorPFH", _monitor];
true
