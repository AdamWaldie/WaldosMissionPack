/*
 * Author: WaldoTheWarfighter
 * Coalesces Economy registry changes into one next-frame local action reconciliation.
 *
 * Locality/authority: interface client only. Repeat/JIP behaviour: repeat-safe; multiple registry
 * publications in one frame schedule one refresh. The callback rechecks active state, so purge can
 * safely invalidate pending work without cancelling an engine or CBA handler.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * BOOL - true when a refresh is queued/already pending; false outside an active interface client.
 *
 * Current callers: local action service, runtime registry mutation on a listen server.
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_requestLocalWorldActionRefresh;
 */

if (!hasInterface || {!([] call Waldo_fnc_EcoCore_isModuleActive)}) exitWith {false};
if (missionNamespace getVariable ["WaldoEcoCore_LocalWorldActionRefreshPending", false]) exitWith {true};

missionNamespace setVariable ["WaldoEcoCore_LocalWorldActionRefreshPending", true];
[
    {
        missionNamespace setVariable ["WaldoEcoCore_LocalWorldActionRefreshPending", false];
        [] call Waldo_fnc_EcoCore_refreshLocalWorldActions;
    },
    []
] call CBA_fnc_execNextFrame;

true
