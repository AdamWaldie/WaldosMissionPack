# Feature Configuration Files

> **Use this page when:** you need to find, understand, or safely change a WMP feature setting.

All mission-maker feature settings live under `MissionConfig`. Each file returns pure data in the
same manner as `acreConfig.sqf`; lifecycle code applies only the correct `SHARED`, `SERVER`, or
`PLAYER_LOCAL` section. Existing values win. A server entry marked for publication is broadcast
once by `initServer.sqf` and remains available to JIP clients. The loader never promotes a local
setting into authoritative state.

The exact shipped defaults are visible beside each variable in the config files. The tables below
define purpose, units and constrained values. Empty arrays/maps mean unrestricted or no overrides
unless the feature guide states otherwise.

## Which settings should I change?

The existence of a setting is not a recommendation to alter it. Config comments use three labels:

| Label | Meaning |
|---|---|
| **MISSION MAKER** | Review for each mission. These select feature enablement, sides/factions/classes, names, content pools, scenario rules and player-facing behavior. |
| **ADVANCED TUNING** | Supported but normally retain the shipped value. Change only for a specific requirement and retest hosted and dedicated behavior. This includes scheduler intervals, safety bounds, UI geometry and AI control loops. |
| **COMPATIBILITY** | Parser or older-call support. Do not use as ordinary mission configuration. |

Recommended review by file:

| File | Mission-maker choices | Normally leave alone |
|---|---|---|
| `acreConfig.sqf` | Enablement, named displays, nets, per-occurrence group/player/role assignments, ear placement and Babel languages | Schema version, strict validation, group-change retuning, priority and shipped capability profiles |
| `persistenceConfig.sqf` | Enablement, saved data categories and database/campaign name | Save cadence and custom-variable serialization list |
| `interfaceConfig.sqf` | Theme, treatment recipients/content, emergency-dismount policy and PID eligibility/content | Queue/reflow limits, tactical knowledge threshold, placement geometry and Draw3D scale/offset internals |
| `aiConfig.sqf` | AI profile/mode, application population and inclusion/exclusion filters | Skill variance and helicopter landing controller values |
| `airOperationsConfig.sqf` | Feature enablement, aircraft/chute/boarding pools, AA assets and jump envelopes | Monitor cadence, service thresholds and server maximum bounds |
| `logisticsConfig.sqf` | Resupply content/balance, recovery packages/markers, scale range and crate classes | Scan cadence, safe-placement geometry, client scaling authority and dependency fallback |
| `environmentConfig.sqf` | Hazard profiles, tree tools/replacements/protected areas and breaching content | Tick rates, damage cadence, tree geometry/cooldowns and regrowth scheduler values |
| `electronicWarfareConfig.sqf` | EW rules, player feedback/toggles and disable challenge | Signal curve/reference, RDF fuzz bands and diagnostics overlay |
| `missionSystemsConfig.sqf` | Rally rules, optional-system enablement, diagnostics and safestart contract | Safe-position geometry and global ACE weight/hearing overrides |

## Common option formats

- Sides: `WEST`, `EAST`, `GUER`/`INDEPENDENT`, and `CIV`/`CIVILIAN` as documented by the specific system.
- AI profiles: `MILITIA`, `LINE`, `VETERAN`, `ELITE`; mode `DAY` or `NIGHT`; apply mode `BOTH`, `EXISTING` or `NEW`.
- UI themes: `DEFAULT`, `WW2`, `VIETNAM`, `SCIFI`.
- Notification placements: `TOP_RIGHT`, `CENTER`, `BOTTOM_LEFT`, `BOTTOM_CENTER`, `BOTTOM_RIGHT`. `TOP` is reserved for mission-flow banners.
- ACRE PRC-343 assignment: `[block, channel]`; both are 1–16 under the default `FULL_RANGE` policy. `SIDE_ISOLATED` reduces WEST/EAST/GUER blocks to 1–5. `[]` requests deterministic allocation.
- ACRE explicit radio: `[base class, same-type occurrence, target, ear]`; ears are `LEFT`, `RIGHT`, `BOTH` or `CENTER`.
- ACRE profile modes: `BLOCK_CHANNEL`, `CHANNEL`, `FREQUENCY`. WMP deliberately leaves alternate PTT defaults alone.
- Jammer disable result: `DISABLE` for the repairable/reactivatable disabled state or `DEACTIVATE` for an ordinary off state.
- Interaction difficulty: `easy`, `standard`, `hard`, `expert`.
- Distances/altitudes are metres and durations are seconds unless a row states otherwise. Damage, fuel and ammunition fractions are `0` through `1`.

## `acreConfig.sqf`

| Key | Purpose |
|---|---|
| `version` | Configuration schema revision required by validation. |
| `enabled` | Enables the replacement ACRE lifecycle. |
| `strict` | Promotes explicit PRC-343 collisions from reported warnings to configuration errors. Structural errors are always rejected. |
| `prc343PresetPolicy` | `FULL_RANGE` keeps all sixteen blocks on every side; `SIDE_ISOLATED` trades combat-side capacity for cross-side PRC-343 frequency separation. It does not change the presets used by other radios. |
| `retuneOnGroupChange` | Allows event-driven group-change retuning; disabled to preserve captured radios. The CEOI still refreshes. |
| `namedDisplays` | Enables supported physical radio channel labels. |
| `notifyAssignmentProblems` | Shows a local WMP warning for failed manual/QA assignment without intruding on initial loading or normal respawn. |
| `radioPriority` | Ordered base-radio classes used when assigning logical long-range nets. |
| `radioProfiles` | Per-radio capability mode, fallback ear sequence and maximum valid numbered channel or tuning range. Shipped limits are PRC-148 32, PRC-152/117F 100, BF-888S 16, SEM52SL 13, PRC-77 30–75.95 MHz/50 kHz and SEM70 30–79.975 MHz/25 kHz. |
| `radioOverrides` | Optional first-match UID, editor-variable or role replacement assignment lists. |
| `sides` | Side preset, logical nets, fallback group mappings and explicit same-type occurrence assignments. |
| `babel` | Language definitions, side defaults, speaking language, overrides and unit-follow behavior. |

See [ACRE2 Babel Configuration](ACRE2-Babel-Configuration),
[PRC-343 Automatic Setup](ACRE-2-Squad-Level-Radios-AN-PRC%E2%80%90343-Automatic-Setup), and
[Long-Range Radio Presetting](ACRE-2-Long-Range-Radio-Presetting).

## `persistenceConfig.sqf` — shared

| Setting | Purpose / units |
|---|---|
| `Waldo_Persistence_Enable` | Master opt-in; the server dependency gate can still reject a missing INIDBI2 extension. |
| `Waldo_Persistence_PlayerSaveInterval` | Seconds between player capture requests. |
| `Waldo_Persistence_ObjectSaveInterval` | Seconds between registered-object saves. |
| `Waldo_Persistence_SaveLoadout` | Saves ACRE-filtered player inventory/loadout. |
| `Waldo_Persistence_SaveMedical` | Saves supported ACE medical state. |
| `Waldo_Persistence_SaveFoodWater` | Saves supported survival values. |
| `Waldo_Persistence_SavePosition` | Saves/restores player position; disabled by default for mission safety. |
| `Waldo_Persistence_SaveRadios` | Stores supported radio channel/spatial state separately from base-class loadouts. |
| `Waldo_Persistence_DatabaseName` | INIDBI2 database namespace. |
| `Waldo_Persistence_DefaultCustomVariables` | Object-variable names copied for registered persistent objects. |

## `interfaceConfig.sqf` — shared

| Setting | Purpose / valid values |
|---|---|
| `Waldo_UI_Theme` | Global visual theme: `DEFAULT`, `WW2`, `VIETNAM`, `SCIFI`, or registered custom ID. |
| `Waldo_UI_CustomThemes` | Custom theme definitions keyed by theme ID. |
| `Waldo_UI_ThemeOverrides` | Mission-wide component-level theme overrides. |

## `interfaceConfig.sqf` — player local

### Notification flow

| Setting | Purpose / units |
|---|---|
| `Waldo_UiNotification_MaximumQueued` | Maximum pending notification channels before coalescing/eviction. |
| `Waldo_UiNotification_QueueLifetime` | Seconds a pending notification may wait before expiry. |
| `Waldo_UiNotification_MaximumPerPlacement` | Simultaneous cards in one screen placement. |
| `Waldo_UiNotification_ReflowDuration` | Seconds used to animate surviving cards into closed gaps. |
| `Waldo_UiNotification_AllowPlacementOverflow` | Allows a full stream to spill into configured alternate placements. |
| `Waldo_UiNotification_OverflowPlacements` | Ordered general overflow placements; top-centre remains reserved. |
| `Waldo_UI_PanelPlacements` | Feature-channel to placement mapping and stacking-enabled flag. |

### Patient treatment feedback

| Setting | Purpose |
|---|---|
| `Waldo_TreatmentFeedback_Enable` | Installs ACE treatment feedback locally. |
| `Waldo_TreatmentFeedback_ShowStart` | Shows treatment-start state. |
| `Waldo_TreatmentFeedback_ShowSuccess` | Shows successful completion. |
| `Waldo_TreatmentFeedback_ShowFailure` | Shows interrupted/failed completion. |
| `Waldo_TreatmentFeedback_NotifyPatient` | Sends visible feedback to the patient owner. |
| `Waldo_TreatmentFeedback_NotifyMedic` | Also shows feedback to the treating medic. |
| `Waldo_TreatmentFeedback_ShowMedicName` | Includes treating-unit name when available. |
| `Waldo_TreatmentFeedback_ShowBodyPart` | Includes translated treatment body region. |
| `Waldo_TreatmentFeedback_StartTitle` | Start-card title text. |
| `Waldo_TreatmentFeedback_SuccessTitle` | Success-card title text. |
| `Waldo_TreatmentFeedback_FailureTitle` | Failure-card title text. |
| `Waldo_TreatmentFeedback_Duration` | Post-event card lifetime in seconds. |
| `Waldo_TreatmentFeedback_TreatmentNames` | Treatment-class to display-name overrides. |
| `Waldo_TreatmentFeedback_BodyPartNames` | ACE body-part key to readable label map. |

### Tactical display

| Setting | Purpose / units |
|---|---|
| `Waldo_TacticalDisplay_AccessDistance` | Metres within which the registered display action is available. |
| `Waldo_TacticalDisplay_MaximumOpenDistance` | Metres before an already-open display closes. |
| `Waldo_TacticalDisplay_MinimumKnowledge` | Minimum Arma knowledge value for enemy display. |

### Emergency dismount

| Setting | Purpose / valid values |
|---|---|
| `Waldo_EmergencyDismount_Enable` | Installs local emergency-exit monitoring. |
| `Waldo_EmergencyDismount_OnOverturn` | Allows exit after the vehicle remains overturned. |
| `Waldo_EmergencyDismount_OnDestroyed` | Allows exit from a destroyed vehicle. |
| `Waldo_EmergencyDismount_PreserveVelocity` | Carries vehicle velocity into the exited unit. |
| `Waldo_EmergencyDismount_ProtectDuringExit` | Applies temporary exit protection. |
| `Waldo_EmergencyDismount_ProtectionSeconds` | Protection duration in seconds. |
| `Waldo_EmergencyDismount_ClearPositionRadius` | Metres searched for a safe exit position. |
| `Waldo_EmergencyDismount_RequireClearExit` | Refuses the action when no safe position is found. |
| `Waldo_EmergencyDismount_UseEject` | Uses eject instead of ordinary get-out behavior. |
| `Waldo_EmergencyDismount_RecoverUnconscious` | Allows configured recovery of an unconscious occupant. |
| `Waldo_EmergencyDismount_MinimumOverturnSeconds` | Continuous overturned time required. |
| `Waldo_EmergencyDismount_DamageOnExit` | Additional damage applied on successful exit. |
| `Waldo_EmergencyDismount_AllowedKinds` | Vehicle inheritance classes eligible for monitoring. |
| `Waldo_EmergencyDismount_VehicleProfiles` | Per-vehicle-class setting overrides. |

### Accessibility PID

| Setting | Purpose / units |
|---|---|
| `Waldo_AccessibilityPID_Enable` | Enables PID for eligible local users. |
| `Waldo_AccessibilityPID_AllowedUIDs` | Steam UID allowlist; `[]` permits every player. |
| `Waldo_AccessibilityPID_DefaultVisible` | Initial local visibility. |
| `Waldo_AccessibilityPID_AllowToggle` | Exposes the accessibility self-interaction toggle. |
| `Waldo_AccessibilityPID_IconRange` | Maximum icon range in metres. |
| `Waldo_AccessibilityPID_NameRange` | Maximum name range in metres. |
| `Waldo_AccessibilityPID_RequireLOS` | Requires local view line of sight. |
| `Waldo_AccessibilityPID_IncludeAI` | Includes friendly AI. |
| `Waldo_AccessibilityPID_IconScale` | Base chevron/icon scale. |
| `Waldo_AccessibilityPID_TextScale` | Base name text scale. |
| `Waldo_AccessibilityPID_DistanceFade` | Fades presentation with distance. |
| `Waldo_AccessibilityPID_GroupOnly` | Restricts PID to the player's group. |
| `Waldo_AccessibilityPID_ShowIncapacitated` | Retains identifiers for incapacitated friendlies. |
| `Waldo_AccessibilityPID_ShowIcons` | Draws the friendly chevron/icon. |
| `Waldo_AccessibilityPID_ShowNames` | Draws names within `NameRange`. |
| `Waldo_AccessibilityPID_ShowVehicleCrew` | Includes eligible friendly vehicle occupants. |
| `Waldo_AccessibilityPID_Font` | Arma font classname used for clear 3D text. |
| `Waldo_AccessibilityPID_TextDistanceGrowth` | Additional text scale per metre. |
| `Waldo_AccessibilityPID_TextMaximumScale` | Upper bound for distance-scaled text. |
| `Waldo_AccessibilityPID_TextHeadOffset` | Metres above the visual head anchor for names. |
| `Waldo_AccessibilityPID_IconHeadOffset` | Metres above the visual head anchor for icons. |
| `Waldo_AccessibilityPID_OutlineScale` | Dark outline scale relative to foreground text. |
| `Waldo_AccessibilityPID_OutlineColour` | RGBA outline colour. |

## `aiConfig.sqf` — shared

| Setting | Purpose / units |
|---|---|
| `Waldo_AIRebalance_Enable` | Enables WMP skill handling for eligible AI. |
| `Waldo_AIRebalance_Profile` | Default named profile: `MILITIA`, `LINE`, `VETERAN` or `ELITE`. |
| `Waldo_AIRebalance_Mode` | `DAY` or `NIGHT` skill variant; may fall back from the older `Waldo_AI_Mode`. |
| `Waldo_AI_ApplyMode` | Which existing/new AI populations receive the profile. |
| `Waldo_AI_RestoreOnStop` | Restores recorded skills when the handler stops. |
| `Waldo_AI_SkillVariance` | Random variation applied around the selected profile. |
| `Waldo_AI_IncludedSides` | Optional side allowlist. |
| `Waldo_AI_IncludedFactions` | Optional faction allowlist. |
| `Waldo_AI_ExcludedFactions` | Factions never altered. |
| `Waldo_AI_ExcludedClasses` | Unit classes never altered. |
| `Waldo_AI_ProfileDisplayNames` | Curator-facing names for the WMP profiles. |
| `Waldo_ImprovedHelicopterLanding_Enable` | Enables AI-only landing correction. |
| `Waldo_ImprovedHelicopterLanding_MinimumActivationDistance` | Minimum initial aircraft-to-waypoint distance in metres. |
| `Waldo_ImprovedHelicopterLanding_TriggerDistance` | Distance at which approach control begins. |
| `Waldo_ImprovedHelicopterLanding_TriggerSpeedFactor` | Speed-sensitive approach trigger multiplier. |
| `Waldo_ImprovedHelicopterLanding_TransitAltitude` | Nominal approach altitude in metres. |
| `Waldo_ImprovedHelicopterLanding_GlideSlopeRatio` | Horizontal distance per metre of descent. |
| `Waldo_ImprovedHelicopterLanding_TreeScanRadius` | Landing-site tree scan radius in metres. |
| `Waldo_ImprovedHelicopterLanding_TreeSafetyBuffer` | Clearance above detected canopy in metres. |
| `Waldo_ImprovedHelicopterLanding_MaximumTreeHoverHeight` | Maximum canopy-adjusted hover height. |
| `Waldo_ImprovedHelicopterLanding_GoAroundTriggerDistance` | Final-distance window used for high-approach rejection. |
| `Waldo_ImprovedHelicopterLanding_GoAroundHeight` | Excess height that triggers a go-around. |
| `Waldo_ImprovedHelicopterLanding_GoAroundExitDistance` | Distance flown clear before re-approach. |
| `Waldo_ImprovedHelicopterLanding_GoAroundSpeed` | Go-around target speed. |
| `Waldo_ImprovedHelicopterLanding_MaximumGoArounds` | Maximum retries before returning control to vanilla AI. |
| `Waldo_ImprovedHelicopterLanding_MaximumClimbRate` | Maximum commanded climb rate. |
| `Waldo_ImprovedHelicopterLanding_MaximumDescentRate` | Maximum commanded descent rate. |
| `Waldo_ImprovedHelicopterLanding_TouchdownRadius` | Acceptable touchdown error in metres. |
| `Waldo_ImprovedHelicopterLanding_FinalCommitDistance` | Distance inside which the final landing point is committed. |
| `Waldo_ImprovedHelicopterLanding_ControlInterval` | Local control-loop interval in seconds. |
| `Waldo_ImprovedHelicopterLanding_TouchdownHoldSeconds` | Time the AI remains landed before constraints are released. |

## `airOperationsConfig.sqf`

### Shared gunship and paradrop settings

| Setting | Purpose / units |
|---|---|
| `Waldo_Gunship_Enable` | Master opt-in for airborne gunship support. |
| `Waldo_Gunship_DefaultAltitude` / `MaximumAltitude` | Default and upper orbit altitude in metres. |
| `Waldo_Gunship_DefaultRadius` / `MaximumRadius` | Default and upper orbit radius in metres. |
| `Waldo_Gunship_DefaultServiceDuration` | Available service time in seconds. |
| `Waldo_Gunship_MonitorInterval` | Server state-check interval in seconds. |
| `Waldo_Gunship_MinimumFuel` | Fuel fraction that requests service/return. |
| `Waldo_Gunship_MaximumDamage` | Damage fraction that requests service/return. |
| `Waldo_Gunship_ServiceFuelFraction` | Fuel fraction restored by service. |
| `Waldo_Gunship_ServiceAmmoFraction` | Ammunition fraction restored by service. |
| `Waldo_Gunship_ServiceDamage` | Damage value after service. |
| `Waldo_Gunship_MaximumServiceCycles` | Service limit; `-1` is unlimited. |
| `Waldo_Gunship_ReturnWhenOutOfAmmo` | Automatically requests return when weapons are exhausted. |
| `Waldo_Gunship_SideAircraftPools` | Default aircraft choices keyed by operational side. |
| `Waldo_Gunship_FactionAircraftPools` | Optional faction-specific aircraft overrides. |
| `Waldo_Paradrop_AircraftClasses` | Aircraft offered by paradrop selectors. |
| `Waldo_Paradrop_StaticChuteClasses` | Static-line parachute classes. |
| `Waldo_Paradrop_HaloBackpackClasses` | Steerable/HALO parachute backpack classes. |
| `Waldo_Paradrop_BoardingPointClasses` | Movable boarding-point object choices. |
| `Waldo_Paradrop_ChuteClasses` | Compatibility alias populated from static chutes when undefined. |

### Server Dynamic AA and jump limits

| Setting | Purpose / units |
|---|---|
| `Waldo_DynamicAA_DefaultDetectionInterval` | Seconds between target detection passes. |
| `Waldo_DynamicAA_MaximumRadius` | Maximum accepted system radius in metres. |
| `Waldo_DynamicAA_MaximumAltitude` | Maximum accepted detection altitude. |
| `Waldo_DynamicAA_MaximumFighters` | Maximum fighters created by one system. |
| `Waldo_DynamicAA_SideAssetPools` | JIP-published radar, static, mobile and fighter pools by side. |
| `Waldo_DynamicAA_FactionAssetPools` | JIP-published faction overrides. |
| `WALDO_STATIC_MINALTITUDE` / `MAXALTITUDE` | Valid static-line jump altitude band. |
| `WALDO_STATIC_MAXSPEED` | Maximum static-line aircraft speed. |
| `WALDO_STATIC_STATICCHUTE` | Default static-line parachute classname. |
| `WALDO_PARA_HALOALTITUDE` | Minimum HALO jump altitude. |
| `WALDO_PARA_HALOCHUTE` | Default HALO parachute backpack classname. |

## `logisticsConfig.sqf`

| Setting | Purpose / units |
|---|---|
| `Waldo_FieldResupply_Enable` | Master field-resupply opt-in. |
| `Waldo_FieldResupply_CrateClass` | Deployed resupply crate class. |
| `Waldo_FieldResupply_DefaultCarrierCapacity` | Default virtual crates carried. |
| `Waldo_FieldResupply_ChargesPerCrate` | Resupply uses available from one deployed crate. |
| `Waldo_FieldResupply_MagazinesPerType` | Fixed magazines granted per compatible type. |
| `Waldo_FieldResupply_UseCapacityBasedAmounts` | Uses the capacity table instead of the fixed amount. |
| `Waldo_FieldResupply_CapacityAmounts` | Amounts for the supported magazine-capacity bands. |
| `Waldo_FieldResupply_MinimumMagazineRounds` | Rejects nearly empty source magazines below this count. |
| `Waldo_FieldResupply_AllowedMagazines` | Optional explicit magazine allowlist. |
| `Waldo_FieldResupply_BlockedMagazines` | Explicit denylist applied after discovery. |
| `Waldo_FieldResupply_RetainOnRespawn` | Restores carrier entitlement after vehicle respawn. |
| `Waldo_Recovery_ScanInterval` | Server recovery-monitor interval in seconds. |
| `Waldo_Recovery_NotificationRadius` | Radius receiving workshop completion notices. |
| `Waldo_Recovery_CreateWorkshopMarkers` | Creates the area and exact workshop markers. |
| `Waldo_Recovery_PlacementClearance` | Required clearance around restored vehicles. |
| `Waldo_Recovery_DefaultCustomVariables` | Additional variables/scripts copied through packages. |
| `Waldo_Recovery_PackageClasses` | Classes recognised as virtual recovery packages. |
| `Waldo_ObjectScaling_Minimum` / `Maximum` | Server-accepted object scale range. |
| `Waldo_ObjectScaling_AllowClientRequests` | Permits validated non-server scale requests. |
| `Logi_SupplyBoxClass` | JIP-published logistics supply crate class. |
| `Logi_MedicalBoxClass` | JIP-published medical crate class; ACE crate when ACE Medical exists. |

## `environmentConfig.sqf` — shared

| Setting | Purpose / units |
|---|---|
| `Waldo_Hazard_Enable` | Master hazardous-environment opt-in. |
| `Waldo_Hazard_Interval` | Local exposure update interval in seconds. |
| `Waldo_Hazard_ShowStatus` | Shows the live hazard status element. |
| `Waldo_Hazard_NotifyTransitions` | Announces entering/leaving a zone. |
| `Waldo_Hazard_NotificationDuration` | Transition-card duration in seconds. |
| `Waldo_Hazard_Presets` | Named profiles. Each profile may set `type`, `label`, `rate`, `decay`, protection/vehicle modifiers, `damageType`, staged `[exposure, damage]` thresholds, stage messages and `fatalExposure`. |
| `Waldo_TreeFelling_Enable` | Master tree-felling opt-in. |
| `Waldo_TreeFelling_Range` | Maximum axe interaction range. |
| `Waldo_TreeFelling_BaseHits` | Base strikes required. |
| `Waldo_TreeFelling_HeightFactor` | Extra strikes derived from tree height. |
| `Waldo_TreeFelling_HitCooldown` | Minimum time between accepted strikes. |
| `Waldo_TreeFelling_WeaponPatterns` | Case-insensitive classname fragments treated as axes. |
| `Waldo_TreeFelling_FallenClasses` | General replacement log classes. |
| `Waldo_TreeFelling_FallenClassesSmall` / `Medium` / `Large` | Size-specific replacement pools. |
| `Waldo_TreeFelling_SizeThresholds` | Height boundaries separating size pools. |
| `Waldo_TreeFelling_FallenRandomDirection` | Randomises fallen-object direction. |
| `Waldo_TreeFelling_DirectionMode` | Direction selection policy. |
| `Waldo_TreeFelling_ClearBushes` | Removes nearby bushes after a successful fell. |
| `Waldo_TreeFelling_BushRadius` | Bush-clearance radius. |
| `Waldo_TreeFelling_ToolEfficiency` | Per-tool hit-efficiency overrides. |
| `Waldo_TreeFelling_ProtectedAreas` | Areas where felling is disallowed. |
| `Waldo_TreeFelling_Yields` | Optional reward/resource definitions. |
| `Waldo_TreeFelling_RegrowSeconds` | Regrowth delay; negative disables regrowth. |
| `Waldo_Breaching_Enable` | Master explosive-breaching opt-in. |
| `Waldo_Breaching_Profiles` | Breachable classes, thresholds and replacement behavior. |
| `Waldo_Breaching_ExplosiveStrengths` | Explosive-ammo class to breaching strength map. |

## `electronicWarfareConfig.sqf` — server, JIP-published

| Setting | Purpose / units |
|---|---|
| `Waldo_Jamming_Enable` | Master electronic-warfare opt-in. |
| `Waldo_Jamming_Notify` | Shows client interference feedback. |
| `Waldo_Jamming_LOS` | Applies line-of-sight attenuation. |
| `Waldo_Jamming_BurnThrough` | Allows sufficiently close radios to overcome interference. |
| `Waldo_Jamming_BurnThroughRef` | Reference distance for burn-through calculations. |
| `Waldo_Jamming_Curve` | Signal-loss curve identifier. |
| `Waldo_Jamming_Destructible` | Allows jammer destruction to stop its effect. |
| `Waldo_Jamming_GmOverlay` | Enables curator diagnostics overlay. |
| `Waldo_Jamming_ScanRange` | Maximum RDF scan range in metres. |
| `Waldo_Jamming_ScanBearingArc` | Total deliberately vague bearing sector in degrees. |
| `Waldo_Jamming_ScanDistanceBands` | Absolute distance thresholds for nearby/medium/distant wording. |
| `Waldo_Jamming_AllowPlayerToggle` | Enables appropriate activate/deactivate interactions. |
| `Waldo_Jamming_DisableChallenge` | Requires the interaction-equipment challenge to disable. |
| `Waldo_Jamming_DisableChallengeId` | Challenge identifier. |
| `Waldo_Jamming_DisableDifficulty` | Challenge difficulty. |
| `Waldo_Jamming_DisableEngineerOnly` | Restricts disable/repair to engineers. |
| `Waldo_Jamming_DisableResult` | Successful challenge state transition. |

## `missionSystemsConfig.sqf`

| Setting | Purpose / units |
|---|---|
| `Waldo_Rally_Enable` | Master squad-rally opt-in. |
| `Waldo_Rally_ObjectClass` | Deployed rally object class. |
| `Waldo_Rally_Duration` | Rally lifetime in seconds. |
| `Waldo_Rally_DeploymentTime` | Placement progress duration. |
| `Waldo_Rally_Cooldown` | Delay before another rally can be placed. |
| `Waldo_Rally_EnemyExclusionRadius` | Hostile exclusion radius. |
| `Waldo_Rally_MinimumGroupMembers` | Minimum current group size. |
| `Waldo_Rally_PlacementDistance` | Distance in front of the leader used for placement. |
| `Waldo_Rally_MaximumSlope` | Maximum permitted terrain slope. |
| `Waldo_Rally_RespawnClearance` | Required open space around the respawn position. |
| `Waldo_Rally_RespawnSearchDistance` | Maximum safe-position search radius. |
| `Waldo_Rally_AllowRegroup` | Allows the configured regroup behavior. |
| `Waldo_Economy_Enable` | Enables the optional WMP economy. |
| `Waldo_MiniGames_Enable` | Enables interaction-equipment challenges. |
| `Waldo_CorpseTraps_Enable` | Enables configured corpse-trap handling. |
| `ACE_maxWeightDrag` / `ACE_maxWeightCarry` | ACE logistics weight limits. |
| `ace_hearing_disableVolumeUpdate` | Disables ACE's automatic hearing-volume adjustment. |
| `Waldo_RunDiagnostics` | Runs the server startup diagnostics report. |
| `Waldo_SafeStart_Confine` | Restricts players to the safestart area. |
| `Waldo_SafeStart_Radius` | Fallback safestart radius in metres. |
| `Waldo_SafeStart_ZoneMarker` | Optional marker defining the safestart area. |
| `Waldo_SafeStart_AutoStart` | Starts safestart automatically during server initialization. |

## Adding or changing settings

Keep configuration files pure data: do not add `spawn`, `execVM`, event handlers, waits or world
mutation. Put the setting in the semantic feature file, document it here and preserve its required
scope. Use `publish = true` only for server-owned values that clients or JIP genuinely consume.
Feature activation and live-setting changes remain in the existing locality-aware scripts/modules.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
