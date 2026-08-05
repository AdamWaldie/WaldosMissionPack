/*
 * Audit pre-configuration shared by server and clients.
 * This runs before the real init.sqf so feature installers see the intended state once.
 */
missionNamespace setVariable ["Waldo_Economy_Enable", true];
missionNamespace setVariable ["Waldo_Jamming_Enable", true];
missionNamespace setVariable ["Waldo_QA_ManualAudit", !(missionNamespace getVariable ["Waldo_QA_RunAutomation", false])];

// The feature range deliberately enables opt-in systems in this mission only.
// Persistence remains disabled until its server-extension dependency is proven.
missionNamespace setVariable ["Waldo_TreatmentFeedback_Enable", true];
missionNamespace setVariable ["Waldo_TreatmentFeedback_NotifyMedic", true];
missionNamespace setVariable ["Waldo_Hazard_Enable", true];
missionNamespace setVariable ["Waldo_TreeFelling_Enable", true];
missionNamespace setVariable ["Waldo_TreeFelling_Range", 4];
missionNamespace setVariable ["Waldo_TreeFelling_BaseHits", 2];
missionNamespace setVariable ["Waldo_TreeFelling_HeightFactor", 0];
missionNamespace setVariable ["Waldo_TreeFelling_HitCooldown", 0.2];
missionNamespace setVariable ["Waldo_TreeFelling_RegrowSeconds", 20];
missionNamespace setVariable ["Waldo_TreeFelling_AllowedClasses", ["Land_TreeBin_F"]];
missionNamespace setVariable ["Waldo_TreeFelling_WeaponPatterns", ["arifle_mx", "axe", "hatchet"]];
missionNamespace setVariable ["Waldo_Breaching_Enable", true];
missionNamespace setVariable ["Waldo_FieldResupply_Enable", true];
missionNamespace setVariable ["Waldo_Rally_Enable", true];
missionNamespace setVariable ["Waldo_Rally_Duration", 60];
missionNamespace setVariable ["Waldo_Rally_DeploymentTime", 3];
missionNamespace setVariable ["Waldo_Rally_Cooldown", 5];
missionNamespace setVariable ["Waldo_Rally_MinimumGroupMembers", 1];
missionNamespace setVariable ["Waldo_Rally_EnemyExclusionRadius", 20];
missionNamespace setVariable ["Waldo_Rally_AllowRegroup", true];
missionNamespace setVariable ["Waldo_EmergencyDismount_Enable", true];
missionNamespace setVariable ["Waldo_EmergencyDismount_MinimumOverturnSeconds", 0.75];
missionNamespace setVariable ["Waldo_WmpHud_Enable", true];
missionNamespace setVariable ["Waldo_WmpHud_IncludeAI", true];
