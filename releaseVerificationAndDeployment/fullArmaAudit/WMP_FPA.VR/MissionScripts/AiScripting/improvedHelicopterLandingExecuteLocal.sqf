/*
 * Author: WaldoTheWarfighter
 * Guides one local AI helicopter down an exact terrain-following glideslope using bounded velocity
 * and orientation vectors. It flares as horizontal speed falls, limits upward/downward collective,
 * aligns the final attitude to the landing slope, raises the approach over nearby tree canopies and
 * performs a bounded go-around when the aircraft reaches the landing area excessively high. Once
 * inside FinalCommitDistance, premature engine completion of the landing waypoint cannot cancel
 * the flare, while deletion or editing of that waypoint always releases the aircraft immediately.
 * LastResult is broadcast on the helicopter for locality-safe diagnostics and QA.
 *
 * Arguments:
 * 0: helicopter <OBJECT>
 * 1: landing position <ARRAY>
 * 2: waypoint type <STRING>
 * 3: expected waypoint index <NUMBER>
 * 4: expected waypoint script <STRING> (default "")
 *
 * Return Value: BOOL - true on touchdown, false after a validated abort.
 *
 * Example: [_helicopter, _position, "TR UNLOAD", _index, ""] call Waldo_fnc_ImprovedHelicopterLandingExecuteLocal;
 * Current caller: ImprovedHelicopterLandingTrackLocal when a supported landing waypoint enters range.
 */

params [
    ["_helicopter", objNull, [objNull]],
    ["_targetPosition", [], [[]]],
    ["_waypointType", "", [""]],
    ["_expectedWaypoint", -1, [0]],
    ["_expectedScript", "", [""]]
];
if (
    isNull _helicopter
    || {!local _helicopter}
    || {!alive _helicopter}
    || {count _targetPosition < 2}
    || {_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_Active", false]}
) exitWith {false};

private _pilot = currentPilot _helicopter;
private _pilotAwake = if (isNull _pilot) then {false} else {
    if (!isNil "ace_common_fnc_isAwake") then {[_pilot] call ace_common_fnc_isAwake} else {lifeState _pilot != "INCAPACITATED"}
};
if (isNull _pilot || {isPlayer _pilot} || {!isNull (remoteControlled _pilot)} || {!alive _pilot} || {!_pilotAwake}) exitWith {false};
private _group = group _pilot;
private _groupHelicopterCount = {
    params ["_group"];
    private _aircraft = [];
    {
        private _vehicle = vehicle _x;
        if (_vehicle isKindOf "Helicopter") then {_aircraft pushBackUnique _vehicle;};
    } forEach units _group;
    count _aircraft
};
// Exact vector landing owns one aircraft and one touchdown point. A formation must remain entirely
// under vanilla group flight control; acquiring any member would steer the shared group into one LZ.
if ([_group] call _groupHelicopterCount != 1) exitWith {false};
private _minimumDistance = ([_helicopter, "MinimumActivationDistance", 50] call Waldo_fnc_ImprovedHelicopterLandingSetting) max 50;
if (_helicopter distance2D _targetPosition <= _minimumDistance) exitWith {false};

// Landing is the authoritative helicopter controller. Any optional cruise-deceleration correction
// sees this state before its next impulse and releases without changing landing vectors or AI state.
_helicopter setVariable ["Waldo_ImprovedHelicopterLanding_Active", true, true];
private _controlRevision = (_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_ControlRevision", 0]) + 1;
_helicopter setVariable ["Waldo_ImprovedHelicopterLanding_ControlRevision", _controlRevision, true];
_helicopter setVariable ["Waldo_HelicopterDeceleration_Active", false, true];
_helicopter disableAI "PATH";
_helicopter disableAI "MOVE";
_pilot disableAI "FSM";
private _startPositionASL = getPosASL _helicopter;
// Remember the aircraft's real pre-controller flight layer. The touchdown anchor later uses forced
// height zero; if Zeus moves/deletes the landing waypoint afterwards, restore uses this non-forced
// height instead of imposing the generic landing transit altitude on the new order.
_helicopter setVariable [
    "Waldo_ImprovedHelicopterLanding_ReleaseHeight",
    (((getPosATL _helicopter) select 2) max 20) min 500
];
private _startTerrainASL = getTerrainHeightASL _startPositionASL;
private _targetTerrainASL = getTerrainHeightASL _targetPosition;
private _startDistance = (_helicopter distance2D _targetPosition) max 1;
// Do not inherit an almost stationary take-off speed as the pace for the entire approach. This is
// particularly visible on agile light helicopters and short transport legs.
private _entrySpeed = ((abs speed _helicopter) / 3.6) max ((([_helicopter, "MinimumApproachSpeed", 55] call Waldo_fnc_ImprovedHelicopterLandingSetting) max 0) / 3.6);
private _transitAltitude = ((getPosATL _helicopter) select 2) max ([_helicopter, "TransitAltitude", 30] call Waldo_fnc_ImprovedHelicopterLandingSetting);
private _glideRatio = ([_helicopter, "GlideSlopeRatio", 4] call Waldo_fnc_ImprovedHelicopterLandingSetting) max 2;
private _descentDistance = (_transitAltitude * _glideRatio) max 150;
private _currentVelocity = velocity _helicopter;
private _attitude = _helicopter call BIS_fnc_getPitchBank;
private _pitch = _attitude param [0, 0];
private _bank = -(_attitude param [1, 0]);
private _yaw = getDir _helicopter;
private _startTime = diag_tickTime;
private _nextValidation = 0;
private _nextObstacleScan = 0;
// Deliberately separate from _nextObstacleScan (the tree-canopy hover-height timer below): the two
// scans have different distance gates (<120 vs >=30) and different rescan intervals (0.5s vs 0.35s).
// Sharing one timer meant that for the entire overlap band (30-120 m, essentially the whole final
// approach), the canopy scan's own <120 condition let it claim and reschedule the shared timer every
// cycle before the forward scan's check ran - starving it completely. _forwardAvoidance would then
// freeze at whatever value it held from outside 120 m and never update again for the rest of the
// approach, in either direction.
private _nextForwardScan = 0;
private _treeHoverHeight = 0;
private _forwardAvoidance = 0;
private _goAround = false;
private _goArounds = 0;
private _goAroundHeading = _yaw;
private _abort = false;
private _groupedAbort = false;
private _landed = false;
private _lastPosition = getPosASL _helicopter;
private _lastTick = diag_tickTime;
private _targetSurfaceNormal = surfaceNormal _targetPosition;
private _touchdownRadius = [_helicopter, "TouchdownRadius", 2] call Waldo_fnc_ImprovedHelicopterLandingSetting;
private _finalCommitDistance = (([_helicopter, "FinalCommitDistance", 75] call Waldo_fnc_ImprovedHelicopterLandingSetting) max (_touchdownRadius + 5)) min 150;
private _committedToTouchdown = false;
private _closestDistance = _startDistance;
_helicopter setVariable ["Waldo_ImprovedHelicopterLanding_LastResult", ["ACTIVE", _targetPosition, diag_tickTime, _startDistance, (getPosATL _helicopter) select 2], true];

while {
    !_abort
    && {!_landed}
    && {_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_Active", false]}
    && {(_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_ControlRevision", -1]) == _controlRevision}
} do {
    private _now = diag_tickTime;
    private _delta = (_now - _lastTick) max 0.01;
    _lastTick = _now;
    private _positionASL = getPosASL _helicopter;
    private _expectedMovement = (vectorMagnitude (velocity _helicopter)) * _delta;
    if (_lastPosition distance _positionASL > (_expectedMovement + 8)) then {_abort = true;};
    _lastPosition = _positionASL;
    private _distance = _helicopter distance2D _targetPosition;
    _closestDistance = _closestDistance min _distance;
    if (_distance <= _finalCommitDistance) then {_committedToTouchdown = true;};
    private _atlAltitude = (getPosATL _helicopter) select 2;
    private _liveVelocity = velocity _helicopter;
    private _horizontalVelocity = sqrt (((_liveVelocity select 0) ^ 2) + ((_liveVelocity select 1) ^ 2));
    // isTouchingGround is unreliable for some helicopter geometry: a settled Little Bird reports
    // roughly 0.65 m ATL. Accept only a tight, slow envelope at the exact touchdown point.
    if (
        _distance < _touchdownRadius
        && {_atlAltitude <= 1}
        && {_horizontalVelocity <= 2}
        && {abs (_liveVelocity select 2) <= 1.5}
    ) then {_landed = true;};
    if (_landed) exitWith {};

    if (_now >= _nextValidation) then {
        _nextValidation = _now + 0.25;
        _pilot = currentPilot _helicopter;
        _pilotAwake = if (isNull _pilot) then {false} else {
            if (!isNil "ace_common_fnc_isAwake") then {[_pilot] call ace_common_fnc_isAwake} else {lifeState _pilot != "INCAPACITATED"}
        };
        _abort = _abort
            || {!local _helicopter}
            || {group _pilot != _group}
            || {!alive _helicopter}
            || {!(missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_Enable", true])}
            || {_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_Exclude", false]}
            || {isNull _pilot}
            || {!alive _pilot}
            || {!_pilotAwake}
            || {isPlayer _pilot}
            || {!isNull (remoteControlled _pilot)}
            || {!isEngineOn _helicopter}
            || {!isNull (getSlingLoad _helicopter)}
            || {!canMove _helicopter}
            || {fuel _helicopter <= 0}
            || {!_committedToTouchdown && {currentWaypoint _group != _expectedWaypoint}}
            || {_expectedWaypoint < 0}
            || {_expectedWaypoint >= count (waypoints _group)};
        if (!_abort && {[_group] call _groupHelicopterCount != 1}) then {
            _abort = true;
            _groupedAbort = true;
        };
        if (!_abort) then {
            private _liveWaypoint = [_group, _expectedWaypoint];
            private _liveType = toUpperANSI (waypointType _liveWaypoint);
            private _liveScript = toLowerANSI (waypointScript _liveWaypoint);
            // A moved waypoint is a new order. Abort this controller and let the tracker decide
            // whether the revised landing task is far enough away to acquire as a fresh approach.
            _abort = (waypointPosition _liveWaypoint) distance2D _targetPosition > 0.5
                || {_liveType != _waypointType}
                || {_waypointType == "SCRIPTED" && {_liveScript != _expectedScript}};
        };
    };

    if (isTouchingGround _helicopter && {_distance > (_touchdownRadius + 5)}) then {_abort = true;};
    if (_abort) exitWith {};
    private _relativeTargetAltitude = (_positionASL select 2) - _targetTerrainASL;
    if (!_goAround && {_goArounds < ([_helicopter, "MaximumGoArounds", 1] call Waldo_fnc_ImprovedHelicopterLandingSetting)}) then {
        if (
            _distance < ([_helicopter, "GoAroundTriggerDistance", 200] call Waldo_fnc_ImprovedHelicopterLandingSetting)
            && {_relativeTargetAltitude > ([_helicopter, "GoAroundHeight", 150] call Waldo_fnc_ImprovedHelicopterLandingSetting)}
        ) then {
            _goAround = true;
            _goArounds = _goArounds + 1;
            _goAroundHeading = _yaw;
        };
    };
    if (_goAround && {_distance >= ([_helicopter, "GoAroundExitDistance", 250] call Waldo_fnc_ImprovedHelicopterLandingSetting)}) then {
        _goAround = false;
        _startDistance = _distance max 1;
        _entrySpeed = ((abs speed _helicopter) / 3.6) max 12;
        _startTerrainASL = getTerrainHeightASL _positionASL;
        _startTime = _now;
        _treeHoverHeight = 0;
        _closestDistance = _distance;
    };
    if (
        !_goAround
        && {_goArounds < ([_helicopter, "MaximumGoArounds", 1] call Waldo_fnc_ImprovedHelicopterLandingSetting)}
        && {_closestDistance < 80}
        && {_distance > (_closestDistance + 20)}
    ) then {
        _goAround = true;
        _goArounds = _goArounds + 1;
        _goAroundHeading = getDir _helicopter;
    };

    if (_now >= _nextObstacleScan && {_distance < 120}) then {
        _nextObstacleScan = _now + 0.5;
        private _trees = nearestTerrainObjects [_targetPosition, ["TREE", "SMALL TREE"], [_helicopter, "TreeScanRadius", 25] call Waldo_fnc_ImprovedHelicopterLandingSetting, false, true];
        private _highestCanopy = _targetTerrainASL;
        {
            private _bounds = boundingBoxReal _x;
            private _top = (_bounds param [1, [0, 0, 0]]) param [2, 0];
            _highestCanopy = _highestCanopy max (((getPosASL _x) select 2) + _top);
        } forEach (_trees select [0, (count _trees) min 12]);
        _treeHoverHeight = (((_highestCanopy - _targetTerrainASL) max 0) + ([_helicopter, "TreeSafetyBuffer", 5] call Waldo_fnc_ImprovedHelicopterLandingSetting))
            min ([_helicopter, "MaximumTreeHoverHeight", 40] call Waldo_fnc_ImprovedHelicopterLandingSetting);
    };
    if (_now >= _nextForwardScan && {_distance >= 30}) then {
        _nextForwardScan = _now + 0.35;
        private _scanPosition = _helicopter getPos [50, getDir _helicopter];
        private _aheadTrees = nearestTerrainObjects [_scanPosition, ["TREE", "SMALL TREE"], 18, false, true];
        _forwardAvoidance = if (_aheadTrees isEqualTo []) then {(_forwardAvoidance - 2) max 0} else {(_forwardAvoidance + 4) min 25};
    };

    private _desiredYaw = if (_goAround) then {_goAroundHeading} else {_helicopter getDir _targetPosition};
    if (!_goAround && {_distance < 8}) then {_desiredYaw = _yaw;};
    private _yawDifference = _desiredYaw - _yaw;
    while {_yawDifference > 180} do {_yawDifference = _yawDifference - 360;};
    while {_yawDifference < -180} do {_yawDifference = _yawDifference + 360;};
    private _desiredBank = if (!_goAround && {_distance > 20}) then {(_yawDifference * -2.2) min 42 max -42} else {0};
    _bank = _bank + ((_desiredBank - _bank) * 0.08);
    _yaw = _yaw + (((_yawDifference * 0.045) + (_bank * -0.012)) min 1.5 max -1.5);
    if (_yaw < 0) then {_yaw = _yaw + 360;};
    if (_yaw >= 360) then {_yaw = _yaw - 360;};

    private _desiredSpeed = if (_goAround) then {
        (([_helicopter, "GoAroundSpeed", 70] call Waldo_fnc_ImprovedHelicopterLandingSetting) / 3.6) max 15
    } else {
        private _factor = sqrt ((_distance / _startDistance) min 1);
        (_entrySpeed * _factor) max (2 min _distance)
    };
    private _targetDeltaX = (_targetPosition select 0) - (_positionASL select 0);
    private _targetDeltaY = (_targetPosition select 1) - (_positionASL select 1);
    private _targetDeltaMagnitude = (sqrt ((_targetDeltaX * _targetDeltaX) + (_targetDeltaY * _targetDeltaY))) max 0.01;
    private _desiredVelocityX = if (_goAround) then {sin _goAroundHeading * _desiredSpeed} else {(_targetDeltaX / _targetDeltaMagnitude) * _desiredSpeed};
    private _desiredVelocityY = if (_goAround) then {cos _goAroundHeading * _desiredSpeed} else {(_targetDeltaY / _targetDeltaMagnitude) * _desiredSpeed};
    private _desiredRelativeAltitude = if (_distance > _descentDistance) then {_transitAltitude} else {0.25 + ((_transitAltitude - 0.25) * (_distance / _descentDistance))};
    // Both obstacle-clearance floors below must release together once genuinely close to touchdown,
    // matched to the same _distance >= 5 threshold. The forward scan (_nextForwardScan above) also
    // stops rescanning below 30 m, so whatever value _forwardAvoidance held at that point is frozen
    // for the final stretch - in a confined clearing, where trees sit within 18 m of the heading the
    // helicopter freezes facing once nearly overhead, that value is commonly non-zero. Without this
    // gate the frozen floor keeps adding height right through the hover-and-descend phase with no way
    // back to zero: the concrete "hovers like a sitting duck, comes down far too slowly" symptom this
    // closes. Releasing it here at the same distance as the tree-canopy floor is enough regardless of
    // whether the last in-range scan happened to leave it at zero or not.
    if (_distance >= 5) then {_desiredRelativeAltitude = _desiredRelativeAltitude + _forwardAvoidance;};
    if (!_goAround && {_distance >= 5}) then {_desiredRelativeAltitude = _desiredRelativeAltitude max _treeHoverHeight;};
    private _progress = 1 - ((_distance / _startDistance) min 1 max 0);
    private _expectedTerrainASL = _startTerrainASL + ((_targetTerrainASL - _startTerrainASL) * _progress);
    private _altitudeError = (_expectedTerrainASL + _desiredRelativeAltitude) - (_positionASL select 2);
    private _desiredVelocityZ = if (_goAround) then {3} else {
        (_altitudeError * 0.45)
            min ([_helicopter, "MaximumClimbRate", 8] call Waldo_fnc_ImprovedHelicopterLandingSetting)
            max (-([_helicopter, "MaximumDescentRate", 10] call Waldo_fnc_ImprovedHelicopterLandingSetting))
    };
    if (!_goAround && {_distance < 12}) then {_desiredVelocityZ = _desiredVelocityZ min -0.35;};

    private _actualSpeedMS = ((abs speed _helicopter) / 3.6) max 0.1;
    private _deltaSpeed = _actualSpeedMS - _desiredSpeed;
    private _desiredPitch = if (_goAround) then {-6} else {(_deltaSpeed * (if (_distance < 150) then {4.5} else {2.2})) min 36 max -20};
    if (_desiredVelocityZ > 2) then {_desiredPitch = _desiredPitch * (1 - ((_desiredVelocityZ / 12) min 1));};
    if (_atlAltitude < 1) then {_desiredPitch = _desiredPitch min (_atlAltitude * 30);};
    _desiredPitch = _desiredPitch - (abs _bank * 0.22);
    _pitch = _pitch + ((_desiredPitch - _pitch) * 0.045);

    private _xyBlend = if (!_goAround && {_distance < 20}) then {0.10 + (0.10 * (1 - (_distance / 20)))} else {0.06};
    _currentVelocity set [0, (_currentVelocity select 0) + ((_desiredVelocityX - (_currentVelocity select 0)) * _xyBlend)];
    _currentVelocity set [1, (_currentVelocity select 1) + ((_desiredVelocityY - (_currentVelocity select 1)) * _xyBlend)];
    private _zBlend = if (_desiredVelocityZ > (_currentVelocity select 2)) then {0.16} else {0.10};
    _currentVelocity set [2, (_currentVelocity select 2) + ((_desiredVelocityZ - (_currentVelocity select 2)) * _zBlend)];
    if ((_now - _startTime) < 2.5) then {
        private _engineWeight = (1 - ((_now - _startTime) / 2.5)) ^ 3;
        private _actualVelocity = velocity _helicopter;
        for "_axis" from 0 to 2 do {
            _currentVelocity set [_axis, ((_currentVelocity select _axis) * (1 - _engineWeight)) + ((_actualVelocity select _axis) * _engineWeight)];
        };
    };

    private _direction = [sin _yaw * cos _pitch, cos _yaw * cos _pitch, sin _pitch];
    private _right = [
        cos _yaw * cos _bank - sin _yaw * sin _pitch * sin _bank,
        -sin _yaw * cos _bank - cos _yaw * sin _pitch * sin _bank,
        cos _pitch * sin _bank
    ];
    private _up = _right vectorCrossProduct _direction;
    if (!_goAround && {_distance < 6 && {_atlAltitude < 3}}) then {
        private _slopeBlend = (1 - ((_distance max _atlAltitude) / 6)) max 0 min 1;
        _up = (_up vectorMultiply (1 - _slopeBlend)) vectorAdd (_targetSurfaceNormal vectorMultiply _slopeBlend);
    };
    // Grouping can occur between the periodic validation above and this frame's write. Recheck at
    // the actual mutation boundary so no further WMP vector reaches a newly formed flight.
    if ([_group] call _groupHelicopterCount != 1) then {
        _abort = true;
        _groupedAbort = true;
    } else {
        _helicopter setVectorDirAndUp [_direction, vectorNormalized _up];
        _helicopter setVelocity _currentVelocity;
    };
    if (_distance < 100 && {_atlAltitude < 50} && {!(_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_GearLocal", false])}) then {
        _helicopter setVariable ["Waldo_ImprovedHelicopterLanding_GearLocal", true];
        _pilot action ["LandGear", _helicopter];
    };
    if (_distance < _touchdownRadius && {isTouchingGround _helicopter || {_atlAltitude < 0.35}}) then {_landed = true;};
    uiSleep (([_helicopter, "ControlInterval", 0.05] call Waldo_fnc_ImprovedHelicopterLandingSetting) max 0.02 min 0.2);
};

if ((_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_ControlRevision", -1]) == _controlRevision) then {
    _helicopter setVariable [
        "Waldo_ImprovedHelicopterLanding_LastResult",
        [["ABORTED", "LANDED"] select _landed, _targetPosition, diag_tickTime, _helicopter distance2D _targetPosition, (getPosATL _helicopter) select 2],
        true
    ];
};
if (
    _landed
    && {local _helicopter}
    && {(_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_ControlRevision", -1]) == _controlRevision}
) then {
    [_helicopter, _group, _targetPosition, _waypointType, _expectedWaypoint, _expectedScript, count (waypoints _group), _controlRevision] spawn Waldo_fnc_ImprovedHelicopterLandingAnchorLocal;
} else {
    // Do not repeat the restore when something else already reclaimed and reconfigured the
    // aircraft while this approach was still catching up to its own abort - most commonly a fresh
    // Waldo_fnc_TransportDispatchLocal retargeting call (a mid-approach MOVE_PICKUP/SET_DESTINATION,
    // i.e. the player moved the LZ), which calls this same restore function itself before wiping
    // waypoints and then applies its own real cruise flyInHeight/land state. This loop's own Active
    // flag being already false at this point means someone else is responsible for the aircraft's
    // flight state now; calling restore again here would stomp that fresh state with the default
    // ~30m transit altitude, degrading the aircraft to a slow, low-altitude crawl toward the new
    // target with no clean cancel - the concrete "moves like a snail and lands randomly enroute
    // after moving the LZ" symptom this closes. Mirrors the equivalent fix already applied to the
    // post-touchdown ground-anchor loop in Waldo_fnc_ImprovedHelicopterLandingAnchorLocal.
    if (
        _helicopter getVariable ["Waldo_ImprovedHelicopterLanding_Active", false]
        && {(_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_ControlRevision", -1]) == _controlRevision}
    ) then {
        [_helicopter, false, "", _groupedAbort] call Waldo_fnc_ImprovedHelicopterLandingRestoreLocal;
    };
};
_landed
