/*
 * Author: WaldoTheWarfighter
 * Purpose: Present one already formatted ACE treatment message in the WMP notification lane.
 * Locality and authority: Interface client only. The treating-unit owner or a validated remote
 * call supplies the content; this function does not change treatment or server state.
 * Repeat/JIP: New treatment cards replace this channel's current card. Prior transient cards
 * are not replayed to joining players.
 * Arguments:
 * 0: title <STRING> (default "TREATMENT UPDATE").
 * 1: message <STRING> (default "Medical treatment").
 * 2: semanticState <STRING> (default "INFO").
 * Return Value: BOOLEAN - true when queued for local notification; false without an interface
 * or with an empty message.
 * Current caller: Waldo_fnc_TreatmentFeedbackNotify, locally or via remoteExecCall to a patient.
 * Example: ["TREATMENT COMPLETE", "Bandage applied", "SUCCESS"] call Waldo_fnc_TreatmentFeedbackShowLocal;
 * Result: The executing player sees a timed bottom-centre treatment notification.
 */
params [
    ["_title", "TREATMENT UPDATE", [""]],
    ["_message", "Medical treatment", [""]],
    ["_semanticState", "INFO", [""]]
];
if (!hasInterface || {_message isEqualTo ""}) exitWith {false};
private _duration = ((missionNamespace getVariable ["Waldo_TreatmentFeedback_Duration", 3]) max 1) min 15;
[_title, _message, _semanticState, _duration, "BOTTOM_CENTER", "TREATMENT_FEEDBACK", "MEDICAL", "REPLACE", 1, true] call Waldo_fnc_ShowUiNotification;
true
