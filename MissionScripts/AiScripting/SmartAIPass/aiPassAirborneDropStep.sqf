/*
 * Author: WaldoTheWarfighter
 * Runs one airborne insertion started by Waldo_fnc_AIPassAirborneCheck: soldiers jump one at a time,
 * then the squad is sent to fight once it is on the ground.
 *
 * DROP: every Waldo_AIPass_Airborne_JumpInterval seconds the next soldier still aboard jumps
 * (Waldo_fnc_AIPassParachuteJump). The drop pauses while the aircraft is below
 * Waldo_AIPass_Airborne_MinAltitude or over water, and stops if the aircraft is lost or Zeus takes
 * the squad; anyone still aboard then stays with the aircraft.
 * LAND: once every living member of the squad is on the ground (or 180 s after the start), the squad
 * returns to normal pass management. If it has no waypoints of its own left, it gets a SAD waypoint
 * on the enemy position that triggered the drop, so it goes and fights rather than standing where it
 * landed.
 * Locality and authority: runs where the group is local; only local soldiers jump.
 *
 * Arguments:
 * 0: job state <HASHMAP> - group, aircraft, jumpers, index, phase, target, deadline
 *
 * Return Value:
 * Number - seconds until the next step, or -1 when finished
 *
 * Example:
 * [Waldo_fnc_AIPassAirborneDropStep, _job, 0] call Waldo_fnc_AIPassQueueJob;
 * Result: the squad parachutes out one soldier at a time.
 *
 * Current caller: Waldo_fnc_AIPassAirborneCheck (through the scheduler).
 */

params [["_job", createHashMap, [createHashMap]]];
private _group = _job getOrDefault ["group", grpNull];
private _aircraft = _job getOrDefault ["aircraft", objNull];
private _finish = {
    if (!isNull _group) then {_group setVariable ["Waldo_AIPass_Dropping", nil]};
    if (!isNull _aircraft) then {_aircraft setVariable ["Waldo_AIPass_DropUntil", nil]};
    -1
};
if (isNull _group || {!local _group}) exitWith {call _finish};

if ((_job get "phase") == "DROP") exitWith {
    private _jumpers = (_job get "jumpers") select {alive _x && {local _x} && {vehicle _x == _aircraft}};
    if (_jumpers isEqualTo [] || {!alive _aircraft}) exitWith {
        _job set ["phase", "LAND"];
        3
    };
    // Zeus has priority: stop the drop; anyone still aboard stays with the aircraft.
    if (time > (_job get "deadline") || {[_group] call Waldo_fnc_AIPassZeusHeld}) exitWith {call _finish};
    if (((getPos _aircraft) select 2) < (missionNamespace getVariable ["Waldo_AIPass_Airborne_MinAltitude", 120])
        || {surfaceIsWater getPos _aircraft}) exitWith {1};
    [_jumpers select 0, _aircraft] call Waldo_fnc_AIPassParachuteJump;
    _aircraft setVariable ["Waldo_AIPass_DropUntil", time + 30];
    (missionNamespace getVariable ["Waldo_AIPass_Airborne_JumpInterval", 1]) max 0.5
};

// LAND
private _alive = (units _group) select {alive _x};
private _landed = _alive findIf {vehicle _x != _x || {!isTouchingGround _x && {((getPosATL _x) select 2) > 2}}} < 0;
if (!_landed && {time < (_job get "deadline")}) exitWith {3};
if (_alive isNotEqualTo [] && {currentWaypoint _group >= count waypoints _group}) then {
    private _waypoint = _group addWaypoint [_job get "target", 30];
    _waypoint setWaypointType "SAD";
    _group setCurrentWaypoint _waypoint;
};
missionNamespace setVariable ["Waldo_AIPass_AirborneDrops", (missionNamespace getVariable ["Waldo_AIPass_AirborneDrops", 0]) + 1];
diag_log format ["[WMP AI PASS] %1 airborne insertion complete (%2 on the ground).", _group, count _alive];
call _finish
