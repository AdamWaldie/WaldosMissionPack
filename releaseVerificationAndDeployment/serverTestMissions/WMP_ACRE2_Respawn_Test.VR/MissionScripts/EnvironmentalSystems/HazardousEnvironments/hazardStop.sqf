/*
 * Author: WaldoTheWarfighter, Val
 * Stops local hazard evaluation and clears its status display.
 *
 * This affects only the executing client and leaves authoritative zone definitions untouched. It is
 * currently called by live runtime deactivation, mission cleanup and the full-pack function station.
 * Locality and authority: Interface-client only. It stops local evaluation/UI and deliberately
 * leaves the server-owned zone registry unchanged.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_HazardStop;
 * Result: Terminates the local loop, clears local exposure/transition state and hides the panel.
 * Current callers: runtime deactivation, snapshot reconciliation, cleanup and the audit station.
 */

if !(hasInterface) exitWith {};
missionNamespace setVariable ["Waldo_Hazard_ClientStarted", false];
private _handle = missionNamespace getVariable ["Waldo_Hazard_ClientLoop", scriptNull];
if !(scriptDone _handle) then {terminate _handle};
[] call Waldo_fnc_HazardResetLocal;
diag_log "[WMP HAZARD] Local evaluator stopped and exposure state cleared.";
