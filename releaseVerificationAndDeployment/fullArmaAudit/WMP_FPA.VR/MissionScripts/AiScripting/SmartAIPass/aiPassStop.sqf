/*
 * Author: WaldoTheWarfighter
 * Stops the Smart AI Pass on this machine and hands every affected group back to its own orders.
 *
 * Removes the scheduler and every event handler and discards queued jobs. Every locally managed
 * group is released (Waldo_fnc_AIPassReleaseGroup): drills end with only the AI features they
 * disabled re-enabled, pass waypoints are removed, behaviour and speed are restored and LAMBS group AI
 * is handed back. Survivors still walking to a host get doFollow. Merges, surrenders and explicit
 * garrison orders that already happened are not undone; release a garrison with
 * Waldo_fnc_AIPassGarrisonRelease.
 * Locality and authority: the server clears Waldo_AIPass_Enable and the JIP key
 * Waldo_AIPass_RuntimeInit, then asks every other machine to stop. Remote calls from anything other
 * than the server are refused. Each machine handles only the groups it owns.
 *
 * Review contract: Repeat calls clear pending startup and abandoned airborne/clear jobs. Explicit garrison and defence orders remain and reapply after restart; tracked aircraft handlers are removed.
 *
 * Arguments: None.
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_AIPassStop;
 * Result: no further pass behaviour runs anywhere until Waldo_fnc_AIPassInit is called again.
 *
 * Current callers: the AI Control ZEN module.
 */

if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {};
if (isServer) then {
    missionNamespace setVariable ["Waldo_AIPass_Enable", false, true];
    {
        private _battery = _y get "battery";
        _battery setVariable ["Waldo_AIPass_FireToken", nil, true];
        _battery setVariable ["Waldo_AIPass_BusyUntil", nil, true];
    } forEach (missionNamespace getVariable ["Waldo_AIPass_FireMissions", createHashMap]);
    missionNamespace setVariable ["Waldo_AIPass_FireMissions", createHashMap];
    [] remoteExecCall ["", "Waldo_AIPass_RuntimeInit"];
    if (remoteExecutedOwner == 0) then {
        [] remoteExecCall ["Waldo_fnc_AIPassStop", -2];
    };
};
if (hasInterface && {!isServer}) exitWith {};
missionNamespace setVariable ["Waldo_AIPass_Active", false];
missionNamespace setVariable ["Waldo_AIPass_InitPending", false];

{
    private _handler = _x getVariable ["Waldo_AIPass_FlaresHandler", -1];
    if (_handler >= 0) then {_x removeEventHandler ["IncomingMissile", _handler]};
    _x setVariable ["Waldo_AIPass_FlaresHandler", nil];
    _x setVariable ["Waldo_AIPass_FlaresInstalled", nil];
} forEach (missionNamespace getVariable ["Waldo_AIPass_FlareVehicles", []]);
missionNamespace setVariable ["Waldo_AIPass_FlareVehicles", []];

private _handle = missionNamespace getVariable "Waldo_AIPass_SchedulerHandle";
if (!isNil "_handle") then {
    [_handle] call CBA_fnc_removePerFrameHandler;
    missionNamespace setVariable ["Waldo_AIPass_SchedulerHandle", nil];
};
{
    _x params ["_variable", "_event"];
    private _handler = missionNamespace getVariable _variable;
    if (!isNil "_handler") then {
        removeMissionEventHandler [_event, _handler];
        missionNamespace setVariable [_variable, nil];
    };
} forEach [
    ["Waldo_AIPass_KilledHandler", "EntityKilled"],
    ["Waldo_AIPass_ProjectileHandler", "ProjectileCreated"],
    ["Waldo_AIPass_ArtilleryHandler", "ArtilleryShellFired"]
];
{
    if (local _x && {count (_x getVariable ["Waldo_AIPass_State", createHashMap]) > 0 || {_x getVariable ["Waldo_AIPass_Managed", false]}}) then {
        [_x] call Waldo_fnc_AIPassReleaseGroup;
    };
    if (local _x) then {[_x] call Waldo_fnc_AIPassClearRelease};
    {
        private _unit = _x;
        {_unit removeEventHandler _x} forEach (_unit getVariable ["Waldo_AIPass_GarrisonHandlerIds", []]);
        _unit setVariable ["Waldo_AIPass_GarrisonHandlerIds", nil];
        _unit setVariable ["Waldo_AIPass_GarrisonHandlers", nil];
        _unit setVariable ["Waldo_AIPass_DuckUntil", nil];
    } forEach units _x;
    private _localHandler = _x getVariable ["Waldo_AIPass_LocalHandler", -1];
    if (_localHandler >= 0) then {_x removeEventHandler ["Local", _localHandler]};
    _x setVariable ["Waldo_AIPass_LocalHandler", nil];
    _x setVariable ["Waldo_AIPass_Adopted", nil];
    _x setVariable ["Waldo_AIPass_Epoch", (_x getVariable ["Waldo_AIPass_Epoch", 0]) + 1];
} forEach allGroups;

private _jobs = (missionNamespace getVariable ["Waldo_AIPass_Jobs", []]) + (missionNamespace getVariable ["Waldo_AIPass_PendingJobs", []]);
{
    private _group = (_x select 2) getOrDefault ["group", grpNull];
    if (!isNull _group) then {
        if (local _group && {!isNull (_group getVariable ["Waldo_AIPass_RegroupHost", grpNull])}) then {
            {
                if (alive _x && {local _x}) then {_x doFollow leader _group};
            } forEach units _group;
        };
        _group setVariable ["Waldo_AIPass_Dropping", nil];
        if (local _group && {"team" in (_x select 2)} && {_group getVariable ["Waldo_AIPass_ClearBuilding", false]}) then {
            private _clearJob = _x select 2;
            {if (alive _x && {local _x}) then {_x doFollow leader _group}} forEach (_clearJob getOrDefault ["team", []]);
            if ("baseBehaviour" in _clearJob && {behaviour leader _group == "COMBAT"}) then {
                _group setBehaviour (_clearJob get "baseBehaviour");
            };
            _group setVariable ["Waldo_AIPass_ClearBuilding", nil, true];
            _group setVariable ["Waldo_AIPass_ClearOrder", nil, true];
            _group setVariable ["Waldo_AIPass_ClearApplied", nil];
        };
        _group setVariable ["Waldo_AIPass_GarrisonApplied", nil];
        _group setVariable ["Waldo_AIPass_DefendApplied", nil];
        private _aircraft = (_x select 2) getOrDefault ["aircraft", objNull];
        if (!isNull _aircraft) then {_aircraft setVariable ["Waldo_AIPass_DropUntil", nil]};
        _group setVariable ["Waldo_AIPass_RegroupQueued", nil];
        _group setVariable ["Waldo_AIPass_RegroupHost", nil];
    };
} forEach _jobs;
missionNamespace setVariable ["Waldo_AIPass_Jobs", []];
missionNamespace setVariable ["Waldo_AIPass_PendingJobs", []];
missionNamespace setVariable ["Waldo_AIPass_DiscoveryQueued", false];
diag_log "[WMP AI PASS] Stopped.";
