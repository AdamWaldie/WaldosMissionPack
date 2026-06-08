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

For a custom end screen, configure `CfgDebriefing` → `End1` in `description.ext`, then trigger with `[[], "End1"] call BIS_fnc_endMission;`.

### Virtual Vehicle Depot (VVD) — WIP

```sqf
[spawnerObject, helipad, types, allowedSides, sideCheck, removeUavs, range, script]
    call Waldo_fnc_VVDInit;
// types: ["Auto"], ["Ground"], ["All"] or specific type strings
// allowedSides: ["ALL"], ["BLUFOR"], ["OPFOR"], ["INDEP"], ["CIV"]
```

This feature is explicitly marked WIP. UAV removal is unreliable (~50%). Test thoroughly with your mod set before using in a live mission.

### Zeus Enhanced Modules

```sqf
[] call Waldo_fnc_ZenInitModules; // already called in init.sqf
```

Registers "Waldos Mission Modules" in the Zeus module menu: Player Supply Crate, Field Hospital Crate, Call Endex, Custom Mission End, Fortify Budget Manager. Silently does nothing if Zeus Enhanced is not loaded.

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
| `CBA_fnc_addClassEventHandler` | `initPlayerLocal.sqf`, `AISkillAdjustmentSystem.sqf` | Fires a callback whenever any unit of the given class triggers an event (e.g. "Respawn", "Killed", "InitPost"). Used to re-apply loadouts on respawn and initialise AI skills for Zeus-spawned units. |
| `CBA_fnc_addEventHandler` | `initPlayerLocal.sqf` | Fires on a named game event (e.g. `ace_arsenal_displayClosed`). Used for the optional "save loadout on arsenal close" feature. |
| `CBA_fnc_execNextFrame` | `ZenModules/` | Defers code by one frame — used so Zeus curator objects exist before being referenced. |
| `CBA_fnc_notify` | `Paradrop/paraEquipmentSim.sqf`, `Paradrop/checkForJumpSettings.sqf` | Shows a brief on-screen notification. Used to tell jumpers what equipment was lost. |
| `CBA_fnc_waitUntilAndExecute` | `ACRE2Init_Legacy.sqf` | Waits for a condition, then runs code — used to defer radio assignment until ACRE is initialised. |
| `CBA_fnc_setPos` / `CBA_fnc_setHeight` | `teleport.sqf` | Position setters compatible with CBA's extension system. |
| `CBA_fnc_hashCreate` / `CBA_fnc_hashGet` | `GetSRChannelName.sqf` | Key-value store used to map squad callsigns to ACRE2 channel data. |

**Pattern:** `["ClassName", "EventName", { code }] call CBA_fnc_addClassEventHandler`

---

### ACE3 (Advanced Combat Environment) — Required

ACE3 is the most heavily used dependency (~80 call sites across 20+ files). WMP uses it for all player-facing interaction menus, medical system, logistics, and weapon safety.

**Interaction menus** — all deployable actions (MHQ, vehicle camo, construction, quartermaster, paradrop) are ACE scroll-wheel actions:
```sqf
private _action = [id, displayName, icon, code, condition, insertCode] 
    call ace_interact_menu_fnc_createAction;
[object, isVehicleAction, pathArray, _action] 
    call ace_interact_menu_fnc_addActionToObject;
```

**Progress bars** — timed actions (deploying/tearing down MHQ, attaching camo) use:
```sqf
[duration, title, condition, completionCode, cancelCode] 
    call ace_common_fnc_progressBar;
```

**Arsenal system** — limited arsenals restricted to mission loadouts:
```sqf
[box, true] call ace_arsenal_fnc_initBox;          // open full ACE Arsenal on box
[box, itemsArray] call ace_arsenal_fnc_addVirtualItems;  // restrict to specific items
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

**Mod detection pattern** used throughout the codebase:
```sqf
if (isClass(configFile >> "CfgPatches" >> "ace_medical")) then { ... };
```

**Key ACE variables** set on objects:
- `ace_medical_isMedicalFacility` — marks a crate as a field hospital
- `ace_medical_isMedicalVehicle` — marks a vehicle as medical
- `ACE_isEngineer` / `ace_medical_medicClass` — checked in briefing documents

---

### ACRE2 (Advanced Combat Radio Environment 2) — Optional

ACRE2 provides realistic radio simulation. WMP auto-assigns radios per squad on spawn. The entire system lives in `MissionScripts/MissionInit/ACRE2/`.

**Radio classnames** WMP configures:

| Class | Type | Stereo assignment |
|---|---|---|
| `ACRE_PRC343` | Short-range squad radio | LEFT ear |
| `ACRE_PRC152` | Long-range handheld | RIGHT ear |
| `ACRE_PRC148` | Long-range handheld (alt) | RIGHT ear |
| `ACRE_PRC117F` | HF vehicle/backpack radio | CENTER |

**Key API calls:**
```sqf
// Configure a preset channel slot (label, frequency, name)
[radioObj, presetIndex, channelIndex, "label", txFreq, rxFreq, "channelName"] 
    call acre_api_fnc_setPresetChannelField;

// Apply a built preset to a radio
[radioObj, presetObj] call acre_api_fnc_copyPreset;
[radioObj, presetObj] call acre_api_fnc_setPreset;

// Tune radio and set stereo position
[radioObj, channelNumber] call acre_api_fnc_setRadioChannel;
[radioObj, "LEFT"]         call acre_api_fnc_setRadioSpatial;  // LEFT / RIGHT / CENTER

// Enumerate player's current radios
[] call acre_api_fnc_getCurrentRadioList;

// Check radio type
[radioObj, "ACRE_PRC343"] call acre_api_fnc_isKindOf;
```

**Babel (multilingual) API:**
```sqf
[languageName] call acre_api_fnc_babelAddLanguageType;
[unit, languagesArray] call acre_api_fnc_babelSetSpokenLanguages;
```

**Initialisation guard** — ACRE2 functions check `acre_api_fnc_isInitialized` before running; the legacy init uses `CBA_fnc_waitUntilAndExecute` to defer until ACRE is ready.

---

### Zeus Enhanced (ZEN) — Optional

ZEN adds a custom module menu inside the Zeus editor. WMP silently does nothing if ZEN is not loaded (`isClass(configFile >> "CfgPatches" >> "zen_main")` check in `Zen_initModules.sqf`).

Only two ZEN functions are used:

```sqf
// Register a custom module (appears in Zeus editor module list)
[category, moduleName, iconPath, tooltipText, code] 
    call zen_custom_modules_fnc_register;

// Show a parameter dialog for a module (Zeus operator fills in fields)
[title, parametersArray] call zen_dialog_fnc_create;
```

The five registered modules are: Player Supply Crate, Field Hospital Crate, Call Endex, Custom Mission End, Fortify Budget Manager.

---

### LAMBS (LAMBS Danger / LAMBS Suppression) — Optional, Zero Integration Code

LAMBS is recommended as a companion mod for AI quality, but WMP has **no LAMBS function calls**. The AITweak system (`AISkillAdjustmentSystem.sqf`) adjusts vanilla AI subskills, which then benefit further from LAMBS Danger's behaviour overhaul automatically — no script integration is needed.

---

### Vanilla Arma 3 (BIS) Functions WMP Relies On

These are Arma 3 built-in functions WMP depends on most heavily:

| Function | Used for |
|---|---|
| `BIS_fnc_saveInventory` / `BIS_fnc_loadInventory` | Loadout save/restore on respawn (backbone of `initPlayerLocal.sqf`) |
| `BIS_fnc_addRespawnPosition` / `BIS_fnc_removeRespawnPosition` | MHQ dynamic respawn point creation/removal |
| `BIS_fnc_holdActionAdd` | Paradrop hold-actions on aircraft (jump triggers) |
| `BIS_fnc_attachToRelative` | Attaching MHQ objects, vehicle camo nets, construction pieces |
| `BIS_fnc_relPos` | Computing cargo drop/jump exit positions relative to an object |
| `BIS_fnc_dynamicText` / `BIS_fnc_typeText` | ENDEX and intro screen text overlays |
| `BIS_fnc_blackOut` / `BIS_fnc_blackIn` / `BIS_fnc_startLoadingScreen` | Intro sequence fade effects |
| `BIS_fnc_endMission` | Triggering the `CfgDebriefing` end screen |
| `BIS_fnc_isThrowable` / `BIS_fnc_objectType` | Classifying items when populating supply crates |
| `BIS_fnc_showNotification` | Pop-up notifications (MHQ state changes, etc.) |

---

## Key Conventions

- **No tabs** — use spaces. The validator logs tab characters in SQF files (currently does not count as hard error, but keep them out).
- **Global variables** use `missionNamespace setVariable ["Waldo_VARNAME", value, true]`. The third argument `true` broadcasts to all clients.
- **`WALDO_INIT_COMPLETE`** — set at the end of `init.sqf` after a 10-second buffer. Scripts depending on full client init should `waitUntil {!isNil {missionNamespace getVariable "WALDO_INIT_COMPLETE"}}`.
- **Adding a function:** create the `.sqf` in the right `MissionScripts/` subdirectory, then add a class entry to `MissionScripts/WaldosFunctions.sqf`.
- **Calling style:** `[args] call Waldo_fnc_X` for synchronous execution; `[args] spawn Waldo_fnc_X` for a new thread (non-blocking).
- All script files include documentation headers explaining purpose, parameters, and examples — read them before modifying.
