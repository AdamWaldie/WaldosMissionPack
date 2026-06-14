# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WaldosMissionPack (WMP) is an **Arma 3 mission scripting starter framework**. It is not a traditional software project — it is a drop-in collection of SQF scripts, config files, and tooling that Arma 3 mission makers use to get automated logistics, radio setup, paradrop, AI tuning, Zeus modules, and other features without writing those systems from scratch. It is designed to ease new mission makers into the craft.

The pack is used by 40+ milsim units. Mission makers are the primary audience — they configure the scripts through the init files and Eden Editor, not by writing new code.

**Required Arma 3 mods:** CBA_A3, ACE 3  
**Optional:** ACRE 2, TFAR, Zeus Enhanced, LAMBS series

**Wiki (feature and Zeus module tutorials):** https://github.com/AdamWaldie/WaldosMissionPack/wiki

---

## SQF Language Basics

SQF is Arma 3's scripting language. Key syntax rules for editing these files:

- Statements end with `;`
- Variables are prefixed with `_` for local (`_myVar`) or stored in `missionNamespace` for global
- Functions are called with `[args] call functionName` (synchronous) or `[args] spawn functionName` (new thread)
- `#include "path"` pastes another file's content at compile time
- Comments: `// line comment` or `/* block comment */`
- No tabs — spaces only (the validator flags tab characters)
- Strings use either `"double"` or `'single'` quotes

---

## Validation & Linting

These run automatically on every push/PR via `.github/workflows/testing.yml`. Both Python scripts exit non-zero on error and block CI:

```bash
# SQF syntax validation — checks bracket matching, semicolons, tabs
python3 releaseVerificationAndDeployment/sqf_validator.py

# Config/HPP bracket validation — checks .cpp and .hpp files
python3 releaseVerificationAndDeployment/config_style_checker.py
```

The sqflint job runs alongside these but `continue-on-error: true` — it never blocks CI due to false positives.

Run both Python validators locally before pushing any SQF changes.

---

## Build & Release

```bash
# Standard dev build (interactive — prompts before packing)
python3 releaseVerificationAndDeployment/build.py

# CI/automated build (non-interactive, used by deploy workflow)
python3 releaseVerificationAndDeployment/build.py --deploy

# Build a specific variant (e.g. exemplar mission)
python3 releaseVerificationAndDeployment/build.py --build config_ExemplarMission.json
```

Build config: `releaseVerificationAndDeployment/config.json` — controls excluded paths (`notlist`) and the output name/version. Output zips land in `release/`. The deploy workflow triggers on GitHub release publish and uploads 5 artifacts: main WMP pack, patch, Compositions, Unit Insignias, and Exemplar Mission.

---

## Architecture

### Function Registration

Every callable function is declared in `MissionScripts/WaldosFunctions.sqf` via Arma 3's `CfgFunctions` system. That file is `#include`-d by `description.ext`, which causes Arma 3 to preload all functions at mission start.

**Naming rule:** all functions are `Waldo_fnc_FunctionName` (CamelCase suffix). The class name in `WaldosFunctions.sqf` must match the suffix exactly. Adding a new function requires two steps: (1) create the `.sqf` file, (2) add the class entry to `WaldosFunctions.sqf`.

### Mission Execution Flow

```
Mission load
  └─ description.ext          → #includes WaldosFunctions.sqf (registers all Waldo_fnc_*)
        │                       #includes GarageDisplayDefine.hpp (VVD GUI)
        │                       #includes mission.sqm (for loadout system)
        │
        ├─ initServer.sqf       (server only)
        │     ├─ Sets supply/medical box classnames in missionNamespace
        │     ├─ Sets paradrop altitude/speed/chute variables
        │     └─ [] call Waldo_fnc_SideBaseLoadoutSetup
        │           └─ Scans mission.sqm for all playable unit loadouts per side
        │               Stores as Logi_MissionSQMArray_West/East/Ind/Civ
        │
        ├─ init.sqf             (all clients + server, on loading screen transition)
        │     ├─ [] call Waldo_fnc_ZenInitModules     (Zeus Enhanced custom modules)
        │     ├─ "DAY"/"NIGHT" call Waldo_fnc_AITweak (AI skill adjustment)
        │     ├─ [_RadioSetups] call Waldo_fnc_ACRE2Init (radio channel assignment)
        │     ├─ call Waldo_fnc_InitVehicles           (vehicle action setup)
        │     ├─ call Waldo_fnc_AddDocs                (briefing documents)
        │     ├─ call Waldo_fnc_SetTeamColour          (squad colour by role)
        │     ├─ ["",""] call Waldo_fnc_InfoText        (intro title screen)
        │     └─ Sets WALDO_INIT_COMPLETE flag
        │
        └─ initPlayerLocal.sqf  (per-player, on each join/respawn)
              ├─ Saves starting loadout via BIS_fnc_saveInventory
              ├─ Adds "Flip Vehicle" action
              └─ CBA Respawn event → restores saved loadout + re-adds flip action
```

### Key Global Variables (missionNamespace)

| Variable | Set in | Purpose |
|---|---|---|
| `WALDO_INIT_COMPLETE` | `init.sqf` | Signals client init is done; scripts should `waitUntil` on this |
| `Logi_MissionSQMArray_West/East/Ind/Civ` | `initServer.sqf` | Unique loadout arrays scraped from mission.sqm |
| `Logi_SupplyBoxClass` / `Logi_MedicalBoxClass` | `initServer.sqf` | Classnames of spawnable crates |
| `WALDO_STATIC_MINALTITUDE` etc. | `initServer.sqf` | Paradrop altitude/speed thresholds |
| `Waldo_Player_Inventory` | `initPlayerLocal.sqf` | Per-player saved loadout |
| `Waldo_ACRE2Setup_LRChannels_BLUFOR` etc. | `init.sqf` | ACRE2 channel name arrays per side |

---

## Feature Configuration Guide

This section covers the systems mission makers configure. All configuration lives in the init files — not in the script files themselves.

### Loadout & Logistics System (Critical)

The supply/logistics system is driven entirely by playable unit loadouts in `mission.sqm`:

- `initServer.sqf` scans all playable units via `Waldo_fnc_SideBaseLoadoutSetup`, extracts weapons/ammo/clothing/items, deduplicates, and stores globally
- These arrays power supply crate contents, limited ACE arsenals, and Zeus logistics modules
- **IMPORTANT:** Unit loadouts **must** be edited using ACE Arsenal in the Eden Editor — vanilla default loadouts produce empty/incomplete crates
- **IMPORTANT:** Mission binarization must be **disabled** (right-click mission in editor → Properties → uncheck Binarize) for `mission.sqm` to be readable

Custom crate classnames (in `initServer.sqf`):
```sqf
missionNamespace setVariable ["Logi_SupplyBoxClass", "B_supplyCrate_F", true];
missionNamespace setVariable ["Logi_MedicalBoxClass", "ACE_medicalSupplyCrate_advanced", true];
```

### AI Skill Adjustment (`init.sqf`)

```sqf
"DAY" call Waldo_fnc_AITweak;    // daytime missions
// "NIGHT" call Waldo_fnc_AITweak; // nighttime missions (comment/uncomment to switch)
```

Night mode applies faction-aware and role-aware tuning: units without NVGs get severely reduced spotting; NVG-equipped units get enhanced night effectiveness; snipers and machine gunners get role-specific accuracy boosts. Works with Zeus-spawned units via CBA class event handlers.

### ACRE2 Radio Setup (`init.sqf`)

```sqf
private _RadioSetups = [
    ["Viking-1-1", [1,5]],   // [group name, [LR channel numbers]]
    ["Viking 5",   [2,7]],
    ["Banshee",    [4,1]]
];
[_RadioSetups] call Waldo_fnc_ACRE2Init;
```

Group names must match exactly what is set in Eden Editor. Channel numbers reference the position in the `Waldo_ACRE2Setup_LRChannels_BLUFOR/OPFOR/IND/CIV` arrays (1-indexed). AN/PRC-343 short-range radios are assigned automatically based on squad numerical designations. CEOI auto-populates in the map screen.

### Paradrop Configuration (`initServer.sqf`)

Most "Plane"-class assets automatically get HALO/static-line actions. Override thresholds here:
```sqf
missionNamespace setVariable ["WALDO_STATIC_MINALTITUDE", 180, true];  // metres
missionNamespace setVariable ["WALDO_STATIC_MAXALTITUDE", 350, true];
missionNamespace setVariable ["WALDO_STATIC_MAXSPEED", 310, true];     // km/h
missionNamespace setVariable ["WALDO_STATIC_STATICCHUTE", "rhs_d6_Parachute", true];
missionNamespace setVariable ["WALDO_PARA_HALOALTITUDE", 1000, true];
missionNamespace setVariable ["WALDO_PARA_HALOCHUTE", "B_Parachute", true];
```

For custom aircraft that don't auto-detect, add in the object's init field in Eden Editor:
```sqf
[this] call Waldo_fnc_VehicleJumpSetup;
```

### MHQ / Mobile Command Post (Eden Editor)

1. Place a vehicle (or static object) with a variable name, e.g. `MHQ_1`
2. Place a Game Logic near it
3. Place tent/crate objects you want deployed — **sync each one to the Logic** (not the vehicle)
4. Raise ground-placed objects ~1ft if using a vehicle (accounts for suspension settling)
5. In the vehicle's init field:
```sqf
[this] call Waldo_fnc_MHQSetup;
// or with options:
[this, true, true, 180, 4] call Waldo_fnc_MHQSetup;
// params: [vehicle, modernAudio, enableLogistics, logiBearing, logiDistance]
```
Players get ACE3 "Deploy/Tear Down Command Post" actions. Deployed state creates a named respawn point and map marker.

### Respawn Options (`initPlayerLocal.sqf`)

Two optional behaviours are commented out by default — uncomment to enable:

```sqf
// Save loadout when closing ACE Arsenal (respawn with chosen kit):
["ace_arsenal_displayClosed", {
    [player, [missionNamespace, "Waldo_Player_Inventory"]] call BIS_fnc_saveInventory;
}] call CBA_fnc_addEventHandler;

// Respawn with what you died with (instead of starting kit):
["CAManBase", "Killed", {
    params ["_unit"];
    if (_unit == player) then {
        [_unit, [player, "Waldo_Player_Inventory"]] call BIS_fnc_saveInventory;
    };
}] call CBA_fnc_addClassEventHandler;
```

### ENDEX / Mission End

```sqf
[] spawn Waldo_fnc_ENDEX;
```

Freezes the mission: broadcasts "ENDEX ENDEX ENDEX", locks all weapons (ACE safety mode), heals all players, deletes fired rounds, sets all AI to CARELESS/BLUE, makes all players invincible. Also accessible via the Zeus Enhanced "Call Endex" module.

The ENDEX hint also shows an **After-Action Report** when AAR tracking is running. Tracking is started automatically from `initServer.sqf` via `[] call Waldo_fnc_AARTrack`, which registers a single `EntityKilled` mission event handler (fires on all machines, so server-side registration captures every kill). If `Waldo_AAR_StartTime` is unset the ENDEX simply omits the AAR block.

The AAR reports: mission **duration**, **KIA** per side, **player losses**, **vehicles lost** per side, **WIA** per side, **friendly-fire** incidents, an **objective summary**, and a **top-fraggers** leaderboard. Each extra line is omitted when its tally is empty. Details:
- *Vehicle losses / friendly fire / fraggers* come from the same `EntityKilled` handler, which now also reads `_killer`/`_instigator`: a kill where instigator and victim share a side counts as friendly fire; an enemy kill by a human player feeds the leaderboard (`Waldo_AAR_Frags`).
- *WIA* requires **ACE medical**. An `ace_unconscious` listener registered in `init.sqf` (runs on all machines) forwards each unit's first unconsciousness to the server via `Waldo_fnc_AARWound`, so each wounded unit is counted once.
- *Objective summary* is populated automatically when objectives are created with `Waldo_fnc_CreateObjective` / resolved with `Waldo_fnc_SetObjectiveState` (they maintain the broadcast `Waldo_AAR_Tasks` ledger).

For a custom end screen, configure `CfgDebriefing` → `End1` in `description.ext`, then trigger with `[[], "End1"] call BIS_fnc_endMission;`.

### Safestart (optional)

Freezes all players at mission start — the reversible mirror of ENDEX. While active: weapons are safe and every shot/grenade/launcher/vehicle-weapon round is deleted, players take and deal **no damage**, players are **confined to a safe zone**, and an on-screen **banner** (with a live go-live countdown when a timer is running) is shown. JIP and respawning players are re-frozen automatically.

Auto-starts from `initServer.sqf` (set the flag to false to start the mission live):
```sqf
missionNamespace setVariable ["Waldo_SafeStart_Confine", true, true];   // safe-zone confinement on/off
missionNamespace setVariable ["Waldo_SafeStart_Radius", 75, true];      // per-player radius (metres)
missionNamespace setVariable ["Waldo_SafeStart_ZoneMarker", "", true];  // marker name for one shared zone (else per-player anchor)
missionNamespace setVariable ["Waldo_SafeStart_AutoStart", true, true]; // false = no safestart at start
```

Scripting API (server-authoritative — safe to call from a client, it forwards to the server):
```sqf
[true]  call Waldo_fnc_SafeStart;        // activate
[false] call Waldo_fnc_SafeStart;        // go live (admin overrule; also cancels any countdown)
[300]   call Waldo_fnc_SafeStartTimer;   // go live automatically in 300s (banner shows the clock)
```

Zeus ("Waldos Mission Modules"): **Safestart - Activate**, **Safestart - Go Live (Lift)**, and **Safestart - Start Go-Live Countdown** (prompts for minutes). The countdown can be overruled at any time with the Lift module. Implemented in `MissionScripts/MissionFlowAndUi/safeStart.sqf`, `safeStartTimer.sqf`, `safeStartApply.sqf`.

### Mission Diagnostics (optional)

Runs a server-side configuration sanity check at mission start (after the loadout scan) and reports the most common WMP misconfigurations to the RPT log (lines prefixed `[WMP DIAG]`), echoing warnings to admins via `systemChat`. It is read-only — it never changes mission state.

```sqf
// In initServer.sqf — set to false to silence it for a shipping mission:
missionNamespace setVariable ["Waldo_RunDiagnostics", true, true];
```

Checks: required mods present (CBA, ACE); per-side loadout scrapes not empty when that side has playable slots (catches vanilla loadouts / binarized `mission.sqm`); supply/medical crate classnames are valid `CfgVehicles` classes; paradrop thresholds sane and parachute classes valid; ACRE2 LR channel arrays populated (only if ACRE2 loaded). Implemented in `MissionScripts/MissionFlowAndUi/runDiagnostics.sqf` (`Waldo_fnc_RunDiagnostics`).

### Tasks / Objectives (scripting helper)

A thin, JIP-safe wrapper over the BIS task framework for mission makers who drive objectives from SQF/triggers (the Eden and Zeus task modules remain the GUI option). Server-authoritative — calling on a client forwards to the server automatically.

```sqf
// Create an assigned task with a persistent map marker at the destination:
["secure_lz", west, "Secure the LZ", "Clear and hold the landing zone.", getMarkerPos "lz1"]
    call Waldo_fnc_CreateObjective;

// Later, resolve it (also removes the helper-created marker):
["secure_lz", "SUCCEEDED"] call Waldo_fnc_SetObjectiveState;
```

Params for `Waldo_fnc_CreateObjective`: `[taskId, owner, title, description, destination, state, createMarker, taskType]`. See the script headers in `MissionScripts/MissionFlowAndUi/createObjective.sqf` and `setObjectiveState.sqf`.

### Virtual Vehicle Depot (VVD) — WIP

```sqf
[spawnerObject, helipad, types, allowedSides, sideCheck, removeUavs, range, script]
    call Waldo_fnc_VVDInit;
// types: ["Auto"], ["Ground"], ["All"] or specific type strings
// allowedSides: ["ALL"], ["BLUFOR"], ["OPFOR"], ["INDEP"], ["CIV"]
```

This feature is explicitly marked **WIP and not recommended for live missions**. UAV removal is unreliable (~50%) due to an Arma engine limitation around UAV crew/connection lifecycle — it is not a simple scripting bug and has no robust fix. For a stable vehicle-spawning experience use **ACE Garage** instead. If you do use VVD, test thoroughly with your exact mod set first.

### Zeus Enhanced Modules

```sqf
[] call Waldo_fnc_ZenInitModules; // already called in init.sqf
```

Registers "Waldos Mission Modules" in the Zeus module menu: Player Supply Crate, Field Hospital Crate, Call Endex, Custom Mission End, Fortify Budget Manager, Spawn AI Convoy. Silently does nothing if Zeus Enhanced is not loaded.

---

## description.ext — Mission Maker Checklist

The fields mission makers should always edit before using the pack:

```
author          = "YOURNAMEHERE";
onLoadName      = "Mission Pack v4.7.2";   // mission title
onLoadMission   = "YOURTEXTHERE";
maxPlayers      = 31;                       // set to your playercount
respawnDelay    = 20;                       // seconds
```

Replace `Pictures\loading.jpg` with a custom loading screen image.

**Do not change** `respawnOnStart = -1` — it is required by the loadout saving system.

---

## MissionScripts Directory Layout

- `MissionInit/` — ACRE2 radio setup, vehicle action setup, team colour helpers, briefing document templates
- `Logistics/` — The largest module: supply/medical crates, loadout saving, MHQ, teleport, fortification, vehicle camo, virtual vehicle depot, map location tools
- `AiScripting/` — AI skill adjustment (`AITweak`) and convoy system (`SimpleAiConvoy`)
- `MissionFlowAndUi/` — ENDEX, info text overlays, respawn messages, timed hints
- `Paradrop/` — HALO and static-line jump system (8 scripts: setup, equipment simulation, vehicle jump config)
- `ZenModules/` — Zeus Enhanced custom modules for logistics and ENDEX
- `ThirdPartyScripts/` — Headless client and player marker integrations (disabled by default via commented-out line in `init.sqf`)

---

## Mod API Reference

This section documents how each mod integrates with WMP so scripts can be read and extended without prior Arma 3 mod knowledge.

### CBA_A3 (Community Base Addons) — Required

CBA is the event system backbone. WMP uses it for all unit lifecycle hooks.

**Key functions used:**

| Function | Where used | What it does |
|---|---|---|
| `CBA_fnc_addClassEventHandler` | `initPlayerLocal.sqf`, `AISkillAdjustmentSystem.sqf` | Fires a callback whenever any unit of the given class triggers an event (e.g. "Respawn", "Killed", "InitPost"). Used to re-apply loadouts on respawn and to initialise AI skills for Zeus-spawned units. |
| `CBA_fnc_addEventHandler` | `initPlayerLocal.sqf` | Fires on a named game event (e.g. `ace_arsenal_displayClosed`). Used for the optional "save loadout on arsenal close" feature. |
| `CBA_fnc_execNextFrame` | `ZenModules/` | Defers code by one frame — used so Zeus curator objects exist before being referenced. |
| `CBA_fnc_notify` | `Paradrop/paraEquipmentSim.sqf`, `checkForJumpSettings.sqf` | Brief on-screen notification. Used to tell jumpers what equipment was lost on exit. |
| `CBA_fnc_setPos` / `CBA_fnc_setHeight` | `teleport.sqf` | Position setters used by the teleport system. |
| `CBA_fnc_hashCreate` / `CBA_fnc_hashGet` | `GetSRChannelName.sqf` | Key-value store mapping squad callsigns to ACRE2 channel data. |

**Call pattern:** `["ClassName", "EventName", { params ["_unit"]; ... }] call CBA_fnc_addClassEventHandler`

---

### ACE3 (Advanced Combat Environment) — Required

ACE3 is the most heavily used dependency (~80 call sites across 20+ files). WMP uses it for all player-facing interaction menus, medical system, logistics, and weapon safety.

**Interaction menus** — every deployable action (MHQ, vehicle camo, construction, quartermaster, paradrop settings) is an ACE scroll-wheel action:
```sqf
private _action = [id, displayName, icon, code, condition, insertCode]
    call ace_interact_menu_fnc_createAction;
[object, isVehicleAction, pathArray, _action]
    call ace_interact_menu_fnc_addActionToObject;
```

**Progress bars** — timed deploy/teardown actions use:
```sqf
[duration, title, condition, completionCode, cancelCode]
    call ace_common_fnc_progressBar;
```

**Arsenal** — limited arsenals restricted to mission loadouts:
```sqf
[box, true]          call ace_arsenal_fnc_initBox;         // full ACE Arsenal on a box
[box, itemsArray]    call ace_arsenal_fnc_addVirtualItems; // restrict to specific items
```

**Cargo / dragging** — crates are made portable:
```sqf
[object, spaceValue] call ace_cargo_fnc_setSpace;
[object, sizeValue]  call ace_cargo_fnc_setSize;
[object, true]       call ace_dragging_fnc_setDraggable;
[object, true]       call ace_dragging_fnc_setCarryable;
```

**Fortification:**
```sqf
[side, objectClassArray, budget] call ace_fortify_fnc_registerObjects;
[side, delta]                    call ace_fortify_fnc_updateBudget;
```

**ENDEX (weapon lock + healing):**
```sqf
[player, true] call ace_safemode_fnc_lockSafety;
[player]       call ace_medical_treatment_fnc_fullHeal;
```

**Drag/carry weight limits** (set in `init.sqf`):
```sqf
ACE_maxWeightDrag  = 10000;
ACE_maxWeightCarry = 6000;
```

**Mod detection pattern** — used throughout to guard ACE-dependent code:
```sqf
if (isClass(configFile >> "CfgPatches" >> "ace_main")) then { ... };
if (isClass(configFile >> "CfgPatches" >> "ace_medical")) then { ... };
```

**Key ACE object variables:**
- `ace_medical_isMedicalFacility` — marks a crate as a field hospital
- `ace_medical_isMedicalVehicle` — marks a vehicle as medical
- `ACE_isEngineer` / `ace_medical_medicClass` — read by briefing documents

---

### ACRE2 (Advanced Combat Radio Environment 2) — Default radio mod

ACRE2 provides realistic radio simulation. WMP auto-assigns radios per squad on spawn. All ACRE2 scripting lives in `MissionScripts/MissionInit/ACRE2/`.

**Detection guard** — every ACRE2 script exits immediately if the mod is absent:
```sqf
if !(isClass(configFile >> "CfgPatches" >> "acre_main")) exitWith { systemChat "ACRE2 Mod Not Enabled"; };
```

**Radio classnames and stereo assignment:**

| Class | Type | Ear |
|---|---|---|
| `ACRE_PRC343` | Short-range squad radio | LEFT |
| `ACRE_PRC152` | Long-range handheld | RIGHT |
| `ACRE_PRC148` | Long-range handheld (alt) | RIGHT |
| `ACRE_PRC117F` | HF backpack/vehicle radio | CENTER |

**Key API calls:**
```sqf
// Check radio model
[radioObj, "ACRE_PRC343"] call acre_api_fnc_isKindOf;

// Tune channel and set stereo position
[radioObj, channelNumber] call acre_api_fnc_setRadioChannel;
[radioObj, "LEFT"]        call acre_api_fnc_setRadioSpatial; // LEFT / RIGHT / CENTER

// Get all radios currently carried by the player
[] call acre_api_fnc_getCurrentRadioList;

// Configure preset channel fields (used in legacy init path)
[radioObj, presetName, channelIndex, "label", value]       call acre_api_fnc_setPresetChannelField;
[radioObj, presetName, channelIndex, "frequencyTX", value] call acre_api_fnc_setPresetChannelField;

// Apply a preset to radios
[radioObj, presetName] call acre_api_fnc_setPreset;

// Wait until ACRE has fully initialised before assigning channels
waitUntil { [] call acre_api_fnc_isInitialized };
```

**Babel (multilingual) API** (`BabelActivation.sqf`):
```sqf
[languageName]          call acre_api_fnc_babelAddLanguageType;
[unit, languagesArray]  call acre_api_fnc_babelSetSpokenLanguages;
```

**Known ACRE2 limitation:** channel _naming_ via `setPresetChannelField` `"label"` does not display in-game — it causes radio inconsistency. Channel names are maintained only in the CEOI map entry; radios are numbered only. The label-setting code in `ACRE2Init.sqf` is commented out for this reason.

**Initialisation sequence in `ACRE2Init.sqf`:**
1. `Waldo_fnc_SquadLevelRadios` runs first to compute SR channel assignments per callsign and sets `Waldo_ACRE2Setup_CallsignChannelAssignments_flag`
2. `waitUntil { acre_api_fnc_isInitialized && callsign flag }` blocks until both are ready
3. PRC343 (SR) assigned from the computed callsign map → LEFT ear; removed from radio list
4. PRC152/148/117F (LR) assigned in order from the `_RadioAssignments` channel array → RIGHT/CENTER; array is popped as each radio is assigned to prevent duplicates
5. Loadout saved via `Waldo_fnc_SaveLoadout` so channels persist through respawn
6. CEOI populated via `Waldo_fnc_CreateACRECEOI`

---

### TFAR (Task Force Arrowhead Radio) — Optional, no scripting required

TFAR has **inherent Eden Editor support** — it assigns radios via the 3Den unit properties panel, not through scripts. WMP has zero TFAR function calls.

The one point of integration: `missionFileLookup.sqf` reads the `radio` inventory slot from `mission.sqm` when scraping unit loadouts. This slot captures TFAR radio classnames placed via Eden, so they flow into supply crates automatically alongside all other items — no extra scripting needed.

---

### Zeus Enhanced — Optional

Zeus Enhanced adds a custom module category inside the Zeus editor. WMP exits silently if ZEN is absent:
```sqf
if !(isClass(configFile >> "CfgPatches" >> "zen_main")) exitWith {};
```

**Two ZEN functions are used:**
```sqf
// Register a module — appears in Zeus editor under the given category
[category, moduleName, code, iconPath] call zen_custom_modules_fnc_register;

// Show a parameter input dialog to the Zeus operator
[title, parametersArray] call zen_dialog_fnc_create;
```

**Registered modules** (all under "Waldos Mission Modules"):
- Player Supply Crate → calls `Waldo_fnc_ZenSupplySpawner`
- Field Hospital Crate → calls `Waldo_fnc_ZenMedicalSpawner`
- Call Endex → `remoteExec ["Waldo_fnc_ENDEX", 0, true]`
- Custom Mission End → `["end1"] remoteExec ["BIS_fnc_endMission", 0, true]`
- Fortify Budget Manager → calls `Waldo_fnc_FortifyBudgetModule`
- Spawn AI Convoy → calls `Waldo_fnc_ZenConvoyModule` (turns the nearest crewed land-vehicle group into a managed convoy via `Waldo_fnc_SimpleAiConvoy`)
- Loadout Save Point → calls `Waldo_fnc_ZenLoadoutSaveModule`
- Safestart - Activate → `[true] remoteExec ["Waldo_fnc_SafeStart", 2]`
- Safestart - Go Live (Lift) → `[false] remoteExec ["Waldo_fnc_SafeStart", 2]`
- Safestart - Start Go-Live Countdown → calls `Waldo_fnc_ZenSafeStartTimer` (prompts for minutes, then `Waldo_fnc_SafeStartTimer`)

---

## Codebase Conventions

### Script file header

Every `.sqf` file in `MissionScripts/` opens with a documentation block:
```sqf
/*
 * Author: Waldo
 * One-line description of what this script does.
 *
 * Arguments:
 * _param1 - Type - Description
 * _param2 - Type - Description (optional, default: value)
 *
 * Return Value:
 * Nothing / description of return
 *
 * Example:
 * [this, true, false] call Waldo_fnc_FunctionName;
 */
```
Read this header before editing any script — it documents all valid arguments.

### Argument parsing

All functions use `params` at the top to unpack `_this`:
```sqf
// Required params
params ["_target", "_side"];

// With optional params and defaults
params ["_target", ["_audio", false], ["_logistics", false], ["_direction", 180]];
```

### Guard clauses

Scripts open with early-exit guards before any logic:
```sqf
if !(isServer) exitWith {};                                          // server-only script
if !(hasInterface) exitWith {};                                      // client-only script
if !(isClass(configFile >> "CfgPatches" >> "ace_main")) exitWith {}; // mod not loaded
```

### Execution locality

- `call` — synchronous, runs in current thread, returns a value
- `spawn` — starts a new thread, non-blocking, cannot return a value; used for long-running or sleep-containing code
- `remoteExec` — runs on other machines: `[args, "functionOrCommand", targets] remoteExec`
  - target `0` = all machines; `-2` = all clients; `2` = server only
  - third arg `true` = persistent (re-runs for JIP players)

### Global variables

All global state is stored in `missionNamespace`:
```sqf
missionNamespace setVariable ["Waldo_VARNAME", value, true]; // true = broadcast to all clients
missionNamespace getVariable ["Waldo_VARNAME", defaultValue];
```

Prefix convention: `Waldo_` for WMP variables, `Logi_` for logistics system variables, `WALDO_` (all caps) for flags/thresholds.

### Function naming and registration

All functions follow `Waldo_fnc_FunctionName` (CamelCase after the prefix). Adding a new function requires:
1. Create the `.sqf` file in the appropriate `MissionScripts/` subdirectory
2. Add a matching class entry to `MissionScripts/WaldosFunctions.sqf` — the class name must match the suffix exactly

### Formatting

- **No tabs** — spaces only. The validator flags tab characters in SQF files.
- Strings use either `"double"` or `'single'` quotes — both are valid in SQF; be consistent within a file.
- Statements end with `;` — the validator checks for missing semicolons after closing `}`.
