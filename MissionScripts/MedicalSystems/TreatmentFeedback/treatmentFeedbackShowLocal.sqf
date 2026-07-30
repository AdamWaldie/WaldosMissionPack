/* One-way local presentation endpoint for already formatted treatment feedback. */
params [
    ["_title", "TREATMENT UPDATE", [""]],
    ["_message", "Medical treatment", [""]],
    ["_semanticState", "INFO", [""]]
];
if (!hasInterface || {_message isEqualTo ""}) exitWith {false};
private _duration = ((missionNamespace getVariable ["Waldo_TreatmentFeedback_Duration", 3]) max 1) min 15;
[_title, _message, _semanticState, _duration, "BOTTOM_CENTER", "TREATMENT_FEEDBACK", "MEDICAL", "REPLACE", 1, true] call Waldo_fnc_ShowUiNotification;
true
