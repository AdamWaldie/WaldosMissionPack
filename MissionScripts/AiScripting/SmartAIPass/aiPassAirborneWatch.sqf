/*
 * Author: WaldoTheWarfighter
 * Watches the jumpers of an airborne reinforcement and releases them to fight once they have landed.
 *
 * Paradrop marks generated jumpers as server-owned feature units, which keeps every WMP AI system
 * away from them during the flight. When every surviving jumper is out of the aircraft and on the
 * ground, or the deadline passes, this clears Waldo_ServerOwnedFeature, the headless pin and the ACE
 * Headless blacklist from the squad, gives it a SEEK AND DESTROY waypoint at the target and sets it
 * to AWARE and open fire. From then on it is an ordinary AI squad: the Smart AI Pass manages it and
 * headless clients may take it.
 * Jumpers the paradrop system has already deleted (retained past the red line) are ignored.
 * Locality and authority: server scheduler job.
 *
 * Arguments:
 * 0: job <HASHMAP> - id, target and deadline
 *
 * Return Value:
 * Number - seconds until the next check, or -1 when finished
 *
 * Example:
 * [Waldo_fnc_AIPassAirborneWatch, createHashMapFromArray [["id", _id], ["target", _pos], ["deadline", time + 900]], 10] call Waldo_fnc_AIPassQueueJob;
 * Result: landed paratroopers move out to attack the target.
 *
 * Current caller: Waldo_fnc_AIPassAirborneRequest.
 */

params [["_job", createHashMap, [createHashMap]]];
private _entry = (missionNamespace getVariable ["Waldo_Paradrop_DropZones", createHashMap]) getOrDefault [_job get "id", createHashMap];
private _group = _entry getOrDefault ["jumpGroup", _job getOrDefault ["group", grpNull]];
_job set ["group", _group];
if (isNull _group) exitWith {if (time > (_job get "deadline")) then {-1} else {10}};
private _jumpers = (units _group) select {alive _x};
if (_jumpers isEqualTo []) exitWith {-1};
private _landed = _jumpers findIf {vehicle _x != _x || {!isTouchingGround _x && {((getPosATL _x) select 2) > 2}}} < 0;
if (!_landed && {time < (_job get "deadline")}) exitWith {5};
_group setVariable ["Waldo_ServerOwnedFeature", false, true];
_group setVariable ["Waldo_Headless_ExcludeGroup", false, true];
{
    _x setVariable ["Waldo_ServerOwnedFeature", false, true];
    _x setVariable ["acex_headless_blacklist", false, true];
} forEach _jumpers;
private _waypoint = _group addWaypoint [_job get "target", 20];
_waypoint setWaypointType "SAD";
_group setCurrentWaypoint _waypoint;
_group setBehaviour "AWARE";
_group setCombatMode "RED";
diag_log format ["[WMP AI PASS] Airborne reinforcement %1 landed and released (%2 jumpers).", _job get "id", count _jumpers];
-1
