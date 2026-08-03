/*
 * Author: WaldoTheWarfighter
 * Stops local hazard evaluation and clears its status display.
 *
 * This affects only the executing client and leaves authoritative zone definitions untouched. It is
 * currently called by live runtime deactivation, mission cleanup and the full-pack function station.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_HazardStop;
 */

if !(hasInterface) exitWith {};
missionNamespace setVariable ["Waldo_Hazard_ClientStarted", false];
missionNamespace setVariable ["Waldo_Hazard_LocalInside", createHashMap];
missionNamespace setVariable ["Waldo_Hazard_LocalDamageStages", createHashMap];
private _handle = missionNamespace getVariable ["Waldo_Hazard_ClientLoop", scriptNull];
if !(scriptDone _handle) then {terminate _handle};
uiNamespace setVariable ["Waldo_Hazard_StatusText", ""];
["HAZARD_STATUS"] call Waldo_fnc_DismissUiNotification;
