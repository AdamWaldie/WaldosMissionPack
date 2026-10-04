/*
 * Author: WaldoTheWarfighter
 * Removes the local ACE treatment feedback handlers.
 * Locality/authority: interface client only. It removes presentation listeners, not treatment.
 * Repeat/JIP: safe to call before installation or more than once; each joining client has its own
 * listener set.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * No useful value.
 * Current callers: feature-runtime disable path and optional mission-maker client scripts.
 *
 * Example:
 * [] call Waldo_fnc_TreatmentFeedbackStop;
 * Result: later ACE treatment events produce no WMP card on this client.
 */

if !(hasInterface) exitWith {};

{
    _x params ["_eventName", "_handlerId"];
    [_eventName, _handlerId] call CBA_fnc_removeEventHandler;
} forEach (missionNamespace getVariable ["Waldo_TreatmentFeedback_Handlers", []]);
missionNamespace setVariable ["Waldo_TreatmentFeedback_Handlers", []];
missionNamespace setVariable ["Waldo_TreatmentFeedback_Started", false];
