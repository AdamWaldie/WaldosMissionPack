/*
 * Author: WaldoTheWarfighter
 * Runs once for each player's own interface client. It starts local UI/actions, applies the
 * server-published ACRE plan, and owns that player's respawn snapshot. Mission makers normally edit
 * MissionConfig rather than this file. Add a custom call here only when its function header says
 * player-local, hasInterface, local UI, local interaction, or local player state.
 *
 * Arguments:
 * None (engine entry point; runs locally for each player)
 *
 * Return Value:
 * Nothing
 */

/*
PLAYER-LOCAL STARTUP
These settings and activations exist only on machines with a player interface. Guarded defaults do
not replace newer server values already received by a JIP player. Do not move server-owned feature
startup into this file: every player would create a competing copy.
*/
if (hasInterface) then {
    // Install briefing records synchronously whenever the player already exists so they are visible
    // before Continue. The bounded asynchronous path is only a fallback for a genuinely late player.
    if (!isNull player) then {
        call Waldo_fnc_AddDocs;
    } else {
        [] spawn {
            private _deadline = diag_tickTime + 30;
            waitUntil {uiSleep 0.1; !isNull player || {diag_tickTime >= _deadline}};
            if (!isNull player) then {call Waldo_fnc_AddDocs};
        };
    };
    [] call Waldo_fnc_ACRE2Init;
    // InfoText marks completion after the fake loading/title presentation. Features may queue
    // non-critical notices against this state instead of drawing over the introduction.
    missionNamespace setVariable ["Waldo_InfoText_Active", false];
    missionNamespace setVariable ["Waldo_InfoText_Complete", false];

    // ZEN module registration is presentation-local; dedicated servers and headless clients do not need it.
    [] call Waldo_fnc_ZenInitModules;

    // Pure-data configuration is local and synchronous; activation and JIP waits remain below.
    ["PLAYER_LOCAL"] call Waldo_fnc_LoadFeatureConfigs;

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
        if (missionNamespace getVariable ["Waldo_WmpHud_Enable", false]) then {
            [] call Waldo_fnc_WmpHudInit;
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

// Save a base-class inventory on mission start. ACRE startup replaces this with the fully assigned
// inventory plus player-level radio snapshot after its one-time baseline configuration.
[false] call Waldo_fnc_SaveLoadout;

// Respawn restores the last explicitly saved inventory and supported personal ACRE settings.
["CAManBase", "Respawn", {
    params ["_unit"];
    if (_unit == player) then {
        private _sideKey = switch (side _unit) do {case west: {"WEST"}; case east: {"EAST"}; case independent: {"GUER"}; default {"CIV"}};
        private _currentIdentity = [getPlayerUID _unit, vehicleVarName _unit, _sideKey];
        private _savedIdentity = missionNamespace getVariable ["Waldo_Player_LoadoutIdentity", []];
        private _identityMatches = _savedIdentity isEqualTo _currentIdentity;
        private _savedLoadout = missionNamespace getVariable ["Waldo_Player_Inventory", []];
        if (_identityMatches && {count _savedLoadout > 0}) then {_unit setUnitLoadout _savedLoadout};
        private _generation = (missionNamespace getVariable ["Waldo_ACRE2_LoadoutGeneration", 0]) + 1;
        missionNamespace setVariable ["Waldo_ACRE2_LoadoutGeneration", _generation];
        missionNamespace setVariable ["Waldo_ACRE2_RestoredRadioGeneration", -1];
        private _savedRadios = if (_identityMatches) then {missionNamespace getVariable ["Waldo_Player_RadioState", []]} else {[]};
        if (!_identityMatches) then {diag_log format ["[WMP LOADOUT] Saved snapshot identity %1 did not match respawn identity %2; baseline retained.", _savedIdentity, _currentIdentity]};
        if (count _savedRadios >= 3 && {count (_savedRadios select 1) > 0}) then {
            missionNamespace setVariable ["Waldo_ACRE2_RadioRestoreInProgress", true];
            [_savedRadios, _generation] spawn {
                params ["_radioState", "_loadoutGeneration"];
                private _restored = [_radioState, _loadoutGeneration] call Waldo_fnc_ACRE2ApplyRadioState;
                missionNamespace setVariable ["Waldo_ACRE2_RadioRestoreInProgress", false];
                if (_restored) then {
                    ["RESPAWN_RESTORED", false] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
                } else {
                    diag_log "[WMP ACRE] Saved respawn radio state could not be restored; applying the current mission plan.";
                    ["RESPAWN_RESTORE_FALLBACK", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
                };
            };
        } else {
            ["RESPAWN_BASELINE", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
        };
        // Respawn Text
        [] spawn Waldo_fnc_RespawnText;
        // Re-apply safestart if it is still active (respawn resets damage/handlers/position)
        if (missionNamespace getVariable ["Waldo_SafeStart_Active", false]) then {
            [true] call Waldo_fnc_SafeStartApply;
        };
        [] call Waldo_fnc_SetupUiCleanupAction;
        [] call Waldo_fnc_AccessibilitySelfInteractionInit;
        [] call Waldo_fnc_TransportInteractionInitLocal;
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
