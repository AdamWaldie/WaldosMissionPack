/*
 * Server configuration applied before the real initServer.sqf.
 * Defaults in the release entry point preserve these explicit mission-maker values.
 */
if (!isServer) exitWith {};
if (!isNil "qa_player_1") then {(group qa_player_1) setGroupIdGlobal ["VIKING-1-1"]};
missionNamespace setVariable ["WALDO_STATIC_STATICCHUTE", "B_Parachute", true];
// The audit range creates its fixtures after the real pack startup. Automatic
// diagnostics would therefore report healthy-but-not-yet-configured stations.
// Manual mode exposes an explicit console action; automated mode runs once the
// feature range has published Waldo_QA_FeatureRangeReady.
missionNamespace setVariable ["Waldo_RunDiagnostics", false, true];
missionNamespace setVariable ["Waldo_SafeStart_AutoStart", false, true];
missionNamespace setVariable ["Waldo_Economy_Enable", true, true];
missionNamespace setVariable ["Waldo_Economy_Preset", "MEDIUM", true];
missionNamespace setVariable [
    "Waldo_Economy_PresetSides",
    [["WEST", "NATO"], ["EAST", "CSAT"], ["GUER", "AAF"]],
    true
];
