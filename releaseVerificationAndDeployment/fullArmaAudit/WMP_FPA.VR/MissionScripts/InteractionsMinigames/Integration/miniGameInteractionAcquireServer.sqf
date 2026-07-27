/*
 * Author: WaldoTheWarfighter
 * Server-side acquisition gate for field-equipment procedures. Exactly one actor receives an
 * owner-bound attempt ID and only that actor is instructed to open the equipment display.
 *
 * Arguments:
 * _object - Object - configured equipment
 * _actor  - Object - requesting player
 *
 * Return Value:
 * Boolean - true when the attempt was accepted
 */

params [
    ["_object", objNull, [objNull]],
    ["_actor", objNull, [objNull]]
];

if (!isServer || {isNull _object} || {isNull _actor}) exitWith {false};
private _caller = if (isRemoteExecuted) then {remoteExecutedOwner} else {owner _actor};
if (isRemoteExecuted && {_caller != owner _actor}) exitWith {false};
private _reject = {
    params ["_message"];
    [_message, "WARN", 4] remoteExecCall ["Waldo_fnc_MiniGameInteractionNotifyClient", owner _actor];
    diag_log format ["[WMP INTERACTION] acquisition rejected for %1 on %2: %3", name _actor, netId _object, _message];
    false
};
if !(_actor in allPlayers) exitWith {["REQUESTING ACTOR IS NOT AN ACTIVE PLAYER"] call _reject};
if !(_object getVariable ["Waldo_MG_Int_Active", true]) exitWith {["EQUIPMENT IS NOT AVAILABLE"] call _reject};
if (_object getVariable ["Waldo_MG_Int_Consumed", false]) exitWith {["EQUIPMENT PROCEDURE HAS ALREADY BEEN COMPLETED"] call _reject};
if ((_object getVariable ["Waldo_MG_InteractionState", "IDLE"]) == "RUNNING") exitWith {["EQUIPMENT IS ALREADY IN USE"] call _reject};

private _distance = _object getVariable ["Waldo_MG_Int_Distance", 4];
if ((_actor distance _object) > _distance) exitWith {[format ["MOVE WITHIN %1 METRES OF THE EQUIPMENT", _distance]] call _reject};
private _condition = _object getVariable ["Waldo_MG_Int_Condition", {true}];
if !(_object call _condition) exitWith {["EQUIPMENT CONDITIONS ARE NOT MET"] call _reject};

private _challengeId = _object getVariable ["Waldo_MG_Int_ChallengeId", "wirecut"];
private _counter = missionNamespace getVariable ["Waldo_MG_Int_AttemptCounter", 0];
missionNamespace setVariable ["Waldo_MG_Int_AttemptCounter", _counter + 1];
private _attemptId = format ["%1:%2:%3:%4", netId _object, owner _actor, _counter, floor (random 1000000000)];
private _startedAt = serverTime;
private _result = ["RUNNING", "", "", _challengeId, _actor, _attemptId, _startedAt, -1];

_object setVariable ["Waldo_MG_Int_AttemptId", _attemptId];
_object setVariable ["Waldo_MG_Int_AttemptActor", _actor];
_object setVariable ["Waldo_MG_Int_AttemptStarted", _startedAt];
_object setVariable ["Waldo_MG_InteractionState", "RUNNING", true];
_object setVariable ["Waldo_MG_InteractionResult", _result, true];
_object setVariable ["Waldo_MG_InteractionComplete", false, true];
_object setVariable ["Waldo_MG_InteractionFailed", false, true];
_object setVariable [format ["Waldo_MG_%1Complete", _challengeId], false, true];
private _successVariable = _object getVariable ["Waldo_MG_Preset_SuccessVariable", ""];
private _failureVariable = _object getVariable ["Waldo_MG_Preset_FailureVariable", ""];
if (_successVariable != "") then {_object setVariable [_successVariable, false, true];};
if (_failureVariable != "") then {_object setVariable [_failureVariable, false, true];};

// CBA/ACE consumers receive the immediate event. Vanilla-only missions use
// the same public object variables and callbacks without requiring CBA.
if !(isNil "CBA_fnc_globalEvent") then {
    ["Waldo_MG_InteractionStateChanged", [_object, "RUNNING", _result]] call CBA_fnc_globalEvent;
};
diag_log format ["[WMP INTERACTION] RUNNING object=%1 challenge=%2 actor=%3 attempt=%4 objectLocal=%5 objectOwner=%6 actorOwner=%7 remoteOwner=%8", netId _object, _challengeId, name _actor, _attemptId, local _object, owner _object, owner _actor, _caller];
[_object, _actor, _attemptId] remoteExecCall ["Waldo_fnc_MiniGameInteractionStartClient", owner _actor];

private _options = _object getVariable ["Waldo_MG_Int_Options", []];
private _lockTimeout = 600;
{
    if ((_x select 0) == "lockTimeout") exitWith {
        private _candidate = _x select 1;
        if (typeName _candidate == "SCALAR") then {_lockTimeout = _candidate max 1;};
    };
} forEach _options;

[_object, _actor, _attemptId, _startedAt, _lockTimeout] spawn {
    params ["_object", "_actor", "_attemptId", "_startedAt", "_lockTimeout"];
    private _finished = false;
    while {!_finished} do {
        sleep 1;
        if (isNull _object) exitWith {_finished = true;};
        if ((_object getVariable ["Waldo_MG_Int_AttemptId", ""]) != _attemptId) exitWith {_finished = true;};
        if (isNull _actor || {!(_actor in allPlayers)}) exitWith {
            [_object, _actor, false, _attemptId, "ABANDONED", "ACTOR DISCONNECTED"]
                remoteExecCall ["Waldo_fnc_MiniGameInteractionResolveServer", 2];
            _finished = true;
        };
        if (!alive _actor) exitWith {
            [_object, _actor, false, _attemptId, "ABANDONED", "ACTOR DIED"]
                remoteExecCall ["Waldo_fnc_MiniGameInteractionResolveServer", 2];
            _finished = true;
        };
        if ((serverTime - _startedAt) >= _lockTimeout) exitWith {
            [_object, _actor, false, _attemptId, "ABANDONED", "EXCLUSIVE LOCK EXPIRED"]
                remoteExecCall ["Waldo_fnc_MiniGameInteractionResolveServer", 2];
            _finished = true;
        };
    };
};

true
