# Mission-Maker Resource Scripts

> **Use this page when:** you need the smaller arsenal, damage-monitor, unhiding, or config-inspection helpers.

_Associated Files: MissionScripts\MissionMakerResourceScripts\_

These are optional mission-maker aids. The arsenal exporter, damage monitor and config
logger belong in a test session. The unhiding file is a template for a mission event;
edit its hard-coded group names before using it during play. None is enabled by a WMP
feature toggle.

| Script | Inputs and type | Result | Where it runs |
| --- | --- | --- | --- |
| `ToolkitAceLimitedArsenal.sqf` | No arguments; reads BLUFOR units and their loadouts | Copies an item-class Array to the local clipboard | Mission-maker debug console on an interface client. |
| `vehicleDamageMonitor.sqf` | No arguments; reads local `cursorObject` Object | Starts a local `real_vicwatch` Script handle and displays hit-point damage | Mission-maker debug console while aiming at a vehicle. |
| `ExampleUnhidingScript.sqf` | No arguments; names of groups are edited inside the file | Reveals and enables simulation on those units and vehicles | Server-owned trigger or server script after you adapt it. |
| `DEBUG_GetNameOfModConfigPatch.sqf` | No arguments; reads loaded `CfgPatches` classes | Writes names to the local `.rpt` log | Mission-maker debug session. |

`execVM` returns a Script handle. None of these files returns a WMP object-registration
result. They do not publish JIP state as a feature service; for a live unhiding event,
design its trigger and late-join behaviour for your mission.

## Quick setup: ACE Limited Arsenal Toolkit

**File:** `ToolkitAceLimitedArsenal.sqf`

Generates a ready-to-paste ACE Arsenal items array from the loadouts of all playable units on a given side. Use this when you want to hand-craft a limited arsenal on a box rather than relying on the automatic loadout-scraping system.

### Usage

1. Spawn units in the editor and assign them the loadouts you want available in the arsenal.
2. Start the mission in the editor, then press **Escape** to open the debug console.
3. Paste the script contents into the console and click **Local Execute**.
4. The items array is copied to your clipboard automatically.
5. Paste the output into an object's init field:

```sqf
// Initialise a new box with the items
[this, ["item1","item2","itemN"]] call ace_arsenal_fnc_initBox;

// Add items to a box that already has an arsenal
[this, ["item1","item2","itemN"]] call ace_arsenal_fnc_addVirtualItems;
```

> This method is best for highly curated loadout pools. For mission packs with standard player loadouts, use the automatic [Logistics System](Logistics-System,-Starter-Crates-And-Quartermaster) instead.

## Script reference: Vehicle Damage Monitor

**File:** `vehicleDamageMonitor.sqf`

Displays a live hint showing the damage percentage of every hit-point on a targeted vehicle, updating every 0.2 seconds. Useful for testing armour, vehicle customisation, and confirming which components are damaged by specific weapons.

### Usage

1. Enter the editor or a session where you have debug permissions.
2. Aim your crosshair at the vehicle you want to monitor.
3. Open the debug console, paste the script, and click **Local Execute**.
4. A continuously updating hint appears until the vehicle is destroyed.

As shipped, this helper calls `terminate real_vicwatch` before creating its next watcher. On the first run, `real_vicwatch` may be undefined and produce a script error. It is a debugging aid, not a dependable mission feature. Check the local `.rpt` if it does not start.

## Example Unhiding Script

**File:** `ExampleUnhidingScript.sqf`

A template demonstrating how to un-hide and enable simulation on pre-placed units and vehicles at a specific moment during a mission (e.g. via a trigger). Useful for wave attacks and ambush design where enemies must not be visible or active until triggered.

### Usage

Replace the group variable names in the script (`Attack1HunterVehicleAlphaCrew`, `Attack1HunterAlpha`, etc.) with your own group variable names, then call the script from a trigger's **On Activation** field:

```sqf
[] execVM "MissionScripts\MissionMakerResourceScripts\ExampleUnhidingScript.sqf";
```

The core pattern per group is:

```sqf
{
    private _vehicle = vehicle _x;
    _x hideObjectGlobal false;
    _x enableSimulationGlobal true;
    _vehicle hideObjectGlobal false;
    _vehicle enableSimulationGlobal true;
} forEach (units YourGroupNameHere);
```

## Debug Mod Config Patch Logger

**File:** `DEBUG_GetNameOfModConfigPatch.sqf`

Iterates through every entry in `CfgPatches` and writes each class name to the Arma 3 log (`.rpt` file). Use this to find the exact config patch name for any loaded mod.

### Why You Need This

WMP scripts use config guards to check whether an optional mod is loaded before running mod-specific code:

```sqf
if !(isClass(configFile >> "CfgPatches" >> "acre_main")) exitWith {};
```

If you are writing a guard for a mod whose patch name you do not know, run this script with that mod loaded and search the `.rpt` for the mod's name.

### Usage

1. Load a session with the mod active.
2. Open the debug console, paste the script, and click **Local Execute**.
3. Open your Arma 3 log file (typically `%LOCALAPPDATA%\Arma 3\` or the game directory) and search for the mod name.

## If a resource script does not work

Check that you copied the example for the named script, not just its filename. Replace placeholder object or group names before running it. For the config patch logger, run it with the relevant mod loaded and read the current session's `.rpt`; it does not change WMP settings.

## See also

- [Mission Configuration Reference](Mission-Configuration-Reference)
- [Feature Index](Feature-Tutorials)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
