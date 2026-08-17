/*
 * Author: WaldoTheWarfighter
 * Validates and applies squad-leader rally deployment, removal and regroup operations on the server.
 *
 * The server owns cooldown, active object, safe respawn position, BIS respawn handle and expiry.
 * Player requests must originate from the owner of the supplied actor. Deployment rejects water,
 * steep ground, nearby enemies, insufficient group strength and blocked object/respawn positions.
 * Regroup and respawn never fall back to the rally object's centre.
 *
 * Arguments:
 * 0: actor <OBJECT> - requesting player unit.
 * 1: operation <STRING> - DEPLOY, REMOVE or REGROUP.
 *
 * Return Value: Boolean - true when the operation was accepted; otherwise false.
 *
 * Example:
 * [player, "DEPLOY"] remoteExecCall ["Waldo_fnc_RallyPointRequestServer", 2];
 *
 * Current callers: RallyPointSetupLocal self-actions and hold-action callbacks.
 */
params [["_actor", objNull, [objNull]], ["_operation", "", [""]]];
if (!isServer) exitWith {_this remoteExecCall ["Waldo_fnc_RallyPointRequestServer", 2]; false};
if (isNull _actor || {!alive _actor}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner != owner _actor}) exitWith {false};
private _group = group _actor;
if (isNull _group) exitWith {false};
private _authority = missionNamespace getVariable ["Waldo_Rally_ServerAuthority", ""];
if (_authority isEqualTo "") then {
    _authority = format ["%1_%2_%3", serverTime, random 1e12, diag_tickTime];
    missionNamespace setVariable ["Waldo_Rally_ServerAuthority", _authority];
};
_operation = toUpperANSI _operation;
if (_operation == "REGROUP") exitWith {
    if !(missionNamespace getVariable ["Waldo_Rally_Enable", false] && {missionNamespace getVariable ["Waldo_Rally_AllowRegroup", false]}) exitWith {false};
    private _rally = _group getVariable ["Waldo_Rally_Object", objNull];
    if (isNull _rally || {vehicle _actor != _actor}) exitWith {false};
    private _destination = [_rally, typeOf _actor] call Waldo_fnc_RallyPointResolveSafePosition;
    if (_destination isEqualTo []) exitWith {
        ["No safe open position is available around the squad rally.", "WARNING"] remoteExecCall ["Waldo_fnc_RallyPointNotifyLocal", owner _actor];
        false
    };
    if (local _actor) then {
        [_actor, _destination] call Waldo_fnc_RallyPointMoveLocal;
    } else {
        [_actor, _destination] remoteExecCall ["Waldo_fnc_RallyPointMoveLocal", owner _actor];
    };
    diag_log format ["[WMP RALLY] Regroup authorised unit=%1 destination=%2 actorOwner=%3 serverLocal=%4", name _actor, _destination, owner _actor, local _actor];
    ["Redeployed at the active squad rally.", "SUCCESS"] remoteExecCall ["Waldo_fnc_RallyPointNotifyLocal", owner _actor];
    true
};
if (_actor != leader _group) exitWith {["Only the current squad leader may manage the rally point.", "WARNING"] remoteExecCall ["Waldo_fnc_RallyPointNotifyLocal", owner _actor]; false};
if (_operation == "REMOVE") exitWith {[_group, "Squad rally packed by the squad leader.", "INFO", _authority] spawn Waldo_fnc_RallyPointRemoveServer; true};
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
private _rallySeed = "Land_SatelliteAntenna_01_F";
private _objectClass = missionNamespace getVariable ["Waldo_Rally_ObjectClass", _rallySeed];
// Waldo_Rally_ObjectClass is a single fixed classname, not a dropdown - there is nothing to "extend"
// the way Dynamic AA/Gunship/Paradrop's class lists are extended. What still matters here is not
// silently trying to spawn a class that does not exist (a mod removed/renamed, or a typo) - fall
// back to another public class inheriting from the vanilla seed, discovered live in the running
// modset, before giving up on the seed itself.
if !(isClass (configFile >> "CfgVehicles" >> _objectClass)) then {
    private _fallbackPool = ["RALLY_OBJECT", {
        isClass (configFile >> "CfgVehicles" >> _this)
        && {getNumber (configFile >> "CfgVehicles" >> _this >> "scope") >= 2}
        && {_this isKindOf _rallySeed}
    }] call Waldo_fnc_ResolveVehicleClassPool;
    private _resolved = if (count _fallbackPool > 0) then {(_fallbackPool select 0) select 0} else {_rallySeed};
    diag_log format ["[WMP RALLY] Configured Waldo_Rally_ObjectClass='%1' does not exist; falling back to '%2'.", _objectClass, _resolved];
    _objectClass = _resolved;
};
private _position = [];
private _origin = getPosATL _actor;
private _maximumSlope = missionNamespace getVariable ["Waldo_Rally_MaximumSlope", 20];
// A zero-result findEmptyPosition call is not sufficient evidence that the entire deployment area
// is blocked. Probe short rings in the leader's facing direction first, then reject real objects,
// water and excessive slope explicitly. This remains bounded and server-authoritative.
for "_radius" from (_deployDistance max 2) to 10 step 1.5 do {
    {
        private _candidate = [_origin, _radius, (getDir _actor) + _x] call BIS_fnc_relPos;
        _candidate set [2, 0];
        if !(surfaceIsWater _candidate) then {
            private _exact = _candidate findEmptyPosition [0, 0, _objectClass];
            if (_exact isEqualTo []) then {_exact = +_candidate};
            private _slope = acos ((((surfaceNormal _exact) select 2) max -1) min 1);
            private _blockers = (nearestObjects [_exact, [], 1.5, true]) select {
                _x != _actor
            };
            if (_slope <= _maximumSlope && {count _blockers == 0}) exitWith {_position = _exact};
        };
    } forEach [0, 45, -45, 90, -90, 135, -135, 180];
    if !(_position isEqualTo []) exitWith {};
};
if (_position isEqualTo []) exitWith {["No clear rally position was found.", "WARNING"] remoteExecCall ["Waldo_fnc_RallyPointNotifyLocal", owner _actor]; false};
private _rally = createVehicle [_objectClass, _position, [], 0, "CAN_COLLIDE"];
_rally setDir getDir _actor;
_rally setVariable ["Waldo_Rally_Group", _group, true];
private _respawnPosition = [_rally, typeOf _actor] call Waldo_fnc_RallyPointResolveSafePosition;
if (_respawnPosition isEqualTo []) exitWith {
    deleteVehicle _rally;
    ["The rally object fits, but no safe player respawn position is available nearby.", "WARNING"] remoteExecCall ["Waldo_fnc_RallyPointNotifyLocal", owner _actor];
    false
};
private _label = format ["%1 Rally", groupId _group];
private _respawn = [_group, _respawnPosition, _label] call BIS_fnc_addRespawnPosition;
if !(_respawn isEqualType [] && {count _respawn == 2} && {(_respawn select 1) isEqualType 0} && {(_respawn select 1) >= 0}) exitWith {
    diag_log format ["[WMP RALLY] Respawn registration failed group=%1 position=%2 handle=%3", groupId _group, _respawnPosition, _respawn];
    deleteVehicle _rally;
    ["The rally object was placed, but its respawn position could not be registered.", "ERROR"] remoteExecCall ["Waldo_fnc_RallyPointNotifyLocal", owner _actor];
    false
};
diag_log format ["[WMP RALLY] Deployed group=%1 objectPosition=%2 respawnPosition=%3 respawnHandle=%4", groupId _group, _position, _respawnPosition, _respawn];
private _markerColour = switch (_side) do {case west: {"ColorWEST"}; case east: {"ColorEAST"}; case independent: {"ColorGUER"}; default {"ColorCIV"}};
private _duration = missionNamespace getVariable ["Waldo_Rally_Duration", 180];
private _token = format ["%1_%2", serverTime, random 1e9];
_group setVariable ["Waldo_Rally_Active", true, true];
_group setVariable ["Waldo_Rally_Object", _rally, true];
_group setVariable ["Waldo_Rally_ExpiresAt", serverTime + _duration, true];
_group setVariable ["Waldo_Rally_CooldownUntil", serverTime + (missionNamespace getVariable ["Waldo_Rally_Cooldown", 300]), true];
_group setVariable ["Waldo_Rally_RespawnHandle", _respawn];
_group setVariable ["Waldo_Rally_RespawnPosition", _respawnPosition, true];
_group setVariable ["Waldo_Rally_Token", _token];
[_rally, _group, _label, _markerColour] remoteExecCall ["Waldo_fnc_RallyPointMarkerLocal", 0, _rally];
[format ["Rally deployed for %1 seconds.", round _duration], "SUCCESS"] remoteExecCall ["Waldo_fnc_RallyPointNotifyLocal", units _group];
[_group, _token, _rally, _respawn, _authority] spawn {
    params ["_group", "_token", "_rally", "_respawn", "_authority"];
    waitUntil {
        sleep 2;
        isNull _group || {!(_group getVariable ["Waldo_Rally_Active", false])}
        || {(_group getVariable ["Waldo_Rally_Token", ""]) != _token}
        || {serverTime >= (_group getVariable ["Waldo_Rally_ExpiresAt", 0])}
        || {isNull _rally || {!alive _rally}}
    };
    if (isNull _group) exitWith {
        if (_respawn isEqualType [] && {count _respawn == 2}) then {_respawn call BIS_fnc_removeRespawnPosition};
        if (!isNull _rally) then {deleteVehicle _rally};
    };
    if ((_group getVariable ["Waldo_Rally_Token", ""]) == _token && {_group getVariable ["Waldo_Rally_Active", false]}) then {
        [_group, "Squad rally is no longer available.", "WARNING", _authority] call Waldo_fnc_RallyPointRemoveServer;
    };
};
true
