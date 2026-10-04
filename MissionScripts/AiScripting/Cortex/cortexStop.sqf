/*
 * Author: WaldoTheWarfighter
 * Stops Cortex on this machine and hands every affected group back to its own orders.
 *
 * Removes the scheduler and every event handler and discards queued jobs. Every locally managed
 * group is released (Waldo_fnc_CortexReleaseGroup): drills end with only the AI features they
 * disabled re-enabled, pass waypoints are removed, behaviour and speed are restored and LAMBS group AI
 * is handed back. Survivors still walking to a host get doFollow. Defence, garrison and clear
 * orders are released on their owner so restarting cannot revive an order superseded while off.
 * Completed merges and surrenders are not undone.
 * Locality and authority: the server clears Waldo_AIPass_Enable and the JIP key
 * Waldo_AIPass_RuntimeInit, then asks every other machine to stop. Remote calls from anything other
 * than the server are refused. Each machine handles only the groups it owns.
 *
 * Repeat/JIP: Repeat calls clear pending startup and abandoned jobs. Owner-local release clears
 * public defence/garrison assignments and restores only Cortex-owned movement restrictions.
 * Restart and ownership adoption cannot replay cancelled orders; tracked aircraft handlers are removed.
 * Public support request/responder state, delayed artillery-relocation tokens and attack-run
 * presentation state are invalidated. An active aircraft lease restores its recorded native group
 * attack policy, deletes its finite native guidance target and named movement waypoint, and removes
 * its firing-solution telemetry and re-attack cooldown before the job is discarded.
 * Vehicle safe-stop handshakes restore their prior forced speed before their tokens are cleared.
 * Owner-local missile-warning generations are advanced before handlers are removed; an
 * old CBA callback cannot become valid again after a quick restart.
 * Civilian event handlers and their EntityCreated installer are removed; external addon state is
 * never cleared. VCOM and LAMBS movement leases restore their captured baseline through group release.
 *
 * Arguments: None.
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_CortexStop;
 * Result: no further pass behaviour runs anywhere until Waldo_fnc_CortexInit is called again.
 *
 * Current callers: the AI Control ZEN module.
 */

if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {};
if (isServer) then {
    {
        private _job = _y;
        private _requester=_job getOrDefault ["requester",grpNull];
        if (!isNull _requester) then {
            _requester setVariable ["Waldo_Cortex_SupportResponders",nil,true];
            _requester setVariable ["Waldo_Cortex_SupportRequestState",nil,true];
        };
        {(_x select 0) setVariable ["Waldo_AIPass_SupportLease",nil,true]} forEach (_job get "leases");
    } forEach (missionNamespace getVariable ["Waldo_AIPass_SupportRequests",createHashMap]);
    missionNamespace setVariable ["Waldo_AIPass_SupportRequests",createHashMap];
    missionNamespace setVariable ["Waldo_AIPass_CounterGeneration", (missionNamespace getVariable ["Waldo_AIPass_CounterGeneration", 0]) + 1];
    missionNamespace setVariable ["Waldo_AIPass_Enable", false, true];
    {
        private _battery = _y get "battery";
        _battery setVariable ["Waldo_AIPass_FireToken", nil, true];
        _battery setVariable ["Waldo_AIPass_BusyUntil", nil, true];
    } forEach (missionNamespace getVariable ["Waldo_AIPass_FireMissions", createHashMap]);
    missionNamespace setVariable ["Waldo_AIPass_FireMissions", createHashMap];
    // Stop is a rare administrative action, so one bounded-by-world vehicle pass is preferable to
    // maintaining another runtime registry. Clearing the public token makes every already queued
    // shoot-and-scoot callback fail its first identity check, including after Cortex restarts.
    {
        private _savedStopSpeed=_x getVariable ["Waldo_Cortex_DismountForcedSpeed",[]];
        if (_savedStopSpeed isNotEqualTo [] && {local _x}) then {_x forceSpeed (_savedStopSpeed param [0,-1])};
        _x setVariable ["Waldo_Cortex_DismountForcedSpeed",nil];
        _x setVariable ["Waldo_Cortex_DismountStopRequest",nil,true];
        _x setVariable ["Waldo_Cortex_ArtilleryScootToken",nil,true];
        _x setVariable ["Waldo_Cortex_ArtilleryScootDeadline",nil,true];
        _x setVariable ["Waldo_Cortex_ArtilleryScootPurpose",nil,true];
        if (_x isKindOf "Air") then {
            private _guidanceTarget=_x getVariable ["Waldo_Cortex_AirAttackGuidanceTarget",objNull];
            if (!isNull _guidanceTarget) then {deleteVehicle _guidanceTarget};
            _x setVariable ["Waldo_Cortex_AttackFlarePhase",nil,true];
            _x setVariable ["Waldo_Cortex_AttackFlareCooldown",nil,true];
            _x setVariable ["Waldo_Cortex_AirAttackPlan",nil,true];
            _x setVariable ["Waldo_Cortex_AirFireSolution",nil,true];
            _x setVariable ["Waldo_Cortex_AirAttackTarget",nil];
            _x setVariable ["Waldo_Cortex_AirAttackGuidedWeapon",nil];
            _x setVariable ["Waldo_Cortex_AirAttackGuidanceTarget",nil];
            _x setVariable ["Waldo_Cortex_AirAttackBlockedUntil",nil];
        };
    } forEach vehicles;
    [] remoteExecCall ["", "Waldo_AIPass_RuntimeInit"];
    if (remoteExecutedOwner == 0) then {
        [] remoteExecCall ["Waldo_fnc_CortexStop", -2];
    };
};
if (hasInterface && {!isServer}) exitWith {};
missionNamespace setVariable ["Waldo_AIPass_Active", false];
missionNamespace setVariable ["Waldo_AIPass_InitPending", false];

{
    private _handler = _x getVariable ["Waldo_AIPass_FlaresHandler", -1];
    if (_handler >= 0) then {_x removeEventHandler ["IncomingMissile", _handler]};
    _x setVariable ["Waldo_Cortex_FlareBurstGeneration",
        (_x getVariable ["Waldo_Cortex_FlareBurstGeneration",0])+1];
    _x setVariable ["Waldo_Cortex_MissileDefenceActive",nil];
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
private _civilianCreated=missionNamespace getVariable "Waldo_Cortex_CivilianCreatedHandler";
if (!isNil "_civilianCreated") then {
    removeMissionEventHandler ["EntityCreated",_civilianCreated];
    missionNamespace setVariable ["Waldo_Cortex_CivilianCreatedHandler",nil];
};
{
    [_x,true] call Waldo_fnc_CortexCivilianSetup;
    private _local=_x getVariable ["Waldo_Cortex_CivilianLocalHandler",-1];
    if (_local >= 0) then {_x removeEventHandler ["Local",_local]};
    _x setVariable ["Waldo_Cortex_CivilianLocalHandler",nil];
} forEach (allUnits select {side group _x == civilian});
{
    [_x,true] call Waldo_fnc_CortexHearingLocal;
    if (local _x) then {_x setVariable ["Waldo_AIPass_AreaReport",nil,true]};
    if (local _x && {count (_x getVariable ["Waldo_AIPass_State", createHashMap]) > 0 || {_x getVariable ["Waldo_AIPass_Managed", false]} || {(_x getVariable ["Waldo_Cortex_Remount",[]]) isNotEqualTo []}}) then {
        [_x,true,"CORTEX_STOPPED"] call Waldo_fnc_CortexReleaseGroup;
    };
    if (local _x) then {
        [_x] call Waldo_fnc_CortexLambsBuildingRelease;
        [_x] call Waldo_fnc_CortexDefendRelease;
        [_x] call Waldo_fnc_CortexGarrisonRelease;
        [_x] call Waldo_fnc_CortexClearRelease;
    };
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
    private _state=_x select 2;
    private _flareAircraft=_state getOrDefault ["aircraft",objNull];
    if (!isNull _flareAircraft) then {
        private _guidanceTarget=_flareAircraft getVariable ["Waldo_Cortex_AirAttackGuidanceTarget",objNull];
        if (!isNull _guidanceTarget) then {deleteVehicle _guidanceTarget};
        _flareAircraft setVariable ["Waldo_Cortex_AttackFlareJob",nil];
        _flareAircraft setVariable ["Waldo_Cortex_AirAttackJob",nil];
        _flareAircraft setVariable ["Waldo_Cortex_AirAttackToken",nil];
        _flareAircraft setVariable ["Waldo_Cortex_AirAttackTarget",nil];
        _flareAircraft setVariable ["Waldo_Cortex_AirAttackGuidedWeapon",nil];
        _flareAircraft setVariable ["Waldo_Cortex_AirAttackGuidanceTarget",nil];
        _flareAircraft setVariable ["Waldo_Cortex_AirAttackBlockedUntil",nil];
        private _airHandler=_state getOrDefault ["firedHandler",-1];
        if (_airHandler >= 0 && {local _flareAircraft}) then {_flareAircraft removeEventHandler ["Fired",_airHandler]};
        if (local _flareAircraft) then {
            _flareAircraft limitSpeed -1;
            private _airGroup=group driver _flareAircraft;
            if (!isNull _airGroup) then {
                private _ownedWaypointName=_state getOrDefault ["ownedWaypointName",""];
                private _ownedWaypointIndex=(waypoints _airGroup) findIf {
                    _ownedWaypointName != "" && {waypointName _x == _ownedWaypointName}
                };
                if (_ownedWaypointIndex >= 0) then {
                    deleteWaypoint ((waypoints _airGroup) select _ownedWaypointIndex);
                };
                _airGroup enableAttack (_state getOrDefault ["previousAttackEnabled",true]);
            };
        };
    };
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
missionNamespace setVariable ["Waldo_AIPass_NextJobDue", -1];
missionNamespace setVariable ["Waldo_AIPass_DiscoveryQueued", false];
diag_log "[WMP CORTEX] Stopped.";
