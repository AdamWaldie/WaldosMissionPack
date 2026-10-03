/*
 * Author: WaldoTheWarfighter
 * Applies bounded horizontal braking and downward world-space impulses to one local AI helicopter while its normal
 * cruise braking is producing an unwanted zoom-climb. Each impulse is mass- and interval-scaled;
 * no velocity, waypoint, AI feature or flight-height setting is overwritten.
 *
 * Improved Helicopter Landing is authoritative. A supported landing order or active landing
 * controller, pending/active Cortex attack, or missile-defence lease cancels this correction before
 * another impulse is applied. Terrain clearance, pilot, damage, sling-load, locality and timeout
 * checks also fail safe by releasing immediately.
 * Pilot/group replacement, waypoint edits, a direct Zeus hold and external-control handover cancel
 * the current correction.
 * Locality and authority: Scheduled only on the current aircraft owner. It changes velocity
 * only while that owner still controls an eligible AI helicopter.
 * Repeat/JIP: A bounded correction exits on timeout or locality change. The owner-local
 * tracker can start a new correction when needed; JIP clients do not gain flight authority.
 *
 * Arguments:
 * 0: aircraft <OBJECT>
 * 1: speed when detected <NUMBER, km/h>
 * 2: ASL altitude when detected <NUMBER, metres>
 * 3: landing-order predicate <CODE>
 * 4: ownership generation <NUMBER, -1 captures current generation for direct calls>
 * Return Value: BOOL - true if at least one correction impulse was applied.
 *
 * Example: [_helicopter, speed _helicopter, getPosASL _helicopter # 2, {false}]
 *     spawn Waldo_fnc_HelicopterDecelerationCorrectLocal;
 * Result: Returns true after at least one bounded impulse, or false when no correction is applied.
 * Current caller: Waldo_fnc_HelicopterDecelerationTrackLocal.
 */

params [
    ["_aircraft", objNull, [objNull]],
    ["_detectedSpeed", 0, [0]],
    ["_detectedAltitude", 0, [0]],
    ["_isLandingOrder", {false}, [{}]],
    ["_generation",-1,[0]]
];
if (isNull _aircraft || {!local _aircraft} || {_aircraft getVariable ["Waldo_HelicopterDeceleration_Active", false]}) exitWith {false};

if (_generation < 0) then {_generation=_aircraft getVariable ["Waldo_HelicopterDeceleration_GenerationLocal",0]};
private _entryPilot=currentPilot _aircraft;
if (isNull _entryPilot) exitWith {false};
private _entryGroup=group _entryPilot;
private _orderSignature={
    private _index=currentWaypoint _entryGroup;
    if (_index >= count waypoints _entryGroup) exitWith {[_index,count waypoints _entryGroup]};
    private _wp=[_entryGroup,_index];
    [_index,count waypoints _entryGroup,waypointPosition _wp,waypointType _wp,waypointScript _wp,waypointSpeed _wp]
};
private _entryOrder=call _orderSignature;
private _brakingTarget=if (count _entryOrder > 2 && {(_entryOrder select 3) == "MOVE"}) then {+(_entryOrder select 2)} else {[]};
private _entryDistance=if (_brakingTarget isEqualTo []) then {0} else {_aircraft distance2D _brakingTarget};
private _entryVelocity=velocity _aircraft;
private _entryHorizontal=sqrt ((_entryVelocity select 0)^2+(_entryVelocity select 1)^2);
private _ownsOrder={
    local _aircraft && {(_aircraft getVariable ["Waldo_HelicopterDeceleration_GenerationLocal",0]) == _generation}
        && {currentPilot _aircraft == _entryPilot} && {group _entryPilot == _entryGroup}
        && {(call _orderSignature) isEqualTo _entryOrder}
        && {!([_entryGroup] call Waldo_fnc_CortexZeusHeld)}
        && {!(_entryGroup getVariable ["Waldo_AI_ExternalControl",false])}
        && {isNull (_entryPilot getVariable ["bis_fnc_moduleRemoteControl_owner",objNull])}
};
if !(call _ownsOrder) exitWith {false};
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
private _lastImpulseTime = time - (_interval min 0.1);
private _correctionDeltaV = 0;
private _brakingDeltaV = 0;
private _nextBrakeLog = 0;

_aircraft setVariable ["Waldo_HelicopterDeceleration_LastResult", ["ACTIVE", clientOwner, diag_tickTime, _detectedSpeed, _detectedAltitude], true];
if (_debug) then {diag_log format ["[WMP AI DECEL] Acquired owner=%1 aircraft=%2 speed=%3 altitudeASL=%4 order=%5 approachDistance=%6", clientOwner, netId _aircraft, round _detectedSpeed, round _detectedAltitude, _entryOrder, _entryDistance]};

while {_correcting && {diag_tickTime < _deadline}} do {
    if !(call _ownsOrder) exitWith {
        if (_debug) then {diag_log format ["[WMP AI DECEL] Order released entry=%1 live=%2 pilotChanged=%3",_entryOrder,call _orderSignature,currentPilot _aircraft != _entryPilot]};
        _reason="ORDER_CHANGED"; _correcting=false
    };
    private _pilot = currentPilot _aircraft;
    private _pilotAwake = if (isNull _pilot) then {false} else {
        if (!isNil "ace_common_fnc_isAwake") then {[_pilot] call ace_common_fnc_isAwake} else {lifeState _pilot != "INCAPACITATED"}
    };
    if (
        !local _aircraft || {!alive _aircraft}
        || {!(missionNamespace getVariable ["Waldo_HelicopterDeceleration_Enable", false])}
        || {!(_aircraft isKindOf "Helicopter") && {!(missionNamespace getVariable ["Waldo_HelicopterDeceleration_IncludeVTOL",false]) || {!(_aircraft isKindOf "VTOL_Base_F")}}}
        || {_aircraft getVariable ["Waldo_HelicopterDeceleration_Exclude", false]}
        || {_aircraft getVariable ["Waldo_Cortex_AirAttackJob", false]}
        || {!isNil {_aircraft getVariable "Waldo_Cortex_AirAttackToken"}}
        || {!isNil {_aircraft getVariable "Waldo_Cortex_MissileDefenceActive"}}
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
                && {call _ownsOrder}
                && {!(_aircraft getVariable ["Waldo_Cortex_AirAttackJob", false])}
                && {isNil {_aircraft getVariable "Waldo_Cortex_AirAttackToken"}}
                && {isNil {_aircraft getVariable "Waldo_Cortex_MissileDefenceActive"}}
                && {!(_aircraft getVariable ["Waldo_ImprovedHelicopterLanding_Active", false])}
                && {!([_aircraft] call _isLandingOrder)}
            ) then {
                // Scheduled sleeps are a minimum delay, not the elapsed simulation time.
                // Integrate elapsed time so scheduler load does not weaken the correction.
                // Cap catch-up after a stall and never remove more than the excess climb.
                private _elapsed = ((time - _lastImpulseTime) max 0) min 0.1;
                _lastImpulseTime = time;
                private _deltaV = (_acceleration * _elapsed) min ((_climbRate - _maximumClimbRate) max 0);
                if (_deltaV > 0) then {
                    private _horizontal=[_velocity select 0,_velocity select 1,0];
                    private _horizontalSpeed=vectorMagnitude _horizontal;
                    private _brake=0;
                    // Use the landing controller's distance-based speed envelope without
                    // replacing the route, yaw or attitude. Only assist an existing approach.
                    if (_entryDistance > 10 && {_horizontalSpeed > 1}) then {
                        private _distance=_aircraft distance2D _brakingTarget;
                        private _toward=_brakingTarget vectorDiff getPosATL _aircraft;
                        _toward set [2,0];
                        if ((_horizontal vectorDotProduct _toward) > 0 && {_distance < _entryDistance}) then {
                            private _desiredSpeed=(_entryHorizontal * sqrt ((_distance/_entryDistance) min 1)) max 2;
                            _brake=((_horizontalSpeed-_desiredSpeed) max 0) min (_maximumAcceleration*_elapsed);
                            if (_debug && {diag_tickTime >= _nextBrakeLog}) then {
                                _nextBrakeLog=diag_tickTime+1;
                                diag_log format ["[WMP AI DECEL] Approach distance=%1 entryDistance=%2 horizontal=%3 desired=%4 brakeDeltaV=%5",_distance,_entryDistance,_horizontalSpeed,_desiredSpeed,_brake];
                            };
                        };
                    };
                    private _change=if (_horizontalSpeed > 1) then {_horizontal vectorMultiply (-_brake/_horizontalSpeed)} else {[0,0,0]};
                    _change set [2,-_deltaV];
                    _aircraft addForce [_change vectorMultiply getMass _aircraft, getCenterOfMass _aircraft];
                    _brakingDeltaV=_brakingDeltaV+_brake;
                    _correctionDeltaV = _correctionDeltaV + _deltaV;
                    _applied = true;
                };
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

if (!isNull _aircraft && {local _aircraft} && {(_aircraft getVariable ["Waldo_HelicopterDeceleration_GenerationLocal",0]) == _generation}) then {
    _aircraft setVariable ["Waldo_HelicopterDeceleration_Active", false, true];
    _aircraft setVariable ["Waldo_HelicopterDeceleration_LastResult", [_reason, clientOwner, diag_tickTime, abs speed _aircraft, (getPosASL _aircraft) select 2], true];
};
if (_debug) then {diag_log format ["[WMP AI DECEL] Released owner=%1 aircraft=%2 reason=%3 applied=%4 correctionDeltaV=%5 brakingDeltaV=%6", clientOwner, if (isNull _aircraft) then {"NULL"} else {netId _aircraft}, _reason, _applied, _correctionDeltaV, _brakingDeltaV]};
_applied
