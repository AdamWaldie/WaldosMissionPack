/*
 * Author: WaldoTheWarfighter
 * Installs repeat-safe ACE treatment event handlers for patient and medic notifications.
 *
 * The treatment-success event is registered under both its current upstream spelling,
 * "ace_treatmentSucceded" (a known typo - missing the second "e" in "succeeded" - present in
 * ACE3's events framework as of this writing), and the corrected "ace_treatmentSucceeded", so this
 * feature keeps working unchanged whichever spelling a given mission's ACE build actually fires.
 * Registering for an event name ACE never fires is a harmless no-op in CBA's event system; only
 * one of the two is expected to actually fire on any given ACE version.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Boolean - true when active or already installed
 *
 * Example:
 * [] call Waldo_fnc_TreatmentFeedbackInit;
 */

if !(hasInterface) exitWith {false};
if !(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", isServer]) exitWith {
    [] spawn {
        waitUntil {
            missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]
            || {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotFailed", false]}
        };
        if (missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]) then {[] call Waldo_fnc_TreatmentFeedbackInit};
    };
    true
};
if !(missionNamespace getVariable ["Waldo_TreatmentFeedback_Enable", false]) exitWith {false};
if !(isClass (configFile >> "CfgPatches" >> "ace_medical")) exitWith {false};
if (missionNamespace getVariable ["Waldo_TreatmentFeedback_Started", false]) exitWith {true};

private _handlers = [
    ["ace_treatmentStarted", ["ace_treatmentStarted", {
        ["START", _this] call Waldo_fnc_TreatmentFeedbackNotify;
    }] call CBA_fnc_addEventHandler],
    ["ace_treatmentSucceded", ["ace_treatmentSucceded", {
        ["SUCCESS", _this] call Waldo_fnc_TreatmentFeedbackNotify;
    }] call CBA_fnc_addEventHandler],
    // Corrected spelling, in case/once ACE ships the "Succeded" -> "Succeeded" typo fix upstream.
    ["ace_treatmentSucceeded", ["ace_treatmentSucceeded", {
        ["SUCCESS", _this] call Waldo_fnc_TreatmentFeedbackNotify;
    }] call CBA_fnc_addEventHandler],
    ["ace_treatmentFailed", ["ace_treatmentFailed", {
        ["FAILURE", _this] call Waldo_fnc_TreatmentFeedbackNotify;
    }] call CBA_fnc_addEventHandler]
];

missionNamespace setVariable ["Waldo_TreatmentFeedback_Handlers", _handlers];
missionNamespace setVariable ["Waldo_TreatmentFeedback_Started", true];
true
