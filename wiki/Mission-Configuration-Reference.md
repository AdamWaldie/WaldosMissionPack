This page documents all the configuration fields and variables that mission makers are expected to customise before shipping a mission built on WMP. It covers `description.ext`, `init.sqf`, and `initServer.sqf`.

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

See [ENDEX Script & Custom End Screen](https://github.com/AdamWaldie/WaldosMissionPack/wiki/ENDEX-Script-&-Custom-End-Screen) for full details.

### Includes (do not remove)

```sqf
#include "MissionScripts\WaldosFunctions.sqf"             // Required — registers all functions
#include "MissionScripts\Logistics\VirtualVehicleDepot\GarageDisplayDefine.hpp"  // VVD GUI
class MissionSQM { #include "mission.sqm" };              // Required for logistics loadout scanning
```

---

## initServer.sqf

Runs **on the server only**. Configure logistics crate classnames and paradrop thresholds here.

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

See [Safestart](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Safestart) for the go-live API and Zeus modules.

### Mission Diagnostics

Runs a read-only server-side configuration sanity check at mission start and reports common WMP misconfigurations to the RPT log (prefixed `[WMP DIAG]`).

```sqf
missionNamespace setVariable ["Waldo_RunDiagnostics", true, true];  // false = silence it for a shipping mission
```

See [Mission Diagnostics](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Mission-Diagnostics).

### After-Action Report Tracking

`initServer.sqf` calls `[] call Waldo_fnc_AARTrack;` to start lightweight event-driven tracking (duration, KIA, vehicle losses, friendly fire, fraggers) so the ENDEX popup can show an After-Action Report. Remove the line to disable the report. See [ENDEX & After-Action Report](https://github.com/AdamWaldie/WaldosMissionPack/wiki/ENDEX-Script-&-Custom-End-Screen).

---

## init.sqf

Runs on **all clients and the server** during the loading screen transition. Enable, disable and configure the majority of WMP features here.

### Third-Party Scripts (disabled by default)

```sqf
// Remove the // to enable headless client and player markers
// [] execVM "MissionScripts\ThirdPartyScripts\ThirdPartyScriptInit.sqf";
```

See [Headless Client & Player Markers](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Third-Party-Scripts-Headless-Client-And-Player-Markers) for the options inside that file.

### Zeus Enhanced Modules

```sqf
[] call Waldo_fnc_ZenInitModules;  // remove this line to disable Zeus modules
```

### ACE Drag/Carry Weight Limits

```sqf
ACE_maxWeightDrag  = 10000;  // max weight in grams a player can drag
ACE_maxWeightCarry = 6000;   // max weight in grams a player can carry
```

Tune these so players can drag and carry logistics crates in-game.

### AI Mode

```sqf
"DAY" call Waldo_fnc_AITweak;   // uncomment for daytime missions
// "NIGHT" call Waldo_fnc_AITweak; // uncomment for nighttime missions
```

Only one should be active at a time. See [Waldos AI Tweak](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-AI-Tweak) for full detail.

### ACRE2 Radio Setup

```sqf
private _RadioSetups = [
    ["Viking-1-1", [1, 5]],   // [group callsign, [LR channel numbers]]
    ["Viking 5",   [2, 7]],
    ["Banshee",    [4, 1]]
];
[_RadioSetups] call Waldo_fnc_ACRE2Init;
```

Channel numbers refer to the index (1-based) in the `_LongRangeRadioChannels_*` arrays below.

### ACRE2 Long-Range Channel Names (CEOI)

```sqf
_LongRangeRadioChannels_BLUFOR = ["PLATOON 1","PLATOON 2","PLATOON 3","COMPANY","AIR 2 GROUND","AIR 2 AIR","CAS 1","CAS 2","CFF 1","CFF 2","CONVOY 1"];
missionNamespace setVariable ["Waldo_ACRE2Setup_LRChannels_BLUFOR", _LongRangeRadioChannels_BLUFOR];
// repeat for OPFOR, IND, CIV
```

Position in the array = channel number. These names appear in the in-game CEOI document.

### ACRE2 Babel (optional — disabled by default)

```sqf
/*
[
    [
        [west, "English", "French"],
        [east, "Russian"],
        [civilian, "French"]
    ]
] call Waldo_fnc_BabelActivation;
*/
```

Remove the `/*` and `*/` to enable. See [ACRE2 Babel Configuration](https://github.com/AdamWaldie/WaldosMissionPack/wiki/ACRE2-Babel-Configuration).

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

Runs **per player on each join and respawn**. Two optional respawn behaviours are commented out by default.

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

See [Loadout Saving and Respawn](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Loadout-Saving-and-Respawn) for full details.
