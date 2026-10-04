# Cortex and AI configuration defaults

Verified against MissionConfig/aiConfig.sqf and the Cortex Control specification on 30 September 2026. These are shipped configuration defaults, before mission or Zeus overrides. Audit scenarios temporarily change values and restore them afterwards.

Cortex automatic tactics are enabled by default. AI skill profiles and improved helicopter landings are independently enabled. Convoy options apply when a convoy is explicitly started. Enabled subfeatures still require their parent feature and applicable setup.

The deliberately opt-in features are artillery support, counter-battery, airborne insertion, helicopter deceleration, Dynamic AO garrison integration, and convoy friendly-infantry avoidance. Each can move or dismount assets, depend on another system, or add a short-range vehicle scan. Missile-threat countermeasures and the bounded break-away reaction are enabled because they are defensive extensions of ordinary AI flight and immediately yield to Zeus or eligibility loss.

Existing Waldo_AIPass_* setting keys remain for mission compatibility; the public AI functions use Waldo_fnc_Cortex*.

Counter-battery defaults to disabled, 60 seconds acquisition without radar or 20 seconds with radar within 8,000 m. Each mission allows up to three bursts of four rounds. The minimum round interval is two seconds; reload time can extend it. The next burst waits until estimated impact plus 20 seconds. The same enemy gun has a 60-second repeat-fire cooldown. A new firing event is required for a later automatic response.

The opening aim exclusion is 200 m plus a 100 m buffer around living players. This controls aim points, not guaranteed impact positions. The shared ranging algorithm starts with a 300 m deliberate offset, reduces it by a factor of 0.55 after a valid correction, and retains a 40 m minimum offset. A reported location change of 150 m resets ranging. These three ranging constants are implementation values, not editable settings.

CounterBattery_Mode is a legacy compatibility value; automatic acquisition does not depend on selecting a mode. ContactReports_RequireRadio is also a legacy value; AI inventory radio items are not required.

| Setting key | Default | Purpose / units |
|---|---|---|
| `Waldo_AIPass_AmmoCapabilityOverrides` | `createHashMap` | MAP: magazine class to ["AT"] / ["AA"] / ["AT","AA"] role overrides. |
| `Waldo_AIRebalance_Enable` | `true` | BOOL: true applies WMP skill profiles to eligible AI. |
| `Waldo_AIRebalance_Profile` | `"LINE"` | STRING: MILITIA, LINE, VETERAN or ELITE. |
| `Waldo_AIRebalance_Mode` | `"AUTO"` | Ambient-darkness and NVG-aware; DAY disables the extra penalty; NIGHT retains legacy night tiers. |
| `Waldo_AI_ApplyMode` | `"BOTH"` | STRING: EXISTING, NEW or BOTH AI populations. |
| `Waldo_AI_RestoreOnStop` | `true` | ADVANCED: restore captured vanilla/mission skills on stop. |
| `Waldo_AI_SkillVariance` | `0` | ADVANCED: one stable per-AI offset; 0 disables variation. |
| `Waldo_AI_InfantryDispersion` | `1.35` | Owner-local aim coefficient for dismounted AI and vehicle cargo. |
| `Waldo_AI_VehicleCrewAimMultiplier` | `0.6` | Final aiming-skill multiplier for ordinary operating vehicle and aircraft crew. Named Dynamic AA crews are exempt. |
| `Waldo_AI_VehicleCrewDispersion` | `3.5` | Owner-local aim coefficient for ground-vehicle operators when LAMBS Turrets is absent. |
| `Waldo_AI_AirCrewDispersion` | `4.25` | Wider owner-local aim coefficient for aircraft operators. Named Dynamic AA crews remain exempt. |
| `Waldo_AI_IncludedSides` | `[]` | ARRAY of WEST/EAST/GUER/CIV strings; [] permits every side. |
| `Waldo_AI_IncludedFactions` | `[]` | ARRAY of CfgFactionClasses names; [] permits every faction. |
| `Waldo_AI_ExcludedFactions` | `[]` | ARRAY of faction names removed after the include filter. |
| `Waldo_AI_ExcludedClasses` | `[]` | ARRAY of exact CfgVehicles unit classnames never changed. |
| `Waldo_ImprovedHelicopterLanding_Enable` | `true` | BOOL: watches eligible landing waypoints for local AI pilots. |
| `Waldo_ImprovedHelicopterLanding_MinimumActivationDistance` | `50` | METRES: waypoint must start at least this far away. |
| `Waldo_ImprovedHelicopterLanding_TriggerDistance` | `500` | METRES: controller takes over inside this distance. |
| `Waldo_ImprovedHelicopterLanding_TriggerSpeedFactor` | `4.2` | MULTIPLIER: approach-speed trigger scaling. |
| `Waldo_ImprovedHelicopterLanding_MinimumApproachSpeed` | `55` | KM/H: minimum speed when scripted approach control begins. |
| `Waldo_ImprovedHelicopterLanding_TransitAltitude` | `30` | METRES AGL: clear-terrain approach height. |
| `Waldo_ImprovedHelicopterLanding_GlideSlopeRatio` | `4` | RATIO: horizontal distance per metre of descent. |
| `Waldo_ImprovedHelicopterLanding_TreeScanRadius` | `25` | METRES: vegetation search around touchdown. |
| `Waldo_ImprovedHelicopterLanding_TreeSafetyBuffer` | `5` | METRES: clearance added above detected canopy. |
| `Waldo_ImprovedHelicopterLanding_MaximumTreeHoverHeight` | `40` | METRES: canopy correction ceiling. |
| `Waldo_ImprovedHelicopterLanding_GoAroundTriggerDistance` | `200` | METRES: assess excessive height inside this range. |
| `Waldo_ImprovedHelicopterLanding_GoAroundHeight` | `150` | METRES AGL: climb target during a go-around. |
| `Waldo_ImprovedHelicopterLanding_GoAroundExitDistance` | `250` | METRES: distance flown clear before re-approach. |
| `Waldo_ImprovedHelicopterLanding_GoAroundSpeed` | `70` | KM/H: commanded go-around speed. |
| `Waldo_ImprovedHelicopterLanding_MaximumGoArounds` | `1` | COUNT: maximum automatic retries for one landing order. |
| `Waldo_ImprovedHelicopterLanding_MaximumClimbRate` | `8` | METRES/SECOND: vertical command clamp. |
| `Waldo_ImprovedHelicopterLanding_MaximumDescentRate` | `10` | METRES/SECOND: descent command clamp. |
| `Waldo_ImprovedHelicopterLanding_TouchdownRadius` | `5` | METRES: accepted horizontal error. Larger is easier but less exact. |
| `Waldo_ImprovedHelicopterLanding_FinalCommitDistance` | `75` | METRES: begin the final flare/landing phase. |
| `Waldo_ImprovedHelicopterLanding_ControlInterval` | `0.05` | SECONDS: local control-loop interval; performance-sensitive. |
| `Waldo_ImprovedHelicopterLanding_TouchdownHoldSeconds` | `20` | SECONDS: keep the AI landed before releasing controls; prevents immediate takeoff. |
| `Waldo_HelicopterDeceleration_Enable` | `false` | BOOL: suppress AI zoom-climb while braking; test airframes before enabling. |
| `Waldo_HelicopterDeceleration_IncludeVTOL` | `false` | BOOL: include VTOL_Base_F aircraft; false is the conservative default. |
| `Waldo_HelicopterDeceleration_MinimumSpeed` | `80` | KM/H: detection is ignored below this airspeed. |
| `Waldo_HelicopterDeceleration_MinimumAltitude` | `25` | METRES AGL: never correct close to terrain. |
| `Waldo_HelicopterDeceleration_MinimumSpeedLoss` | `4` | KM/H PER SAMPLE: braking threshold. |
| `Waldo_HelicopterDeceleration_MinimumAltitudeGain` | `0.5` | METRES PER SAMPLE: unwanted climb threshold. |
| `Waldo_HelicopterDeceleration_MinimumNoseUp` | `0.02` | VECTOR DIR Z: positive nose-up threshold. |
| `Waldo_HelicopterDeceleration_TerrainClearance` | `25` | METRES: required clearance over terrain 100/300/500 m ahead. |
| `Waldo_HelicopterDeceleration_MaximumCorrectionAcceleration` | `2.5` | M/S^2: downward world-force cap. |
| `Waldo_HelicopterDeceleration_MaximumClimbRate` | `0.5` | M/S: release once vertical climb falls to this value. |
| `Waldo_HelicopterDeceleration_SampleInterval` | `0.5` | SECONDS: local detection cadence. |
| `Waldo_HelicopterDeceleration_ControlInterval` | `0.02` | SECONDS: active correction cadence. |
| `Waldo_HelicopterDeceleration_MaximumCorrectionSeconds` | `4` | SECONDS: hard cap per correction event. |
| `Waldo_HelicopterDeceleration_Debug` | `false` | BOOL: detailed RPT acquire/release logging. |
| `Waldo_AIPass_Enable` | `true` | BOOL: master switch for Cortex automatic tactics (server and headless clients only). |
| `Waldo_AIPass_IncludedSides` | `["WEST", "EAST", "GUER"]` | ARRAY of WEST/EAST/GUER/CIV strings the pass may command. |
| `Waldo_AIPass_TickBudgetMs` | `1` | MILLISECONDS: work allowed per 0.25 s scheduler tick; at least one job always runs. |
| `Waldo_AIPass_LowFpsThreshold` | `25` | FPS: below this, behaviour steps are rescheduled half as often. |
| `Waldo_AIPass_Regroup_Enable` | `true` | BOOL: survivors of a destroyed squad regroup with a nearby friendly squad. |
| `Waldo_AIPass_Regroup_MaxRemnantSize` | `2` | COUNT: living members at or below this make a remnant. |
| `Waldo_AIPass_Regroup_MinimumPeakSize` | `3` | COUNT: smaller deliberate teams are never merged. |
| `Waldo_AIPass_Regroup_SearchRadius` | `400` | METRES: host squad search radius. |
| `Waldo_AIPass_Regroup_MaxGroupSize` | `12` | COUNT: host size limit after the merge. |
| `Waldo_AIPass_Regroup_JoinDistance` | `30` | METRES: survivors join the host inside this distance. |
| `Waldo_AIPass_Regroup_StuckSeconds` | `20` | SECONDS: without progress, survivors join where they stand. |
| `Waldo_AIPass_Regroup_TimeoutSeconds` | `120` | SECONDS: limit for finding a host and for walking to it. |
| `Waldo_AIPass_Regroup_SettleSeconds` | `5` | SECONDS: delay after a kill before the remnant is assessed. |
| `Waldo_AIPass_BehaviourProfile` | `""` | STRING: "" follows the AI Rebalance profile; MILITIA, LINE, VETERAN or ELITE sets squad tactics for every squad without its own. |
| `Waldo_AIPass_Aggression` | `1.2` | 0-2: scales how often squads flank, assault, advance, investigate and coordinate. |
| `Waldo_AIPass_Cohesion` | `1` | 0.5-2: above 1 squads take more before morale breaks, below 1 they break sooner. |
| `Waldo_AIPass_ReactionSpeed` | `1` | 0.5-2: above 1 squads re-assess more often (more server time), below 1 less often. |
| `Waldo_AIPass_LambsMode` | `"SPLIT"` | STRING: SPLIT (LAMBS keeps in-contact unit tactics) or WMP (LAMBS group AI off for managed squads). |
| `Waldo_AIPass_CivilianReaction_Enable` | `true` | BOOL: event-driven flight for unarmed civilians; Simple Civilian Behaviour takes priority. |
| `Waldo_AIPass_CivilianReaction_Radius` | `45` | METRES: nearby gunfire trigger range. |
| `Waldo_AIPass_CivilianReaction_Distance` | `180` | METRES: approximate one-shot escape leg. |
| `Waldo_AIPass_CivilianReaction_Cooldown` | `20` | SECONDS: minimum delay before replacing a civilian escape order. |
| `Waldo_AIPass_Debug` | `false` | BOOL: extra [WMP CORTEX] RPT lines for contact, flanks, morale and retreats. |
| `Waldo_AIPass_EngageRange` | `800` | METRES: enemies the leader knows about within this range are considered. |
| `Waldo_AIPass_NearRange` | `1000` | METRES: squads this close to a player run at the near cadence. |
| `Waldo_AIPass_FarRange` | `2500` | METRES: beyond this only the state ladder and morale run. |
| `Waldo_AIPass_TickContact` | `2` | SECONDS: step interval for a squad in contact near players. |
| `Waldo_AIPass_TickNear` | `4` | SECONDS: step interval within NearRange. |
| `Waldo_AIPass_TickMid` | `8` | SECONDS: step interval within FarRange. |
| `Waldo_AIPass_TickFar` | `20` | SECONDS: step interval beyond FarRange. |
| `Waldo_AIPass_DiscoveryInterval` | `10` | SECONDS: how often each machine looks for newly local AI groups. |
| `Waldo_AIPass_Contact_Enable` | `true` | BOOL: contact state ladder; needed by every combat behaviour. |
| `Waldo_AIPass_PostContact_Enable` | `true` | BOOL: hold, search the last known position, regroup after contact. |
| `Waldo_AIPass_PostContact_LostSeconds` | `30` | SECONDS: without a sighting before contact counts as lost. |
| `Waldo_AIPass_PostContact_SecuritySeconds` | `10` | SECONDS: security hold before searching. |
| `Waldo_AIPass_PostContact_SearchSeconds` | `45` | SECONDS: search time limit. |
| `Waldo_AIPass_PostContact_RegroupSeconds` | `30` | SECONDS: regroup time limit. |
| `Waldo_AIPass_Flank_Enable` | `true` | BOOL: base of fire plus a flanking element in covered bounds. |
| `Waldo_AIPass_Flank_MinGroupSize` | `6` | COUNT: soldiers on foot needed to flank. |
| `Waldo_AIPass_Flank_MinRange` | `60` | METRES: nearer enemies are fought, not flanked. |
| `Waldo_AIPass_Flank_MaxRange` | `400` | METRES: farther enemies are not flanked. |
| `Waldo_AIPass_Flank_BoundDistance` | `55` | METRES: length of one bound (minimum 15). |
| `Waldo_AIPass_Flank_BoundPause` | `2` | SECONDS: overwatch halt between bounds. |
| `Waldo_AIPass_Flank_BoundTimeout` | `25` | SECONDS: a bound ends after this even if not everyone arrived. |
| `Waldo_AIPass_Flank_Cooldown` | `90` | SECONDS: before the same squad flanks again. |
| `Waldo_AIPass_StreetCrossing_Enable` | `true` | BOOL: flanks stop at roads, smoke, and cross in one bound. |
| `Waldo_AIPass_FireControl_Enable` | `true` | BOOL: close threats, fire distribution, disciplined suppression. |
| `Waldo_AIPass_FireControl_MaxSuppressors` | `2` | COUNT: soldiers suppressing at once. |
| `Waldo_AIPass_FireControl_MaxShootersPerTarget` | `2` | COUNT: shooters per visible enemy before others switch. |
| `Waldo_AIPass_Morale_Enable` | `true` | BOOL: weighted morale; broken squads retreat under smoke. |
| `Waldo_AIPass_Morale_RetreatDistance` | `200` | METRES: how far a broken squad falls back. |
| `Waldo_AIPass_Surrender_Enable` | `true` | BOOL: last survivors of a broken, isolated squad surrender. |
| `Waldo_AIPass_GrenadeEvasion_Enable` | `true` | BOOL: move away from seen grenades. |
| `Waldo_AIPass_AntiArmour_Enable` | `true` | BOOL: best AT gunner engages known armour, clear of backblast. |
| `Waldo_AIPass_VehicleDismount_Enable` | `true` | Unloads capable passengers only when safely stopped on dry ground. |
| `Waldo_AIPass_VehicleRemount_Enable` | `true` | Allows safe conscious passengers to reboard after Smart AI contact. Convoy resume stays explicit. |
| `Waldo_AIPass_VehicleWithdraw_Enable` | `true` | Allows damaged vehicles to withdraw and use existing smoke. |
| `Waldo_AIPass_CoverValidation_Enable` | `true` | Adds bounded slope and body clearance checks to shared cover selection. |
| `Waldo_Convoy_MountedFire_Enable` | `true` | WMP assigns targets to weapon crew under existing ROE. Disable to leave targeting to another AI mod. |
| `Waldo_Convoy_Cover_Enable` | `true` | Moves dismounted passengers clear of vehicles; seeks cover during contact. |
| `Waldo_Convoy_AvoidInfantry_Enable` | `false` | Optional short-range friendly infantry corridor checks before driving. |
| `Waldo_Convoy_DrivingAssist_Enable` | `true` | Low-frequency road look-ahead and damped speed changes for smoother curves, junctions and grades without replacing authored routes or bypassing obstacles. |
| `Waldo_Convoy_RouteRecovery_Enable` | `true` | Re-select the same unchanged final MOVE waypoint when the engine completes it prematurely while the convoy remains well outside its completion radius. Never creates a route, teleports, repairs or bypasses an obstruction. |
| `Waldo_Convoy_ContactHalt_Enable` | `true` | Automatic ambush halt using push-through and pinned rules. Route arrival and explicit stop remain available. |
| `Waldo_Convoy_Unload_Enable` | `true` | Allows WMP passenger unloading on halt. Operating crews remain aboard. |
| `Waldo_AIPass_Hearing_Enable` | `true` | Nearby gunfire creates throttled approximate investigation reports, never target reveals. |
| `Waldo_AIPass_Vehicles_Enable` | `true` | BOOL: dismount under fire; damaged vehicles smoke and withdraw. |
| `Waldo_AIPass_NavalAssault_Enable` | `true` | BOOL: finite coastal boat approach and infantry landing; yields to PROTOCOL AI NAVY SEAL. |
| `Waldo_AIPass_ContactReports_Enable` | `true` | BOOL: share sightings by radio (jammable) or voice. |
| `Waldo_AIPass_ContactReports_Radius` | `500` | METRES: radio report range. |
| `Waldo_AIPass_ContactReports_VoiceRange` | `35` | METRES: report range when AI transmission is blocked. |
| `Waldo_Cortex_CombinedArms_AirRange` | `4000` | METRES: radio-linked aircraft support opportunity radius, independent of squad report range. |
| `Waldo_AIPass_ContactReports_RequireRadio` | `false` | Legacy compatibility only: AI inventory radios are no longer checked. |
| `Waldo_AIPass_Reinforce_Enable` | `true` | BOOL: idle nearby squads move up behind a squad in contact. |
| `Waldo_AIPass_Reinforce_Radius` | `600` | METRES: how far away responders may be. |
| `Waldo_AIPass_Reinforce_MaxResponders` | `2` | COUNT: responding squads per squad in contact. |
| `Waldo_AIPass_Artillery_Enable` | `false` | BOOL: squads call fire from friendly AI artillery on well-located enemies. |
| `Waldo_AIPass_Artillery_OpeningSafeDistance` | `200` | Advanced artillery ranging control. |
| `Waldo_AIPass_Artillery_OpeningBuffer` | `100` | Advanced artillery ranging control. |
| `Waldo_AIPass_Artillery_WarningInterval` | `20` | Advanced artillery ranging control. |
| `Waldo_AIPass_Artillery_Bursts` | `3` | Maximum HE bursts per mission; smoke uses one burst. |
| `Waldo_AIPass_Artillery_RoundInterval` | `2` | Minimum seconds between confirmed rounds inside one burst. |
| `Waldo_AIPass_Artillery_LocationResetDistance` | `150` | Reported movement in metres that resets opening offset and safety checks. |
| `Waldo_AIPass_CounterBattery_RadarDelay` | `20` | Counter-battery acquisition seconds with radar coverage; capped by the normal delay. |
| `Waldo_AIPass_Artillery_Rounds` | `3` | COUNT: rounds per support burst. |
| `Waldo_AIPass_Artillery_MinFriendlyDistance` | `200` | METRES: no mission near friendlies or civilians. |
| `Waldo_AIPass_Artillery_MaxError` | `50` | METRES: largest target position error accepted. |
| `Waldo_AIPass_Artillery_Cooldown` | `120` | SECONDS: between missions called by one squad. |
| `Waldo_AIPass_Artillery_ShootAndScoot` | `true` | BOOL: mobile batteries relocate after a support mission. |
| `Waldo_AIPass_Artillery_DefaultRole` | `"BOTH"` | STRING: SUPPORT, COUNTER or BOTH for guns with no role of their own. |
| `Waldo_AIPass_CounterBattery_Enable` | `false` | BOOL: AI artillery answers enemy artillery whose position is known. |
| `Waldo_AIPass_CounterBattery_Mode` | `"AUTO"` | Legacy compatibility: detection is always automatic. |
| `Waldo_AIPass_CounterBattery_RadarRange` | `8000` | METRES: radar detection range. |
| `Waldo_AIPass_CounterBattery_Delay` | `60` | SECONDS: before counter-battery fire. |
| `Waldo_AIPass_CounterBattery_Rounds` | `4` | COUNT: rounds per counter-battery burst. |
| `Waldo_AIPass_CounterBattery_MaxError` | `100` | Metres: maximum accepted spotter correction error. Automatic firing-event acquisition uses a 30 m report error. |
| `Waldo_AIPass_CounterBattery_MinFriendlyDistance` | `200` | METRES: no fire near friendlies or civilians. |
| `Waldo_AIPass_CounterBattery_Interval` | `60` | SECONDS: before the same enemy gun is answered again. |
| `Waldo_AIPass_CounterBattery_ShootAndScoot` | `true` | BOOL: mobile batteries relocate after counter-battery. |
| `Waldo_AIPass_Airborne_Enable` | `false` | BOOL: AI passengers parachute out near known enemies. |
| `Waldo_AIPass_Airborne_ApproachDistance` | `2000` | METRES: climb to jump altitude inside this range. |
| `Waldo_AIPass_Airborne_DeployDistance` | `700` | METRES: jump inside this range of a known enemy. |
| `Waldo_AIPass_Airborne_Altitude` | `250` | METRES: jump altitude above ground. |
| `Waldo_AIPass_Airborne_MinAltitude` | `120` | METRES: never jump lower than this. |
| `Waldo_AIPass_Airborne_JumpInterval` | `1` | SECONDS: between jumpers. |
| `Waldo_AIPass_Garrison_DynamicAO` | `false` | BOOL: WMP garrison handling for Dynamic AO garrisons. |
| `Waldo_AIPass_Garrison_BreakFraction` | `0.5` | 0-1: a garrison breaks at this share of its strength. |
| `Waldo_Cortex_AttackRunFlares_Enable` | `true` | BOOL: finite countermeasure requests while eligible AI aircraft approach and leave assigned attack targets. |
| `Waldo_Cortex_AirAttack_Enable` | `true` | BOOL: finite threat-aware strafe, offset, hook, capability-gated lateral and aimed standoff attack patterns. |
| `Waldo_AIPass_AircraftFlares_Enable` | `true` | BOOL: eligible AI aircraft make a staggered countermeasure sequence after a missile warning. |
| `Waldo_AIPass_FactionProfiles` | `createHashMap` | MAP: CfgFactionClasses name to behaviour profile, for example OPF_F to ELITE. |
| `Waldo_AIPass_ZeusHoldSeconds` | `120` | SECONDS: the pass leaves a group alone this long after Zeus selects or edits it. |
| `Waldo_AIPass_Investigate_Enable` | `true` | BOOL: squads check out enemies they know about but have not seen. |
| `Waldo_AIPass_Investigate_Range` | `300` | METRES: how far away a known enemy may be to be investigated. |
| `Waldo_AIPass_Investigate_Seconds` | `60` | SECONDS: investigation time limit. |
| `Waldo_AIPass_Assault_Enable` | `true` | BOOL: a flank can finish with a grenade and a rush on the enemy position. |
| `Waldo_AIPass_Assault_Range` | `80` | METRES: the enemy must be this close to the flanking element to assault. |
| `Waldo_AIPass_Advance_Enable` | `true` | BOOL: pinned squads with somewhere to go push a team forward in bounds. |
| `Waldo_AIPass_Advance_MinContactSeconds` | `5` | SECONDS: confirmed contact before an advance is considered. |
| `Waldo_AIPass_Advance_Cooldown` | `20` | SECONDS: after an advance ends before the squad may start another. |
| `Waldo_AIPass_CoordinatedAssault_Enable` | `true` | BOOL: reinforcing squads assault together while the first squad fires. |
| `Waldo_AIPass_Stance_Enable` | `true` | BOOL: stance chosen from the height of the cover in front. |
| `Waldo_AIPass_AmmoShare_Enable` | `true` | BOOL: soldiers low on magazines get one from a squad-mate. |
| `Waldo_AIPass_AmmoShare_Distance` | `10` | METRES: how close the squad-mate must be. |
| `Waldo_AIPass_VehicleGunnery_Enable` | `true` | BOOL: gunners prioritise AT soldiers; armour keeps away from them. |
| `Waldo_AIPass_Vehicles_StandoffDistance` | `250` | METRES: distance armour keeps from known AT soldiers. |
| `Waldo_AIPass_ArtillerySmoke_Enable` | `true` | BOOL: a retreating squad gets an artillery smoke screen (needs Artillery). |
| `Waldo_AIPass_AircraftBreak_Enable` | `true` | BOOL: eligible AI aircraft preserve forward energy while making a bounded break from missile launches. |


## Behaviour profile map

Waldo_AIPass_ProfileBehaviour has these defaults. Chance values are weighted by aggression and eligibility; they are not a promise to act on every tick.

```sqf
            ["MILITIA", createHashMapFromArray [["flankChance", 0.3], ["assaultChance", 0.2], ["advanceChance", 0.3], ["investigateChance", 0.4], ["coordinatedChance", 0.2], ["moraleShaken", 0.65], ["moraleBroken", 0.4], ["retreatScale", 1.5], ["surrenderSurvivors", 3]]],
            ["LINE", createHashMapFromArray [["flankChance", 0.5], ["assaultChance", 0.4], ["advanceChance", 0.5], ["investigateChance", 0.6], ["coordinatedChance", 0.4], ["moraleShaken", 0.55], ["moraleBroken", 0.3], ["retreatScale", 1], ["surrenderSurvivors", 2]]],
            ["LEGACY", createHashMapFromArray [["flankChance", 0.5], ["assaultChance", 0.4], ["advanceChance", 0.5], ["investigateChance", 0.6], ["coordinatedChance", 0.4], ["moraleShaken", 0.55], ["moraleBroken", 0.3], ["retreatScale", 1], ["surrenderSurvivors", 2]]],
            ["VETERAN", createHashMapFromArray [["flankChance", 0.6], ["assaultChance", 0.55], ["advanceChance", 0.6], ["investigateChance", 0.75], ["coordinatedChance", 0.5], ["moraleShaken", 0.45], ["moraleBroken", 0.22], ["retreatScale", 0.8], ["surrenderSurvivors", 1]]],
            ["ELITE", createHashMapFromArray [["flankChance", 0.7], ["assaultChance", 0.7], ["advanceChance", 0.7], ["investigateChance", 0.85], ["coordinatedChance", 0.6], ["moraleShaken", 0.4], ["moraleBroken", 0.18], ["retreatScale", 0.7], ["surrenderSurvivors", 1]]]
```

Waldo_AI_ProfileDisplayNames: LEGACY = Existing Mission Balance; MILITIA = WMP Militia; LINE = WMP Line; VETERAN = WMP Veteran; ELITE = WMP Elite.

The table includes all single-line shared settings. The two multiline maps are documented above.
