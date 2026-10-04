/*
 * Author: WaldoTheWarfighter
 * Purpose: Enables opt-in features for the disposable full-pack audit only.
 * Locality / Authority: Runs on server and clients before the real init.sqf; the server later
 * publishes the authoritative ordered settings snapshot.
 * Repeat / JIP: Re-execution writes the same QA defaults; JIP receives the server snapshot.
 * Arguments: None. Return Value: Nothing.
 * Current caller: generated audit init.sqf pre-hook.
 * Example: call compile preprocessFileLineNumbers "auditPreInit.sqf";
 */
missionNamespace setVariable ["Waldo_Economy_Enable", true];
missionNamespace setVariable ["Waldo_Jamming_Enable", true];
missionNamespace setVariable ["Waldo_QA_ManualAudit", !(missionNamespace getVariable ["Waldo_QA_RunAutomation", false])];

// The full audit is also the supported HC testbed. Keep native HC handling and its detailed RPT
// trace enabled here so dedicated runs exercise registration, migration, AI reapplication and
// server-owned feature exclusions without changing the release defaults.
missionNamespace setVariable ["Waldo_Headless_Enable", true];
// QA-only opt-in: release missions keep cruise deceleration disabled by default. This station tests
// ordinary braking and confirms that a subsequent landing order takes unconditional priority.
missionNamespace setVariable ["Waldo_HelicopterDeceleration_Enable", true];
missionNamespace setVariable ["Waldo_HelicopterDeceleration_Debug", true];
missionNamespace setVariable ["Waldo_Headless_Debug", true];

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
missionNamespace setVariable ["Waldo_BaseServices_Enable", true];
missionNamespace setVariable ["Waldo_SupplyTransfers_Enable", true];
missionNamespace setVariable ["Waldo_PhysicalCargo_Enable", true];
missionNamespace setVariable ["Waldo_PhysicalCargo_BlockSeats", true];
{missionNamespace setVariable [format ["Waldo_QM_%1_Enable", _x], true]} forEach
    ["Grenades", "Explosives", "Rearm", "FuelBarrel", "FuelJerrycan"];
