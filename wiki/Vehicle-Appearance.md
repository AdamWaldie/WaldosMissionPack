# Vehicle Appearance

> **Use this page when:** you want to recolor a vehicle (a "pink tank"), or show/hide a named physical
> model part (e.g. visually remove a turret cupola), through a script call or Zeus - not weapons/ammo,
> that's [Vehicle Weapon Loadout](Vehicle-Weapon-Loadout).

_Associated Files: `MissionScripts\CombatSystems\VehicleAppearance\vehicleAppearanceApply.sqf`, `vehicleAppearanceInspect.sqf`, `vehicleComponentCatalogRegister.sqf`, `vehicleComponentRemove.sqf`, `MissionScripts\ZenModules\Zen_vehicleAppearanceTextureModule.sqf`, `zenVehicleAppearanceTextureServer.sqf`, `Zen_vehicleAppearanceInspectModule.sqf`, `Zen_vehicleComponentRegisterModule.sqf`, `zenVehicleComponentRegisterServer.sqf`, `Zen_vehicleComponentRemoveModule.sqf`, `zenVehicleComponentRemoveServer.sqf`, `Waldo_fnc_VehicleAppearanceApply`, `Waldo_fnc_VehicleAppearanceInspect`, `Waldo_fnc_VehicleComponentCatalogRegister`, `Waldo_fnc_VehicleComponentRemove`, `Waldo_fnc_ZenVehicleAppearanceTexture`, `Waldo_fnc_ZenVehicleAppearanceTextureServer`, `Waldo_fnc_ZenVehicleAppearanceInspect`, `Waldo_fnc_ZenVehicleComponentRegister`, `Waldo_fnc_ZenVehicleComponentRegisterServer`, `Waldo_fnc_ZenVehicleComponentRemove`, `Waldo_fnc_ZenVehicleComponentRemoveServer`_

There is no `MissionConfig` file for this feature - it's a call/ZEN-only tool, not a global setting.

---

## Overview

Two genuinely separate cosmetic capabilities, both operating on a vehicle's own model/config rather
than its weapon/ammo content (that's [Vehicle Weapon Loadout](Vehicle-Weapon-Loadout) - a different
Arma system entirely):

- **Recoloring** - apply a texture (a bitmap path, a hand-written procedural string, or a flat solid
  colour needing no texture asset at all) to one of a vehicle's own config-declared texture slots.
- **Physical components** - show or hide a named model selection, optionally combined with clearing a
  linked turret's weapon in one action, so "remove this vehicle's turret" means both gone-looking and
  gone-functioning.

Server-authoritative, like the rest of WMP's object-anchored features (`Waldo_fnc_Jammer`,
`Waldo_fnc_VehicleWeaponLoadoutApply`): safe to call from a vehicle's own Eden init field with no
`isServer` wrapper, since the call forwards itself to the server automatically.

**There is no engine query for "this model selection is a removable physical component."** Unlike
weapons (enumerable via `allTurrets`/`weaponsTurret`), a model selection is just a named piece the
vehicle's original author gave it - valid for hiding, or not, with no config flag either way. WMP
therefore ships **no pre-seeded catalog of known removable parts** for any vehicle, vanilla or
otherwise - a wrong selection name presented as fact is worse than none at all. Discover a real
selection name with **Vehicle Appearance - Inspect** first, then optionally save it for reuse with
**Vehicle Appearance - Register Component**.

## Scripting

```sqf
// [vehicle, rows]; each row: [targetType, selector, action, value]
[this, [
    ["TEXTURE", 0, "SET", [1, 0, 1, 1]]   // paint texture slot 0 pink - no texture asset needed
]] call Waldo_fnc_VehicleAppearanceApply;
```

| Field | Type | Meaning |
|---|---|---|
| `targetType` | STRING | `"TEXTURE"` or `"SELECTION"` |
| `selector` | NUMBER or STRING | TEXTURE: a 0-based index into the vehicle's own `hiddenSelections[]` config array. SELECTION: a model selection name, validated against the live `selectionNames vehicle`. |
| `action` | STRING | TEXTURE: `SET` or `CLEAR` (reverts to the vehicle's own default). SELECTION: `HIDE` or `SHOW`. |
| `value` | STRING, ARRAY, or "" | TEXTURE `SET` only: a texture path/procedural string, or an `[R,G,B,A]` array (0..1 each) auto-converted via the engine's own `BIS_fnc_colorRGBAtoTexture`. Ignored everywhere else. |

Multiple rows apply independently in one call - a bad row (out-of-range texture index, unknown
selection name) is reported for that row only and never blocks the rest. The return value is
`[[ok, detail], ...]`, one entry per row, in the same order.

```sqf
// Custom texture path (a real bitmap, or a hand-written procedural string) instead of a solid colour:
[this, [["TEXTURE", 1, "SET", "\myaddon\data\camo_desert.paa"]]] call Waldo_fnc_VehicleAppearanceApply;

// Revert a slot to the vehicle's own default texture:
[this, [["TEXTURE", 0, "CLEAR", ""]]] call Waldo_fnc_VehicleAppearanceApply;

// Hide a named model selection (confirm the real name with Inspect first - never guessed):
[this, [["SELECTION", "rws_base", "HIDE", ""]]] call Waldo_fnc_VehicleAppearanceApply;
```

The built-in procedural syntax `"#(rgb,8,8,3)color(R,G,B,A)"` needs no texture asset at all - the
classic "pink tank" case is just `[1, 0, 1, 1] call BIS_fnc_colorRGBAtoTexture` (or pass the
`[R,G,B,A]` array directly as `value`, as in the first example above, which does the conversion for
you).

### Removing or restoring a physical component

```sqf
// [vehicle, selectionName, turretPath, hide] - hides the selection AND clears turretPath's weapon:
[this, "rws_base", [0], true] call Waldo_fnc_VehicleComponentRemove;

// Restore later - only re-shows the model part, does NOT re-arm the weapon (never recorded):
[this, "rws_base", [], false] call Waldo_fnc_VehicleComponentRemove;
```

Leave `turretPath` as `[]` for a purely cosmetic component with no associated weapon. Restoring only
re-shows the selection - re-arm the turret separately with
[`Waldo_fnc_VehicleWeaponLoadoutApply`](Vehicle-Weapon-Loadout) if you want the weapon back.

### Registering a component for reuse across a vehicle class

```sqf
// Register once, after confirming the real selection name on the actual vehicle with Inspect:
[["B_MRAP_01_F", "B_MRAP_01_gmg_F"], "Remote Weapon Station", "rws_base", [0]]
    call Waldo_fnc_VehicleComponentCatalogRegister;
```

Registers a reusable `[componentLabel, selectionName, turretPath]` entry for one or more vehicle
**classes** (not one instance) under `Waldo_VehicleComponentCatalog`, a broadcast HashMap keyed by
class. Every future **Vehicle Appearance - Remove/Restore Component** dialog opened on a vehicle of
that class then offers it as a one-click picker option instead of a typed field - the discovery only
has to happen once per class, not once per placed vehicle.

### Discovering real texture slots and selection names

```sqf
private _report = [vehicle] call Waldo_fnc_VehicleAppearanceInspect;
// [textureSlots, selectionNames, reportText, pasteReadyText]
hint (_report select 2);
```

`textureSlots` is `[[index, hiddenSelectionName, currentTexture], ...]` - one per `hiddenSelections[]`
config entry, in the same order `Waldo_fnc_VehicleAppearanceApply`'s TEXTURE rows index into.
`selectionNames` is the full live `selectionNames vehicle` list - every named model selection the
vehicle's model actually exposes, valid for hiding or not (there is no way to tell which from the
engine alone; hiding one you shouldn't have is reversible with no lasting effect - test it against the
real vehicle). `pasteReadyText` is just the comma-joined selection names, comment-free - this is what
the ZEN Inspect module copies to the clipboard, deliberately never the full `reportText`.

## Zeus modules

All four live under category **WMP Vehicle Appearance** and must be placed **directly on the
vehicle** being edited or inspected - same convention as **Vehicle Weapon Loadout**'s modules.
Placement anywhere else is rejected with an on-screen notice.

**Vehicle Appearance - Set Texture** - the texture-slot list is discovered live from the placed
vehicle's own `hiddenSelections[]` config, with each slot's label showing its current texture.

| Control | Meaning |
|---|---|
| Texture Slot | Which `hiddenSelections[]` slot to change |
| Mode | Solid Color (four 0..1 sliders, no texture asset needed), Custom Texture Path, or Restore Default |
| Red / Green / Blue / Alpha | 0..1 sliders, used only in Solid Color mode |
| Custom Texture Path | Exact bitmap path or a hand-written procedural texture string, used only in Custom Texture Path mode |

Routes through the curator-authenticated `Waldo_fnc_ZenVehicleAppearanceTextureServer` bridge before
calling the same public `Waldo_fnc_VehicleAppearanceApply` API mission scripts use directly.

**Vehicle Appearance - Inspect** - read-only, no dialog, acts immediately. Reports every texture slot
and every named model selection as a full-screen `hint`, logs the same to RPT, and copies the plain
comma-joined selection-name list to the clipboard (never the full prose report - see the paste-safety
note below). Needs no curator-authentication bridge and never touches the server.

**Vehicle Appearance - Register Component** - records a component for the placed vehicle's exact
class.

| Control | Meaning |
|---|---|
| Component Label | Short curator-facing name, e.g. "Remote Weapon Station" |
| Selection Name | Exact model selection to hide/show - confirm it with Inspect first |
| Linked Turret Path (optional) | e.g. `[0]` or `[-1]` - that turret's weapon is also cleared on removal. Leave blank for a purely cosmetic part. |

Routes through the curator-authenticated `Waldo_fnc_ZenVehicleComponentRegisterServer` bridge to
`Waldo_fnc_VehicleComponentCatalogRegister`.

**Vehicle Appearance - Remove/Restore Component** - offers every component previously registered for
the placed vehicle's exact class as a picker (the "dynamic pickup" path - no typing needed once
registered), or "Type manually" with typed selection-name/turret-path fields as a fallback.

| Control | Meaning |
|---|---|
| Component | A registered component for this vehicle class, or "Type manually" |
| Selection Name (manual) | Used only when Component is "Type manually" |
| Linked Turret Path (manual, optional) | Used only when Component is "Type manually" |
| Action | Remove (hides the part and clears its linked weapon, if any) or Restore (only re-shows the part) |

Routes through the curator-authenticated `Waldo_fnc_ZenVehicleComponentRemoveServer` bridge to
`Waldo_fnc_VehicleComponentRemove`.

### A note on pasting into Eden init fields

A mission maker was observed pasting a multi-line, `//`-commented row example directly into a
vehicle's Eden init field and hitting `Error Type String, expected Number` / `Invalid number in
expression` - the inline comment swallowed the rest of the statement once the paste lost its real line
breaks. Every clipboard payload this feature (and [Vehicle Weapon Loadout](Vehicle-Weapon-Loadout))
produces is built to be paste-safe: single-statement, comment-free text only. The full human-readable
`reportText` from Inspect is for reading in the `hint`, never for pasting whole into a script or init
field.

## Notes and limitations

- Works on any `AllVehicles`-derived object - cars, tanks, boats, static weapons, aircraft. `Man`
  (soldiers/AI) is explicitly excluded even though it technically inherits from `AllVehicles` too in
  Arma 3's own config tree.
- Safe to call again later on the same vehicle for further changes; each call is independent and
  nothing from a prior call is cached or assumed.
- This is a one-shot apply, not a saved/restorable profile - to persist a vehicle's full state across
  a mission see [Persistence](Persistence) instead.
- Diagnostics/troubleshooting: every `Waldo_fnc_VehicleAppearanceApply` call logs one `[WMP VEHAPP]`
  RPT line summarising every row's outcome; `Waldo_fnc_VehicleComponentRemove` logs a matching
  `[WMP VEHAPP COMPONENT]` line; `Waldo_fnc_VehicleComponentCatalogRegister` logs
  `[WMP VEHAPP CATALOG]`.
- **Out of scope: weapons and ammo.** Adding, replacing, removing, or clearing a turret's weapon, or
  setting an aircraft pylon's ordnance, is a completely different, unrelated Arma system covered by
  [Vehicle Weapon Loadout](Vehicle-Weapon-Loadout), not this feature.

## See also

- [Vehicle Weapon Loadout](Vehicle-Weapon-Loadout) - the weapon/ammo counterpart to this feature, a
  genuinely different Arma system.
- [Vehicle Ambush Script And Vehicle Camo](Vehicle-Ambush-Script-And-Vehicle-Camo) - a related but
  different existing WMP feature that works via physical deployable camo objects, not texture-swapping.
- [Persistence](Persistence) - saving/restoring a vehicle's state across a mission.
- [Zeus and Script API Parity](Zeus-And-Script-API-Parity) - how WMP keeps every Zeus module and its
  underlying script API in sync.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
