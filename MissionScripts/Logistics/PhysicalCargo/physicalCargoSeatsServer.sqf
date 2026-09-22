/*
 * Author: WaldoTheWarfighter
 * Purpose: Locks/unlocks verified cargo or FFV person-turret seats covered by physical cargo.
 * Locality / Authority: Server; seat locks have global effect. Existing mission-maker locks remain.
 * Repeat / JIP: Reference-counts WMP mount objects per index/path; removal is idempotent.
 * Arguments: cargo <OBJECT>, vehicle <OBJECT>, add <BOOL> (true), offset <ARRAY> ([]),
 *   cargo forward/up vectors in vehicle model space <ARRAY> ([] each).
 * Return Value: <BOOL> handled. Current callers: physical attach/clear.
 * Example: [crate, truck, true, [0, -1, 1], [0, 1, 0], [0, 0, 1]] call Waldo_fnc_PhysicalCargoSeatsServer;
 */
params [["_cargo", objNull, [objNull]], ["_vehicle", objNull, [objNull]],
    ["_add", true, [true]], ["_offset", [], [[]]],
    ["_relativeDir", [], [[]]], ["_relativeUp", [], [[]]]];
if (!isServer || {isNull _vehicle}) exitWith {false};
private _locks = +(_vehicle getVariable ["Waldo_PhysicalCargo_SeatLocks", []]);
private _turretLocks = +(_vehicle getVariable ["Waldo_PhysicalCargo_TurretLocks", []]);
if (_add) then {
    if !(missionNamespace getVariable ["Waldo_PhysicalCargo_BlockSeats", true]) exitWith {true};
    if !(_offset isEqualTypeArray [0, 0, 0]
        && {_relativeDir isEqualTypeArray [0, 0, 0]}
        && {_relativeUp isEqualTypeArray [0, 0, 0]}) exitWith {false};
    private _seatPoints = _vehicle getVariable ["Waldo_PhysicalCargo_SeatPoints", []];
    private _validSeats = fullCrew [_vehicle, "", true];
    private _bounds = boundingBoxReal _cargo;
    _bounds params ["_minimum", "_maximum"];
    private _forward = vectorNormalized _relativeDir;
    private _up = vectorNormalized _relativeUp;
    private _right = vectorNormalized (_forward vectorCrossProduct _up);
    diag_log format ["[WMP PHYSICAL CARGO SEATS] vehicle=%1 mapped=%2 cargoOffset=%3 bounds=%4 crew=%5",
        typeOf _vehicle, _seatPoints, _offset, _bounds, _validSeats];
    {
        private _kind = "CARGO";
        private _key = -1;
        private _seatOffset = [];
        if (_x isEqualType [] && {count _x == 2} && {(_x select 0) isEqualType 0}) then {
            _key = _x select 0;
            _seatOffset = _x select 1;
        } else {
            if (_x isEqualType [] && {count _x == 3}) then {
                _kind = _x select 0;
                _key = _x select 1;
                _seatOffset = _x select 2;
            };
        };
        private _covered = false;
        if (_seatOffset isEqualTypeArray [0, 0, 0]) then {
            private _delta = _seatOffset vectorDiff _offset;
            private _pointInCargo = [_delta vectorDotProduct _right,
                _delta vectorDotProduct _forward, _delta vectorDotProduct _up];
            _covered = true;
            for "_axis" from 0 to 2 do {
                // A seat merely touching the model's broad geometry edge is not
                // materially occupied. Require penetration into the horizontal
                // footprint; allow vertical tolerance for seated-unit origins.
                private _margin = if (_axis < 2) then {
                    0.2 min (((_maximum select _axis) - (_minimum select _axis)) * 0.2)
                } else {-0.15};
                if ((_pointInCargo select _axis) < ((_minimum select _axis) + _margin)
                    || {(_pointInCargo select _axis) > ((_maximum select _axis) - _margin)}) exitWith {
                    _covered = false;
                };
            };
        };
        if (_covered) then {
            if (_kind isEqualTo "CARGO" && {_key isEqualType 0} && {_key >= 0}
                && {_validSeats findIf {toLowerANSI (_x select 1) isEqualTo "cargo"
                    && {(_x select 2) isEqualTo _key} && {isNull (_x select 0)}} >= 0}) then {
                private _entry = _locks findIf {(_x select 0) isEqualTo _key};
                if (_entry >= 0 || {!(_vehicle lockedCargo _key)}) then {
                    if (_entry < 0) then {
                        _vehicle lockCargo [_key, true];
                        _locks pushBack [_key, [_cargo]];
                        diag_log format ["[WMP PHYSICAL CARGO SEATS] locked cargoIndex=%1 for %2", _key, typeOf _cargo];
                    } else {
                        private _holders = +((_locks select _entry) select 1);
                        _holders pushBackUnique _cargo;
                        _locks set [_entry, [_key, _holders]];
                    };
                };
            };
            if (_kind isEqualTo "TURRET" && {_key isEqualType []} && {_key isNotEqualTo []}
                && {_validSeats findIf {(_x select 4) && {(_x select 3) isEqualTo _key}
                    && {isNull (_x select 0)}} >= 0}) then {
                private _entry = _turretLocks findIf {(_x select 0) isEqualTo _key};
                if (_entry >= 0 || {!(_vehicle lockedTurret _key)}) then {
                    if (_entry < 0) then {
                        _vehicle lockTurret [_key, true];
                        _turretLocks pushBack [_key, [_cargo]];
                        diag_log format ["[WMP PHYSICAL CARGO SEATS] locked FFV turretPath=%1 for %2", _key, typeOf _cargo];
                    } else {
                        private _holders = +((_turretLocks select _entry) select 1);
                        _holders pushBackUnique _cargo;
                        _turretLocks set [_entry, [_key, _holders]];
                    };
                };
            };
        };
    } forEach _seatPoints;
} else {
    {
        _x params ["_index", "_holders"];
        _holders = _holders - [_cargo];
        if (_holders isEqualTo []) then {
            _vehicle lockCargo [_index, false];
            _locks set [_forEachIndex, []];
        } else {
            _locks set [_forEachIndex, [_index, _holders]];
        };
    } forEach +_locks;
    _locks = _locks select {_x isNotEqualTo []};
    {
        _x params ["_path", "_holders"];
        _holders = _holders - [_cargo];
        if (_holders isEqualTo []) then {
            _vehicle lockTurret [_path, false];
            _turretLocks set [_forEachIndex, []];
        } else {
            _turretLocks set [_forEachIndex, [_path, _holders]];
        };
    } forEach +_turretLocks;
    _turretLocks = _turretLocks select {_x isNotEqualTo []};
};
_vehicle setVariable ["Waldo_PhysicalCargo_SeatLocks", _locks, true];
_vehicle setVariable ["Waldo_PhysicalCargo_TurretLocks", _turretLocks, true];
true
