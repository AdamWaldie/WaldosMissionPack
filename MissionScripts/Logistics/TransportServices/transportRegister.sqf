/*
 * Author: WaldoTheWarfighter, Val
 * Registers one AI-crewed helicopter or ground vehicle with the authoritative typed transport
 * service. Calls are accepted directly on the server or forwarded from an authorized curator.
 * Registration is repeat-safe and stores enough public object state for JIP interactions while the
 * full mutable registry remains server-only.
 * Locality and authority: callable anywhere and self-forwards; only the server mutates registration state.
 *
 * Arguments:
 * 0: vehicle <OBJECT>
 * 1: service type <STRING> - HELICOPTER or GROUND.
 * 2: service ID <STRING> - unique readable key; blank generates one.
 * 3: display name <STRING> - player-facing callsign/name; blank uses groupId.
 * 4: options <HASHMAP|ARRAY> - optional keys: cruiseAltitude, stopRadius, boardingSeconds,
 *    destinationDwell, allowedSides, allowedGroups, leadersOnly, showMarker, repairAtBase,
 *    refuelAtBase, forceDisembark, failSafeReset, speedMode, behaviour, landingSearchRadius,
 *    landingClearanceScale,
 *    roadSearchRadius, minimumSeparation, groundSpeedLimit, pathRetrySeconds, pathRetryLimit,
 *    invulnerable (vehicle and original AI service crew; default false),
 *    useImprovedLanding and keepEngineOnAway (helicopters only; default true - keeps the engine
 *    running at a pickup/destination stop away from base, overriding vanilla TR UNLOAD idle-down;
 *    set false to allow it to idle down like a normal AI landing). minimumSeparation spaces active
 *    destinations/bulk service slots (default: helicopters 60, ground vehicles 18); prepared bases
 *    are checked only for physical overlap.
 *
 * Return Value: Boolean - true when forwarded or registered.
 *
 * Example:
 * [this, "HELICOPTER", "RAVEN_1", "Raven One", createHashMapFromArray [["cruiseAltitude", 80]]]
 *     call Waldo_fnc_TransportRegister;
 * Result: Raven One enters the helicopter pool at its current position.
 * Current callers: mission-maker vehicle init fields, transport ZEN registration and audit tests.
 */

params [
    ["_vehicle", objNull, [objNull]], ["_type", "GROUND", [""]], ["_id", "", [""]],
    ["_displayName", "", [""]], ["_options", createHashMap, [createHashMap, []]]
];
_type = toUpperANSI _type;
if (isNull _vehicle || {!(_type in ["HELICOPTER", "GROUND"])}) exitWith {false};
if (!isServer) exitWith {
    private _safeOptions = _options;
    if (typeName _safeOptions == "HASHMAP") then {
        private _pairs = [];
        {_pairs pushBack [_x, _safeOptions get _x]} forEach keys _safeOptions;
        _safeOptions = _pairs;
    };
    [_vehicle, _type, _id, _displayName, _safeOptions] remoteExecCall ["Waldo_fnc_TransportRegister", 2];
    true
};

private _reject = {
    params ["_message"];
    missionNamespace setVariable ["Waldo_Transport_LastRegistrationError", _message];
    diag_log format ["[WMP TRANSPORT] Registration rejected: %1", _message];
    false
};
missionNamespace setVariable ["Waldo_Transport_LastRegistrationError", ""];

private _authorized = remoteExecutedOwner == 0;
if (!_authorized) then {
    private _callerIndex = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_callerIndex >= 0) then {allPlayers select _callerIndex} else {objNull};
    _authorized = !isNull _caller && {!isNull getAssignedCuratorLogic _caller};
};
if (!_authorized) exitWith {["Only the server or an assigned curator may register a transport."] call _reject};
if !(missionNamespace getVariable ["Waldo_FeatureConfig_SERVER_Ready", false]) exitWith {
    [_vehicle, _type, _id, _displayName, _options] spawn {
        params ["_vehicle", "_type", "_id", "_displayName", "_options"];
        waitUntil {sleep 0.1; missionNamespace getVariable ["Waldo_FeatureConfig_SERVER_Ready", false]};
        [_vehicle, _type, _id, _displayName, _options] call Waldo_fnc_TransportRegister;
    };
    true
};
if !(missionNamespace getVariable ["Waldo_TransportServices_Enable", false]) exitWith {["Transport Services is disabled in MissionConfig/logisticsConfig.sqf."] call _reject};
if (_type == "HELICOPTER" && {!(_vehicle isKindOf "Helicopter")}) exitWith {["Helicopter service was selected, but the target is not a helicopter."] call _reject};
if (_type == "GROUND" && {!(_vehicle isKindOf "LandVehicle") || {_vehicle isKindOf "StaticWeapon"}}) exitWith {["Ground service was selected, but the target is not a driveable ground vehicle."] call _reject};
if (isNull driver _vehicle) exitWith {["The selected vehicle has no driver."] call _reject};
if (!alive driver _vehicle) exitWith {["The selected vehicle's driver is dead."] call _reject};
if (isPlayer driver _vehicle) exitWith {["The selected vehicle must have an AI driver."] call _reject};

[] call Waldo_fnc_TransportInitServer;
if (_id == "") then {_id = format ["%1_%2", _type, floor (random 1000000)]};
_id = [_id, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] call BIS_fnc_filterString;
if (_id == "") exitWith {["The generated or supplied service ID contained no usable characters."] call _reject};
if (_displayName == "") then {_displayName = groupId group driver _vehicle};

private _optionMap = createHashMap;
if (typeName _options == "HASHMAP") then {
    {_optionMap set [_x, _options get _x]} forEach keys _options;
} else {
    {if (_x isEqualType [] && {count _x >= 2}) then {_optionMap set [_x select 0, _x select 1]}} forEach _options;
};
private _config = createHashMapFromArray [
    ["cruiseAltitude", _optionMap getOrDefault ["cruiseAltitude", missionNamespace getVariable ["Waldo_HeliTransport_DefaultAltitude", 50]]],
    ["stopRadius", _optionMap getOrDefault ["stopRadius", if (_type == "HELICOPTER") then {35} else {12}]],
    ["boardingSeconds", _optionMap getOrDefault ["boardingSeconds", missionNamespace getVariable ["Waldo_Transport_DefaultBoardingSeconds", 300]]],
    ["destinationDwell", _optionMap getOrDefault ["destinationDwell", missionNamespace getVariable ["Waldo_Transport_DefaultDestinationDwell", 45]]],
    ["allowedSides", _optionMap getOrDefault ["allowedSides", [side driver _vehicle]]],
    ["allowedGroups", _optionMap getOrDefault ["allowedGroups", []]],
    ["leadersOnly", _optionMap getOrDefault ["leadersOnly", false]],
    ["showMarker", _optionMap getOrDefault ["showMarker", true]],
    ["repairAtBase", _optionMap getOrDefault ["repairAtBase", false]],
    ["refuelAtBase", _optionMap getOrDefault ["refuelAtBase", true]],
    ["invulnerable", _optionMap getOrDefault ["invulnerable", false]],
    ["forceDisembark", _optionMap getOrDefault ["forceDisembark", false]],
    ["failSafeReset", _optionMap getOrDefault ["failSafeReset", false]],
    ["speedMode", toUpperANSI (_optionMap getOrDefault ["speedMode", if (_type == "GROUND") then {"NORMAL"} else {"FULL"}])],
    ["behaviour", toUpperANSI (_optionMap getOrDefault ["behaviour", "CARELESS"])],
    ["landingSearchRadius", (_optionMap getOrDefault ["landingSearchRadius", missionNamespace getVariable ["Waldo_HeliTransport_DefaultLzSearchRadius", 250]]) max 10],
    ["landingClearanceScale", (_optionMap getOrDefault ["landingClearanceScale", missionNamespace getVariable ["Waldo_HeliTransport_DefaultLzClearanceScale", 2.0]]) max 1],
    ["roadSearchRadius", (_optionMap getOrDefault ["roadSearchRadius", missionNamespace getVariable ["Waldo_GroundTransport_DefaultRoadSearchRadius", 200]]) max 0],
    ["minimumSeparation", (_optionMap getOrDefault ["minimumSeparation", if (_type == "HELICOPTER") then {missionNamespace getVariable ["Waldo_HeliTransport_DefaultSeparation", 60]} else {missionNamespace getVariable ["Waldo_GroundTransport_DefaultSeparation", 18]}]) max 0],
    ["groundSpeedLimit", (_optionMap getOrDefault ["groundSpeedLimit", missionNamespace getVariable ["Waldo_GroundTransport_DefaultSpeedLimit", 60]]) max 5],
    ["pathRetrySeconds", (_optionMap getOrDefault ["pathRetrySeconds", missionNamespace getVariable ["Waldo_Transport_DefaultPathRetrySeconds", 25]]) max 10],
    ["pathRetryLimit", floor ((_optionMap getOrDefault ["pathRetryLimit", missionNamespace getVariable ["Waldo_Transport_DefaultPathRetryLimit", 3]]) max 0)],
    ["useImprovedLanding", _optionMap getOrDefault ["useImprovedLanding", true]]
];
private _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
// minimumSeparation protects active destinations and bulk landing slots. At a prepared base,
// mission makers may park services closer together. Reject only physical overlap, using each
// vehicle's real model footprint plus a small safety margin.
private _footprintRadius = {
    params ["_object"];
    private _bounds = boundingBoxReal _object;
    _bounds params ["_minimum", "_maximum"];
    private _halfWidth = abs ((_maximum select 0) - (_minimum select 0)) * 0.5;
    private _halfLength = abs ((_maximum select 1) - (_minimum select 1)) * 0.5;
    (sqrt (_halfWidth * _halfWidth + _halfLength * _halfLength)) max 1
};
private _vehicleFootprint = [_vehicle] call _footprintRadius;
private _baseConflict = (keys _services) findIf {
    private _other = _services get _x;
    private _otherVehicle = _other getOrDefault ["vehicle", objNull];
    _other getOrDefault ["type", ""] == _type
    && {!isNull _otherVehicle}
    && {_otherVehicle != _vehicle}
    && {getPosATL _vehicle distance2D (_other getOrDefault ["startPos", getPosATL _otherVehicle]) < (_vehicleFootprint + ([_otherVehicle] call _footprintRadius) + 2)}
};
if (_baseConflict >= 0) exitWith {
    private _other = _services get ((keys _services) select _baseConflict);
    [format ["%1 physically overlaps %2. Move the vehicles far enough apart that their model footprints do not touch.", _displayName, _other getOrDefault ["name", "another transport"]]] call _reject
};
private _existing = _services getOrDefault [_id, createHashMap];
private _oldVehicle = _existing getOrDefault ["vehicle", objNull];
if (!isNull _oldVehicle && {_oldVehicle != _vehicle}) exitWith {[format ["Service ID %1 is already used by another vehicle.", _id]] call _reject};
private _entry = createHashMapFromArray [
    ["id", _id], ["type", _type], ["name", _displayName], ["vehicle", _vehicle],
    ["state", "AVAILABLE"], ["requestId", -1], ["requester", objNull], ["requesterUID", ""], ["config", _config],
    ["startPos", getPosATL _vehicle], ["startDir", getDir _vehicle], ["baseCrew", +crew _vehicle],
    ["phaseStarted", serverTime]
];
_services set [_id, _entry];
missionNamespace setVariable ["Waldo_Transport_Services", _services];
private _pools = missionNamespace getVariable ["Waldo_Transport_Pools", createHashMapFromArray [["HELICOPTER", []], ["GROUND", []]]];
private _pool = _pools getOrDefault [_type, []];
_pool pushBackUnique _id;
_pools set [_type, _pool];
missionNamespace setVariable ["Waldo_Transport_Pools", _pools];

_vehicle setVariable ["Waldo_TransportService_Id", _id, true];
_vehicle setVariable ["Waldo_TransportService_Type", _type, true];
_vehicle setVariable ["Waldo_TransportService_Name", _displayName, true];
_vehicle setVariable ["Waldo_TransportService_State", "AVAILABLE", true];
_vehicle setVariable ["Waldo_TransportService_RequestId", -1, true];
_vehicle setVariable ["Waldo_TransportService_RequesterUID", "", true];
_vehicle setVariable ["Waldo_TransportService_Registered", true, true];
_vehicle setVariable ["Waldo_TransportService_BaseCrew", +crew _vehicle, true];
if (_config get "invulnerable") then {_vehicle setDamage 0};
private _registrationOptions = [];
{_registrationOptions pushBack [_x, _config get _x]} forEach keys _config;
_vehicle setVariable ["Waldo_TransportService_Registration", [_type, _id, _displayName, _registrationOptions], true];
_vehicle lockDriver true;
// The 2-element array form forces strict AGL terrain-following instead of leaving the AI free to
// compute its own "safe" cruise profile - over long routes with real elevation change, plain
// single-argument flyInHeight lets the AI climb far above the requested altitude and produces the
// intermittent stop/start hunting this was tuned to fix. Waldo_fnc_ParadropBuildFlightRoute already
// established this exact fix for the same class of AI flight behaviour.
if (_type == "HELICOPTER") then {_vehicle flyInHeight [_config get "cruiseAltitude", true]};
// Retain the original TR UNLOAD route. Improved landing is the only default addition and owns the
// vector-guided final approach; the transport LAND command remains a fallback if it cannot acquire.
if (_type == "HELICOPTER") then {
    _vehicle setVariable ["Waldo_ImprovedHelicopterLanding_Exclude", !(_config get "useImprovedLanding"), true];
    // Transport's original LAND fallback begins inside 300 m. The global acceleration gate must
    // not delay controller acquisition past that fallback; the controller itself supplies the
    // minimum entry speed needed to avoid the former slow Little Bird approach.
    _vehicle setVariable ["Waldo_ImprovedHelicopterLanding_ImmediateAcquisition", _config get "useImprovedLanding", true];
};
missionNamespace setVariable [if (_type == "HELICOPTER") then {"Waldo_HeliTransport_Available"} else {"Waldo_GroundTransport_Available"}, true, true];
[] remoteExecCall ["Waldo_fnc_TransportInteractionInitLocal", 0, "Waldo_Transport_Interactions"];
[_vehicle] remoteExecCall ["Waldo_fnc_TransportSetupVehicleLocal", 0, _vehicle];
_entry = [_entry] call Waldo_fnc_TransportRefreshProtectionServer;

if (_config get "showMarker") then {
    private _marker = format ["Waldo_Transport_%1", _id];
    deleteMarker _marker;
    createMarker [_marker, getPosATL _vehicle];
    _marker setMarkerType (if (_type == "HELICOPTER") then {"loc_heli"} else {"loc_car"});
    // Matches the "name - state" format Waldo_fnc_TransportMonitorServer keeps updated afterward -
    // a freshly registered service is always AVAILABLE, so this is the same text the monitor's own
    // first tick would set a moment later.
    private _initialMarkerText = format ["%1 - Available", _displayName];
    _marker setMarkerText _initialMarkerText;
    _marker setMarkerColor (switch (side driver _vehicle) do {case west: {"ColorWEST"}; case east: {"ColorEAST"}; case independent: {"ColorGUER"}; case civilian: {"ColorCIV"}; default {"ColorUNKNOWN"}});
    _entry set ["marker", _marker];
    _entry set ["markerText", _initialMarkerText];
};
_services set [_id, _entry];
missionNamespace setVariable ["Waldo_Transport_Services", _services];
private _serviceGroup = group driver _vehicle;
if (!isNull _serviceGroup) then {[_serviceGroup, _displayName] call Waldo_fnc_TransportSetGroupNameLocal};
diag_log format ["[WMP TRANSPORT] Registered service=%1 name=%2 type=%3 vehicle=%4 marker=%5", _id, _displayName, _type, typeOf _vehicle, _config get "showMarker"];
true
