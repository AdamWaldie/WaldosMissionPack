/*
 * Author: WaldoTheWarfighter
 * Defines repeat-safe presentation and interaction defaults for a machine with a player interface.
 * This file contains no activation, waiting, remote execution or authoritative publication.
 * Server/JIP values already present in missionNamespace are preserved by every isNil guard.
 *
 * Arguments: None.
 * Return Value: Nothing; guarded player-local defaults are installed.
 *
 * Example: call compile preprocessFileLineNumbers "MissionConfig\PlayerLocalFeatureDefaults.sqf";
 * Current caller: initPlayerLocal.sqf inside its hasInterface branch, before local feature startup.
 */
if (isNil "Waldo_UiNotification_MaximumQueued") then {Waldo_UiNotification_MaximumQueued = 12};
if (isNil "Waldo_UiNotification_QueueLifetime") then {Waldo_UiNotification_QueueLifetime = 15};
if (isNil "Waldo_UiNotification_MaximumPerPlacement") then {Waldo_UiNotification_MaximumPerPlacement = 3};
if (isNil "Waldo_UiNotification_ReflowDuration") then {Waldo_UiNotification_ReflowDuration = 0.18};
if (isNil "Waldo_UiNotification_AllowPlacementOverflow") then {Waldo_UiNotification_AllowPlacementOverflow = true};
if (isNil "Waldo_UiNotification_OverflowPlacements") then {
    Waldo_UiNotification_OverflowPlacements = ["BOTTOM_RIGHT", "BOTTOM_LEFT", "CENTER"];
};
if (isNil "Waldo_UI_PanelPlacements") then {
    Waldo_UI_PanelPlacements = [
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
    ];
};

if (isNil "Waldo_TreatmentFeedback_Enable") then {Waldo_TreatmentFeedback_Enable = false};
if (isNil "Waldo_TreatmentFeedback_ShowStart") then {Waldo_TreatmentFeedback_ShowStart = true};
if (isNil "Waldo_TreatmentFeedback_ShowSuccess") then {Waldo_TreatmentFeedback_ShowSuccess = true};
if (isNil "Waldo_TreatmentFeedback_ShowFailure") then {Waldo_TreatmentFeedback_ShowFailure = true};
if (isNil "Waldo_TreatmentFeedback_NotifyPatient") then {Waldo_TreatmentFeedback_NotifyPatient = true};
if (isNil "Waldo_TreatmentFeedback_NotifyMedic") then {Waldo_TreatmentFeedback_NotifyMedic = false};
if (isNil "Waldo_TreatmentFeedback_ShowMedicName") then {Waldo_TreatmentFeedback_ShowMedicName = true};
if (isNil "Waldo_TreatmentFeedback_ShowBodyPart") then {Waldo_TreatmentFeedback_ShowBodyPart = true};
if (isNil "Waldo_TreatmentFeedback_StartTitle") then {Waldo_TreatmentFeedback_StartTitle = "TREATMENT STARTED"};
if (isNil "Waldo_TreatmentFeedback_SuccessTitle") then {Waldo_TreatmentFeedback_SuccessTitle = "TREATMENT COMPLETE"};
if (isNil "Waldo_TreatmentFeedback_FailureTitle") then {Waldo_TreatmentFeedback_FailureTitle = "TREATMENT FAILED"};
if (isNil "Waldo_TreatmentFeedback_Duration") then {Waldo_TreatmentFeedback_Duration = 3};
if (isNil "Waldo_TreatmentFeedback_TreatmentNames") then {Waldo_TreatmentFeedback_TreatmentNames = createHashMap};
if (isNil "Waldo_TreatmentFeedback_BodyPartNames") then {
    Waldo_TreatmentFeedback_BodyPartNames = createHashMapFromArray [
        ["head", "Head"], ["body", "Torso"], ["leftarm", "Left arm"], ["rightarm", "Right arm"],
        ["leftleg", "Left leg"], ["rightleg", "Right leg"]
    ];
};

if (isNil "Waldo_TacticalDisplay_AccessDistance") then {Waldo_TacticalDisplay_AccessDistance = 4};
if (isNil "Waldo_TacticalDisplay_MaximumOpenDistance") then {Waldo_TacticalDisplay_MaximumOpenDistance = 8};
if (isNil "Waldo_TacticalDisplay_MinimumKnowledge") then {Waldo_TacticalDisplay_MinimumKnowledge = 1.5};

if (isNil "Waldo_EmergencyDismount_Enable") then {Waldo_EmergencyDismount_Enable = false};
if (isNil "Waldo_EmergencyDismount_OnOverturn") then {Waldo_EmergencyDismount_OnOverturn = true};
if (isNil "Waldo_EmergencyDismount_OnDestroyed") then {Waldo_EmergencyDismount_OnDestroyed = true};
if (isNil "Waldo_EmergencyDismount_PreserveVelocity") then {Waldo_EmergencyDismount_PreserveVelocity = true};
if (isNil "Waldo_EmergencyDismount_ProtectDuringExit") then {Waldo_EmergencyDismount_ProtectDuringExit = true};
if (isNil "Waldo_EmergencyDismount_ProtectionSeconds") then {Waldo_EmergencyDismount_ProtectionSeconds = 2};
if (isNil "Waldo_EmergencyDismount_ClearPositionRadius") then {Waldo_EmergencyDismount_ClearPositionRadius = 6};
if (isNil "Waldo_EmergencyDismount_RequireClearExit") then {Waldo_EmergencyDismount_RequireClearExit = false};
if (isNil "Waldo_EmergencyDismount_UseEject") then {Waldo_EmergencyDismount_UseEject = false};
if (isNil "Waldo_EmergencyDismount_RecoverUnconscious") then {Waldo_EmergencyDismount_RecoverUnconscious = false};
if (isNil "Waldo_EmergencyDismount_MinimumOverturnSeconds") then {Waldo_EmergencyDismount_MinimumOverturnSeconds = 1};
if (isNil "Waldo_EmergencyDismount_DamageOnExit") then {Waldo_EmergencyDismount_DamageOnExit = 0};
if (isNil "Waldo_EmergencyDismount_AllowedKinds") then {Waldo_EmergencyDismount_AllowedKinds = ["LandVehicle", "Ship"]};
if (isNil "Waldo_EmergencyDismount_VehicleProfiles") then {Waldo_EmergencyDismount_VehicleProfiles = createHashMap};

if (isNil "Waldo_AccessibilityPID_Enable") then {Waldo_AccessibilityPID_Enable = true};
if (isNil "Waldo_AccessibilityPID_AllowedUIDs") then {Waldo_AccessibilityPID_AllowedUIDs = ["76561198094931408"]};
if (isNil "Waldo_AccessibilityPID_DefaultVisible") then {Waldo_AccessibilityPID_DefaultVisible = true};
if (isNil "Waldo_AccessibilityPID_AllowToggle") then {Waldo_AccessibilityPID_AllowToggle = true};
if (isNil "Waldo_AccessibilityPID_IconRange") then {Waldo_AccessibilityPID_IconRange = 300};
if (isNil "Waldo_AccessibilityPID_NameRange") then {Waldo_AccessibilityPID_NameRange = 50};
if (isNil "Waldo_AccessibilityPID_RequireLOS") then {Waldo_AccessibilityPID_RequireLOS = true};
if (isNil "Waldo_AccessibilityPID_IncludeAI") then {Waldo_AccessibilityPID_IncludeAI = false};
if (isNil "Waldo_AccessibilityPID_IconScale") then {Waldo_AccessibilityPID_IconScale = 0.8};
if (isNil "Waldo_AccessibilityPID_TextScale") then {Waldo_AccessibilityPID_TextScale = 0.035};
if (isNil "Waldo_AccessibilityPID_DistanceFade") then {Waldo_AccessibilityPID_DistanceFade = true};
if (isNil "Waldo_AccessibilityPID_GroupOnly") then {Waldo_AccessibilityPID_GroupOnly = false};
if (isNil "Waldo_AccessibilityPID_ShowIncapacitated") then {Waldo_AccessibilityPID_ShowIncapacitated = true};
if (isNil "Waldo_AccessibilityPID_ShowIcons") then {Waldo_AccessibilityPID_ShowIcons = true};
if (isNil "Waldo_AccessibilityPID_ShowNames") then {Waldo_AccessibilityPID_ShowNames = true};
if (isNil "Waldo_AccessibilityPID_ShowVehicleCrew") then {Waldo_AccessibilityPID_ShowVehicleCrew = false};
if (isNil "Waldo_AccessibilityPID_Font") then {Waldo_AccessibilityPID_Font = "PuristaBold"};
if (isNil "Waldo_AccessibilityPID_TextDistanceGrowth") then {Waldo_AccessibilityPID_TextDistanceGrowth = 0.00025};
if (isNil "Waldo_AccessibilityPID_TextMaximumScale") then {Waldo_AccessibilityPID_TextMaximumScale = 0.05};
if (isNil "Waldo_AccessibilityPID_TextHeadOffset") then {Waldo_AccessibilityPID_TextHeadOffset = 0.30};
if (isNil "Waldo_AccessibilityPID_IconHeadOffset") then {Waldo_AccessibilityPID_IconHeadOffset = 0.75};
if (isNil "Waldo_AccessibilityPID_OutlineScale") then {Waldo_AccessibilityPID_OutlineScale = 1.12};
if (isNil "Waldo_AccessibilityPID_OutlineColour") then {Waldo_AccessibilityPID_OutlineColour = [0.03, 0.03, 0.03, 1]};
