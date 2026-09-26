/*
 * Author: WaldoTheWarfighter
 * Airborne insertion: decides when an AI squad riding as cargo in an AI-flown aircraft parachutes
 * onto a known enemy, and starts the drop.
 *
 * It acts on aircraft the mission maker (or Zeus) already put in
 * the air with AI passengers; nothing is spawned. Its faults are not repeated: the aircraft check
 * works, only hostile sides count (civilians never trigger a drop), soldiers keep their own
 * backpacks (each gets a parachute of his own, Waldo_fnc_AIPassParachuteJump), and it runs inside the
 * pass's budgeted scheduler on the machine that owns the squad instead of a loop on every machine.
 * The squad's own knowledge decides (Waldo_fnc_AIPassKnowledge); nothing is revealed to it.
 * - Within Waldo_AIPass_Airborne_ApproachDistance of the nearest known enemy the aircraft climbs to
 *   Waldo_AIPass_Airborne_Altitude (flyInHeight, when this machine owns the aircraft).
 * - Within Waldo_AIPass_Airborne_DeployDistance, with the aircraft at least
 *   Waldo_AIPass_Airborne_MinAltitude above ground and not over water, the drop starts
 *   (Waldo_fnc_AIPassAirborneDropStep).
 * Passengers are the cargo seats and the person-turret (FFV) seats many helicopters use for troops;
 * crew never jump. Never drops from an aircraft flown or commanded by a player, while an unload or
 * get-out waypoint is still ahead for the pilots or the squad (the mission maker planned a landing;
 * the aircraft is not climbed either), or from aircraft owned by another WMP feature (the squad
 * would already be ineligible: Transport Services, Paradrop, Gunship). The aircraft keeps the jump
 * altitude afterwards; give it a new flyInHeight in a later waypoint if it should fly lower.
 * Locality and authority: call where the group is local.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP> - from Waldo_fnc_AIPassGroupState
 * 2: force <BOOL> (optional, default: false) - drop now whatever the enemy distance or planned
 *    landing (Zeus and Waldo_fnc_AIPassAirborneDrop); altitude, water and AI pilots are still checked
 *
 * Return Value:
 * Number - -1 when the squad is not riding an aircraft (the group tick continues normally), otherwise
 * the seconds until the group tick should run again. With force, 0 means the drop started.
 *
 * Example:
 * private _delay = [_group, _state] call Waldo_fnc_AIPassAirborneCheck;
 * Result: a squad in a helicopter jumps when its helicopter comes within 700 m of a known enemy.
 *
 * Current callers: Waldo_fnc_AIPassGroupTick and Waldo_fnc_AIPassAirborneDrop.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_force", false, [false]]];
if (!_force && {!(missionNamespace getVariable ["Waldo_AIPass_Airborne_Enable", false])}) exitWith {-1};
// Passengers: cargo seats and the person-turret (FFV) seats many helicopters use for troops. Crew
// (pilots, gunners, commanders) never counts.
private _passengersOf = {
    params ["_vehicle"];
    ((fullCrew [_vehicle, "cargo"]) + ((fullCrew [_vehicle, "turret"]) select {_x select 4})) apply {_x select 0}
};
private _riding = (units _group) select {
    alive _x && {local _x} && {!isPlayer _x} && {(vehicle _x) isKindOf "Air"} && {!((vehicle _x) isKindOf "ParachuteBase")}
};
if (_riding isEqualTo []) exitWith {-1};
private _aircraft = vehicle (_riding select 0);
private _passengers = [_aircraft] call _passengersOf;
private _cargo = _riding select {vehicle _x == _aircraft && {_x in _passengers}};
if (_cargo isEqualTo []) exitWith {-1};

private _pilot = driver _aircraft;
if (!alive _aircraft || {!alive _pilot} || {isPlayer _pilot} || {isPlayer effectiveCommander _aircraft}) exitWith {[5, -1] select _force};
if (time < (_aircraft getVariable ["Waldo_AIPass_DropUntil", -1])) exitWith {[5, -1] select _force};
// The mission maker planned a landing: an unload or get-out still ahead on the pilots' or the squad's
// own waypoints. Zeus and scripted drops (force) are deliberate and override it.
private _plannedLanding = {
    params ["_waypointGroup"];
    private _found = false;
    for "_index" from (currentWaypoint _waypointGroup) to ((count waypoints _waypointGroup) - 1) do {
        if (waypointType [_waypointGroup, _index] in ["TR UNLOAD", "UNLOAD", "GETOUT"]) exitWith {_found = true};
    };
    _found
};
if (!_force && {[group _pilot] call _plannedLanding || {[_group] call _plannedLanding}}) exitWith {10};

private _target = getPosATL _aircraft;
if (!_force) then {
    private _approach = missionNamespace getVariable ["Waldo_AIPass_Airborne_ApproachDistance", 2000];
    private _enemies = ([_group, _approach] call Waldo_fnc_AIPassKnowledge) select 0;
    _target = if (_enemies isEqualTo []) then {[]} else {(_enemies select 0) select 1};
};
if (_target isEqualTo []) exitWith {10};
private _distance = _aircraft distance2D _target;
if (!_force && {local _aircraft} && {!(_aircraft getVariable ["Waldo_AIPass_AirborneClimb", false])}) then {
    _aircraft setVariable ["Waldo_AIPass_AirborneClimb", true];
    _aircraft flyInHeight (missionNamespace getVariable ["Waldo_AIPass_Airborne_Altitude", 250]);
};
private _height = (getPos _aircraft) select 2;
private _ready = (_force || {_distance <= (missionNamespace getVariable ["Waldo_AIPass_Airborne_DeployDistance", 700])})
    && {_height >= (missionNamespace getVariable ["Waldo_AIPass_Airborne_MinAltitude", 120])}
    && {!surfaceIsWater getPos _aircraft};
if (!_ready) exitWith {[[5, 2] select (_distance < 1200), -1] select _force};

_aircraft setVariable ["Waldo_AIPass_DropUntil", time + 30 + count _cargo * 3];
_group setVariable ["Waldo_AIPass_Dropping", true];
[Waldo_fnc_AIPassAirborneDropStep, createHashMapFromArray [
    ["group", _group], ["aircraft", _aircraft], ["jumpers", _cargo], ["index", 0], ["phase", "DROP"],
    ["target", _target], ["deadline", time + 180]
], 0] call Waldo_fnc_AIPassQueueJob;
diag_log format ["[WMP AI PASS] %1 airborne insertion from %2 (%3 jumpers, %4 m from target, forced=%5).",
    _group, typeOf _aircraft, count _cargo, round _distance, _force];
[3, 0] select _force
