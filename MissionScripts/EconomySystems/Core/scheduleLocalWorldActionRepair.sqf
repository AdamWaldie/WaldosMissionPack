/*
 * Author: WaldoTheWarfighter
 * Schedules the retained ten-second Economy action repair as an epoch-guarded one-shot callback.
 *
 * Locality/authority: interface client only. Repeat/JIP behaviour: each callback schedules exactly
 * one successor while its service epoch remains current. Purge/restart changes the epoch, making
 * stale callbacks exit without action or rescheduling.
 *
 * Arguments:
 * 0: _epoch <NUMBER> - local action service epoch (default: -1)
 *
 * Return Value:
 * BOOL - true when scheduled; false for an inactive/stale service.
 *
 * Current callers: startLocalWorldActionService and this function's current callback.
 *
 * Example:
 * [_epoch] call Waldo_fnc_EcoCore_scheduleLocalWorldActionRepair;
 */

params [["_epoch", -1, [0]]];

if (!hasInterface || {_epoch < 0}) exitWith {false};
if (_epoch != (missionNamespace getVariable ["WaldoEcoCore_LocalWorldActionServiceEpoch", -2])) exitWith {false};

[
    {
        params ["_epoch"];

        if (_epoch != (missionNamespace getVariable ["WaldoEcoCore_LocalWorldActionServiceEpoch", -2])) exitWith {};
        if !([] call Waldo_fnc_EcoCore_isModuleActive) exitWith {};

        [] call Waldo_fnc_EcoCore_requestLocalWorldActionRefresh;
        [_epoch] call Waldo_fnc_EcoCore_scheduleLocalWorldActionRepair;
    },
    [_epoch],
    10
] call CBA_fnc_waitAndExecute;

true
