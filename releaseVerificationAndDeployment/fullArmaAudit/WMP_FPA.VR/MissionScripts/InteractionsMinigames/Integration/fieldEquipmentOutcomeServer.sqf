/*
 * Author: WaldoTheWarfighter
 * Executes a curated ZEN Field Equipment success outcome. The server owns the decision and applies
 * the selected globally effective object command. Script-authored interactions
 * retain their unrestricted custom callbacks; this helper exists only for the safe Zeus menu.
 *
 * Arguments: 0 target <OBJECT>; 1 successful actor <OBJECT> (default objNull).
 * Return Value: Boolean - true when a supported outcome was accepted.
 * Current caller: Waldo_fnc_FieldEquipmentZenSetupLocal standard-procedure callback.
 * Example: [_target, _actor] call Waldo_fnc_FieldEquipmentOutcomeServer;
 */
params [["_target", objNull, [objNull]], ["_actor", objNull, [objNull]]];
// This function is an internal callback, not a public client request. Refuse non-server execution
// rather than creating a second remotely callable mutation surface.
if (!isServer) exitWith {false};
if (isNull _target || {!(_target getVariable ["Waldo_FieldEquipment_ZenConfigured", false])}) exitWith {false};
private _outcome = _target getVariable ["Waldo_FieldEquipment_Outcome", "COMPLETE"];
switch (_outcome) do {
    case "ACTIVATE": {_target hideObjectGlobal false; _target enableSimulationGlobal true;};
    case "DEACTIVATE": {_target enableSimulationGlobal false;};
    case "UNLOCK": {_target lock 0;};
    case "DESTROY": {_target setDamage 1;};
    case "DELETE": {deleteVehicle _target;};
    default {_target setVariable ["Waldo_FieldEquipment_Completed", true, true];};
};
diag_log format ["[WMP INTERACTION] ZEN outcome=%1 target=%2 actor=%3", _outcome, netId _target, if (isNull _actor) then {"<none>"} else {name _actor}];
true
