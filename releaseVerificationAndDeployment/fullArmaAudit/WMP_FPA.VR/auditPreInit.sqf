/*
 * Audit pre-configuration shared by server and clients.
 * This runs before the real init.sqf so feature installers see the intended state once.
 */
missionNamespace setVariable ["Waldo_Economy_Enable", true];
missionNamespace setVariable ["Waldo_Jamming_Enable", true];
missionNamespace setVariable ["Waldo_QA_ManualAudit", !(missionNamespace getVariable ["Waldo_QA_RunAutomation", false])];
