/*
 * Author: WaldoTheWarfighter
 * Applies short, bounded downward world-space impulses to one local AI helicopter while its normal
 * cruise braking is producing an unwanted zoom-climb. Each impulse is mass- and interval-scaled;
 * no velocity, waypoint, AI feature or flight-height setting is overwritten.
 *
 * Improved Helicopter Landing is authoritative. A supported landing order or active landing
 * controller cancels this correction before another impulse is applied. Terrain clearance, pilot,
 * damage, sling-load, locality and timeout checks also fail safe by releasing immediately.
 *
 * Arguments:
 * 0: aircraft <OBJECT>
 * 1: speed when detected <NUMBER, km/h>
 * 2: ASL altitude when detected <NUMBER, metres>
 * 3: landing-order predicate <CODE>
 * Return Value: BOOL - true if at least one correction impulse was applied.
 *
 * Example: [_helicopter, speed _helicopter, getPosASL _helicopter # 2, {false}]
 *     spawn Waldo_fnc_HelicopterDecelerationCorrectLocal;
 * Current caller: Waldo_fnc_HelicopterDecelerationTrackLocal.
 */

params [
    ["_aircraft", objNull, [objNull]],
    ["_detectedSpeed", 0, [0]],
    ["_detectedAltitude", 0, [0]],
    ["_isLandingOrder", {false}, [{}]]
];
if (isNull _aircraft || {!local _aircraft} || {_aircraft getVariable ["Waldo_HelicopterDeceleration_Active", false]}) exitWith {false};

_aircraft setVariable ["Waldo_HelicopterDeceleration_Active", true, true];
private _start = diag_tickTime;
private _deadline = _start + ((missionNamespace getVariable ["Waldo_HelicopterDeceleration_MaximumCorrectionSeconds", 4]) max 0.1);
private _interval = (missionNamespace getVariable ["Waldo_HelicopterDeceleration_ControlInterval", 0.02]) max 0.01;
private _maximumAcceleration = (missionNamespace getVariable ["Waldo_HelicopterDeceleration_MaximumCorrectionAcceleration", 2.5]) max 0;
private _maximumClimbRate = missionNamespace getVariable ["Waldo_HelicopterDeceleration_MaximumClimbRate", 0.5];
private _minimumAltitude = (missionNamespace getVariable ["Waldo_HelicopterDeceleration_MinimumAltitude", 25]) max 0;
private _clearance = (missionNamespace getVariable ["Waldo_HelicopterDeceleration_TerrainClearance", 25]) max 0;
private _debug = missionNamespace getVariable ["Waldo_HelicopterDeceleration_Debug", false];
private _correcting = true;
private _applied = false;
private _reason = "TIMEOUT";
private _nextTerrainCheck = 0;
private _terrainClear = true;

_aircraft setVariable ["Waldo_HelicopterDeceleration_LastResult", ["ACTIVE", clientOwner, diag_tickTime, _detectedSpeed, _detectedAltitude], true];
if (_debug) then {diag_log format ["[WMP AI DECEL] Acquired owner=%1 aircraft=%2 speed=%3 altitudeASL=%4", clientOwner, netId _aircraft, round _detectedSpeed, round _detectedAltitude]};

while {_correcting && {diag_tickTime < _deadline}} do {
    private _pilot = currentPilot _aircraft;
    private _pilotAwake = if (isNull _pilot) then {false} else {
        if (!isNil "ace_common_fnc_isAwake") then {[_pilot] call ace_common_fnc_isAwake} else {lifeState _pilot != "INCAPACITATED"}
    };
    if (
        !local _aircraft || {!alive _aircraft}
        || {!(missionNamespace getVariable ["Waldo_HelicopterDeceleration_Enable", false])}
        || {_aircraft getVariable ["Waldo_HelicopterDeceleration_Exclude", false]}
        || {_aircraft getVariable ["Waldo_ImprovedHelicopterLanding_Active", false]}
        || {[_aircraft] call _isLandingOrder}
        || {isNull _pilot} || {!alive _pilot} || {!_pilotAwake} || {isPlayer _pilot}
        || {!isNull (remoteControlled _pilot)} || {!isEngineOn _aircraft} || {!canMove _aircraft}
        || {fuel _aircraft <= 0} || {isTouchingGround _aircraft} || {!isNull (getSlingLoad _aircraft)}
    ) then {
        _reason = if (_aircraft getVariable ["Waldo_ImprovedHelicopterLanding_Active", false] || {[_aircraft] call _isLandingOrder}) then {"LANDING_PRIORITY"} else {"INELIGIBLE"};
        _correcting = false;
    };

    if (_correcting && {diag_tickTime >= _nextTerrainCheck}) then {
        _nextTerrainCheck = diag_tickTime + 0.2;
        private _positionASL = getPosASL _aircraft;
        private _direction = vectorDir _aircraft;
        private _horizontal = [_direction select 0, _direction select 1, 0];
        private _magnitude = vectorMagnitude _horizontal;
        if (_magnitude < 0.01) then {_horizontal = [0, 1, 0]} else {_horizontal = _horizontal vectorMultiply (1 / _magnitude)};
        _terrainClear = ((getPosATL _aircraft) select 2) >= _minimumAltitude;
        {
            private _ahead = _positionASL vectorAdd (_horizontal vectorMultiply _x);
            if ((_positionASL select 2) - (getTerrainHeightASL _ahead) < _clearance) exitWith {_terrainClear = false};
        } forEach [100, 300, 500];
        if (!_terrainClear) then {_reason = "TERRAIN_GUARD"; _correcting = false};
    };

    if (_correcting) then {
        private _velocity = velocity _aircraft;
        private _climbRate = _velocity select 2;
        private _noseUp = vectorDir _aircraft select 2;
        if (_climbRate <= _maximumClimbRate || {_noseUp <= 0}) then {
            _reason = "STABLE";
            _correcting = false;
        } else {
            private _altitudeGain = (((getPosASL _aircraft) select 2) - _detectedAltitude) max 0;
            private _acceleration = (((_climbRate - _maximumClimbRate) * 1.2) + (_altitudeGain * 0.2)) min _maximumAcceleration;
            // Recheck landing ownership at the exact mutation boundary. This closes the small gap
            // between the loop's eligibility test and its impulse if a waypoint changes that frame.
            if (
                _acceleration > 0
                && {!(_aircraft getVariable ["Waldo_ImprovedHelicopterLanding_Active", false])}
                && {!([_aircraft] call _isLandingOrder)}
            ) then {
                // addForce expects a world-space impulse. Multiplying acceleration by mass and this
                // frame interval keeps the response comparable across light and heavy helicopters.
                _aircraft addForce [[0, 0, -(getMass _aircraft) * _acceleration * _interval], getCenterOfMass _aircraft];
                _applied = true;
            } else {
                if (_aircraft getVariable ["Waldo_ImprovedHelicopterLanding_Active", false] || {[_aircraft] call _isLandingOrder}) then {
                    _reason = "LANDING_PRIORITY";
                    _correcting = false;
                };
            };
        };
    };
    if (_correcting) then {uiSleep _interval};
};

if (!isNull _aircraft) then {
    _aircraft setVariable ["Waldo_HelicopterDeceleration_Active", false, true];
    _aircraft setVariable ["Waldo_HelicopterDeceleration_LastResult", [_reason, clientOwner, diag_tickTime, abs speed _aircraft, (getPosASL _aircraft) select 2], true];
};
if (_debug) then {diag_log format ["[WMP AI DECEL] Released owner=%1 aircraft=%2 reason=%3 applied=%4", clientOwner, if (isNull _aircraft) then {"NULL"} else {netId _aircraft}, _reason, _applied]};
_applied
