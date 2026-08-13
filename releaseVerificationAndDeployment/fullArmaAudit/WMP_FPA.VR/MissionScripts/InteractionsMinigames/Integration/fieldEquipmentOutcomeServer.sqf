/*
 * Author: WaldoTheWarfighter
 * Executes a ZEN Field Equipment success or failure outcome. The server first applies the selected
 * named preset to the interaction target, then calls the optional curator-authored code with
 * `[_target, _actor, _success, _result]`. Curator code is compiled and retained only on the server.
 *
 * Arguments: 0 target <OBJECT>; 1 actor <OBJECT> (default objNull); 2 success <BOOL> (default true);
 * 3 procedure result <ARRAY> (default []).
 * Return Value: Boolean - true when a supported outcome was accepted.
 * Current caller: Waldo_fnc_FieldEquipmentZenSetupLocal standard-procedure callback.
 * Example: [_target, _actor, true, _result] call Waldo_fnc_FieldEquipmentOutcomeServer;
 */
params [["_target", objNull, [objNull]], ["_actor", objNull, [objNull]], ["_success", true, [true]], ["_result", [], [[]]]];
// This function is an internal callback, not a public client request. Refuse non-server execution
// rather than creating a second remotely callable mutation surface.
if (!isServer) exitWith {false};
if (isNull _target || {!(_target getVariable ["Waldo_FieldEquipment_ZenConfigured", false])}) exitWith {false};
private _preset = _target getVariable [if (_success) then {"Waldo_FieldEquipment_SuccessPreset"} else {"Waldo_FieldEquipment_FailurePreset"}, if (_success) then {"COMPLETE"} else {"NONE"}];
// Capture the callback before a destructive preset can delete its variable-bearing target.
private _callback = _target getVariable [if (_success) then {"Waldo_FieldEquipment_SuccessCode"} else {"Waldo_FieldEquipment_FailureCode"}, {}];
switch (_preset) do {
    case "SHOW_ENABLE": {_target hideObjectGlobal false; _target enableSimulationGlobal true;};
    case "HIDE_DISABLE": {_target enableSimulationGlobal false; _target hideObjectGlobal true;};
    case "UNLOCK": {_target lock 0;};
    case "LOCK": {_target lock 2;};
    case "DESTROY": {_target setDamage 1;};
    case "DELETE": {deleteVehicle _target;};
    case "COMPLETE": {_target setVariable ["Waldo_FieldEquipment_Completed", true, true];};
};
[_target, _actor, _success, _result] call _callback;
diag_log format ["[WMP INTERACTION] ZEN result=%1 preset=%2 target=%3 actor=%4 customCode=%5", if (_success) then {"SUCCESS"} else {"FAILURE"}, _preset, netId _target, if (isNull _actor) then {"<none>"} else {name _actor}, !(_callback isEqualTo {})];
true
