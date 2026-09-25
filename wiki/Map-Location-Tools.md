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
> the intended inputs; they are not a verified working setup.

Both functions require a **Game Logic** placed in the Eden Editor as a position reference.

---

## Create New Map Location

`Waldo_fnc_CreateMapLocationName` creates a brand-new named location at a game logic's position, independently of any existing Arma 3 map data.

### Setup in Eden

1. Place a **Game Logic** (found in the Modules menu) where you want the location to appear on the map, and give it a variable name (e.g. `FobBartLogic`).
2. After the helper is repaired, call it once from a server-owned setup script or trigger.

### Parameters

| # | Type | Description |
|---|---|---|
| 0 | OBJECT | The game logic object to use as the position reference |
| 1 | STRING | The display name for the new location |
| 2 | STRING | The location type (controls icon and map behaviour — see table below) |

### Example

```sqf
[FobBartLogic, "FOB Bart", "NameVillage"] call Waldo_fnc_CreateMapLocationName;
[MainAirfieldLogic, "Tempest International", "NameLocal"] call Waldo_fnc_CreateMapLocationName;
```

---

## Replace Existing Map Location Name

`Waldo_fnc_ReplaceMapLocationName` finds the nearest existing named location to a game logic and renames it. Use this to rename pre-existing Arma 3 map locations (cities, mountains, airfields).

### Setup in Eden

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

## Common Location Types

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
| `b_hq` | BLUFOR HQ marker icon |
| `o_hq` | OPFOR HQ marker icon |
| `n_hq` | Independent HQ marker icon |

> The full list of available location types is documented inside both `.sqf` files as a commented reference block.

Both calls take three required arguments: a Game Logic Object, a display-name String
and a location-type String. Neither currently provides a documented return value or
safe JIP/repeated-call behaviour. A mission maker should wait for the implementation
fix before depending on either example above.

## If a name does not change

Check whether you are creating a new location or renaming an existing one. The target's map location type and position must match the call you chose. A locally created label may not be visible to other players; use the documented shared setup path when everyone should see it.

## See also

- [Custom 3D World Markers](Custom-3D-World-Markers)
- [Teleport Action](Teleport-Actions)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
