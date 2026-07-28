// Generated full-pack audit entry point. Keep the real pack lifecycle intact.
call compile preprocessFileLineNumbers "auditBootstrap.sqf";
call compile preprocessFileLineNumbers "auditPreInitPlayerLocal.sqf";

/*
 * Author: WaldoTheWarfighter
 * initPlayerLocal.sqf - runs per-player on each join and respawn. Saves the starting loadout, adds
 * the "Flip Vehicle" action, and re-applies the saved loadout and action on respawn via a CBA event
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
    // ZEN module registration is presentation-local; dedicated servers and headless clients do not need it.
    [] call Waldo_fnc_ZenInitModules;

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
    if (isNil "Waldo_TreatmentFeedback_StartColour") then {Waldo_TreatmentFeedback_StartColour = [0.95, 0.75, 0.20, 1]};
    if (isNil "Waldo_TreatmentFeedback_SuccessColour") then {Waldo_TreatmentFeedback_SuccessColour = [0.20, 0.85, 0.35, 1]};
    if (isNil "Waldo_TreatmentFeedback_FailureColour") then {Waldo_TreatmentFeedback_FailureColour = [0.95, 0.25, 0.20, 1]};
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

    [] spawn {
        waitUntil {
            missionNamespace getVariable ["Waldo_SharedFeatureConfigReady", false]
            && {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]}
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
    };
};

//Post-Init Setup of saved Loadout (Measure taken to help prevent Naked/unarmed People)


// Save Inventory on mission start
[player, [missionNamespace, "Waldo_Player_Inventory"], [], false] call BIS_fnc_saveInventory;

player addAction [
    "Flip Vehicle",
    "MissionScripts\Logistics\LogiHelpers\flipAction.sqf",
    [],
    0,
    false,
    true,
    "",
    "_this == (vehicle _target) && {(count nearestObjects [_target, ['landVehicle'], 5]) > 0 && {(vectorUp cursorTarget) select 2 < 0}}"
];

/* //This doesnt seem to work after the 2022 December patch.
["CAManBase", "InitPost", {
    params ["_unit"];
    if (_unit == player) then {
        [_unit, [missionNamespace, "Waldo_Player_Inventory"], [], false] call BIS_fnc_saveInventory; // Apparently just doesnt work anymore
        //missionNamespace setVariable ["Waldo_Player_Inventory",getUnitLoadout _unit,false]
        _unit addAction [
        "Flip Vehicle",
        "MissionScripts\Logistics\LogiHelpers\flipAction.sqf",
        [],
        0,
        false,
        true,
        "",
        "_this == (vehicle _target) && {(count nearestObjects [_target, ['landVehicle'], 5]) > 0 && {(vectorUp cursorTarget) select 2 < 0}}"
    ];
    };
}] call CBA_fnc_addClassEventHandler;*/


//Respawn Reapplication Of Loadout Segment
["CAManBase", "Respawn", {
    params ["_unit"];
    if (_unit == player) then {
        [_unit, [missionNamespace, "Waldo_Player_Inventory"]] call BIS_fnc_loadInventory;
        //_unit setUnitLoadout (missionNamespace getVariable "Waldo_Player_Inventory");
        // Respawn Text
        [] spawn Waldo_fnc_RespawnText;
        // Re-apply safestart if it is still active (respawn resets damage/handlers/position)
        if (missionNamespace getVariable ["Waldo_SafeStart_Active", false]) then {
            [true] call Waldo_fnc_SafeStartApply;
        };
        [] call Waldo_fnc_SetupUiCleanupAction;
        player addAction [
        "Flip Vehicle",
        "MissionScripts\Logistics\LogiHelpers\flipAction.sqf",
        [],
        0,
        false,
        true,
        "",
        "_this == (vehicle _target) && {(count nearestObjects [_target, ['landVehicle'], 5]) > 0 && {(vectorUp cursorTarget) select 2 < 0}}"
    ];
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
//     [player, [missionNamespace, "Waldo_Player_Inventory"]] call BIS_fnc_saveInventory;
// }] call CBA_fnc_addEventHandler;

/*
=====================RESPAWN WITH LOADOUT ON DEATH====================================

UNCOMMENT THE BELOW IF YOU WANT PEOPLE TO RESPAWN WITH WHAT THEY DIED WITH!


*/

/*
["CAManBase", "Killed", {
    params ["_unit"];
    if (_unit == player) then {
        [_unit, [player, "Waldo_Player_Inventory"]] call BIS_fnc_saveInventory;
    };
}] call CBA_fnc_addClassEventHandler;


*/

call compile preprocessFileLineNumbers "auditInitPlayerLocal.sqf";
