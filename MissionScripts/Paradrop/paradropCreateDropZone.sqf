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
 *    autoDropPlayers, automaticJumpMode, createMarkers and keepMarkersOnCleanup (default false).
 *    Automatic teardown always deletes the spawned aircraft/crew, on either aircraft loss or a
 *    DESPAWN pass completing normally, and by default removes the markers along with them - a marker
 *    for a drop zone that's no longer active is just stale. Set keepMarkersOnCleanup true to leave
 *    the markers on the map instead. An explicit Waldo_fnc_ParadropRemoveDropZone call, e.g. the ZEN
 *    "Remove Operation" module, always removes markers regardless of this option.
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
private _automaticMode = toUpperANSI (_config getOrDefault ["automaticJumpMode", "STATIC"]);
if (_config getOrDefault ["autoDropPlayers", false]) then {
    if (_automaticMode == "STATIC" && {!_staticEnabled}) then {_automaticMode = if (_haloEnabled) then {"HALO"} else {"NONE"}};
    if (_automaticMode == "HALO" && {!_haloEnabled}) then {_automaticMode = if (_staticEnabled) then {"STATIC"} else {"NONE"}};
    if (_automaticMode == "NONE") then {_config set ["autoDropPlayers", false]};
};
// requireOpenDoor defaults true here to match Waldo_fnc_ParadropQuickFlightSetup - the check is a
// no-op anyway for any airframe without a recognised door/ramp animation, so this only changes
// behaviour for airframes that actually have one.
private _requireDoor = _config getOrDefault ["requireOpenDoor", true];
if (_requireDoor) then {
    private _animationSources = configFile >> "CfgVehicles" >> _class >> "AnimationSources";
    private _recognizedDoorSources = ["ramp_bottom", "door_2_1", "door_2_2", "jumpdoor_1", "jumpdoor_2", "back_ramp_switch", "back_ramp_half_switch", "RearDoors", "Door_1_source", "ramp_anim"];
    if (_recognizedDoorSources findIf {isClass (_animationSources >> _x)} < 0) then {_requireDoor = false};
};
_config set ["staticJumpEnabled", _staticEnabled];
_config set ["haloJumpEnabled", _haloEnabled];
_config set ["automaticJumpMode", _automaticMode];
_config set ["requireOpenDoor", _requireDoor];
private _approach = ((_config getOrDefault ["approachDistance", 2500]) max 800) min 10000;
private _runLength = ((_config getOrDefault ["runLength", 2500]) max 300) min 6000;
private _exitDistance = ((_config getOrDefault ["exitDistance", 2500]) max 800) min 10000;
private _lifecycle = toUpperANSI (_config getOrDefault ["lifecycle", if (_config getOrDefault ["deleteAfterRun", false]) then {"DESPAWN"} else {"LOOP"}]);
if !(_lifecycle in ["LOOP", "RETAIN", "DESPAWN"]) then {_lifecycle = "LOOP"};
private _circuitDirection = toUpperANSI (_config getOrDefault ["circuitDirection", "LEFT"]);
// Only the standby/spawn point is needed before the aircraft exists (to know where to create it).
// Waldo_fnc_ParadropBuildFlightRoute derives the same point again once the aircraft is real, along
// with the rest of the route (green/red/exit/etc) it hands back below.
private _standby = [_centre, _runLength * 0.65, _direction + 180] call BIS_fnc_relPos;
private _spawn = [_standby, _approach, _direction + 180] call BIS_fnc_relPos;
_spawn set [2, _altitude];

private _aircraft = createVehicle [_class, _spawn, [], 0, "FLY"];
_aircraft setPosATL _spawn;
_aircraft setDir _direction;
_aircraft setVelocityModelSpace [0, _maximumSpeed / 3.6, 0];
createVehicleCrew _aircraft;
// Same guard as Waldo_fnc_ParadropQuickFlightSetup: mark this spawned aircraft as explicitly
// configured before any client's Waldo_fnc_AddVehicleFunctions auto-detection (installed on the
// "AllVehicles" init class event) has a chance to add its own conflicting static/HALO defaults.
_aircraft setVariable ["Waldo_Paradrop_ManuallyConfigured", true, true];
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
_aircraft setVehicleLock "UNLOCKED";

private _route = [
    _aircraft, _flightGroup, _centre, _direction, _altitude, _maximumSpeed,
    _approach, _runLength, _exitDistance, _lifecycle, _circuitDirection
] call Waldo_fnc_ParadropBuildFlightRoute;
if (_route isEqualTo createHashMap) exitWith {
    deleteVehicle _aircraft; deleteGroup _flightGroup;
    ["Creation failed: the flight route could not be built.", "ERROR"] call _notifyRequester;
    false
};
private _green = _route get "green";
private _red = _route get "red";
private _exit = _route get "exit";

// Normalized against the route's own returned altitude/speed (not the pre-clamp local variables
// above) so this and Waldo_fnc_ParadropQuickFlightSetup can never drift onto a different basis than
// what the aircraft is actually flying.
private _routeAltitude = _route get "altitude";
private _routeMaxSpeed = _route get "maxSpeed";
private _envelope = [
    _routeAltitude, _routeMaxSpeed,
    _config getOrDefault ["staticMinimumAltitude", 180], _config getOrDefault ["staticMaximumAltitude", 350],
    _config getOrDefault ["staticMaximumSpeed", 310], _config getOrDefault ["haloMinimumAltitude", 1000]
] call Waldo_fnc_ParadropNormalizeJumpEnvelope;
private _staticMinimum = _envelope get "staticMinimumAltitude";
private _staticMaximum = _envelope get "staticMaximumAltitude";
private _staticMaximumSpeed = _envelope get "staticMaximumSpeed";
private _haloMinimum = _envelope get "haloMinimumAltitude";
_config set ["staticMinimumAltitude", _staticMinimum];
_config set ["staticMaximumAltitude", _staticMaximum];
_config set ["staticMaximumSpeed", _staticMaximumSpeed];
_config set ["haloMinimumAltitude", _haloMinimum];

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
    private _deleteMarkersOnCleanup = !(_config getOrDefault ["keepMarkersOnCleanup", false]);
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
    // Automatic teardown removes its markers by default on either trigger - a marker for a drop zone
    // that's no longer active is just stale - unless the mission maker opted out with
    // keepMarkersOnCleanup.
    if (isNull _aircraft || {!alive _aircraft}) exitWith {[_id, true, objNull, false, _deleteMarkersOnCleanup] call Waldo_fnc_ParadropRemoveDropZone};
    if ((_state getOrDefault ["lifecycle", "LOOP"]) == "DESPAWN") then {
        [_id, true, objNull, false, _deleteMarkersOnCleanup] call Waldo_fnc_ParadropRemoveDropZone;
    };
};
diag_log format ["[WMP PARADROP] Created id=%1 name=%2 side=%3 airframe=%4 pilot=%5 optionalJumpers=%6 lifecycle=%7 markers=%8", _id, _name, _side, _class, _pilot, count _jumpers, _lifecycle, count _markers];
[format ["%1 created for players. Route %2m AGL / %3 km/h; static envelope %4-%5m / <=%6 km/h; HALO floor %7m. Use Paradrop - Embark Players to board.", _name, round _routeAltitude, round _routeMaxSpeed, round _staticMinimum, round _staticMaximum, round _staticMaximumSpeed, round _haloMinimum], "SUCCESS"] call _notifyRequester;
true
