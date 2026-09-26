/*
 * Author: WaldoTheWarfighter
 * Adds one job to this machine's Smart AI Pass scheduler.
 *
 * A job is code that takes one state HASHMAP and returns the number of seconds until it should run
 * again, or -1 when it has finished. Jobs never sleep: the scheduler runs them unscheduled inside a
 * per-tick time budget. New jobs wait in a pending list that the next tick merges, so a job may
 * safely queue another job while it runs.
 * Locality and authority: machine-local. Jobs and their state are never broadcast.
 *
 * Arguments:
 * 0: job <CODE> - receives [state] and returns the next delay in seconds or -1
 * 1: state <HASHMAP> - job-owned state carried between runs
 * 2: delay <NUMBER> - seconds before the first run (optional, default: 0)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [Waldo_fnc_AIPassRegroupStep, createHashMapFromArray [["group", _group]], 5] call Waldo_fnc_AIPassQueueJob;
 * Result: the regroup step runs on this machine about five seconds later.
 *
 * Current callers: Waldo_fnc_AIPassRegroupOnKill.
 */

params [["_job", {}, [{}]], ["_state", createHashMap, [createHashMap]], ["_delay", 0, [0]]];
private _group = _state getOrDefault ["group", grpNull];
if (!isNull _group) then {_state set ["ownerEpoch", _group getVariable ["Waldo_AIPass_Epoch", 0]]};
private _pending = missionNamespace getVariable ["Waldo_AIPass_PendingJobs", []];
_pending pushBack [time + (_delay max 0), _job, _state];
missionNamespace setVariable ["Waldo_AIPass_PendingJobs", _pending];
