/* Audit player pre-hook. Manual tests remain opt-in after the normal pack startup. */
if (!hasInterface) exitWith {};
missionNamespace setVariable ["Waldo_QA_FeatureRangeClientReady", false];
missionNamespace setVariable ["Waldo_QA_FeatureRangeClientStarting", false];
// Production keeps accessibility access limited to configured recipients. The audit
// makes the current tester eligible locally without weakening release defaults.
private _auditUid = getPlayerUID player;
missionNamespace setVariable ["Waldo_WmpHud_AccessibilityUIDs", if (_auditUid == "") then {[]} else {[_auditUid]}];
