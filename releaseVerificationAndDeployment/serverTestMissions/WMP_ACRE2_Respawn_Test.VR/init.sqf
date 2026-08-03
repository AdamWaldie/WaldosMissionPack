/*
 * Author: WaldoTheWarfighter
 * Defines shared WMP mission configuration and starts systems whose state or behavior is consumed
 * on every machine. Guarded defaults preserve authoritative live changes for JIP clients.
 *
 * Arguments: None.
 * Return Value: Nothing; initializes shared mission state and schedules feature startup.
 *
 * Example: Arma executes init.sqf automatically during mission initialization.
 * Current caller: the Arma mission initialization sequence on server, clients and headless clients.
*/

//Lighting Setup Engine - Optional
//"LightShafts" ppEffectAdjust [0.9, 0.8, 0.9, 0.8];

//Third Party Scripts (Look at mentioned file to enable
//[] execVM "MissionScripts\ThirdPartyScripts\ThirdPartyScriptInit.sqf";


// Pure-data shared feature configs are synchronous and repeat-safe. Runtime authority remains below.
["SHARED"] call Waldo_fnc_LoadFeatureConfigs;
missionNamespace setVariable ["Waldo_SharedFeatureConfigReady", true];
if (isServer) then {
    missionNamespace setVariable ["Waldo_FeatureRuntimeSnapshotReceived", true];
    missionNamespace setVariable ["Waldo_FeatureRuntimeSnapshotFailed", false];
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

A pub-Zeus economy suite: define resources, capturable income zones and collectable crates,
run research at a Research Center, construct and upgrade buildings, and let players buy vehicles.
A trusted "Ground Command" controls spending. Everything is driven live from the Zeus menu
"Waldos Economy Systems" - no editor work required beyond enabling it.

Set the flag below to true to start the economy suite (runs on all machines; it self-branches
between the server authority loops and the client Zeus menu). It is OFF by default so missions
that do not use it pay no cost. You can also enable it without editing this file by dropping the
"[WMP] Waldos Economy Systems" composition (its object boots the suite from its own init).

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

/*
After-Action WIA listener (ACE)

ACE raises "ace_unconscious" locally on the machine owning the unit, so it cannot be caught by the
server-only EntityKilled handler in Waldo_fnc_AARTrack. This all-machines listener forwards each
unit's first unconsciousness to the server (Waldo_fnc_AARWound) so the ENDEX debrief can show WIA
per side. Counts each unit once. Silently absent if ACE medical is not loaded.
*/
if (isClass(configFile >> "CfgPatches" >> "ace_medical")) then {
    ["ace_unconscious", {
        params ["_unit", "_state"];
        if (_state && {local _unit} && {!(_unit getVariable ["Waldo_AAR_Wounded", false])}) then {
            _unit setVariable ["Waldo_AAR_Wounded", true];
            [[west, east, independent, civilian] find (side group _unit)] remoteExec ["Waldo_fnc_AARWound", 2];
        };
    }] call CBA_fnc_addEventHandler;
};

/*===========================================================================================================================*/

/*
AI Tweak setup
These commands initiate Waldos AI Tweaks. It is an Either/OR situation, where the DAY OR NIGHT mode can be active per mission.
Daytime Mission parameter - uncomment this for daytime AI values.
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
};
// Nightime Mission - uncomment this for nightime AI values.
//"NIGHT" call Waldo_fnc_AITweak;


/*===========================================================================================================================*/


/*
ACRE2 communications and Babel are authored in MissionConfig\acreConfig.sqf. CfgFunctions pre-init registers
deterministic preset labels and Babel definitions; initServer.sqf publishes the authoritative plan;
initPlayerLocal.sqf applies carried-radio state, CEOI and local language knowledge. Multiplayer
init.sqf deliberately owns no ACRE defaults, waits or mutable authority.
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

Briefing documents

*/
if (hasInterface) then {call Waldo_fnc_AddDocs};

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

When left with no parameters, as below, the script autogenerates the location based on the terrain name, and the mission title from the description.ext
You can optionally define replacements for the title & location, as is demonstrated in the trigger in the exemplar mission.
*/
// Player presentation requires display 46. Running InfoText on a dedicated server
// waits forever for a display that cannot exist and blocks WALDO_INIT_COMPLETE.
if (hasInterface) then {["",""] call Waldo_fnc_InfoText};

/*

waldos Init Completion flag

======DO NOT TOUCH!=====
*/
sleep 10; // Buffer cycles for other inits to be completed - should not be removed
// A dedicated server has no local player. Waiting for one here prevented the pack's
// completion flag and any post-start consumers from ever running on that machine.
waitUntil {isDedicated || {!isNull player && {player == player}}};
// Per-machine readiness: a client must not mark the server (or another JIP client)
// complete. Every machine reaches this only after its own shared init chain finishes.
missionNamespace setVariable ["WALDO_INIT_COMPLETE", true];
