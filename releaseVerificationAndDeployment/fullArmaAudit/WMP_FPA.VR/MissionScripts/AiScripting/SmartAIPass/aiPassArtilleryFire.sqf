/*
 * Author: WaldoTheWarfighter
 * Queues a finite mission of bounded bursts on the server. This is dispatch acceptance, not proof a shell fired.
 * Locality/authority: documented guards enforce server coordination and owner-local execution.
 * Repeat/JIP: mission tokens reject stale work; server state survives HC migration, not restart.
 * Arguments: 0: battery <OBJECT>, objNull selects a same-side gun for the spotter; 1: reported ATL <ARRAY>; 2: error <NUMBER>, 0; 3: mode <STRING>, HE; 4: rounds <NUMBER>, -1; 5: scoot <BOOL/NUMBER>, -1; 6: purpose <STRING>, SUPPORT; 7: spotter <OBJECT>, objNull; 8: enemy <OBJECT>, objNull.
 * Return Value: Boolean, request queued or accepted.
 * Current callers: ArtilleryRequest, CounterBattery, Retreat and server mission scripts.
 * Example: [_gun, _reportedPosition, 40] call Waldo_fnc_AIPassArtilleryFire;
 */
params [["_battery", objNull, [objNull]], ["_target", [], [[]]], ["_error", 0, [0]], ["_mode", "HE", [""]],
    ["_rounds", -1, [0]], ["_scoot", -1, [0, true]], ["_purpose", "SUPPORT", [""]], ["_spotter", objNull, [objNull]], ["_enemy", objNull, [objNull]]];
if (!isServer) exitWith {_this remoteExecCall ["Waldo_fnc_AIPassArtilleryFire", 2]; true};
if (remoteExecutedOwner > 2) then {
    // Only AI owners may forward these internal requests. Player clients use authenticated Zeus APIs.
    private _hc = allPlayers findIf {_x isKindOf "HeadlessClient_F" && {owner _x == remoteExecutedOwner}};
    if (_hc < 0 || {if (isNull _spotter) then {remoteExecutedOwner != owner _battery} else {remoteExecutedOwner != owner _spotter}}) then {_purpose = ""};
};
if (!(_purpose in ["SUPPORT", "COUNTER"]) || {!(_mode in ["HE", "SMOKE"])} || {count _target < 2} || {_target findIf {!(_x isEqualType 0)} >= 0}
    || {!(missionNamespace getVariable ["Waldo_AIPass_Active", false])} || {[] call Waldo_fnc_AIPassIsPaused}) exitWith {false};
private _counter = _purpose == "COUNTER";
private _feature = ["Waldo_AIPass_Artillery_Enable", "Waldo_AIPass_CounterBattery_Enable"] select _counter;
if (!isNull _spotter && {!([group _spotter,_feature,false] call Waldo_fnc_AIPassFeatureEnabled)}) exitWith {false};
if !(missionNamespace getVariable [["Waldo_AIPass_Artillery_Enable", "Waldo_AIPass_CounterBattery_Enable"] select _counter, false]) exitWith {false};
if (!isNull _spotter && {!alive _spotter || {!(_spotter getVariable ["Waldo_AIPass_Spotter", false])}}) exitWith {false};
if (!isNull _spotter && {time < (_spotter getVariable ["Waldo_AIPass_NextFireRequest_" + _purpose, -1])}) exitWith {false};
if (_counter && {!isNull _enemy} && {!isNull _spotter || {!isNull _battery}}) then {
    private _sideKey = str (if (isNull _spotter) then {side group gunner _battery} else {side group _spotter});
    if (time < (_enemy getVariable ["Waldo_AIPass_CounterUntil_" + _sideKey, -1])) then {_purpose = ""};
};
if (_purpose == "") exitWith {false};
private _missions = missionNamespace getVariable ["Waldo_AIPass_FireMissions", createHashMap];
if (isNull _battery) then {
    private _candidates = missionNamespace getVariable ["Waldo_AIPass_AllArtillery", []];
    private _index = _candidates findIf {
        alive _x && {alive gunner _x} && {side group gunner _x == side group _spotter}
        && {!((netId _x) in _missions)} && {[_x, _purpose] call Waldo_fnc_AIPassArtilleryRole}
        && {[group gunner _x] call Waldo_fnc_AIPassIsEligible}
        && {[group gunner _x,_feature,false] call Waldo_fnc_AIPassFeatureEnabled}
        && {_target inRangeOfArtillery [[_x], [_x, _mode == "SMOKE"] call Waldo_fnc_AIPassArtilleryAmmo]}
    };
    if (_index >= 0) then {_battery = _candidates select _index};
};
if (isNull _battery || {!alive gunner _battery} || {(netId _battery) in _missions}
    || {!([_battery, _purpose] call Waldo_fnc_AIPassArtilleryRole)}
    || {!([group gunner _battery] call Waldo_fnc_AIPassIsEligible)}
    || {!([group gunner _battery,_feature,false] call Waldo_fnc_AIPassFeatureEnabled)}
    || {!isNull _spotter && {side group _spotter != side group gunner _battery}}) exitWith {false};
private _magazine = [_battery, _mode == "SMOKE"] call Waldo_fnc_AIPassArtilleryAmmo;
if (_magazine == "") exitWith {false};
if (_rounds < 1) then {_rounds = missionNamespace getVariable [["Waldo_AIPass_Artillery_Rounds", "Waldo_AIPass_CounterBattery_Rounds"] select _counter, 3]};
if (_scoot isEqualType 0) then {_scoot = missionNamespace getVariable [["Waldo_AIPass_Artillery_ShootAndScoot", "Waldo_AIPass_CounterBattery_ShootAndScoot"] select _counter, true]};
private _serial = (missionNamespace getVariable ["Waldo_AIPass_FireSerial", 0]) + 1;
missionNamespace setVariable ["Waldo_AIPass_FireSerial", _serial];
private _token = format ["%1:%2", netId _battery, _serial];
private _mission = createHashMapFromArray [
    ["battery", _battery], ["key", netId _battery], ["token", _token], ["fix", [+_target, _error max 0]], ["mode", _mode], ["purpose", _purpose],
    ["spotter", _spotter], ["enemy", _enemy], ["remaining", (round _rounds max 1) min 10], ["fired", 0], ["burstSize", (round _rounds max 1) min 10],
    ["burstsLeft", if (_mode == "SMOKE") then {1} else {(round (missionNamespace getVariable ["Waldo_AIPass_Artillery_Bursts", 3]) max 1) min 5}],
    ["burstsCompleted", 0], ["opening", true], ["location", +_target],
    ["offset", [300, 0] select (_mode == "SMOKE")], ["bearing", random 360], ["magazine", _magazine],
    ["phase", "WAIT"], ["due", time], ["deadline", time + 900], ["scoot", _scoot], ["side", side group gunner _battery]
];
if (!isNull _spotter) then {_spotter setVariable ["Waldo_AIPass_NextFireRequest_" + _purpose, time + 900]};
if (_counter && {!isNull _enemy}) then {_enemy setVariable ["Waldo_AIPass_CounterUntil_" + str (side group gunner _battery), time + 900]};
_missions set [netId _battery, _mission];
missionNamespace setVariable ["Waldo_AIPass_FireMissions", _missions];
_battery setVariable ["Waldo_AIPass_FireToken", _token, true];
_battery setVariable ["Waldo_AIPass_BusyUntil", time + 900, true];
[Waldo_fnc_AIPassArtilleryMissionStep, _mission, 0] call Waldo_fnc_AIPassQueueJob;
true
