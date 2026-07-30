/*
 * Author: WaldoTheWarfighter
 * Displays one configured ACE treatment event through the pack notification UI.
 *
 * Arguments:
 * 0: state <STRING> - START, SUCCESS or FAILURE
 * 1: event arguments <ARRAY> - medic, patient, body part and treatment classname
 *
 * Return Value:
 * Boolean - true when a notification was shown locally
 *
 * Example:
 * ["SUCCESS", _this] call Waldo_fnc_TreatmentFeedbackNotify;
 */

params [
    ["_state", "", [""]],
    ["_eventArguments", [], [[]]]
];
if !(missionNamespace getVariable ["Waldo_TreatmentFeedback_Enable", false]) exitWith {false};

_eventArguments params [
    ["_medic", objNull, [objNull]],
    ["_patient", objNull, [objNull]],
    ["_bodyPart", "", [""]],
    ["_treatment", "", [""]]
];
if (isNull _patient) exitWith {false};
// ACE treatment events may be raised on more than one machine. Only the
// machine that owns the treating unit formats and dispatches feedback.
if (remoteExecutedOwner > 0 || {isNull _medic} || {!local _medic}) exitWith {false};

private _enabled = switch (toUpperANSI _state) do {
    case "START": {missionNamespace getVariable ["Waldo_TreatmentFeedback_ShowStart", true]};
    case "SUCCESS": {missionNamespace getVariable ["Waldo_TreatmentFeedback_ShowSuccess", true]};
    case "FAILURE": {missionNamespace getVariable ["Waldo_TreatmentFeedback_ShowFailure", true]};
    default {false};
};
if !(_enabled) exitWith {false};

private _title = switch (toUpperANSI _state) do {
    case "START": {missionNamespace getVariable ["Waldo_TreatmentFeedback_StartTitle", "TREATMENT STARTED"]};
    case "SUCCESS": {missionNamespace getVariable ["Waldo_TreatmentFeedback_SuccessTitle", "TREATMENT COMPLETE"]};
    default {missionNamespace getVariable ["Waldo_TreatmentFeedback_FailureTitle", "TREATMENT FAILED"]};
};

private _treatmentNames = missionNamespace getVariable ["Waldo_TreatmentFeedback_TreatmentNames", createHashMap];
private _treatmentName = _treatmentNames getOrDefault [_treatment, ""];
if (_treatmentName == "" && {_treatment != ""}) then {
    _treatmentName = getText (configFile >> "CfgWeapons" >> _treatment >> "displayName");
};
if (_treatmentName == "") then {_treatmentName = if (_treatment == "") then {"Medical treatment"} else {_treatment}};

private _lines = [_treatmentName];
if (missionNamespace getVariable ["Waldo_TreatmentFeedback_ShowMedicName", true] && {!isNull _medic}) then {
    _lines pushBack format ["Medic: %1", name _medic];
};
if (missionNamespace getVariable ["Waldo_TreatmentFeedback_ShowBodyPart", true] && {_bodyPart != ""}) then {
    private _bodyPartNames = missionNamespace getVariable ["Waldo_TreatmentFeedback_BodyPartNames", createHashMapFromArray [
        ["head", "Head"], ["body", "Torso"], ["leftarm", "Left arm"], ["rightarm", "Right arm"],
        ["leftleg", "Left leg"], ["rightleg", "Right leg"]
    ]];
    _lines pushBack format ["Location: %1", _bodyPartNames getOrDefault [toLowerANSI _bodyPart, _bodyPart]];
};
private _semanticState = switch (toUpperANSI _state) do {case "SUCCESS": {"SUCCESS"}; case "FAILURE": {"ERROR"}; default {"INFO"}};
private _message = _lines joinString "<br/>";
private _notifyPatient = missionNamespace getVariable ["Waldo_TreatmentFeedback_NotifyPatient", true];
private _notifyMedic = missionNamespace getVariable ["Waldo_TreatmentFeedback_NotifyMedic", false];
private _shownLocally = false;

if (_notifyPatient && {isPlayer _patient}) then {
    if (hasInterface && {player isEqualTo _patient}) then {
        [_title, _message, _semanticState] call Waldo_fnc_TreatmentFeedbackShowLocal;
        _shownLocally = true;
    } else {
        [_title, _message, _semanticState] remoteExecCall ["Waldo_fnc_TreatmentFeedbackShowLocal", owner _patient];
    };
};
if (_notifyMedic && {hasInterface} && {player isEqualTo _medic} && {!(_shownLocally && {_medic isEqualTo _patient})}) then {
    [_title, _message, _semanticState] call Waldo_fnc_TreatmentFeedbackShowLocal;
    _shownLocally = true;
};
_shownLocally || {_notifyPatient && {isPlayer _patient}}
