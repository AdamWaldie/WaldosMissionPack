/*
 * Author: Waldo
 * Stops the local emergency-dismount monitor.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EmergencyDismountStop;
 */

if !(hasInterface) exitWith {};
missionNamespace setVariable ["Waldo_EmergencyDismount_ClientStarted", false];
private _handle = missionNamespace getVariable ["Waldo_EmergencyDismount_ClientLoop", scriptNull];
if !(scriptDone _handle) then {terminate _handle};
