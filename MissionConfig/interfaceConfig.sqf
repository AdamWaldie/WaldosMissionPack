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
 * Current callers: init.sqf (SHARED) and initPlayerLocal.sqf (PLAYER_LOCAL) through the loader.
 */
createHashMapFromArray [
    ["featureFamilies", ["UI Themes", "Notification UI", "Treatment Feedback", "Tactical Display", "Emergency Dismount", "Accessibility"]],
    ["shared", [
        ["Waldo_UI_Theme", "DEFAULT"],
        ["Waldo_UI_CustomThemes", createHashMap],
        ["Waldo_UI_ThemeOverrides", createHashMap]
    ]],
    ["playerLocal", [
        ["Waldo_UiNotification_MaximumQueued", 12],
        ["Waldo_UiNotification_QueueLifetime", 15],
        ["Waldo_UiNotification_MaximumPerPlacement", 3],
        ["Waldo_UiNotification_ReflowDuration", 0.18],
        ["Waldo_UiNotification_AllowPlacementOverflow", true],
        ["Waldo_UiNotification_OverflowPlacements", ["BOTTOM_RIGHT", "BOTTOM_LEFT", "CENTER"]],
        ["Waldo_UI_PanelPlacements", [
            ["TREATMENT_FEEDBACK", "BOTTOM_CENTER", true],
            ["ACCESSIBILITY_PID", "TOP_RIGHT", true],
            ["EMERGENCY_DISMOUNT", "TOP_RIGHT", true],
            ["DYNAMIC_AA", "BOTTOM_RIGHT", true],
            ["EXPLOSIVE_BREACH", "BOTTOM_RIGHT", true],
            ["TREE_FELLING", "BOTTOM_RIGHT", true],
            ["FIELD_RESUPPLY", "BOTTOM_LEFT", true],
            ["VEHICLE_RECOVERY", "BOTTOM_LEFT", true],
            ["PERSISTENCE", "BOTTOM_LEFT", true],
            ["RESPAWN_LOADOUT", "BOTTOM_LEFT", true],
            ["RALLY_POINT", "BOTTOM_RIGHT", true],
            ["AIRBORNE_GUNSHIP", "BOTTOM_RIGHT", true]
        ]],
        ["Waldo_TreatmentFeedback_Enable", false],
        ["Waldo_TreatmentFeedback_ShowStart", true],
        ["Waldo_TreatmentFeedback_ShowSuccess", true],
        ["Waldo_TreatmentFeedback_ShowFailure", true],
        ["Waldo_TreatmentFeedback_NotifyPatient", true],
        ["Waldo_TreatmentFeedback_NotifyMedic", false],
        ["Waldo_TreatmentFeedback_ShowMedicName", true],
        ["Waldo_TreatmentFeedback_ShowBodyPart", true],
        ["Waldo_TreatmentFeedback_StartTitle", "TREATMENT STARTED"],
        ["Waldo_TreatmentFeedback_SuccessTitle", "TREATMENT COMPLETE"],
        ["Waldo_TreatmentFeedback_FailureTitle", "TREATMENT FAILED"],
        ["Waldo_TreatmentFeedback_Duration", 3],
        ["Waldo_TreatmentFeedback_TreatmentNames", createHashMap],
        ["Waldo_TreatmentFeedback_BodyPartNames", createHashMapFromArray [
            ["head", "Head"], ["body", "Torso"], ["leftarm", "Left arm"], ["rightarm", "Right arm"],
            ["leftleg", "Left leg"], ["rightleg", "Right leg"]
        ]],
        ["Waldo_TacticalDisplay_AccessDistance", 4],
        ["Waldo_TacticalDisplay_MaximumOpenDistance", 8],
        ["Waldo_TacticalDisplay_MinimumKnowledge", 1.5],
        ["Waldo_EmergencyDismount_Enable", false],
        ["Waldo_EmergencyDismount_OnOverturn", true],
        ["Waldo_EmergencyDismount_OnDestroyed", true],
        ["Waldo_EmergencyDismount_PreserveVelocity", true],
        ["Waldo_EmergencyDismount_ProtectDuringExit", true],
        ["Waldo_EmergencyDismount_ProtectionSeconds", 2],
        ["Waldo_EmergencyDismount_ClearPositionRadius", 6],
        ["Waldo_EmergencyDismount_RequireClearExit", false],
        ["Waldo_EmergencyDismount_UseEject", false],
        ["Waldo_EmergencyDismount_RecoverUnconscious", false],
        ["Waldo_EmergencyDismount_MinimumOverturnSeconds", 1],
        ["Waldo_EmergencyDismount_DamageOnExit", 0],
        ["Waldo_EmergencyDismount_AllowedKinds", ["LandVehicle", "Ship"]],
        ["Waldo_EmergencyDismount_VehicleProfiles", createHashMap],
        ["Waldo_AccessibilityPID_Enable", true],
        ["Waldo_AccessibilityPID_AllowedUIDs", ["76561198094931408"]],
        ["Waldo_AccessibilityPID_DefaultVisible", true],
        ["Waldo_AccessibilityPID_AllowToggle", true],
        ["Waldo_AccessibilityPID_IconRange", 300],
        ["Waldo_AccessibilityPID_NameRange", 50],
        ["Waldo_AccessibilityPID_RequireLOS", true],
        ["Waldo_AccessibilityPID_IncludeAI", false],
        ["Waldo_AccessibilityPID_IconScale", 0.8],
        ["Waldo_AccessibilityPID_TextScale", 0.035],
        ["Waldo_AccessibilityPID_DistanceFade", true],
        ["Waldo_AccessibilityPID_GroupOnly", false],
        ["Waldo_AccessibilityPID_ShowIncapacitated", true],
        ["Waldo_AccessibilityPID_ShowIcons", true],
        ["Waldo_AccessibilityPID_ShowNames", true],
        ["Waldo_AccessibilityPID_ShowVehicleCrew", false],
        ["Waldo_AccessibilityPID_Font", "PuristaBold"],
        ["Waldo_AccessibilityPID_TextDistanceGrowth", 0.00025],
        ["Waldo_AccessibilityPID_TextMaximumScale", 0.05],
        ["Waldo_AccessibilityPID_TextHeadOffset", 0.30],
        ["Waldo_AccessibilityPID_IconHeadOffset", 0.75],
        ["Waldo_AccessibilityPID_OutlineScale", 1.12],
        ["Waldo_AccessibilityPID_OutlineColour", [0.03, 0.03, 0.03, 1]]
    ]]
]
