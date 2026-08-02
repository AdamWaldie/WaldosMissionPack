/*
 * Author: WaldoTheWarfighter
 * Removes the local friendly identification overlay and toggle action.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_AccessibilityPIDStop;
 */

if !(hasInterface) exitWith {};
private _eventId = missionNamespace getVariable ["Waldo_AccessibilityPID_EventId", -1];
if (_eventId >= 0) then {removeMissionEventHandler ["Draw3D", _eventId]};
missionNamespace setVariable ["Waldo_AccessibilityPID_Visible", false];
missionNamespace setVariable ["Waldo_AccessibilityPID_ClientStarted", false];
