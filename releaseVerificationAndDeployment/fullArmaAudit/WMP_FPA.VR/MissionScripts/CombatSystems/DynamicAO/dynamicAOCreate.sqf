/*
 * Author: WaldoTheWarfighter
 * Builds a complete randomized, server-authoritative area of operations from a HashMap.
 *
 * The generator discovers faction assets at runtime, validates all bounds, tracks every spawned
 * entity and marker, and publishes only compact state for JIP clients. Infantry patrols, building
 * garrisons, static weapons, weighted vehicle and air patrols, civilians, parked cars, minefields
 * and manned roadblocks are independently optional. Generated AI use the active WMP AI profile;
 * legacy config maps containing a skill key remain accepted but that key is ignored. The invisible
 * centre anchor and per-minefield anchors are curator-editable deletion handles. Reusing an id
 * replaces the old AO safely.
 *
 * Locality and authority:
 * Server-owned creation, AI/marker registry and cleanup. Curator client requests route to the server;
 * AI commands run where their groups are local and compact published state supplies JIP clients.
 *
 * Arguments:
 * 0: config <HASHMAP> - see Wiki/Dynamic-AO-Generation.md for every supported key
 * 1: requester <OBJECT> - optional curator player used for authorization and feedback
 *
 * Return Value:
 * Boolean - true when the AO was accepted and registered
 *
 * Current callers: server mission scripts, Waldo_fnc_DynamicAOZen and the full-pack audit station.
 * Eden init fields run on every machine: a non-server copy without an explicit curator requester
 * exits quietly, while an intentional client request supplies that requester and routes to server.
 *
 * Example:
 * [createHashMapFromArray [["id","AO_NORTH"],["center",getMarkerPos "ao_north"],
 *  ["side",east],["faction","OPF_F"],["radius",600],["patrolGroups",3]]]
 *  call Waldo_fnc_DynamicAOCreate;
 * Result: AO_NORTH is registered with its generated assets, or validation leaves no partial AO.
 */
params [["_config", createHashMap, [createHashMap]], ["_requester", objNull, [objNull]]];
if (!isServer) exitWith {
    if (isNull _requester) exitWith {true};
    [_config, _requester] remoteExecCall ["Waldo_fnc_DynamicAOCreate", 2];
    true
};

if (remoteExecutedOwner > 0) then {
    if (isNull _requester || {owner _requester != remoteExecutedOwner} || {isNull getAssignedCuratorLogic _requester}) exitWith {false};
};
private _notify = {
    params ["_message", ["_state", "INFO"]];
    if (!isNull _requester) then {
        ["DYNAMIC AO", _message, _state, "DYNAMIC_AO", 8]
            remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _requester];
    };
};

private _id = _config getOrDefault ["id", ""];
private _center = _config getOrDefault ["center", _config getOrDefault ["centre", []]];
private _faction = _config getOrDefault ["faction", ""];
private _side = _config getOrDefault ["side", east];
private _displayName = [_config getOrDefault ["displayName", _id], "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 _-"] call BIS_fnc_filterString;
if (_displayName == "") then {_displayName = _id};
_displayName = _displayName select [0, 64];
if (_id == "" || {count _center < 2} || {_faction == ""}) exitWith {
    ["AO id, centre and enemy faction are required.", "ERROR"] call _notify;
    false
};
private _safeId = [_id, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] call BIS_fnc_filterString;
if (_safeId != _id) exitWith {["AO id contains unsupported characters.", "ERROR"] call _notify; false};
if !(_side in [west, east, independent, civilian]) then {_side = east};
private _factionValid = ([[west, east, independent, civilian]] call Waldo_fnc_DynamicAOGetFactions)
    findIf {(_x select 0) isEqualTo _side && {(_x select 1) == _faction}};
if (_factionValid < 0) exitWith {["The selected enemy faction is unavailable on the server or belongs to another side.", "ERROR"] call _notify; false};

private _radius = ((_config getOrDefault ["radius", 500]) max 100) min 2000;
private _patrolCount = round (((_config getOrDefault ["patrolGroups", 3]) max 0) min 12);
private _garrisonCount = round (((_config getOrDefault ["garrisonGroups", 3]) max 0) min 30);
private _staticCount = round (((_config getOrDefault ["staticTurrets", 0]) max 0) min 20);
private _vehicleCount = round (((_config getOrDefault ["vehiclePatrols", 0]) max 0) min 10);
private _airCount = round (((_config getOrDefault ["airPatrols", 0]) max 0) min 8);
private _civPatrolCount = round (((_config getOrDefault ["civilianPatrols", 0]) max 0) min 50);
private _civGarrisonCount = round (((_config getOrDefault ["civilianGarrisons", 0]) max 0) min 50);
private _civCarCount = round (((_config getOrDefault ["civilianCars", 0]) max 0) min 30);
private _minefieldCount = round (((_config getOrDefault ["minefields", 0]) max 0) min 15);
private _roadblockCount = round (((_config getOrDefault ["roadblocks", 0]) max 0) min 12);
private _simple = _config getOrDefault ["simplePathing", false];
private _heliRange = ((_config getOrDefault ["heliPatrolRange", 1000]) max 200) min 3000;
private _planeRange = ((_config getOrDefault ["planePatrolRange", 2000]) max 200) min 4000;
private _vehicleWeights = _config getOrDefault ["vehicleMix", [34, 33, 33]];
private _airWeights = _config getOrDefault ["airMix", [25, 25, 25, 25]];
if (count _vehicleWeights < 3) then {_vehicleWeights = [34, 33, 33]};
if (count _airWeights < 4) then {_airWeights = [25, 25, 25, 25]};

_config set ["id", _id];
_config set ["center", [_center select 0, _center select 1, 0]];
_config set ["side", _side];
_config set ["faction", _faction];
_config set ["displayName", _displayName];
_config set ["radius", _radius];
private _registry = missionNamespace getVariable ["Waldo_DynamicAO_Registry", createHashMap];
if (_id in keys _registry) then {[_id] call Waldo_fnc_DynamicAODestroy};

private _pools = [_faction, _side] call Waldo_fnc_DynamicAOResolvePools;
private _infantry = _pools get "infantry";
if (count _infantry == 0) exitWith {["The selected faction has no public infantry classes.", "ERROR"] call _notify; false};
private _civilianFaction = _config getOrDefault ["civilianFaction", ""];
private _civilianPools = if (_civilianFaction == "") then {createHashMapFromArray [["infantry", []], ["car", []]]} else {[_civilianFaction, civilian] call Waldo_fnc_DynamicAOResolvePools};

private _objects = [];
private _groups = [];
private _markers = [];
private _minefields = [];
private _buildings = (nearestObjects [_center, ["House", "Building"], _radius, true]) select {count (_x buildingPos -1) > 0};
_buildings = _buildings call BIS_fnc_arrayShuffle;
private _roads = (_center nearRoads _radius) call BIS_fnc_arrayShuffle;

private _trackGroup = {
    params ["_group"];
    _groups pushBackUnique _group;
    _group
};
private _spawnUnit = {
    params ["_group", "_class", "_position", ["_placementRadius", 0, [0]]];
    // Runtime-created infantry must not share one exact model-space position. On a dedicated
    // server the overlapping collision geometries can prevent the leader and followers from
    // acquiring their first path even though the group's waypoint is valid.
    private _unit = _group createUnit [_class, _position, [], _placementRadius, "NONE"];
    _objects pushBack _unit;
    if (!isNil "Waldo_fnc_AIApplyProfile") then {[_unit] call Waldo_fnc_AIApplyProfile};
    _unit
};
private _groundPosition = {
    params ["_candidate", ["_size", 5]];
    private _result = [_candidate, 0, 60, _size, 0, 0.35, 0, [], [_candidate, _candidate]] call BIS_fnc_findSafePos;
    [_result select 0, _result select 1, 0]
};
private _weightedClass = {
    params ["_buckets", "_weights"];
    private _available = [];
    {
        if (count _x > 0) then {_available pushBack [_forEachIndex, (_weights param [_forEachIndex, 0]) max 0]};
    } forEach _buckets;
    if (count _available == 0) exitWith {""};
    private _total = 0;
    {_total = _total + (_x select 1)} forEach _available;
    if (_total <= 0) exitWith {selectRandom (_buckets select (selectRandom _available select 0))};
    private _roll = random _total;
    private _chosen = (_available select ((count _available) - 1)) select 0;
    private _running = 0;
    {
        _running = _running + (_x select 1);
        if (_roll <= _running) exitWith {_chosen = _x select 0};
    } forEach _available;
    selectRandom (_buckets select _chosen)
};
private _crewVehicle = {
    params ["_vehicle"];
    createVehicleCrew _vehicle;
    private _oldGroups = [];
    {_oldGroups pushBackUnique (group _x)} forEach crew _vehicle;
    private _group = createGroup _side;
    [_group] call _trackGroup;
    (crew _vehicle) joinSilent _group;
    _group addVehicle _vehicle;
    {if (!isNil "Waldo_fnc_AIApplyProfile") then {[_x] call Waldo_fnc_AIApplyProfile}} forEach crew _vehicle;
    {if (!isNull _x && {count units _x == 0}) then {deleteGroup _x}} forEach _oldGroups;
    _group
};

for "_patrolIndex" from 1 to _patrolCount do {
    private _position = [_center getPos [random _radius, random 360], 4] call _groundPosition;
    private _group = createGroup _side;
    [_group] call _trackGroup;
    for "_unitIndex" from 1 to (4 + floor random 5) do {
        [_group, selectRandom _infantry, _position, 12] call _spawnUnit;
    };
    [_group, _center, _radius, _simple, "SAFE", "LIMITED", ["COLUMN", "STAG COLUMN", "WEDGE"]]
        call Waldo_fnc_DynamicAOAddPatrolWaypoints;
};

private _usableGarrisons = _garrisonCount min count _buildings;
for "_buildingIndex" from 0 to (_usableGarrisons - 1) do {
    private _positions = (_buildings select _buildingIndex) buildingPos -1;
    private _group = createGroup _side;
    [_group] call _trackGroup;
    private _occupants = (2 + floor random 3) min count _positions;
    for "_unitIndex" from 0 to (_occupants - 1) do {
        private _unit = [_group, selectRandom _infantry, _positions select _unitIndex] call _spawnUnit;
        doStop _unit;
        _unit setUnitPos (selectRandom ["UP", "MIDDLE"]);
    };
};

for "_staticIndex" from 1 to _staticCount do {
    private _staticPool = _pools get "static";
    if (count _staticPool > 0) then {
        private _position = [_center getPos [_radius * (0.25 + random 0.65), random 360], 5] call _groundPosition;
        private _weapon = createVehicle [selectRandom _staticPool, _position, [], 0, "NONE"];
        _weapon setDir (_position getDir _center);
        _objects pushBack _weapon;
        [_weapon] call _crewVehicle;
    };
};

for "_vehicleIndex" from 1 to _vehicleCount do {
    private _class = [[_pools get "car", _pools get "apc", _pools get "tank"], _vehicleWeights] call _weightedClass;
    if (_class != "") then {
        private _position = [_center getPos [_radius * (0.35 + random 0.55), random 360], 9] call _groundPosition;
        private _vehicle = createVehicle [_class, _position, [], 0, "NONE"];
        _vehicle setDir random 360;
        _objects pushBack _vehicle;
        private _group = [_vehicle] call _crewVehicle;
        [_group, _center, _radius, _simple, "SAFE", "LIMITED", ["COLUMN"]]
            call Waldo_fnc_DynamicAOAddPatrolWaypoints;
    };
};

for "_airIndex" from 1 to _airCount do {
    private _buckets = [_pools get "heli", _pools get "jet", _pools get "drone", _pools get "plane"];
    private _class = [_buckets, _airWeights] call _weightedClass;
    if (_class != "") then {
        private _isHeli = _class isKindOf "Helicopter";
        private _patrolRange = if (_isHeli) then {_heliRange} else {_planeRange};
        private _altitude = if (_isHeli) then {150 + random 200} else {500 + random 500};
        private _spawn = _center getPos [_radius + _patrolRange, random 360];
        _spawn set [2, _altitude];
        private _aircraft = createVehicle [_class, _spawn, [], 0, "FLY"];
        _aircraft setDir (_spawn getDir _center);
        _aircraft setPosATL _spawn;
        _aircraft flyInHeight _altitude;
        _aircraft engineOn true;
        _objects pushBack _aircraft;
        private _group = [_aircraft] call _crewVehicle;
        [_group, _center, _patrolRange, _simple, "AWARE", "NORMAL"]
            call Waldo_fnc_DynamicAOAddPatrolWaypoints;
    };
};

private _civilianInfantry = _civilianPools getOrDefault ["infantry", []];
for "_civilianIndex" from 1 to _civPatrolCount do {
    if (count _civilianInfantry > 0) then {
        private _position = [_center getPos [random _radius, random 360], 2] call _groundPosition;
        private _group = createGroup civilian;
        [_group] call _trackGroup;
        [_group, selectRandom _civilianInfantry, _position] call _spawnUnit;
        [_group, _center, _radius, _simple, "SAFE", "LIMITED", ["COLUMN"]]
            call Waldo_fnc_DynamicAOAddPatrolWaypoints;
    };
};
private _civGarrisons = _civGarrisonCount min count _buildings;
for "_civilianIndex" from 0 to (_civGarrisons - 1) do {
    if (count _civilianInfantry > 0) then {
        private _positions = (_buildings select _civilianIndex) buildingPos -1;
        private _group = createGroup civilian;
        [_group] call _trackGroup;
        private _unit = [_group, selectRandom _civilianInfantry, selectRandom _positions] call _spawnUnit;
        doStop _unit;
    };
};
private _civilianCars = _civilianPools getOrDefault ["car", []];
for "_carIndex" from 1 to _civCarCount do {
    if (count _civilianCars > 0) then {
        private _position = [_center getPos [random _radius, random 360], 6] call _groundPosition;
        private _car = createVehicle [selectRandom _civilianCars, _position, [], 0, "NONE"];
        _car setDir random 360;
        _car setFuel (0.15 + random 0.7);
        _objects pushBack _car;
    };
};

for "_fieldIndex" from 0 to (_minefieldCount - 1) do {
    private _fieldCenter = _center getPos [_radius * (0.72 + random 0.23), random 360];
    private _fieldAnchor = createVehicle ["Land_HelipadEmpty_F", _fieldCenter, [], 0, "CAN_COLLIDE"];
    _fieldAnchor setVariable ["Waldo_DynamicAO_Id", _id];
    _fieldAnchor setVariable ["Waldo_DynamicAO_MinefieldIndex", _fieldIndex];
    _fieldAnchor addEventHandler ["Deleted", {
        params ["_anchor"];
        [_anchor getVariable ["Waldo_DynamicAO_Id", ""], _anchor getVariable ["Waldo_DynamicAO_MinefieldIndex", -1]]
            call Waldo_fnc_DynamicAODestroyMinefield;
    }];
    private _mines = [];
    for "_mineIndex" from 1 to (5 + floor random 8) do {
        private _minePosition = _fieldCenter getPos [random 35, random 360];
        private _mine = createMine [selectRandom ["APERSMine", "APERSBoundingMine", "ATMine"], _minePosition, [], 0];
        _side revealMine _mine;
        _mines pushBack _mine;
    };
    private _fieldMarkers = [];
    if (_config getOrDefault ["showMineMarkers", false]) then {
        private _marker = createMarker [format ["Waldo_DynamicAO_%1_Mines_%2", _id, _fieldIndex], _fieldCenter];
        _marker setMarkerShape "ELLIPSE";
        _marker setMarkerSize [40, 40];
        _marker setMarkerBrush "Border";
        _marker setMarkerColor "ColorRed";
        _marker setMarkerText "Minefield";
        _fieldMarkers pushBack _marker;
    };
    _minefields pushBack createHashMapFromArray [["active", true], ["anchor", _fieldAnchor], ["mines", _mines], ["markers", _fieldMarkers]];
    _objects pushBack _fieldAnchor;
};

private _roadblocksToCreate = _roadblockCount min count _roads;
for "_roadblockIndex" from 0 to (_roadblocksToCreate - 1) do {
    private _road = _roads select _roadblockIndex;
    private _roadPosition = getPosATL _road;
    private _connections = roadsConnectedTo _road;
    private _direction = if (count _connections > 0) then {_road getDir (_connections select 0)} else {random 360};
    private _bunkerPosition = _roadPosition getPos [9, _direction + 90];
    private _bunker = createVehicle ["Land_BagBunker_Small_F", _bunkerPosition, [], 0, "CAN_COLLIDE"];
    _bunker setDir (_direction - 90);
    _objects pushBack _bunker;
    {
        private _barrierPosition = _roadPosition getPos [5, _direction + _x];
        private _barrier = createVehicle ["Land_Razorwire_F", _barrierPosition, [], 0, "CAN_COLLIDE"];
        _barrier setDir (_direction + 90);
        _objects pushBack _barrier;
    } forEach [80, 260];
    private _group = createGroup _side;
    [_group] call _trackGroup;
    for "_guardIndex" from 1 to 4 do {
        private _guard = [_group, selectRandom _infantry, _roadPosition getPos [4 + random 8, random 360]] call _spawnUnit;
        doStop _guard;
    };
};

private _anchor = createVehicle ["Land_HelipadEmpty_F", _center, [], 0, "CAN_COLLIDE"];
_anchor setVariable ["Waldo_DynamicAO_Id", _id];
_anchor setVariable ["Waldo_DynamicAO_Anchor", true, true];
_anchor addEventHandler ["Deleted", {
    params ["_anchor"];
    [_anchor getVariable ["Waldo_DynamicAO_Id", ""]] call Waldo_fnc_DynamicAODestroy;
}];
_objects pushBack _anchor;

if (_config getOrDefault ["showMarker", true]) then {
    private _colour = switch (_side) do {case west: {"ColorBLUFOR"}; case independent: {"ColorIndependent"}; case civilian: {"ColorCivilian"}; default {"ColorOPFOR"}};
    private _area = createMarker [format ["Waldo_DynamicAO_%1_Area", _id], _center];
    _area setMarkerShape "ELLIPSE";
    _area setMarkerSize [_radius, _radius];
    _area setMarkerBrush "Border";
    _area setMarkerColor _colour;
    private _point = createMarker [format ["Waldo_DynamicAO_%1_Point", _id], _center];
    _point setMarkerShape "ICON";
    _point setMarkerType "mil_objective";
    _point setMarkerColor _colour;
    _point setMarkerText _displayName;
    _markers = [_area, _point];
};

private _state = createHashMapFromArray [
    ["config", _config], ["anchor", _anchor], ["objects", _objects], ["groups", _groups],
    ["markers", _markers], ["minefields", _minefields], ["createdAt", serverTime]
];
_registry set [_id, _state];
missionNamespace setVariable ["Waldo_DynamicAO_Registry", _registry];
// Curator registration must happen after the engine has networked this frame's newly created units.
// Every infantry unit/vehicle root is already present in _objects; includeCrew discovers vehicle
// crews, so appending group units again only duplicates registration and caused dedicated-server
// "Ref to nonnetwork object" floods during AO creation.
[+_objects, +_minefields] spawn {
    params ["_editableObjects", "_fields"];
    sleep 0.1;
    _editableObjects = _editableObjects select {!isNull _x};
    {
        private _curator = _x;
        _curator addCuratorEditableObjects [_editableObjects, true];
        {
            private _fieldAnchor = _x getOrDefault ["anchor", objNull];
            if (!isNull _fieldAnchor) then {_curator addCuratorEditableObjects [[_fieldAnchor], false]};
        } forEach _fields;
    } forEach allCurators;
};
[] call Waldo_fnc_DynamicAOPublishState;
[format ["%1 created: %2 patrols, %3 garrisons, %4 vehicles and %5 air patrols.", _id, _patrolCount, _usableGarrisons, _vehicleCount, _airCount], "SUCCESS"] call _notify;
diag_log format ["[WMP DYNAMIC AO] Created '%1' faction=%2 side=%3 radius=%4 objects=%5 groups=%6.", _id, _faction, _side, _radius, count _objects, count _groups];
true
