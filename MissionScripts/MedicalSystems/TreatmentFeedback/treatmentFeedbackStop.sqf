/*
 * Author: Waldo
 * Removes the local ACE treatment feedback handlers.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_TreatmentFeedbackStop;
 */

if !(hasInterface) exitWith {};

{
    _x params ["_eventName", "_handlerId"];
    [_eventName, _handlerId] call CBA_fnc_removeEventHandler;
} forEach (missionNamespace getVariable ["Waldo_TreatmentFeedback_Handlers", []]);
missionNamespace setVariable ["Waldo_TreatmentFeedback_Handlers", []];
missionNamespace setVariable ["Waldo_TreatmentFeedback_Started", false];
