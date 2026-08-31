/*
 * Author: WaldoTheWarfighter
 * Starts change-driven Economy world-action reconciliation plus ten-second repair fallback.
 *
 * Locality/authority: interface client only. Repeat/JIP behaviour: repeat-safe; the public registry
 * revision listener is installed once before initial reconciliation, covering either JIP arrival
 * order. Arma does not provide removal for public-variable event handlers, so the permanent local
 * listener is inert while the service is stopped. A new service epoch owns its one-shot repair
 * chain and is invalidated by cleanup/purge.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * BOOL - true when active/already active; false outside an active interface client.
 *
 * Current callers: economyInit.
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_startLocalWorldActionService;
 */

if (!hasInterface || {!([] call Waldo_fnc_EcoCore_isModuleActive)}) exitWith {false};
if (missionNamespace getVariable ["WaldoEcoCore_LocalWorldActionServiceStarted", false]) exitWith {true};

private _epoch = (missionNamespace getVariable ["WaldoEcoCore_LocalWorldActionServiceEpoch", 0]) + 1;
missionNamespace setVariable ["WaldoEcoCore_LocalWorldActionServiceEpoch", _epoch];
missionNamespace setVariable ["WaldoEcoCore_LocalWorldActionServiceStarted", true];

if !(missionNamespace getVariable ["WaldoEcoCore_LocalWorldActionRegistryPVEHInstalled", false]) then {
    "WaldoEcoCore_RuntimeRegistryRevision" addPublicVariableEventHandler {
        if (missionNamespace getVariable ["WaldoEcoCore_LocalWorldActionServiceStarted", false]) then {
            [] call Waldo_fnc_EcoCore_requestLocalWorldActionRefresh;
        };
    };
    missionNamespace setVariable ["WaldoEcoCore_LocalWorldActionRegistryPVEHInstalled", true];
};

[] call Waldo_fnc_EcoCore_requestLocalWorldActionRefresh;
[_epoch] call Waldo_fnc_EcoCore_scheduleLocalWorldActionRepair;

true
