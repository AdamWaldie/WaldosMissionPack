# Feature Configuration Files

> **Use this page when:** you need to find, understand, or safely change a WMP feature setting.

All mission-maker feature settings live under `MissionConfig`. Each file returns pure data in the
same manner as `acreConfig.sqf`; lifecycle code applies only the correct `SHARED`, `SERVER`, or
`PLAYER_LOCAL` section. Existing values win. A server entry marked for publication is broadcast
once by `initServer.sqf` and remains available to JIP clients. The loader never promotes a local
setting into authoritative state.

This page is the variable reference. If you are asking **whether the setting starts the feature**,
**what else must be placed/registered**, or **which init file receives a custom call**, begin with
[Feature Setup and Activation](Feature-Setup-and-Activation). A config file never spawns or
registers world content by itself.

## Reading a setting when you do not know SQF

For a line such as `["Waldo_AIRebalance_Mode", "DAY"]`, keep the quoted setting name on the left and
change only the value on the right. Text stays inside quotation marks. `true` means enabled,
`false` means disabled, and `[]` is an empty list whose exact meaning is stated by the nearby
comment. Keep brackets and commas intact. Comments beginning with `//` are guidance, not code.

Complex settings are expanded vertically in the config file. Their fields are numbered from `0`
and explained beside the exact value being edited. Start with the supplied example, duplicate the
whole block where instructed, and change one clearly labelled field at a time.

The in-code baseline is deliberately repetitive: `SETTING`, `WHAT IT CHANGES`, `VALUES`, then a
copyable `EXAMPLE/RESULT`. This is preferable to expecting a new mission maker to decode a compact
schema reference.

Each `SETTING` also identifies its customisation level. `VALUES` includes the data type, units,
allowed range or IDs and shipped default. `EXAMPLE/RESULT` explains an alternative value in terms of
what the mission maker or players will observe. For positional arrays, each zero-based field is
explained beside the row. The compact wiki tables are navigation aids; they do not replace these
setting-level explanations in the file.

Callable scripts use the same beginner-first, detail-preserving rule. Their in-file headers retain
all numbered arguments and nested shapes, plus return value, locality/authority, current callers,
copyable call and expected result. See [Coding and Documentation Standards](Coding-Standards).

## Before changing a value

Read the header of that config file in this order:

1. **ACTIVATION MODEL** - automatic, enable plus registration, call-driven, or mixed.
2. **EDIT FOR A NORMAL MISSION** - the values expected to change between operations.
3. **LEAVE ALONE UNLESS EXTENDING/TESTING** - supported internals that require focused retesting.
4. **CUSTOM CALLS** - whether a pre-planned object/system needs initServer.sqf or object setup.

The exact shipped defaults are visible beside each variable in the config files. The tables below
define purpose, units and constrained values. Empty arrays/maps mean unrestricted or no overrides
unless the feature guide states otherwise.

Every config also contains a `HOW TO READ THE DATA BELOW` section. That is the local contract for
row order, server publication, positional arrays and nested HashMaps. Inline comments state the
type, units and practical consequence beside the actual default, so this wiki is a navigation and
reference layer rather than required to decode the source file.

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
| `acreConfig.sqf` | Enablement, named displays, nets, per-occurrence group/player/role assignments, ear placement and Babel languages | Strict validation and shipped capability profiles |
| `persistenceConfig.sqf` | Enablement, saved data categories and database/campaign name | Save cadence and custom-variable serialization list |
| `interfaceConfig.sqf` | Theme, treatment recipients/content, emergency-dismount policy and PID eligibility/content | Queue/reflow limits, tactical knowledge threshold, placement geometry and Draw3D scale/offset internals |
| `aiConfig.sqf` | AI profile/mode, application population and inclusion/exclusion filters | Skill variance and helicopter landing controller values |
| `airOperationsConfig.sqf` | Feature enablement, aircraft/chute/boarding pools, AA assets and jump envelopes | Monitor cadence, service thresholds and server maximum bounds |
| `logisticsConfig.sqf` | Resupply content/balance, recovery packages/markers, scale range and crate classes | Scan cadence, safe-placement geometry, client scaling authority and dependency fallback |
| `environmentConfig.sqf` | Hazard profiles, tree tools/replacements/protected areas and breaching content | Tick rates, damage cadence, tree geometry/cooldowns and regrowth scheduler values |
| `electronicWarfareConfig.sqf` | EW rules, player feedback/toggles and disable challenge | Signal curve/reference, RDF fuzz bands and diagnostics overlay |
| `missionSystemsConfig.sqf` | Rally rules, optional-system enablement, diagnostics and safestart contract | Safe-position geometry and global ACE weight/hearing overrides |
| `economyConfig.sqf` | Hand-authored economy catalogues and pre-planned economy world setup | Authority guard and setup-call ordering |

## Common option formats

- Sides: `WEST`, `EAST`, `GUER`/`INDEPENDENT`, and `CIV`/`CIVILIAN` as documented by the specific system.
- AI profiles: `MILITIA`, `LINE`, `VETERAN`, `ELITE`; mode `DAY` or `NIGHT`; apply mode `BOTH`, `EXISTING` or `NEW`.
- UI themes: `DEFAULT`, `WW2`, `VIETNAM`, `SCIFI`, `PARCHMENT`, `MINIMAL`.
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
| `enabled` | Enables the replacement ACRE lifecycle. |
| `strict` | Promotes explicit PRC-343 collisions from reported warnings to configuration errors. Structural errors are always rejected. |
| `prc343PresetPolicy` | `FULL_RANGE` keeps all sixteen blocks on every side; `SIDE_ISOLATED` trades combat-side capacity for cross-side PRC-343 frequency separation. It does not change the presets used by other radios. |
| `namedDisplays` | Enables supported physical radio channel labels. |
| `notifyAssignmentProblems` | Shows a local WMP warning for failed manual/QA assignment without intruding on initial loading or normal respawn. |
| `additionalRadioProfiles` | Advanced-only extensions for tested third-party carried radios; built-in ACRE capabilities are code-owned. |
| `radioOverrides` | Side-scoped UID, editor-variable or role `MERGE`/`REPLACE` assignment rules. |
| `sides` | Side preset, radio-specific net tunings, fallback group mappings and optional same-type occurrence templates. |
| `babel` | Language definitions, side defaults, speaking language, overrides and unit-follow behavior. |

The file includes working channel-radio, local-radio and common-frequency examples. A net declares
only the radio types that can use it, so BF-888S or SEM52SL capacity never limits PRC-152/117F nets.
Explicit group rows apply only when the player actually carries that radio occurrence.

Radio channel/ear state is not embedded in a player's inventory classname. Normal Save Respawn
Loadout filters transient `_ID_n` classes to base radio classes and stores supported player-level
state separately by base class plus same-type occurrence. It restores that snapshot after fresh
ACRE IDs exist. `Waldo_Persistence_SaveRadios = true` persists the same state across sessions.
Neither path polls or continually retunes radios during play, and PTT defaults remain player-owned.

See [ACRE2 Babel Configuration](ACRE2-Babel-Configuration),
[PRC-343 Automatic Setup](ACRE-2-Squad-Level-Radios-AN-PRC%E2%80%90343-Automatic-Setup), and
[Long-Range Radio Presetting](ACRE-2-Long-Range-Radio-Presetting).

## `persistenceConfig.sqf` — shared

See [Persistence](Persistence) for setup steps, registering world objects, and the Zeus modules.

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
| `Waldo_Persistence_DatabaseName` | Human-chosen name for this mission or campaign's save collection. |
| `Waldo_Persistence_Scope` | `"MISSION"` isolates player and object records by database name + mission + terrain. `"CAMPAIGN"` deliberately shares records between missions with the same database name. |
| `Waldo_Persistence_DefaultCustomVariables` | Object-variable names copied for registered persistent objects. |

Normal standalone mission example:

```sqf
["Waldo_Persistence_DatabaseName", "Operation_Nightjar"],
["Waldo_Persistence_Scope", "MISSION"]
```

The server also binds each record to the requesting Steam UID and rejects stored identity that does
not match. Use `CAMPAIGN` only when cross-mission player progression is intentional.

## `interfaceConfig.sqf` — shared

| Setting | Purpose / valid values |
|---|---|
| `Waldo_UI_Theme` | Global visual theme: `DEFAULT`, `WW2`, `VIETNAM`, `SCIFI`, `PARCHMENT`, `MINIMAL`, or registered custom ID. |
| `Waldo_UI_CustomThemes` | Custom theme definitions keyed by theme ID. |
| `Waldo_UI_ThemeOverrides` | Mission-wide component-level theme overrides. |

## `interfaceConfig.sqf` — player local

### Notification flow

| Setting | Purpose / units |
|---|---|
| `Waldo_UiNotification_MaximumQueued` | Maximum pending notification channels before coalescing/eviction. |
| `Waldo_UiNotification_QueueLifetime` | Seconds a pending notification may wait before expiry. |
| `Waldo_UiNotification_MinimumDuration` | Shortest lifetime in seconds for a concise timed card. |
| `Waldo_UiNotification_CharactersPerSecond` | Reading-speed divisor that scales longer text up to each call's existing maximum. |
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

### WMP HUD

| Setting | Purpose / units |
|---|---|
| `Waldo_WmpHud_Enable` | Installs the local WMP HUD framework. |
| `Waldo_WmpHud_SystemName` | Player-facing system name used by HUD feedback. |
| `Waldo_WmpHud_AccessibilityUIDs` | Steam UID strings that qualify without campaign equipment. |
| `Waldo_WmpHud_ExcludedUIDs` | Steam UID strings denied through every route. |
| `Waldo_WmpHud_AllowEveryone` | Explicitly grants the HUD to every player. |
| `Waldo_WmpHud_Headgear` | Headgear classnames granting high-tech campaign access. |
| `Waldo_WmpHud_Facewear` | Glasses and facewear classnames granting high-tech campaign access. |
| `Waldo_WmpHud_NVGs` | NVG and HMD classnames granting high-tech campaign access. |
| `Waldo_WmpHud_DefaultVisible` | Initial visibility for equipment-qualified users. |
| `Waldo_WmpHud_AccessibilityDefaultVisible` | Initial visibility for accessibility UIDs. |
| `Waldo_WmpHud_AllowToggle` | Exposes the WMP Interface self-interaction toggle. |
| `Waldo_WmpHud_Icon` | Texture path used for the friendly marker. |
| `Waldo_WmpHud_Colour` | Optional RGBA override; `[]` follows the colour-vision-aware theme. |
| `Waldo_WmpHud_IconRange`, `NameRange` | Separate maximum friendly icon/name ranges in metres. |
| `Waldo_WmpHud_RequireLOS` | Requires local view line of sight. |
| `Waldo_WmpHud_IncludeAI` | Includes friendly AI. |
| `Waldo_WmpHud_IconScale`, `TextScale` | Base chevron and name sizes. |
| `Waldo_WmpHud_DistanceFade` | Fades presentation with distance. |
| `Waldo_WmpHud_GroupOnly` | Restricts the HUD to the player's group. |
| `Waldo_WmpHud_ShowIncapacitated` | Keeps identifiers visible on incapacitated friendlies. |
| `Waldo_WmpHud_ShowIcons` | Enables the friendly marker layer. |
| `Waldo_WmpHud_ShowNames` | Enables names inside the configured name range. |
| `Waldo_WmpHud_ShowVehicleCrew` | Permits identifiers for units inside vehicles. |
| `Waldo_WmpHud_Font`, `TextDistanceGrowth` | Advanced readable text styling and distance scaling. |
| `Waldo_WmpHud_TextMaximumScale` | Upper bound for name scaling at range. |
| `Waldo_WmpHud_TextHeadOffset` | Name height above the animated head anchor in metres. |
| `Waldo_WmpHud_IconHeadOffset` | Marker height above the animated head anchor in metres. |
| `Waldo_WmpHud_OutlineScale` | Contrast outline scale relative to the name. |
| `Waldo_WmpHud_OutlineColour` | RGBA contrast-outline colour. |

## `aiConfig.sqf` — shared

| Setting | Purpose / units |
|---|---|
| `Waldo_AIRebalance_Enable` | Enables WMP skill handling for eligible AI. |
| `Waldo_AIRebalance_Profile` | Default named profile: `MILITIA`, `LINE`, `VETERAN` or `ELITE`. |
| `Waldo_AIRebalance_Mode` | Lighting-condition skill variant: `DAY` or `NIGHT`. |
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
| `Waldo_ImprovedHelicopterLanding_MinimumApproachSpeed` | Minimum approach-entry speed in km/h outside the close descent envelope. |
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
| `Waldo_ImprovedHelicopterLanding_TouchdownRadius` | Acceptable horizontal touchdown error in metres. Default `5`; increasing it makes touchdown detection easier but less exact. |
| `Waldo_ImprovedHelicopterLanding_FinalCommitDistance` | Distance inside which the final landing point is committed. |
| `Waldo_ImprovedHelicopterLanding_ControlInterval` | Local control-loop interval in seconds. |
| `Waldo_ImprovedHelicopterLanding_TouchdownHoldSeconds` | Seconds WMP holds the AI in its landed state before releasing control. Default `20` prevents the vanilla AI immediately taking off again. |

## `airOperationsConfig.sqf`

### Shared gunship and paradrop settings

| Setting | Purpose / units |
|---|---|
| `Waldo_Gunship_Enable` | Master permission for airborne gunship support. Default `true`; it does not spawn an aircraft by itself. |
| `Waldo_Gunship_DefaultAltitude` | Default orbit altitude in metres when a request does not override it. |
| `Waldo_Gunship_MaximumAltitude` | Server-accepted upper orbit altitude in metres. |
| `Waldo_Gunship_DefaultRadius` | Default orbit radius in metres when a request does not override it. |
| `Waldo_Gunship_MaximumRadius` | Server-accepted upper orbit radius in metres. |
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
| `Waldo_Gunship_FactionAircraftPools` | Optional faction-specific aircraft overrides. Beginners should leave this empty; use it only to narrow a named faction beyond the side pool. |
| `Waldo_Paradrop_AircraftClasses` | Aircraft offered by paradrop selectors. |
| `Waldo_Paradrop_StaticChuteClasses` | Static-line parachute classes. |
| `Waldo_Paradrop_HaloBackpackClasses` | Steerable/HALO parachute backpack classes. |
| `Waldo_Paradrop_BoardingPointClasses` | Movable boarding-point object choices. |
| `Waldo_Paradrop_ChuteClasses` | Compatibility alias populated from static chutes when undefined. |
| `Waldo_Paradrop_DefaultStaticRouteAltitude` | Initial Static-Line route-altitude value, in metres AGL, shown by the ZEN module and used when the direct setup call omits altitude. Shipped value `300`, matching the full example composition. |
| `Waldo_Paradrop_DefaultStaticRouteSpeed` | Initial Static-Line route-speed value in km/h. Shipped value `300`; keep it at or below `WALDO_STATIC_MAXSPEED`. |
| `Waldo_Paradrop_DefaultHaloRouteAltitude` | Initial HALO route-altitude value in metres AGL. Shipped value `1200`; keep it at or above `WALDO_PARA_HALOALTITUDE`. |
| `Waldo_Paradrop_DefaultHaloRouteSpeed` | Initial HALO route-speed value in km/h. Shipped value `250`; HALO has no static-line speed ceiling unless the operation enables both jump methods. |
| `Waldo_Paradrop_DefaultAircraftInvincible` | Default damage protection for quick/scripted/ZEN paradrop aircraft. Shipped `false`; individual calls and the ZEN checkbox may override it. Protection follows aircraft locality and does not block scripted `setDamage`/`setHit`. |

### Server Dynamic AA and jump limits

| Setting | Purpose / units |
|---|---|
| `Waldo_DynamicAA_DefaultDetectionInterval` | Seconds between target detection passes. |
| `Waldo_DynamicAA_MaximumRadius` | Maximum accepted system radius in metres. |
| `Waldo_DynamicAA_MaximumAltitude` | Maximum accepted detection altitude. |
| `Waldo_DynamicAA_MaximumFighters` | Maximum fighters created by one system. |
| `Waldo_DynamicAA_MaxSlopeDegrees` | Steepest terrain (degrees) a component may be placed on; rejected the same as a nearby tree/rock/building. |
| `Waldo_DynamicAA_SideAssetPools` | Shared fallback radar, static, mobile and fighter content pools by operational side. |
| `Waldo_DynamicAA_FactionAssetPools` | Shared faction/content profiles; selection is independent of operational side. |

These are catalogue and safety settings, not the floor/ceiling for one individual system. A specific
system supplies its `radius`, `engagementRadius`, `minimumAltitude`, `maximumAltitude` and
`altitudeMode` in the Dynamic AA creation call or ZEN dialog. Both radii are horizontal map distances;
the altitude band is checked separately. See [Dynamic Anti-Air](Dynamic-Anti-Air) for a copyable
first system and a boundary-by-boundary test.

### Server paradrop safety envelope

These values are the mission-wide safe defaults used by direct calls and ZEN. They do not create an
aircraft or drop zone. Start with the shipped values; change them only when your chosen aircraft and
parachute have been tested at the replacement altitude and speed.

| Setting | Purpose / units |
|---|---|
| `WALDO_STATIC_MINALTITUDE` | Lowest valid static-line release altitude in metres. |
| `WALDO_STATIC_MAXALTITUDE` | Highest valid static-line release altitude; must exceed the minimum. |
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
| `Waldo_TransportServices_Enable` | Enables the inert shared transport framework; vehicles still require registration. |
| `Waldo_Transport_TravelTimeout` | Maximum seconds for one physical pickup, destination or RTB journey. |
| `Waldo_Transport_DefaultBoardingSeconds` | Pickup boarding window before automatic RTB. |
| `Waldo_Transport_DefaultDestinationDwell` | Seconds before optional `forceDisembark` asks remaining players to leave. Default `45`; this never permits RTB while a human remains aboard. |
| `Waldo_Transport_DestinationSettleSeconds` | Continuous seconds the vehicle must remain grounded and at/below the settled-speed limit before automatic RTB. Default `3`; beginners should leave this unchanged. |
| `Waldo_Transport_DestinationEmptyConfirmSeconds` | Continuous seconds every driver, commander, turret, FFV and cargo seat must remain human-empty before automatic RTB. Default `2`; this prevents a landing/exit timing race. |
| `Waldo_Transport_DestinationSettleSpeedKph` | Maximum total vehicle speed counted as safely settled at destination. Default `5 km/h`; beginners should leave this unchanged. |
| `Waldo_HeliTransport_DefaultAltitude` | Default AI helicopter transit height in metres. |
| `Waldo_HeliTransport_DefaultLzSearchRadius` | Maximum safe-LZ adjustment from the player's helicopter pickup/destination click. Default 500 metres. |
| `Waldo_HeliTransport_DefaultLzClearanceScale` | Multiplier applied to the helicopter's real model bounding box when validating an LZ. Default 1.5. |
| `Waldo_HeliTransport_DefaultSeparation` | Minimum spacing in metres between helicopter bases, active LZs and bulk pickup slots. Default 60. |
| `Waldo_GroundTransport_DefaultRoadSearchRadius` | Radius searched for a connected road around a ground-transport click. |
| `Waldo_GroundTransport_DefaultSeparation` | Minimum spacing in metres between ground-transport bases, active stops and bulk pickup slots. Default 18. |
| `Waldo_GroundTransport_DefaultSpeedLimit` | Default AI ground-transport speed cap in kilometres per hour. |
| `Waldo_Transport_DefaultPathRetrySeconds` | No-progress interval before a ground movement order is reissued. |
| `Waldo_Transport_DefaultPathRetryLimit` | Maximum automatic order retries during one ground journey. |
| `Waldo_Transport_MaxEffectiveDamage` | Damage fraction (0-1) at/above which a still-"alive" transport is written off the service pool the same as an outright loss. |
| `Waldo_ObjectScaling_Minimum` | Smallest positive object scale accepted by the server. |
| `Waldo_ObjectScaling_Maximum` | Largest object scale accepted by the server; must be at least the minimum. |
| `Waldo_ObjectScaling_AllowClientRequests` | Permits validated non-server scale requests. |
| `Logi_SupplyBoxClass` | JIP-published logistics supply crate class. |
| `Logi_MedicalBoxClass` | JIP-published medical crate class; ACE crate when ACE Medical exists. |

## `environmentConfig.sqf` — shared

| Setting | Purpose / units |
|---|---|
| `Waldo_Hazard_Enable` | Master hazardous-environment opt-in. |
| `Waldo_Hazard_Interval` | Local exposure update interval in seconds. |
| `Waldo_Hazard_ShowStatus` | Continuous exposure panel. Defaults on, updates in place and never consumes notification-card lanes. A profile may override it with `showStatus`. |
| `Waldo_Hazard_StatusGraceSeconds` | Seconds the exposure panel lingers per hazard type after the player leaves every zone of that type. Presence-based, like a Geiger counter - independent of the (deliberately slower) exposure value decaying to zero. |
| `Waldo_Hazard_NotifyTransitions` | Announces entering/leaving a zone. |
| `Waldo_Hazard_NotificationDuration` | Transition-card duration in seconds. |
| `Waldo_Hazard_DosimeterEnable` | Enables exposure-reading interactions. |
| `Waldo_Hazard_DosimeterRequireItem` | Requires a configured carried dosimeter item when true. |
| `Waldo_Hazard_DosimeterItems` | Item classnames accepted as dosimeters. |
| `Waldo_Hazard_Treatments` | Treatment rows: `[consumed item class, readable name, exposure reduction]`. |
| `Waldo_Hazard_TreatmentDuration` | ACE treatment progress duration in seconds. |
| `Waldo_Hazard_TreatmentMedicOnly` | Restricts exposure treatment to units with the Medic trait. |
| `Waldo_Hazard_Presets` | Named profiles. In addition to exposure/damage/protection, a profile may use `detectorItems`, `detectorObjects`, `detectorObjectRange`, `awarenessCondition`, `requireAwarenessForStatus` and `requireAwarenessForNotifications`. Awareness changes information only; danger still applies. Networked callbacks use missionNamespace function-name strings. |
| `Waldo_TreeFelling_Enable` | Master tree-felling opt-in. |
| `Waldo_TreeFelling_Range` | Maximum axe interaction range. |
| `Waldo_TreeFelling_BaseHits` | Base strikes required. |
| `Waldo_TreeFelling_HeightFactor` | Extra strikes derived from tree height. |
| `Waldo_TreeFelling_HitCooldown` | Minimum time between accepted strikes. |
| `Waldo_TreeFelling_WeaponPatterns` | Case-insensitive weapon-classname fragments treated as axes. Arma has no vanilla axe; add a fragment from the axe mod used by the mission. |
| `Waldo_TreeFelling_AllowedClasses` | Exact tree object classes accepted when their model path does not contain `tree`; normally leave empty. |
| `Waldo_TreeFelling_FallenClasses` | General replacement log classes. |
| `Waldo_TreeFelling_FallenClassesSmall` | Optional short-tree replacement pool; an empty list falls back to `FallenClasses`. |
| `Waldo_TreeFelling_FallenClassesMedium` | Optional medium-tree replacement pool; an empty list falls back to `FallenClasses`. |
| `Waldo_TreeFelling_FallenClassesLarge` | Optional tall-tree replacement pool; an empty list falls back to `FallenClasses`. |
| `Waldo_TreeFelling_SizeThresholds` | `[end of small, end of medium]` tree-height boundaries in metres. |
| `Waldo_TreeFelling_DirectionMode` | `RANDOM`, `STRIKE` (away from the player), or `ORIGINAL`. |
| `Waldo_TreeFelling_ClearBushes` | Removes nearby bushes after a successful fell. |
| `Waldo_TreeFelling_BushRadius` | Bush-clearance radius. |
| `Waldo_TreeFelling_ToolEfficiency` | Classname or classname-fragment multipliers: `1` normal, `2` double, `0.5` half. Exact matches win, otherwise the longest fragment wins. |
| `Waldo_TreeFelling_ProtectedAreas` | Existing marker/trigger/area definitions where felling is disallowed; marker names are the simplest option. |
| `Waldo_TreeFelling_Yields` | Optional `[CfgVehicles classname, count]` reward rows spawned per tree. |
| `Waldo_TreeFelling_RegrowSeconds` | Positive regrowth delay in seconds; `-1` or `0` disables regrowth. |
| `Waldo_Breaching_Enable` | Master ACE explosive-breaching opt-in. The shipped wall profile remains harmless while this is false. |
| `Waldo_Breaching_ShowNotifications` | Default false. Opt in only if successful breaches should notify the player who placed the charge. |
| `Waldo_Breaching_Profiles` | Target CfgVehicles classname to profile map. The shipped `Land_City2_8m_F` example is ready to test. Each profile explains radius, allowed CfgAmmo classes, required force, original-object handling and optional replacements inline. |
| `Waldo_Breaching_ExplosiveStrengths` | CfgAmmo classname to force per detonation. These are ammo classes such as `DemoCharge_Remote_Ammo`, not inventory magazine classes. |

Beginner breaching workflow: place `Land_City2_8m_F`, set `Waldo_Breaching_Enable` to `true`, and
detonate an ACE demo charge within 5 m. Copy the complete target/profile block only after that test
works. See [Explosive wall breaching](Optional-Feature-Systems#explosive-wall-breaching) for the
annotated profile and advanced replacement-row format.

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
| `Waldo_Jamming_DisableChallenge` | Default `true`: active jammers use **Disable Jammer** and the selected interaction challenge, preventing the ordinary toggle from bypassing it. |
| `Waldo_Jamming_DisableChallengeId` | Challenge identifier. |
| `Waldo_Jamming_DisableDifficulty` | Challenge difficulty. |
| `Waldo_Jamming_DisableEngineerOnly` | Default `false`: anyone may attempt the challenge. Set `true` to require ACE engineers. |
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
| `ACE_maxWeightDrag` | Maximum ACE draggable mass; the shipped value preserves permissive WMP logistics. |
| `ACE_maxWeightCarry` | Maximum ACE carryable mass; the shipped value preserves permissive WMP logistics. |
| `ace_hearing_disableVolumeUpdate` | Disables ACE's automatic hearing-volume adjustment. |
| `Waldo_RunDiagnostics` | Runs the server startup diagnostics report. |
| `Waldo_SafeStart_Confine` | Restricts players to the safestart area. |
| `Waldo_SafeStart_Radius` | Fallback safestart radius in metres. |
| `Waldo_SafeStart_ZoneMarker` | Optional marker defining the safestart area. |
| `Waldo_SafeStart_AutoStart` | `false` starts live while retaining Zeus controls; `true` begins the mission under Safestart protection. |

## `economyConfig.sqf`

This file is executable server-side mission-maker authoring rather than a pure setting HashMap.
`_useExample = false` keeps the demonstration inactive. Set it to `true` only in a disposable test,
then return it to `false` and copy the required rows into **YOUR ECONOMY**.

| Row or call | Fields, in order |
|---|---|
| Resource | `name`, HTML hex `colour`, `icon path`, `storage cap` (`-1` unlimited) |
| Research | `name`, `description`, `cost rows`, `requirements`, `time in seconds` |
| Building | research fields, advanced condition/callback fields, initially built flag, object class, optional produced resource/amount/interval |
| Purchase | `name`, `description`, `cost rows`, `requirements`, object class, `Ground`/`Air`/`Naval`, access ID |
| Resource zone | position, name, radius, deposit rows, side ID, production interval |
| Resource crate | position, `[resource name, amount]` content rows |
| Research centre | world position |
| Purchase drop | position, category, direction in degrees, access ID |

Each positional field and a working result are documented immediately above the active examples in
`MissionConfig\economyConfig.sqf`. Catalogue calls run once on server authority after the economy
runtime and any selected preset/import have been applied.

## Adding or changing settings

Keep configuration files pure data: do not add `spawn`, `execVM`, event handlers, waits or world
mutation. Put the setting in the semantic feature file, document it here and preserve its required
scope. Use `publish = true` only for server-owned values that clients or JIP genuinely consume.
Feature activation and live-setting changes remain in the existing locality-aware scripts/modules.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
