/*
 * Author: WaldoTheWarfighter
 * Registers or updates a bounded mission-script convoy without pinning it to the server. Speed <= 0 stops it.
 * Locality/authority: server owns registration; driving commands execute only on current owners.
 * Repeat/JIP: ordered registry snapshots replace old settings; owner-local paths rebuild on migration.
 * Arguments: 0: group <GROUP>, grpNull; 1: maximum km/h <NUMBER>, 30; 2: separation metres <NUMBER>, 15; 3: push through <BOOL>, true.
 * Return Value: Boolean, server registration accepted; a forwarded call returns dispatch acceptance.
 * Current callers: mission scripts and authenticated convoy Zeus control.
 * Example: [convoyGroup, 30, 20, true] call Waldo_fnc_SimpleAiConvoy;
 */
params [["_group", grpNull, [grpNull]], ["_speed", 30, [0]], ["_separation", 15, [0]], ["_pushThrough", true, [true]]];
if (!isServer) exitWith {_this remoteExecCall ["Waldo_fnc_SimpleAiConvoy", 2]; true};
if (isNull _group) exitWith {false};
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) then {
    private _sender = remoteExecutedOwner;
    private _authorized = allPlayers findIf {owner _x == _sender && {
        !isNull getAssignedCuratorLogic _x || {_x isKindOf "HeadlessClient_F" && {groupOwner _group == _sender}}
    }};
    if (_authorized < 0) then {_group = grpNull};
};
if (isNull _group) exitWith {false};
private _registry = missionNamespace getVariable ["Waldo_Convoy_Registry", []];
_registry = _registry select {!isNull (_x select 0) && {(_x select 0) != _group}};
if (_speed > 0) then {
    if ((units _group) findIf {isPlayer _x} >= 0 || {_group getVariable ["Waldo_ServerOwnedFeature", false]}) exitWith {};
    private _vehicles = [];
    {private _v = vehicle _x; if (_v isKindOf "LandVehicle" && {!(_v isKindOf "StaticWeapon")} && {alive driver _v} && {group driver _v == _group}) then {_vehicles pushBackUnique _v}} forEach units _group;
    if (count _vehicles < 2 || {count _vehicles > 20} || {_vehicles findIf {(crew _x) findIf {isPlayer _x} >= 0 || {_x getVariable ["Waldo_ServerOwnedFeature", false]}} >= 0}) exitWith {};
    private _lead = vehicle leader _group;
    if (_lead in _vehicles) then {_vehicles = [_lead] + (_vehicles - [_lead])};
    private _revision = (_group getVariable ["Waldo_Convoy_Revision", 0]) + 1;
    _group setVariable ["Waldo_Convoy_Revision", _revision, true];
    _registry pushBack [_group, [_revision, (_speed max 5) min 120, (_separation max 10) min 100, _pushThrough, _vehicles]];
};
private _active = _registry findIf {(_x select 0) == _group} >= 0;
// A failed start must not silently stop an existing registration.
if (_speed > 0 && {!_active}) exitWith {false};
_group setVariable ["Waldo_Convoy_Active", _active, true];
missionNamespace setVariable ["Waldo_Convoy_Registry", _registry];
private _revision = (missionNamespace getVariable ["Waldo_Convoy_RegistryRevision", 0]) + 1;
missionNamespace setVariable ["Waldo_Convoy_RegistryRevision", _revision];
[_revision, _registry] remoteExecCall ["Waldo_fnc_ConvoySync", 0, "Waldo_Convoy_RegistrySync"];
true
