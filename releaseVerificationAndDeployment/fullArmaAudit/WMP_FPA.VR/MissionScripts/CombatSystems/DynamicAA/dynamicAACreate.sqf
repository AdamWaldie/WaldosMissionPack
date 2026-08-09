/*
 * Author: WaldoTheWarfighter
 * Creates or replaces a named, server-authoritative Dynamic AA system from an extensible hash-map configuration.
 * The config file supplies candidate asset pools and safety bounds; it does not call this function.
 * Use initServer.sqf for pre-planned systems or ZEN for live creation. The same call may be placed in
 * an Eden object init: only its server execution creates the system and client duplicates exit safely.
 * ZEN requests are sent to the server and require an assigned curator. Reusing an id replaces it.
 *
 * Locality and authority:
 * The server validates, creates and publishes the registry snapshot. ZEN requests require a curator;
 * AI commands later follow each group's current owner. Vehicle crews are created directly into the
 * selected operational side so dedicated servers never publish a transient config-side group.
 * Repeated ids replace the existing system.
 *
 * Arguments:
 * 0: config <HASHMAP> with:
 *    Required: id <STRING> safe unique key; centre <ARRAY> detection centre.
 *    Naming: displayName <STRING> is the human-readable marker/removal name (default: id).
 *    Detection: side <SIDE>; radius and engagementRadius are horizontal map distances <METRES>;
 *      minimumAltitude/maximumAltitude are the independent flight floor/ceiling <METRES>,
 *      detectionDwell, clearDelay and detectionInterval <SECONDS>.
 *    Placement: radarPosition/radarPositions, staticPositions and mobilePositions <ARRAY> for
 *      authored layouts. Otherwise radarCount/staticCount/mobileCount produce a terrain-safe,
 *      server-generated layout around centre. staticSiteSpacing <METRES>; radarDirection <DEGREES>.
 *    Response: fighterCount <NUMBER>; initialAmmoFraction <0..1>; createMarkers <BOOL>.
 *      showMarkerDetails <BOOL> controls whether marker text includes range, floor and ceiling
 *      and defaults true; it does not enable markers by itself.
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
 * Result: one validated system is registered; a failed complete layout leaves no partial assets.
 *
 * Current callers: Dynamic AA ZEN creation, compositions, audit mission and mission-maker server
 * scripts. ZEN submits to the server; ordinary non-server execution exits quietly so an Eden init
 * does not submit one duplicate system per connected client. Server registry/snapshot publication
 * supplies JIP state, while group-local AI work follows the group's current owner/headless client.
 */

params [["_config", createHashMap, [createHashMap]]];
if !(isServer) exitWith {true};

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
private _minimumAltitude = ((_config getOrDefault ["minimumAltitude", 60]) max 0) min (missionNamespace getVariable ["Waldo_DynamicAA_MaximumAltitude", 10000]);
private _maximumAltitude = ((_config getOrDefault ["maximumAltitude", missionNamespace getVariable ["Waldo_DynamicAA_MaximumAltitude", 10000]]) max _minimumAltitude) min (missionNamespace getVariable ["Waldo_DynamicAA_MaximumAltitude", 10000]);
private _engagementRadius = ((_config getOrDefault ["engagementRadius", _radius]) max 100) min _radius;
private _detectionDwell = (_config getOrDefault ["detectionDwell", 0]) max 0;
private _clearDelay = (_config getOrDefault ["clearDelay", 5]) max 0;
private _staticSiteSpacing = ((_config getOrDefault ["staticSiteSpacing", 30]) max 10) min 200;
private _fighterCount = round (((_config getOrDefault ["fighterCount", 0]) max 0) min (missionNamespace getVariable ["Waldo_DynamicAA_MaximumFighters", 12]));
private _detectionInterval = (_config getOrDefault ["detectionInterval", missionNamespace getVariable ["Waldo_DynamicAA_DefaultDetectionInterval", 1]]) max 0.25;
private _radarAssignments = _config getOrDefault ["radarAssignments", []];
private _staticAssignments = _config getOrDefault ["staticAssignments", []];
private _mobileAssignments = _config getOrDefault ["mobileAssignments", []];
private _fighterAssignments = _config getOrDefault ["fighterAssignments", []];
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
private _radarSlotCount = if ("radarPositions" in keys _config) then {(count (_config get "radarPositions")) max 1} else {
    if ("radarPosition" in keys _config) then {1} else {round ((_config getOrDefault ["radarCount", 1]) max 1 min 4)}
};
private _staticSlotCount = if ("staticPositions" in keys _config) then {count (_config get "staticPositions")} else {round ((_config getOrDefault ["staticCount", 0]) max 0 min 8)};
private _mobileSlotCount = if ("mobilePositions" in keys _config) then {count (_config get "mobilePositions")} else {round ((_config getOrDefault ["mobileCount", 0]) max 0 min 8)};
private _assignmentMismatch = (count _radarAssignments > 0 && {count _radarAssignments != _radarSlotCount})
    || {count _staticAssignments > 0 && {count _staticAssignments != _staticSlotCount}}
    || {count _mobileAssignments > 0 && {count _mobileAssignments != _mobileSlotCount}}
    || {count _fighterAssignments > 0 && {count _fighterAssignments != _fighterCount}};
if (_assignmentMismatch) exitWith {
    diag_log format ["[WMP DYNAMIC AA] '%1' rejected: exact assignment counts do not match requested slots.", _id];
    ["Creation rejected: exact equipment selections do not match the requested asset counts.", "ERROR"] call _reply;
    false
};
private _displayName = [_config getOrDefault ["displayName", _id], "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 _-()[]"] call BIS_fnc_filterString;
if (_displayName == "") then {_displayName = _id};
_displayName = _displayName select [0, 64];
private _classes = +_radarClasses;
if (_mobileSlotCount > 0) then {_classes append _mobileClasses};
if (_fighterCount > 0) then {_classes append _fighterClasses};
if (_staticSlotCount > 0) then {{_classes append _x} forEach _staticSitePools};
private _invalidClass = _classes findIf {!isClass (configFile >> "CfgVehicles" >> _x)};
private _missingPool = count _radarClasses == 0
    || {_staticSlotCount > 0 && {count _staticSitePools == 0}}
    || {_mobileSlotCount > 0 && {count _mobileClasses == 0}}
    || {_fighterCount > 0 && {count _fighterClasses == 0}};
if (_invalidClass >= 0 || {_missingPool}) exitWith {
    private _reason = if (_invalidClass >= 0) then {format ["invalid classname %1", _classes select _invalidClass]} else {"a required asset pool is empty"};
    diag_log format ["[WMP DYNAMIC AA] '%1' rejected: %2.", _id, _reason];
    [format ["Creation rejected: %1.", _reason], "ERROR"] call _reply;
    false
};

// sizeOf is evaluated only after class validation. It approximates an object's MAP ICON size (per
// Bohemia's own command documentation), not its physical footprint - it is used here only because
// it is the one size query that works on a classname alone, before anything is spawned to measure
// with boundingBoxReal. For a large "detection installation" prop like Land_Radar_F that map-icon
// size can run well past the ground space the object actually occupies; combined with the previous
// 0.75 multiplier and a 100 m cap, that produced clearance requirements real, organically-dressed
// terrain (rocky/forested hillsides, not manicured airfields) could fail to satisfy anywhere across
// a large search, even on what looks like genuinely open ground. Scaled down and capped tighter -
// still comfortably larger than the supplied per-role minimum for every shipped class.
private _classClearance = {
    params ["_class", "_minimum"];
    ((((sizeOf _class) * 0.5) max _minimum) min 40)
};
private _largestClearance = {
    params ["_candidateClasses", "_minimum"];
    private _largest = _minimum;
    {_largest = _largest max ([_x, _minimum] call _classClearance)} forEach _candidateClasses;
    _largest
};
private _staticComponentClasses = [];
{{_staticComponentClasses pushBackUnique _x} forEach _x} forEach _staticSitePools;
private _staticComponentClearance = [_staticComponentClasses, 14] call _largestClearance;
private _effectiveStaticSpacing = _staticSiteSpacing max (_staticComponentClearance * 1.5);
private _makeLayoutRing = {
    params ["_count", "_distance", ["_includeCentre", false], ["_angleOffset", 0]];
    private _positions = [];
    private _centreOffset = if (_includeCentre) then {1} else {0};
    for "_index" from 0 to (_count - 1) do {
        private _candidate = if (_includeCentre && {_index == 0}) then {
            +_centre
        } else {
            private _ringIndex = _index - _centreOffset;
            private _ringCount = _count - _centreOffset;
            _centre getPos [_distance, (_ringIndex * (360 / (_ringCount max 1))) + _angleOffset]
        };
        _candidate set [2, 0];
        _positions pushBack _candidate;
    };
    _positions
};
private _radarPositions = if ("radarPositions" in keys _config) then {
    +(_config get "radarPositions")
} else {
    if ("radarPosition" in keys _config) then {[_config get "radarPosition"]} else {
        [_radarSlotCount, 140, true, 0] call _makeLayoutRing
    }
};
_radarPositions = _radarPositions select {_x isEqualType [] && {count _x >= 2}};
if (count _radarPositions == 0 && {_radarSlotCount > 0}) then {_radarPositions = [+_centre]};
private _layoutRadius = ((_radius * 0.35) max 120) min 700;
private _staticAuthored = "staticPositions" in keys _config;
private _staticPositions = if (_staticAuthored) then {+(_config get "staticPositions")} else {
    [_staticSlotCount, _layoutRadius, false, 20] call _makeLayoutRing
};
_staticPositions = _staticPositions select {_x isEqualType [] && {count _x >= 2}};
private _mobileAuthored = "mobilePositions" in keys _config;
private _mobilePositions = if (_mobileAuthored) then {+(_config get "mobilePositions")} else {
    [_mobileSlotCount, _layoutRadius * 0.65, false, 200] call _makeLayoutRing
};
_mobilePositions = _mobilePositions select {_x isEqualType [] && {count _x >= 2}};
private _layoutFailed = count _radarPositions != _radarSlotCount
    || {count _staticPositions != _staticSlotCount}
    || {count _mobilePositions != _mobileSlotCount};
if (_layoutFailed) exitWith {
    diag_log format ["[WMP DYNAMIC AA] '%1' rejected: no collision-safe generated layout was available.", _id];
    ["Creation rejected: the server could not find enough clear positions for the requested AA assets. Try a more open location or fewer assets.", "ERROR"] call _reply;
    false
};

_config set ["id", _id];
_config set ["displayName", _displayName];
_config set ["centre", _centre];
_config set ["side", _side];
_config set ["radius", _radius];
_config set ["minimumAltitude", _minimumAltitude];
_config set ["maximumAltitude", _maximumAltitude];
_config set ["engagementRadius", _engagementRadius];
_config set ["detectionDwell", _detectionDwell];
_config set ["clearDelay", _clearDelay];
_config set ["staticSiteSpacing", _effectiveStaticSpacing];
_config set ["fighterCount", _fighterCount];
_config set ["detectionInterval", _detectionInterval];
_config set ["radarPosition", _radarPositions select 0];
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
private _assetPlan = [];
{
    private _class = if (count _radarAssignments > 0) then {_radarAssignments select _forEachIndex} else {selectRandom _radarClasses};
    _assetPlan pushBack ["RADAR", _class, _x, _config getOrDefault ["radarDirection", random 360]];
} forEach _radarPositions;
{
    private _base = _x;
    private _direction = _base getDir _centre;
    private _siteClasses = if (count _staticAssignments > 0) then {[_staticAssignments select _forEachIndex]} else {selectRandom _staticSitePools};
    private _siteClassCount = (count _siteClasses) max 1;
    {
        private _candidate = if (_siteClassCount == 1) then {_base} else {
            _base getPos [_effectiveStaticSpacing, _direction + 180 + ((_forEachIndex * 360) / _siteClassCount)]
        };
        _assetPlan pushBack ["STATIC", _x, _candidate, _direction];
    } forEach _siteClasses;
} forEach _staticPositions;
{
    private _class = if (count _mobileAssignments > 0) then {_mobileAssignments select _forEachIndex} else {selectRandom _mobileClasses};
    _assetPlan pushBack ["MOBILE", _class, _x, _x getDir _centre];
} forEach _mobilePositions;

// Resolve every final component before creating the first vehicle. findEmptyPosition protects the
// real selected class against existing world objects; the additional reservation list protects
// planned assets that do not exist yet and therefore cannot be seen by the engine query.
// findEmptyPosition does not itself reject steep terrain - a clutter-free patch of open hillside
// passes every other check here just as readily as flat ground, which used to mean either a
// visibly tilted radar/launcher on a slope or (on a hillside dense enough that every open patch
// also happens to carry rocks/trees) the whole ring search failing outright with a misleading
// "no complete collision-free footprint" reason. Reject candidates over Waldo_DynamicAA_MaxSlopeDegrees
// explicitly so the search keeps walking outward toward an actually flat shelf instead.
private _maxSlopeDegrees = missionNamespace getVariable ["Waldo_DynamicAA_MaxSlopeDegrees", 12];
private _resolvedPlan = [];
private _finalReservations = [];
private _resolveFinalPosition = {
    params ["_candidate", "_class"];
    private _footprint = [_class, 8] call _classClearance;
    private _clearance = _footprint + 5;
    private _result = [];
    private _ringStep = ((_footprint * 2) + 15) max 35;
    for "_ring" from 0 to 16 do {
        if (count _result >= 2) exitWith {};
        private _samples = if (_ring == 0) then {1} else {(8 + (_ring * 2)) min 32};
        for "_sample" from 0 to (_samples - 1) do {
            if (count _result >= 2) exitWith {};
            private _samplePosition = if (_ring == 0) then {+_candidate} else {
                _candidate getPos [_ring * _ringStep, (_sample * (360 / _samples)) + ((_ring mod 2) * (180 / _samples))]
            };
            _samplePosition set [2, 0];
            private _exact = _samplePosition findEmptyPosition [0, _footprint max 5, _class];
            if (count _exact >= 2) then {
                _exact set [2, 0];
                private _plannedOverlap = _finalReservations findIf {
                    _x params ["_reservedPosition", "_reservedClearance"];
                    _exact distance2D _reservedPosition < (_clearance + _reservedClearance)
                };
                // Unfiltered nearestObjects catches anything sitting nearby regardless of relevance -
                // most notably the curator's own body/camera at ring 0 when a ZEN module is dropped
                // exactly where they are standing, and any other player/AI unit passing through later
                // rings. Neither should ever block a physical AA installation.
                private _objectBlockers = (nearestObjects [_exact, [], _clearance, true]) select {
                    !(_x isKindOf "CAManBase") && {!(_x isKindOf "Logic")}
                };
                private _terrainBlockers = nearestTerrainObjects [
                    _exact,
                    ["TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS", "BUILDING", "HOUSE", "FENCE", "WALL"],
                    _clearance,
                    false,
                    true
                ];
                private _waterCompatible = if (_class isKindOf "Ship") then {surfaceIsWater _exact} else {!surfaceIsWater _exact};
                // surfaceNormal is a unit vector; its Z component is the cosine of the angle between
                // the ground and world-up, so acos of it is the slope in degrees directly (0 = flat).
                private _slopeOk = _class isKindOf "Ship" || {(acos ((surfaceNormal _exact) select 2)) <= _maxSlopeDegrees};
                if (_plannedOverlap < 0 && {_objectBlockers isEqualTo []} && {_terrainBlockers isEqualTo []} && {_waterCompatible} && {_slopeOk}) then {
                    _result = _exact;
                    _finalReservations pushBack [_result, _clearance];
                };
            };
        };
    };
    _result
};
private _planFailed = false;
{
    _x params ["_kind", "_class", "_candidate", "_direction"];
    private _position = [_candidate, _class] call _resolveFinalPosition;
    if (count _position < 2) then {
        _planFailed = true;
        diag_log format ["[WMP DYNAMIC AA] '%1' placement failed for %2 %3 near %4.", _id, _kind, _class, _candidate];
    } else {
        _resolvedPlan pushBack [_kind, _class, _position, _direction, [_class, 8] call _classClearance];
    };
} forEach _assetPlan;
if (_planFailed || {count _resolvedPlan != count _assetPlan}) exitWith {
    ["Creation rejected: one or more selected AA components had no complete collision-free footprint. Try a more open location or fewer assets.", "ERROR"] call _reply;
    false
};
diag_log format ["[WMP DYNAMIC AA] '%1' resolved placement plan: %2", _id, _resolvedPlan apply {[_x select 0, _x select 1, _x select 2, _x select 4]}];

private _assignCrew = {
    params ["_vehicle", "_defence"];
    // Create the crew directly on the selected operational side. Creating config-side crew first,
    // then moving it into a second group, briefly published the wrong group and side on dedicated
    // servers and generated stale network objects for Zeus. The side form of createVehicleCrew
    // produces the final group in one operation.
    private _group = _side createVehicleCrew _vehicle;
    if (isNull _group || {count crew _vehicle == 0} || {side _group != _side}) exitWith {
        diag_log format [
            "[WMP DYNAMIC AA] Crew creation failed: vehicle=%1 requestedSide=%2 group=%3 actualSide=%4 crew=%5.",
            typeOf _vehicle, _side, _group, side _group, count crew _vehicle
        ];
        grpNull
    };
    _groups pushBackUnique _group;
    if (_defence) then {
        [_group, false] call Waldo_fnc_DynamicAASetGroupState;
        _defenceGroups pushBackUnique _group;
    } else {
        _group setCombatMode "RED";
    };
    _group
};
private _radars = [];
private _spawnFailed = false;
{
    _x params ["_kind", "_class", "_position", "_direction"];
    private _vehicle = createVehicle [_class, _position, [], 0, "CAN_COLLIDE"];
    if (isNull _vehicle) then {
        _spawnFailed = true;
    } else {
        _vehicle setPosATL _position;
        _vehicle setDir _direction;
        _objects pushBack _vehicle;
        if (_kind == "RADAR") then {
            _radars pushBack _vehicle;
            if (_vehicle isKindOf "AllVehicles") then {
                private _crewGroup = [_vehicle, false] call _assignCrew;
                if (isNull _crewGroup) then {_spawnFailed = true} else {_vehicle setVehicleRadar 1};
            };
        } else {
            _vehicle setVehicleAmmo (((_config getOrDefault ["initialAmmoFraction", 1]) max 0) min 1);
            private _crewGroup = [_vehicle, true] call _assignCrew;
            if (isNull _crewGroup) then {_spawnFailed = true};
        };
    };
} forEach _resolvedPlan;
if (_spawnFailed || {count _radars == 0}) exitWith {
    {{if (!isNull _x) then {deleteVehicle _x}} forEach crew _x; deleteVehicle _x} forEach _objects;
    {{if (!isNull _x) then {deleteVehicle _x}} forEach units _x; deleteGroup _x} forEach _groups;
    ["Creation failed while materialising the validated AA plan; all partial assets were removed.", "ERROR"] call _reply;
    false
};
private _radar = _radars select 0;

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
    private _markerText = if (_config getOrDefault ["showMarkerDetails", true]) then {
        format ["%1 - range %2m / floor %3m / ceiling %4m", _displayName, round _radius, round _minimumAltitude, round _maximumAltitude]
    } else {
        _displayName
    };
    _iconMarker setMarkerText _markerText;
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
// Newly created network objects are not guaranteed to be available to curator replication in the
// same simulation frame. Adding vehicles and every crew unit immediately (then asking includeCrew
// to add those units a second time) produced Type_112/116 "Object not found" traffic on dedicated
// servers and stale Zeus entries. Defer one frame and add each root asset once; includeCrew supplies
// its crew after the objects have valid network identities.
[+_objects] spawn {
    params ["_assets"];
    sleep 0.1;
    _assets = _assets select {!isNull _x};
    {_x addCuratorEditableObjects [_assets, true]} forEach allCurators;
};
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
diag_log format [
    "[WMP DYNAMIC AA] '%1' (%2) active: side=%3 crewSides=%4 detection=%5m engagement=%6m altitude=%7-%8m %9 assetPool=%10.",
    _displayName, _id, _side, _groups apply {side _x}, _radius, _engagementRadius,
    _minimumAltitude, _maximumAltitude, _config getOrDefault ["altitudeMode", "AUTO"],
    _config get "resolvedAssetPool"
];
[format ["%1 is active with %2 radar(s), %3 static position(s), %4 mobile position(s) and %5 fighter(s) per wave.", _displayName, count _radars, count (_config getOrDefault ["staticPositions", []]), count (_config getOrDefault ["mobilePositions", []]), _fighterCount], "SUCCESS"] call _reply;
true
