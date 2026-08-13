# Mission Configuration Reference

> **Use this page when:** you need the authoritative fields and variables used by WMP mission entry files.

This page documents mission entry points and feature configuration lifecycle. Feature defaults live in semantic pure-data files under `MissionConfig`; the three Arma init files retain lifecycle, authority, activation and JIP handling only. See [Feature Configuration Files](Feature-Configuration-Files) for every setting and [Feature Setup and Activation](Feature-Setup-and-Activation) for the difference between automatic features and features that require a registration/creation call.

## Feature configuration directory

- `MissionConfig\featureConfigManifest.sqf` lists the semantic configuration files.
- Each feature file separates guarded `shared`, authoritative `server`, and interface-only `playerLocal` settings where required.
- `MissionConfig\acreConfig.sqf` remains dedicated because ACRE consumes it during CfgFunctions pre-init, before Arma event scripts.
- Each file's `HOW TO READ THE DATA BELOW` section defines its exact row and nested-data schemas;
  inline comments state types, units, valid IDs and whether a value is normal or advanced tuning.

Do not move activation calls, waits, event handlers or public-state ownership into configuration
files. Edit the appropriate MissionConfig file for mission-start policy. A build/generator may set a
value before its guarded default, but ordinary missions should not duplicate settings in an init
file. Live ZEN changes remain authoritative and are not overwritten when a player joins.

### Adding your own feature setup calls

The semantic config directory replaces large blocks of tweakable defaults; it does **not** replace
custom mission composition:

- Put pre-planned shared world registration/creation in `initServer.sqf`: Dynamic AA, gunships,
  paradrop zones, hazards, recovery, resupply hubs, tactical displays and persistent objects.
- Use an editor object's init only where that public function explicitly documents `this` usage
  and repeat-safe/server-routed setup.
- Put custom player-interface behavior in `initPlayerLocal.sqf` only. Do not recreate WMP's
  automatic local handlers there.
- Do not use multiplayer `init.sqf` as a catch-all. It runs on server, headless clients and every
  joining client, so server-owned creation there risks duplicates and stale-state broadcasts.
- Use a server-owned trigger/script or the supported ZEN module for systems created during play.

Copy-ready examples are in [Feature Setup and Activation](Feature-Setup-and-Activation).

---

## description.ext

Located in the mission root. Sets mission metadata, respawn rules, and includes all WMP scripts.

### Identity Fields

```sqf
author      = "YOURNAMEHERE";       // Your name, shown on the loading screen
onLoadName  = "Mission Pack v4.8.0"; // Mission title — also used by Waldo_fnc_InfoText
onLoadMission = "YOURTEXTHERE";     // Mission subtitle
onLoadIntro   = "YOURTEXTHERE";     // Additional intro subtitle
loadScreen    = "Pictures\loading.jpg"; // Replace with your own image
overviewPicture = "Pictures\loading.jpg";
```

> Replace `Pictures\loading.jpg` with a custom image (JPG or PAA). Keep the same filename or update both paths.

### Player Count

```sqf
class Header {
    gameType   = Coop;
    minPlayers = 1;
    maxPlayers = 31;  // set to your actual maximum player count
};
```

### Respawn

```sqf
respawn      = BASE;   // Respawn method. BASE = on a respawn marker/module.
respawnDelay = 20;     // Seconds before a player can respawn
respawnOnStart = -1;   // DO NOT CHANGE — required by the loadout saving system
respawnTemplatesWest[] = {"MenuPosition","Counter"};
respawnTemplatesEast[] = {"MenuPosition","Counter"};
respawnTemplatesGuer[] = {"MenuPosition","Counter"};
respawnTemplatesCiv[]  = {"MenuPosition","Counter"};
```

> `respawnOnStart = -1` is mandatory. Changing it will break loadout saving and respawn behaviour.

### Custom End Screen

```sqf
class CfgDebriefing {
    class End1 {
        title       = "MISSION COMPLETE";
        subtitle    = "Objectives Complete";
        description = "Good Job!";
        pictureBackground = "Pictures\loading.jpg";
    };
};
```

Trigger with: `["end1"] remoteExec ["BIS_fnc_endMission", 0, true];`

See [ENDEX Script & Custom End Screen](ENDEX-Script-&-Custom-End-Screen) for full details.

### Includes (do not remove)

```sqf
#include "MissionScripts\WaldosFunctions.sqf"             // Required — registers all functions
#include "MissionScripts\Logistics\VirtualVehicleDepot\GarageDisplayDefine.hpp"  // VVD GUI
class MissionSQM { #include "mission.sqm" };              // Required for logistics loadout scanning
```

---

## initServer.sqf

Runs **on the server only**. Its server defaults are loaded synchronously from the semantic files under `MissionConfig`; activation and authority remain in `initServer.sqf`.

### Server-Owned Optional Feature Settings

`MissionConfig\logisticsConfig.sqf` defines object-scaling limits and `MissionConfig\airOperationsConfig.sqf` defines Dynamic AA side/faction asset pools. `initServer.sqf` owns the database branch of persistence and system activation. Dynamic AA publishes a read-only copy of its asset catalogues so curator clients can build filtered selectors; all resolution and world mutation remain server-validated.

Dynamic AA pool entries select candidate radar, static-site, mobile-AA and fighter classes. Object scaling defaults to a validated range of `0.1`–`10`, with direct client requests disabled. See [Dynamic Anti-Air](Dynamic-Anti-Air) and [Optional Feature Systems](Optional-Feature-Systems).

Shared hazard presentation defaults live in `MissionConfig\environmentConfig.sqf`: `Waldo_Hazard_NotifyTransitions` enables entry/exit WMP cards and `Waldo_Hazard_NotificationDuration` sets their lifetime. `Waldo_Hazard_ShowStatus` defaults on and uses one continuously updated lower-left specialist panel rather than notification lanes. A profile can override `showStatus`. Optional detector items, nearby detector objects or an advanced awareness condition can hide status and notices from players without the required information source while exposure and damage continue normally.

### Logistics Crate Classnames

**Do not paste the following resulting runtime values into initServer.sqf.** Edit their entries in
`MissionConfig\logisticsConfig.sqf`; the loader publishes them. They are consumed defaults and do
not create crates by themselves.

```sqf
// The crate spawned for supply/ammo requests (Quartermaster and Zeus module)
missionNamespace setVariable ["Logi_SupplyBoxClass", "B_supplyCrate_F", true];

// The crate spawned for medical requests
// Defaults to ACE advanced crate if ACE Medical is loaded, IDAP crate otherwise
missionNamespace setVariable ["Logi_MedicalBoxClass", "ACE_medicalSupplyCrate_advanced", true];
```

Replace the classname string with any crate classname from your mod set.

### Paradrop Thresholds

**Do not paste these resulting runtime values into initServer.sqf.** Edit the SERVER entries in
`MissionConfig\airOperationsConfig.sqf`. A drop zone is still created separately by script/ZEN.

```sqf
// Static Line — jump available between these altitudes and below this speed
missionNamespace setVariable ["WALDO_STATIC_MINALTITUDE", 180,  true]; // metres AGL minimum
missionNamespace setVariable ["WALDO_STATIC_MAXALTITUDE", 350,  true]; // metres AGL maximum
missionNamespace setVariable ["WALDO_STATIC_MAXSPEED",    310,  true]; // km/h maximum
missionNamespace setVariable ["WALDO_STATIC_STATICCHUTE", "NonSteerable_Parachute_F", true]; // chute class (vanilla default)

// HALO — jump available above this altitude
missionNamespace setVariable ["WALDO_PARA_HALOALTITUDE", 1000,  true]; // metres AGL minimum
missionNamespace setVariable ["WALDO_PARA_HALOCHUTE",    "B_Parachute", true]; // chute class
missionNamespace setVariable ["Waldo_Paradrop_DefaultAircraftInvincible", false, true]; // default off
```

For missions running RHS, replace `"NonSteerable_Parachute_F"` with `"rhs_d6_Parachute"` for a steerable static-line chute.

### Safestart

Edit the `Waldo_SafeStart_*` SERVER entries in `MissionConfig\missionSystemsConfig.sqf`. The
snippet below describes resulting runtime state; WMP already starts/publishes it.

When active, freezes all players until you go live. It starts inactive by default, while the Zeus
activate, lift and countdown controls remain available throughout the mission.

```sqf
missionNamespace setVariable ["Waldo_SafeStart_Confine", true, true];   // safe-zone confinement on/off
missionNamespace setVariable ["Waldo_SafeStart_Radius", 75, true];      // per-player radius (metres)
missionNamespace setVariable ["Waldo_SafeStart_ZoneMarker", "", true];  // marker name for one shared zone (else per-player anchor)
missionNamespace setVariable ["Waldo_SafeStart_AutoStart", false, true]; // true = begin under protection
```

See [Safestart](Safestart) for the go-live API and Zeus modules.

### Mission Diagnostics

Edit `Waldo_RunDiagnostics` in `MissionConfig\missionSystemsConfig.sqf`. WMP performs the call;
do not add another diagnostics startup to initServer.sqf.

Runs a read-only server-side configuration sanity check at mission start and reports common WMP misconfigurations to the RPT log (prefixed `[WMP DIAG]`).

```sqf
missionNamespace setVariable ["Waldo_RunDiagnostics", true, true];  // false = silence it for a shipping mission
```

See [Mission Diagnostics](Mission-Diagnostics).

### After-Action Report Tracking

`initServer.sqf` calls `[] call Waldo_fnc_AARTrack;` to start lightweight event-driven tracking (duration, KIA, vehicle losses, friendly fire, fraggers) so the ENDEX popup can show an After-Action Report. Remove the line to disable the report. See [ENDEX & After-Action Report](ENDEX-Script-&-Custom-End-Screen).

---

## init.sqf

Runs on **all clients, headless clients and the server** during the loading-screen transition. Keep only shared configuration and systems whose engine locality can genuinely occur on any machine here.

### Shared Optional Feature Settings

The guarded `Waldo_*` defaults cover persistence policy, field resupply, airborne-gunship defaults, hazardous-environment presets, tree felling, explosive breaching and AI rebalance. The `isNil` guards are intentional: they prevent a joining machine from replacing settings that the server changed during the mission.

Do not move presentation-only settings back here. Player UI/actions belong in `initPlayerLocal.sqf`; server-only limits and pools belong in `initServer.sqf`. See the [Complete Feature Catalogue](Feature-Catalogue).

### Third-Party Player Markers (disabled by default)

```sqf
// Remove the // to enable the legacy player-marker integration
// [] execVM "MissionScripts\ThirdPartyScripts\ThirdPartyScriptInit.sqf";
```

This legacy entry point does not enable WMP's Headless Client manager. Configure the native manager
through `MissionConfig\headlessConfig.sqf`; see [Headless Client Support](Headless-Client-Support).
See [Third-Party Scripts and Player Markers](Third-Party-Scripts-Headless-Client-And-Player-Markers)
for the optional marker settings inside the legacy file.

### Mini Games (table games)

Edit `Waldo_MiniGames_Enable` in `MissionConfig\missionSystemsConfig.sqf`. The lifecycle block
shown below is already part of WMP and is explanatory only; do not duplicate it in your init.sqf.

```sqf
Waldo_MiniGames_Enable = true;     // false = don't install the seated table-games engine
if (Waldo_MiniGames_Enable) then {
    [] call Waldo_fnc_MiniGamesInit;
};
```

Installs the seated multiplayer party-games engine. The single-player [interaction challenges](Waldos-Mini-Games-Interaction-Challenges) (bomb defusal, hacking, lockpicking, etc.) register themselves on first use and are **not** affected by this flag. See [Waldos Mini Games](Waldos-Mini-Games).

### ACE Corpse Traps (disabled by default)

Edit `Waldo_CorpseTraps_Enable` in `MissionConfig\missionSystemsConfig.sqf`. The lifecycle block
below is already installed by WMP when enabled.

```sqf
Waldo_CorpseTraps_Enable = false;
if (Waldo_CorpseTraps_Enable) then {
    [] call Waldo_fnc_CorpseTrapInit;
};
```

Set the flag to `true` to let players consume carried throwables and conceal them on corpses. The
trap activates when somebody opens the corpse's inventory. See [ACE Corpse Traps](ACE-Corpse-Traps).

### ACE Drag/Carry Weight Limits

These global policy values are exposed in `MissionConfig\missionSystemsConfig.sqf`. The shown
assignments are resulting values, not extra init.sqf setup.

```sqf
ACE_maxWeightDrag  = 10000;  // max weight in grams a player can drag
ACE_maxWeightCarry = 6000;   // max weight in grams a player can carry
```

Tune these so players can drag and carry logistics crates in-game.

### AI Rebalance

Edit the enable/profile/mode/filter entries in `MissionConfig\aiConfig.sqf`. WMP starts and follows
AI locality automatically; do not repeat the initialization in init.sqf.

```sqf
Waldo_AIRebalance_Enable = true;
Waldo_AIRebalance_Mode = "DAY";       // DAY | NIGHT
Waldo_AIRebalance_Profile = "LINE";   // LINE default | MILITIA | VETERAN | ELITE | LEGACY compatibility
```

Only one profile should be active at a time. AI rebalance initialises wherever AI can be local, including headless clients, and reapplies after locality migration. See [Waldos AI Rebalance](Waldos-AI-Tweak) for filters, variance, and restoration.

### ACRE2 Radio Setup

Edit the pure-data `MissionConfig\acreConfig.sqf`. Each side defines an existing ACRE side preset, logical net keys and group assignments. The pack automatically loads it during pre-init, server init and player-local init; no call belongs in multiplayer `init.sqf`.

`enabled` gates the complete replacement lifecycle. `prc343PresetPolicy` defaults to `FULL_RANGE`, preserving all sixteen PRC-343 blocks while other radios retain their official side presets; `SIDE_ISOLATED` reduces combat-side PRC-343 presets to five blocks. Group changes refresh the CEOI but never rewrite radios. Built-in radio capabilities live in code. `additionalRadioProfiles` is an advanced escape hatch for a tested third-party carried radio. Unknown radios and vehicle racks are preserved.

A net is `[key, label, radio family, one value]`; it never contains separate per-radio channels. A
group is `[group ID, assignment rows]`, and every assignment is
`[base class, "ALL" or same-type occurrence, target, ear]`. Use `ALL` only when every radio of that
class is identical. If duplicate radios differ, number every intended occurrence; combining `ALL`
and numbered rows for one class is rejected. This includes PRC-343 block/channel and ear setup.

### ACRE2 Long-Range Channel Names (CEOI)

```sqf
["WEST", "default3", [
    ["PLT1", "PLATOON 1", "PRC_LR", 2],
    ["AIRGND", "AIR-GND", "PRC_LR", 6]
], [
    ["VIKING-2-3", [
        ["ACRE_PRC343", 1, [2, 3], "LEFT"],
        ["ACRE_PRC148", "ALL", "PLT1", "RIGHT"],
        ["ACRE_PRC152", 1, "PLT1", "RIGHT"],
        ["ACRE_PRC152", 2, "AIRGND", "LEFT"]
    ]]
]]
```

`PRC_LR` covers PRC-148/152/117F because their official side presets interoperate at matching channel
numbers. BF-888S, SEM52SL and legacy frequency radios use separate families. Validation rejects a
family mismatch, a channel outside the specifically assigned radio's capacity, or an invalid
frequency range/step. A net needs at least one capable radio in its declared family, but a less-capable
radio does not invalidate that net until the mission assigns that radio to it. A blank
A PRC-343 row whose target is `[]` requests deterministic callsign allocation; explicit
`[block, channel]` reserves it.

### ACRE2 Babel (optional — disabled by default)

```sqf
["languages", [["common", "Common"], ["en", "English"], ["ru", "Russian"], ["fr", "French"], ["ar", "Arabic"]]],
["sideDefaults", [["WEST", ["common", "en"], "en"], ["EAST", ["common", "ru"], "ru"]]],
["unitOverrides", [
    [["UID", "7656119..."], ["common", "en", "ru"], "ru"],
    [["VARIABLENAME", "interpreter_1"], ["common", "en", "ru"], "ru"]
]]
```

Set the `babel` map's `enabled` value to `true`. IDs are registered in declared order on every
machine. `UID` follows a Steam account; `VARIABLENAME` matches the current playable unit's Eden
Variable Name. Override rows are first-match-wins. See [ACRE2 Babel Configuration](ACRE2-Babel-Configuration).

### Radio Jamming (ACRE2 / TFAR)

Edit these settings in `MissionConfig\electronicWarfareConfig.sqf`. The block below documents the
published runtime values and must not be copied into init.sqf/initServer.sqf. Enablement starts the
service but creates no jammer; register an object, call a creation script, or use ZEN. The current
disable result values are `DISABLE` (repairable/reactivatable) and `DEACTIVATE` (ordinary off).

```sqf
Waldo_Jamming_Enable = true;                                           // false = feature off entirely
missionNamespace setVariable ["Waldo_Jamming_Notify", true, true];     // on-screen jamming HUD + chat feedback
missionNamespace setVariable ["Waldo_Jamming_LOS", true, true];        // terrain blocks the field
missionNamespace setVariable ["Waldo_Jamming_BurnThrough", true, true];// stronger radios resist jamming
missionNamespace setVariable ["Waldo_Jamming_BurnThroughRef", 500, true];
missionNamespace setVariable ["Waldo_Jamming_Curve", "LINEAR", true];  // or "INVSQ"
missionNamespace setVariable ["Waldo_Jamming_Destructible", true, true];// destroy the object = remove jammer
missionNamespace setVariable ["Waldo_Jamming_GmOverlay", false, true]; // opt in to curator jammer markers
missionNamespace setVariable ["Waldo_Jamming_ScanRange", 3000, true];  // RDF hard cap; source must also actively affect the operator
missionNamespace setVariable ["Waldo_Jamming_ScanBearingArc", 30, true]; // quantised bearing-sector width (deg)
missionNamespace setVariable ["Waldo_Jamming_ScanDistanceBands", [35, 150, 600], true]; // metre thresholds: very close / nearby / distant
missionNamespace setVariable ["Waldo_Jamming_AllowPlayerToggle", true, true]; // legacy direct toggle on non-challenge jammers
missionNamespace setVariable ["Waldo_Jamming_DisableChallenge", true, true]; // active jammers require the disable procedure
missionNamespace setVariable ["Waldo_Jamming_DisableChallengeId", "circuit", true];
missionNamespace setVariable ["Waldo_Jamming_DisableDifficulty", "standard", true];
missionNamespace setVariable ["Waldo_Jamming_DisableEngineerOnly", false, true]; // set true to require ACE engineers
missionNamespace setVariable ["Waldo_Jamming_DisableResult", "DISABLE", true]; // or DEACTIVATE
```

On by default; does nothing until a jammer is placed. Drop a jammer from an object init field with `[this] call Waldo_fnc_Jammer;`, from a script/trigger, or live from the Zeus "Radio Jammer" modules. The optional disable challenge connects the jammer to the shared field-procedure framework while keeping completion and radio state server-authoritative. Supports terrain line-of-sight, radio-power burn-through, directional cones, pulsing, optional UAV/drone jamming, destructible "blow the tower" jammers, ACE player actions and a handheld RDF scanner. ACRE2 needs the LOS Multipath or Arcade signal model. See [Radio Jamming](Radio-Jamming) for the full API.

The related **EMP burst** (`Waldo_fnc_EMP`) and **signal trackers** (`Waldo_fnc_Tracker`) are on-demand — no init configuration, just script/Zeus calls. See [EW: EMP & Signal Trackers](Electronic-Warfare-EMP-And-Signal-Trackers).

### Introduction Text

```sqf
["", ""] call Waldo_fnc_InfoText;
// First param: custom title (blank = use onLoadName from description.ext)
// Second param: custom location (blank = use worldName)
```

### Briefing Documents

```sqf
call Waldo_fnc_AddDocs;  // remove or comment to disable all briefing documents
```

### Team Colour Assignment

```sqf
call Waldo_fnc_SetTeamColour;  // remove to disable automatic ACE team colour assignment
```

---

## initPlayerLocal.sqf

Runs **once locally when each player joins**. Respawn behavior is handled by the event handlers installed here.

### Player-Local Optional Feature Settings

Treatment-feedback presentation, tactical-display access, emergency-dismount behavior and
WMP HUD eligibility/presentation are loaded here, but mission makers edit their values in
`MissionConfig\interfaceConfig.sqf`. ZEN custom modules are registered here because only interface
clients consume them. Do not copy these settings into initPlayerLocal.sqf.

Player-local feature activation waits for an ordered server runtime snapshot. This ensures a mid-mission ZEN change is applied before a joining player installs actions, displays or event handlers.

```sqf
// The listed UID always qualifies; other players require configured campaign equipment.
Waldo_WmpHud_Enable = true;
Waldo_WmpHud_AccessibilityUIDs = ["76561198094931408"];
Waldo_WmpHud_Facewear = ["G_Goggles_VR"];
Waldo_WmpHud_Font = "PuristaBold";
```

Colour-vision presentation is selected personally through **ACE Self Interact > WMP Interface > Accessibility > Colour Vision Settings** and stored in `profileNamespace` as `Waldo_UI_ColourVisionProfile`. Do not publish it from `initServer.sqf` or overwrite it in `init.sqf`; it is intentionally different for each player. Scripted local selection is available when building another accessibility UI:

```sqf
["RED_GREEN", true] call Waldo_fnc_UiColourVisionApplyLocal;
```

See [Optional Feature Systems](Optional-Feature-Systems) for the complete setting groups.

### Global UI Visual Style

Set `Waldo_UI_Theme` in `MissionConfig\interfaceConfig.sqf` to `DEFAULT`, `WW2`, `VIETNAM`,
`SCIFI`, `PARCHMENT` or `MINIMAL`. Do not redeclare it in init.sqf. The setting changes presentation only and is consumed
by WMP displays. Curator QA can change it live and the server publishes that durable selection for
JIP. See [UI Visual Themes](UI-Visual-Themes).

### Improved AI Helicopter Landings

`Waldo_ImprovedHelicopterLanding_Enable` controls the AI-only exact landing system. The remaining `Waldo_ImprovedHelicopterLanding_*` values tune activation range, glideslope, canopy clearance, collective limits, touchdown tolerance, final-approach commitment and go-around policy. `FinalCommitDistance` prevents vanilla LAND-waypoint completion from cancelling a flare already in progress. Event-driven class-init and `Local` handlers cover editor, Zeus and migrated helicopters on their current owner. See [Improved AI Helicopter Landings](Improved-AI-Helicopter-Landings).

### AI Helicopter Deceleration

`Waldo_HelicopterDeceleration_Enable` controls the separate cruise-braking climb helper and defaults
to `false`. It applies bounded local impulses only when an AI aircraft is losing speed, gaining
height and pitching up above the configured terrain-clearance envelope. Supported landing orders
always reserve the aircraft for Improved Landing, so the two controllers cannot compete. VTOL
support has a separate opt-in. See [AI Helicopter Deceleration](AI-Helicopter-Deceleration).

### Zeus Enhanced Modules

`Waldo_fnc_ZenInitModules` is called automatically on interface clients. The function is repeat-safe and exits when Zeus Enhanced is unavailable.

### Respawn With Death Loadout

Uncomment to have players respawn with whatever they were carrying when they died:

```sqf
["CAManBase", "Killed", {
    params ["_unit"];
    if (_unit == player) then {
        [_unit, [player, "Waldo_Player_Inventory"]] call BIS_fnc_saveInventory;
    };
}] call CBA_fnc_addClassEventHandler;
```

### Save Loadout on Arsenal Close

Uncomment to automatically save the player's respawn loadout whenever they close the ACE Arsenal:

```sqf
["ace_arsenal_displayClosed", {
    [player, [missionNamespace, "Waldo_Player_Inventory"]] call BIS_fnc_saveInventory;
}] call CBA_fnc_addEventHandler;
```

See [Loadout Saving and Respawn](Loadout-Saving-and-Respawn) for full details.

Temporary squad-owned respawn points are configured with the shared `Waldo_Rally_*` settings in
`MissionConfig\missionSystemsConfig.sqf`. Vehicle-recovery settings live in
`MissionConfig\logisticsConfig.sqf`; workshop/vehicle/carrier objects are registered separately.
Object registration and runtime options are documented in [Vehicle Recovery and Squad Rally Points](Vehicle-Recovery-And-Squad-Rallies).

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
