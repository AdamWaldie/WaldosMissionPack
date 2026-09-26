/*
 * Author: WaldoTheWarfighter
 * Accepts the pending observer result only from its expected and current owner.
 * Locality/authority: documented guards enforce server coordination and owner-local execution.
 * Repeat/JIP: mission tokens reject stale work; server state survives HC migration, not restart.
 * Arguments: 0: battery <OBJECT>; 1: token <STRING>; 2: spotter <OBJECT>; 3: fix <ARRAY>.
 * Return Value: Nothing.
 * Current callers: ArtilleryObserve.
 * Example: [_gun, _token, _spotter, []] remoteExecCall ["Waldo_fnc_AIPassArtilleryReport", 2];
 */
params ["_battery", "_token", "_spotter", "_fix"];
if (!isServer || {isNull _battery}) exitWith {};
private _mission = (missionNamespace getVariable ["Waldo_AIPass_FireMissions", createHashMap]) getOrDefault [netId _battery, createHashMap];
if (count _mission == 0 || {(_mission get "token") != _token} || {(_mission get "phase") != "OBSERVE"}
    || {_spotter != (_mission get "spotter")} || {remoteExecutedOwner != (_mission get "observerOwner")}
    || {remoteExecutedOwner != owner _spotter}) exitWith {};
if (count _fix == 2 && {alive _spotter} && {_spotter getVariable ["Waldo_AIPass_Spotter", false]}
    && {(_fix select 0) isEqualType []} && {count (_fix select 0) == 3} && {(_fix select 1) isEqualType 0}
    && {(_fix select 1) <= (missionNamespace getVariable [["Waldo_AIPass_Artillery_MaxError", "Waldo_AIPass_CounterBattery_MaxError"] select ((_mission get "purpose") == "COUNTER"), 50])}) then {
    _mission set ["fix", _fix];
    private _moved = (_fix select 0) distance2D (_mission get "location") >= (missionNamespace getVariable ["Waldo_AIPass_Artillery_LocationResetDistance", 150]);
    if (_moved) then {
        _mission set ["location", +(_fix select 0)];
        _mission set ["offset", 300];
        _mission set ["opening", true];
        _mission set ["bearing", random 360];
    } else {
        if ((_mission get "burstsCompleted") > 0) then {
            _mission set ["offset", ((_mission get "offset") * 0.55) max 40];
            _mission set ["opening", false];
        };
    };
};
_mission set ["phase", "READY"];
