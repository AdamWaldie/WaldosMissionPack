/*
 * Author: WaldoTheWarfighter
 * Defines server-authoritative electronic-warfare and jammer defaults. Every entry is published
 * once by initServer for current clients and JIP; later server/ZEN changes remain authoritative.
 *
 * Schema: SERVER entries are [missionNamespace variable name, guarded default, publish BOOL].
 * Arguments: None. Return Value: HASHMAP consumed by Waldo_fnc_LoadFeatureConfigs.
 *
 * Example: tune ScanDistanceBands as absolute metre thresholds for RDF distance wording.
 * Current caller: Waldo_fnc_LoadFeatureConfigs from initServer.sqf using the SERVER scope.
 */
createHashMapFromArray [
    ["featureFamilies", ["Electronic Warfare", "Radio Jamming"]],
    ["server", [
        ["Waldo_Jamming_Enable", true, true],
        ["Waldo_Jamming_Notify", true, true],
        ["Waldo_Jamming_LOS", true, true],
        ["Waldo_Jamming_BurnThrough", true, true],
        ["Waldo_Jamming_BurnThroughRef", 500, true],
        ["Waldo_Jamming_Curve", "LINEAR", true],
        ["Waldo_Jamming_Destructible", true, true],
        ["Waldo_Jamming_GmOverlay", false, true],
        ["Waldo_Jamming_ScanRange", 3000, true],
        ["Waldo_Jamming_ScanBearingArc", 30, true],
        ["Waldo_Jamming_ScanDistanceBands", [35, 150, 600], true],
        ["Waldo_Jamming_AllowPlayerToggle", true, true],
        ["Waldo_Jamming_DisableChallenge", false, true],
        ["Waldo_Jamming_DisableChallengeId", "circuit", true],
        ["Waldo_Jamming_DisableDifficulty", "standard", true],
        ["Waldo_Jamming_DisableEngineerOnly", true, true],
        ["Waldo_Jamming_DisableResult", "DISABLE", true]
    ]]
]
