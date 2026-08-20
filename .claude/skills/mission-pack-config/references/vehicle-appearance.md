# Vehicle Appearance (recolor, show/hide model parts)

Associated files: `MissionScripts\CombatSystems\VehicleAppearance\vehicleAppearanceApply.sqf`
(`Waldo_fnc_VehicleAppearanceApply`), `vehicleAppearanceInspect.sqf`
(`Waldo_fnc_VehicleAppearanceInspect`), `vehicleComponentCatalogRegister.sqf`
(`Waldo_fnc_VehicleComponentCatalogRegister`), `vehicleComponentRemove.sqf`
(`Waldo_fnc_VehicleComponentRemove`), plus four ZEN modules and their curator-authenticated server
bridges under `MissionScripts\ZenModules\`. No `MissionConfig` file — this is a call/ZEN-only
feature, not a global setting.

## What it does

Two separate cosmetic capabilities, both distinct from
[Vehicle Weapon Loadout](vehicle-weapon-loadout.md) (weapon/ammo content is a different Arma system):

- **Recoloring** a vehicle's own config-declared texture slots (`setObjectTextureGlobal`), including a
  solid colour needing no texture asset via `BIS_fnc_colorRGBAtoTexture`.
- **Physical components** — show/hide a named model selection (`hideSelection`), optionally combined
  with clearing a linked turret's weapon in one call, so "remove this vehicle's turret" is both
  gone-looking and gone-functioning.

Server-authoritative, callable from an object's own Eden init field with no `isServer` wrapper (same
convention as `Waldo_fnc_Jammer`/`Waldo_fnc_VehicleWeaponLoadoutApply`).

**There is no engine query for "this selection is a removable part."** Unlike weapons (enumerable via
`allTurrets`), a model selection is just a named piece the model's author gave it, with no config flag
marking it as removable — WMP ships no pre-seeded catalog of known parts for any vehicle, vanilla or
otherwise. Always route through Inspect first.

## Script API

```sqf
// Recolor: [vehicle, rows]; row = [targetType, selector, action, value]
[this, [["TEXTURE", 0, "SET", [1, 0, 1, 1]]]] call Waldo_fnc_VehicleAppearanceApply;  // pink, no asset
[this, [["SELECTION", "rws_base", "HIDE", ""]]] call Waldo_fnc_VehicleAppearanceApply;

// Remove/restore a component (hides selection AND clears turretPath's weapon when hide=true):
[this, "rws_base", [0], true] call Waldo_fnc_VehicleComponentRemove;

// Register a component once for a vehicle class, for reuse in the ZEN picker:
[["B_MRAP_01_F"], "Remote Weapon Station", "rws_base", [0]] call Waldo_fnc_VehicleComponentCatalogRegister;

// Discover real texture slots and selection names:
[cursorObject] call Waldo_fnc_VehicleAppearanceInspect;  // [textureSlots, selectionNames, reportText, pasteReadyText]
```

`targetType` `"TEXTURE"`: `selector` is a 0-based `hiddenSelections[]` index; `action` `SET` (`value` =
texture path/procedural string, or `[R,G,B,A]` auto-converted) or `CLEAR` (revert to default).
`targetType` `"SELECTION"`: `selector` is a model selection name (validated against live
`selectionNames vehicle`); `action` `HIDE` or `SHOW`.

## Finding real texture slots and selection names

Always route through **Vehicle Appearance - Inspect** (or `Waldo_fnc_VehicleAppearanceInspect`
directly) before typing a texture-slot index or selection name — never guess or recall one from
memory. It reports every slot's current texture and every named selection the model exposes, and the
ZEN module copies the plain selection-name list to the clipboard.

## Zeus modules

Category **WMP Vehicle Appearance**; all four must be placed **directly on the vehicle**, same
convention as Vehicle Weapon Loadout's modules.

- **"Vehicle Appearance - Set Texture"** — texture-slot list discovered live; Solid Color (4 sliders)
  or Custom Texture Path modes, or Restore Default. Routes through
  `Waldo_fnc_ZenVehicleAppearanceTextureServer`.
- **"Vehicle Appearance - Inspect"** — read-only, no dialog, reports slots/selections via `hint`,
  copies the comma-joined selection names to the clipboard (never the full prose report — see paste
  safety below).
- **"Vehicle Appearance - Register Component"** — records `[label, selectionName, turretPath]` for
  the placed vehicle's exact class via `Waldo_fnc_ZenVehicleComponentRegisterServer`.
- **"Vehicle Appearance - Remove/Restore Component"** — offers registered components for that class
  as a one-click picker (dynamic pickup, no typing once registered), or typed
  selection-name/turret-path fallback. Routes through `Waldo_fnc_ZenVehicleComponentRemoveServer`.

## Paste safety (Eden init fields)

A mission maker pasted a multi-line, `//`-commented row example directly into a vehicle's Eden init
field and hit `Invalid number in expression` — the inline comment swallowed the rest of the statement
once the paste lost real line breaks. Every clipboard payload this feature (and Vehicle Weapon
Loadout) produces is single-statement and comment-free by design. Never hand-build a multi-line,
commented example for a mission maker to paste directly into an init field — strip comments first.

## Notes

- Works on any `AllVehicles`-derived object, excluding `Man`.
- One-shot apply, not a persistent profile — see `persistence.md` for saving/restoring vehicle state.
- Diagnostics: `[WMP VEHAPP]`, `[WMP VEHAPP COMPONENT]`, `[WMP VEHAPP CATALOG]` RPT lines.
