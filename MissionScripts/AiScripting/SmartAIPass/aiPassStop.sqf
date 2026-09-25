/*
 * Author: WaldoTheWarfighter
 * Stops the Smart AI Pass on this machine and hands every affected group back to its own orders.
 *
 * Removes the scheduler and kill handlers and discards queued jobs. Survivors still walking to a
 * host get doFollow so they return to their own group's formation and waypoints; nothing the pass
 * did stays in force. Merges that have already happened are not undone.
 * Locality and authority: the server clears Waldo_AIPass_Enable and the JIP key
 * Waldo_AIPass_RuntimeInit, then asks every other machine to stop. Remote calls from anything other
 * than the server are refused. Each machine handles only the groups it owns.
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
    [] remoteExecCall ["", "Waldo_AIPass_RuntimeInit"];
    if (remoteExecutedOwner == 0) then {
        [] remoteExecCall ["Waldo_fnc_AIPassStop", -2];
    };
};
if (hasInterface && {!isServer}) exitWith {};
missionNamespace setVariable ["Waldo_AIPass_Active", false];

private _handle = missionNamespace getVariable "Waldo_AIPass_SchedulerHandle";
if (!isNil "_handle") then {
    [_handle] call CBA_fnc_removePerFrameHandler;
    missionNamespace setVariable ["Waldo_AIPass_SchedulerHandle", nil];
};
private _killed = missionNamespace getVariable "Waldo_AIPass_KilledHandler";
if (!isNil "_killed") then {
    removeMissionEventHandler ["EntityKilled", _killed];
    missionNamespace setVariable ["Waldo_AIPass_KilledHandler", nil];
};

private _jobs = (missionNamespace getVariable ["Waldo_AIPass_Jobs", []]) + (missionNamespace getVariable ["Waldo_AIPass_PendingJobs", []]);
{
    private _group = (_x select 2) getOrDefault ["group", grpNull];
    if (!isNull _group) then {
        if (local _group && {!isNull (_group getVariable ["Waldo_AIPass_RegroupHost", grpNull])}) then {
            {
                if (alive _x && {local _x}) then {_x doFollow leader _group};
            } forEach units _group;
        };
        _group setVariable ["Waldo_AIPass_RegroupQueued", nil];
        _group setVariable ["Waldo_AIPass_RegroupHost", nil];
    };
} forEach _jobs;
missionNamespace setVariable ["Waldo_AIPass_Jobs", []];
missionNamespace setVariable ["Waldo_AIPass_PendingJobs", []];
diag_log "[WMP AI PASS] Stopped.";
