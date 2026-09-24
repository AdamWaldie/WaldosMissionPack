/*
 * Author: WaldoTheWarfighter
 * Purpose: Prepare local full-pack audit controls before the normal client startup.
 * Locality / Authority: Interface client only; changes no server-owned settings.
 * Repeat / JIP: Runs once per joining client and is safe to repeat.
 * Arguments: None.
 * Return Value: Nothing.
 * Current caller: Generated full-pack audit initPlayerLocal.sqf.
 * Example: call compile preprocessFileLineNumbers "auditPreInitPlayerLocal.sqf";
 */
if (!hasInterface) exitWith {};
missionNamespace setVariable ["Waldo_QA_FeatureRangeClientReady", false];
missionNamespace setVariable ["Waldo_QA_FeatureRangeClientStarting", false];
// Production keeps accessibility access limited to configured recipients. The audit
// makes the current tester eligible locally without weakening release defaults.
private _auditUid = getPlayerUID player;
missionNamespace setVariable ["Waldo_WmpHud_AccessibilityUIDs", if (_auditUid == "") then {[]} else {[_auditUid]}];
