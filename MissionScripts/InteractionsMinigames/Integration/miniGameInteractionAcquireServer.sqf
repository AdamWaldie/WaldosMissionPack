/*
 * Author: Waldo
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
if (remoteExecutedOwner != owner _actor) exitWith {false};
if !(_actor in allPlayers) exitWith {false};
if !(_object getVariable ["Waldo_MG_Int_Active", true]) exitWith {false};
if (_object getVariable ["Waldo_MG_Int_Consumed", false]) exitWith {false};
if ((_object getVariable ["Waldo_MG_InteractionState", "IDLE"]) == "RUNNING") exitWith {false};

private _distance = _object getVariable ["Waldo_MG_Int_Distance", 4];
if ((_actor distance _object) > _distance) exitWith {false};

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

["Waldo_MG_InteractionStateChanged", [_object, "RUNNING", _result]] call CBA_fnc_globalEvent;
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
