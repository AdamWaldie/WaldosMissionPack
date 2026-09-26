/*
 * Author: WaldoTheWarfighter
 * Registers mixed land convoys; speed <= 0 holds vehicles and unloads passengers. Release removes the controller.
 * Locality/authority: server validates requests and owns registry/baselines; each owner applies local effects.
 * Repeat/JIP: versioned snapshots include halt cargo and restoration data; reconfigure explicitly resumes travel.
 * Arguments: 0: group <GROUP>, grpNull; 1: maximum km/h <NUMBER>, 30; 2: separation metres <NUMBER>, 15;
 * 3: push through <BOOL>, true; 4: release controller without unloading <BOOL>, false.
 * Return Value: Boolean server acceptance; forwarded calls return dispatch acceptance.
 * Current callers: mission scripts, ConvoyHaltServer and authenticated convoy Zeus control.
 * Example: [convoyGroup, 0] call Waldo_fnc_SimpleAiConvoy; // hold and unload cargo, keep operating crew
 */
params [["_group", grpNull, [grpNull]], ["_speed", 30, [0]], ["_separation", 15, [0]], ["_pushThrough", true, [true]], ["_release", false, [true]]];
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
private _registry = +(missionNamespace getVariable ["Waldo_Convoy_Registry", []]);
private _oldIndex = _registry findIf {(_x select 0) == _group};
private _old = if (_oldIndex >= 0) then {(_registry select _oldIndex) select 1} else {[]};
if ((_release || {_speed <= 0}) && {_old isEqualTo []}) exitWith {false};
private _vehicles = [];
if (_speed > 0 && {!_release}) then {
    {private _v = vehicle _x; if (_v isKindOf "LandVehicle" && {!(_v isKindOf "StaticWeapon")} && {alive driver _v} && {group driver _v == _group}) then {_vehicles pushBackUnique _v}} forEach units _group;
};
if (_speed > 0 && {!_release} && {count _vehicles < ([1, 2] select (_old isEqualTo [])) || {count _vehicles > 20}
    || {_group getVariable ["Waldo_ServerOwnedFeature", false]} || {(units _group) findIf {isPlayer _x} >= 0}
    || {_vehicles findIf {(crew _x) findIf {isPlayer _x} >= 0 || {_x getVariable ["Waldo_ServerOwnedFeature", false]}
        || {_x getVariable ["Waldo_Convoy_Active", false] && {(_x getVariable ["Waldo_Convoy_Group", grpNull]) != _group}}} >= 0}}) exitWith {false};
if (!_release && {_speed <= 0} && {(_old param [5, "TRAVEL"]) == "HALT"}) exitWith {true};
private _revision = (_group getVariable ["Waldo_Convoy_Revision", 0]) + 1;
private _configuration = [];
if (!_release) then {
    if (_speed <= 0) then {
        _vehicles = _old select 4;
        private _cargo = [];
        {
            private _vehicle = _x;
            {
                _x params ["_unit", "_role", "", "", "_personTurret"];
                if (alive _unit && {!isPlayer _unit} && {_role == "cargo" || {_personTurret}}) then {_cargo pushBack [_unit, _vehicle]};
            } forEach fullCrew [_vehicle, "", false];
        } forEach _vehicles;
        _configuration = [_revision, _old select 1, _old select 2, _old select 3, _vehicles, "HALT", _cargo, _old select 7];
    } else {
        private _lead = vehicle leader _group;
        if (_lead in _vehicles) then {_vehicles = [_lead] + (_vehicles - [_lead])};
        private _restore = if (_old isEqualTo []) then {[formation _group, attackEnabled _group, []]} else {+(_old select 7)};
        private _saved = +(_restore select 2);
        {
            private _vehicle = _x;
            if (_saved findIf {(_x select 0) == _vehicle} < 0) then {_saved pushBack [_vehicle, getForcedSpeed _vehicle, getUnloadInCombat _vehicle]};
        } forEach _vehicles;
        _restore set [2, _saved];
        _configuration = [_revision, (_speed max 5) min 120, (_separation max 10) min 100, _pushThrough, _vehicles, "TRAVEL", [], _restore];
    };
};
_registry = _registry select {!isNull (_x select 0) && {(_x select 0) != _group}};
if (!_release) then {
    _registry pushBack [_group, _configuration];
    {
        _x setVariable ["Waldo_Convoy_Group", _group, true];
        _x setVariable ["Waldo_Convoy_Active", true, true];
    } forEach (_configuration select 4);
};
_group setVariable ["Waldo_Convoy_Revision", _revision, true];
_group setVariable ["Waldo_Convoy_Active", !_release, true];
_group setVariable ["Waldo_Convoy_ContactProgress", nil, true];
missionNamespace setVariable ["Waldo_Convoy_Registry", _registry];
private _registryRevision = (missionNamespace getVariable ["Waldo_Convoy_RegistryRevision", 0]) + 1;
missionNamespace setVariable ["Waldo_Convoy_RegistryRevision", _registryRevision];
[_registryRevision, _registry] remoteExecCall ["Waldo_fnc_ConvoySync", 0, "Waldo_Convoy_RegistrySync"];
true
