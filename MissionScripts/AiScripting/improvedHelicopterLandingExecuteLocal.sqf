/*
 * Author: WaldoTheWarfighter
 * Guides one local AI helicopter down an exact terrain-following glideslope using bounded velocity
 * and orientation vectors. It flares as horizontal speed falls, limits upward/downward collective,
 * aligns the final attitude to the landing slope, raises the approach over nearby tree canopies and
 * performs a bounded go-around when the aircraft reaches the landing area excessively high.
 *
 * Arguments:
 * 0: helicopter <OBJECT>
 * 1: landing position <ARRAY>
 * 2: waypoint type <STRING>
 * 3: expected waypoint index <NUMBER>
 *
 * Return Value: BOOL - true on touchdown, false after a validated abort.
 *
 * Example: [_helicopter, _position, "TR UNLOAD", _index] call Waldo_fnc_ImprovedHelicopterLandingExecuteLocal;
 * Current caller: ImprovedHelicopterLandingTrackLocal when a supported landing waypoint enters range.
 */

params [
    ["_helicopter", objNull, [objNull]],
    ["_targetPosition", [], [[]]],
    ["_waypointType", "", [""]],
    ["_expectedWaypoint", -1, [0]]
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
private _minimumDistance = ([_helicopter, "MinimumActivationDistance", 50] call Waldo_fnc_ImprovedHelicopterLandingSetting) max 50;
if (_helicopter distance2D _targetPosition <= _minimumDistance) exitWith {false};

_helicopter setVariable ["Waldo_ImprovedHelicopterLanding_Active", true, true];
_helicopter disableAI "PATH";
_helicopter disableAI "MOVE";
_pilot disableAI "FSM";
private _startPositionASL = getPosASL _helicopter;
private _startTerrainASL = getTerrainHeightASL _startPositionASL;
private _targetTerrainASL = getTerrainHeightASL _targetPosition;
private _startDistance = (_helicopter distance2D _targetPosition) max 1;
private _entrySpeed = ((abs speed _helicopter) / 3.6) max 8;
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
private _treeHoverHeight = 0;
private _forwardAvoidance = 0;
private _goAround = false;
private _goArounds = 0;
private _goAroundHeading = _yaw;
private _abort = false;
private _landed = false;
private _lastPosition = getPosASL _helicopter;
private _lastTick = diag_tickTime;
private _targetSurfaceNormal = surfaceNormal _targetPosition;

while {!_abort && {!_landed}} do {
    private _now = diag_tickTime;
    private _delta = (_now - _lastTick) max 0.01;
    _lastTick = _now;
    private _positionASL = getPosASL _helicopter;
    private _expectedMovement = (vectorMagnitude (velocity _helicopter)) * _delta;
    if (_lastPosition distance _positionASL > (_expectedMovement + 8)) then {_abort = true;};
    _lastPosition = _positionASL;

    if (_now >= _nextValidation) then {
        _nextValidation = _now + 0.25;
        _pilot = currentPilot _helicopter;
        _pilotAwake = if (isNull _pilot) then {false} else {
            if (!isNil "ace_common_fnc_isAwake") then {[_pilot] call ace_common_fnc_isAwake} else {lifeState _pilot != "INCAPACITATED"}
        };
        _abort = _abort
            || {!local _helicopter}
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
            || {currentWaypoint _group != _expectedWaypoint};
        if (!_abort && {_expectedWaypoint < count (waypoints _group)}) then {
            _abort = (waypointPosition [_group, _expectedWaypoint]) distance2D _targetPosition > 25;
        };
    };

    private _distance = _helicopter distance2D _targetPosition;
    private _atlAltitude = (getPosATL _helicopter) select 2;
    private _touchdownRadius = [_helicopter, "TouchdownRadius", 2] call Waldo_fnc_ImprovedHelicopterLandingSetting;
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
    if (_now >= _nextObstacleScan && {_distance >= 30}) then {
        _nextObstacleScan = _now + 0.35;
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
    private _travelYaw = if (_goAround) then {_goAroundHeading} else {_yaw};
    private _desiredVelocityX = sin _travelYaw * _desiredSpeed;
    private _desiredVelocityY = cos _travelYaw * _desiredSpeed;
    private _desiredRelativeAltitude = if (_distance > _descentDistance) then {_transitAltitude} else {0.25 + ((_transitAltitude - 0.25) * (_distance / _descentDistance))};
    _desiredRelativeAltitude = _desiredRelativeAltitude + _forwardAvoidance;
    if (!_goAround && {_distance >= 5}) then {_desiredRelativeAltitude = _desiredRelativeAltitude max _treeHoverHeight;};
    private _progress = 1 - ((_distance / _startDistance) min 1 max 0);
    private _expectedTerrainASL = _startTerrainASL + ((_targetTerrainASL - _startTerrainASL) * _progress);
    private _altitudeError = (_expectedTerrainASL + _desiredRelativeAltitude) - (_positionASL select 2);
    private _desiredVelocityZ = if (_goAround) then {-3} else {
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

    private _xyBlend = if (!_goAround && {_distance < 15}) then {0.03 + (0.07 * (1 - (_distance / 15)))} else {0.025};
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
    _helicopter setVectorDirAndUp [_direction, vectorNormalized _up];
    _helicopter setVelocity _currentVelocity;
    if (_distance < 100 && {_atlAltitude < 50} && {!(_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_GearLocal", false])}) then {
        _helicopter setVariable ["Waldo_ImprovedHelicopterLanding_GearLocal", true];
        _pilot action ["LandGear", _helicopter];
    };
    if (_distance < _touchdownRadius && {isTouchingGround _helicopter || {_atlAltitude < 0.35}}) then {_landed = true;};
    uiSleep (([_helicopter, "ControlInterval", 0.05] call Waldo_fnc_ImprovedHelicopterLandingSetting) max 0.02 min 0.2);
};

[_helicopter, _landed, _waypointType] call Waldo_fnc_ImprovedHelicopterLandingRestoreLocal;
if (_landed && {local _helicopter}) then {
    private _mass = getMass _helicopter;
    [_helicopter, _mass] spawn {
        params ["_helicopter", "_mass"];
        private _deadline = diag_tickTime + 1.5;
        while {diag_tickTime < _deadline && {alive _helicopter} && {local _helicopter} && {isTouchingGround _helicopter}} do {
            _helicopter addForce [(vectorUp _helicopter) vectorMultiply (-0.5 * _mass), getCenterOfMass _helicopter];
            uiSleep 0.05;
        };
    };
};
_landed
