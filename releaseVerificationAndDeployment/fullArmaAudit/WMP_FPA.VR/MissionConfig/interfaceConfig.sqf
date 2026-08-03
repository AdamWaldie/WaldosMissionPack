/*
 * Author: WaldoTheWarfighter
 * Defines global visual-theme defaults and interface-local notification, treatment, tactical,
 * emergency-dismount and accessibility presentation settings. It never opens displays or actions.
 *
 * Schema: SHARED entries run on every machine; PLAYER_LOCAL entries run only for hasInterface.
 * Each entry is [missionNamespace variable name, guarded default value].
 * Arguments: None.
 * Return Value: HASHMAP consumed by Waldo_fnc_LoadFeatureConfigs.
 *
 * Example: set Waldo_AccessibilityPID_AllowedUIDs to [] to permit every player to use PID.
 * Result: every interface client may use PID when the feature is enabled and locally toggled on.
 * Current callers: init.sqf (SHARED) and initPlayerLocal.sqf (PLAYER_LOCAL) through the loader.
 *
 * ACTIVATION MODEL: AUTOMATIC LOCAL UI, EXCEPT TACTICAL DISPLAY REGISTRATION.
 * Theme/notification policy is consumed automatically. Treatment feedback, emergency dismount and
 * accessibility install on each interface client when enabled. Tactical display values only tune a
 * display object; register a suitable whiteboard/map board separately by script or ZEN.
 *
 * EDIT FOR A NORMAL MISSION: theme, panel channel routing, treatment recipients/content, dismount
 * policy and accessibility eligibility/presentation. LEAVE ALONE UNLESS EXTENDING/TESTING: queue
 * limits, animation geometry, tactical knowledge bounds and Draw3D fine tuning. CUSTOM CALLS: put a
 * pre-planned Waldo_fnc_TacticalDisplayRegister call in initServer.sqf; do not start local UI systems
 * manually from init.sqf or duplicate their initPlayerLocal lifecycle.
 *
 * CUSTOMISATION GUIDE:
 * MISSION MAKER - UI_Theme (DEFAULT, WW2, VIETNAM or SCIFI), treatment-feedback policy,
 * emergency-dismount policy and accessibility eligibility/presentation are intended choices.
 * Panel placement names are TOP_RIGHT, CENTER, BOTTOM_LEFT, BOTTOM_CENTER and BOTTOM_RIGHT; TOP is
 * reserved for mission-flow banners. Panel entries are [channel, placement, allow stacking].
 * ADVANCED TUNING - notification queue/reflow limits, tactical knowledge threshold, dismount safety
 * geometry and PID font/scale/offset/outline values are tested UI or engine bounds. Keep shipped
 * values unless a specific resolution, vehicle family or accessibility test demonstrates a need.
 * CustomThemes and ThemeOverrides require the documented WMP theme HashMap schema.
 *
 * HOW TO READ THE DATA BELOW:
 * `shared` rows are `[variable, guarded default]` on every machine. `playerLocal` rows use the same
 * shape but exist only on clients with an interface. Do not publish player-local accessibility or
 * queue state. Panel rows are `[notification channel ID, screen placement, allow stacking]`.
 * `allow stacking` lets simultaneous messages from that channel share/reflow within the placement;
 * it does not bypass the global queue/coalescing limits.
 *
 * A custom theme is a HashMap keyed by a new theme ID and must provide the complete token set used
 * by Waldo_fnc_UiTheme. ThemeOverrides is a partial HashMap of existing token -> replacement value;
 * each replacement must keep the built-in token's type. RGBA colours are `[red,green,blue,alpha]`
 * values from 0 to 1. Prefer a built-in theme and overrides unless creating a fully tested style.
 * Theme token groups are: identity/text (`id`, `label`, `font`, `fontBold`), RGBA surfaces
 * (`shade`, `panel`, `panelAlt`, `header`, `button`, `buttonActive`, `edit`, `list`, `casing`), RGBA
 * semantics (`accent`, `accentActive`, `trim`, `text`, `muted`, `success`, `warning`, `danger`),
 * matching HTML hex colours (`textHex` through `dangerHex`), `railMode`, prefix/suffix strings and
 * `motif`. A complete custom theme must provide all of them.
 * VehicleProfiles is keyed by exact vehicle classname. Its HashMap may override the unprefixed
 * setting names read by the dismount controller, for example `OnOverturn`, `OnDestroyed`,
 * `PreserveVelocity`, `RequireClearExit`, `MinimumOverturnSeconds` and `UpThreshold`.
 */
createHashMapFromArray [
    ["featureFamilies", ["UI Themes", "Notification UI", "Treatment Feedback", "Tactical Display", "Emergency Dismount", "Accessibility"]],
    ["shared", [
        ["Waldo_UI_Theme", "DEFAULT"],              // MISSION MAKER: DEFAULT, WW2, VIETNAM or SCIFI.
        ["Waldo_UI_CustomThemes", createHashMap],    // ADVANCED: complete named custom-theme definitions.
        ["Waldo_UI_ThemeOverrides", createHashMap]   // ADVANCED: partial overrides keyed by theme ID.
    ]],
    ["playerLocal", [
        // ADVANCED TUNING: global notification queue and animation behavior.
        ["Waldo_UiNotification_MaximumQueued", 12], // COUNT: oldest pending messages are discarded beyond this bound.
        ["Waldo_UiNotification_QueueLifetime", 15], // SECONDS: pending message expires instead of playing much later.
        ["Waldo_UiNotification_MaximumPerPlacement", 3], // LANES: simultaneous panels at one screen placement.
        ["Waldo_UiNotification_ReflowDuration", 0.18], // SECONDS: animation when a stack closes its gap.
        ["Waldo_UiNotification_AllowPlacementOverflow", true], // BOOL: use next placement when all lanes are occupied.
        ["Waldo_UiNotification_OverflowPlacements", ["BOTTOM_RIGHT", "BOTTOM_LEFT", "CENTER"]], // ordered fallback placements.
        ["Waldo_UI_PanelPlacements", [              // MISSION MAKER: channel routing; avoid reserved TOP.
            // Every row is [feature message channel, screen area, may stack with simultaneous cards].
            ["TREATMENT_FEEDBACK", "BOTTOM_CENTER", true], // medical feedback at padded bottom-centre.
            ["ACCESSIBILITY_PID", "TOP_RIGHT", true],      // accessibility messages in top-right lanes.
            ["EMERGENCY_DISMOUNT", "TOP_RIGHT", true],    // dismount messages share/reflow those lanes.
            ["DYNAMIC_AA", "BOTTOM_RIGHT", true],         // AA state at bottom-right.
            ["EXPLOSIVE_BREACH", "BOTTOM_RIGHT", true],   // breach feedback at bottom-right.
            ["TREE_FELLING", "BOTTOM_RIGHT", true],       // tree progress at bottom-right.
            ["FIELD_RESUPPLY", "BOTTOM_LEFT", true],      // resupply messages at bottom-left.
            ["VEHICLE_RECOVERY", "BOTTOM_LEFT", true],    // recovery messages at bottom-left.
            ["PERSISTENCE", "BOTTOM_LEFT", true],         // database messages at bottom-left.
            ["RESPAWN_LOADOUT", "BOTTOM_LEFT", true],     // loadout-save confirmation at bottom-left.
            ["RALLY_POINT", "BOTTOM_RIGHT", true],        // squad rally status at bottom-right.
            ["AIRBORNE_GUNSHIP", "BOTTOM_RIGHT", true]    // gunship status at bottom-right.
        ]],
        // MISSION MAKER: ACE treatment feedback content and recipients.
        ["Waldo_TreatmentFeedback_Enable", false], // BOOL: install ACE treatment event feedback locally.
        ["Waldo_TreatmentFeedback_ShowStart", true], // BOOL: emit when treatment begins.
        ["Waldo_TreatmentFeedback_ShowSuccess", true], // BOOL: emit only on ACE's successful completion event.
        ["Waldo_TreatmentFeedback_ShowFailure", true], // BOOL: emit on interruption/failure.
        ["Waldo_TreatmentFeedback_NotifyPatient", true], // BOOL: patient receives their local feedback copy.
        ["Waldo_TreatmentFeedback_NotifyMedic", false], // BOOL: treatment giver also receives a local copy.
        ["Waldo_TreatmentFeedback_ShowMedicName", true], // BOOL: include giver's display name in patient text.
        ["Waldo_TreatmentFeedback_ShowBodyPart", true], // BOOL: include translated body-part text.
        ["Waldo_TreatmentFeedback_StartTitle", "TREATMENT STARTED"], // STRING: localised/custom title text.
        ["Waldo_TreatmentFeedback_SuccessTitle", "TREATMENT COMPLETE"], // STRING: localised/custom title text.
        ["Waldo_TreatmentFeedback_FailureTitle", "TREATMENT FAILED"], // STRING: localised/custom title text.
        ["Waldo_TreatmentFeedback_Duration", 3],     // Seconds after the event, not action duration.
        ["Waldo_TreatmentFeedback_TreatmentNames", createHashMap], // Treatment classname to display-name overrides.
        ["Waldo_TreatmentFeedback_BodyPartNames", createHashMapFromArray [ // ACE body-part ID -> player-facing label.
            ["head", "Head"], ["body", "Torso"], ["leftarm", "Left arm"], ["rightarm", "Right arm"],
            ["leftleg", "Left leg"], ["rightleg", "Right leg"]
        ]],
        // MISSION MAKER distances; ADVANCED knowledge threshold (Arma knowsAbout scale 0-4).
        ["Waldo_TacticalDisplay_AccessDistance", 4], // METRES: distance at which display interaction appears.
        ["Waldo_TacticalDisplay_MaximumOpenDistance", 8], // METRES: UI closes beyond this distance.
        ["Waldo_TacticalDisplay_MinimumKnowledge", 1.5], // knowsAbout 0-4: contacts below are omitted.
        // MISSION MAKER: when and for which vehicle families emergency extraction is allowed.
        ["Waldo_EmergencyDismount_Enable", false], // BOOL: install self-actions; vehicles need simulation for overturn state.
        ["Waldo_EmergencyDismount_OnOverturn", true], // BOOL: allow extraction after sustained overturn.
        ["Waldo_EmergencyDismount_OnDestroyed", true], // BOOL: allow extraction from destroyed eligible vehicle.
        ["Waldo_EmergencyDismount_PreserveVelocity", true], // ADVANCED: retains momentum; false is safer but less physical.
        ["Waldo_EmergencyDismount_ProtectDuringExit", true], // BOOL: temporary damage protection during relocation.
        ["Waldo_EmergencyDismount_ProtectionSeconds", 2], // SECONDS: duration of temporary protection.
        ["Waldo_EmergencyDismount_ClearPositionRadius", 6], // METRES: safe-position search around vehicle.
        ["Waldo_EmergencyDismount_RequireClearExit", false], // BOOL: refuse rather than use fallback when no clear point exists.
        ["Waldo_EmergencyDismount_UseEject", false], // ADVANCED: true uses engine ejection rather than safe move-out.
        ["Waldo_EmergencyDismount_RecoverUnconscious", false], // BOOL: permit script to move unconscious occupants.
        ["Waldo_EmergencyDismount_MinimumOverturnSeconds", 1], // SECONDS: overturn must persist before action enables.
        ["Waldo_EmergencyDismount_DamageOnExit", 0], // Damage fraction 0-1.
        ["Waldo_EmergencyDismount_AllowedKinds", ["LandVehicle", "Ship"]], // isKindOf roots.
        ["Waldo_EmergencyDismount_VehicleProfiles", createHashMap], // ADVANCED per-class safety overrides.
        // MISSION MAKER: PID eligibility and visible information.
        ["Waldo_AccessibilityPID_Enable", true],    // BOOL: makes PID available to eligible local players.
        ["Waldo_AccessibilityPID_AllowedUIDs", ["76561198094931408"]], // Steam UID strings; [] allows all players.
        ["Waldo_AccessibilityPID_DefaultVisible", true], // BOOL: initial state for an eligible player.
        ["Waldo_AccessibilityPID_AllowToggle", true], // BOOL: show Accessibility self-action to change visibility.
        ["Waldo_AccessibilityPID_IconRange", 300],   // METRES: maximum friendly chevron range.
        ["Waldo_AccessibilityPID_NameRange", 50],   // METRES: maximum name/role text range.
        ["Waldo_AccessibilityPID_RequireLOS", true], // BOOL: hide identifiers through occluding geometry.
        ["Waldo_AccessibilityPID_IncludeAI", false], // BOOL: include friendly AI as PID targets.
        ["Waldo_AccessibilityPID_IconScale", 0.8],   // DrawIcon3D scale multiplier.
        ["Waldo_AccessibilityPID_TextScale", 0.035], // close-range DrawIcon3D text scale.
        ["Waldo_AccessibilityPID_DistanceFade", true], // BOOL: progressively reduce alpha with distance.
        ["Waldo_AccessibilityPID_GroupOnly", false], // BOOL: restrict targets to player's group rather than side.
        ["Waldo_AccessibilityPID_ShowIncapacitated", true], // BOOL: retain PID on incapacitated friendlies.
        ["Waldo_AccessibilityPID_ShowIcons", true], // BOOL: draw the high-clarity chevron/icon layer.
        ["Waldo_AccessibilityPID_ShowNames", true], // BOOL: draw name/role text within NameRange.
        ["Waldo_AccessibilityPID_ShowVehicleCrew", false], // BOOL: draw identifiers for units currently in vehicles.
        // ADVANCED TUNING: tested Draw3D typography/geometry; validate at close and maximum range.
        ["Waldo_AccessibilityPID_Font", "PuristaBold"], // Arma font class used for maximum legibility.
        ["Waldo_AccessibilityPID_TextDistanceGrowth", 0.00025], // scale added per metre before MaximumScale clamp.
        ["Waldo_AccessibilityPID_TextMaximumScale", 0.05], // upper Draw3D text-scale clamp at range.
        ["Waldo_AccessibilityPID_TextHeadOffset", 0.30], // METRES above head selection for text baseline.
        ["Waldo_AccessibilityPID_IconHeadOffset", 0.75], // METRES above head selection for chevron/icon centre.
        ["Waldo_AccessibilityPID_OutlineScale", 1.12], // shadow/outline size relative to foreground text.
        ["Waldo_AccessibilityPID_OutlineColour", [0.03, 0.03, 0.03, 1]] // RGBA 0-1 contrast outline.
    ]]
]
