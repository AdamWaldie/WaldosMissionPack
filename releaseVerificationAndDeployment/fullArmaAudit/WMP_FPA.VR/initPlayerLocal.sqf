// Generated full-pack audit entry point. Keep the real pack lifecycle intact.
call compile preprocessFileLineNumbers "auditBootstrap.sqf";
call compile preprocessFileLineNumbers "auditPreInitPlayerLocal.sqf";

/*
 * Author: WaldoTheWarfighter
 * initPlayerLocal.sqf - runs per-player on each join. Saves the starting loadout and re-applies it
 * on respawn via a CBA event. Vehicle recovery actions are bound to vehicles by VehicleInit.
 * handler. Two optional behaviours (save-on-arsenal-close, respawn-with-what-you-died-with) are
 * included commented out below.
 *
 * Arguments:
 * None (engine entry point; runs locally for each player)
 *
 * Return Value:
 * Nothing
 */

/*
Player-local optional feature configuration and activation

These defaults are installed only on machines with a player interface. The isNil guards preserve
newer values published by the server before a JIP player reaches initPlayerLocal.sqf. Server-owned
or cross-locality features wait for init.sqf to finish its shared configuration before starting.
*/
if (hasInterface) then {
    [] call Waldo_fnc_ACRE2Init;
    // InfoText marks completion after the fake loading/title presentation. Features may queue
    // non-critical notices against this state instead of drawing over the introduction.
    missionNamespace setVariable ["Waldo_InfoText_Active", false];
    missionNamespace setVariable ["Waldo_InfoText_Complete", false];

    // ZEN module registration is presentation-local; dedicated servers and headless clients do not need it.
    [] call Waldo_fnc_ZenInitModules;

    // Local notification back-pressure and screen-region overflow.
    if (isNil "Waldo_UiNotification_MaximumQueued") then {Waldo_UiNotification_MaximumQueued = 12};
    if (isNil "Waldo_UiNotification_QueueLifetime") then {Waldo_UiNotification_QueueLifetime = 15};
    if (isNil "Waldo_UiNotification_MaximumPerPlacement") then {Waldo_UiNotification_MaximumPerPlacement = 3};
    if (isNil "Waldo_UiNotification_ReflowDuration") then {Waldo_UiNotification_ReflowDuration = 0.18};
    if (isNil "Waldo_UiNotification_AllowPlacementOverflow") then {Waldo_UiNotification_AllowPlacementOverflow = true};
    if (isNil "Waldo_UiNotification_OverflowPlacements") then {
        Waldo_UiNotification_OverflowPlacements = ["BOTTOM_RIGHT", "BOTTOM_LEFT", "CENTER"];
    };
    // Actual feature families use independent screen streams. Mission makers can
    // replace this array before initPlayerLocal runs, and permitted players can
    // override individual channels through Waldo_fnc_SetLocalUiPanelPlacement.
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

    // Enabled only for the original intended recipient; [] permits every player.
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

    // Server-authored electronic-warfare settings are replicated before JIP init. Initial
    // lobby clients may still race server startup, so wait asynchronously for the sentinel.
    [] spawn {
        private _deadline = diag_tickTime + 30;
        waitUntil {
            uiSleep 0.1;
            missionNamespace getVariable ["Waldo_Jamming_ConfigReady", false]
            || {diag_tickTime >= _deadline}
        };
        if (
            missionNamespace getVariable ["Waldo_Jamming_ConfigReady", false]
            && {missionNamespace getVariable ["Waldo_Jamming_Enable", false]}
        ) then {
            [] call Waldo_fnc_JammingInit;
        };
    };

    [] spawn {
        waitUntil {
            missionNamespace getVariable ["Waldo_SharedFeatureConfigReady", false]
            && {
                missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]
                || {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotFailed", false]}
            }
        };
        if !(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]) exitWith {};
        if (missionNamespace getVariable ["Waldo_Economy_Enable", false]) then {
            // Client presentation starts only after the server's authoritative preset/catalogues
            // have been published. On a hosted server EcoInit is repeat-safe and this is a no-op.
            [] call Waldo_fnc_EcoInit;
        };
        if (missionNamespace getVariable ["Waldo_TreatmentFeedback_Enable", false]) then {
            [] call Waldo_fnc_TreatmentFeedbackInit;
        };
        if (missionNamespace getVariable ["Waldo_EmergencyDismount_Enable", false]) then {
            [] call Waldo_fnc_EmergencyDismountInit;
        };
        if (missionNamespace getVariable ["Waldo_AccessibilityPID_Enable", false]) then {
            [] call Waldo_fnc_AccessibilityPIDInit;
        };
        if (missionNamespace getVariable ["Waldo_Persistence_Enable", false]) then {
            [] call Waldo_fnc_PersistenceInit;
        };
        if (missionNamespace getVariable ["Waldo_FieldResupply_Enable", false]) then {
            [] call Waldo_fnc_FieldResupplyInit;
        };
        if (missionNamespace getVariable ["Waldo_Hazard_Enable", false]) then {
            [] call Waldo_fnc_HazardInit;
        };
        if (missionNamespace getVariable ["Waldo_TreeFelling_Enable", false]) then {
            [] call Waldo_fnc_TreeFellingInit;
        };
        if (missionNamespace getVariable ["Waldo_Rally_Enable", false]) then {
            [] call Waldo_fnc_RallyPointInit;
        };
    };
};

//Post-Init Setup of saved Loadout (Measure taken to help prevent Naked/unarmed People)


// Save a base-class inventory on mission start. ACRE startup refreshes it after radio assignment.
[false] call Waldo_fnc_SaveLoadout;

//Respawn Reapplication Of Loadout Segment
["CAManBase", "Respawn", {
    params ["_unit"];
    if (_unit == player) then {
        private _savedLoadout = missionNamespace getVariable ["Waldo_Player_Inventory", []];
        if (count _savedLoadout > 0) then {_unit setUnitLoadout _savedLoadout};
        private _generation = (missionNamespace getVariable ["Waldo_ACRE2_LoadoutGeneration", 0]) + 1;
        missionNamespace setVariable ["Waldo_ACRE2_LoadoutGeneration", _generation];
        missionNamespace setVariable ["Waldo_ACRE2_PersistenceRadioGeneration", -1];
        [] spawn {
            private _deadline = diag_tickTime + 10;
            waitUntil {
                uiSleep 0.1;
                !(isClass (configFile >> "CfgPatches" >> "acre_main"))
                    || {[] call acre_api_fnc_isInitialized}
                    || {diag_tickTime >= _deadline}
            };
            [true, "RESPAWN"] call Waldo_fnc_ACRE2ApplyPlayerPlan;
            [] call Waldo_fnc_ACRE2ApplyBabel;
            [] call Waldo_fnc_ACRE2BuildCEOI;
        };
        // Respawn Text
        [] spawn Waldo_fnc_RespawnText;
        // Re-apply safestart if it is still active (respawn resets damage/handlers/position)
        if (missionNamespace getVariable ["Waldo_SafeStart_Active", false]) then {
            [true] call Waldo_fnc_SafeStartApply;
        };
        [] call Waldo_fnc_SetupUiCleanupAction;
        [] call Waldo_fnc_AccessibilitySelfInteractionInit;
    };
}] call CBA_fnc_addClassEventHandler;

// Apply safestart to this client if a freeze is already active when they join (JIP).
if (missionNamespace getVariable ["Waldo_SafeStart_Active", false]) then {
    [true] call Waldo_fnc_SafeStartApply;
};

// Shared, JIP-safe renderer for mission-maker custom 3D world markers.
[] call Waldo_fnc_Init3DMarkers;

// Local emergency cleanup for WMP-owned UI. ACE self-interaction is preferred;
// vanilla addAction is used only when ACE interaction is unavailable.
[] call Waldo_fnc_SetupUiCleanupAction;
// Personal accessibility presentation is installed for every interface client. The colour-vision
// profile is local/profile-persistent; eligible PID users receive their toggle under the same root.
[] call Waldo_fnc_AccessibilitySelfInteractionInit;
// ACE interaction owns the local interaction view while open. WMP notification
// cards are hidden/queued locally and restored when ACE closes.
[] call Waldo_fnc_SetupUiAcePriority;

// WMP overlays must never survive into Arma's death or debriefing displays.
// The cleanup function only hides controls owned by this pack.
addMissionEventHandler ["EntityKilled", {
    params ["_killed"];
    if (_killed isEqualTo player) then {[] call Waldo_fnc_CleanupTransientUi;};
}];
addMissionEventHandler ["Ended", {[] call Waldo_fnc_CleanupTransientUi;}];

/*
=====================ACE 3 SAVE LOADOUT ON ARSENAL CLOSE====================================
This allows you to save whatever loadout the player selected after they close the arsenal
so that they may respawn with it.  Particularly helpful when you just want the player to
select a loadout and then forget about having to use the arsenal after respawning.
*/

// ["ace_arsenal_displayClosed", {
//     [false] call Waldo_fnc_SaveLoadout;
// }] call CBA_fnc_addEventHandler;

/*
=====================RESPAWN WITH LOADOUT ON DEATH====================================

UNCOMMENT THE BELOW IF YOU WANT PEOPLE TO RESPAWN WITH WHAT THEY DIED WITH!


*/

/*
["CAManBase", "Killed", {
    params ["_unit"];
    if (_unit == player) then {
        [false] call Waldo_fnc_SaveLoadout;
    };
}] call CBA_fnc_addClassEventHandler;


*/

call compile preprocessFileLineNumbers "auditInitPlayerLocal.sqf";
