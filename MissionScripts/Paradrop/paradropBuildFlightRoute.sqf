/*
 * Author: WaldoTheWarfighter
 * Builds one reliable AI paradrop flight route (standby, green line, red line, exit) around an
 * existing aircraft and flight group, and configures the group/aircraft to actually fly it cleanly.
 *
 * This is the exact route/behaviour logic proven by Waldo_fnc_ParadropCreateDropZone (Dynamic Drop
 * Zone Operations), extracted so it can be shared by any caller instead of re-implemented per
 * feature: getting an AI-flown paradrop aircraft to hold altitude, speed and a clean line to the
 * drop point reliably is the hard part mission makers otherwise re-solve by hand with Eden
 * waypoints. Both the ZEN-driven Dynamic Drop Zone system and the simpler
 * Waldo_fnc_ParadropQuickFlightSetup entry point (for an aircraft a mission maker already placed
 * and crewed in Eden) call this same function, so a route-quality fix here benefits both paths.
 *
 * The aircraft's current flight group has every existing waypoint deleted before the new route is
 * added. This is deliberate: an Eden-placed aircraft's own default waypoints are the single most
 * common reason a "should be simple" paradrop setup misbehaves - the new scripted route and any
 * leftover manual waypoint silently fight each other for the AI's attention. Callers that want to
 * keep their own waypoints should not call this function.
 *
 * Arguments:
 * 0: aircraft <OBJECT> - must already exist, be crewed (a driver present) and be in the air or able
 *    to become airborne; this function does not create, position or crew the aircraft.
 * 1: flight group <GROUP> - the aircraft's pilot's group; waypoints are added to this group.
 * 2: centre <ARRAY> - drop point position (2 or 3 element ATL-ish position; Z is normalised to
 *    altitude below).
 * 3: direction <NUMBER> - degrees; the aircraft approaches centre flying along this heading.
 * 4: altitude <NUMBER> - route altitude AGL in metres (default 250, clamped 100-2000).
 * 5: maximum speed <NUMBER> - km/h (default 220, clamped 80-500).
 * 6: approach distance <NUMBER> - metres from standby to the spawn/rejoin point (default 2500).
 * 7: run length <NUMBER> - metres of the green-to-red jump run (default 2500).
 * 8: exit distance <NUMBER> - metres flown past the red line before turning off (default 2500).
 * 9: lifecycle <STRING> - LOOP (fly a re-alignment circuit and repeat), RETAIN (loiter near exit
 *    after one pass) or DESPAWN (fly off and stop; caller handles cleanup) (default LOOP).
 * 10: circuit direction <STRING> - LEFT or RIGHT, which way the LOOP circuit turns (default LEFT).
 *
 * Return Value:
 * HashMap - key positions for the caller (standby, green, centre, red, spawn, exit, hold), each a
 * 3D position with Z set to the route altitude, plus the actual clamped "altitude" and "maxSpeed"
 * this route was built with (clamping happens inside this function - callers that need to reason
 * about the aircraft's real flight envelope, e.g. to normalize a jump envelope against it, must read
 * these back rather than reusing their own unclamped input values). Empty HashMap when the
 * aircraft/group is invalid.
 *
 * Example:
 * [_aircraft, _flightGroup, getMarkerPos "dz1", 45, 250, 220, 2500, 2500, 2500, "LOOP", "LEFT"]
 *     call Waldo_fnc_ParadropBuildFlightRoute;
 *
 * Current callers: Waldo_fnc_ParadropCreateDropZone, Waldo_fnc_ParadropQuickFlightSetup.
 */

params [
    ["_aircraft", objNull, [objNull]],
    ["_flightGroup", grpNull, [grpNull]],
    ["_centre", [], [[]]],
    ["_direction", 0, [0]],
    ["_altitude", 250, [0]],
    ["_maxSpeed", 220, [0]],
    ["_approach", 2500, [0]],
    ["_runLength", 2500, [0]],
    ["_exitDistance", 2500, [0]],
    ["_lifecycle", "LOOP", [""]],
    ["_circuitDirection", "LEFT", [""]]
];
if (!isServer || {isNull _aircraft} || {isNull _flightGroup} || {count _centre < 2}) exitWith {createHashMap};

_direction = _direction mod 360;
_altitude = (_altitude max 100) min 2000;
_maxSpeed = (_maxSpeed max 80) min 500;
_approach = (_approach max 800) min 10000;
_runLength = (_runLength max 300) min 6000;
_exitDistance = (_exitDistance max 800) min 10000;
_lifecycle = toUpperANSI _lifecycle;
if !(_lifecycle in ["LOOP", "RETAIN", "DESPAWN"]) then {_lifecycle = "LOOP"};
_circuitDirection = toUpperANSI _circuitDirection;
private _circuitTurn = if (_circuitDirection == "RIGHT") then {90} else {-90};

private _standby = [_centre, _runLength * 0.65, _direction + 180] call BIS_fnc_relPos;
private _green = [_centre, _runLength * 0.5, _direction + 180] call BIS_fnc_relPos;
private _red = [_centre, _runLength * 0.5, _direction] call BIS_fnc_relPos;
private _spawn = [_standby, _approach, _direction + 180] call BIS_fnc_relPos;
private _exit = [_red, _exitDistance, _direction] call BIS_fnc_relPos;
private _circuitWidth = ((_approach max _runLength) * 0.75) max 1200;
private _crosswind = [_exit, _circuitWidth, _direction + _circuitTurn] call BIS_fnc_relPos;
private _downwind = [_spawn, _circuitWidth, _direction + _circuitTurn] call BIS_fnc_relPos;
private _rejoin = [_spawn, _approach * 0.6, _direction + 180] call BIS_fnc_relPos;
private _hold = [_exit, 1800, _direction] call BIS_fnc_relPos;
{_x set [2, _altitude]} forEach [_standby, _green, _centre, _red, _spawn, _exit, _crosswind, _downwind, _rejoin, _hold];

{deleteWaypoint _x} forEach (reverse (waypoints _flightGroup));
_flightGroup setBehaviourStrong "CARELESS";
_flightGroup setCombatMode "BLUE";
_flightGroup setSpeedMode "LIMITED";
_aircraft flyInHeight [_altitude, true];
_aircraft limitSpeed _maxSpeed;
// limitSpeed is km/h, while forceSpeed is metres/second. Applying one raw value to both causes
// extreme overspeed and an apparent lateral break at the drop zone - the exact failure mode that
// made ad hoc paradrop aircraft setups unreliable before this route builder existed.
_aircraft forceSpeed (_maxSpeed / 3.6);
_aircraft engineOn true;

private _addRouteWaypoint = {
    params ["_position", ["_type", "MOVE"], ["_radius", 40]];
    // A negative placement radius consumes ASL and creates an exact waypoint. Radius zero may be
    // displaced by nearby terrain objects, which is unacceptable on a marked jump run.
    private _waypoint = _flightGroup addWaypoint [AGLToASL _position, -1];
    _waypoint setWaypointType _type;
    _waypoint setWaypointBehaviour "CARELESS";
    _waypoint setWaypointCombatMode "BLUE";
    _waypoint setWaypointSpeed "LIMITED";
    _waypoint setWaypointCompletionRadius _radius;
    _waypoint
};
{
    [_x, "MOVE", if (_forEachIndex in [1, 2, 3]) then {30} else {100}] call _addRouteWaypoint;
} forEach [_standby, _green, _centre, _red, _exit];
if (_lifecycle == "LOOP") then {
    {[_x, "MOVE", 180] call _addRouteWaypoint} forEach [_crosswind, _downwind, _rejoin];
    [_spawn, "CYCLE", 120] call _addRouteWaypoint;
};
if (_lifecycle == "RETAIN") then {
    private _loiter = [_hold, "LOITER", 250] call _addRouteWaypoint;
    _loiter setWaypointLoiterRadius 900;
    _loiter setWaypointLoiterType "CIRCLE_L";
};

createHashMapFromArray [
    ["standby", _standby], ["green", _green], ["centre", _centre], ["red", _red],
    ["spawn", _spawn], ["exit", _exit], ["hold", _hold],
    ["altitude", _altitude], ["maxSpeed", _maxSpeed]
]
