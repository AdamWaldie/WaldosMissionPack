/*
 * Author: Waldo
 * Actor-side runner for a gated interaction created with Waldo_fnc_MiniGameInteraction. Reads
 * the challenge stored on the object, plays it for the local player, and reports the result to
 * the server (Waldo_fnc_MiniGameInteractionResolveServer) which runs the authoritative
 * success/failure callback. Bound as the action's statement - not usually called directly.
 *
 * Arguments:
 * _object - Object - the interacted object (the ACE/addAction target)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * _bomb call Waldo_fnc_MiniGameInteractionActivate;
 */

params [["_object", objNull, [objNull]]];

if (isNull _object) exitWith {};
if !(_object getVariable ["Waldo_MG_Int_Active", true]) exitWith {};

private _challengeId = _object getVariable ["Waldo_MG_Int_ChallengeId", "wirecut"];
private _config = _object getVariable ["Waldo_MG_Int_Config", []];

private _onSuccess = {
    params ["_actor", "_cid", "_ctx"];
    [_ctx select 0, _actor, true] remoteExec ["Waldo_fnc_MiniGameInteractionResolveServer", 2];
};
private _onFailure = {
    params ["_actor", "_cid", "_ctx"];
    [_ctx select 0, _actor, false] remoteExec ["Waldo_fnc_MiniGameInteractionResolveServer", 2];
};

[_challengeId, _config, _onSuccess, _onFailure, player, [_object]] call Waldo_fnc_MiniGameChallenge;
