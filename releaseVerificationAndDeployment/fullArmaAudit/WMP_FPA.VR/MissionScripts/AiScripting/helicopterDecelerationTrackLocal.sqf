/*
 * Author: WaldoTheWarfighter
 * Samples one local AI helicopter and starts a bounded correction when Arma's braking behaviour is
 * simultaneously losing forward speed, gaining altitude and pitching up. It never operates near
 * terrain, on player/UAV/remote-controlled aircraft, or while a supported landing order exists.
 *
 * Locality/authority: scheduled on the aircraft owner only. The loop ends when locality moves and
 * the Local handler installs a fresh tracker on the new owner. Public state is diagnostics only.
 *
 * Arguments:
 * 0: aircraft <OBJECT> - local AI helicopter (or VTOL when explicitly enabled).
 * Return Value: Nothing (scheduled tracker lifecycle).
 *
 * Example: [_helicopter] spawn Waldo_fnc_HelicopterDecelerationTrackLocal;
 * Current callers: Waldo_fnc_HelicopterDecelerationInit and its aircraft Local event handler.
 */

params [["_aircraft", objNull, [objNull]]];
if (isNull _aircraft) exitWith {};

private _isLandingOrder = {
    params ["_vehicle"];
    private _pilot = currentPilot _vehicle;
    if (isNull _pilot) exitWith {false};
    private _group = group _pilot;
    private _index = currentWaypoint _group;
    private _waypoints = waypoints _group;
    if (_index < 0 || {_index >= count _waypoints}) exitWith {false};
    private _waypoint = [_group, _index];
    private _type = toUpperANSI (waypointType _waypoint);
    private _script = toLowerANSI (waypointScript _waypoint);
    _type in ["LAND", "UNLOAD", "TR UNLOAD", "GETOUT"]
        || {_type == "SCRIPTED" && {_script find "land" >= 0}}
        || {
            _type == "MOVE"
            && {_vehicle getVariable ["Waldo_TransportService_Registered", false]}
            && {_vehicle getVariable ["Waldo_TransportService_State", ""] == "TO_DESTINATION"}
        }
};
private _sampleInterval = (missionNamespace getVariable ["Waldo_HelicopterDeceleration_SampleInterval", 0.5]) max 0.1;
private _lastSpeed = abs speed _aircraft;
private _lastAltitude = (getPosASL _aircraft) select 2;

while {alive _aircraft && {local _aircraft}} do {
    uiSleep _sampleInterval;
    private _speed = abs speed _aircraft;
    private _altitudeASL = (getPosASL _aircraft) select 2;
    private _altitudeAGL = (getPosATL _aircraft) select 2;
    private _pilot = currentPilot _aircraft;
    private _pilotAwake = if (isNull _pilot) then {false} else {
        if (!isNil "ace_common_fnc_isAwake") then {[_pilot] call ace_common_fnc_isAwake} else {lifeState _pilot != "INCAPACITATED"}
    };
    private _eligible = missionNamespace getVariable ["Waldo_HelicopterDeceleration_Enable", false]
        && {!(_aircraft getVariable ["Waldo_HelicopterDeceleration_Exclude", false])}
        && {!(_aircraft getVariable ["Waldo_HelicopterDeceleration_Active", false])}
        && {!(_aircraft getVariable ["Waldo_ImprovedHelicopterLanding_Active", false])}
        && {!([_aircraft] call _isLandingOrder)}
        && {!isNull _pilot}
        && {alive _pilot}
        && {_pilotAwake}
        && {!isPlayer _pilot}
        && {isNull (remoteControlled _pilot)}
        && {isEngineOn _aircraft}
        && {canMove _aircraft}
        && {fuel _aircraft > 0}
        && {!isTouchingGround _aircraft}
        && {isNull (getSlingLoad _aircraft)};
    if (_eligible) then {
        private _speedLoss = _lastSpeed - _speed;
        private _altitudeGain = _altitudeASL - _lastAltitude;
        if (
            _speed >= (missionNamespace getVariable ["Waldo_HelicopterDeceleration_MinimumSpeed", 80])
            && {_altitudeAGL >= (missionNamespace getVariable ["Waldo_HelicopterDeceleration_MinimumAltitude", 25])}
            && {_speedLoss >= (missionNamespace getVariable ["Waldo_HelicopterDeceleration_MinimumSpeedLoss", 4])}
            && {_altitudeGain >= (missionNamespace getVariable ["Waldo_HelicopterDeceleration_MinimumAltitudeGain", 0.5])}
            && {(vectorDir _aircraft select 2) >= (missionNamespace getVariable ["Waldo_HelicopterDeceleration_MinimumNoseUp", 0.02])}
        ) then {
            [_aircraft, _speed, _altitudeASL, _isLandingOrder] spawn Waldo_fnc_HelicopterDecelerationCorrectLocal;
        };
    };
    _lastSpeed = _speed;
    _lastAltitude = _altitudeASL;
};

if (!isNull _aircraft) then {
    _aircraft setVariable ["Waldo_HelicopterDeceleration_TrackedLocal", false];
    _aircraft setVariable ["Waldo_HelicopterDeceleration_Active", false, true];
};
