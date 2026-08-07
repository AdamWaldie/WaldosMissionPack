/*
 * Author: WaldoTheWarfighter
 * One-call reliable paradrop setup for an aircraft a mission maker has already placed and crewed in
 * Eden Editor - the simple alternative to the full Dynamic Drop Zone system (Waldo_fnc_
 * ParadropCreateDropZone / the ZEN "Dynamic Paradrop" module) for missions that just want a working
 * jump plane without a managed registry, generated jumpers or map markers.
 *
 * This shares its actual flight logic with the Dynamic Drop Zone system through
 * Waldo_fnc_ParadropBuildFlightRoute - the same proven standby/green/red/exit route, the same
 * altitude/speed handling that avoids the km/h-vs-m/s overspeed mistake, and the same waypoint
 * cleanup that stops an Eden-placed aircraft's own default waypoints from fighting the scripted
 * route. That waypoint conflict, more than anything else, is why a manually wired-up paradrop plane
 * is "hard to get in position" - see Waldo_fnc_ParadropBuildFlightRoute's own header for detail.
 *
 * Unlike the Dynamic Drop Zone system, this does not create or re-crew the aircraft: it uses
 * whichever group currently owns the driver's seat, waiting (bounded) for a pilot to exist if the
 * aircraft was just placed and crew spawn-in is still in progress. If that group has other units
 * besides this aircraft's crew (e.g. a squad leader who is also the pilot), the crew is moved into a
 * dedicated fresh group first - Waldo_fnc_ParadropBuildFlightRoute clears every waypoint of whatever
 * group it's given, and a shared group must not lose waypoints that belong to units who were never
 * part of this aircraft. Static-line and HALO jump actions are installed through the exact same
 * Waldo_fnc_ParadropConfigureAircraftLocal used by the Dynamic Drop Zone system, so both paths behave
 * identically once airborne.
 *
 * A lightweight cleanup watcher removes this call's own markers (never the aircraft or its crew,
 * which this function never owned in the first place) once the aircraft is destroyed/deleted, or
 * once a "DESPAWN" lifecycle run reaches its exit point - matching Waldo_fnc_ParadropCreateDropZone's
 * own automatic cleanup. Set the keepMarkersOnCleanup option true to opt out and leave the markers on
 * the map instead. This is a deliberately smaller contract than Waldo_fnc_ParadropRemoveDropZone,
 * which does delete the aircraft it spawned - see the difference called out in the lifecycle option
 * below.
 *
 * Arguments:
 * 0: aircraft <OBJECT> - placed, ideally already crewed with a pilot (e.g. via
 *    Waldo_fnc_MoveInCargoPlane in the object's own init field, or an Eden-assigned crew).
 * 1: target <STRING, ARRAY or OBJECT> - drop point: a marker name, a position, or an object. A
 *    marker name is the beginner-friendly option - place a marker in Eden, name it, put that name
 *    here. A mistyped or never-placed marker name is reported clearly (see Return Value) rather
 *    than silently sending the aircraft toward the map's [0,0] corner.
 * 2: direction <NUMBER> - degrees; the aircraft approaches the target along this heading. -1 (the
 *    default) computes a sensible heading automatically from the aircraft's position to the target.
 * 3: altitude <NUMBER> - route altitude AGL in metres (default 250, clamped 100-2000).
 * 4: maximum speed <NUMBER> - km/h (default 220, clamped 80-500).
 * 5: options <HASHMAP> - optional overrides: staticJumpEnabled (default true), haloJumpEnabled
 *    (default false), staticMinimumAltitude/staticMaximumAltitude/staticMaximumSpeed/
 *    staticChuteClass, haloMinimumAltitude/haloBackpackClass (all default from the mission's
 *    configured WALDO_STATIC_ and WALDO_PARA_ envelope variables, same as every other WMP
 *    paradrop entry point), requireOpenDoor (default true, ignored if the airframe has no recognised door/ramp
 *    animation), lifecycle (LOOP/RETAIN/DESPAWN, default LOOP - this function never deletes the
 *    aircraft under any lifecycle, unlike Waldo_fnc_ParadropCreateDropZone; DESPAWN only changes
 *    which waypoints get added and is one of the two automatic marker-cleanup triggers below),
 *    circuitDirection (LEFT/RIGHT, default LEFT), approachDistance/runLength/exitDistance (metres,
 *    default 2500 each), createMarkers (default true - AREA/STANDBY/GREEN/RED markers matching
 *    Waldo_fnc_ParadropCreateDropZone's layout, created invisible (alpha 0, still real/queryable
 *    markers) so a mission maker gets the route's positional markers without the map clutter, plus a
 *    visible POINT marker at the target - but only when target was not itself a marker name, since
 *    that marker already sits exactly there and a second icon/label on top of it would just overlap;
 *    set false for a map-clutter-free operation), keepMarkersOnCleanup (default false -
 *    the created markers are removed automatically once the aircraft is destroyed/deleted, or once a
 *    DESPAWN run reaches its exit point; set true to leave them on the map instead; never affects the
 *    aircraft or crew either way), name (marker label, default "Drop Zone").
 *
 * Return Value:
 * Boolean - true when accepted (the actual route/actions are applied a moment later on the server
 * once a pilot is confirmed present; check the RPT for "[WMP PARADROP] Quick flight setup" if a
 * plane never starts flying). A target marker name that doesn't exist on the map is also reported
 * in-game via systemChat, not just the RPT - the single most common beginner setup mistake with
 * this function is placing the aircraft before placing (or correctly naming) its target marker.
 *
 * Example:
 * [this, "dz1"] call Waldo_fnc_ParadropQuickFlightSetup;
 * Result: the plane this is placed on flies a standby/green/red/exit run toward marker "dz1" at
 * 250 m / 220 km/h, looping to repeat, with the mission's configured static-line jump action ready.
 *
 * Example (HALO instead of static-line, one-shot):
 * [this, getMarkerPos "dz2", -1, 1200, 250, createHashMapFromArray [
 *     ["staticJumpEnabled", false], ["haloJumpEnabled", true], ["lifecycle", "DESPAWN"]
 * ]] call Waldo_fnc_ParadropQuickFlightSetup;
 *
 * Current callers: mission-maker object init fields (see the Halo And Static-Line Paradrop
 * compositions); available to scripts.
 */

params [
    ["_aircraft", objNull, [objNull]],
    ["_target", "", ["", [], objNull]],
    ["_direction", -1, [0]],
    ["_altitude", 250, [0]],
    ["_maxSpeed", 220, [0]],
    ["_options", createHashMap, [createHashMap]]
];
if (isNull _aircraft || {!(_aircraft isKindOf "Air")}) exitWith {false};
// Set as early and as synchronously as possible - before any waiting, before the isServer forward
// below - so Waldo_fnc_AddVehicleFunctions' own class-based auto-detection (which fires on "init"
// for classes like B_T_VTOL_01_infantry_F/RHS_C130J_Base and would otherwise unconditionally add
// BOTH static and HALO with mission-global defaults) can see this aircraft is being explicitly
// configured and skip its own jump-action setup instead of fighting this call for the final state.
// Broadcast from the server (every machine also sets it locally as its own init field runs, at
// roughly the same moment) so JIP clients that never execute this object's init field still see it.
_aircraft setVariable ["Waldo_Paradrop_ManuallyConfigured", true, isServer];
if !(isServer) exitWith {_this remoteExecCall ["Waldo_fnc_ParadropQuickFlightSetup", 2]; true};

// This object's own init field runs on every machine (standard Eden behaviour), so every non-server
// machine above just forwarded the exact same call here - with more than one client connected, the
// server can receive it several times for the same aircraft. Waldo_fnc_ParadropBuildFlightRoute
// deletes and rebuilds the whole group's waypoint list; a second rebuild landing mid-flight is
// exactly how a LOOP aircraft ends up flying only one pass before falling back to loitering near
// wherever its waypoint list happened to be cut off. Only the first arrival for this aircraft
// actually builds the route.
if (_aircraft getVariable ["Waldo_Paradrop_QuickSetupStarted", false]) exitWith {false};
_aircraft setVariable ["Waldo_Paradrop_QuickSetupStarted", true];

[_aircraft, _target, _direction, _altitude, _maxSpeed, _options] spawn {
    params ["_aircraft", "_target", "_direction", "_altitude", "_maxSpeed", "_options"];

    // Called from an object's init field, this can run before the aircraft's own crew (placed in
    // Eden, or assigned by another object's init field such as Waldo_fnc_MoveInCargoPlane) exists
    // yet. Wait for both mission init and an actual pilot rather than failing immediately - the
    // single biggest source of "the plane just sits there" reports for a script wired up this way.
    // Bounded the same way as the pilot wait below it: a mission that never sets WALDO_INIT_COMPLETE
    // (broken init.sqf, non-standard init flow) must not leave this spawned handle looping forever.
    // 180s, not 30s - this is a one-time setup cost, and a heavy multi-feature mission (many
    // compositions, ACRE/ACE/Zeus registration, background Steam Workshop lookups, first-load asset
    // streaming) can legitimately still be mid-init.sqf at 30s without anything actually being
    // broken; a real "give up" deadline still exists, it just isn't tight enough to fire on a slow
    // but healthy mission load.
    private _initDeadline = serverTime + 180;
    waitUntil {sleep 0.5; missionNamespace getVariable ["WALDO_INIT_COMPLETE", false] || {isNull _aircraft} || {serverTime >= _initDeadline}};
    if (isNull _aircraft) exitWith {};
    if !(missionNamespace getVariable ["WALDO_INIT_COMPLETE", false]) exitWith {
        diag_log format ["[WMP PARADROP] Quick flight setup abandoned for %1: WALDO_INIT_COMPLETE never became true within 180 seconds.", typeOf _aircraft];
    };
    private _deadline = serverTime + 180;
    waitUntil {sleep 0.5; isNull _aircraft || {!isNull (driver _aircraft)} || {serverTime >= _deadline}};
    if (isNull _aircraft) exitWith {};
    if (isNull driver _aircraft) exitWith {
        diag_log format ["[WMP PARADROP] Quick flight setup abandoned for %1: no pilot became available within 180 seconds. Assign a crew (Eden crew or Waldo_fnc_MoveInCargoPlane) before this call.", typeOf _aircraft];
    };

    // getMarkerPos on a marker name that doesn't exist returns [0,0,0], not an empty array - it
    // would otherwise silently pass the position check below and send the aircraft toward the
    // map's [0,0] corner. markerType returning "" is the actual "no such marker" signal, and it's
    // the single most common beginner mistake with this function (aircraft placed and configured,
    // target marker forgotten or misspelled), so it gets its own clearly worded, in-game-visible
    // rejection rather than folding into the generic "didn't resolve" case below.
    private _missingMarker = typeName _target == "STRING" && {_target != ""} && {markerType _target == ""};
    if (_missingMarker) exitWith {
        private _message = format ["[WMP PARADROP] %1 has no flight target: place a map marker named %2 (Eden Editor > Markers) for it to fly toward.", typeOf _aircraft, _target];
        diag_log format ["[WMP PARADROP] Quick flight setup rejected for %1: marker %2 does not exist.", typeOf _aircraft, _target];
        [_message] remoteExec ["systemChat", 0];
    };
    private _centre = switch (typeName _target) do {
        case "STRING": {if (_target == "") then {[]} else {getMarkerPos _target}};
        case "ARRAY": {_target};
        case "OBJECT": {if (isNull _target) then {[]} else {getPosATL _target}};
        default {[]};
    };
    if (count _centre < 2) exitWith {
        diag_log format ["[WMP PARADROP] Quick flight setup rejected for %1: target '%2' did not resolve to a position.", typeOf _aircraft, _target];
    };

    private _resolvedDirection = if (_direction >= 0) then {_direction mod 360} else {
        [getPosATL _aircraft, _centre] call BIS_fnc_dirTo
    };

    // Waldo_fnc_ParadropBuildFlightRoute clears every waypoint of the group it's given. That's safe
    // when the group belongs only to this aircraft's crew, but the pilot's actual Eden group may
    // contain other units entirely (a squad leader also flying, a multi-crew group with members
    // elsewhere) - wiping their waypoints too would be a surprising side effect of a call meant to
    // only touch this one aircraft. Isolate the crew into a dedicated fresh group first, only when
    // the group actually needs it.
    private _originalGroup = group driver _aircraft;
    private _flightGroup = _originalGroup;
    private _crew = crew _aircraft;
    if ({!(_x in _crew)} count units _originalGroup > 0) then {
        _flightGroup = createGroup [side _originalGroup, true];
        {[_x] joinSilent _flightGroup} forEach _crew;
        if (count units _originalGroup == 0) then {deleteGroup _originalGroup};
    };

    private _route = [
        _aircraft, _flightGroup, _centre, _resolvedDirection, _altitude, _maxSpeed,
        _options getOrDefault ["approachDistance", 2500], _options getOrDefault ["runLength", 2500],
        _options getOrDefault ["exitDistance", 2500], _options getOrDefault ["lifecycle", "LOOP"],
        _options getOrDefault ["circuitDirection", "LEFT"]
    ] call Waldo_fnc_ParadropBuildFlightRoute;
    if (_route isEqualTo createHashMap) exitWith {
        diag_log format ["[WMP PARADROP] Quick flight setup failed for %1: the flight route could not be built.", typeOf _aircraft];
    };
    private _lifecycle = toUpperANSI (_options getOrDefault ["lifecycle", "LOOP"]);
    if !(_lifecycle in ["LOOP", "RETAIN", "DESPAWN"]) then {_lifecycle = "LOOP"};
    // The route builder clamps altitude/speed internally and hands the real values back - use those
    // (not the raw params above) as the basis for everything that follows, so the jump envelope is
    // always normalized off what the aircraft is actually flying.
    private _routeAltitude = _route get "altitude";
    private _routeMaxSpeed = _route get "maxSpeed";

    private _requireDoor = _options getOrDefault ["requireOpenDoor", true];
    if (_requireDoor) then {
        private _animationSources = configFile >> "CfgVehicles" >> (typeOf _aircraft) >> "AnimationSources";
        private _recognizedDoorSources = ["ramp_bottom", "door_2_1", "door_2_2", "jumpdoor_1", "jumpdoor_2", "back_ramp_switch", "back_ramp_half_switch", "RearDoors", "Door_1_source", "ramp_anim"];
        if (_recognizedDoorSources findIf {isClass (_animationSources >> _x)} < 0) then {_requireDoor = false};
    };
    // Requesting a route altitude/speed and a jump envelope independently is exactly how a jump
    // action ends up permanently unavailable (the aircraft cruises outside its own configured
    // window). Normalize the envelope around the route this aircraft is actually flying, the same
    // way the Dynamic Drop Zone system already does.
    private _envelope = [
        _routeAltitude, _routeMaxSpeed,
        _options getOrDefault ["staticMinimumAltitude", missionNamespace getVariable ["WALDO_STATIC_MINALTITUDE", 180]],
        _options getOrDefault ["staticMaximumAltitude", missionNamespace getVariable ["WALDO_STATIC_MAXALTITUDE", 350]],
        _options getOrDefault ["staticMaximumSpeed", missionNamespace getVariable ["WALDO_STATIC_MAXSPEED", 310]],
        _options getOrDefault ["haloMinimumAltitude", missionNamespace getVariable ["WALDO_PARA_HALOALTITUDE", 1000]]
    ] call Waldo_fnc_ParadropNormalizeJumpEnvelope;
    private _jumpConfig = createHashMapFromArray [
        ["staticJumpEnabled", _options getOrDefault ["staticJumpEnabled", true]],
        ["staticMinimumAltitude", _envelope get "staticMinimumAltitude"],
        ["staticMaximumAltitude", _envelope get "staticMaximumAltitude"],
        ["staticMaximumSpeed", _envelope get "staticMaximumSpeed"],
        ["staticChuteClass", _options getOrDefault ["staticChuteClass", missionNamespace getVariable ["WALDO_STATIC_STATICCHUTE", "NonSteerable_Parachute_F"]]],
        ["haloJumpEnabled", _options getOrDefault ["haloJumpEnabled", false]],
        ["haloMinimumAltitude", _envelope get "haloMinimumAltitude"],
        ["haloBackpackClass", _options getOrDefault ["haloBackpackClass", missionNamespace getVariable ["WALDO_PARA_HALOCHUTE", "B_Parachute"]]],
        ["requireOpenDoor", _requireDoor]
    ];
    // A configured static chute class (e.g. a mod's steerable rig) may not be loaded in every
    // mission. Fall back to the vanilla class rather than silently disabling the jump action.
    if !(isClass (configFile >> "CfgVehicles" >> (_jumpConfig get "staticChuteClass"))) then {
        _jumpConfig set ["staticChuteClass", "NonSteerable_Parachute_F"];
    };
    [_aircraft, _jumpConfig] remoteExec ["Waldo_fnc_ParadropConfigureAircraftLocal", 0, _aircraft];
    diag_log format [
        "[WMP PARADROP] Quick flight setup jump envelope: aircraft=%1 static=%2 static-alt=%3-%4m static-speed<=%5 halo=%6 halo-alt>=%7.",
        typeOf _aircraft, _jumpConfig get "staticJumpEnabled", round (_envelope get "staticMinimumAltitude"), round (_envelope get "staticMaximumAltitude"),
        round (_envelope get "staticMaximumSpeed"), _jumpConfig get "haloJumpEnabled", round (_envelope get "haloMinimumAltitude")
    ];

    // On by default: the whole point of this entry point is a mission maker getting a working,
    // visible drop zone from one line, not a silent invisible route. Set createMarkers to false in
    // options for a map-clutter-free operation instead.
    private _markers = [];
    if (_options getOrDefault ["createMarkers", true]) then {
        private _label = _options getOrDefault ["name", "Drop Zone"];
        private _runLength = _options getOrDefault ["runLength", 2500];
        private _prefix = format ["Waldo_DZQ_%1", netId _aircraft];
        private _zoneMarker = createMarker [format ["%1_AREA", _prefix], _centre];
        _zoneMarker setMarkerShape "RECTANGLE";
        _zoneMarker setMarkerBrush "Border";
        _zoneMarker setMarkerDir _resolvedDirection;
        _zoneMarker setMarkerSize [100, (_runLength * 0.65) max 200];
        _zoneMarker setMarkerColor "ColorBlack";
        // AREA/STANDBY/GREEN/RED stay invisible (alpha 0) - they remain real markers at the exact
        // route positions (still queryable by name, e.g. getMarkerPos, and still visible to a mission
        // maker who reveals them deliberately) but are not shown on the map. The POINT marker below is
        // layered on top of this whole set as the one thing players actually see, instead of the
        // previous stacked five-marker layout.
        _zoneMarker setMarkerAlpha 0;
        _markers pushBack _zoneMarker;
        {
            _x params ["_suffix", "_key", "_colour", "_text"];
            private _marker = createMarker [format ["%1_%2", _prefix, _suffix], _route get _key];
            _marker setMarkerShape "RECTANGLE";
            _marker setMarkerBrush "SolidBorder";
            _marker setMarkerDir _resolvedDirection;
            _marker setMarkerSize [30, 4];
            _marker setMarkerColor _colour;
            _marker setMarkerText _text;
            _marker setMarkerAlpha 0;
            _markers pushBack _marker;
        } forEach [["STANDBY", "standby", "ColorYellow", "STANDBY"], ["GREEN", "green", "ColorGreen", "GREEN LINE"], ["RED", "red", "ColorRed", "RED LINE"]];
        // When target was a marker name, that marker already sits exactly at _centre - creating
        // another icon+label marker on top of it just doubles up (overlapping text, two stacked
        // icons) instead of adding information. Only add the POINT marker for an ARRAY/OBJECT
        // target, where nothing was already there to mark the drop point itself.
        if !(typeName _target == "STRING" && {_target != ""}) then {
            private _point = createMarker [format ["%1_POINT", _prefix], _centre];
            _point setMarkerType "mil_end";
            _point setMarkerColor "ColorBlack";
            _point setMarkerText _label;
            _markers pushBack _point;
        };
    };

    // Cleanup watcher. Markers are removed automatically once the aircraft is destroyed/deleted, or
    // once a DESPAWN run reaches its exit point - a marker for a drop zone that's no longer active is
    // just stale either way. Set keepMarkersOnCleanup true to opt out and leave them on the map. This
    // function never owns the aircraft's lifecycle either way (unlike Waldo_fnc_ParadropCreateDropZone,
    // which spawns and therefore deletes its own aircraft), so this only ever removes the markers
    // created above - never the aircraft or its crew.
    if (count _markers > 0 && {!(_options getOrDefault ["keepMarkersOnCleanup", false])}) then {
        [_aircraft, _markers, _lifecycle, _route] spawn {
            params ["_aircraft", "_markers", "_lifecycle", "_route"];
            waitUntil {
                sleep 1;
                isNull _aircraft
                || {!alive _aircraft}
                || {_lifecycle == "DESPAWN" && {_aircraft distance2D (_route get "exit") < 200}}
            };
            {deleteMarker _x} forEach _markers;
        };
    };

    diag_log format ["[WMP PARADROP] Quick flight setup complete: aircraft=%1 pilot=%2 centre=%3 direction=%4 altitude=%5 speed=%6.", typeOf _aircraft, driver _aircraft, _centre, round _resolvedDirection, round _routeAltitude, round _routeMaxSpeed];
};
true
