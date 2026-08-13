/*
 * Author: WaldoTheWarfighter
 * Defines AI rebalance selection, filters, display names and improved helicopter-landing control
 * limits. AI application and locality migration remain in MissionScripts\AiScripting.
 *
 * Schema: SHARED entries are [missionNamespace variable name, guarded default value].
 * Arguments: None.
 * Return Value: HASHMAP consumed by Waldo_fnc_LoadFeatureConfigs.
 *
 * Example: change Waldo_AIRebalance_Profile from LINE to MILITIA, VETERAN or ELITE.
 * Result: eligible AI receive that named WMP skill profile when the automatic handler applies it.
 * Current caller: Waldo_fnc_LoadFeatureConfigs from init.sqf using the SHARED scope.
 *
 * ACTIVATION MODEL: AUTOMATIC WHEN EACH ENABLE SWITCH IS TRUE.
 * No custom call is required. AI rebalance follows AI locality on server, headless client or client;
 * improved landing watches local AI helicopter pilots with LAND/UNLOAD/TRANSPORT UNLOAD/GET OUT
 * waypoints. Setting an enable switch false prevents that handler from starting.
 *
 * EDIT FOR A NORMAL MISSION: both Enable switches, AI profile/mode/apply population and optional
 * side/faction/class filters. LEAVE ALONE UNLESS EXTENDING/TESTING: skill variance, restore policy,
 * display-name keys and every helicopter controller distance/rate/timing value.
 * CUSTOM CALLS: not required. Runtime AI profile changes should use Waldo_fnc_AIRebalanceInit;
 * Waldo_fnc_AIRebalanceStop restores recorded skills when RestoreOnStop is true.
 *
 * CUSTOMISATION GUIDE:
 * MISSION MAKER - enable, Profile, Mode and include/exclude filters are intended choices. Profiles
 * are MILITIA, LINE, VETERAN or ELITE; LINE is the WMP default for editor and Zeus AI. Mode is DAY
 * or NIGHT. ApplyMode is BOTH, EXISTING or NEW. Side filters use WEST, EAST, GUER or CIV; faction
 * and class filters use config classnames. Empty include arrays mean unrestricted.
 * ADVANCED TUNING - SkillVariance, RestoreOnStop and every ImprovedHelicopterLanding numeric value
 * are control/safety parameters. Keep defaults unless a repeatable aircraft/terrain test requires
 * adjustment. Distances/heights are metres, rates are metres/second, intervals/times are seconds.
 *
 * HOW TO READ THE DATA BELOW:
 * `shared` rows are `[variable name, default value]`. The loader sets the default only when the
 * variable does not already exist, on every machine that may own AI. A value already supplied by
 * mission code or JIP is preserved. Mode selects lighting conditions; ApplyMode independently
 * selects which AI population receives the profile.
 *
 * SETTING-BY-SETTING GUIDE - AI REBALANCE:
 * - Waldo_AIRebalance_Enable (MISSION MAKER): true applies WMP skill profiles; false leaves AI skills alone.
 * - Waldo_AIRebalance_Profile (MISSION MAKER): MILITIA, LINE, VETERAN or ELITE; LINE is the normal baseline.
 * - Waldo_AIRebalance_Mode (MISSION MAKER): DAY or NIGHT; NIGHT uses the deliberately lower low-light values.
 * - Waldo_AI_ApplyMode (MISSION MAKER): EXISTING, NEW or BOTH; choose which AI population receives the profile.
 * - Waldo_AI_RestoreOnStop (ADVANCED): true restores the skills WMP recorded when its handler is stopped.
 * - Waldo_AI_SkillVariance (ADVANCED): stable random offset chosen once per AI; 0 disables variation.
 * - Waldo_AI_IncludedSides (MISSION MAKER): [] allows every side; example ["WEST", "GUER"] limits application.
 * - Waldo_AI_IncludedFactions (MISSION MAKER): [] allows all; otherwise list CfgFactionClasses names.
 * - Waldo_AI_ExcludedFactions (MISSION MAKER): listed factions are always skipped after the include checks.
 * - Waldo_AI_ExcludedClasses (MISSION MAKER): exact CfgVehicles unit classes that WMP must never modify.
 *
 * SETTING-BY-SETTING GUIDE - IMPROVED HELICOPTER LANDING:
 * - Waldo_ImprovedHelicopterLanding_Enable (MISSION MAKER): true watches local AI helicopter landing waypoints.
 * - Waldo_ImprovedHelicopterLanding_MinimumActivationDistance (ADVANCED): waypoint must begin at least this far away.
 * - Waldo_ImprovedHelicopterLanding_TriggerDistance (ADVANCED): distance at which WMP starts approach control.
 * - Waldo_ImprovedHelicopterLanding_TriggerSpeedFactor (ADVANCED): scales the speed-sensitive takeover test.
 * - Waldo_ImprovedHelicopterLanding_MinimumApproachSpeed (ADVANCED): minimum entry speed in km/h; prevents slow short legs.
 * - Waldo_ImprovedHelicopterLanding_TransitAltitude (ADVANCED): preferred clear-ground approach height in metres AGL.
 * - Waldo_ImprovedHelicopterLanding_GlideSlopeRatio (ADVANCED): horizontal travel per metre of planned descent.
 * - Waldo_ImprovedHelicopterLanding_TreeScanRadius (ADVANCED): vegetation search radius around the landing point.
 * - Waldo_ImprovedHelicopterLanding_TreeSafetyBuffer (ADVANCED): extra clearance above detected tree canopies.
 * - Waldo_ImprovedHelicopterLanding_MaximumTreeHoverHeight (ADVANCED): ceiling on canopy-induced hover correction.
 * - Waldo_ImprovedHelicopterLanding_GoAroundTriggerDistance (ADVANCED): range in which excessive height is tested.
 * - Waldo_ImprovedHelicopterLanding_GoAroundHeight (ADVANCED): safe AGL climb target for a retry.
 * - Waldo_ImprovedHelicopterLanding_GoAroundExitDistance (ADVANCED): distance flown clear before turning back.
 * - Waldo_ImprovedHelicopterLanding_GoAroundSpeed (ADVANCED): commanded retry speed in kilometres per hour.
 * - Waldo_ImprovedHelicopterLanding_MaximumGoArounds (ADVANCED): maximum automatic retries per landing order.
 * - Waldo_ImprovedHelicopterLanding_MaximumClimbRate (ADVANCED): upward command clamp in metres per second.
 * - Waldo_ImprovedHelicopterLanding_MaximumDescentRate (ADVANCED): downward command clamp in metres per second.
 * - Waldo_ImprovedHelicopterLanding_TouchdownRadius (ADVANCED): accepted horizontal error; 5 m is the current default.
 * - Waldo_ImprovedHelicopterLanding_FinalCommitDistance (ADVANCED): range at which flare/final landing begins.
 * - Waldo_ImprovedHelicopterLanding_ControlInterval (ADVANCED): controller update period; lowering it costs more CPU.
 * - Waldo_ImprovedHelicopterLanding_TouchdownHoldSeconds (ADVANCED): landed hold; 20 s prevents immediate takeoff.
 * - Waldo_AI_ProfileDisplayNames (INFRASTRUCTURE): labels for diagnostics/UI; keys must match implementation IDs.
 */
createHashMapFromArray [
    ["featureFamilies", ["AI Rebalance", "Improved AI Helicopter Landings"]],
    ["shared", [
        // MISSION MAKER: AI population, profile and filtering policy.
        ["Waldo_AIRebalance_Enable", true],          // BOOL: true applies WMP skill profiles to eligible AI.
        ["Waldo_AIRebalance_Profile", "LINE"],      // STRING: MILITIA, LINE, VETERAN or ELITE.
        ["Waldo_AIRebalance_Mode", "DAY"],          // STRING: DAY or NIGHT (low-light/NVG-aware skill variant).
        ["Waldo_AI_ApplyMode", "BOTH"],             // STRING: EXISTING, NEW or BOTH AI populations.
        ["Waldo_AI_RestoreOnStop", true],            // ADVANCED: restore captured vanilla/mission skills on stop.
        ["Waldo_AI_SkillVariance", 0],               // ADVANCED: one stable per-AI offset; 0 disables variation.
        ["Waldo_AI_IncludedSides", []],             // ARRAY of WEST/EAST/GUER/CIV strings; [] permits every side.
        ["Waldo_AI_IncludedFactions", []],          // ARRAY of CfgFactionClasses names; [] permits every faction.
        ["Waldo_AI_ExcludedFactions", []],          // ARRAY of faction names removed after the include filter.
        ["Waldo_AI_ExcludedClasses", []],           // ARRAY of exact CfgVehicles unit classnames never changed.
        // MISSION MAKER master switch followed by ADVANCED landing-controller tuning.
        ["Waldo_ImprovedHelicopterLanding_Enable", true], // BOOL: watches eligible landing waypoints for local AI pilots.
        ["Waldo_ImprovedHelicopterLanding_MinimumActivationDistance", 50], // METRES: waypoint must start at least this far away.
        ["Waldo_ImprovedHelicopterLanding_TriggerDistance", 500], // METRES: controller takes over inside this distance.
        ["Waldo_ImprovedHelicopterLanding_TriggerSpeedFactor", 4.2], // MULTIPLIER: approach-speed trigger scaling.
        ["Waldo_ImprovedHelicopterLanding_MinimumApproachSpeed", 55], // KM/H: minimum speed when scripted approach control begins.
        ["Waldo_ImprovedHelicopterLanding_TransitAltitude", 30], // METRES AGL: clear-terrain approach height.
        ["Waldo_ImprovedHelicopterLanding_GlideSlopeRatio", 4], // RATIO: horizontal distance per metre of descent.
        ["Waldo_ImprovedHelicopterLanding_TreeScanRadius", 25], // METRES: vegetation search around touchdown.
        ["Waldo_ImprovedHelicopterLanding_TreeSafetyBuffer", 5], // METRES: clearance added above detected canopy.
        ["Waldo_ImprovedHelicopterLanding_MaximumTreeHoverHeight", 40], // METRES: canopy correction ceiling.
        ["Waldo_ImprovedHelicopterLanding_GoAroundTriggerDistance", 200], // METRES: assess excessive height inside this range.
        ["Waldo_ImprovedHelicopterLanding_GoAroundHeight", 150], // METRES AGL: climb target during a go-around.
        ["Waldo_ImprovedHelicopterLanding_GoAroundExitDistance", 250], // METRES: distance flown clear before re-approach.
        ["Waldo_ImprovedHelicopterLanding_GoAroundSpeed", 70], // KM/H: commanded go-around speed.
        ["Waldo_ImprovedHelicopterLanding_MaximumGoArounds", 1], // COUNT: maximum automatic retries for one landing order.
        ["Waldo_ImprovedHelicopterLanding_MaximumClimbRate", 8], // METRES/SECOND: vertical command clamp.
        ["Waldo_ImprovedHelicopterLanding_MaximumDescentRate", 10], // METRES/SECOND: descent command clamp.
        ["Waldo_ImprovedHelicopterLanding_TouchdownRadius", 5], // METRES: accepted horizontal error. Larger is easier but less exact.
        ["Waldo_ImprovedHelicopterLanding_FinalCommitDistance", 75], // METRES: begin the final flare/landing phase.
        ["Waldo_ImprovedHelicopterLanding_ControlInterval", 0.05], // SECONDS: local control-loop interval; performance-sensitive.
        ["Waldo_ImprovedHelicopterLanding_TouchdownHoldSeconds", 20], // SECONDS: keep the AI landed before releasing controls; prevents immediate takeoff.
        ["Waldo_AI_ProfileDisplayNames", createHashMapFromArray [ // ADVANCED: labels only; keys are implementation IDs.
            ["LEGACY", "Existing Mission Balance"], ["MILITIA", "WMP Militia"],
            ["LINE", "WMP Line"], ["VETERAN", "WMP Veteran"], ["ELITE", "WMP Elite"]
        ]]
    ]]
]
