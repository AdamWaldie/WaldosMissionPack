/*
 * Author: WaldoTheWarfighter
 * Creates or replaces a named, server-authoritative Dynamic AA system from an extensible hash-map configuration.
 * The config file supplies candidate asset pools and safety bounds; it does not call this function.
 * Use initServer.sqf for pre-planned systems or ZEN for live creation. Non-server calls route to the
 * server and remote player requests require an assigned curator. Reusing an id replaces the system.
 *
 * Arguments:
 * 0: config <HASHMAP> with:
 *    Required: id <STRING> safe unique key; centre <ARRAY> detection centre.
 *    Detection: side <SIDE>, radius, minimumAltitude, maximumAltitude, engagementRadius <METRES>,
 *      detectionDwell, clearDelay and detectionInterval <SECONDS>.
 *    Placement: radarPosition/radarPositions, staticPositions and mobilePositions <ARRAY>;
 *      staticSiteSpacing <METRES>; radarDirection <DEGREES>.
 *    Response: fighterCount <NUMBER>; initialAmmoFraction <0..1>; createMarkers <BOOL>.
 *    Pool selection: faction <STRING> is a content profile independent of side. Exact ZEN selection
 *      uses radarAssignments/staticAssignments/mobileAssignments/fighterAssignments, with one class
 *      per requested slot. Script callers may still use the singular class overrides. Omitted values
 *      resolve through MissionConfig airOperationsConfig side/faction pools.
 *    Optional shutdown interaction: shutdownInteraction <BOOL>, shutdownChallenge <STRING> and
 *      shutdownDifficulty <easy|standard|hard|expert>.
 *
 * Return Value:
 * Boolean - true when creation was accepted; false when id, centre, classes or authority are invalid.
 *
 * Example:
 * private _config = createHashMapFromArray [
 *     ["id", "AA_NORTH"], ["centre", getMarkerPos "aa_north"],
 *     ["radarPosition", getMarkerPos "aa_north_radar"], ["side", east],
 *     ["radius", 2500], ["minimumAltitude", 80]
 * ];
 * [_config] call Waldo_fnc_DynamicAACreate;
 *
 * Current callers: Dynamic AA ZEN creation, audit mission and mission-maker server scripts.
 */

params [["_config", createHashMap, [createHashMap]]];
if !(isServer) exitWith {
    [_config] remoteExecCall ["Waldo_fnc_DynamicAACreate", 2];
    true
};

private _remoteAuthorized = true;
private _requestOwner = remoteExecutedOwner;
if (remoteExecutedOwner > 0) then {
    private _callerIndex = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_callerIndex >= 0) then {allPlayers select _callerIndex} else {objNull};
    _remoteAuthorized = !isNull _caller && {!isNull (getAssignedCuratorLogic _caller)};
};
if !(_remoteAuthorized) exitWith {false};
private _reply = {
    params ["_message", "_state"];
    if (_requestOwner > 2) then {
        ["DYNAMIC AA", _message, _state, "DYNAMIC_AA_CREATE", 7] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _requestOwner];
    };
};

private _id = _config getOrDefault ["id", ""];
private _centre = _config getOrDefault ["centre", []];
if (_id == "" || {count _centre < 2}) exitWith {
    diag_log "[WMP DYNAMIC AA] Creation rejected: id and centre are required.";
    ["Creation rejected: a valid system ID and detection centre are required.", "ERROR"] call _reply;
    false
};
private _safeId = [_id, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] call BIS_fnc_filterString;
if (_safeId != _id) exitWith {
    diag_log format ["[WMP DYNAMIC AA] Creation rejected: id '%1' contains unsupported characters.", _id];
    ["Creation rejected: the generated system ID contains unsupported characters.", "ERROR"] call _reply;
    false
};

private _registry = missionNamespace getVariable ["Waldo_DynamicAA_Registry", createHashMap];
if (_id in (keys _registry)) then {[_id, true] call Waldo_fnc_DynamicAADestroy};

private _side = _config getOrDefault ["side", east];
if !(_side in [west, east, independent]) then {_side = east};
private _radius = ((_config getOrDefault ["radius", 2000]) max 100) min (missionNamespace getVariable ["Waldo_DynamicAA_MaximumRadius", 50000]);
private _minimumAltitude = ((_config getOrDefault ["minimumAltitude", 50]) max 0) min (missionNamespace getVariable ["Waldo_DynamicAA_MaximumAltitude", 10000]);
private _maximumAltitude = ((_config getOrDefault ["maximumAltitude", missionNamespace getVariable ["Waldo_DynamicAA_MaximumAltitude", 10000]]) max _minimumAltitude) min (missionNamespace getVariable ["Waldo_DynamicAA_MaximumAltitude", 10000]);
private _engagementRadius = ((_config getOrDefault ["engagementRadius", _radius]) max 100) min _radius;
private _detectionDwell = (_config getOrDefault ["detectionDwell", 0]) max 0;
private _clearDelay = (_config getOrDefault ["clearDelay", 5]) max 0;
private _staticSiteSpacing = ((_config getOrDefault ["staticSiteSpacing", 30]) max 10) min 200;
private _fighterCount = round (((_config getOrDefault ["fighterCount", 0]) max 0) min (missionNamespace getVariable ["Waldo_DynamicAA_MaximumFighters", 12]));
private _detectionInterval = (_config getOrDefault ["detectionInterval", missionNamespace getVariable ["Waldo_DynamicAA_DefaultDetectionInterval", 1]]) max 0.25;
private _radarPosition = _config getOrDefault ["radarPosition", _centre];
private _radarPositions = _config getOrDefault ["radarPositions", [_radarPosition]];
if (count _radarPositions == 0) then {_radarPositions = [_radarPosition]};
private _staticPositions = _config getOrDefault ["staticPositions", []];
private _mobilePositions = _config getOrDefault ["mobilePositions", []];
private _radarAssignments = _config getOrDefault ["radarAssignments", []];
private _staticAssignments = _config getOrDefault ["staticAssignments", []];
private _mobileAssignments = _config getOrDefault ["mobileAssignments", []];
private _fighterAssignments = _config getOrDefault ["fighterAssignments", []];
private _assignmentMismatch = (count _radarAssignments > 0 && {count _radarAssignments != count _radarPositions})
    || {count _staticAssignments > 0 && {count _staticAssignments != count _staticPositions}}
    || {count _mobileAssignments > 0 && {count _mobileAssignments != count _mobilePositions}}
    || {count _fighterAssignments > 0 && {count _fighterAssignments != _fighterCount}};
if (_assignmentMismatch) exitWith {
    diag_log format ["[WMP DYNAMIC AA] '%1' rejected: exact assignment counts do not match requested slots.", _id];
    ["Creation rejected: exact equipment selections do not match the requested asset counts.", "ERROR"] call _reply;
    false
};
private _pool = [_config, _side] call Waldo_fnc_DynamicAAResolveAssetPool;
private _radarClasses = if (count _radarAssignments > 0) then {+_radarAssignments} else {
    if ("radarClass" in (keys _config)) then {[_config get "radarClass"]} else {_config getOrDefault ["radarClasses", _pool get "radarClasses"]}
};
private _staticSitePools = if ("staticClass" in (keys _config)) then {
    [[_config get "staticClass"]]
} else {
    if (count _staticAssignments > 0) then {_staticAssignments apply {[_x]}} else {
        if ("staticClasses" in (keys _config)) then {[+(_config get "staticClasses")]} else {_config getOrDefault ["staticSitePools", _pool get "staticSitePools"]}
    }
};
private _mobileClasses = if (count _mobileAssignments > 0) then {+_mobileAssignments} else {
    if ("mobileClass" in (keys _config)) then {[_config get "mobileClass"]} else {_config getOrDefault ["mobileClasses", _pool get "mobileClasses"]}
};
private _fighterClasses = if (count _fighterAssignments > 0) then {+_fighterAssignments} else {
    if ("fighterClass" in (keys _config)) then {[_config get "fighterClass"]} else {_config getOrDefault ["fighterClasses", _pool get "fighterClasses"]}
};
private _classes = +_radarClasses;
if (count _mobilePositions > 0) then {_classes append _mobileClasses};
if (_fighterCount > 0) then {_classes append _fighterClasses};
if (count _staticPositions > 0) then {{_classes append _x} forEach _staticSitePools};
private _invalidClass = _classes findIf {!isClass (configFile >> "CfgVehicles" >> _x)};
private _missingPool = count _radarClasses == 0
    || {count _staticPositions > 0 && {count _staticSitePools == 0}}
    || {count _mobilePositions > 0 && {count _mobileClasses == 0}}
    || {_fighterCount > 0 && {count _fighterClasses == 0}};
if (_invalidClass >= 0 || {_missingPool}) exitWith {
    private _reason = if (_invalidClass >= 0) then {format ["invalid classname %1", _classes select _invalidClass]} else {"a required asset pool is empty"};
    diag_log format ["[WMP DYNAMIC AA] '%1' rejected: %2.", _id, _reason];
    [format ["Creation rejected: %1.", _reason], "ERROR"] call _reply;
    false
};

_config set ["id", _id];
_config set ["centre", _centre];
_config set ["side", _side];
_config set ["radius", _radius];
_config set ["minimumAltitude", _minimumAltitude];
_config set ["maximumAltitude", _maximumAltitude];
_config set ["engagementRadius", _engagementRadius];
_config set ["detectionDwell", _detectionDwell];
_config set ["clearDelay", _clearDelay];
_config set ["staticSiteSpacing", _staticSiteSpacing];
_config set ["fighterCount", _fighterCount];
_config set ["detectionInterval", _detectionInterval];
_config set ["radarPosition", _radarPosition];
_config set ["radarPositions", _radarPositions];
_config set ["radarClasses", _radarClasses];
_config set ["staticSitePools", _staticSitePools];
_config set ["mobileClasses", _mobileClasses];
_config set ["fighterClasses", _fighterClasses];
_config set ["radarAssignments", _radarAssignments];
_config set ["staticAssignments", _staticAssignments];
_config set ["mobileAssignments", _mobileAssignments];
_config set ["fighterAssignments", _fighterAssignments];
_config set ["resolvedAssetPool", _pool getOrDefault ["source", "SIDE"]];

private _objects = [];
private _groups = [];
private _defenceGroups = [];
private _radars = _radarPositions apply {
    private _radarClass = if (count _radarAssignments > 0) then {_radarAssignments select _forEachIndex} else {selectRandom _radarClasses};
    private _radar = createVehicle [_radarClass, _x, [], 0, "NONE"];
    _radar setDir (_config getOrDefault ["radarDirection", random 360]);
    if (_radar isKindOf "AllVehicles") then {
        createVehicleCrew _radar;
        if (count crew _radar > 0) then {
            private _oldGroups = [];
            {_oldGroups pushBackUnique (group _x)} forEach crew _radar;
            private _group = createGroup _side;
            (crew _radar) joinSilent _group;
            {if (!isNull _x && {count units _x == 0}) then {deleteGroup _x}} forEach _oldGroups;
            _group setCombatMode "RED";
            _groups pushBackUnique _group;
        };
        _radar setVehicleRadar 1;
    };
    _objects pushBack _radar;
    _radar
};
private _radar = _radars select 0;

{
    private _base = _x;
    private _direction = _base getDir _centre;
    private _staticClasses = if (count _staticAssignments > 0) then {[_staticAssignments select _forEachIndex]} else {selectRandom _staticSitePools};
    private _staticClassCount = (count _staticClasses) max 1;
    private _positions = _staticClasses apply {
        if (_staticClassCount == 1) then {_base} else {
            _base getPos [_staticSiteSpacing, _direction + 180 + ((_forEachIndex * 360) / _staticClassCount)]
        }
    };
    {
        private _vehicle = createVehicle [_x, _positions select _forEachIndex, [], 0, "NONE"];
        _vehicle setVehicleAmmo (((_config getOrDefault ["initialAmmoFraction", 1]) max 0) min 1);
        _vehicle setDir _direction;
        createVehicleCrew _vehicle;
        private _oldGroups = [];
        {_oldGroups pushBackUnique (group _x)} forEach crew _vehicle;
        private _group = createGroup _side;
        (crew _vehicle) joinSilent _group;
        {if (!isNull _x && {count units _x == 0}) then {deleteGroup _x}} forEach _oldGroups;
        [_group, false] call Waldo_fnc_DynamicAASetGroupState;
        _objects pushBack _vehicle;
        _groups pushBackUnique _group;
        _defenceGroups pushBackUnique _group;
    } forEach _staticClasses;
} forEach _staticPositions;

{
    private _mobileClass = if (count _mobileAssignments > 0) then {_mobileAssignments select _forEachIndex} else {selectRandom _mobileClasses};
    private _vehicle = createVehicle [_mobileClass, _x, [], 0, "NONE"];
    _vehicle setVehicleAmmo (((_config getOrDefault ["initialAmmoFraction", 1]) max 0) min 1);
    _vehicle setDir (_x getDir _centre);
    createVehicleCrew _vehicle;
    private _oldGroups = [];
    {_oldGroups pushBackUnique (group _x)} forEach crew _vehicle;
    private _group = createGroup _side;
    (crew _vehicle) joinSilent _group;
    {if (!isNull _x && {count units _x == 0}) then {deleteGroup _x}} forEach _oldGroups;
    [_group, false] call Waldo_fnc_DynamicAASetGroupState;
    _objects pushBack _vehicle;
    _groups pushBackUnique _group;
    _defenceGroups pushBackUnique _group;
} forEach _mobilePositions;

private _markerPrefix = format ["Waldo_DynamicAA_%1", _id];
private _markers = [];
if (_config getOrDefault ["createMarkers", true]) then {
    private _colour = switch (_side) do {
        case west: {"ColorBLUFOR"};
        case independent: {"ColorIndependent"};
        default {"ColorOPFOR"};
    };
    private _areaMarker = createMarker [format ["%1_Area", _markerPrefix], _centre];
    _areaMarker setMarkerShape "ELLIPSE";
    _areaMarker setMarkerSize [_radius, _radius];
    _areaMarker setMarkerBrush "Border";
    _areaMarker setMarkerColor _colour;
    private _iconMarker = createMarker [format ["%1_Icon", _markerPrefix], _centre];
    _iconMarker setMarkerShape "ICON";
    _iconMarker setMarkerType "o_antiair";
    _iconMarker setMarkerColor _colour;
    _iconMarker setMarkerText format ["%1 AA - %2m / floor %3m", _id, round _radius, round _minimumAltitude];
    _markers = [_areaMarker, _iconMarker];
};

private _state = createHashMapFromArray [
    ["config", _config], ["radar", _radar], ["radars", _radars], ["objects", _objects], ["groups", _groups],
    ["defenceGroups", _defenceGroups], ["markers", _markers], ["active", true],
    ["detected", false], ["engaged", false], ["candidateSince", -1], ["clearSince", -1],
    ["fightersScrambled", false], ["fighterWaves", 0], ["lastFighterScramble", -1e10], ["handle", scriptNull]
];
_registry set [_id, _state];
missionNamespace setVariable ["Waldo_DynamicAA_Registry", _registry];
if (_config getOrDefault ["shutdownInteraction", false]) then {
    private _interactionSettings = [_id, _config getOrDefault ["shutdownChallenge", "circuit"], _config getOrDefault ["shutdownDifficulty", "standard"]];
    _radar setVariable ["Waldo_DynamicAA_SystemId", _id, true];
    _radar setVariable ["Waldo_DynamicAA_InteractionAvailable", true, true];
    [_radar, _interactionSettings] remoteExecCall ["Waldo_fnc_DynamicAAInteractionSetup", 0, _radar];
};
private _handle = [_id] spawn Waldo_fnc_DynamicAADetectorLoop;
_state set ["handle", _handle];
_registry set [_id, _state];
missionNamespace setVariable ["Waldo_DynamicAA_Registry", _registry];
[] call Waldo_fnc_DynamicAAPublishState;
diag_log format ["[WMP DYNAMIC AA] '%1' active: radius %2m, altitude floor %3m, asset pool %4.", _id, _radius, _minimumAltitude, _config get "resolvedAssetPool"];
[format ["System %1 is active with %2 radar(s), %3 static position(s), %4 mobile position(s) and %5 fighter(s) per wave.", _id, count _radars, count (_config getOrDefault ["staticPositions", []]), count (_config getOrDefault ["mobilePositions", []]), _fighterCount], "SUCCESS"] call _reply;
true
