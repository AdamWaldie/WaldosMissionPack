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

if (missionNamespace getVariable ["Waldo_ACRE2_Enabled", false]) then {
    player createDiarySubject ["WMP_ACRE_TEST", "WMP ACRE Test"];
    player createDiaryRecord ["WMP_ACRE_TEST", ["Expected radio settings", format [
        "Group: %1<br/><br/>ALPHA: PRC-343 B5/C3 left; PRC-152 C4 right; PRC-77 45.500 MHz both.<br/><br/>BRAVO: PRC-343 B6/C7 right; PRC-152 C8 left; PRC-77 51.000 MHz both.<br/><br/>Change a channel and ear, save at the equipment crate, respawn, then confirm your saved personal state returns.",
        groupId group player
    ]]];
};

// The real lifecycle builds the CEOI after the server plan and unique radios are ready. These
// local controls make CEOI and optional Babel verification explicit instead of asking a tester to
// infer success from the physical radios alone.
[] spawn {
    if !(missionNamespace getVariable ["Waldo_ACRE2_Enabled", false]) exitWith {};
    private _deadline = diag_tickTime + 35;
    waitUntil {
        uiSleep 0.2;
        !isNull acre_loadout_crate
        && {
            (
                missionNamespace getVariable ["Waldo_ACRE2_CEOIReady", false]
                && {(missionNamespace getVariable ["Waldo_ACRE2_CEOIOwner", objNull]) == player}
            )
            || {diag_tickTime >= _deadline}
        }
    };
    if (isNull acre_loadout_crate || {acre_loadout_crate getVariable ["Waldo_ACRE_TestReportActions", false]}) exitWith {};
    acre_loadout_crate addAction [
        "<t color='#106BB5'>Refresh ACRE2 CEOI</t>",
        {
            private _built = [] call Waldo_fnc_ACRE2BuildCEOI;
            ["ACRE2 TEST", if (_built) then {"CEOI rebuilt. Open Map > Briefing > ACRE2 > CEOI."} else {"CEOI could not be built. The server plan or group assignment is unavailable; inspect the RPT."}, if (_built) then {"SUCCESS"} else {"ERROR"}, "ACRE2_TEST", 8]
                call Waldo_fnc_FeatureNotifyLocal;
            openMap [true, true];
        },
        [], 1.5, true, true, "", "_this distance _target < 4", 4
    ];
    acre_loadout_crate addAction [
        "<t color='#106BB5'>Report ACRE2 / Babel State</t>",
        {
            private _config = missionNamespace getVariable ["Waldo_ACRE2_Config", createHashMap];
            private _babel = _config getOrDefault ["babel", createHashMap];
            private _babelEnabled = _babel getOrDefault ["enabled", false];
            private _last = missionNamespace getVariable ["Waldo_ACRE2_LastApplication", []];
            private _applied = if (count _last >= 5) then {count (_last select 4)} else {0};
            private _problems = if (count _last >= 6) then {_last select 5} else {["No completed local application"]};
            private _babelState = if (_babelEnabled) then {
                format ["enabled; understood %1; speaking %2", missionNamespace getVariable ["Waldo_ACRE2_BabelLanguages", []], missionNamespace getVariable ["Waldo_ACRE2_BabelSpeaking", "UNSET"]]
            } else {
                "disabled by MissionConfig\\acreConfig.sqf"
            };
            private _ceoiReady = missionNamespace getVariable ["Waldo_ACRE2_CEOIReady", false]
                && {(missionNamespace getVariable ["Waldo_ACRE2_CEOIOwner", objNull]) == player};
            private _message = format ["Applied radio entries: %1. CEOI: %2. Babel: %3%4", _applied, ["MISSING", "READY"] select _ceoiReady, _babelState, if (_problems isEqualTo []) then {"."} else {format [". Problems: %1", _problems]}];
            ["ACRE2 TEST", _message, if (_applied > 0 && {_problems isEqualTo []}) then {"SUCCESS"} else {"WARNING"}, "ACRE2_TEST", 12]
                call Waldo_fnc_FeatureNotifyLocal;
        },
        [], 1.5, true, true, "", "_this distance _target < 4", 4
    ];
    private _babel = (missionNamespace getVariable ["Waldo_ACRE2_Config", createHashMap]) getOrDefault ["babel", createHashMap];
    if (_babel getOrDefault ["enabled", false]) then {
        acre_loadout_crate addAction [
            "<t color='#106BB5'>Reapply Enabled ACRE2 Babel</t>",
            {
                private _applied = [] call Waldo_fnc_ACRE2ApplyBabel;
                ["ACRE2 BABEL", if (_applied) then {"Enabled Babel settings reapplied. See Map > Briefing > ACRE2 > Babel."} else {"Babel application failed; inspect the RPT."}, if (_applied) then {"SUCCESS"} else {"ERROR"}, "ACRE2_TEST", 8]
                    call Waldo_fnc_FeatureNotifyLocal;
            },
            [], 1.5, true, true, "", "_this distance _target < 4", 4
        ];
    };
    acre_loadout_crate setVariable ["Waldo_ACRE_TestReportActions", true];
};

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
