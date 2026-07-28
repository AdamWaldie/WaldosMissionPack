/* Validates and applies squad-leader rally operations on the server. */
params [["_actor", objNull, [objNull]], ["_operation", "", [""]]];
if (!isServer) exitWith {_this remoteExecCall ["Waldo_fnc_RallyPointRequestServer", 2]; false};
if (isNull _actor || {!alive _actor}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner != owner _actor}) exitWith {false};
private _group = group _actor;
if (isNull _group) exitWith {false};
_operation = toUpperANSI _operation;
if (_operation == "REGROUP") exitWith {
    if !(missionNamespace getVariable ["Waldo_Rally_Enable", false] && {missionNamespace getVariable ["Waldo_Rally_AllowRegroup", false]}) exitWith {false};
    private _rally = _group getVariable ["Waldo_Rally_Object", objNull];
    if (isNull _rally || {vehicle _actor != _actor}) exitWith {false};
    private _destination = (getPosATL _rally) findEmptyPosition [2, 15, typeOf _actor];
    if (_destination isEqualTo []) then {_destination = getPosATL _rally};
    [_actor, _destination] remoteExecCall ["Waldo_fnc_RallyPointMoveLocal", owner _actor];
    ["Redeployed at the active squad rally.", "SUCCESS"] remoteExecCall ["Waldo_fnc_RallyPointNotifyLocal", owner _actor];
    true
};
if (_actor != leader _group) exitWith {["Only the current squad leader may manage the rally point.", "WARNING"] remoteExecCall ["Waldo_fnc_RallyPointNotifyLocal", owner _actor]; false};
if (_operation == "REMOVE") exitWith {[_group, "Squad rally packed by the squad leader.", "INFO"] spawn Waldo_fnc_RallyPointRemoveServer; true};
if (_operation != "DEPLOY" || {!(missionNamespace getVariable ["Waldo_Rally_Enable", false])}) exitWith {false};
if (_group getVariable ["Waldo_Rally_Active", false]) exitWith {["This squad already has an active rally point.", "WARNING"] remoteExecCall ["Waldo_fnc_RallyPointNotifyLocal", owner _actor]; false};
private _cooldownUntil = _group getVariable ["Waldo_Rally_CooldownUntil", -1];
if (serverTime < _cooldownUntil) exitWith {
    [format ["Rally deployment is available in %1 seconds.", ceil (_cooldownUntil - serverTime)], "WARNING"] remoteExecCall ["Waldo_fnc_RallyPointNotifyLocal", owner _actor]; false
};
if (vehicle _actor != _actor || {surfaceIsWater getPosWorld _actor}) exitWith {["Deploy on foot over dry ground.", "WARNING"] remoteExecCall ["Waldo_fnc_RallyPointNotifyLocal", owner _actor]; false};
private _minimumMembers = missionNamespace getVariable ["Waldo_Rally_MinimumGroupMembers", 2];
if ({alive _x} count units _group < _minimumMembers) exitWith {[format ["At least %1 living squad members are required.", _minimumMembers], "WARNING"] remoteExecCall ["Waldo_fnc_RallyPointNotifyLocal", owner _actor]; false};
private _enemyRadius = missionNamespace getVariable ["Waldo_Rally_EnemyExclusionRadius", 100];
private _side = side _group;
private _enemyNear = allUnits findIf {alive _x && {_side getFriend side group _x < 0.6} && {_x distance2D _actor < _enemyRadius}};
if (_enemyNear >= 0) exitWith {[format ["Hostile forces are within %1 metres.", round _enemyRadius], "WARNING"] remoteExecCall ["Waldo_fnc_RallyPointNotifyLocal", owner _actor]; false};
private _deployDistance = missionNamespace getVariable ["Waldo_Rally_PlacementDistance", 2];
private _candidate = [getPosATL _actor, _deployDistance, getDir _actor] call BIS_fnc_relPos;
private _objectClass = missionNamespace getVariable ["Waldo_Rally_ObjectClass", "Land_SatelliteAntenna_01_F"];
private _position = _candidate findEmptyPosition [0, 8, _objectClass];
if (_position isEqualTo []) exitWith {["No clear rally position was found.", "WARNING"] remoteExecCall ["Waldo_fnc_RallyPointNotifyLocal", owner _actor]; false};
private _normal = surfaceNormal _position;
private _maximumSlope = missionNamespace getVariable ["Waldo_Rally_MaximumSlope", 20];
if (acos ((_normal select 2) max -1 min 1) > _maximumSlope) exitWith {["The ground is too steep for a rally point.", "WARNING"] remoteExecCall ["Waldo_fnc_RallyPointNotifyLocal", owner _actor]; false};
private _rally = createVehicle [_objectClass, _position, [], 0, "CAN_COLLIDE"];
_rally setDir getDir _actor;
_rally setVariable ["Waldo_Rally_Group", _group, true];
private _label = format ["%1 Rally", groupId _group];
private _respawn = [_group, _position, _label] call BIS_fnc_addRespawnPosition;
private _markerColour = switch (_side) do {case west: {"ColorWEST"}; case east: {"ColorEAST"}; case independent: {"ColorGUER"}; default {"ColorCIV"}};
private _duration = missionNamespace getVariable ["Waldo_Rally_Duration", 180];
private _token = format ["%1_%2", serverTime, random 1e9];
_group setVariable ["Waldo_Rally_Active", true, true];
_group setVariable ["Waldo_Rally_Object", _rally, true];
_group setVariable ["Waldo_Rally_ExpiresAt", serverTime + _duration, true];
_group setVariable ["Waldo_Rally_CooldownUntil", serverTime + (missionNamespace getVariable ["Waldo_Rally_Cooldown", 300]), true];
_group setVariable ["Waldo_Rally_RespawnHandle", _respawn];
_group setVariable ["Waldo_Rally_Token", _token];
[_rally, _group, _label, _markerColour] remoteExecCall ["Waldo_fnc_RallyPointMarkerLocal", 0, _rally];
[format ["Rally deployed for %1 seconds.", round _duration], "SUCCESS"] remoteExecCall ["Waldo_fnc_RallyPointNotifyLocal", units _group];
[_group, _token, _rally, _respawn] spawn {
    params ["_group", "_token", "_rally", "_respawn"];
    waitUntil {
        sleep 2;
        isNull _group || {!(_group getVariable ["Waldo_Rally_Active", false])}
        || {(_group getVariable ["Waldo_Rally_Token", ""]) != _token}
        || {serverTime >= (_group getVariable ["Waldo_Rally_ExpiresAt", 0])}
        || {isNull _rally || {!alive _rally}}
    };
    if (isNull _group) exitWith {
        if !(_respawn isEqualTo []) then {_respawn call BIS_fnc_removeRespawnPosition};
        if (!isNull _rally) then {deleteVehicle _rally};
    };
    if ((_group getVariable ["Waldo_Rally_Token", ""]) == _token && {_group getVariable ["Waldo_Rally_Active", false]}) then {
        [_group, "Squad rally is no longer available.", "WARNING"] call Waldo_fnc_RallyPointRemoveServer;
    };
};
true
