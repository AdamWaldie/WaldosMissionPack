// Generated full-pack audit entry point. Keep the real pack lifecycle intact.
call compile preprocessFileLineNumbers "auditBootstrap.sqf";
call compile preprocessFileLineNumbers "auditPreInitPlayerLocal.sqf";

/*
 * Author: WaldoTheWarfighter
 * The engine re-executes this file on every respawn (and JIP), not only at mission start - only the
 * loadout-baseline capture and the "Respawn" handler registration further down are guarded to run
 * once per client; everything else here is designed to re-run per respawn so it rebinds to the
 * fresh unit object (ACE self-actions, ACRE assignment, etc. are per-object, not per-class). It
 * starts local UI/actions, applies the server-published ACRE plan, and owns that player's respawn
 * snapshot. Mission makers normally edit MissionConfig rather than this file. Add a custom call here
 * only when its function header says player-local, hasInterface, local UI, local interaction, or
 * local player state.
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
    // ACRE's initial assignment must not race a player-persistence read. Start closed, then let the
    // authoritative runtime snapshot resolve this to DISABLED, PENDING, FOUND, NONE or FAILED.
    // FAILED deliberately releases ACRE but never permits this client to overwrite an unread save.
    missionNamespace setVariable ["Waldo_Persistence_PlayerLoadState", "WAITING_RUNTIME"];
    missionNamespace setVariable ["Waldo_Persistence_PlayerSaveReady", false];
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
        if !(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]) exitWith {
            missionNamespace setVariable ["Waldo_Persistence_PlayerLoadState", "FAILED"];
            missionNamespace setVariable ["Waldo_Persistence_PlayerSaveReady", false];
            ["PERSISTENCE_RUNTIME_FAILED", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
        };
        if (missionNamespace getVariable ["Waldo_Economy_Enable", false]) then {
            // Client presentation starts only after the server's authoritative preset/catalogues
            // have been published. On a hosted server EcoInit is repeat-safe and this is a no-op.
            [] call Waldo_fnc_EcoInit;
        };
        if (missionNamespace getVariable ["Waldo_TreatmentFeedback_Enable", false]) then {
            [] call Waldo_fnc_TreatmentFeedbackInit;
        };
        if (missionNamespace getVariable ["Waldo_Obituary_Enable", true]) then {
            [] call Waldo_fnc_ObituaryInit;
        };
        if (missionNamespace getVariable ["Waldo_EmergencyDismount_Enable", false]) then {
            [] call Waldo_fnc_EmergencyDismountInit;
        };
        if (missionNamespace getVariable ["Waldo_WmpHud_Enable", false]) then {
            [] call Waldo_fnc_WmpHudInit;
        };
        if (missionNamespace getVariable ["Waldo_Persistence_Enable", false]) then {
            [] call Waldo_fnc_PersistenceInit;
        } else {
            missionNamespace setVariable ["Waldo_Persistence_PlayerLoadState", "DISABLED"];
            missionNamespace setVariable ["Waldo_Persistence_PlayerSaveReady", true];
            ["PERSISTENCE_DISABLED", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
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

// The engine re-executes this whole file on every respawn, not only at mission start/JIP. Guard just
// this block - the mission-start baseline capture and the "Respawn" handler registration - to run
// once per client: without the guard, a respawn rerunning Waldo_fnc_SaveLoadout here would
// immediately re-capture the freshly-spawned unit's raw default loadout into Waldo_Player_Inventory,
// clobbering whatever loadout was actually saved, and each rerun would also stack a duplicate
// "Respawn" handler registration. The single handler registered below persists at the engine level
// and keeps firing correctly on every later respawn without this block needing to run again.
if (isNil "Waldo_InitPlayerLocal_RespawnHandlerInstalled") then {
    Waldo_InitPlayerLocal_RespawnHandlerInstalled = true;

    // Save a base-class inventory on mission start. ACRE startup replaces this with the fully assigned
    // inventory plus player-level radio snapshot after its one-time baseline configuration.
    [false] call Waldo_fnc_SaveLoadout;

    // Respawn restores the last explicitly saved inventory and supported personal ACRE settings.
    // Two independent triggers call the shared, idempotent Waldo_fnc_RespawnRestoreLoadout rather than
    // depending on a single signal - the same "don't just wait and hope, actively cover the failure
    // mode" approach applied to the ACRE Eden-attribute race. Waldo_fnc_RespawnRestoreLoadout's own
    // per-unit "Waldo_RespawnRestoreHandled" guard makes it safe for both to fire for the same life.
    //
    // Trigger 1: the "CAManBase"/"Respawn" extended event handler. Gated on locality, not "_unit ==
    // player" - the engine does not guarantee `player` has been reassigned to the new unit at the
    // exact tick this event fires, and when it hasn't, that comparison silently skips everything with
    // no error and no log line (this was the actual cause of the restore never running even with an
    // otherwise-correct identity check and guard). This extended event handler only ever fires on
    // whichever machine the new unit is local to in the first place - the same guarantee ACE's own
    // respawn/init handlers rely on (ace/addons/common/CfgEventHandlers.hpp checks
    // "local (_this select 0)" rather than comparing against `player`).
    ["CAManBase", "Respawn", {
        params ["_unit"];
        // Unconditional, unguarded proof-of-dispatch line - written before any gate, so RPT can
        // distinguish "this extended event handler never fired at all" from "it fired but a gate
        // skipped the restore". Cheap and permanent: one line per actual respawn, not a loop.
        diag_log format ["[WMP LOADOUT] Respawn event received for %1 (local=%2, isPlayer=%3, player==_unit=%4).", _unit, local _unit, isPlayer _unit, _unit == player];
        [_unit] call Waldo_fnc_RespawnRestoreLoadout;
    }] call CBA_fnc_addClassEventHandler;

    // Trigger 2: CBA's own "player object changed" event - the exact same mechanism
    // Waldo_fnc_ACRE2Init already uses to refresh radios on respawn (see acre2InitNew.sqf's "unit"
    // handler), and unambiguous by construction: CBA only calls this once `player` itself already
    // equals the new unit, so there is no reassignment-timing question here at all. CBA passes
    // [_newPlayer, _oldPlayer] - only treat this as a respawn (and restore the saved loadout) when the
    // previous player object is dead or gone; a "unit" change with a still-alive old unit is some
    // other kind of player-object reassignment (e.g. a Zeus takeover), not a death/respawn, and must
    // not have the respawn loadout stamped over whatever that unit already legitimately has.
    [
        "unit",
        {
            params ["_newUnit", ["_oldUnit", objNull]];
            private _isRespawn = isNull _oldUnit || {!alive _oldUnit};
            diag_log format ["[WMP LOADOUT] Player-unit-changed event received for %1 (oldUnit=%2, oldAlive=%3, treatingAsRespawn=%4).", _newUnit, _oldUnit, !isNull _oldUnit && {alive _oldUnit}, _isRespawn];
            if (_isRespawn) then {[_newUnit] call Waldo_fnc_RespawnRestoreLoadout};
        },
        false
    ] call CBA_fnc_addPlayerEventHandler;
};

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

Off by default (Waldo_Respawn_SaveOnDeath in MissionConfig\logisticsConfig.sqf). The default respawn
source is the mission-start baseline plus whatever a player last saved through the manual "Loadout
Save Point" ACE/vanilla action (Waldo_fnc_SaveLoadout, Zen_loadoutSaveSetup.sqf). Set
Waldo_Respawn_SaveOnDeath to true for players to instead respawn with whatever equipment and ACRE2
radio channels they had at the moment of death - Waldo_fnc_SaveLoadout captures both loadout and
supported radio state together (see its own header), so this one handler fixes both.
*/

if (missionNamespace getVariable ["Waldo_Respawn_SaveOnDeath", false]) then {
    ["CAManBase", "Killed", {
        params ["_unit"];
        if (_unit == player) then {
            [false] call Waldo_fnc_SaveLoadout;
        };
    }] call CBA_fnc_addClassEventHandler;
};

call compile preprocessFileLineNumbers "auditInitPlayerLocal.sqf";
