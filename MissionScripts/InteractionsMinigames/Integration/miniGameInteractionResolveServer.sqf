/*
 * Author: Waldo
 * Server authority for a gated interaction. Runs the object's stored success or failure
 * callback exactly where mission state should change - on the server. Handles one-shot
 * consumption (hiding the action everywhere via a broadcast flag) before invoking the
 * callback with [_object, _actor, _success].
 *
 * Called via remoteExec from Waldo_fnc_MiniGameInteractionActivate - not usually called
 * directly.
 *
 * Arguments:
 * _object  - Object  - the interacted object
 * _actor   - Object  - the player who attempted it
 * _success - Boolean - challenge outcome
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_bomb, _player, false] remoteExec ["Waldo_fnc_MiniGameInteractionResolveServer", 2];
 */

params [
    ["_object", objNull, [objNull]],
    ["_actor", objNull, [objNull]],
    ["_success", false, [false]]
];

if (!isServer) exitWith {};
if (isNull _object) exitWith {};

private _options = _object getVariable ["Waldo_MG_Int_Options", []];
private _oneShot = true;
{ if ((_x select 0) == "oneShot") exitWith { _oneShot = _x select 1; }; } forEach _options;

if (_oneShot && {_object getVariable ["Waldo_MG_Int_Consumed", false]}) exitWith {};
if (_oneShot) then {
    _object setVariable ["Waldo_MG_Int_Consumed", true, true];
    _object setVariable ["Waldo_MG_Int_Active", false, true];
};

private _cb = if (_success) then {
    _object getVariable ["Waldo_MG_Int_OnSuccess", {}]
} else {
    _object getVariable ["Waldo_MG_Int_OnFailure", {}]
};

[_object, _actor, _success] call _cb;
