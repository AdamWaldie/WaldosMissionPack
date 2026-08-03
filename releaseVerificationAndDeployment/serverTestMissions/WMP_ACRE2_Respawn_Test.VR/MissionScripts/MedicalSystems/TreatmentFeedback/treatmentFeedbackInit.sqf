/*
 * Author: WaldoTheWarfighter
 * Installs repeat-safe ACE treatment event handlers for patient and medic notifications.
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
    ["ace_treatmentFailed", ["ace_treatmentFailed", {
        ["FAILURE", _this] call Waldo_fnc_TreatmentFeedbackNotify;
    }] call CBA_fnc_addEventHandler]
];

missionNamespace setVariable ["Waldo_TreatmentFeedback_Handlers", _handlers];
missionNamespace setVariable ["Waldo_TreatmentFeedback_Started", true];
true
