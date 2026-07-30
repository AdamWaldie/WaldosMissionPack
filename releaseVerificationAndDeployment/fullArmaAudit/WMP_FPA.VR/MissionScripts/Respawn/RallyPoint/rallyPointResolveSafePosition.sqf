/*
 * Author: WaldoTheWarfighter
 * Resolves a short-range, empty ATL position around a rally object for one unit class.
 *
 * The function is locality-neutral and samples bounded radial findEmptyPosition searches. It never
 * returns the rally object's centre as a successful fallback. The server uses it when registering
 * the respawn position; the owning client uses it again after respawn or direct regroup in case the
 * area became obstructed. Currently called by RallyPointRequestServer and RallyPointSetupLocal.
 *
 * Arguments:
 * 0: rally object <OBJECT>
 * 1: unit or vehicle class <STRING> (default: B_Soldier_F)
 * 2: minimum clearance <NUMBER> metres (default: configured value)
 * 3: maximum search distance <NUMBER> metres (default: configured value)
 *
 * Return Value:
 * ARRAY - safe PositionATL, or [] when no suitable position exists
 *
 * Example:
 * private _position = [rallyObject, typeOf player] call Waldo_fnc_RallyPointResolveSafePosition;
 */

params [
    ["_rally", objNull, [objNull]],
    ["_class", "B_Soldier_F", [""]],
    ["_clearance", missionNamespace getVariable ["Waldo_Rally_RespawnClearance", 2.5], [0]],
    ["_searchDistance", missionNamespace getVariable ["Waldo_Rally_RespawnSearchDistance", 15], [0]]
];
if (isNull _rally || {_class == ""}) exitWith {[]};
private _origin = getPosATL _rally;
private _minimum = (_clearance max 1) min 10;
private _maximum = (_searchDistance max (_minimum + 1)) min 30;
private _result = [];

// findEmptyPosition treats the already-created rally as an obstacle and a single search can reject
// an otherwise usable area. Sample bounded rings instead, use the command only for each exact unit
// footprint, and explicitly reject live units/vehicles. The rally itself is deliberately ignored.
for "_radius" from _minimum to _maximum step 1.5 do {
    for "_bearing" from 0 to 315 step 45 do {
        private _candidate = [_origin, _radius, _bearing] call BIS_fnc_relPos;
        _candidate set [2, 0];
        if !(surfaceIsWater _candidate) then {
            private _exact = _candidate findEmptyPosition [0, 0, _class];
            if (_exact isEqualTo []) then {_exact = +_candidate};
            private _normal = surfaceNormal _exact;
            private _slope = acos (((_normal select 2) max -1) min 1);
            private _blockers = nearestObjects [_exact, ["CAManBase", "LandVehicle", "Air", "Ship"], 1.25, true];
            _blockers = _blockers select {_x != _rally && {alive _x}};
            if (_slope <= 35 && {count _blockers == 0}) exitWith {_result = _exact};
        };
    };
    if !(_result isEqualTo []) exitWith {};
};
if !(_result isEqualTo []) then {_result set [2, 0]};
_result
