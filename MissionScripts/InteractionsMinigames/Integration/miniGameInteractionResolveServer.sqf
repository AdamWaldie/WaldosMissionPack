/*
 * Author: Waldo
 * Server authority for interaction completion. Accepts only the current attempt and its owner,
 * publishes terminal state before events/callbacks, and guarantees exactly-once resolution.
 * Existing callbacks keep [_object, _actor, _success] and receive the result array as argument 4.
 */

params [
    ["_object", objNull, [objNull]],
    ["_actor", objNull, [objNull]],
    ["_success", false, [false]],
    ["_attemptId", "", [""]],
    ["_outcomeCode", "FAILURE", [""]],
    ["_reason", "", [""]]
];

if (!isServer || {isNull _object} || {_attemptId == ""}) exitWith {false};
if ((_object getVariable ["Waldo_MG_InteractionState", "IDLE"]) != "RUNNING") exitWith {false};
if ((_object getVariable ["Waldo_MG_Int_AttemptId", ""]) != _attemptId) exitWith {false};
if ((_object getVariable ["Waldo_MG_Int_AttemptActor", objNull]) isNotEqualTo _actor) exitWith {false};

private _caller = if (isNil "remoteExecutedOwner") then {2} else {remoteExecutedOwner};
if (_caller > 2 && {_caller != owner _actor}) exitWith {false};

_outcomeCode = toUpper _outcomeCode;
if !(_outcomeCode in ["SUCCESS", "FAILURE", "TIMEOUT", "ABORTED", "ABANDONED"]) then {
    _outcomeCode = if (_success) then {"SUCCESS"} else {"FAILURE"};
};
if (_success) then {_outcomeCode = "SUCCESS";};
if (!_success && {_outcomeCode == "SUCCESS"}) then {_outcomeCode = "FAILURE";};
if (_reason == "") then {
    _reason = switch (_outcomeCode) do {
        case "SUCCESS": {"PROCEDURE COMPLETED"};
        case "TIMEOUT": {"OPERATING WINDOW EXPIRED"};
        case "ABORTED": {"PROCEDURE ABORTED"};
        case "ABANDONED": {"PROCEDURE ABANDONED"};
        default {"PROCEDURE FAILED"};
    };
};

private _state = if (_success) then {"SUCCESS"} else {"FAILURE"};
private _challengeId = _object getVariable ["Waldo_MG_Int_ChallengeId", "wirecut"];
private _startedAt = _object getVariable ["Waldo_MG_Int_AttemptStarted", serverTime];
private _result = [_state, _outcomeCode, _reason, _challengeId, _actor, _attemptId, _startedAt, serverTime];

// Invalidate ownership before publishing so duplicate or stale client messages cannot resolve.
_object setVariable ["Waldo_MG_Int_AttemptId", ""];
_object setVariable ["Waldo_MG_Int_AttemptActor", objNull];
_object setVariable ["Waldo_MG_InteractionState", _state, true];
_object setVariable ["Waldo_MG_InteractionResult", _result, true];
_object setVariable ["Waldo_MG_InteractionComplete", _success, true];
_object setVariable ["Waldo_MG_InteractionFailed", !_success, true];
_object setVariable [format ["Waldo_MG_%1Complete", _challengeId], _success, true];

private _successVariable = _object getVariable ["Waldo_MG_Preset_SuccessVariable", ""];
private _failureVariable = _object getVariable ["Waldo_MG_Preset_FailureVariable", ""];
if (_successVariable != "") then {_object setVariable [_successVariable, _success, true];};
if (_failureVariable != "") then {_object setVariable [_failureVariable, !_success, true];};

private _options = _object getVariable ["Waldo_MG_Int_Options", []];
private _oneShot = true;
{if ((_x select 0) == "oneShot") exitWith {_oneShot = _x select 1;};} forEach _options;
if (_oneShot) then {
    _object setVariable ["Waldo_MG_Int_Consumed", true, true];
    _object setVariable ["Waldo_MG_Int_Active", false, true];
} else {
    if (_success && {!(_object getVariable ["Waldo_MG_Preset_Repeatable", true])}) then {
        _object setVariable ["Waldo_MG_Int_Active", false, true];
    };
    if (!_success && {!(_object getVariable ["Waldo_MG_Preset_RetryOnFailure", true])}) then {
        _object setVariable ["Waldo_MG_Int_Active", false, true];
    };
};

["Waldo_MG_InteractionStateChanged", [_object, _state, _result]] call CBA_fnc_globalEvent;

private _callback = if (_success) then {
    _object getVariable ["Waldo_MG_Int_OnSuccess", {}]
} else {
    _object getVariable ["Waldo_MG_Int_OnFailure", {}]
};
[_object, _actor, _success, _result] call _callback;

true
