/*
 * Author: Waldo
 * Stops local hazard evaluation and clears its status display.
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
private _handle = missionNamespace getVariable ["Waldo_Hazard_ClientLoop", scriptNull];
if !(scriptDone _handle) then {terminate _handle};
["", safeZoneX, safeZoneY, 0, 0, 0, 791] spawn BIS_fnc_dynamicText;
