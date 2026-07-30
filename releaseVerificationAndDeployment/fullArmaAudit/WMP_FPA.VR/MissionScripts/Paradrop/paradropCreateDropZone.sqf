/*
 * Author: WaldoTheWarfighter
 * Creates one server-authoritative AI paradrop run and its optional map symbology.
 *
 * Operational side controls crew and generated jumper allegiance; airframe class is deliberately
 * independent. The server owns registry, groups, waypoints, jump timing and cleanup. Global Arma
 * markers provide normal JIP visibility without a custom replay layer. Repeat use is isolated by ID.
 *
 * Arguments:
 * 0: configuration <HASHMAP> - id, name, centre, direction, side, aircraftClass, altitude,
 *    maximumSpeed, approachDistance, runLength, exitDistance, jumperCount, jumpInterval,
 *    chuteClass, jumperClass, createJumpers, autoDropPlayers, createMarkers, deleteAfterRun.
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
private _approach = ((_config getOrDefault ["approachDistance", 2500]) max 800) min 10000;
private _runLength = ((_config getOrDefault ["runLength", 2500]) max 300) min 6000;
private _exitDistance = ((_config getOrDefault ["exitDistance", 2500]) max 800) min 10000;
private _standby = [_centre, _runLength * 0.65, _direction + 180] call BIS_fnc_relPos;
private _green = [_centre, _runLength * 0.5, _direction + 180] call BIS_fnc_relPos;
private _red = [_centre, _runLength * 0.5, _direction] call BIS_fnc_relPos;
private _spawn = [_standby, _approach, _direction + 180] call BIS_fnc_relPos;
private _exit = [_red, _exitDistance, _direction] call BIS_fnc_relPos;
{_x set [2, _altitude]} forEach [_standby, _green, _red, _spawn, _exit];

private _aircraft = createVehicle [_class, _spawn, [], 0, "FLY"];
_aircraft setPosATL _spawn;
_aircraft setDir _direction;
_aircraft setVelocityModelSpace [0, _maximumSpeed / 3.6, 0];
createVehicleCrew _aircraft;
if (isNull driver _aircraft) exitWith {deleteVehicle _aircraft; ["Creation failed: the selected airframe could not be crewed.", "ERROR"] call _notifyRequester; false};
private _oldGroups = [];
{_oldGroups pushBackUnique group _x} forEach crew _aircraft;
private _flightGroup = createGroup _side;
(crew _aircraft) joinSilent _flightGroup;
{if (!isNull _x && {count units _x == 0}) then {deleteGroup _x}} forEach _oldGroups;
_flightGroup setBehaviourStrong "CARELESS";
_flightGroup setCombatMode "BLUE";
_flightGroup setSpeedMode "LIMITED";
_aircraft flyInHeight [_altitude, true];
_aircraft limitSpeed _maximumSpeed;
_aircraft engineOn true;

{
    private _waypoint = _flightGroup addWaypoint [_x, 0];
    _waypoint setWaypointType "MOVE";
    _waypoint setWaypointBehaviour "CARELESS";
    _waypoint setWaypointCombatMode "BLUE";
    _waypoint setWaypointSpeed "LIMITED";
    _waypoint setWaypointCompletionRadius 100;
} forEach [_standby, _green, _red, _exit];

private _jumpers = [];
private _jumpGroup = grpNull;
if (_config getOrDefault ["createJumpers", true]) then {
    private _jumperClass = _config getOrDefault ["jumperClass", switch (_side) do {case east: {"O_Soldier_F"}; case independent: {"I_Soldier_F"}; default {"B_Soldier_F"}}];
    if !(isClass (configFile >> "CfgVehicles" >> _jumperClass) && {_jumperClass isKindOf "CAManBase"}) then {
        _jumperClass = switch (_side) do {case east: {"O_Soldier_F"}; case independent: {"I_Soldier_F"}; default {"B_Soldier_F"}};
    };
    _jumpGroup = createGroup _side;
    private _capacity = _aircraft emptyPositions "cargo";
    private _count = ((round (_config getOrDefault ["jumperCount", 20])) max 0) min _capacity min 60;
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
    ["jumpers", _jumpers], ["jumpGroup", _jumpGroup], ["markers", _markers], ["green", _green], ["red", _red],
    ["config", _config], ["active", true], ["createdAt", serverTime]
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
        private _chute = _config getOrDefault ["chuteClass", "NonSteerable_Parachute_F"];
        {
            if (_aircraft distance2D _red <= 150) exitWith {
                diag_log format ["[WMP PARADROP] Red line reached; remaining jumpers retained id=%1", _id];
            };
            if (!isNull _x && {alive _x} && {vehicle _x == _aircraft}) then {
                [_x, _aircraft, _chute] remoteExec ["Waldo_fnc_StaticJumpFunc", owner _x];
                sleep _interval;
            };
        } forEach _dropUnits;
    };
    waitUntil {sleep 1; isNull _aircraft || {!alive _aircraft} || {currentWaypoint _flightGroup >= 4} || {serverTime >= _deadline}};
    if (_config getOrDefault ["deleteAfterRun", false]) then {[_id, true, objNull] call Waldo_fnc_ParadropRemoveDropZone};
};
diag_log format ["[WMP PARADROP] Created id=%1 name=%2 side=%3 airframe=%4 jumpers=%5 markers=%6", _id, _name, _side, _class, count _jumpers, count _markers];
[format ["%1 created with %2 generated jumpers. The aircraft will begin its approach immediately.", _name, count _jumpers], "SUCCESS"] call _notifyRequester;
true
