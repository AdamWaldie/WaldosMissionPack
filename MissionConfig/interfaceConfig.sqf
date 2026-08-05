/*
 * Author: WaldoTheWarfighter
 * Defines global visual-theme defaults and interface-local notification, treatment, tactical,
 * emergency-dismount, WMP HUD and accessibility presentation settings. It never opens displays or actions.
 *
 * Schema: SHARED entries run on every machine; PLAYER_LOCAL entries run only for hasInterface.
 * Each entry is [missionNamespace variable name, guarded default value].
 * Arguments: None.
 * Return Value: HASHMAP consumed by Waldo_fnc_LoadFeatureConfigs.
 *
 * Example: add a Steam UID to Waldo_WmpHud_AccessibilityUIDs so that person can always use the HUD.
 * Result: that player receives the WMP HUD in every campaign; everyone else needs configured gear.
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
 *
 * SETTING-BY-SETTING GUIDE - THEME AND NOTIFICATIONS:
 * - Waldo_UI_Theme (MISSION MAKER): DEFAULT, WW2, VIETNAM or SCIFI; affects WMP UI, not Arma/ACE menus.
 * - Waldo_UI_CustomThemes (ADVANCED): complete new theme definitions; leave empty unless all tokens are tested.
 * - Waldo_UI_ThemeOverrides (ADVANCED): partial token overrides for an existing theme ID.
 * - Waldo_UiNotification_MaximumQueued (ADVANCED): maximum pending cards; oldest excess entries are discarded.
 * - Waldo_UiNotification_QueueLifetime (ADVANCED): seconds a pending card may wait before expiring.
 * - Waldo_UiNotification_MaximumPerPlacement (ADVANCED): simultaneous visible lanes in one screen region.
 * - Waldo_UiNotification_ReflowDuration (ADVANCED): seconds used to slide remaining cards into closed gaps.
 * - Waldo_UiNotification_AllowPlacementOverflow (MISSION MAKER): true sends excess cards to fallback regions.
 * - Waldo_UiNotification_OverflowPlacements (MISSION MAKER): ordered fallback screen regions; TOP is reserved.
 * - Waldo_UI_PanelPlacements (MISSION MAKER): `[feature channel, placement, can stack]` routing rows.
 *
 * SETTING-BY-SETTING GUIDE - TREATMENT FEEDBACK:
 * - Waldo_TreatmentFeedback_Enable: installs local ACE medical-event feedback when true.
 * - Waldo_TreatmentFeedback_ShowStart: shows the treatment-begin event.
 * - Waldo_TreatmentFeedback_ShowSuccess: shows ACE's successful-completion event.
 * - Waldo_TreatmentFeedback_ShowFailure: shows interruption/failure events.
 * - Waldo_TreatmentFeedback_NotifyPatient: patient receives their local copy.
 * - Waldo_TreatmentFeedback_NotifyMedic: treatment giver receives a separate local copy.
 * - Waldo_TreatmentFeedback_ShowMedicName: includes the giver's name in patient-facing text.
 * - Waldo_TreatmentFeedback_ShowBodyPart: includes the translated treated-body-part label.
 * - Waldo_TreatmentFeedback_StartTitle: player-facing title for treatment beginning.
 * - Waldo_TreatmentFeedback_SuccessTitle: player-facing title for successful completion.
 * - Waldo_TreatmentFeedback_FailureTitle: player-facing title for interruption/failure.
 * - Waldo_TreatmentFeedback_Duration: seconds the resulting card remains after the event fires.
 * - Waldo_TreatmentFeedback_TreatmentNames: optional treatment classname -> readable label overrides.
 * - Waldo_TreatmentFeedback_BodyPartNames: ACE body-part ID -> readable label map.
 *
 * SETTING-BY-SETTING GUIDE - TACTICAL DISPLAY:
 * - Waldo_TacticalDisplay_AccessDistance: interaction range in metres around a registered whiteboard/map board.
 * - Waldo_TacticalDisplay_MaximumOpenDistance: display closes when the player moves beyond this range.
 * - Waldo_TacticalDisplay_MinimumKnowledge: Arma knowsAbout threshold 0-4; higher shows fewer contacts.
 *
 * SETTING-BY-SETTING GUIDE - EMERGENCY DISMOUNT:
 * - Waldo_EmergencyDismount_Enable: installs self-actions when true; eligible vehicles need simulation enabled.
 * - Waldo_EmergencyDismount_OnOverturn: permits extraction after the overturn delay.
 * - Waldo_EmergencyDismount_OnDestroyed: permits extraction from destroyed eligible vehicles.
 * - Waldo_EmergencyDismount_PreserveVelocity: keeps vehicle momentum after exit; false is safer.
 * - Waldo_EmergencyDismount_ProtectDuringExit: temporarily prevents relocation damage.
 * - Waldo_EmergencyDismount_ProtectionSeconds: duration of that temporary protection.
 * - Waldo_EmergencyDismount_ClearPositionRadius: safe-position search radius around the vehicle.
 * - Waldo_EmergencyDismount_RequireClearExit: true refuses when no safe point exists; false permits fallback.
 * - Waldo_EmergencyDismount_UseEject: advanced engine ejection rather than WMP safe relocation.
 * - Waldo_EmergencyDismount_RecoverUnconscious: permits relocation of unconscious occupants.
 * - Waldo_EmergencyDismount_MinimumOverturnSeconds: continuous overturn time required before use.
 * - Waldo_EmergencyDismount_DamageOnExit: damage fraction 0-1 applied after extraction.
 * - Waldo_EmergencyDismount_AllowedKinds: isKindOf roots accepted by the feature.
 * - Waldo_EmergencyDismount_VehicleProfiles: exact vehicle class -> per-class override HashMap.
 *
 * SETTING-BY-SETTING GUIDE - WMP HUD:
 * - Waldo_WmpHud_Enable: installs the local friendly-identification HUD when true.
 * - Waldo_WmpHud_SystemName: campaign-facing name used by its toggle notification (for example Auspex).
 * - Waldo_WmpHud_AccessibilityUIDs: Steam UIDs that always qualify without campaign equipment.
 * - Waldo_WmpHud_ExcludedUIDs: Steam UIDs that never qualify; exclusions override every route.
 * - Waldo_WmpHud_AllowEveryone: gives every player the HUD without equipment; normally leave false.
 * - Waldo_WmpHud_Headgear: headgear classnames that grant high-tech campaign access.
 * - Waldo_WmpHud_Facewear: glasses/facewear classnames that grant high-tech campaign access.
 * - Waldo_WmpHud_NVGs: NVG/HMD classnames that grant high-tech campaign access.
 * - Waldo_WmpHud_DefaultVisible: initial state for an equipment-qualified player.
 * - Waldo_WmpHud_AccessibilityDefaultVisible: initial state for an accessibility UID.
 * - Waldo_WmpHud_AllowToggle: exposes the WMP Interface self-action.
 * - Waldo_WmpHud_Icon: optional texture path for the friendly marker.
 * - Waldo_WmpHud_Colour: RGBA colour; [] follows the active colour-vision-aware UI theme.
 * - Waldo_WmpHud_IconRange: maximum friendly icon distance in metres.
 * - Waldo_WmpHud_NameRange: maximum friendly name distance in metres.
 * - Waldo_WmpHud_RequireLOS: hides identification through occluding geometry when true.
 * - Waldo_WmpHud_IncludeAI: includes friendly AI targets when true.
 * - Waldo_WmpHud_IconScale/TextScale: base Draw3D sizes.
 * - Waldo_WmpHud_DistanceFade: progressively reduces alpha with distance.
 * - Waldo_WmpHud_GroupOnly: restricts identification to the player's current group.
 * - Waldo_WmpHud_ShowIncapacitated: retains identifiers on incapacitated friendlies.
 * - Waldo_WmpHud_ShowIcons: draws the friendly marker layer.
 * - Waldo_WmpHud_ShowNames: draws names inside NameRange.
 * - Waldo_WmpHud_ShowVehicleCrew: permits identifiers for units inside vehicles.
 * - Waldo_WmpHud_Font: Arma font classname used for names.
 * - Waldo_WmpHud_TextDistanceGrowth: small scale increase per metre before the maximum clamp.
 * - Waldo_WmpHud_TextMaximumScale: largest allowed name scale at range.
 * - Waldo_WmpHud_TextHeadOffset: name height above the animated head position in metres.
 * - Waldo_WmpHud_IconHeadOffset: marker height above the animated head position in metres.
 * - Waldo_WmpHud_OutlineScale: contrast-outline size relative to the name.
 * - Waldo_WmpHud_OutlineColour: outline RGBA colour; defaults to near-black for clarity.
 *
 * PANEL EXAMPLE: `["RALLY_POINT", "BOTTOM_RIGHT", true]` routes rally cards to the bottom-right
 * stack. Keep continuous hazard and jammer overlays out of this list: their dedicated layouts are
 * deliberately deconflicted by the UI manager rather than queued as notification cards.
 */
createHashMapFromArray [
    ["featureFamilies", ["UI Themes", "Notification UI", "Treatment Feedback", "Tactical Display", "Emergency Dismount", "WMP HUD", "Accessibility"]],
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
            ["WMP_HUD", "TOP_RIGHT", true],               // WMP HUD messages in top-right lanes.
            ["EMERGENCY_DISMOUNT", "TOP_RIGHT", true],    // dismount messages share/reflow those lanes.
            ["DYNAMIC_AA", "BOTTOM_RIGHT", true],         // AA state at bottom-right.
            ["EXPLOSIVE_BREACH", "BOTTOM_RIGHT", true],   // breach feedback at bottom-right.
            ["TREE_FELLING", "BOTTOM_RIGHT", true],       // tree progress at bottom-right.
            ["FIELD_RESUPPLY", "BOTTOM_LEFT", true],      // resupply messages at bottom-left.
            ["VEHICLE_RECOVERY", "BOTTOM_LEFT", true],    // recovery messages at bottom-left.
            ["PERSISTENCE", "BOTTOM_LEFT", true],         // database messages at bottom-left.
            ["RESPAWN_LOADOUT", "BOTTOM_LEFT", true],     // loadout-save confirmation at bottom-left.
            ["RALLY_POINT", "BOTTOM_RIGHT", true],        // squad rally status at bottom-right.
            ["AIRBORNE_GUNSHIP", "BOTTOM_RIGHT", true],   // gunship status at bottom-right.
            ["HELI_TRANSPORT", "BOTTOM_RIGHT", true],     // helicopter transport status.
            ["GROUND_TRANSPORT", "BOTTOM_RIGHT", true]    // ground transport status.
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
        // MISSION MAKER: dual campaign-equipment and accessibility WMP HUD eligibility.
        ["Waldo_WmpHud_Enable", true],              // BOOL: install the local HUD framework.
        ["Waldo_WmpHud_SystemName", "WMP HUD"],    // STRING: campaign-facing system name, e.g. "Auspex".
        ["Waldo_WmpHud_AccessibilityUIDs", ["76561198094931408"]], // Steam UIDs that bypass equipment.
        ["Waldo_WmpHud_ExcludedUIDs", []],          // Steam UIDs denied even if equipment is worn.
        ["Waldo_WmpHud_AllowEveryone", false],      // true bypasses both UID and equipment checks.
        ["Waldo_WmpHud_Headgear", []],              // CfgWeapons headgear classnames granting HUD access.
        ["Waldo_WmpHud_Facewear", [                 // CfgGlasses facewear classnames granting HUD access.
            "FIG_CadianOGMaskFaceW", "FIG_CadianOGMaskFaceWGrey", "bio_1_fg", "bio_2_fg", "bio_3_fg", "bio_4_fg"
        ]],
        ["Waldo_WmpHud_NVGs", [                     // CfgWeapons NVG/HMD classnames granting HUD access.
            "FIG_SniperNVGs", "FIG_CadianAuspecs", "FIG_CadianAuspecsKasr", "FIG_CadianAuspecs150th",
            "FIG_CadianAuspecsKasr150th", "FIG_CadianAuspecsGrey", "FIG_CadianAuspecsKasrGrey",
            "ic_bionicEye", "TIOW_Bionic_Eye", "TIOW_Bionic_Eye_Green", "TIOW_Bionic_Eye_2",
            "TIOW_Bionic_Eye_2_Green", "TIOW_IG_NVG"
        ]],
        ["Waldo_WmpHud_DefaultVisible", true],       // initial state when qualified by equipment.
        ["Waldo_WmpHud_AccessibilityDefaultVisible", true], // initial state for accessibility UIDs.
        ["Waldo_WmpHud_AllowToggle", true],         // show the WMP Interface self-action.
        ["Waldo_WmpHud_Icon", "\a3\ui_f\data\igui\cfg\actions\getincommander_ca.paa"],
        ["Waldo_WmpHud_Colour", []],                // [] follows colour-vision-aware theme; otherwise RGBA 0-1.
        ["Waldo_WmpHud_IconRange", 300], ["Waldo_WmpHud_NameRange", 50],
        ["Waldo_WmpHud_RequireLOS", true], ["Waldo_WmpHud_IncludeAI", false],
        ["Waldo_WmpHud_IconScale", 0.8], ["Waldo_WmpHud_TextScale", 0.035],
        ["Waldo_WmpHud_DistanceFade", true], ["Waldo_WmpHud_GroupOnly", false],
        ["Waldo_WmpHud_ShowIncapacitated", true], ["Waldo_WmpHud_ShowIcons", true],
        ["Waldo_WmpHud_ShowNames", true], ["Waldo_WmpHud_ShowVehicleCrew", false],
        // ADVANCED TUNING: tested Draw3D typography/geometry; validate at close and maximum range.
        ["Waldo_WmpHud_Font", "PuristaBold"], ["Waldo_WmpHud_TextDistanceGrowth", 0.00025],
        ["Waldo_WmpHud_TextMaximumScale", 0.05], ["Waldo_WmpHud_TextHeadOffset", 0.30],
        ["Waldo_WmpHud_IconHeadOffset", 0.75], ["Waldo_WmpHud_OutlineScale", 1.12],
        ["Waldo_WmpHud_OutlineColour", [0.03, 0.03, 0.03, 1]]
    ]]
]
