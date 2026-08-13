/*
 * Author: WaldoTheWarfighter
 * Spawns the configured fighter response and places it under the same server detector gate as AA.
 *
 * Locality and authority:
 * Server-only creation. Crew is created directly on the configured operational side, avoiding a
 * transient config-side group during dedicated-server replication. Fighter responses remain
 * server-owned because the Dynamic AA detector continuously controls their target/fire state.
 * Fighters are published through the Dynamic AA snapshot and added to all active curators.
 * Repeated waves follow the configured wave/cooldown state.
 *
 * Arguments:
 * 0: id <STRING>
 * 1: detectedAircraft <ARRAY> - current hostile targets
 *
 * Return Value:
 * Number - fighters successfully spawned during this wave
 *
 * Current callers:
 * Waldo_fnc_DynamicAADetectorLoop when an eligible hostile aircraft activates a fighter response.
 *
 * Example:
 * ["north_sector", _targets] call Waldo_fnc_DynamicAASpawnFighters;
 * Result: the configured wave is spawned, curator-editable and governed by the same detector gate.
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
private _fighterAssignments = _config getOrDefault ["fighterAssignments", []];
private _spawnedCount = 0;

for "_i" from 1 to _count do {
    private _fighterClass = if (count _fighterAssignments == _count) then {
        _fighterAssignments select (_i - 1)
    } else {
        selectRandom _fighterClasses
    };
    private _spawn2D = _centre getPos [_radius * (_config getOrDefault ["fighterSpawnRangeMultiplier", 2]), random 360];
    private _height = (_config getOrDefault ["fighterSpawnAltitude", 1000]) + ((_i - 1) * 40);
    private _spawnPosition = [_spawn2D select 0, _spawn2D select 1, _height];
    private _fighter = createVehicle [_fighterClass, _spawnPosition, [], 0, "FLY"];
    [_fighter] call Waldo_fnc_HeadlessPinCrew;
    _fighter setVariable ["Waldo_DynamicAA_SystemId", _id, true];
    _fighter setPosATL _spawnPosition;
    _fighter setDir (_spawn2D getDir _centre);
    _fighter flyInHeight _height;
    // Use the side-aware command directly. A config-side group followed by joinSilent briefly
    // exposed the wrong/unknown side and stale crew references on dedicated servers.
    private _group = _side createVehicleCrew _fighter;
    if (isNull _group || {count crew _fighter == 0} || {side _group != _side}) then {
        diag_log format [
            "[WMP DYNAMIC AA] Fighter crew creation failed: class=%1 requestedSide=%2 group=%3 actualSide=%4 crew=%5.",
            _fighterClass, _side, _group, side _group, count crew _fighter
        ];
        {deleteVehicle _x} forEach crew _fighter;
        deleteVehicle _fighter;
    } else {
        _group addVehicle _fighter;
        [_fighter] call Waldo_fnc_HeadlessPinCrew;
        private _waypoint = _group addWaypoint [_centre, 0];
        // MOVE keeps the route useful without SAD independently selecting low aircraft or ground units.
        _waypoint setWaypointType "MOVE";
        _waypoint setWaypointBehaviour "COMBAT";
        _waypoint setWaypointCombatMode "RED";
        _waypoint setWaypointSpeed "FULL";
        [_group, true, _detectedAircraft] call Waldo_fnc_DynamicAASetGroupState;
        private _objects = _state get "objects";
        _objects pushBack _fighter;
        _state set ["objects", _objects];
        private _groups = _state get "groups";
        _groups pushBackUnique _group;
        _state set ["groups", _groups];
        private _defenceGroups = _state getOrDefault ["defenceGroups", []];
        _defenceGroups pushBackUnique _group;
        _state set ["defenceGroups", _defenceGroups];
        _spawnedCount = _spawnedCount + 1;
        [[_fighter], _group] spawn {
            params ["_assets", "_group"];
            private _deadline = diag_tickTime + 10;
            private _editable = [];
            waitUntil {
                sleep 0.1;
                _assets = _assets select {!isNull _x};
                _editable = +_assets;
                {_editable pushBackUnique _x} forEach units _group;
                ((_editable findIf {netId _x in ["", "0:0"]}) < 0) || {diag_tickTime >= _deadline}
            };
            {_x addCuratorEditableObjects [_editable, false]} forEach allCurators;
        };
    };
};
if (_spawnedCount > 0) then {
    _state set ["fightersScrambled", true];
    _state set ["fighterWaves", (_state getOrDefault ["fighterWaves", 0]) + 1];
    _state set ["lastFighterScramble", diag_tickTime];
};
_registry set [_id, _state];
missionNamespace setVariable ["Waldo_DynamicAA_Registry", _registry];
if (_config getOrDefault ["announce", true]) then {
    private _recipientOwners = (allPlayers select {side group _x == _side}) apply {owner _x};
    _recipientOwners = _recipientOwners arrayIntersect _recipientOwners;
    {
        ["AIR DEFENCE", format ["System %1 scrambled %2 fighter(s).", _id, _spawnedCount], "WARNING", "DYNAMIC_AA"] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _x];
    } forEach _recipientOwners;
};
_spawnedCount
