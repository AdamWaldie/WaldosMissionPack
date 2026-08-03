/*
 * Author: WaldoTheWarfighter
 * Creates one server-authoritative player-focused paradrop operation and optional map symbology.
 *
 * Operational side controls crew and generated jumper allegiance; airframe class is deliberately
 * independent. The server owns registry, groups, waypoints, jump timing and cleanup. Global Arma
 * markers provide normal JIP visibility without a custom replay layer. The aircraft carries only
 * one AI pilot by default, receives the selected static-line/HALO actions on every client and can
 * fly a wide re-alignment circuit, remain after one pass or despawn. Jump envelopes are normalized
 * against the selected route altitude and speed so customization cannot silently make every jump
 * action unavailable. Repeat use is isolated by ID.
 *
 * Arguments:
 * 0: configuration <HASHMAP> - id, name, centre, direction, side, aircraftClass, altitude,
 *    maximumSpeed, approachDistance, runLength, exitDistance, jumperCount, jumpInterval,
 *    lifecycle, circuitDirection, static/halo jump settings, jumperClass, createJumpers,
 *    autoDropPlayers, automaticJumpMode and createMarkers.
 * 1: requester <OBJECT> (default objNull) - curator used to authorize remote requests.
 *
 * Return Value:
 * Boolean - true when the operation was created.
 *
 * Example:
 * [createHashMapFromArray [["id","DZ_ALPHA"],["centre",getMarkerPos "dz"],
 * ["side",west],["aircraftClass","B_T_VTOL_01_infantry_F"]]], player]
 * remoteExecCall ["Waldo_fnc_ParadropCreateDropZone", 2];
 *
 * Current callers: ParadropCreateDropZoneZen and mission scripts.
 */
params [["_config", createHashMap, [createHashMap]], ["_requester", objNull, [objNull]]];
if (!isServer) exitWith {_this remoteExecCall ["Waldo_fnc_ParadropCreateDropZone", 2]; true};
if (remoteExecutedOwner > 0) then {
    if (isNull _requester || {owner _requester != remoteExecutedOwner} || {isNull getAssignedCuratorLogic _requester}) exitWith {false};
};
private _notifyRequester = {
    params ["_message", "_state"];
    if (!isNull _requester && {_config getOrDefault ["notifyRequester", true]}) then {
        ["DYNAMIC PARADROP", _message, _state, "PARADROP_CREATE", 8] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _requester];
    };
};

private _id = _config getOrDefault ["id", ""];
private _safeId = [_id, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] call BIS_fnc_filterString;
private _centre = +(_config getOrDefault ["centre", []]);
private _class = _config getOrDefault ["aircraftClass", ""];
if (_id == "" || {_safeId != _id} || {count _centre < 2}) exitWith {["Creation rejected: the operation name or centre is invalid.", "ERROR"] call _notifyRequester; false};
if !(isClass (configFile >> "CfgVehicles" >> _class) && {_class isKindOf "Air"}) exitWith {["Creation rejected: the selected airframe is unavailable.", "ERROR"] call _notifyRequester; false};

private _registry = missionNamespace getVariable ["Waldo_Paradrop_DropZones", createHashMap];
if (_id in keys _registry) then {[_id, true, _requester, false] call Waldo_fnc_ParadropRemoveDropZone};
_registry = missionNamespace getVariable ["Waldo_Paradrop_DropZones", createHashMap];
private _name = _config getOrDefault ["name", _id];
private _direction = (_config getOrDefault ["direction", 0]) mod 360;
private _side = _config getOrDefault ["side", west];
if !(_side in [west, east, independent]) then {_side = west};
private _altitude = ((_config getOrDefault ["altitude", 250]) max 100) min 2000;
private _maximumSpeed = ((_config getOrDefault ["maximumSpeed", 220]) max 80) min 500;
private _staticEnabled = _config getOrDefault ["staticJumpEnabled", true];
private _haloEnabled = _config getOrDefault ["haloJumpEnabled", false];
private _staticMinimum = ((_config getOrDefault ["staticMinimumAltitude", 180]) max 0) min ((_altitude - 25) max 0);
private _staticMaximum = ((_config getOrDefault ["staticMaximumAltitude", 350]) max (_altitude + 75)) min 2500;
private _staticMaximumSpeed = ((_config getOrDefault ["staticMaximumSpeed", 310]) max (_maximumSpeed + 40)) min 700;
private _haloMinimum = ((_config getOrDefault ["haloMinimumAltitude", 1000]) max 0) min _altitude;
private _automaticMode = toUpperANSI (_config getOrDefault ["automaticJumpMode", "STATIC"]);
if (_config getOrDefault ["autoDropPlayers", false]) then {
    if (_automaticMode == "STATIC" && {!_staticEnabled}) then {_automaticMode = if (_haloEnabled) then {"HALO"} else {"NONE"}};
    if (_automaticMode == "HALO" && {!_haloEnabled}) then {_automaticMode = if (_staticEnabled) then {"STATIC"} else {"NONE"}};
    if (_automaticMode == "NONE") then {_config set ["autoDropPlayers", false]};
};
private _requireDoor = _config getOrDefault ["requireOpenDoor", false];
if (_requireDoor) then {
    private _animationSources = configFile >> "CfgVehicles" >> _class >> "AnimationSources";
    private _recognizedDoorSources = ["ramp_bottom", "door_2_1", "door_2_2", "jumpdoor_1", "jumpdoor_2", "back_ramp_switch", "back_ramp_half_switch", "RearDoors", "Door_1_source", "ramp_anim"];
    if (_recognizedDoorSources findIf {isClass (_animationSources >> _x)} < 0) then {_requireDoor = false};
};
_config set ["staticJumpEnabled", _staticEnabled];
_config set ["staticMinimumAltitude", _staticMinimum];
_config set ["staticMaximumAltitude", _staticMaximum];
_config set ["staticMaximumSpeed", _staticMaximumSpeed];
_config set ["haloJumpEnabled", _haloEnabled];
_config set ["haloMinimumAltitude", _haloMinimum];
_config set ["automaticJumpMode", _automaticMode];
_config set ["requireOpenDoor", _requireDoor];
private _approach = ((_config getOrDefault ["approachDistance", 2500]) max 800) min 10000;
private _runLength = ((_config getOrDefault ["runLength", 2500]) max 300) min 6000;
private _exitDistance = ((_config getOrDefault ["exitDistance", 2500]) max 800) min 10000;
private _standby = [_centre, _runLength * 0.65, _direction + 180] call BIS_fnc_relPos;
private _green = [_centre, _runLength * 0.5, _direction + 180] call BIS_fnc_relPos;
private _red = [_centre, _runLength * 0.5, _direction] call BIS_fnc_relPos;
private _spawn = [_standby, _approach, _direction + 180] call BIS_fnc_relPos;
private _exit = [_red, _exitDistance, _direction] call BIS_fnc_relPos;
private _lifecycle = toUpperANSI (_config getOrDefault ["lifecycle", if (_config getOrDefault ["deleteAfterRun", false]) then {"DESPAWN"} else {"LOOP"}]);
if !(_lifecycle in ["LOOP", "RETAIN", "DESPAWN"]) then {_lifecycle = "LOOP"};
private _circuitDirection = toUpperANSI (_config getOrDefault ["circuitDirection", "LEFT"]);
private _circuitTurn = if (_circuitDirection == "RIGHT") then {90} else {-90};
private _circuitWidth = ((_approach max _runLength) * 0.75) max 1200;
private _crosswind = [_exit, _circuitWidth, _direction + _circuitTurn] call BIS_fnc_relPos;
private _downwind = [_spawn, _circuitWidth, _direction + _circuitTurn] call BIS_fnc_relPos;
private _rejoin = [_spawn, _approach * 0.6, _direction + 180] call BIS_fnc_relPos;
private _hold = [_exit, 1800, _direction] call BIS_fnc_relPos;
{_x set [2, _altitude]} forEach [_standby, _green, _centre, _red, _spawn, _exit, _crosswind, _downwind, _rejoin, _hold];

private _aircraft = createVehicle [_class, _spawn, [], 0, "FLY"];
_aircraft setPosATL _spawn;
_aircraft setDir _direction;
_aircraft setVelocityModelSpace [0, _maximumSpeed / 3.6, 0];
createVehicleCrew _aircraft;
if (isNull driver _aircraft) exitWith {deleteVehicle _aircraft; ["Creation failed: the selected airframe could not be crewed.", "ERROR"] call _notifyRequester; false};
private _pilot = driver _aircraft;
private _oldGroups = [];
{_oldGroups pushBackUnique group _x} forEach crew _aircraft;
// Retain only the pilot. Optional jumpers are created separately and default to zero; gunners and
// faction-provided cargo must never silently fill a player transport.
{
    if (_x != _pilot) then {
        moveOut _x;
        deleteVehicle _x;
    };
} forEach +(crew _aircraft);
private _flightGroup = createGroup _side;
[_pilot] joinSilent _flightGroup;
{if (!isNull _x && {count units _x == 0}) then {deleteGroup _x}} forEach _oldGroups;
_flightGroup setBehaviourStrong "CARELESS";
_flightGroup setCombatMode "BLUE";
_flightGroup setSpeedMode "LIMITED";
_aircraft flyInHeight [_altitude, true];
_aircraft limitSpeed _maximumSpeed;
// limitSpeed is km/h, while forceSpeed is metres/second. Applying one raw value to both caused
// extreme overspeed and the apparent lateral break at the drop zone.
_aircraft forceSpeed (_maximumSpeed / 3.6);
_aircraft engineOn true;
_aircraft setVehicleLock "UNLOCKED";

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

// One object-keyed replay configures current clients and JIP clients with both selected jump
// systems. The setup function reconciles repeated configuration rather than duplicating actions.
[_aircraft, _config] remoteExec ["Waldo_fnc_ParadropConfigureAircraftLocal", 0, _aircraft];

private _jumpers = [];
private _jumpGroup = grpNull;
if (_config getOrDefault ["createJumpers", true]) then {
    private _jumperClass = _config getOrDefault ["jumperClass", switch (_side) do {case east: {"O_Soldier_F"}; case independent: {"I_Soldier_F"}; default {"B_Soldier_F"}}];
    if !(isClass (configFile >> "CfgVehicles" >> _jumperClass) && {_jumperClass isKindOf "CAManBase"}) then {
        _jumperClass = switch (_side) do {case east: {"O_Soldier_F"}; case independent: {"I_Soldier_F"}; default {"B_Soldier_F"}};
    };
    _jumpGroup = createGroup _side;
    private _capacity = _aircraft emptyPositions "cargo";
    private _count = ((round (_config getOrDefault ["jumperCount", 0])) max 0) min _capacity min 60;
    for "_index" from 1 to _count do {
        private _unit = _jumpGroup createUnit [_jumperClass, _spawn, [], 0, "NONE"];
        _unit moveInCargo _aircraft;
        if (vehicle _unit == _aircraft) then {_jumpers pushBack _unit} else {deleteVehicle _unit};
    };
};

private _markers = [];
if (_config getOrDefault ["createMarkers", true]) then {
    private _prefix = format ["Waldo_DZ_%1", _id];
    private _zoneMarker = createMarker [format ["%1_AREA", _prefix], _centre];
    _zoneMarker setMarkerShape "RECTANGLE";
    _zoneMarker setMarkerBrush "Border";
    _zoneMarker setMarkerDir _direction;
    _zoneMarker setMarkerSize [100, (_runLength * 0.65) max 200];
    _zoneMarker setMarkerColor "ColorBlack";
    _markers pushBack _zoneMarker;
    {
        _x params ["_suffix", "_position", "_colour", "_text"];
        private _marker = createMarker [format ["%1_%2", _prefix, _suffix], _position];
        _marker setMarkerShape "RECTANGLE";
        _marker setMarkerBrush "SolidBorder";
        _marker setMarkerDir _direction;
        _marker setMarkerSize [30, 4];
        _marker setMarkerColor _colour;
        _marker setMarkerText _text;
        _markers pushBack _marker;
    } forEach [["STANDBY", _standby, "ColorYellow", "STANDBY"], ["GREEN", _green, "ColorGreen", "GREEN LINE"], ["RED", _red, "ColorRed", "RED LINE"]];
    private _point = createMarker [format ["%1_POINT", _prefix], _centre];
    _point setMarkerType "mil_end";
    _point setMarkerColor "ColorBlack";
    _point setMarkerText _name;
    _markers pushBack _point;
};

private _state = createHashMapFromArray [
    ["id", _id], ["name", _name], ["aircraft", _aircraft], ["flightGroup", _flightGroup],
    ["jumpers", _jumpers], ["jumpGroup", _jumpGroup], ["markers", _markers], ["green", _green], ["red", _red], ["exit", _exit],
    ["config", _config], ["lifecycle", _lifecycle], ["boardingPoints", []], ["active", true], ["createdAt", serverTime]
];
_registry set [_id, _state];
missionNamespace setVariable ["Waldo_Paradrop_DropZones", _registry];
_aircraft setVariable ["Waldo_Paradrop_DropZoneId", _id, true];
private _public = missionNamespace getVariable ["Waldo_Paradrop_PublicDropZones", []];
private _publicIndex = _public findIf {(_x select 0) == _id};
private _summary = [_id, _name, _aircraft, _centre, _side, _class];
if (_publicIndex >= 0) then {_public set [_publicIndex, _summary]} else {_public pushBack _summary};
missionNamespace setVariable ["Waldo_Paradrop_PublicDropZones", _public, true];

[_id] spawn {
    params ["_id"];
    private _registry = missionNamespace getVariable ["Waldo_Paradrop_DropZones", createHashMap];
    if !(_id in keys _registry) exitWith {};
    private _state = _registry get _id;
    private _aircraft = _state get "aircraft";
    private _flightGroup = _state get "flightGroup";
    private _config = _state get "config";
    private _green = _state get "green";
    private _red = _state get "red";
    private _deadline = serverTime + ((_config getOrDefault ["operationTimeout", 900]) max 60);
    waitUntil {sleep 0.25; isNull _aircraft || {!alive _aircraft} || {_aircraft distance2D _green < 180} || {serverTime >= _deadline}};
    if (!isNull _aircraft && {alive _aircraft} && {serverTime < _deadline}) then {
        private _dropUnits = +(_state getOrDefault ["jumpers", []]);
        if (_config getOrDefault ["autoDropPlayers", false]) then {
            {_dropUnits pushBackUnique _x} forEach ((crew _aircraft) select {isPlayer _x && {_aircraft getCargoIndex _x >= 0}});
        };
        private _interval = ((_config getOrDefault ["jumpInterval", 2]) max 0.5) min 10;
        private _automaticMode = toUpperANSI (_config getOrDefault ["automaticJumpMode", "STATIC"]);
        private _staticChute = _config getOrDefault ["staticChuteClass", _config getOrDefault ["chuteClass", "NonSteerable_Parachute_F"]];
        private _haloChute = _config getOrDefault ["haloBackpackClass", "B_Parachute"];
        {
            if (_aircraft distance2D _red <= 150) exitWith {
                diag_log format ["[WMP PARADROP] Red line reached; remaining jumpers retained id=%1", _id];
            };
            if (!isNull _x && {alive _x} && {vehicle _x == _aircraft}) then {
                if (_automaticMode == "HALO") then {
                    [_x, _aircraft, _haloChute] remoteExec ["Waldo_fnc_HaloJumpFunc", owner _x];
                } else {
                    [_x, _aircraft, _staticChute] remoteExec ["Waldo_fnc_StaticJumpFunc", owner _x];
                };
                sleep _interval;
            };
        } forEach _dropUnits;
    };
    waitUntil {sleep 1; isNull _aircraft || {!alive _aircraft} || {_aircraft distance2D (_state get "red") < 180} || {serverTime >= _deadline}};
    waitUntil {sleep 1; isNull _aircraft || {!alive _aircraft} || {_aircraft distance2D (_state getOrDefault ["exit", _state get "red"]) < 220} || {serverTime >= _deadline}};
    if (isNull _aircraft || {!alive _aircraft}) exitWith {[_id, true, objNull, false] call Waldo_fnc_ParadropRemoveDropZone};
    if ((_state getOrDefault ["lifecycle", "LOOP"]) == "DESPAWN") then {
        [_id, true, objNull, false] call Waldo_fnc_ParadropRemoveDropZone;
    };
};
diag_log format ["[WMP PARADROP] Created id=%1 name=%2 side=%3 airframe=%4 pilot=%5 optionalJumpers=%6 lifecycle=%7 markers=%8", _id, _name, _side, _class, _pilot, count _jumpers, _lifecycle, count _markers];
[format ["%1 created for players. Route %2m AGL / %3 km/h; static envelope %4-%5m / <=%6 km/h; HALO floor %7m. Use Paradrop - Embark Players to board.", _name, round _altitude, round _maximumSpeed, round _staticMinimum, round _staticMaximum, round _staticMaximumSpeed, round _haloMinimum], "SUCCESS"] call _notifyRequester;
true
