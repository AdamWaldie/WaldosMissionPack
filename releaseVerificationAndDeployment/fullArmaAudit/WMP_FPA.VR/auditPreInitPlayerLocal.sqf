/* Audit player pre-hook. Manual tests remain opt-in after the normal pack startup. */
if (!hasInterface) exitWith {};
missionNamespace setVariable ["Waldo_QA_FeatureRangeClientReady", false];
missionNamespace setVariable ["Waldo_QA_FeatureRangeClientStarting", false];
