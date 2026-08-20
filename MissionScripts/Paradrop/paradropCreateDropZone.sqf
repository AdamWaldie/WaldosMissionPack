/*
 * Author: WaldoTheWarfighter
 * Creates one server-authoritative player-focused paradrop operation and optional map symbology.
 *
 * Operational side controls crew and generated jumper allegiance; airframe class is deliberately
 * independent. The server owns registry, groups, waypoints, jump timing and cleanup. Global Arma
 * markers provide normal JIP visibility without a custom replay layer. When createMarkers is true,
 * the overall DZ boundary, amber standby line, green jump line, red stop line and named point are
 * all visible, matching the pre-placed quick-flight setup. A live-updating b_plane marker (same
 * mechanism as airborne gunships, via Waldo_fnc_ParadropSetupLocal) tracks the aircraft's actual
 * position/heading every frame while it flies. The aircraft carries only
 * one AI pilot by default, receives the selected static-line/HALO actions on every client and can
 * fly a wide re-alignment circuit, remain after one pass or despawn. Jump envelopes are normalized
 * against the selected route altitude and speed so customization cannot silently make every jump
 * action unavailable. Repeat use is isolated by ID.
 *
 * Locality and authority: The server validates the request and owns creation, registry state,
 * route setup and cleanup. A curator client request is authenticated and forwarded to the server;
 * public state and marker objects provide JIP visibility, while actions are installed locally.
 *
 * Arguments:
 * 0: configuration <HASHMAP> - id, name, centre, direction, side, aircraftClass, altitude,
 *    maximumSpeed, approachDistance, runLength, exitDistance, jumperCount, jumpInterval,
 *    lifecycle, circuitDirection, static/halo jump settings, jumperClass, createJumpers,
 *    autoDropPlayers, automaticJumpMode, createMarkers, keepMarkersOnCleanup and
 *    aircraftInvincible (default Waldo_Paradrop_DefaultAircraftInvincible, shipped false).
 *    Automatic teardown always deletes the spawned aircraft/crew, on either aircraft loss or a
 *    DESPAWN pass completing normally, and by default removes the markers along with them - a marker
 *    for a drop zone that's no longer active is just stale. Set keepMarkersOnCleanup true to leave
 *    the markers on the map instead. An explicit Waldo_fnc_ParadropRemoveDropZone call, e.g. the ZEN
 *    "Remove Operation" module, always removes markers regardless of this option.
 * 1: requester <OBJECT> (default objNull) - curator used to authorize remote requests.
 *
 * Return Value:
 * Boolean - true when the operation was created.
 * Result: A successful call registers one isolated operation and publishes its player-facing state.
 *
 * Example:
 * [createHashMapFromArray [["id","DZ_ALPHA"],["centre",getMarkerPos "dz"],
 * ["side",west],["aircraftClass","B_T_VTOL_01_infantry_F"]]], player]
 * remoteExecCall ["Waldo_fnc_ParadropCreateDropZone", 2];
 *
 * Current callers: ParadropCreateDropZoneZen and server mission scripts. Eden init fields run on
 * every machine: a non-server copy without an explicit curator requester exits quietly, while an
 * intentional client request supplies that requester and routes to server.
 */
params [["_config", createHashMap, [createHashMap]], ["_requester", objNull, [objNull]]];
if (!isServer) exitWith {
    if (isNull _requester) exitWith {true};
    _this remoteExecCall ["Waldo_fnc_ParadropCreateDropZone", 2];
    true
};
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
private _altitude = ((_config getOrDefault ["altitude", missionNamespace getVariable ["Waldo_Paradrop_DefaultStaticRouteAltitude", 300]]) max 100) min 2000;
private _maximumSpeed = ((_config getOrDefault ["maximumSpeed", missionNamespace getVariable ["Waldo_Paradrop_DefaultStaticRouteSpeed", 300]]) max 80) min 500;
private _staticEnabled = _config getOrDefault ["staticJumpEnabled", true];
private _haloEnabled = _config getOrDefault ["haloJumpEnabled", false];
// ZEN sends its semantic jump-method choice as well as the already-normalised values. Repeat the
// hard gates here on authoritative state so a modified/stale client cannot create an unusable route.
private _jumpMethods = toUpperANSI (_config getOrDefault ["jumpMethods", ""]);
if (_jumpMethods in ["STATIC", "HALO", "BOTH"]) then {
    _staticEnabled = _jumpMethods in ["STATIC", "BOTH"];
    _haloEnabled = _jumpMethods in ["HALO", "BOTH"];
    private _configuredStaticMinimum = missionNamespace getVariable ["WALDO_STATIC_MINALTITUDE", 180];
    private _configuredStaticMaximum = (missionNamespace getVariable ["WALDO_STATIC_MAXALTITUDE", 350]) max _configuredStaticMinimum;
    private _configuredHaloMinimum = missionNamespace getVariable ["WALDO_PARA_HALOALTITUDE", 1000];
    private _minimumZenAltitude = if (_haloEnabled) then {_configuredHaloMinimum} else {_configuredStaticMinimum};
    private _maximumZenAltitude = if (_jumpMethods == "STATIC") then {_configuredStaticMaximum} else {2000};
    _altitude = (_altitude max _minimumZenAltitude) min _maximumZenAltitude;
    private _maximumZenSpeed = if (_staticEnabled) then {missionNamespace getVariable ["WALDO_STATIC_MAXSPEED", 310]} else {500};
    _maximumSpeed = (_maximumSpeed max 80) min _maximumZenSpeed;
};
private _automaticMode = toUpperANSI (_config getOrDefault ["automaticJumpMode", "STATIC"]);
private _aircraftInvincible = _config getOrDefault [
    "aircraftInvincible",
    missionNamespace getVariable ["Waldo_Paradrop_DefaultAircraftInvincible", false]
];
_config set ["aircraftInvincible", _aircraftInvincible];
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

// createVehicle special "FLY" plus crewing the aircraft immediately afterward (no
// enableSimulationGlobal freeze/unfreeze pause in between) is the same pattern
// Waldo_fnc_GunshipRegister and Waldo_fnc_DynamicAOCreate's own air-patrol spawn already use
// successfully for both planes and helicopters - freezing the aircraft while crew is assigned, as
// this used to do, is what was actually causing a helicopter to sink/crash once simulation resumed:
// its rotor lift only exists while simulation is live, so pausing simulation mid-setup and then
// resuming it moments later left the rotor state uninitialised for that first stretch of live frames.
private _aircraft = createVehicle [_class, _spawn, [], 0, "FLY"];
[_aircraft] call Waldo_fnc_HeadlessPinCrew;
_aircraft setPosATL _spawn;
_aircraft setDir _direction;
// Same guard as Waldo_fnc_ParadropQuickFlightSetup: mark this spawned aircraft as explicitly
// configured before any client's Waldo_fnc_AddVehicleFunctions auto-detection (installed on the
// "AllVehicles" init class event) has a chance to add its own conflicting static/HALO defaults.
_aircraft setVariable ["Waldo_Paradrop_ManuallyConfigured", true, true];
// This is a player transport, not an armed response asset. createVehicleCrew creates every engine
// crew position and then deleting all but the pilot produces unnecessary replicated AI entities and
// "Object not found" traffic on dedicated servers. Create exactly one pilot in an explicitly sided
// group instead. Optional jumpers are handled separately below and default to zero.
private _flightGroup = createGroup [_side, true];
_flightGroup setVariable ["Waldo_ServerOwnedFeature", true, true];
_flightGroup setVariable ["Waldo_Headless_ExcludeGroup", true, true];
// Airframe selection is deliberately independent of operational side (see this script's header),
// so the class's own native "crew" pilot can belong to a different faction/side entirely - most
// visibly with a live-modset-discovered airframe (Waldo_fnc_ResolveVehicleClassPool), where the
// native crew class is that mod's own faction. createUnit below still places the pilot on the
// correct _side regardless (a unit's actual side always follows its group), but only reuse the
// native crew class when it is already configured for the requested side - otherwise it is created
// on _side wearing a different faction's uniform, reading as "the aircraft was created on its
// original side" even though the pilot is functionally on the right team. Fall back to the vanilla
// per-side pilot whenever the native class doesn't match.
private _sideNumbers = createHashMapFromArray [[west, 1], [east, 0], [independent, 2], [civilian, 3]];
private _pilotClass = getText (configFile >> "CfgVehicles" >> _class >> "crew");
private _pilotIsCorrectSide = isClass (configFile >> "CfgVehicles" >> _pilotClass)
    && {_pilotClass isKindOf "CAManBase"}
    && {getNumber (configFile >> "CfgVehicles" >> _pilotClass >> "side") == (_sideNumbers getOrDefault [_side, 1])};
if !(_pilotIsCorrectSide) then {
    _pilotClass = switch (_side) do {
        case east: {"O_Pilot_F"};
        case independent: {"I_Pilot_F"};
        default {"B_Pilot_F"};
    };
};
private _pilot = _flightGroup createUnit [_pilotClass, _spawn, [], 0, "NONE"];
_pilot setVariable ["Waldo_ServerOwnedFeature", true, true];
_pilot setVariable ["acex_headless_blacklist", true, true];
_pilot moveInDriver _aircraft;
if (isNull _pilot || {driver _aircraft != _pilot}) exitWith {
    if (!isNull _pilot) then {deleteVehicle _pilot};
    deleteGroup _flightGroup;
    deleteVehicle _aircraft;
    ["Creation failed: the selected airframe could not receive its AI pilot.", "ERROR"] call _notifyRequester;
    false
};
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
// Reassert the exact creation transform after crew and waypoint creation, then issue the flight
// orders. The aircraft has been live/simulated since creation (see the "FLY" comment above) - no
// enableSimulationGlobal toggle here.
_aircraft setDir _direction;
_aircraft setPosATL (_route get "spawn");
_aircraft engineOn true;
_aircraft setVelocityModelSpace [0, (_route get "maxSpeed") / 3.6, 0];
_aircraft limitSpeed (_route get "maxSpeed");
_aircraft forceSpeed ((_route get "maxSpeed") / 3.6);
// Match ZEN's working Fly Height operation exactly. This vehicle is server-created and remains
// server-local here, so the locality-targeted operation is executed directly on its owner.
_aircraft flyInHeight (_route get "altitude");
diag_log format [
    "[WMP PARADROP] Dynamic aircraft activated: id=%1 requested=%2m AGL actual=%3m AGL speed=%4km/h currentWaypoint=%5.",
    _id,
    round (_route get "altitude"),
    round ((getPosATL _aircraft) # 2),
    round speed _aircraft,
    currentWaypoint _flightGroup
];
private _green = _route get "green";
private _red = _route get "red";
private _exit = _route get "exit";

// See Waldo_fnc_ParadropQuickFlightSetup for why this is needed: the requireOpenDoor check above
// only confirms the airframe HAS a recognised ramp/door animation, not that anything can actually
// open it - a live-modset-discovered airframe (Waldo_fnc_ResolveVehicleClassPool) frequently has no
// player-facing action wired to it, which otherwise leaves the jump action permanently unavailable.
// Open it automatically as the aircraft nears the drop run; never closed again afterward, including
// across a LOOP aircraft's repeat passes.
if (_requireDoor) then {
    [_aircraft, _green] spawn {
        params ["_aircraft", "_green"];
        waitUntil {sleep 1; isNull _aircraft || {!alive _aircraft} || {_aircraft distance2D _green < 900}};
        if (!isNull _aircraft && {alive _aircraft}) then {[_aircraft, true] call Waldo_fnc_ParadropOperateDoor};
    };
};

// Normalized against the route's own returned altitude/speed (not the pre-clamp local variables
// above) so this and Waldo_fnc_ParadropQuickFlightSetup can never drift onto a different basis than
// what the aircraft is actually flying.
private _routeAltitude = _route get "altitude";
private _routeMaxSpeed = _route get "maxSpeed";
// Fall back to the mission's own configured WALDO_STATIC_/WALDO_PARA_ envelope (airOperationsConfig.sqf),
// not hardcoded literals - matches Waldo_fnc_ParadropQuickFlightSetup, so a ZEN-created drop zone that
// doesn't override a threshold gets the mission maker's actual configured default, not the shipped
// pack default regardless of what the mission configured.
private _envelope = [
    _routeAltitude, _routeMaxSpeed,
    _config getOrDefault ["staticMinimumAltitude", missionNamespace getVariable ["WALDO_STATIC_MINALTITUDE", 180]],
    _config getOrDefault ["staticMaximumAltitude", missionNamespace getVariable ["WALDO_STATIC_MAXALTITUDE", 350]],
    _config getOrDefault ["staticMaximumSpeed", missionNamespace getVariable ["WALDO_STATIC_MAXSPEED", 310]],
    _config getOrDefault ["haloMinimumAltitude", missionNamespace getVariable ["WALDO_PARA_HALOALTITUDE", 1000]]
] call Waldo_fnc_ParadropNormalizeJumpEnvelope;
private _staticMinimum = _envelope get "staticMinimumAltitude";
private _staticMaximum = _envelope get "staticMaximumAltitude";
private _staticMaximumSpeed = _envelope get "staticMaximumSpeed";
private _haloMinimum = _envelope get "haloMinimumAltitude";
_config set ["staticMinimumAltitude", _staticMinimum];
_config set ["staticMaximumAltitude", _staticMaximum];
_config set ["staticMaximumSpeed", _staticMaximumSpeed];
_config set ["haloMinimumAltitude", _haloMinimum];

// A named JIP replay sends only the net ID and serialisable settings. A newly created aircraft may
// not exist on a remote client yet; the local resolver waits for objectFromNetId before installing
// the repeat-safe actions instead of silently receiving objNull.
_aircraft setVariable [
    "Waldo_Paradrop_ConfiguredJumpTypes",
    [_config get "staticJumpEnabled", _config get "haloJumpEnabled"],
    true
];
private _jumpConfig = createHashMapFromArray [
    ["staticJumpEnabled", _config get "staticJumpEnabled"],
    ["staticMinimumAltitude", _staticMinimum],
    ["staticMaximumAltitude", _staticMaximum],
    ["staticMaximumSpeed", _staticMaximumSpeed],
    ["staticChuteClass", _config getOrDefault ["staticChuteClass", missionNamespace getVariable ["WALDO_STATIC_STATICCHUTE", "NonSteerable_Parachute_F"]]],
    ["haloJumpEnabled", _config get "haloJumpEnabled"],
    ["haloMinimumAltitude", _haloMinimum],
    ["haloBackpackClass", _config getOrDefault ["haloBackpackClass", missionNamespace getVariable ["WALDO_PARA_HALOCHUTE", "B_Parachute"]]],
    ["requireOpenDoor", _config get "requireOpenDoor"]
];
if !(isClass (configFile >> "CfgVehicles" >> (_jumpConfig get "staticChuteClass"))) then {
    _jumpConfig set ["staticChuteClass", "NonSteerable_Parachute_F"];
};
private _actionJipKey = format ["WMP_Paradrop_Actions_%1", _id];
_aircraft setVariable ["Waldo_Paradrop_ActionJipKey", _actionJipKey, true];
private _jumpConfigPairs = keys _jumpConfig apply {[_x, _jumpConfig get _x]};
[netId _aircraft, _jumpConfigPairs] remoteExec ["Waldo_fnc_ParadropConfigureAircraftNetworkedLocal", 0, _actionJipKey];
if (_aircraftInvincible) then {
    private _damageJipKey = format ["WMP_Paradrop_Damage_%1", _id];
    _aircraft setVariable ["Waldo_Paradrop_DamageJipKey", _damageJipKey, true];
    _aircraft setVariable ["Waldo_Paradrop_AircraftInvincible", true, true];
    [netId _aircraft, true] remoteExec ["Waldo_fnc_ParadropSetAircraftInvincibilityLocal", 0, _damageJipKey];
};
// Mirrors Waldo_fnc_ParadropQuickFlightSetup's own envelope log line - without this, a ZEN-created
// operation's actual normalized envelope was invisible in the RPT, making a reported "jump action
// doesn't work" impossible to diagnose from logs alone.
diag_log format [
    "[WMP PARADROP] Dynamic drop zone jump envelope: id=%1 aircraft=%2 static=%3 static-alt=%4-%5m static-speed<=%6 halo=%7 halo-alt>=%8.",
    _id, _class, _config get "staticJumpEnabled", round _staticMinimum, round _staticMaximum,
    round _staticMaximumSpeed, _config get "haloJumpEnabled", round _haloMinimum
];

private _jumpers = [];
private _jumpGroup = grpNull;
if (_config getOrDefault ["createJumpers", true]) then {
    private _jumperClass = _config getOrDefault ["jumperClass", switch (_side) do {case east: {"O_Soldier_F"}; case independent: {"I_Soldier_F"}; default {"B_Soldier_F"}}];
    if !(isClass (configFile >> "CfgVehicles" >> _jumperClass) && {_jumperClass isKindOf "CAManBase"}) then {
        _jumperClass = switch (_side) do {case east: {"O_Soldier_F"}; case independent: {"I_Soldier_F"}; default {"B_Soldier_F"}};
    };
    _jumpGroup = createGroup _side;
    _jumpGroup setVariable ["Waldo_ServerOwnedFeature", true, true];
    _jumpGroup setVariable ["Waldo_Headless_ExcludeGroup", true, true];
    private _capacity = _aircraft emptyPositions "cargo";
    private _count = ((round (_config getOrDefault ["jumperCount", 0])) max 0) min _capacity min 60;
    for "_index" from 1 to _count do {
        private _unit = _jumpGroup createUnit [_jumperClass, _spawn, [], 0, "NONE"];
        _unit setVariable ["Waldo_ServerOwnedFeature", true, true];
        _unit setVariable ["acex_headless_blacklist", true, true];
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
    // This is the same visible route symbology used by the pre-placed quick-flight setup. The create
    // dialog already has an explicit Create map markers checkbox; hiding four of the five markers
    // after Zeus enabled that option made the control misleading and removed the operational gates.
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
// Separate from Waldo_Paradrop_PublicDropZones above - that list drives the ZEN Embark dropdown and
// must only ever contain registry-backed operations. This one only feeds the live aircraft marker
// (Waldo_fnc_ParadropSetupLocal/UpdateMarkersLocal, the same pattern airborne gunships use) and is
// also fed by Waldo_fnc_ParadropQuickFlightSetup, which has no registry entry of its own.
private _publicAircraft = missionNamespace getVariable ["Waldo_Paradrop_PublicAircraft", []];
private _aircraftIndex = _publicAircraft findIf {(_x select 0) == _id};
private _aircraftSummary = [_id, _name, _aircraft, _side];
if (_aircraftIndex >= 0) then {_publicAircraft set [_aircraftIndex, _aircraftSummary]} else {_publicAircraft pushBack _aircraftSummary};
missionNamespace setVariable ["Waldo_Paradrop_PublicAircraft", _publicAircraft, true];
[] remoteExecCall ["Waldo_fnc_ParadropSetupLocal", 0];

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
        private _staticChute = _config getOrDefault ["staticChuteClass", _config getOrDefault ["chuteClass", missionNamespace getVariable ["WALDO_STATIC_STATICCHUTE", "NonSteerable_Parachute_F"]]];
        private _haloChute = _config getOrDefault ["haloBackpackClass", missionNamespace getVariable ["WALDO_PARA_HALOCHUTE", "B_Parachute"]];
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
