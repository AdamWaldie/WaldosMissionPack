/*
 * Author: Waldo
 * Scrambles the configured fighter response for one Dynamic AA system once per activation.
 *
 * Arguments:
 * 0: id <STRING>
 * 1: detectedAircraft <ARRAY> - current hostile targets
 *
 * Return Value:
 * Number - fighters spawned
 *
 * Example:
 * ["north_sector", _targets] call Waldo_fnc_DynamicAASpawnFighters;
 */

params ["_id", ["_detectedAircraft", [], [[]]]];
if !(isServer) exitWith {0};
private _registry = missionNamespace getVariable ["Waldo_DynamicAA_Registry", createHashMap];
if !(_id in (keys _registry)) exitWith {0};
private _state = _registry get _id;
private _config = _state get "config";
private _count = (_config getOrDefault ["fighterCount", 0]) max 0;
private _centre = _config get "centre";
private _radius = _config get "radius";
private _side = _config get "side";
private _fighterClasses = _config getOrDefault ["fighterClasses", [_config getOrDefault ["fighterClass", "O_Plane_Fighter_02_F"]]];

for "_i" from 1 to _count do {
    private _fighterClass = selectRandom _fighterClasses;
    private _spawn2D = _centre getPos [_radius * (_config getOrDefault ["fighterSpawnRangeMultiplier", 2]), random 360];
    private _height = (_config getOrDefault ["fighterSpawnAltitude", 1000]) + ((_i - 1) * 40);
    private _spawnPosition = [_spawn2D select 0, _spawn2D select 1, _height];
    private _fighter = createVehicle [_fighterClass, _spawnPosition, [], 0, "FLY"];
    _fighter setPosATL _spawnPosition;
    _fighter setDir (_spawn2D getDir _centre);
    _fighter flyInHeight _height;
    createVehicleCrew _fighter;
    private _oldGroups = [];
    {_oldGroups pushBackUnique (group _x)} forEach crew _fighter;
    private _group = createGroup _side;
    (crew _fighter) joinSilent _group;
    {if (!isNull _x && {count units _x == 0}) then {deleteGroup _x}} forEach _oldGroups;
    _group setBehaviourStrong "COMBAT";
    _group setCombatMode "RED";
    {_group reveal [_x, 4]} forEach _detectedAircraft;
    private _waypoint = _group addWaypoint [_centre, 0];
    _waypoint setWaypointType "SAD";
    _waypoint setWaypointBehaviour "COMBAT";
    _waypoint setWaypointCombatMode "RED";
    _waypoint setWaypointSpeed "FULL";
    private _objects = _state get "objects";
    _objects pushBack _fighter;
    _state set ["objects", _objects];
    private _groups = _state get "groups";
    _groups pushBackUnique _group;
    _state set ["groups", _groups];
};
_state set ["fightersScrambled", true];
_state set ["fighterWaves", (_state getOrDefault ["fighterWaves", 0]) + 1];
_state set ["lastFighterScramble", diag_tickTime];
_registry set [_id, _state];
missionNamespace setVariable ["Waldo_DynamicAA_Registry", _registry];
if (_config getOrDefault ["announce", true]) then {
    ["AIR DEFENCE", format ["System %1 scrambled %2 fighter(s).", _id, _count], "WARNING", "DYNAMIC_AA"] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", 0];
};
_count
