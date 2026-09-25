/*
 * Author: WaldoTheWarfighter
 * Runs due Smart AI Pass jobs on this machine within a strict per-tick time budget.
 *
 * Called by one CBA per-frame handler every 0.25 seconds on each AI-owning machine (server and
 * headless clients only). At least one due job runs on each tick; the rest run only while
 * Waldo_AIPass_TickBudgetMs remains. Jobs that do not fit wait for the next tick, which keeps
 * frame-time cost bounded however many groups are busy. Jobs that ran move to the back of the
 * queue, so no group is starved when the budget is always spent. When the machine's FPS is below
 * Waldo_AIPass_LowFpsThreshold, rescheduling delays are doubled. While ENDEX or SafeStart is
 * active, due jobs are postponed by five seconds and never run.
 * Locality and authority: machine-local. It performs no world scans and no network traffic.
 *
 * Arguments: None.
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_AIPassSchedulerTick;
 * Result: due jobs run and are rescheduled or retired.
 *
 * Current caller: the per-frame handler installed by Waldo_fnc_AIPassInit.
 */

if !(missionNamespace getVariable ["Waldo_AIPass_Active", false]) exitWith {};
private _jobs = missionNamespace getVariable ["Waldo_AIPass_Jobs", []];
private _pending = missionNamespace getVariable ["Waldo_AIPass_PendingJobs", []];
if (_pending isNotEqualTo []) then {
    _jobs append _pending;
    missionNamespace setVariable ["Waldo_AIPass_PendingJobs", []];
};
if (_jobs isEqualTo []) exitWith {missionNamespace setVariable ["Waldo_AIPass_Jobs", []]};

private _now = time;
private _start = diag_tickTime;
private _budget = ((missionNamespace getVariable ["Waldo_AIPass_TickBudgetMs", 1]) max 0.2) / 1000;
private _slow = diag_fps < (missionNamespace getVariable ["Waldo_AIPass_LowFpsThreshold", 25]);
private _paused = [] call Waldo_fnc_AIPassIsPaused;
private _processed = 0;
private _next = [];
private _rescheduled = [];
{
    _x params ["_dueAt", "_job", "_state"];
    if (_dueAt > _now || {_processed > 0 && {diag_tickTime - _start >= _budget}}) then {
        _next pushBack _x;
    } else {
        _processed = _processed + 1;
        private _delay = if (_paused) then {5} else {[_state] call _job};
        if (!isNil "_delay" && {_delay isEqualType 0} && {_delay >= 0}) then {
            if (_slow && {!_paused}) then {_delay = _delay * 2};
            _rescheduled pushBack [_now + _delay, _job, _state];
        };
    };
} forEach _jobs;
// Jobs that just ran move behind those still waiting, so a full budget rotates fairly.
_next append _rescheduled;
missionNamespace setVariable ["Waldo_AIPass_Jobs", _next];
