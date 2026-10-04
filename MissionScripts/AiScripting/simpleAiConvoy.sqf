/*
 * Author: WaldoTheWarfighter
 * Registers mixed land convoys; speed <= 0 holds vehicles and unloads passengers except a STALLED recovery halt. Release removes the controller.
 * Locality/authority: server validates requests and owns registry/baselines; each owner applies local effects.
 * Repeat/JIP: versioned snapshots include halt cargo and restoration data; reconfigure explicitly resumes travel.
 * If HBQ Advanced Driving AI is present, WMP temporarily pauses its steering/unstuck worker and
 * crew-return option on controlled vehicles, then restores each exact prior variable state on release.
 * Accepted halt transitions notify assigned Zeus players once through the shared UI; no historical JIP alerts.
 * Arguments: 0: group <GROUP>, grpNull; 1: maximum km/h <NUMBER>, 30; 2: separation metres <NUMBER>, 30;
 * 3: push through <BOOL>, true; 4: release controller without unloading <BOOL>, false;
 * 5: halt context <ARRAY>, [] of named reason/threat pairs, used by ConvoyHaltServer.
 * Return Value: Boolean server acceptance; forwarded calls return dispatch acceptance.
 * Current callers: mission scripts, ConvoyHaltServer and authenticated convoy Zeus control.
 * Example: [convoyGroup, 0] call Waldo_fnc_SimpleAiConvoy; // hold and unload cargo, keep operating crew
 */
params [["_group", grpNull, [grpNull]], ["_speed", 30, [0]], ["_separation", 30, [0]], ["_pushThrough", true, [true]], ["_release", false, [true]], ["_haltContext", [], [[]]]];
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
if (_haltContext findIf {!(_x isEqualType []) || {count _x != 2} || {!((_x select 0) isEqualType "")}} >= 0) exitWith {false};
private _context = createHashMapFromArray _haltContext;
private _reason = _context getOrDefault ["reason", "MANUAL"];
private _threat = _context getOrDefault ["threat", []];
private _blockedVehicle = _context getOrDefault ["blockedVehicle",objNull];
if !(_blockedVehicle isEqualType objNull) exitWith {false};
if (!(_reason in ["MANUAL", "ARRIVED", "AMBUSH", "IMMOBILE", "STALLED"]) || {!(_threat isEqualType [])}
    || {!(count _threat in [0, 3])} || {_threat findIf {!(_x isEqualType 0)} >= 0}) exitWith {false};
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
                if (_reason != "STALLED" && {alive _unit} && {!isPlayer _unit} && {_role == "cargo" || {_role == "turret" && {_personTurret}}}) then {_cargo pushBack [_unit, _vehicle]};
            } forEach fullCrew [_vehicle, "", false];
        } forEach _vehicles;
        _configuration = [_revision, _old select 1, _old select 2, _old select 3, _vehicles, "HALT", _cargo, _old select 7, _reason, +_threat, serverTime + 45];
    } else {
        private _lead = vehicle leader _group;
        if (_lead in _vehicles) then {_vehicles = [_lead] + (_vehicles - [_lead])};
        private _restore = if (_old isEqualTo []) then {[formation _group, attackEnabled _group, []]} else {+(_old select 7)};
        private _saved = +(_restore select 2);
        {
            private _vehicle = _x;
            if (_saved findIf {(_x select 0) == _vehicle} < 0) then {
                private _hbqPause = if (isNil {_vehicle getVariable "HBQAD_Pause"}) then {[false,false]} else {[true,_vehicle getVariable ["HBQAD_Pause",false]]};
                private _hbqCrew = if (isNil {_vehicle getVariable "HBQAD_PreventDisembark"}) then {[false,false]} else {[true,_vehicle getVariable ["HBQAD_PreventDisembark",false]]};
                _saved pushBack [_vehicle, getForcedSpeed _vehicle, getUnloadInCombat _vehicle, [_hbqPause,_hbqCrew]];
            };
            // HBQ's public live pause stops obstacle, traffic and unstuck movement without disabling
            // its addon. Its separate crew loop does not read Pause, so WMP also suspends only that
            // per-vehicle option while WMP owns seat and dismount semantics.
            if (isClass (configFile >> "CfgPatches" >> "hbq_advanced_driving_ai")) then {
                _vehicle setVariable ["HBQAD_Pause",true,true];
                _vehicle setVariable ["HBQAD_PreventDisembark",false,true];
            };
        } forEach _vehicles;
        _restore set [2, _saved];
        _configuration = [_revision, (_speed max 5) min 120, (_separation max 10) min 100, _pushThrough, _vehicles, "TRAVEL", [], _restore, "NONE", [], 0];
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
// Report accepted state transitions, not repeated ticks or duplicate halt requests.
if (!_release && {_speed <= 0}) then {
    private _description = switch (_reason) do {
        case "ARRIVED": {"Destination reached"};
        case "AMBUSH": {"Halted by contact"};
        case "IMMOBILE": {"No mobile controlled vehicle remains"};
        case "STALLED": {"Movement recovery exhausted; inspect obstruction and issue a resume or new route"};
        default {"Halted by order"};
    };
    private _lead = if (_reason == "STALLED" && {_blockedVehicle in (_old select 4)}) then {_blockedVehicle} else {(_old select 4) param [0,objNull]};
    if (_reason == "STALLED" && {!isNull _lead}) then {_description = _description + format [" (%1)",getText (configOf _lead >> "displayName")]};
    private _location = if (isNull _lead) then {"unknown"} else {mapGridPosition _lead};
    private _recipients = [];
    {
        private _curator = getAssignedCuratorUnit _x;
        if (!isNull _curator && {isPlayer _curator}) then {_recipients pushBackUnique owner _curator};
    } forEach allCurators;
    {
        ["CORTEX CONVOY STOPPED",format ["%1 — %2. Grid %3. %4",groupId _group,_description,_location,["Cargo dismount ordered; operating crew stays aboard.","Passengers and operating crew remain aboard."] select (_reason == "STALLED")],
            "WARNING",format ["CORTEX_CONVOY_%1",netId _group],10] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal",_x];
    } forEach _recipients;
};
true
