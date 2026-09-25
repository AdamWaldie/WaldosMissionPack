/*
 * Author: WaldoTheWarfighter
 * Defines AI rebalance selection, filters, display names and improved helicopter-landing control
 * limits, optional cruise-deceleration climb suppression and the optional Smart AI Pass. AI application and locality
 * migration remain in MissionScripts\AiScripting.
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
 *
 * SETTING-BY-SETTING GUIDE - AI HELICOPTER DECELERATION:
 * - Waldo_HelicopterDeceleration_Enable (MISSION MAKER): false by default until your airframes pass live testing.
 * - Waldo_HelicopterDeceleration_IncludeVTOL (MISSION MAKER): false keeps VTOL flight modes out of the system.
 * - Waldo_HelicopterDeceleration_MinimumSpeed (ADVANCED): minimum forward speed in km/h before detection can start.
 * - Waldo_HelicopterDeceleration_MinimumAltitude (ADVANCED): minimum terrain-relative height in metres.
 * - Waldo_HelicopterDeceleration_MinimumSpeedLoss (ADVANCED): required km/h lost during one sample.
 * - Waldo_HelicopterDeceleration_MinimumAltitudeGain (ADVANCED): required metres climbed during one sample.
 * - Waldo_HelicopterDeceleration_MinimumNoseUp (ADVANCED): minimum upward vectorDir component; 0 is level.
 * - Waldo_HelicopterDeceleration_TerrainClearance (ADVANCED): required clearance above terrain ahead.
 * - Waldo_HelicopterDeceleration_MaximumCorrectionAcceleration (ADVANCED): downward correction cap in m/s squared.
 * - Waldo_HelicopterDeceleration_MaximumClimbRate (ADVANCED): correction ends below this upward m/s rate.
 * - Waldo_HelicopterDeceleration_SampleInterval (ADVANCED): seconds between detection samples.
 * - Waldo_HelicopterDeceleration_ControlInterval (ADVANCED): seconds between force corrections while active.
 * - Waldo_HelicopterDeceleration_MaximumCorrectionSeconds (ADVANCED): hard duration cap for one correction.
 * - Waldo_HelicopterDeceleration_Debug (TROUBLESHOOTING): logs acquire/release reasons and owner IDs.
 * Per-aircraft opt-out example: this setVariable ["Waldo_HelicopterDeceleration_Exclude", true, true];
 * - Waldo_AI_ProfileDisplayNames (INFRASTRUCTURE): labels for diagnostics/UI; keys must match implementation IDs.
 *
 * SETTING-BY-SETTING GUIDE - SMART AI PASS:
 * Behaviour improvements for all non-player AI groups. It runs only on the server and headless
 * clients, inside a fixed per-tick time budget, and adds no network traffic of its own. Player-led
 * groups and units owned by other WMP features (Gunship, Transport Services, Paradrop, Dynamic AA,
 * AI Convoy, dialogue speakers, drones) are always excluded. Dynamic AO groups are included.
 * Per-unit or per-group opt-out: _group setVariable ["Waldo_AIPass_Exclude", true, true];
 * - Waldo_AIPass_Enable (MISSION MAKER): master switch; false means no pass code runs anywhere.
 * - Waldo_AIPass_IncludedSides (MISSION MAKER): sides the pass may command; CIV is left out by default.
 *   The shared Waldo_AI_IncludedFactions/ExcludedFactions/ExcludedClasses filters above also apply.
 * - Waldo_AIPass_TickBudgetMs (ADVANCED): milliseconds of work allowed per scheduler tick (0.25 s).
 * - Waldo_AIPass_LowFpsThreshold (ADVANCED): below this machine FPS, behaviour steps run half as often.
 * - Waldo_AIPass_Regroup_Enable (MISSION MAKER): survivors of a destroyed squad join a nearby friendly squad.
 * - Waldo_AIPass_Regroup_MaxRemnantSize (ADVANCED): a group this small or smaller counts as a remnant.
 * - Waldo_AIPass_Regroup_MinimumPeakSize (ADVANCED): groups that never reached this size (snipers,
 *   sentries) are never merged.
 * - Waldo_AIPass_Regroup_SearchRadius (ADVANCED): metres searched for a host squad.
 * - Waldo_AIPass_Regroup_MaxGroupSize (ADVANCED): a host may not exceed this size after the merge.
 * - Waldo_AIPass_Regroup_JoinDistance (ADVANCED): survivors join once this close to the host leader.
 * - Waldo_AIPass_Regroup_StuckSeconds (ADVANCED): no progress for this long joins them where they stand.
 * - Waldo_AIPass_Regroup_TimeoutSeconds (ADVANCED): limit for finding a host and for walking to it.
 * - Waldo_AIPass_Regroup_SettleSeconds (ADVANCED): wait after a kill so simultaneous deaths settle.
 * - Waldo_AIPass_LambsMode (MISSION MAKER): only matters with LAMBS Danger loaded; SPLIT lets LAMBS keep in-contact unit tactics, WMP turns LAMBS group AI off for squads the pass manages.
 * - Waldo_AIPass_Debug (TROUBLESHOOTING): logs contact, flank, morale and retreat events to RPT.
 * - Waldo_AIPass_EngageRange (ADVANCED): range in metres within which known enemies are considered.
 * - Waldo_AIPass_NearRange (ADVANCED): squads this close to a player are stepped every TickNear seconds.
 * - Waldo_AIPass_FarRange (ADVANCED): beyond this distance from every player only the state ladder and morale run.
 * - Waldo_AIPass_TickContact (ADVANCED): seconds between steps for a squad in contact near players.
 * - Waldo_AIPass_TickNear (ADVANCED): seconds between steps within NearRange.
 * - Waldo_AIPass_TickMid (ADVANCED): seconds between steps within FarRange.
 * - Waldo_AIPass_TickFar (ADVANCED): seconds between steps beyond FarRange.
 * - Waldo_AIPass_DiscoveryInterval (ADVANCED): seconds between discovery sweeps for newly local AI groups.
 * - Waldo_AIPass_Contact_Enable (MISSION MAKER): contact handling and the state ladder; every combat behaviour below needs it.
 * - Waldo_AIPass_PostContact_Enable (MISSION MAKER): after contact is lost: hold, search the last known enemy position, regroup.
 * - Waldo_AIPass_PostContact_LostSeconds (ADVANCED): seconds without a sighting before contact counts as lost.
 * - Waldo_AIPass_PostContact_SecuritySeconds (ADVANCED): seconds of security hold before the search.
 * - Waldo_AIPass_PostContact_SearchSeconds (ADVANCED): time limit for the two-man search.
 * - Waldo_AIPass_PostContact_RegroupSeconds (ADVANCED): time limit for the squad to close up before returning to CALM.
 * - Waldo_AIPass_Flank_Enable (MISSION MAKER): half the squad flanks in covered bounds while the rest suppresses.
 * - Waldo_AIPass_Flank_MinGroupSize (ADVANCED): soldiers on foot needed before a squad may flank.
 * - Waldo_AIPass_Flank_MinRange (ADVANCED): enemies nearer than this are fought, not flanked.
 * - Waldo_AIPass_Flank_MaxRange (ADVANCED): enemies farther than this are not flanked.
 * - Waldo_AIPass_Flank_BoundDistance (ADVANCED): length of one bound in metres.
 * - Waldo_AIPass_Flank_BoundPause (ADVANCED): seconds of overwatch between bounds.
 * - Waldo_AIPass_Flank_BoundTimeout (ADVANCED): a bound ends after this many seconds even if not everyone arrived.
 * - Waldo_AIPass_Flank_Cooldown (ADVANCED): seconds before the same squad may flank again.
 * - Waldo_AIPass_StreetCrossing_Enable (MISSION MAKER): flanking elements stop at roads, throw smoke and cross in one bound.
 * - Waldo_AIPass_FireControl_Enable (MISSION MAKER): close threats first, fire spread across visible enemies, disciplined suppression.
 * - Waldo_AIPass_FireControl_MaxSuppressors (ADVANCED): soldiers allowed to suppress at the same time.
 * - Waldo_AIPass_FireControl_MaxShootersPerTarget (ADVANCED): shooters on one visible enemy before extra shooters switch targets.
 * - Waldo_AIPass_Morale_Enable (MISSION MAKER): squads under losses and fire break and fall back under smoke.
 * - Waldo_AIPass_Morale_RetreatDistance (ADVANCED): how far a broken squad falls back.
 * - Waldo_AIPass_Surrender_Enable (MISSION MAKER): the last one or two survivors of a broken, isolated squad surrender (ACE Captives when loaded).
 * - Waldo_AIPass_GrenadeEvasion_Enable (MISSION MAKER): AI move away from a live grenade they can see; off until tested in your setup.
 * - Waldo_AIPass_AntiArmour_Enable (MISSION MAKER): the best anti-tank gunner engages known armour, clear of backblast.
 * - Waldo_AIPass_Vehicles_Enable (MISSION MAKER): infantry dismount under fire and remount afterwards; damaged vehicles smoke and withdraw.
 * - Waldo_AIPass_ContactReports_Enable (MISSION MAKER): squads share sighted enemies by radio (blocked by jamming) or by voice.
 * - Waldo_AIPass_ContactReports_Radius (ADVANCED): radio report range in metres.
 * - Waldo_AIPass_ContactReports_VoiceRange (ADVANCED): report range in metres without a working radio.
 * - Waldo_AIPass_ContactReports_RequireRadio (ADVANCED): false treats every AI as carrying a radio (jamming still applies).
 * - Waldo_AIPass_Reinforce_Enable (MISSION MAKER): idle nearby squads move up behind a squad in contact.
 * - Waldo_AIPass_Reinforce_Radius (ADVANCED): how far away responding squads may be.
 * - Waldo_AIPass_Reinforce_MaxResponders (ADVANCED): responding squads per squad in contact.
 * - Difficulty (MISSION MAKER; all of these, and the support, artillery, counter-battery and airborne
 *   numbers below, can be changed during the mission with the AI Tuning Zeus module or
 *   Waldo_fnc_AIPassTuning):
 *   - Waldo_AIPass_BehaviourProfile: "" follows the AI Rebalance profile; MILITIA, LINE, VETERAN or ELITE sets squad tactics mission-wide (group and faction profiles still win).
 *   - Waldo_AIPass_Aggression: scales flank, assault, advance, investigate and coordinated-assault chances (1 = the profile's own).
 *   - Waldo_AIPass_Cohesion: how much punishment squads take before morale breaks (1 = normal).
 *   - Waldo_AIPass_ReactionSpeed: how often squads re-assess (1 = normal; higher costs more server time).
 * - Waldo_AIPass_Artillery_Enable (MISSION MAKER): squads call fire from friendly AI artillery on well-located enemies only.
 * - Waldo_AIPass_Artillery_Rounds (ADVANCED): rounds per fire mission.
 * - Waldo_AIPass_Artillery_MinFriendlyDistance (ADVANCED): no mission lands within this distance of friendlies or civilians.
 * - Waldo_AIPass_Artillery_MaxError (ADVANCED): largest target position error accepted for a mission.
 * - Waldo_AIPass_Artillery_Cooldown (ADVANCED): seconds between missions called by one squad.
 * - Waldo_AIPass_Artillery_ShootAndScoot (ADVANCED): mobile batteries move 200-350 m after a support mission.
 * - Waldo_AIPass_Artillery_DefaultRole (MISSION MAKER): missions a battery takes unless you set its own role: SUPPORT (squads' calls only), COUNTER (counter-battery only) or BOTH. Per gun: [this, "COUNTER"] call Waldo_fnc_AIPassSetArtilleryRole; or the AI Orders Zeus module.
 * - Waldo_AIPass_CounterBattery_Enable (MISSION MAKER): AI artillery answers enemy artillery whose position is known.
 * - Waldo_AIPass_CounterBattery_Mode (MISSION MAKER): KNOWN answers only spotted batteries; RADAR also uses radars registered with Waldo_fnc_AIPassRegisterRadar.
 * - Waldo_AIPass_CounterBattery_RadarRange (ADVANCED): detection range of a registered counter-battery radar.
 * - Waldo_AIPass_CounterBattery_Delay (ADVANCED): seconds before counter-battery fire is returned.
 * - Waldo_AIPass_CounterBattery_Rounds (ADVANCED): rounds per counter-battery mission.
 * - Waldo_AIPass_CounterBattery_MaxError (ADVANCED): largest position error on the enemy gun accepted in KNOWN mode.
 * - Waldo_AIPass_CounterBattery_MinFriendlyDistance (ADVANCED): no counter-battery fire when friendlies or civilians are this close to the enemy gun.
 * - Waldo_AIPass_CounterBattery_Interval (ADVANCED): seconds before the same enemy gun is answered again.
 * - Waldo_AIPass_CounterBattery_ShootAndScoot (ADVANCED): mobile batteries move 200-350 m after a counter-battery mission.
 * - Waldo_AIPass_Airborne_Enable (MISSION MAKER): AI squads riding in AI-flown helicopters or planes parachute out when their aircraft nears a known enemy. Helicopters on an unload or get-out waypoint still land. [group this] call Waldo_fnc_AIPassAirborneDrop orders a drop at any time.
 * - Waldo_AIPass_Airborne_ApproachDistance (ADVANCED): within this distance of a known enemy the aircraft climbs to jump altitude.
 * - Waldo_AIPass_Airborne_DeployDistance (MISSION MAKER): the squad jumps once its aircraft is this close to a known enemy.
 * - Waldo_AIPass_Airborne_Altitude (ADVANCED): height above ground the aircraft climbs to for the drop.
 * - Waldo_AIPass_Airborne_MinAltitude (ADVANCED): never jump below this height above ground (or over water).
 * - Waldo_AIPass_Airborne_JumpInterval (ADVANCED): seconds between jumpers.
 * - Waldo_AIPass_Garrison_DynamicAO (MISSION MAKER): Dynamic AO garrisons duck under fire, watch outward and break at losses.
 * - Waldo_AIPass_Garrison_BreakFraction (ADVANCED): a garrison or defence line breaks when down to this share of its strength at the time of the order.
 * - Waldo_AIPass_AircraftFlares_Enable (MISSION MAKER): WMP gunships and Dynamic AA fighters fire flares at incoming missiles; test your aircraft first.
 * - Waldo_AIPass_ProfileBehaviour (ADVANCED): behaviour per profile name, alongside AI Rebalance's skill
 *   values (which the pass never changes): flank, assault, advance, investigate and coordinated-assault
 *   chances (0-1), morale thresholds, retreat distance scale and the largest squad that may surrender.
 *   A group uses Waldo_AIPass_Profile set on the group, then Waldo_AIPass_FactionProfiles, then the
 *   active Waldo_AIRebalance_Profile, then LINE.
 * - Waldo_AIPass_FactionProfiles (MISSION MAKER): optional map of faction classname to behaviour profile name, overriding the AI Rebalance profile for that faction's squads.
 * - Waldo_AIPass_ZeusHoldSeconds (MISSION MAKER): seconds the pass leaves a group alone after Zeus selects, edits or orders it; Zeus waypoints hold it until they are finished.
 * - Waldo_AIPass_Investigate_Enable (MISSION MAKER): squads send two riflemen (the whole squad beyond 150 m) to check enemies they know about but have not seen (reported, or heard firing).
 * - Waldo_AIPass_Investigate_Range (ADVANCED): how far away a known but unseen enemy may be to be investigated.
 * - Waldo_AIPass_Investigate_Seconds (ADVANCED): time limit for an investigation.
 * - Waldo_AIPass_Assault_Enable (MISSION MAKER): a flank can finish with a grenade and a rush on the enemy position while the base of fire suppresses.
 * - Waldo_AIPass_Assault_Range (ADVANCED): the enemy must be believed this close to the flanking element before an assault.
 * - Waldo_AIPass_Advance_Enable (MISSION MAKER): squads in a long firefight that still have a waypoint to reach push a fire team forward in covered bounds.
 * - Waldo_AIPass_Advance_MinContactSeconds (ADVANCED): seconds in contact before a bounding advance is considered.
 * - Waldo_AIPass_CoordinatedAssault_Enable (MISSION MAKER): squads that came to reinforce assault the enemy from both sides while the squad in contact fires.
 * - Waldo_AIPass_Stance_Enable (MISSION MAKER): soldiers stand, kneel or go prone to match the cover in front of them.
 * - Waldo_AIPass_AmmoShare_Enable (MISSION MAKER): soldiers down to their last magazine get one from a nearby squad-mate with plenty.
 * - Waldo_AIPass_AmmoShare_Distance (ADVANCED): how close a squad-mate must be to hand over a magazine.
 * - Waldo_AIPass_VehicleGunnery_Enable (MISSION MAKER): AI gunners engage anti-tank soldiers first, then armour; armour backs away from known AT teams.
 * - Waldo_AIPass_Vehicles_StandoffDistance (ADVANCED): distance armour tries to keep from known anti-tank soldiers.
 * - Waldo_AIPass_ArtillerySmoke_Enable (MISSION MAKER): a retreating squad with a radio gets an artillery smoke screen; needs artillery support on and a battery with smoke.
 * - Waldo_AIPass_AircraftBreak_Enable (MISSION MAKER): WMP gunships and Dynamic AA fighters jink sideways away from a missile launch; test your aircraft first.
 */
createHashMapFromArray [
    ["featureFamilies", ["AI Rebalance", "Improved AI Helicopter Landings", "AI Helicopter Deceleration", "Smart AI Pass"]],
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
        // MISSION MAKER switches followed by ADVANCED cruise-deceleration safety limits.
        ["Waldo_HelicopterDeceleration_Enable", false], // BOOL: suppress AI zoom-climb while braking; test airframes before enabling.
        ["Waldo_HelicopterDeceleration_IncludeVTOL", false], // BOOL: include VTOL_Base_F aircraft; false is the conservative default.
        ["Waldo_HelicopterDeceleration_MinimumSpeed", 80], // KM/H: detection is ignored below this airspeed.
        ["Waldo_HelicopterDeceleration_MinimumAltitude", 25], // METRES AGL: never correct close to terrain.
        ["Waldo_HelicopterDeceleration_MinimumSpeedLoss", 4], // KM/H PER SAMPLE: braking threshold.
        ["Waldo_HelicopterDeceleration_MinimumAltitudeGain", 0.5], // METRES PER SAMPLE: unwanted climb threshold.
        ["Waldo_HelicopterDeceleration_MinimumNoseUp", 0.02], // VECTOR DIR Z: positive nose-up threshold.
        ["Waldo_HelicopterDeceleration_TerrainClearance", 25], // METRES: required clearance over terrain 100/300/500 m ahead.
        ["Waldo_HelicopterDeceleration_MaximumCorrectionAcceleration", 2.5], // M/S^2: downward world-force cap.
        ["Waldo_HelicopterDeceleration_MaximumClimbRate", 0.5], // M/S: release once vertical climb falls to this value.
        ["Waldo_HelicopterDeceleration_SampleInterval", 0.5], // SECONDS: local detection cadence.
        ["Waldo_HelicopterDeceleration_ControlInterval", 0.02], // SECONDS: active correction cadence.
        ["Waldo_HelicopterDeceleration_MaximumCorrectionSeconds", 4], // SECONDS: hard cap per correction event.
        ["Waldo_HelicopterDeceleration_Debug", false], // BOOL: detailed RPT acquire/release logging.
        // MISSION MAKER switches followed by ADVANCED Smart AI Pass scheduling and behaviour tuning.
        ["Waldo_AIPass_Enable", false], // BOOL: master switch for the Smart AI Pass (server and headless clients only).
        ["Waldo_AIPass_IncludedSides", ["WEST", "EAST", "GUER"]], // ARRAY of WEST/EAST/GUER/CIV strings the pass may command.
        ["Waldo_AIPass_TickBudgetMs", 1], // MILLISECONDS: work allowed per 0.25 s scheduler tick; at least one job always runs.
        ["Waldo_AIPass_LowFpsThreshold", 25], // FPS: below this, behaviour steps are rescheduled half as often.
        ["Waldo_AIPass_Regroup_Enable", true], // BOOL: survivors of a destroyed squad regroup with a nearby friendly squad.
        ["Waldo_AIPass_Regroup_MaxRemnantSize", 2], // COUNT: living members at or below this make a remnant.
        ["Waldo_AIPass_Regroup_MinimumPeakSize", 3], // COUNT: smaller deliberate teams are never merged.
        ["Waldo_AIPass_Regroup_SearchRadius", 400], // METRES: host squad search radius.
        ["Waldo_AIPass_Regroup_MaxGroupSize", 12], // COUNT: host size limit after the merge.
        ["Waldo_AIPass_Regroup_JoinDistance", 30], // METRES: survivors join the host inside this distance.
        ["Waldo_AIPass_Regroup_StuckSeconds", 20], // SECONDS: without progress, survivors join where they stand.
        ["Waldo_AIPass_Regroup_TimeoutSeconds", 120], // SECONDS: limit for finding a host and for walking to it.
        ["Waldo_AIPass_Regroup_SettleSeconds", 5], // SECONDS: delay after a kill before the remnant is assessed.
        ["Waldo_AIPass_BehaviourProfile", ""], // STRING: "" follows the AI Rebalance profile; MILITIA, LINE, VETERAN or ELITE sets squad tactics for every squad without its own.
        ["Waldo_AIPass_Aggression", 1], // 0-2: scales how often squads flank, assault, advance, investigate and coordinate.
        ["Waldo_AIPass_Cohesion", 1], // 0.5-2: above 1 squads take more before morale breaks, below 1 they break sooner.
        ["Waldo_AIPass_ReactionSpeed", 1], // 0.5-2: above 1 squads re-assess more often (more server time), below 1 less often.
        ["Waldo_AIPass_LambsMode", "SPLIT"], // STRING: SPLIT (LAMBS keeps in-contact unit tactics) or WMP (LAMBS group AI off for managed squads).
        ["Waldo_AIPass_Debug", false], // BOOL: extra [WMP AI PASS] RPT lines for contact, flanks, morale and retreats.
        ["Waldo_AIPass_EngageRange", 800], // METRES: enemies the leader knows about within this range are considered.
        ["Waldo_AIPass_NearRange", 1000], // METRES: squads this close to a player run at the near cadence.
        ["Waldo_AIPass_FarRange", 2500], // METRES: beyond this only the state ladder and morale run.
        ["Waldo_AIPass_TickContact", 2], // SECONDS: step interval for a squad in contact near players.
        ["Waldo_AIPass_TickNear", 4], // SECONDS: step interval within NearRange.
        ["Waldo_AIPass_TickMid", 8], // SECONDS: step interval within FarRange.
        ["Waldo_AIPass_TickFar", 20], // SECONDS: step interval beyond FarRange.
        ["Waldo_AIPass_DiscoveryInterval", 10], // SECONDS: how often each machine looks for newly local AI groups.
        ["Waldo_AIPass_Contact_Enable", true], // BOOL: contact state ladder; needed by every combat behaviour.
        ["Waldo_AIPass_PostContact_Enable", true], // BOOL: hold, search the last known position, regroup after contact.
        ["Waldo_AIPass_PostContact_LostSeconds", 30], // SECONDS: without a sighting before contact counts as lost.
        ["Waldo_AIPass_PostContact_SecuritySeconds", 10], // SECONDS: security hold before searching.
        ["Waldo_AIPass_PostContact_SearchSeconds", 45], // SECONDS: search time limit.
        ["Waldo_AIPass_PostContact_RegroupSeconds", 30], // SECONDS: regroup time limit.
        ["Waldo_AIPass_Flank_Enable", true], // BOOL: base of fire plus a flanking element in covered bounds.
        ["Waldo_AIPass_Flank_MinGroupSize", 6], // COUNT: soldiers on foot needed to flank.
        ["Waldo_AIPass_Flank_MinRange", 60], // METRES: nearer enemies are fought, not flanked.
        ["Waldo_AIPass_Flank_MaxRange", 400], // METRES: farther enemies are not flanked.
        ["Waldo_AIPass_Flank_BoundDistance", 40], // METRES: length of one bound (minimum 15).
        ["Waldo_AIPass_Flank_BoundPause", 4], // SECONDS: overwatch halt between bounds.
        ["Waldo_AIPass_Flank_BoundTimeout", 25], // SECONDS: a bound ends after this even if not everyone arrived.
        ["Waldo_AIPass_Flank_Cooldown", 90], // SECONDS: before the same squad flanks again.
        ["Waldo_AIPass_StreetCrossing_Enable", true], // BOOL: flanks stop at roads, smoke, and cross in one bound.
        ["Waldo_AIPass_FireControl_Enable", true], // BOOL: close threats, fire distribution, disciplined suppression.
        ["Waldo_AIPass_FireControl_MaxSuppressors", 2], // COUNT: soldiers suppressing at once.
        ["Waldo_AIPass_FireControl_MaxShootersPerTarget", 2], // COUNT: shooters per visible enemy before others switch.
        ["Waldo_AIPass_Morale_Enable", true], // BOOL: weighted morale; broken squads retreat under smoke.
        ["Waldo_AIPass_Morale_RetreatDistance", 200], // METRES: how far a broken squad falls back.
        ["Waldo_AIPass_Surrender_Enable", false], // BOOL: last survivors of a broken, isolated squad surrender.
        ["Waldo_AIPass_GrenadeEvasion_Enable", false], // BOOL: move away from seen grenades; test in your setup first.
        ["Waldo_AIPass_AntiArmour_Enable", true], // BOOL: best AT gunner engages known armour, clear of backblast.
        ["Waldo_AIPass_Vehicles_Enable", true], // BOOL: dismount under fire; damaged vehicles smoke and withdraw.
        ["Waldo_AIPass_ContactReports_Enable", true], // BOOL: share sightings by radio (jammable) or voice.
        ["Waldo_AIPass_ContactReports_Radius", 500], // METRES: radio report range.
        ["Waldo_AIPass_ContactReports_VoiceRange", 35], // METRES: report range without a working radio.
        ["Waldo_AIPass_ContactReports_RequireRadio", true], // BOOL: false treats every AI as carrying a radio.
        ["Waldo_AIPass_Reinforce_Enable", true], // BOOL: idle nearby squads move up behind a squad in contact.
        ["Waldo_AIPass_Reinforce_Radius", 600], // METRES: how far away responders may be.
        ["Waldo_AIPass_Reinforce_MaxResponders", 2], // COUNT: responding squads per squad in contact.
        ["Waldo_AIPass_Artillery_Enable", false], // BOOL: squads call fire from friendly AI artillery on well-located enemies.
        ["Waldo_AIPass_Artillery_Rounds", 3], // COUNT: rounds per fire mission.
        ["Waldo_AIPass_Artillery_MinFriendlyDistance", 200], // METRES: no mission near friendlies or civilians.
        ["Waldo_AIPass_Artillery_MaxError", 50], // METRES: largest target position error accepted.
        ["Waldo_AIPass_Artillery_Cooldown", 120], // SECONDS: between missions called by one squad.
        ["Waldo_AIPass_Artillery_ShootAndScoot", true], // BOOL: mobile batteries relocate after a support mission.
        ["Waldo_AIPass_Artillery_DefaultRole", "BOTH"], // STRING: SUPPORT, COUNTER or BOTH for guns with no role of their own.
        ["Waldo_AIPass_CounterBattery_Enable", false], // BOOL: AI artillery answers enemy artillery whose position is known.
        ["Waldo_AIPass_CounterBattery_Mode", "KNOWN"], // STRING: KNOWN (spotted only) or RADAR (also registered radars).
        ["Waldo_AIPass_CounterBattery_RadarRange", 8000], // METRES: radar detection range.
        ["Waldo_AIPass_CounterBattery_Delay", 20], // SECONDS: before counter-battery fire.
        ["Waldo_AIPass_CounterBattery_Rounds", 4], // COUNT: rounds per counter-battery mission.
        ["Waldo_AIPass_CounterBattery_MaxError", 100], // METRES: largest enemy-gun position error accepted (KNOWN).
        ["Waldo_AIPass_CounterBattery_MinFriendlyDistance", 200], // METRES: no fire near friendlies or civilians.
        ["Waldo_AIPass_CounterBattery_Interval", 60], // SECONDS: before the same enemy gun is answered again.
        ["Waldo_AIPass_CounterBattery_ShootAndScoot", true], // BOOL: mobile batteries relocate after counter-battery.
        ["Waldo_AIPass_Airborne_Enable", false], // BOOL: AI passengers parachute out near known enemies.
        ["Waldo_AIPass_Airborne_ApproachDistance", 2000], // METRES: climb to jump altitude inside this range.
        ["Waldo_AIPass_Airborne_DeployDistance", 700], // METRES: jump inside this range of a known enemy.
        ["Waldo_AIPass_Airborne_Altitude", 250], // METRES: jump altitude above ground.
        ["Waldo_AIPass_Airborne_MinAltitude", 120], // METRES: never jump lower than this.
        ["Waldo_AIPass_Airborne_JumpInterval", 1], // SECONDS: between jumpers.
        ["Waldo_AIPass_Garrison_DynamicAO", false], // BOOL: WMP garrison handling for Dynamic AO garrisons.
        ["Waldo_AIPass_Garrison_BreakFraction", 0.5], // 0-1: a garrison breaks at this share of its strength.
        ["Waldo_AIPass_AircraftFlares_Enable", false], // BOOL: WMP gunships and Dynamic AA fighters flare at missiles.
        ["Waldo_AIPass_ProfileBehaviour", createHashMapFromArray [ // ADVANCED: behaviour per AI Rebalance profile name.
            ["MILITIA", createHashMapFromArray [["flankChance", 0.3], ["assaultChance", 0.2], ["advanceChance", 0.3], ["investigateChance", 0.4], ["coordinatedChance", 0.2], ["moraleShaken", 0.65], ["moraleBroken", 0.4], ["retreatScale", 1.5], ["surrenderSurvivors", 3]]],
            ["LINE", createHashMapFromArray [["flankChance", 0.5], ["assaultChance", 0.4], ["advanceChance", 0.5], ["investigateChance", 0.6], ["coordinatedChance", 0.4], ["moraleShaken", 0.55], ["moraleBroken", 0.3], ["retreatScale", 1], ["surrenderSurvivors", 2]]],
            ["LEGACY", createHashMapFromArray [["flankChance", 0.5], ["assaultChance", 0.4], ["advanceChance", 0.5], ["investigateChance", 0.6], ["coordinatedChance", 0.4], ["moraleShaken", 0.55], ["moraleBroken", 0.3], ["retreatScale", 1], ["surrenderSurvivors", 2]]],
            ["VETERAN", createHashMapFromArray [["flankChance", 0.6], ["assaultChance", 0.55], ["advanceChance", 0.6], ["investigateChance", 0.75], ["coordinatedChance", 0.5], ["moraleShaken", 0.45], ["moraleBroken", 0.22], ["retreatScale", 0.8], ["surrenderSurvivors", 1]]],
            ["ELITE", createHashMapFromArray [["flankChance", 0.7], ["assaultChance", 0.7], ["advanceChance", 0.7], ["investigateChance", 0.85], ["coordinatedChance", 0.6], ["moraleShaken", 0.4], ["moraleBroken", 0.18], ["retreatScale", 0.7], ["surrenderSurvivors", 1]]]
        ]],
        ["Waldo_AIPass_FactionProfiles", createHashMap], // MAP: CfgFactionClasses name to behaviour profile, for example OPF_F to ELITE.
        ["Waldo_AIPass_ZeusHoldSeconds", 120], // SECONDS: the pass leaves a group alone this long after Zeus selects or edits it.
        ["Waldo_AIPass_Investigate_Enable", true], // BOOL: squads check out enemies they know about but have not seen.
        ["Waldo_AIPass_Investigate_Range", 300], // METRES: how far away a known enemy may be to be investigated.
        ["Waldo_AIPass_Investigate_Seconds", 60], // SECONDS: investigation time limit.
        ["Waldo_AIPass_Assault_Enable", true], // BOOL: a flank can finish with a grenade and a rush on the enemy position.
        ["Waldo_AIPass_Assault_Range", 80], // METRES: the enemy must be this close to the flanking element to assault.
        ["Waldo_AIPass_Advance_Enable", true], // BOOL: pinned squads with somewhere to go push a team forward in bounds.
        ["Waldo_AIPass_Advance_MinContactSeconds", 30], // SECONDS: in contact before an advance is considered.
        ["Waldo_AIPass_CoordinatedAssault_Enable", true], // BOOL: reinforcing squads assault together while the first squad fires.
        ["Waldo_AIPass_Stance_Enable", true], // BOOL: stance chosen from the height of the cover in front.
        ["Waldo_AIPass_AmmoShare_Enable", true], // BOOL: soldiers low on magazines get one from a squad-mate.
        ["Waldo_AIPass_AmmoShare_Distance", 10], // METRES: how close the squad-mate must be.
        ["Waldo_AIPass_VehicleGunnery_Enable", true], // BOOL: gunners prioritise AT soldiers; armour keeps away from them.
        ["Waldo_AIPass_Vehicles_StandoffDistance", 250], // METRES: distance armour keeps from known AT soldiers.
        ["Waldo_AIPass_ArtillerySmoke_Enable", true], // BOOL: a retreating squad gets an artillery smoke screen (needs Artillery).
        ["Waldo_AIPass_AircraftBreak_Enable", false], // BOOL: WMP gunships and fighters jink sideways from missiles; test first.
        ["Waldo_AI_ProfileDisplayNames", createHashMapFromArray [ // ADVANCED: labels only; keys are implementation IDs.
            ["LEGACY", "Existing Mission Balance"], ["MILITIA", "WMP Militia"],
            ["LINE", "WMP Line"], ["VETERAN", "WMP Veteran"], ["ELITE", "WMP Elite"]
        ]]
    ]]
]
