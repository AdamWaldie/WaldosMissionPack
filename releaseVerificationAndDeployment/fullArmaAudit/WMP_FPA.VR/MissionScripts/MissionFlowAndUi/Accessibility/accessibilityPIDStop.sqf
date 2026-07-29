/*
 * Author: Waldo
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
private _actionUnit = missionNamespace getVariable ["Waldo_AccessibilityPID_ActionUnit", objNull];
private _actionPath = missionNamespace getVariable ["Waldo_AccessibilityPID_ActionPath", []];
if (!isNull _actionUnit && {count _actionPath > 0} && {!(isNil "ace_interact_menu_fnc_removeActionFromObject")}) then {
    [_actionUnit, 1, _actionPath] call ace_interact_menu_fnc_removeActionFromObject;
};
missionNamespace setVariable ["Waldo_AccessibilityPID_ActionUnit", objNull];
missionNamespace setVariable ["Waldo_AccessibilityPID_ActionPath", []];
missionNamespace setVariable ["Waldo_AccessibilityPID_Visible", false];
missionNamespace setVariable ["Waldo_AccessibilityPID_ClientStarted", false];
