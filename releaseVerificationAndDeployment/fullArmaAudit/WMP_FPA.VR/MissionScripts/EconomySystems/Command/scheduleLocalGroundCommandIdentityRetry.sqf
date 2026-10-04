/*
 * Author: WaldoTheWarfighter
 * Schedules bounded reconciliation while Arma resolves a client's multiplayer UID.
 *
 * Locality/authority: interface client only. Repeat/JIP behaviour: one-shot callbacks continue only
 * while service epoch and player generation remain current, Economy is active, the UID is blank and
 * the 60-second readiness window has not expired. Single-player/fallback identities therefore leave
 * no mission-long worker.
 *
 * Arguments:
 * 0: _epoch <NUMBER> - identity service epoch (default: -1)
 * 1: _generation <NUMBER> - current player-object generation (default: -1)
 * 2: _deadline <NUMBER> - diag_tickTime deadline (default: 0)
 *
 * Return Value:
 * BOOL - true when scheduled; false for invalid/stale state.
 *
 * Current callers: requestLocalGroundCommandIdentityRefresh and this callback.
 *
 * Example:
 * [_epoch, _generation, diag_tickTime + 60] call Waldo_fnc_EcoCommand_scheduleLocalGroundCommandIdentityRetry;
 * Locality/Authority: Interface client; queued callback only reads/publishes its local player identity.
 * Repeat/JIP Behaviour: Epoch, generation and deadline reject stale retry chains.
 * Result: Returns true for a live bounded retry, false for stale or invalid state.
 */

params [
    ["_epoch", -1, [0]],
    ["_generation", -1, [0]],
    ["_deadline", 0, [0]]
];

if (!hasInterface || {_epoch < 0} || {_generation < 0}) exitWith {false};
if (_epoch != (missionNamespace getVariable ["WaldoEcoCommand_LocalIdentityServiceEpoch", -2])) exitWith {false};
if (_generation != (missionNamespace getVariable ["WaldoEcoCommand_LocalIdentityGeneration", -2])) exitWith {false};

[
    {
        params ["_epoch", "_generation", "_deadline"];

        if (_epoch != (missionNamespace getVariable ["WaldoEcoCommand_LocalIdentityServiceEpoch", -2])) exitWith {};
        if (_generation != (missionNamespace getVariable ["WaldoEcoCommand_LocalIdentityGeneration", -2])) exitWith {};
        if !([] call Waldo_fnc_EcoCore_isModuleActive) exitWith {};
        if (isNull player) exitWith {};

        [] call Waldo_fnc_EcoCommand_publishLocalGroundCommandIdentity;

        if ((getPlayerUID player) isEqualTo "" && {diag_tickTime < _deadline}) then {
            [_epoch, _generation, _deadline] call Waldo_fnc_EcoCommand_scheduleLocalGroundCommandIdentityRetry;
        };
    },
    [_epoch, _generation, _deadline],
    0.5
] call CBA_fnc_waitAndExecute;

true
