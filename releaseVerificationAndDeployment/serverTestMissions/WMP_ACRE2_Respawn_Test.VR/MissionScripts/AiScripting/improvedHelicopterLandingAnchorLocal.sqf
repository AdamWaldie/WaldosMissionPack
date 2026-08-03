/*
 * Author: WaldoTheWarfighter
 * Keeps a successfully landed local AI helicopter committed to the ground until its orders or
 * ownership genuinely change. The anchor survives vanilla completion of the final landing
 * waypoint, but releases for a moved, deleted or retyped landing waypoint, a valid onward
 * waypoint after the settling delay, Zeus/player pilot takeover, locality migration, feature
 * disablement or loss of a usable AI pilot. This function is scheduled and locality-safe.
 *
 * Arguments:
 * 0: helicopter <OBJECT>
 * 1: pilot group <GROUP>
 * 2: touchdown position <ARRAY>
 * 3: landing waypoint type <STRING>
 * 4: landing waypoint index <NUMBER>
 * 5: landing waypoint script <STRING> (default "")
 * 6: waypoint count at controller acquisition <NUMBER>
 *
 * Return Value: BOOL - true after the local ground-anchor lifecycle ends.
 *
 * Example: [_helicopter, _group, _position, "SCRIPTED", 1, _script, 2] spawn Waldo_fnc_ImprovedHelicopterLandingAnchorLocal;
 * Current caller: ImprovedHelicopterLandingExecuteLocal after a validated touchdown.
 */

params [
    ["_helicopter", objNull, [objNull]],
    ["_group", grpNull, [grpNull]],
    ["_targetPosition", [], [[]]],
    ["_waypointType", "", [""]],
    ["_expectedWaypoint", -1, [0]],
    ["_expectedScript", "", [""]],
    ["_expectedWaypointCount", 0, [0]]
];
if (isNull _helicopter || {isNull _group} || {count _targetPosition < 2} || {!local _helicopter}) exitWith {false};

private _normalisedType = toUpperANSI _waypointType;
private _normalisedScript = toLowerANSI _expectedScript;
private _settleUntil = diag_tickTime + (([_helicopter, "TouchdownHoldSeconds", 8] call Waldo_fnc_ImprovedHelicopterLandingSetting) max 0 min 60);
private _anchorPosition = getPosASL _helicopter;
private _mass = getMass _helicopter;
private _nextValidation = 0;
private _release = false;
private _releaseReason = "UNKNOWN";

_helicopter setVariable ["Waldo_ImprovedHelicopterLanding_Active", true, true];
_helicopter setVariable ["Waldo_ImprovedHelicopterLanding_GearLocal", false];
_helicopter setVariable ["Waldo_ImprovedHelicopterLanding_LastResult", ["ANCHORED", _targetPosition, diag_tickTime, 0, (getPosATL _helicopter) select 2], true];
_helicopter disableAI "MOVE";
_helicopter enableAI "PATH";
_helicopter land "LAND";
_helicopter flyInHeight 0;
_helicopter setVelocity [0, 0, 0];
private _pilot = currentPilot _helicopter;
if (!isNull _pilot) then {_pilot disableAI "FSM";};
if (_normalisedType == "GETOUT") then {_helicopter engineOn false;};

while {!_release} do {
    if (!alive _helicopter || {!local _helicopter}) exitWith {
        _release = true;
        _releaseReason = "LOCALITY_OR_DESTRUCTION";
    };
    if (_anchorPosition distance2D (getPosASL _helicopter) > 5) exitWith {
        _release = true;
        _releaseReason = "EXTERNAL_REPOSITION";
    };
    _anchorPosition = getPosASL _helicopter;

    if (isTouchingGround _helicopter || {((getPosATL _helicopter) select 2) <= 1.5}) then {
        _helicopter addForce [(vectorUp _helicopter) vectorMultiply (-0.5 * _mass), getCenterOfMass _helicopter];
    };

    if (diag_tickTime >= _nextValidation) then {
        _nextValidation = diag_tickTime + 0.25;
        _pilot = currentPilot _helicopter;
        private _pilotAwake = if (isNull _pilot) then {false} else {
            if (!isNil "ace_common_fnc_isAwake") then {[_pilot] call ace_common_fnc_isAwake} else {lifeState _pilot != "INCAPACITATED"}
        };
        if (
            !(missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_Enable", true])
            || {_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_Exclude", false]}
            || {isNull _pilot}
            || {!alive _pilot}
            || {!_pilotAwake}
            || {isPlayer _pilot}
            || {!isNull (remoteControlled _pilot)}
        ) then {
            _release = true;
            _releaseReason = "CONTROL_OR_FEATURE_CHANGE";
        } else {
            private _waypoints = waypoints _group;
            private _waypointCount = count _waypoints;
            if (_waypointCount < _expectedWaypointCount || {_expectedWaypoint < 0} || {_expectedWaypoint >= _waypointCount}) then {
                _release = true;
                _releaseReason = "LANDING_WAYPOINT_DELETED";
            } else {
                private _landingWaypoint = [_group, _expectedWaypoint];
                private _liveType = toUpperANSI (waypointType _landingWaypoint);
                private _liveScript = toLowerANSI (waypointScript _landingWaypoint);
                if (
                    (waypointPosition _landingWaypoint) distance2D _targetPosition > 0.5
                    || {_liveType != _normalisedType}
                    || {_normalisedType == "SCRIPTED" && {_liveScript != _normalisedScript}}
                ) then {
                    _release = true;
                    _releaseReason = "LANDING_WAYPOINT_EDITED";
                } else {
                    private _currentIndex = currentWaypoint _group;
                    if (
                        diag_tickTime >= _settleUntil
                        && {_currentIndex >= 0}
                        && {_currentIndex < _waypointCount}
                        && {_currentIndex != _expectedWaypoint}
                        && {(waypointPosition [_group, _currentIndex]) distance2D _targetPosition > 25}
                    ) then {
                        _release = true;
                        _releaseReason = "ONWARD_WAYPOINT";
                    };
                };
            };
        };
    };
    uiSleep 0.05;
};

if (!isNull _helicopter && {local _helicopter}) then {
    [_helicopter, false, ""] call Waldo_fnc_ImprovedHelicopterLandingRestoreLocal;
    _helicopter setVariable ["Waldo_ImprovedHelicopterLanding_LastResult", ["RELEASED", _targetPosition, diag_tickTime, _releaseReason, (getPosATL _helicopter) select 2], true];
    diag_log format ["[WMP AI LANDING] Ground anchor released helicopter=%1 reason=%2", netId _helicopter, _releaseReason];
};
true
