# Mission Configuration Reference

> **Use this page when:** you need the authoritative fields and variables used by WMP mission entry files.

This page documents all configuration fields and variables mission makers are expected to customise before shipping a WMP mission. Feature defaults now live in the clearly separated `MissionConfig` directory; the three Arma init files retain lifecycle, authority, activation and JIP handling only.

## Feature configuration directory

- `MissionConfig\SharedFeatureDefaults.sqf` contains guarded defaults needed on every machine.
- `MissionConfig\ServerFeatureDefaults.sqf` contains server-owned limits, pools and JIP-safe published defaults.
- `MissionConfig\PlayerLocalFeatureDefaults.sqf` contains interface-only presentation and interaction defaults.
- Root `acreConfig.sqf` remains separate because ACRE consumes it during CfgFunctions pre-init, before Arma event scripts.

Do not move activation calls, waits, event handlers or public-state ownership into configuration files. Set a variable before its guarded default when generating a mission, or edit the corresponding locality file. Live ZEN changes remain authoritative and are not overwritten when a player joins.

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

Runs **on the server only**. Its server defaults are loaded synchronously from `MissionConfig\ServerFeatureDefaults.sqf`; activation and authority remain in `initServer.sqf`.

### Server-Owned Optional Feature Settings

`MissionConfig\ServerFeatureDefaults.sqf` defines object-scaling limits and Dynamic AA side/faction asset pools. `initServer.sqf` owns the database branch of persistence and system activation. Dynamic AA publishes a read-only copy of its asset catalogues so curator clients can build filtered selectors; all resolution and world mutation remain server-validated.

Dynamic AA pool entries select candidate radar, static-site, mobile-AA and fighter classes. Object scaling defaults to a validated range of `0.1`–`10`, with direct client requests disabled. See [Dynamic Anti-Air](Dynamic-Anti-Air) and [Optional Feature Systems](Optional-Feature-Systems).

Shared hazard presentation defaults live in `MissionConfig\SharedFeatureDefaults.sqf`: `Waldo_Hazard_NotifyTransitions` enables entry/exit WMP cards and `Waldo_Hazard_NotificationDuration` sets their lifetime. Individual zone profiles can override both without changing other zones.

### Logistics Crate Classnames

```sqf
// The crate spawned for supply/ammo requests (Quartermaster and Zeus module)
missionNamespace setVariable ["Logi_SupplyBoxClass", "B_supplyCrate_F", true];

// The crate spawned for medical requests
// Defaults to ACE advanced crate if ACE Medical is loaded, IDAP crate otherwise
missionNamespace setVariable ["Logi_MedicalBoxClass", "ACE_medicalSupplyCrate_advanced", true];
```

Replace the classname string with any crate classname from your mod set.

### Paradrop Thresholds

```sqf
// Static Line — jump available between these altitudes and below this speed
missionNamespace setVariable ["WALDO_STATIC_MINALTITUDE", 180,  true]; // metres AGL minimum
missionNamespace setVariable ["WALDO_STATIC_MAXALTITUDE", 350,  true]; // metres AGL maximum
missionNamespace setVariable ["WALDO_STATIC_MAXSPEED",    310,  true]; // km/h maximum
missionNamespace setVariable ["WALDO_STATIC_STATICCHUTE", "rhs_d6_Parachute", true]; // chute class

// HALO — jump available above this altitude
missionNamespace setVariable ["WALDO_PARA_HALOALTITUDE", 1000,  true]; // metres AGL minimum
missionNamespace setVariable ["WALDO_PARA_HALOCHUTE",    "B_Parachute", true]; // chute class
```

For non-RHS missions, replace `"rhs_d6_Parachute"` with `"NonSteerable_Parachute_F"` (vanilla).

### Safestart

Freezes all players at mission start until you go live. Auto-starts by default.

```sqf
missionNamespace setVariable ["Waldo_SafeStart_Confine", true, true];   // safe-zone confinement on/off
missionNamespace setVariable ["Waldo_SafeStart_Radius", 75, true];      // per-player radius (metres)
missionNamespace setVariable ["Waldo_SafeStart_ZoneMarker", "", true];  // marker name for one shared zone (else per-player anchor)
missionNamespace setVariable ["Waldo_SafeStart_AutoStart", true, true]; // false = start the mission live
```

See [Safestart](Safestart) for the go-live API and Zeus modules.

### Mission Diagnostics

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

### Third-Party Scripts (disabled by default)

```sqf
// Remove the // to enable headless client and player markers
// [] execVM "MissionScripts\ThirdPartyScripts\ThirdPartyScriptInit.sqf";
```

See [Headless Client & Player Markers](Third-Party-Scripts-Headless-Client-And-Player-Markers) for the options inside that file.

### Mini Games (table games)

```sqf
Waldo_MiniGames_Enable = true;     // false = don't install the seated table-games engine
if (Waldo_MiniGames_Enable) then {
    [] call Waldo_fnc_MiniGamesInit;
};
```

Installs the seated multiplayer party-games engine. The single-player [interaction challenges](Waldos-Mini-Games-Interaction-Challenges) (bomb defusal, hacking, lockpicking, etc.) register themselves on first use and are **not** affected by this flag. See [Waldos Mini Games](Waldos-Mini-Games).

### ACE Corpse Traps (disabled by default)

```sqf
Waldo_CorpseTraps_Enable = false;
if (Waldo_CorpseTraps_Enable) then {
    [] call Waldo_fnc_CorpseTrapInit;
};
```

Set the flag to `true` to let players consume carried throwables and conceal them on corpses. The
trap activates when somebody opens the corpse's inventory. See [ACE Corpse Traps](ACE-Corpse-Traps).

### ACE Drag/Carry Weight Limits

```sqf
ACE_maxWeightDrag  = 10000;  // max weight in grams a player can drag
ACE_maxWeightCarry = 6000;   // max weight in grams a player can carry
```

Tune these so players can drag and carry logistics crates in-game.

### AI Rebalance

```sqf
Waldo_AIRebalance_Enable = true;
Waldo_AIRebalance_Mode = "DAY";       // DAY | NIGHT
Waldo_AIRebalance_Profile = "LINE";   // LINE default | MILITIA | VETERAN | ELITE | LEGACY compatibility
```

Only one profile should be active at a time. AI rebalance initialises wherever AI can be local, including headless clients, and reapplies after locality migration. See [Waldos AI Rebalance](Waldos-AI-Tweak) for filters, variance, and restoration.

### ACRE2 Radio Setup

Edit the pure-data root `acreConfig.sqf`. Each side defines an existing ACRE side preset, logical net keys and group assignments. The pack automatically loads it during pre-init, server init and player-local init; no call belongs in multiplayer `init.sqf`.

`retuneOnGroupChange` defaults to `false`, named displays default to enabled, and `strict` defaults to `true`. `radioPriority` determines which supported carried radio consumes each ordered group net. `radioProfiles` may extend known third-party carried radios; unknown radios and vehicle racks are not guessed or modified.

### ACRE2 Long-Range Channel Names (CEOI)

```sqf
["WEST", "default3", [
    ["PLT1", "PLATOON 1", []],
    ["AIRGND", "AIR-GND", []]
], [
    ["VIKING-1-1", ["PLT1", "AIRGND"], [1, 1]]
]]
```

Group net keys drive both radio channels and the CEOI. The optional final `[block, channel]` is a strict PRC-343 override.

### ACRE2 Babel (optional — disabled by default)

```sqf
["languages", [["en", "English"], ["fr", "French"]]],
["sideDefaults", [["WEST", ["en", "fr"], "en"]]],
["unitOverrides", [[["UID", "7656119..."], ["en", "fr"], "fr"]]]
```

Set the `babel` map's `enabled` value to `true`. IDs are registered in declared order on every machine. See [ACRE2 Babel Configuration](ACRE2-Babel-Configuration).

### Radio Jamming (ACRE2 / TFAR)

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
missionNamespace setVariable ["Waldo_Jamming_DisableChallenge", false, true]; // opt in globally; Zeus-created jammers default on
missionNamespace setVariable ["Waldo_Jamming_DisableChallengeId", "circuit", true];
missionNamespace setVariable ["Waldo_Jamming_DisableDifficulty", "standard", true];
missionNamespace setVariable ["Waldo_Jamming_DisableEngineerOnly", true, true];
missionNamespace setVariable ["Waldo_Jamming_DisableResult", "DISABLE", true]; // or DESTROY
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

Treatment-feedback presentation, tactical-display access, emergency-dismount behavior and accessibility PID eligibility/presentation are configured here. ZEN custom modules are also registered here because only interface clients consume them.

Player-local feature activation waits for an ordered server runtime snapshot. This ensures a mid-mission ZEN change is applied before a joining player installs actions, displays or event handlers.

```sqf
// Enabled only for the listed player IDs by default; [] allows every player.
Waldo_AccessibilityPID_Enable = true;
Waldo_AccessibilityPID_AllowedUIDs = ["76561198094931408"];
Waldo_AccessibilityPID_Font = "PuristaBold";
```

Colour-vision presentation is selected personally through **ACE Self Interact > WMP Interface > Accessibility > Colour Vision Settings** and stored in `profileNamespace` as `Waldo_UI_ColourVisionProfile`. Do not publish it from `initServer.sqf` or overwrite it in `init.sqf`; it is intentionally different for each player. Scripted local selection is available when building another accessibility UI:

```sqf
["RED_GREEN", true] call Waldo_fnc_UiColourVisionApplyLocal;
```

See [Optional Feature Systems](Optional-Feature-Systems) for the complete setting groups.

### Global UI Visual Style

Set `Waldo_UI_Theme` in `init.sqf` to `DEFAULT`, `WW2`, `VIETNAM` or `SCIFI`. The setting changes presentation only and is consumed locally by WMP displays. Curator QA can change it live through **UI QA - Set Visual Theme**; the server publishes the durable selection for JIP. See [UI Visual Themes](UI-Visual-Themes).

### Improved AI Helicopter Landings

`Waldo_ImprovedHelicopterLanding_Enable` controls the AI-only exact landing system. The remaining `Waldo_ImprovedHelicopterLanding_*` values tune activation range, glideslope, canopy clearance, collective limits, touchdown tolerance, final-approach commitment and go-around policy. `FinalCommitDistance` prevents vanilla LAND-waypoint completion from cancelling a flare already in progress. Event-driven class-init and `Local` handlers cover editor, Zeus and migrated helicopters on their current owner. See [Improved AI Helicopter Landings](Improved-AI-Helicopter-Landings).

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

Temporary squad-owned respawn points are configured with the shared `Waldo_Rally_*` settings in `init.sqf`; vehicle-recovery scans use `Waldo_Recovery_ScanInterval`, workshop-completion notification distance uses `Waldo_Recovery_NotificationRadius` (default 100 metres), `Waldo_Recovery_PlacementClearance` pads the combined workshop/vehicle footprints, and `Waldo_Recovery_CreateWorkshopMarkers` controls the default global delivery-area and exact-position workshop markers. Object registration and runtime options are documented in [Vehicle Recovery and Squad Rally Points](Vehicle-Recovery-And-Squad-Rallies).

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
