# Vehicle Appearance

> **Use this page when:** you want to recolor a vehicle (a "pink tank"), or show/hide a named physical
> model part (e.g. visually remove a turret cupola), through a script call or Zeus - not weapons/ammo,
> that's [Vehicle Weapon Loadout](Vehicle-Weapon-Loadout).

_Associated Files: `MissionScripts\CombatSystems\VehicleAppearance\vehicleAppearanceApply.sqf`, `vehicleAppearanceInspect.sqf`, `vehicleComponentHeuristicScan.sqf`, `vehicleComponentRemove.sqf`, `MissionScripts\CombatSystems\VehicleCustomization\vehicleCustomizationPromptEditor.sqf` (Appearance and Component tabs; and its collector/pending-list files), `MissionScripts\ZenModules\Zen_vehicleCustomizationEditorModule.sqf`, `Zen_vehicleCustomizationInspectModule.sqf`, `zenVehicleCustomizationServer.sqf`, `Waldo_fnc_VehicleAppearanceApply`, `Waldo_fnc_VehicleAppearanceInspect`, `Waldo_fnc_VehicleComponentHeuristicScan`, `Waldo_fnc_VehicleComponentRemove`, `Waldo_fnc_VehicleCustomizationInspect`, `Waldo_fnc_ZenVehicleCustomizationEditor`, `Waldo_fnc_ZenVehicleCustomizationInspect`, `Waldo_fnc_ZenVehicleCustomizationServer`_

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
otherwise - a wrong selection name presented as fact is worse than none at all.
`Waldo_fnc_VehicleComponentHeuristicScan` re-scans the actual placed vehicle live every time the ZEN
Editor's Component tab opens (name-filtered, best-effort turret correlation, every candidate labelled
with an explicit "verify" caveat) instead of relying on a persistent per-class registration step. You
can still confirm a real selection name yourself first with **Vehicle Customisation - Inspect**.

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

### Discovering candidate components automatically

```sqf
private _candidates = [vehicle] call Waldo_fnc_VehicleComponentHeuristicScan;
// Array of [selectionName, likelyTurretPath, label] - label already carries a "verify" caveat.
```

Rather than a persistent per-class registration step, `Waldo_fnc_VehicleComponentHeuristicScan`
re-scans the live placed vehicle every time the ZEN Editor's Component tab opens: it filters
`selectionNames vehicle` to those whose name contains a plausible hint (`"turret"`, `"gun"`,
`"weapon"`, `"mount"`, `"hatch"`, `"rws"`, `"cannon"`, `"hmg"`, `"gmg"`), then best-effort-correlates
each candidate against the vehicle's real turret paths. Picking a candidate in the Editor auto-fills
the Selection Name and Linked Turret Path fields - never presented as fact, always labelled
best-effort, and always worth a visual check against the real vehicle before removing. The Linked
Turret Path field also has its own small picker listing every editable turret path on this vehicle
(the same mount-less/horn-excluded list the Turret tab uses), so a curator rarely has to type a path
array by hand at all.

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

Both vehicle appearance actions - recoloring a texture slot and hiding/showing a model selection
(optionally clearing a linked turret's weapon at the same time) - live as tabs inside the unified
**Vehicle Customisation - Editor** and **Vehicle Customisation - Inspect** ZEN modules (category
**WMP Vehicle Customisation**), documented in full on [Vehicle Weapon Loadout](Vehicle-Weapon-Loadout)
alongside the Turret and Pylon tabs, rather than duplicated here. In short:

- **Vehicle Customisation - Editor**'s **Appearance** tab recolors a texture slot (Solid Color, no
  texture asset needed, or Custom Texture Path) or restores its default; the **Component** tab
  hides/shows a model selection and, when removing, optionally clears a linked turret's weapon too -
  offering `Waldo_fnc_VehicleComponentHeuristicScan`'s live, best-effort candidates for the placed
  vehicle as a picker (see [Overview](#overview) above), or a typed selection-name/turret-path
  fallback. Both tabs queue into the same Pending Changes list as Turret/Pylon rows and apply through
  the same consolidated `Waldo_fnc_ZenVehicleCustomizationServer` bridge.
- **Vehicle Customisation - Inspect** reports every texture slot and every named model selection for
  the placed vehicle, merged with the turret/pylon report, via one `hint` and one clipboard copy.

Both modules must be placed **directly on the vehicle** being edited or inspected - same convention as
every module in this family. Placement anywhere else is rejected with an on-screen notice.

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
  `[WMP VEHAPP COMPONENT]` line; the merged ZEN Inspect module logs `[WMP VEHCUST INSPECT]`.
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
