/*
 * Author: WaldoTheWarfighter
 * Publishes the current Ground Command identity and starts bounded UID-readiness reconciliation.
 *
 * Locality/authority: interface client only; publishes only this client's current player identity.
 * Repeat/JIP behaviour: repeat-safe and change-gated by publishLocalGroundCommandIdentity. Each
 * request advances a generation so retries for an earlier player object cannot overwrite a later
 * respawn/team-switch identity.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * BOOL - true when refreshed/queued; false outside the active local identity service.
 *
 * Current callers: startLocalGroundCommandIdentityService and its CBA unit-change handler.
 *
 * Example:
 * [] call Waldo_fnc_EcoCommand_requestLocalGroundCommandIdentityRefresh;
 */

if (!hasInterface || {isNull player}) exitWith {false};
if !(missionNamespace getVariable ["WaldoEcoCommand_LocalIdentityServiceStarted", false]) exitWith {false};
if !([] call Waldo_fnc_EcoCore_isModuleActive) exitWith {false};

private _epoch = missionNamespace getVariable ["WaldoEcoCommand_LocalIdentityServiceEpoch", -1];
private _generation = (missionNamespace getVariable ["WaldoEcoCommand_LocalIdentityGeneration", 0]) + 1;
missionNamespace setVariable ["WaldoEcoCommand_LocalIdentityGeneration", _generation];

[] call Waldo_fnc_EcoCommand_publishLocalGroundCommandIdentity;

if ((getPlayerUID player) isEqualTo "") then {
    [_epoch, _generation, diag_tickTime + 60] call Waldo_fnc_EcoCommand_scheduleLocalGroundCommandIdentityRetry;
};

true
