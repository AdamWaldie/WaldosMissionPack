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
 * aircraft was just placed and crew spawn-in is still in progress. Static-line and HALO jump
 * actions are installed through the exact same Waldo_fnc_ParadropConfigureAircraftLocal used by the
 * Dynamic Drop Zone system, so both paths behave identically once airborne.
 *
 * Arguments:
 * 0: aircraft <OBJECT> - placed, ideally already crewed with a pilot (e.g. via
 *    Waldo_fnc_MoveInCargoPlane in the object's own init field, or an Eden-assigned crew).
 * 1: target <STRING, ARRAY or OBJECT> - drop point: a marker name, a position, or an object.
 * 2: direction <NUMBER> - degrees; the aircraft approaches the target along this heading. -1 (the
 *    default) computes a sensible heading automatically from the aircraft's position to the target.
 * 3: altitude <NUMBER> - route altitude AGL in metres (default 250, clamped 100-2000).
 * 4: maximum speed <NUMBER> - km/h (default 220, clamped 80-500).
 * 5: options <HASHMAP> - optional overrides: staticJumpEnabled (default true), haloJumpEnabled
 *    (default false), staticMinimumAltitude/staticMaximumAltitude/staticMaximumSpeed/
 *    staticChuteClass, haloMinimumAltitude/haloBackpackClass (all default from the mission's
 *    configured WALDO_STATIC_ and WALDO_PARA_ envelope variables, same as every other WMP
 *    paradrop entry point), requireOpenDoor (default true, ignored if the airframe has no recognised door/ramp
 *    animation), lifecycle (LOOP/RETAIN/DESPAWN, default LOOP), circuitDirection (LEFT/RIGHT,
 *    default LEFT), approachDistance/runLength/exitDistance (metres, default 2500 each),
 *    createMarkers (default true - AREA/STANDBY/GREEN/RED/POINT markers matching Waldo_fnc_
 *    ParadropCreateDropZone's layout, so a mission maker sees a working drop zone immediately; set
 *    false for a map-clutter-free operation), name (marker label, default "Drop Zone").
 *
 * Return Value:
 * Boolean - true when accepted (the actual route/actions are applied a moment later on the server
 * once a pilot is confirmed present; check the RPT for "[WMP PARADROP] Quick flight setup" if a
 * plane never starts flying).
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
if !(isServer) exitWith {_this remoteExecCall ["Waldo_fnc_ParadropQuickFlightSetup", 2]; true};

[_aircraft, _target, _direction, _altitude, _maxSpeed, _options] spawn {
    params ["_aircraft", "_target", "_direction", "_altitude", "_maxSpeed", "_options"];

    // Called from an object's init field, this can run before the aircraft's own crew (placed in
    // Eden, or assigned by another object's init field such as Waldo_fnc_MoveInCargoPlane) exists
    // yet. Wait for both mission init and an actual pilot rather than failing immediately - the
    // single biggest source of "the plane just sits there" reports for a script wired up this way.
    waitUntil {sleep 0.5; missionNamespace getVariable ["WALDO_INIT_COMPLETE", false] || {isNull _aircraft}};
    if (isNull _aircraft) exitWith {};
    private _deadline = serverTime + 30;
    waitUntil {sleep 0.5; isNull _aircraft || {!isNull (driver _aircraft)} || {serverTime >= _deadline}};
    if (isNull _aircraft) exitWith {};
    if (isNull driver _aircraft) exitWith {
        diag_log format ["[WMP PARADROP] Quick flight setup abandoned for %1: no pilot became available within 30 seconds. Assign a crew (Eden crew or Waldo_fnc_MoveInCargoPlane) before this call.", typeOf _aircraft];
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
    private _flightGroup = group driver _aircraft;
    private _route = [
        _aircraft, _flightGroup, _centre, _resolvedDirection, _altitude, _maxSpeed,
        _options getOrDefault ["approachDistance", 2500], _options getOrDefault ["runLength", 2500],
        _options getOrDefault ["exitDistance", 2500], _options getOrDefault ["lifecycle", "LOOP"],
        _options getOrDefault ["circuitDirection", "LEFT"]
    ] call Waldo_fnc_ParadropBuildFlightRoute;
    if (_route isEqualTo createHashMap) exitWith {
        diag_log format ["[WMP PARADROP] Quick flight setup failed for %1: the flight route could not be built.", typeOf _aircraft];
    };

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
        _altitude, _maxSpeed,
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
        {
            _x params ["_suffix", "_key", "_colour", "_text"];
            private _marker = createMarker [format ["%1_%2", _prefix, _suffix], _route get _key];
            _marker setMarkerShape "RECTANGLE";
            _marker setMarkerBrush "SolidBorder";
            _marker setMarkerDir _resolvedDirection;
            _marker setMarkerSize [30, 4];
            _marker setMarkerColor _colour;
            _marker setMarkerText _text;
        } forEach [["STANDBY", "standby", "ColorYellow", "STANDBY"], ["GREEN", "green", "ColorGreen", "GREEN LINE"], ["RED", "red", "ColorRed", "RED LINE"]];
        private _point = createMarker [format ["%1_POINT", _prefix], _centre];
        _point setMarkerType "mil_end";
        _point setMarkerColor "ColorBlack";
        _point setMarkerText _label;
    };

    diag_log format ["[WMP PARADROP] Quick flight setup complete: aircraft=%1 pilot=%2 centre=%3 direction=%4 altitude=%5 speed=%6.", typeOf _aircraft, driver _aircraft, _centre, round _resolvedDirection, _altitude, _maxSpeed];
};
true
