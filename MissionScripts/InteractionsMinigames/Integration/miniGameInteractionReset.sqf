/*
 * Author: Waldo
 * Server-only reset for interaction lifecycle state.
 *
 * Arguments: [object, reenableAction, forceRunningReset]
 * Return: Boolean - false when called off-server, invalid, or refusing an active attempt
 */

params [
    ["_object", objNull, [objNull]],
    ["_reenableAction", true, [false]],
    ["_forceRunningReset", false, [false]]
];

if (!isServer || {isNull _object}) exitWith {false};
if ((_object getVariable ["Waldo_MG_InteractionState", "IDLE"]) == "RUNNING" && {!_forceRunningReset}) exitWith {false};

private _challengeId = _object getVariable ["Waldo_MG_Int_ChallengeId", ""];
private _result = ["IDLE", "", "RESET", _challengeId, objNull, "", -1, serverTime];
_object setVariable ["Waldo_MG_Int_AttemptId", ""];
_object setVariable ["Waldo_MG_Int_AttemptActor", objNull];
_object setVariable ["Waldo_MG_Int_AttemptStarted", -1];
_object setVariable ["Waldo_MG_Int_Consumed", false, true];
_object setVariable ["Waldo_MG_InteractionState", "IDLE", true];
_object setVariable ["Waldo_MG_InteractionResult", _result, true];
_object setVariable ["Waldo_MG_InteractionComplete", false, true];
_object setVariable ["Waldo_MG_InteractionFailed", false, true];
if (_challengeId != "") then {_object setVariable [format ["Waldo_MG_%1Complete", _challengeId], false, true];};
private _successVariable = _object getVariable ["Waldo_MG_Preset_SuccessVariable", ""];
private _failureVariable = _object getVariable ["Waldo_MG_Preset_FailureVariable", ""];
if (_successVariable != "") then {_object setVariable [_successVariable, false, true];};
if (_failureVariable != "") then {_object setVariable [_failureVariable, false, true];};
private _bombDefusedVariable = _object getVariable ["Waldo_MG_Bomb_DefusedVar", ""];
if (_bombDefusedVariable != "") then {_object setVariable [_bombDefusedVariable, false, true];};
if !(isNil {_object getVariable "Waldo_MG_BombDefused"}) then {
    _object setVariable ["Waldo_MG_BombDefused", false, true];
};
if (_reenableAction) then {_object setVariable ["Waldo_MG_Int_Active", true, true];};

["Waldo_MG_InteractionStateChanged", [_object, "IDLE", _result]] call CBA_fnc_globalEvent;
true
