/*
 * Author: WaldoTheWarfighter
 * Purpose: Configures live service/logistics fixtures and repeatable audit controls.
 * Locality / Authority: Dedicated/hosted server only. Requests verify the player's network owner.
 * Repeat / JIP: Setup runs once per audit mission; production seat discovery publishes matched points for JIP.
 * Arguments: None. Return Value: Nothing; sets Waldo_QA_ServiceLogisticsReady publicly.
 * Current caller: extendedFeatureStationsServer.sqf after the feature range is ready.
 * Example: call compile preprocessFileLineNumbers "serviceLogisticsStationsServer.sqf";
 */
if (!isServer) exitWith {};

// The editor fixture is the vanilla NATO Prowler (DAGOR). Keep its original
// object identity so production proxy discovery and local test actions refer to one vehicle.
private _seatFixture = missionNamespace getVariable ["qa_seat_vehicle", objNull];
if (!isNull _seatFixture) then {
    diag_log format ["[WMP QA SEAT VEHICLE] class=%1 cargoOrFfvSeats=%2",
        typeOf _seatFixture, (fullCrew [_seatFixture, "", true]) select {
            toLowerANSI (_x select 1) isEqualTo "cargo" || {_x select 4}
        }];
};

private _get = {
    params ["_name"];
    private _object = missionNamespace getVariable [_name, objNull];
    if (!isNull _object) then {[_object] call Waldo_QA_fnc_trackFeatureObjectServer};
    _object
};

private _hq = "qa_base_hq" call _get;
private _fob = "qa_base_fob" call _get;
if (!isNull _hq && {!isNull _fob}) then {
    private _services = ["SAVE", "HEAL", "SPECTATE", "TELEPORT"];
    ["QA_BASE", [[_hq, "QA Headquarters", _services],
        [_fob, "QA Forward Base", _services]], "TRAVEL"]
        call Waldo_fnc_BaseServicesRegister;
};
missionNamespace setVariable ["Waldo_QA_BaseObjects", [_hq, _fob], true];

private _quartermaster = "qa_qm_point" call _get;
if (!isNull _quartermaster) then {
    [_quartermaster, 0, 5] call Waldo_fnc_SetupQuarterMaster;
};

private _source = "qa_transfer_source" call _get;
private _target = "qa_transfer_target" call _get;
private _transferControl = "qa_transfer_control" call _get;
private _transferVehicle = "qa_transfer_vehicle" call _get;
if (!isNull _transferControl) then {
    _transferControl setPhysicsCollisionFlag true;
    _transferControl enableSimulationGlobal true;
    [_transferControl, -1, 1, true, true] call Waldo_fnc_SetCargoAttributes;
};
if (!isNull _transferVehicle) then {
    _transferVehicle setPhysicsCollisionFlag true;
    _transferVehicle enableSimulationGlobal true;
    [_transferVehicle, 30, -1, false, false] call Waldo_fnc_SetCargoAttributes;
    [_transferVehicle] call Waldo_fnc_SupplyTransfersRegister;
    // Live HEMTT: service roles coexist with inventory transfers and preserve simulation.
    // Exercise ZEN edits, consumption, explicit refill and JIP here; this is setup, not a pass result.
    [_transferVehicle, [["rearm", true], ["rearmSupply", 1500], ["refuel", true],
        ["fuelLitres", 2000], ["repair", true], ["medical", true]]]
        call Waldo_fnc_VehicleServicesConfigure;
};
if (!isNull _source && {!isNull _target}) then {
    { _x setPhysicsCollisionFlag true; _x enableSimulationGlobal true } forEach [_source, _target];
    {[_x, -1, 1, true, true] call Waldo_fnc_SetCargoAttributes} forEach [_source, _target];
    clearWeaponCargoGlobal _source;
    clearMagazineCargoGlobal _source;
    clearItemCargoGlobal _source;
    clearBackpackCargoGlobal _source;
    clearWeaponCargoGlobal _target;
    clearMagazineCargoGlobal _target;
    clearItemCargoGlobal _target;
    clearBackpackCargoGlobal _target;
    _source addItemCargoGlobal ["ACE_fieldDressing", 8];
    _source addMagazineAmmoCargo ["30Rnd_65x39_caseless_mag", 3, 11];
    _source addWeaponWithAttachmentsCargoGlobal [["arifle_MX_F", "muzzle_snds_H", "acc_pointer_IR", "optic_Hamr", ["30Rnd_65x39_caseless_mag", 13], [], ""], 1];
    _source addBackpackCargoGlobal ["B_AssaultPack_mcamo", 1];
    private _backpacks = everyBackpack _source;
    if (_backpacks isNotEqualTo []) then {(_backpacks select 0) addItemCargoGlobal ["ACE_fieldDressing", 3]};
    _target addItemCargoGlobal ["ACE_fieldDressing", 2];
    [_source] call Waldo_fnc_SupplyTransfersRegister;
    [_target] call Waldo_fnc_SupplyTransfersRegister;
};

{
    private _object = _x call _get;
    if (!isNull _object) then {
        _object setPhysicsCollisionFlag true;
        _object enableSimulationGlobal true;
        if (_object isKindOf "ReammoBox_F" || {_object isKindOf "StaticWeapon"}) then {
            [_object, -1, 1, true, true] call Waldo_fnc_SetCargoAttributes;
            [_object] call Waldo_fnc_PhysicalCargoRegister;
        } else {
            [_object, 50, -1, false, false] call Waldo_fnc_SetCargoAttributes;
        };
    };
} forEach ["qa_cargo_vehicle", "qa_cargo_crate", "qa_weapon_vehicle", "qa_weapon_static",
    "qa_seat_vehicle", "qa_seat_crate"];
private _controlCrate = "qa_cargo_control" call _get;
if (!isNull _controlCrate) then {
    _controlCrate setPhysicsCollisionFlag true;
    _controlCrate enableSimulationGlobal true;
    [_controlCrate, -1, 1, true, true] call Waldo_fnc_SetCargoAttributes;
    _controlCrate setVariable ["Waldo_PhysicalCargo_Eligible", false, true];
    diag_log format ["[WMP QA CARGO CONTROL] class=%1 physicalEligible=%2",
        typeOf _controlCrate, _controlCrate getVariable ["Waldo_PhysicalCargo_Eligible", false]];
};
private _seatControl = "qa_seat_control" call _get;
if (!isNull _seatControl) then {
    _seatControl setPhysicsCollisionFlag true;
    _seatControl enableSimulationGlobal true;
    [_seatControl, -1, 1, true, true] call Waldo_fnc_SetCargoAttributes;
    _seatControl setVariable ["Waldo_PhysicalCargo_Eligible", false, true];
    diag_log format ["[WMP QA SEAT CONTROL] class=%1 physicalEligible=%2",
        typeOf _seatControl, _seatControl getVariable ["Waldo_PhysicalCargo_Eligible", false]];
};
{
    private _object = missionNamespace getVariable [_x, objNull];
    if (!isNull _object) then {
        diag_log format ["[WMP QA CARGO FIXTURE] %1 class=%2 simulation=%3 collision=%4 aceSize=%5 aceSpace=%6 owner=%7",
            _x, typeOf _object, simulationEnabled _object,
            (getPhysicsCollisionFlag _object) param [0, false],
            _object getVariable ["ace_cargo_size", -999],
            _object getVariable ["ace_cargo_space", -999], owner _object];
    };
} forEach ["qa_transfer_source", "qa_transfer_target", "qa_transfer_control", "qa_transfer_vehicle", "qa_cargo_vehicle", "qa_cargo_crate", "qa_cargo_control",
    "qa_weapon_vehicle", "qa_weapon_static", "qa_seat_vehicle", "qa_seat_crate", "qa_seat_control"];

Waldo_QA_fnc_captureCargoSeatServer = {
    params [["_actor", objNull, [objNull]]];
    if (!isServer || {isNull _actor} || {remoteExecutedOwner != owner _actor}) exitWith {false};
    private _vehicle = missionNamespace getVariable ["qa_seat_vehicle", objNull];
    if (isNull _vehicle || {vehicle _actor != _vehicle}) exitWith {false};
    private _crew = fullCrew [_vehicle, "", true];
    private _row = _crew findIf {(_x select 0) isEqualTo _actor};
    if (_row < 0) exitWith {false};
    private _seat = _crew select _row;
    private _index = _seat select 2;
    private _path = _seat select 3;
    private _ffv = _seat select 4;
    private _cargoSeat = toLowerANSI (_seat select 1) isEqualTo "cargo" && {_index >= 0};
    if (!_cargoSeat && {!_ffv || {_path isEqualTo []}}) exitWith {false};
    // getPosWorld is ASL; worldToModel expects AGL. Preserve the actor's model
    // centre for a measured seat location, but convert its coordinate frame.
    private _point = _vehicle worldToModel (ASLToAGL getPosWorld _actor);
    private _points = +(_vehicle getVariable ["Waldo_PhysicalCargo_SeatPoints", []]);
    private _key = if (_cargoSeat) then {["CARGO", _index]} else {["TURRET", _path]};
    private _old = _points findIf {
        if (count _x == 2) then {_cargoSeat && {(_x select 0) isEqualTo _index}}
        else {(_x select 0) isEqualTo (_key select 0) && {(_x select 1) isEqualTo (_key select 1)}}
    };
    if (_old >= 0) then {_points deleteAt _old};
    _points pushBack [_key select 0, _key select 1, _point];
    _vehicle setVariable ["Waldo_PhysicalCargo_SeatPoints", _points];
    diag_log format ["[WMP QA SEAT CAPTURE] actor=%1 vehicle=%2 kind=%3 key=%4 modelPoint=%5 fullCrew=%6",
        name _actor, typeOf _vehicle, _key select 0, _key select 1, _point, _crew];
    [_actor, "CARGO SEAT QA", format ["Measured %1 seat %2 at model offset %3. Dismount and place the small crate over this exact seat.", _key select 0, _key select 1, _point], "SUCCESS", "CARGO_SEAT_QA"] call Waldo_QA_fnc_notifyActorServer;
    true
};

Waldo_QA_fnc_reportCargoSeatsServer = {
    params [["_actor", objNull, [objNull]]];
    if (!isServer || {isNull _actor} || {remoteExecutedOwner != owner _actor}) exitWith {false};
    private _vehicle = missionNamespace getVariable ["qa_seat_vehicle", objNull];
    if (isNull _vehicle || {_actor distance _vehicle > 30}) exitWith {
        diag_log format ["[WMP QA SEAT REPORT] Rejected: actor=%1 distance=%2 vehicle=%3",
            name _actor, _actor distance _vehicle, _vehicle];
        false
    };
    private _points = _vehicle getVariable ["Waldo_PhysicalCargo_SeatPoints", []];
    private _cargoLocks = _vehicle getVariable ["Waldo_PhysicalCargo_SeatLocks", []];
    private _turretLocks = _vehicle getVariable ["Waldo_PhysicalCargo_TurretLocks", []];
    private _crate = missionNamespace getVariable ["qa_seat_crate", objNull];
    private _engineTurrets = _turretLocks apply {
        private _path = _x select 0;
        [_path, _vehicle lockedTurret _path]
    };
    diag_log format ["[WMP QA SEAT REPORT] actor=%1 crateMounted=%2 points=%3 cargoLocks=%4 turretLocks=%5 engineTurrets=%6 vehicleOwner=%7 vehicleLocal=%8",
        name _actor, !isNull _crate && {!isNull (_crate getVariable ["Waldo_PhysicalCargo_AttachedVehicle", objNull])},
        _points, _cargoLocks, _turretLocks, _engineTurrets, owner _vehicle, local _vehicle];
    ["CARGO SEAT QA", format ["Matched seats: %1. WMP cargo locks: %2. WMP FFV locks: %3. Crate mounted: %4. See server RPT for seat paths.",
        count _points, count _cargoLocks, count _turretLocks,
        !isNull _crate && {!isNull (_crate getVariable ["Waldo_PhysicalCargo_AttachedVehicle", objNull])}],
        "INFO", "CARGO_SEAT_REPORT", 12] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _actor];
    true
};

Waldo_QA_fnc_resetBaseServicesServer = {
    params [["_actor", objNull, [objNull]]];
    if (isNull _actor || {remoteExecutedOwner != owner _actor}) exitWith {false};
    private _objects = missionNamespace getVariable ["Waldo_QA_BaseObjects", []];
    _objects params [["_hq", objNull], ["_fob", objNull]];
    if (isNull _hq || {isNull _fob} || {_actor distance _hq > 12}) exitWith {false};
    private _services = ["SAVE", "HEAL", "SPECTATE", "TELEPORT"];
    ["QA_BASE", [[_hq, "QA Headquarters", _services],
        [_fob, "QA Forward Base", _services]], "TRAVEL"]
        call Waldo_fnc_BaseServicesRegister;
    [_actor, "BASE SERVICES QA", "Service group re-registered. Check that actions and 3D labels were replaced, not duplicated.", "SUCCESS"] call Waldo_QA_fnc_notifyActorServer;
    true
};

missionNamespace setVariable ["Waldo_QA_ServiceLogisticsReady", true, true];
diag_log "WMP SERVICE/LOGISTICS STATIONS READY: base, issues, transfers, physical and inert static cargo, seats.";
