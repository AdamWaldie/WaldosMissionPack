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
 *    refuelAtBase, forceDisembark, failSafeReset, speedMode and behaviour.
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

private _authorized = remoteExecutedOwner == 0;
if (!_authorized) then {
    private _callerIndex = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_callerIndex >= 0) then {allPlayers select _callerIndex} else {objNull};
    _authorized = !isNull _caller && {!isNull getAssignedCuratorLogic _caller};
};
if (!_authorized) exitWith {false};
if !(missionNamespace getVariable ["Waldo_FeatureConfig_SERVER_Ready", false]) exitWith {
    [_vehicle, _type, _id, _displayName, _options] spawn {
        params ["_vehicle", "_type", "_id", "_displayName", "_options"];
        waitUntil {sleep 0.1; missionNamespace getVariable ["Waldo_FeatureConfig_SERVER_Ready", false]};
        [_vehicle, _type, _id, _displayName, _options] call Waldo_fnc_TransportRegister;
    };
    true
};
if !(missionNamespace getVariable ["Waldo_TransportServices_Enable", false]) exitWith {false};
if (_type == "HELICOPTER" && {!(_vehicle isKindOf "Helicopter")}) exitWith {false};
if (_type == "GROUND" && {!(_vehicle isKindOf "LandVehicle") || {_vehicle isKindOf "StaticWeapon"}}) exitWith {false};
if (isNull driver _vehicle || {!alive driver _vehicle} || {isPlayer driver _vehicle}) exitWith {false};

[] call Waldo_fnc_TransportInitServer;
if (_id == "") then {_id = format ["%1_%2", _type, floor (random 1000000)]};
_id = [_id, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] call BIS_fnc_filterString;
if (_id == "") exitWith {false};
if (_displayName == "") then {_displayName = groupId group driver _vehicle};

private _optionMap = createHashMap;
if (typeName _options == "HASHMAP") then {
    {_optionMap set [_x, _options get _x]} forEach keys _options;
} else {
    {if (_x isEqualType [] && {count _x >= 2}) then {_optionMap set [_x select 0, _x select 1]}} forEach _options;
};
private _config = createHashMapFromArray [
    ["cruiseAltitude", _optionMap getOrDefault ["cruiseAltitude", missionNamespace getVariable ["Waldo_HeliTransport_DefaultAltitude", 80]]],
    ["stopRadius", _optionMap getOrDefault ["stopRadius", if (_type == "HELICOPTER") then {35} else {12}]],
    ["boardingSeconds", _optionMap getOrDefault ["boardingSeconds", missionNamespace getVariable ["Waldo_Transport_DefaultBoardingSeconds", 300]]],
    ["destinationDwell", _optionMap getOrDefault ["destinationDwell", missionNamespace getVariable ["Waldo_Transport_DefaultDestinationDwell", 45]]],
    ["allowedSides", _optionMap getOrDefault ["allowedSides", [side driver _vehicle]]],
    ["allowedGroups", _optionMap getOrDefault ["allowedGroups", []]],
    ["leadersOnly", _optionMap getOrDefault ["leadersOnly", false]],
    ["showMarker", _optionMap getOrDefault ["showMarker", true]],
    ["repairAtBase", _optionMap getOrDefault ["repairAtBase", false]],
    ["refuelAtBase", _optionMap getOrDefault ["refuelAtBase", true]],
    ["forceDisembark", _optionMap getOrDefault ["forceDisembark", false]],
    ["failSafeReset", _optionMap getOrDefault ["failSafeReset", true]],
    ["speedMode", toUpperANSI (_optionMap getOrDefault ["speedMode", "FULL"])],
    ["behaviour", toUpperANSI (_optionMap getOrDefault ["behaviour", "CARELESS"])]
];
private _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
private _existing = _services getOrDefault [_id, createHashMap];
if !(_existing isEqualTo createHashMap) then {
    private _oldVehicle = _existing getOrDefault ["vehicle", objNull];
    if (!isNull _oldVehicle && {_oldVehicle != _vehicle}) exitWith {false};
};
private _entry = createHashMapFromArray [
    ["id", _id], ["type", _type], ["name", _displayName], ["vehicle", _vehicle],
    ["state", "AVAILABLE"], ["requestId", -1], ["requester", objNull], ["config", _config],
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
_vehicle setVariable ["Waldo_TransportService_Registered", true, true];
private _registrationOptions = [];
{_registrationOptions pushBack [_x, _config get _x]} forEach keys _config;
_vehicle setVariable ["Waldo_TransportService_Registration", [_type, _id, _displayName, _registrationOptions], true];
_vehicle lockDriver true;
if (_type == "HELICOPTER") then {_vehicle flyInHeight (_config get "cruiseAltitude")};
missionNamespace setVariable [if (_type == "HELICOPTER") then {"Waldo_HeliTransport_Available"} else {"Waldo_GroundTaxi_Available"}, true, true];
[] remoteExecCall ["Waldo_fnc_TransportInteractionInitLocal", 0, "Waldo_Transport_Interactions"];

if (_config get "showMarker") then {
    private _marker = format ["Waldo_Transport_%1", _id];
    deleteMarker _marker;
    createMarker [_marker, getPosATL _vehicle];
    _marker setMarkerType (if (_type == "HELICOPTER") then {"loc_heli"} else {"loc_car"});
    _marker setMarkerText _displayName;
    _marker setMarkerColor (switch (side driver _vehicle) do {case west: {"ColorWEST"}; case east: {"ColorEAST"}; case independent: {"ColorGUER"}; case civilian: {"ColorCIV"}; default {"ColorUNKNOWN"}});
    _entry set ["marker", _marker];
};
_services set [_id, _entry];
missionNamespace setVariable ["Waldo_Transport_Services", _services];
true
