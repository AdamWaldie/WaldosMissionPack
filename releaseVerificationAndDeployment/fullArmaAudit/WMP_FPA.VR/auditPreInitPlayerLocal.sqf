/* Audit player pre-hook. Manual tests remain opt-in after the normal pack startup. */
if (!hasInterface) exitWith {};
missionNamespace setVariable ["Waldo_QA_FeatureRangeClientReady", false];
missionNamespace setVariable ["Waldo_QA_FeatureRangeClientStarting", false];
// Production intentionally limits PID to its configured recipient. The audit
// must make the current tester eligible locally without weakening that default.
private _auditUid = getPlayerUID player;
missionNamespace setVariable ["Waldo_AccessibilityPID_AllowedUIDs", if (_auditUid == "") then {[]} else {[_auditUid]}];
