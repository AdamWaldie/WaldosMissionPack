/*
 * Author: WaldoTheWarfighter
 * Defines server-authoritative electronic-warfare and jammer defaults. Every entry is published
 * once by initServer for current clients and JIP; later server/ZEN changes remain authoritative.
 *
 * Schema: SERVER entries are [missionNamespace variable name, guarded default, publish BOOL].
 * Arguments: None. Return Value: HASHMAP consumed by Waldo_fnc_LoadFeatureConfigs.
 *
 * Example: tune ScanDistanceBands as absolute metre thresholds for RDF distance wording.
 * Result: later player scans describe contacts using the configured distance bands.
 * Current caller: Waldo_fnc_LoadFeatureConfigs from initServer.sqf using the SERVER scope.
 *
 * ACTIVATION MODEL: ENABLE PLUS REGISTERED/CREATED OBJECTS.
 * Waldo_Jamming_Enable starts the shared EW service but creates no jammer. Register an editor object
 * with `[this] call Waldo_fnc_Jammer;`, create one from a server script/trigger, or use ZEN. EMP and
 * trackers are on-demand calls and use these systems without needing a separate automatic object.
 *
 * EDIT FOR A NORMAL MISSION: master availability, player feedback, toggle/destruction rules and the
 * optional disable challenge. LEAVE ALONE UNLESS EXTENDING/TESTING: attenuation/RDF maths and GM
 * diagnostics. CUSTOM CALLS: object init is supported for Waldo_fnc_Jammer and
 * Waldo_fnc_EMPImmune; use initServer.sqf or a server-owned trigger for pre-planned EMP/tracker work.
 *
 * CUSTOMISATION GUIDE:
 * MISSION MAKER - enablement, player feedback, LOS/burn-through/destruction rules, player toggle,
 * disable challenge, engineer restriction and success result are intended scenario choices.
 * DisableResult is DISABLE (repairable/reactivatable disabled state) or DEACTIVATE (ordinary off).
 * ChallengeDifficulty is easy, standard, hard or expert and ChallengeId must be a registered WMP
 * interaction-equipment procedure such as circuit.
 * ADVANCED TUNING - BurnThroughRef, Curve, ScanRange, ScanBearingArc and ScanDistanceBands define
 * signal/RDF maths. Curve is LINEAR unless an implementation-supported alternative is documented.
 * Distances are metres; bearing arc is total degrees; distance bands are ascending absolute metre
 * thresholds [near, medium, distant]. Keep GM overlay false outside diagnostics.
 *
 * HOW TO READ THE DATA BELOW:
 * Every `server` row is `[variable name, default value, publish to clients/JIP]`. `true` in the
 * third field means the server owns the value and broadcasts later changes; it is not another
 * enable switch. These settings configure the EW service only. A jammer object must still be
 * registered or created, and its own range/power/frequency settings remain object-specific.
 */
createHashMapFromArray [
    ["featureFamilies", ["Electronic Warfare", "Radio Jamming"]],
    ["server", [
        // MISSION MAKER: EW availability and gameplay rules.
        ["Waldo_Jamming_Enable", true, true],       // BOOL: starts EW services; does not create a jammer.
        ["Waldo_Jamming_Notify", true, true],       // BOOL: show affected players WMP interference feedback.
        ["Waldo_Jamming_LOS", true, true],          // BOOL: terrain/objects reduce a jammer's effective signal.
        ["Waldo_Jamming_BurnThrough", true, true],  // BOOL: very close radios may overcome interference.
        ["Waldo_Jamming_BurnThroughRef", 500, true], // ADVANCED reference distance in metres.
        ["Waldo_Jamming_Curve", "LINEAR", true],   // ADVANCED supported attenuation curve ID.
        ["Waldo_Jamming_Destructible", true, true], // BOOL: destruction can stop registered jammer objects.
        ["Waldo_Jamming_GmOverlay", false, true],   // ADVANCED diagnostics only.
        ["Waldo_Jamming_ScanRange", 3000, true],    // ADVANCED maximum RDF range in metres.
        ["Waldo_Jamming_ScanBearingArc", 30, true], // ADVANCED total vague bearing sector in degrees.
        ["Waldo_Jamming_ScanDistanceBands", [35, 150, 600], true], // METRES: <=35 nearby, <=150 close, <=600 distant, then very distant.
        ["Waldo_Jamming_AllowPlayerToggle", true, true], // BOOL: ordinary activate/deactivate operator action.
        ["Waldo_Jamming_DisableChallenge", true, true], // true: active jammers use Disable Jammer and its minigame instead of a bypass toggle.
        ["Waldo_Jamming_DisableChallengeId", "circuit", true], // STRING: registered interaction-equipment ID.
        ["Waldo_Jamming_DisableDifficulty", "standard", true], // STRING: easy, standard, hard or expert.
        ["Waldo_Jamming_DisableEngineerOnly", false, true], // false: anyone may try; true: only ACE engineers may try.
        ["Waldo_Jamming_DisableResult", "DISABLE", true] // DISABLE or DEACTIVATE.
    ]]
]
