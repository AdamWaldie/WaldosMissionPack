// Generated full-pack audit entry point. Keep the real pack lifecycle intact.
call compile preprocessFileLineNumbers "auditBootstrap.sqf";
call compile preprocessFileLineNumbers "auditPreInitPlayerLocal.sqf";

/*
 * Author: WaldoTheWarfighter
 * Runs once when this player joins the mission, including JIP. It starts local UI/actions, applies
 * the server-published ACRE plan, owns that player's respawn snapshot, and installs the local
 * Respawn event handler that survives later player-unit replacement. Per-respawn work belongs in
 * that handler; the engine does not rerun initPlayerLocal.sqf for every death. Mission makers
 * normally edit MissionConfig rather than this file. Add a custom call here
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
    // Register before any other player-local startup work. PreloadFinished is the engine event for
    // the mission preload screen actually ending; init/postInit completion and briefing state both
    // happen too early to prove that the player can see the scene. The same event also fires after
    // closing the map, so this handler removes itself after the first (initial-load) event.
    missionNamespace setVariable ["Waldo_InfoText_InitialPreloadFinished", false];
    private _infoTextPreloadHandler = addMissionEventHandler ["PreloadFinished", {
        missionNamespace setVariable ["Waldo_InfoText_InitialPreloadFinished", true];
        missionNamespace setVariable ["Waldo_InfoText_InitialPreloadFinishedAt", diag_tickTime];
        diag_log format ["[WMP INFOTEXT] Initial PreloadFinished received at diag_tickTime=%1.", diag_tickTime];
        removeMissionEventHandler ["PreloadFinished", _thisEventHandler];
    }];
    missionNamespace setVariable ["Waldo_InfoText_PreloadHandler", _infoTextPreloadHandler];

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

    // Adds a selected-object setDamage fallback after normal Zeus END-key processing. The display
    // handler never consumes END and does not require ZEN.
    [] call Waldo_fnc_KillHotkeyInit;

    // Pure-data configuration is local and synchronous; activation and JIP waits remain below.
    ["PLAYER_LOCAL"] call Waldo_fnc_LoadFeatureConfigs;

    // Seated tables are opt-in object registrations. This is a metadata replay only; when a mission
    // has no registered table it performs no MiniGames runtime compilation or background work.
    [] call Waldo_fnc_MiniGamesInitPlayerLocal;

    // Introduction Text - content and timing are MissionConfig\interfaceConfig.sqf settings, loaded
    // just above, not call-site parameters. The worker waits for the initial PreloadFinished event
    // registered at the top of this file, then performs only its short local presentation. It does
    // not gate other startup work or explicitly lock player input.
    [] spawn Waldo_fnc_InfoText;

    // ACE 3.21.1 forwards Arma's old-corpse object into a Boolean argument in its setName Respawn
    // callback. CBA may populate the per-unit callback list slightly after this event script starts,
    // so wait for that exact list before repairing only ACE's malformed entry.
    [] spawn {
        private _deadline = diag_tickTime + 30;
        waitUntil {
            uiSleep 0.1;
            (!isNull player && {!isNil {player getVariable "cba_xeh_respawn"}})
            || {diag_tickTime >= _deadline}
        };
        if (!isNull player && {!isNil {player getVariable "cba_xeh_respawn"}}) then {
            [player] call Waldo_fnc_AceSetNameRespawnBindingRepair;
        } else {
            diag_log "[WMP ACE COMPAT] Timed out waiting for CBA's player Respawn callback list; no repair was applied.";
        };
    };

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

// Capture a provisional mission-start baseline once this client's player unit actually exists, and
// install the persistent Respawn handler on it. `player` is not guaranteed to be non-null yet at this
// point in the file - JIP and slower-loading clients can reach this line before their unit is created,
// the same race already hedged around AddDocs and the ACE nametags Respawn-binding repair above.
// Capturing the baseline against a still-null player silently saves an empty loadout (getUnitLoadout
// objNull), and `player addEventHandler` against objNull attaches the handler to nothing - either one
// leaves that client's later respawns falling back to whatever generic loadout the engine's own
// respawn template assigns, instead of their Eden/ACE-Arsenal loadout. When ACRE is enabled, its
// initial assignment later replaces this baseline with a complete inventory-plus-radio snapshot.
// Loadout restore is mission-critical, so this waits indefinitely (not a single bounded attempt) and
// installs two independent restore triggers below rather than trusting one signal.
[] spawn {
    private _waitedSeconds = 0;
    waitUntil {
        uiSleep 0.1;
        if (isNull player) then {
            _waitedSeconds = _waitedSeconds + 0.1;
            // Log roughly every 30s instead of once - a client that takes unusually long to spawn a
            // player object should still show up in RPT as "still waiting", not go silent forever.
            if ((round (_waitedSeconds * 10)) % 300 == 0) then {
                diag_log format ["[WMP LOADOUT] initPlayerLocal.sqf: still waiting for player (%1s elapsed) before baseline capture and Respawn handler installation.", round _waitedSeconds];
            };
        };
        !isNull player
    };
    // `player` existing does not guarantee the engine has finished populating its
    // Eden/mission.sqm-configured inventory at that exact tick - the same class of transient-state
    // race the restore side already guards against (canary-verify-and-retry), never previously
    // guarded against here. Bounded settle-wait so the captured baseline reflects the unit's actually
    // fully-populated loadout, not whatever is present the instant the object reference appears.
    private _settleResult = [player] call Waldo_fnc_LoadoutWaitStable;
    _settleResult params ["_settleStable", "_settleElapsed"];
    [false] call Waldo_fnc_SaveLoadout;
    // Gate for trigger 2 below: it must never fire before the baseline above actually exists once,
    // otherwise it would treat this client's very first spawn as a "respawn" and race
    // Waldo_fnc_ACRE2Init's own one-time radio-generation setup on initial join.
    missionNamespace setVariable ["Waldo_LoadoutBaselineCaptured", true];
    // Diagnostic breadcrumbs only - read by respawn/baseline-capture and respawn/triggers in
    // runDiagnosticsClient.sqf so a mission maker can see exactly how long this client waited for
    // `player`, and whether each trigger below has ever actually fired, without needing to grep RPT.
    missionNamespace setVariable ["Waldo_LoadoutBaselineCapturedAt", diag_tickTime];
    missionNamespace setVariable ["Waldo_LoadoutBaselineWaitSeconds", _waitedSeconds];
    missionNamespace setVariable ["Waldo_LoadoutBaselineSettle", [_settleStable, _settleElapsed]];
    missionNamespace setVariable ["Waldo_LoadoutTrigger1FireCount", 0];
    missionNamespace setVariable ["Waldo_LoadoutTrigger2FireCount", 0];

    // Trigger 1: Bohemia's documented local "Respawn" handler - installed once here and carried by
    // the engine onto every later respawned unit body without needing to be re-registered.
    player addEventHandler ["Respawn", {
        params ["_newUnit", ["_oldUnit", objNull]];
        diag_log format ["[WMP LOADOUT] Local Respawn event received new=%1 old=%2 local=%3 playerMatches=%4.", _newUnit, _oldUnit, local _newUnit, _newUnit isEqualTo player];
        missionNamespace setVariable ["Waldo_LoadoutTrigger1FireCount", (missionNamespace getVariable ["Waldo_LoadoutTrigger1FireCount", 0]) + 1];
        [_newUnit, _oldUnit, "RESPAWN_EH"] call Waldo_fnc_RespawnRestoreLoadout;
    }];

    // Trigger 2 (independent safety net): CBA's own "player object changed" event - the same
    // mechanism Waldo_fnc_ACRE2Init already uses to refresh radios on respawn. Field evidence from an
    // earlier revision of this system (see project history around the "Respawn: independent second
    // restore trigger" and "Stabilize respawn radio state" changes) found trigger 1 alone can go a
    // full session without firing in some environments, while this CBA hook reliably did. It was later
    // dropped in favour of a single trigger specifically to avoid two failure modes that are now both
    // closed: (a) firing on the very first spawn and racing ACRE's initial setup - closed by the
    // Waldo_LoadoutBaselineCaptured gate above; (b) a duplicate-restore guard that lived on the unit
    // object itself and could be inherited onto the next respawned body, silently suppressing a later
    // life's restore - Waldo_fnc_RespawnRestoreLoadout's guard is now a single missionNamespace
    // "last handled unit" reference compared by object identity, which a fresh respawned unit can
    // never satisfy, so both triggers firing for the same life is simply a harmless no-op on whichever
    // runs second. Waldo_LoadoutTrigger1FireCount staying at 0 across a session with real respawns is
    // exactly the historical failure signature that justified keeping this second trigger - watch for
    // it in respawn/triggers.
    [
        "unit",
        {
            params ["_newUnit", ["_oldUnit", objNull]];
            private _isRespawn = (missionNamespace getVariable ["Waldo_LoadoutBaselineCaptured", false]) && {isNull _oldUnit || {!alive _oldUnit}};
            if (_isRespawn) then {
                diag_log format ["[WMP LOADOUT][WATCHDOG] Player-unit-changed fallback trigger fired for %1 (old=%2).", _newUnit, _oldUnit];
                missionNamespace setVariable ["Waldo_LoadoutTrigger2FireCount", (missionNamespace getVariable ["Waldo_LoadoutTrigger2FireCount", 0]) + 1];
                [_newUnit, _oldUnit, "UNIT_WATCHDOG"] call Waldo_fnc_RespawnRestoreLoadout;
            };
        },
        false
    ] call CBA_fnc_addPlayerEventHandler;

    // Live side-change detection for respawn snapshot seeding: side is always derived from group
    // membership in Arma, so a "group" player-event fires exactly when a Zeus/admin/mission-scripted
    // side reassignment actually takes effect - the same mechanism acre2InitNew.sqf already uses for
    // its own independent radio refresh. This handler is deliberately separate from that one: it only
    // ever seeds a missing per-side snapshot (Waldo_fnc_RespawnSeedSideSwitch), never touches ACRE's
    // plan directly. Always active, no mission-maker toggle - see logisticsConfig.sqf. No settle
    // window is needed here - unlike the two respawn triggers above, this always fires against an
    // already-fully-initialized live unit, never a freshly-created respawn body, so the transient
    // side-misread race the respawn path guards against does not apply.
    missionNamespace setVariable ["Waldo_Player_LastKnownSideKey", switch (side player) do {case west: {"WEST"}; case east: {"EAST"}; case independent: {"GUER"}; default {"CIV"}}];
    [
        "group",
        {
            if (isNull player) exitWith {};
            private _newSideKey = switch (side player) do {case west: {"WEST"}; case east: {"EAST"}; case independent: {"GUER"}; default {"CIV"}};
            private _lastSideKey = missionNamespace getVariable ["Waldo_Player_LastKnownSideKey", _newSideKey];
            if (_newSideKey == _lastSideKey) exitWith {};
            missionNamespace setVariable ["Waldo_Player_LastKnownSideKey", _newSideKey];
            [_newSideKey] call Waldo_fnc_RespawnSeedSideSwitch;
        },
        false
    ] call CBA_fnc_addPlayerEventHandler;
};

// Request one ordered server snapshot instead of trusting public-variable arrival order during JIP.
// The response applies either active or live state, so a stale local true can never strand a joiner.
[player] remoteExecCall ["Waldo_fnc_SafeStartRequestStateServer", 2];

// Shared, JIP-safe renderer for mission-maker custom 3D world markers.
[] call Waldo_fnc_Init3DMarkers;
// Start the paradrop aircraft-marker reconciler on every interface client. It reads the
// server-broadcast registry continuously, so marker creation no longer depends on a remote setup
// call arriving after the public state during initial join or JIP.
[] call Waldo_fnc_ParadropSetupLocal;

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
