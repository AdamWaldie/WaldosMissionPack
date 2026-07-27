/*
 * Author: WaldoTheWarfighter
 * Internal completion handler for Waldo_fnc_MiniGameChallenge. A challenge opener calls the
 * resolve callback it was given with [_success]; that callback is compiled to forward here
 * with the job token, so this looks up the stored job, clears it (guaranteeing the callbacks
 * fire at most once) and dispatches to the success or failure callback.
 *
 * Not intended to be called directly.
 *
 * Arguments:
 * _success - Boolean - challenge outcome
 * _outcome - Array   - optional [outcomeCode, reason]
 * _jobVar  - String  - missionNamespace variable holding [_actor, _id, _onSuccess, _onFailure, _context]
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [true, ["SUCCESS", ""], "Waldo_MG_Job_4"] call Waldo_fnc_MiniGameChallengeResolve;
 */

params [
    ["_success", false, [false]],
    ["_outcome", [], [[]]],
    ["_jobVar", "", [""]]
];

if (_jobVar == "") exitWith {};

private _job = missionNamespace getVariable [_jobVar, []];
if (_job isEqualTo []) exitWith {};
missionNamespace setVariable [_jobVar, nil];
missionNamespace setVariable ["Waldo_IMG_ActiveProfile", nil];

_job params ["_actor", "_challengeId", "_onSuccess", "_onFailure", "_context"];

private _outcomeCode = if (_success) then {"SUCCESS"} else {"FAILURE"};
private _reason = "";
if !(_outcome isEqualTo []) then {
    _outcomeCode = toUpper (_outcome param [0, _outcomeCode, [""]]);
    _reason = _outcome param [1, "", [""]];
};
if !(_outcomeCode in ["SUCCESS", "FAILURE", "TIMEOUT", "ABORTED", "ABANDONED"]) then {
    _outcomeCode = if (_success) then {"SUCCESS"} else {"FAILURE"};
};
if (_success) then {_outcomeCode = "SUCCESS";};
if (!_success && {_outcomeCode == "SUCCESS"}) then {_outcomeCode = "FAILURE";};
private _detail = [_outcomeCode, _reason];

if (_success) then {
    [_actor, _challengeId, _context, _detail] call _onSuccess;
} else {
    [_actor, _challengeId, _context, _detail] call _onFailure;
};
