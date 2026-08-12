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
 * Locality and authority: Run where the pilot group is local, normally the server for WMP-created
 * operations. The caller must remote the request if the pilot group moves to a headless client.
 *
 * Arguments:
 * 0: aircraft <OBJECT> - must already exist, be crewed (a driver present) and be in the air or able
 *    to become airborne; this function does not create, position or crew the aircraft.
 * 1: flight group <GROUP> - the aircraft's pilot's group; waypoints are added to this group.
 * 2: centre <ARRAY> - drop point position (2 or 3 element ATL-ish position; Z is normalised to
 *    altitude below).
 * 3: direction <NUMBER> - degrees; the aircraft approaches centre flying along this heading.
 * 4: altitude <NUMBER> - route altitude AGL in metres (default 300, clamped 100-2000).
 * 5: maximum speed <NUMBER> - km/h (default 300, clamped 80-500).
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
 * Result: A valid group receives the complete route and the caller receives its normalized geometry.
 *
 * Example:
 * [_aircraft, _flightGroup, getMarkerPos "dz1", 45, 300, 300, 2500, 2500, 2500, "LOOP", "LEFT"]
 *     call Waldo_fnc_ParadropBuildFlightRoute;
 *
 * Current callers: Waldo_fnc_ParadropCreateDropZone, Waldo_fnc_ParadropQuickFlightSetup.
 */

params [
    ["_aircraft", objNull, [objNull]],
    ["_flightGroup", grpNull, [grpNull]],
    ["_centre", [], [[]]],
    ["_direction", 0, [0]],
    ["_altitude", 300, [0]],
    ["_maxSpeed", 300, [0]],
    ["_approach", 2500, [0]],
    ["_runLength", 2500, [0]],
    ["_exitDistance", 2500, [0]],
    ["_lifecycle", "LOOP", [""]],
    ["_circuitDirection", "LEFT", [""]]
];
if (!isServer || {isNull _aircraft} || {isNull _flightGroup} || {count _centre < 2}) exitWith {createHashMap};

// This route is actively driven by a continuous server-spawned watcher below (the LOOP restart guard)
// and depends on the aircraft/group staying local to whichever machine is running it - an external
// headless rebalance (WMP's own, or ACE's separate ace_headless module) moving this group mid-flight
// would desynchronise that watcher. Pin server-side by default; see headlessPinCrew.sqf for detail.
[_aircraft] call Waldo_fnc_HeadlessPinCrew;

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
_aircraft limitSpeed _maxSpeed;
// limitSpeed is km/h, while forceSpeed is metres/second. Applying one raw value to both causes
// extreme overspeed and an apparent lateral break at the drop zone.
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
// The green/centre/red run-line waypoints are deliberately tighter than standby/exit to keep the
// jump line geometrically precise, but too tight for a fast aircraft's turning radius is a known
// Arma AI failure mode: it can perpetually fail to satisfy the completion radius and circle trying,
// rather than actually breaking off toward the next waypoint - which reads exactly as "only one
// pass, then loitering" instead of continuing the loop. 50 m still keeps the line tight relative to
// the run length while giving faster-than-default aircraft (missions commonly configure well above
// the 300 km/h default) real room to satisfy it.
// _standby is added on its own, and its real [group, index] return value is kept, rather than
// assuming it lands at waypoint index 0 alongside the rest in one forEach: a freshly createGroup'd
// flight group (Waldo_fnc_ParadropCreateDropZone's own dedicated pilot group) can carry an implicit
// phantom index 0 at the group's [0,0,0] creation position that `waypoints _flightGroup` does not
// enumerate and the deleteWaypoint loop above therefore never touches - silently pushing every
// scripted waypoint one index late. Addressing the LOOP restart by this captured reference instead
// of a hardcoded index 0 is correct regardless of whether that phantom waypoint exists.
private _standbyWaypoint = [_standby, "MOVE", 100] call _addRouteWaypoint;
{
    [_x, "MOVE", if (_forEachIndex in [0, 1, 2]) then {50} else {100}] call _addRouteWaypoint;
} forEach [_green, _centre, _red, _exit];
if (_lifecycle == "LOOP") then {
    {[_x, "MOVE", 180] call _addRouteWaypoint} forEach [_crosswind, _downwind, _rejoin, _spawn];
    // Arma's native "CYCLE" waypoint type does not reliably resume at waypoint index 0 - the engine
    // resumes at whichever waypoint in the group's list is geometrically nearest to the cycle
    // waypoint's own position. For this route's shape that is "rejoin" (~_approach*0.6 away), not
    // "standby" (a full _approach away by design) - so a native CYCLE waypoint here collapses the
    // loop into a tight rejoin<->spawn shuttle after the very first pass instead of re-flying the
    // marked standby->green->red->exit line, and anything anchored to that flight (drop timing, a
    // mission maker's own per-pass marker/trigger logic) ends up scattered relative to where the
    // first clean pass put it. Force a deterministic restart at standby's own captured [group, index]
    // instead of trusting that engine heuristic or assuming standby landed at index 0 (see the
    // comment above _standbyWaypoint's assignment for why that assumption previously sent the
    // aircraft back to a phantom [0,0,0] waypoint instead - "no looping" and "waypoints at 0,0" were
    // the exact symptom this produced).
    // This function clears and rebuilds the group's whole waypoint list on every call (see the file
    // header), so a stray second call against the same still-flying group (both callers already
    // guard against that themselves, but this loop must not assume it will always be true) must not
    // stack a second copy of this watcher on top of the first.
    if !(_flightGroup getVariable ["Waldo_Paradrop_CycleGuardStarted", false]) then {
        _flightGroup setVariable ["Waldo_Paradrop_CycleGuardStarted", true];
        [_flightGroup, _spawn, _standbyWaypoint] spawn {
            params ["_flightGroup", "_spawn", "_standbyWaypoint"];
            while {!isNull _flightGroup && {count units _flightGroup > 0}} do {
                waitUntil {
                    sleep 1;
                    isNull _flightGroup
                    || {count units _flightGroup == 0}
                    || {!alive leader _flightGroup}
                    || {(leader _flightGroup) distance2D _spawn < 150}
                };
                if (isNull _flightGroup || {count units _flightGroup == 0} || {!alive leader _flightGroup}) exitWith {};
                _flightGroup setCurrentWaypoint _standbyWaypoint;
                sleep 5; // clear the spawn radius before re-arming so this doesn't refire mid-restart.
            };
        };
    };
};
if (_lifecycle == "RETAIN") then {
    private _loiter = [_hold, "LOITER", 250] call _addRouteWaypoint;
    _loiter setWaypointLoiterRadius 900;
    _loiter setWaypointLoiterType "CIRCLE_L";
};

// Select the first real route waypoint explicitly. Newly created groups can retain an implicit
// creation waypoint even though it is not returned by `waypoints`, leaving the aircraft flying its
// default state instead of this route. Apply flyInHeight last as well: enabling simulation or
// activating the first waypoint after an earlier altitude order can make a freshly spawned plane
// settle back to Arma's default ~100 m flight height. Use the scalar form used by ZEN's proven Fly
// Height module: the documented forced-array form is not retained by the Passenger Blackfish in
// this dynamic creation lifecycle. The caller may still have simulation disabled while this route
// is assembled; the order persists and the dynamic-spawn caller repeats it once the aircraft is live.
_flightGroup setCurrentWaypoint _standbyWaypoint;
_aircraft flyInHeight _altitude;

createHashMapFromArray [
    ["standby", _standby], ["green", _green], ["centre", _centre], ["red", _red],
    ["spawn", _spawn], ["exit", _exit], ["hold", _hold],
    ["altitude", _altitude], ["maxSpeed", _maxSpeed]
]
