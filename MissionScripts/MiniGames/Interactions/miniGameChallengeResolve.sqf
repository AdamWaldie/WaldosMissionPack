/*
 * Author: Waldo
 * Internal completion handler for Waldo_fnc_MiniGameChallenge. A challenge opener calls the
 * resolve callback it was given with [_success]; that callback is compiled to forward here
 * with the job token, so this looks up the stored job, clears it (guaranteeing the callbacks
 * fire at most once) and dispatches to the success or failure callback.
 *
 * Not intended to be called directly.
 *
 * Arguments:
 * _success - Boolean - challenge outcome
 * _jobVar  - String  - missionNamespace variable holding [_actor, _id, _onSuccess, _onFailure, _context]
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [true, "Waldo_MG_Job_4"] call Waldo_fnc_MiniGameChallengeResolve;
 */

params [
    ["_success", false, [false]],
    ["_jobVar", "", [""]]
];

if (_jobVar == "") exitWith {};

private _job = missionNamespace getVariable [_jobVar, []];
if (_job isEqualTo []) exitWith {};
missionNamespace setVariable [_jobVar, nil];

_job params ["_actor", "_challengeId", "_onSuccess", "_onFailure", "_context"];

if (_success) then {
    [_actor, _challengeId, _context] call _onSuccess;
} else {
    [_actor, _challengeId, _context] call _onFailure;
};
