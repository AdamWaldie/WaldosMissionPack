# Map Location Tools

> **Use this page when:** you need to create a map location or replace an existing location name.

_Associated Files:_
- _MissionScripts\Logistics\LogiHelpers\createNewMapLocation.sqf_
- _MissionScripts\Logistics\LogiHelpers\replaceMapLocationName.sqf_

Two functions for modifying the named locations players see on the in-game map. Useful for renaming real-world map locations to fit mission lore, or adding new named points of interest such as FOBs and objectives.

> **Current status:** Do not use these helpers in a live mission yet. The create helper
> refers to an undefined `_editableLocation` when setting the new type. The shipped
> functions also lack a server-only/repeat guard, although this page previously told
> mission makers to call them from multiplayer `init.sqf`. The signatures below record
> the intended inputs. They are not a verified working setup.

Both functions require a **Game Logic** placed in the Eden Editor as a position reference.

## Setup status: not ready for live missions

There is no safe copy-and-paste setup for these helpers in this version. The sections below describe their intended inputs for a maintainer to repair and test. Do not activate them in a live mission.

---

## Create New Map Location

`Waldo_fnc_CreateMapLocationName` is intended to create a named location at a game logic's position. **Do not use the shipped function yet:** it refers to `_editableLocation`, which is not defined in that function. The example below describes the intended call, not a working recipe.

### Intended Eden setup, after repair

1. Place a **Game Logic** where you want the location to appear on the map. Give it a variable name, such as `FobBartLogic`.
2. After the helper is repaired, call it once from a server-owned setup script or trigger.

### Parameters

| # | Type | Description |
|---|---|---|
| 0 | OBJECT | The game logic object to use as the position reference |
| 1 | STRING | The display name for the new location |
| 2 | STRING | The location type. See the table below. |

### Example

```sqf
[FobBartLogic, "FOB Bart", "NameVillage"] call Waldo_fnc_CreateMapLocationName;
[MainAirfieldLogic, "Tempest International", "NameLocal"] call Waldo_fnc_CreateMapLocationName;
```

---

## Replace Existing Map Location Name

`Waldo_fnc_ReplaceMapLocationName` is intended to find a nearby map location and give a new location its name and type. Its multiplayer and repeated-call behaviour has not been verified. Do not assume the shipped helper safely renames an existing location for every player.

### Intended Eden setup, after verification

1. Place a **Game Logic** near the map location you want to rename and give it a variable name.
2. After the helper is repaired, call it once from a server-owned setup script.

### Parameters

| # | Type | Description |
|---|---|---|
| 0 | OBJECT | The game logic object near the location to rename |
| 1 | STRING | The new name to apply |
| 2 | STRING | The new location type |

### Example

```sqf
[AltisAirportLogic, "Al-Rayak Air Base", "NameLocal"] call Waldo_fnc_ReplaceMapLocationName;
[KavalaLogic, "Port Kavala", "NameCity"] call Waldo_fnc_ReplaceMapLocationName;
```

---

## Script contracts and location types

Only types defined in `CfgLocationTypes` will display correctly. Commonly used types are listed below.

| Type | Description |
|---|---|
| `NameCity` | City |
| `NameCityCapital` | Capital city |
| `NameVillage` | Village or small settlement |
| `NameLocal` | Local area name (also used for airports) |
| `NameMarine` | Sea or ocean area |
| `Mount` | Mountain peak |
| `Hill` | Hill |
| `FlatArea` | Open flat terrain |
| `FlatAreaCity` | Urban flat area |
| `Strategic` | Strategic point of interest |
The source comments also mix map-marker icon names such as `b_hq` into a list of possible location types. Do not copy those entries as `CfgLocationTypes` values without checking the terrain and game config. The helpers' current validation logs an invalid type but does not stop execution.

Both calls take three required arguments: a Game Logic Object, a display-name String
and a location-type String. Neither currently provides a documented return value or
safe JIP/repeated-call behaviour. A mission maker should wait for the implementation
fix before depending on either example above.

## If a name does not change

There is no supported shared setup path for these helpers yet. The create function's undefined variable is a known defect, and the replace function has no verified multiplayer or repeat guard. Use a tested map-marker workflow for a live mission, or repair and test these helpers before depending on them.

## See also

- [Custom 3D World Markers](Custom-3D-World-Markers)
- [Teleport Action](Teleport-Actions)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
