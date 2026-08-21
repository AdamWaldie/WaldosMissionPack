/*
 * Author: WaldoTheWarfighter
 * Starts WMP code that must exist on every machine: server, players and headless clients.
 * Mission makers normally DO NOT enable features here. Edit the clearly named files inside
 * MissionConfig instead. WMP loads their SHARED settings below without overwriting values that a
 * server has already broadcast to a joining player.
 *
 * Arguments: None.
 * Return Value: Nothing; initializes shared mission state and schedules feature startup.
 *
 * Example: Arma executes init.sqf automatically during mission initialization.
 * Current caller: the Arma mission initialization sequence on server, clients and headless clients.
*/

/* BEGINNER START HERE
 * - A setting needed everywhere belongs in MissionConfig and is loaded here as SHARED data.
 * - A server-owned system starts in initServer.sqf.
 * - Player UI, local actions and personal state start in initPlayerLocal.sqf.
 * - A custom call belongs here only when its documentation explicitly says "every machine".
 * Never move a server or player-local activation here merely to make it run earlier: that creates
 * duplicate authorities and JIP races.
 */

// OPTIONAL VISUAL EXPERIMENT: uncomment only if this mission wants the post-process effect.
//"LightShafts" ppEffectAdjust [0.9, 0.8, 0.9, 0.8];

// OPTIONAL THIRD-PARTY ENTRY POINT: review that file before enabling it.
//[] execVM "MissionScripts\ThirdPartyScripts\ThirdPartyScriptInit.sqf";


// Pure-data shared feature configs are synchronous and repeat-safe. Runtime authority remains below.
["SHARED"] call Waldo_fnc_LoadFeatureConfigs;
missionNamespace setVariable ["Waldo_SharedFeatureConfigReady", true];
if (isServer) then {
    missionNamespace setVariable ["Waldo_FeatureRuntimeSnapshotReceived", true];
    missionNamespace setVariable ["Waldo_FeatureRuntimeSnapshotFailed", false];
    // A hosted server is both the authoritative server and an interface client. It does not pass
    // through FeatureRuntimeReceiveState during initial startup, so apply the authoritative shared
    // theme locally here. Dedicated servers skip this presentation-only work.
    if (hasInterface) then {
        [missionNamespace getVariable ["Waldo_UI_Theme", "DEFAULT"], false] call Waldo_fnc_UiThemeApplyLocal;
    };
} else {
    missionNamespace setVariable ["Waldo_FeatureRuntimeSnapshotReceived", false];
    missionNamespace setVariable ["Waldo_FeatureRuntimeSnapshotFailed", false];
    [] call Waldo_fnc_FeatureRuntimeRequestState;
};

[] spawn {
    waitUntil {
        missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]
        || {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotFailed", false]}
    };
    if !(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]) exitWith {};
    if (missionNamespace getVariable ["Waldo_Breaching_Enable", false]) then {
        [] call Waldo_fnc_BreachingInit;
    };
};

/*
Waldos Economy Systems (Resource / Research / Build / Buy + Ground Command)

A Zeus economy suite: define resources, capturable income zones and collectable crates,
run research at a Research Center, construct and upgrade buildings, and let players buy vehicles.
A trusted "Ground Command" controls spending. Everything is driven live from the Zeus menu
"Waldos Economy Systems" - no editor work required beyond enabling it.

Set `Waldo_Economy_Enable` in `MissionConfig\economyConfig.sqf`. It is OFF by default. Server and
player startup are already routed through their correct init files; do not add another activation
call here. A WMP economy composition may also supply mission setup where documented.

To pre-configure the economy from the editor (a bundled LOW/MEDIUM/HIGH preset, a full exported
config string, or commitment mode) without opening Zeus, see the "Waldos Economy Systems"
setup block in initServer.sqf.

Full guide (easiest path first): https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems
*/
// Activation is deliberately deferred to initServer.sqf and initPlayerLocal.sqf.
// The server must publish its preset/configuration before Economy reads it; starting here can
// race initServer.sqf and leave an enabled economy with empty catalogues.

/*
Waldos Mini Games (table party games + interaction procedures)

Two complementary systems under one feature:

  1. Table games - a seated, multiplayer party-games engine with twelve games including Texas
     Hold'em, Five-Card Draw, Liar's Dice and Connect Four. Place any supported table object (a
     camping table by default) in Eden and players get actions to sit, vote and play. Runs on all
     machines (server authority + client UI) and is JIP-safe. This installer is repeat-safe.

  2. Interaction procedures - ten single-player field-equipment procedures that resolve to an
     authoritative outcome and can gate any object interaction (see Waldo_fnc_MiniGameInteraction
     / Waldo_fnc_BombDefuseSetup). They register on first use and are independent of this flag.

Set the flag to false if your mission uses no table games (the interaction challenges are
unaffected). Full guide: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games
*/
if (Waldo_MiniGames_Enable) then {
    [] call Waldo_fnc_MiniGamesInit;
};

/*
ACE Corpse Traps

Lets players consume a carried throwable to rig any corpse through ACE interaction. The exact
magazine is preserved, so vanilla and modded frag, smoke, flashbang, incendiary and utility
throwables use their own projectile behaviour when somebody opens the body's inventory.

This is deliberately OFF by default because it changes a familiar inventory interaction into a
lethal risk. Full guide: https://github.com/AdamWaldie/WaldosMissionPack/wiki/ACE-Corpse-Traps
*/
if (Waldo_CorpseTraps_Enable) then {
    [] call Waldo_fnc_CorpseTrapInit;
};

/*===========================================================================================================================*/

/* AI REBALANCE, HELICOPTER LANDING AND DECELERATION
 * Normal setup: MissionConfig\aiConfig.sqf.
 * Waldo_AIRebalance_Mode is "DAY" or "NIGHT"; the profile is MILITIA, LINE, VETERAN or ELITE.
 * Do not add another AITweak call here. This readiness-aware activation uses the settings received
 * from server authority and applies the chosen baseline to local AI when locality changes.
 */
[] spawn {
    waitUntil {
        missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]
        || {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotFailed", false]}
    };
    if !(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]) exitWith {};
    if (missionNamespace getVariable ["Waldo_AIRebalance_Enable", true]) then {
        [
            missionNamespace getVariable ["Waldo_AIRebalance_Mode", "DAY"],
            missionNamespace getVariable ["Waldo_AIRebalance_Profile", "LINE"]
        ] call Waldo_fnc_AITweak;
    };
    [] call Waldo_fnc_ImprovedHelicopterLandingInit;
    [] call Waldo_fnc_HelicopterDecelerationInit;
};
/*===========================================================================================================================*/

/* HEADLESS CLIENT SUPPORT
 * Detects whether this machine is a connected headless client and, if so, registers it with the
 * server so eligible AI groups are distributed to it automatically - no per-feature mission-maker
 * workaround needed. Has no effect on the server or on players. Gated on the same ordered
 * feature-runtime snapshot handshake as AI rebalance/helicopter landing above, so a joining headless
 * client never registers before it has a consistent runtime picture.
 */
[] spawn {
    waitUntil {
        missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]
        || {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotFailed", false]}
    };
    if !(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]) exitWith {};
    [] call Waldo_fnc_HeadlessDetectLocal;
};
/*===========================================================================================================================*/


/*
ACRE2 communications and Babel are authored only in MissionConfig\acreConfig.sqf. Do not call the
radio setup from this file. Pre-init registers labels/languages, initServer publishes one plan, and
initPlayerLocal applies each player's radios and CEOI after ACRE is ready. That separation prevents
JIP clients from replacing the server plan or retuning somebody else's radios.
*/


/*===========================================================================================================================*/

/*
Localised Radio Jamming (ACRE2 / TFAR)

Area-denial radio jamming for both ACRE2 and TFAR. A "jammer" is any object with a radius: radios
inside its field (ACRE2) or players standing in it (TFAR) lose comms, with a linear falloff at the
edge. You can jam everyone or only chosen sides, and (ACRE2 only) restrict it to frequency bands.

Set up jammers however suits you:
- From an object's init field in Eden:      [this] call Waldo_fnc_Jammer;                  // 300 m, jams all
                                            [this, 500, "EAST"] call Waldo_fnc_Jammer;      // 500 m, OPFOR only
- From a trigger / script:                  [myTower, 800, "ALL", [[30,88]]] call Waldo_fnc_Jammer;
- Live from Zeus ("Waldos Mission Modules"): Radio Jammer - Place / Toggle Nearest / Remove Nearest.

Toggle or remove later with [ref, active] call Waldo_fnc_JammerToggle; and [ref] call Waldo_fnc_JammerRemove;
(ref = the jammer object or the id returned by Waldo_fnc_Jammer).

ACRE2 note: your ACRE2 signal model must be "LOS Multipath" (the default) or "Arcade" for jamming to
apply. Full guide: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Radio-Jamming

The feature installs its radio engines only while enabled; with no jammers placed it has no effect.
Set Waldo_Jamming_Enable to false to disable it entirely; Waldo_Jamming_Notify controls the on-screen
jamming meter players see when they enter a field.

Model options (tune the realism/gameplay to taste):
- Waldo_Jamming_LOS            true  = terrain/hills block the jamming field (line of sight)
- Waldo_Jamming_BurnThrough    true  = higher-power radios (e.g. PRC-117F) resist jamming, shrinking
                                       the effective field; Waldo_Jamming_BurnThroughRef is the mW
                                       reference power (a radio at this power is fully affected)
- Waldo_Jamming_Curve          "LINEAR" or "INVSQ" edge falloff
- Waldo_Jamming_Destructible   true  = destroying a jammer's object removes it (EW objectives)
- Waldo_Jamming_GmOverlay      false = optional curator-only jammer marker and facing line
- Waldo_Jamming_ScanRange      hard detection cap (m); RDF reports only sources whose active field currently reaches the operator
- Waldo_Jamming_ScanBearingArc width (deg) of the reported bearing sector
- Waldo_Jamming_ScanDistanceBands absolute metre thresholds for VERY CLOSE / NEARBY / DISTANT; beyond the third is VERY DISTANT
- Waldo_Jamming_DisableChallenge false = legacy instant engineer disable; true = shared field procedure
- Waldo_Jamming_DisableChallengeId "circuit" and Waldo_Jamming_DisableDifficulty "standard"
- Waldo_Jamming_DisableEngineerOnly true = server and client both require ACE engineer capability
- Waldo_Jamming_DisableResult "DISABLE" preserves the emitter for curator reactivation; "DESTROY" removes it
- Waldo_Jamming_AllowPlayerToggle true = legacy direct toggle on non-challenge emitters only
*/
// Authoritative jamming configuration is established once in initServer.sqf and
// consumed by each joining player in initPlayerLocal.sqf. Do not broadcast defaults
// here: init.sqf runs again on JIP clients and would overwrite live server/Zeus state.


/*===========================================================================================================================*/

/*
Vehicle function eventhandler

This adds vehicle functions to affected vehicles:
- Get out on specfic side. Only affects RHS gear so far.
- Auto added medical/logistics status to vehicles.  Only affects RHS gear so far.
- HALO / Static line [WIP] Only affects RHS gear so far.

*/
call Waldo_fnc_InitVehicles;

/*

Sets team colour based on contents of role description.
Colour selections are RED,BLUE,GREEN,YELLOW.
Name Selections are ALPHA,BRAVO,CHARLIE,DELTA - which maps to colours as in colour selections.
Role selections are SQUAD Leader (Yellow), MEDIC (Green).

Currently based on the first word in the role description.

So Squad Leader will trigger assignment as Yellow but Viking Squad Leader will not- will likely refine this later.

*/
if (hasInterface) then {call Waldo_fnc_SetTeamColour};

/*===========================================================================================================================*/

/*
Introduction Text - Cool Introduction stuff like location, date, time and mission name and locale

Player presentation; installed from initPlayerLocal.sqf, not here (this file also runs on the
dedicated server, which has no display 46 to present anything on). Content and timing are mission
settings in MissionConfig\interfaceConfig.sqf, not call-site parameters - see that file's
Introduction Text setting-by-setting guide.
*/

/*

waldos Init Completion flag

======DO NOT TOUCH!=====
*/
// Was an unconditional `sleep 10;` ("buffer cycles for other inits to be completed"), not gated on
// any actual check. Audited every WALDO_INIT_COMPLETE consumer in the pack: none of them actually
// depend on this specific duration for correctness - the ones with a real data-readiness dependency
// (starter/supply crates, limited arsenals) already double-check the broadcast
// Logi_MissionScanComplete flag independently; Dynamic AA already has its own bounded queue/retry
// worker; the rest (jamming HUD, safestart HUD) only use this flag as a presentation courtesy ("don't
// draw over the intro"), not a safety dependency. A blind sleep with no check was strictly worse than
// waiting on the real signal: it could still fire before the loadout scan finished on a slow server,
// and it unconditionally cost ~10s even when the mission was ready in ~1s (confirmed against a real
// playtest RPT). Bounded so a mission that somehow never completes the scan doesn't hang forever -
// same 60s ceiling used for the WALDO_INIT_COMPLETE wait inside infoText.sqf.
private _initCompleteScanDeadline = diag_tickTime + 60;
waitUntil {
    sleep 0.2;
    missionNamespace getVariable ["Logi_MissionScanComplete", false] || {diag_tickTime >= _initCompleteScanDeadline}
};
if !(missionNamespace getVariable ["Logi_MissionScanComplete", false]) then {
    diag_log "[WMP INIT] Logi_MissionScanComplete never became true within the timeout; setting WALDO_INIT_COMPLETE anyway.";
};
// A dedicated server has no local player. Waiting for one here prevented the pack's
// completion flag and any post-start consumers from ever running on that machine.
waitUntil {isDedicated || {!isNull player && {player == player}}};
// Per-machine readiness: a client must not mark the server (or another JIP client)
// complete. Every machine reaches this only after its own shared init chain finishes.
missionNamespace setVariable ["WALDO_INIT_COMPLETE", true];
