# Vehicle Appearance (recolor, show/hide model parts)

Associated files: `MissionScripts\CombatSystems\VehicleAppearance\vehicleAppearanceApply.sqf`
(`Waldo_fnc_VehicleAppearanceApply`), `vehicleAppearanceInspect.sqf`
(`Waldo_fnc_VehicleAppearanceInspect`), `vehicleComponentHeuristicScan.sqf`
(`Waldo_fnc_VehicleComponentHeuristicScan`), `vehicleComponentRemove.sqf`
(`Waldo_fnc_VehicleComponentRemove`), plus the shared
`MissionScripts\CombatSystems\VehicleCustomization\vehicleCustomizationPromptEditor.sqf` dialog
(Appearance and Component tabs) and its two ZEN modules + consolidated server bridge under
`MissionScripts\ZenModules\`. No `MissionConfig` file — this is a call/ZEN-only feature, not a global
setting.

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
otherwise. `Waldo_fnc_VehicleComponentHeuristicScan` re-scans the live placed vehicle every time the
ZEN Editor's Component tab opens instead (name-filtered, best-effort turret correlation, every
candidate labelled with an explicit "verify" caveat) — always route through Inspect or the heuristic
scan first, never a guessed selection name presented as fact.

## Script API

```sqf
// Recolor: [vehicle, rows]; row = [targetType, selector, action, value]
[this, [["TEXTURE", 0, "SET", [1, 0, 1, 1]]]] call Waldo_fnc_VehicleAppearanceApply;  // pink, no asset
[this, [["SELECTION", "rws_base", "HIDE", ""]]] call Waldo_fnc_VehicleAppearanceApply;

// Remove/restore a component (hides selection AND clears turretPath's weapon when hide=true):
[this, "rws_base", [0], true] call Waldo_fnc_VehicleComponentRemove;

// Discover candidate removable components on a live vehicle (best-effort, always verify):
private _candidates = [cursorObject] call Waldo_fnc_VehicleComponentHeuristicScan;
// Array of [selectionName, likelyTurretPath, label]

// Discover real texture slots and selection names:
[cursorObject] call Waldo_fnc_VehicleAppearanceInspect;  // [textureSlots, selectionNames, reportText, pasteReadyText]
```

`targetType` `"TEXTURE"`: `selector` is a 0-based `hiddenSelections[]` index; `action` `SET` (`value` =
texture path/procedural string, or `[R,G,B,A]` auto-converted) or `CLEAR` (revert to default).
`targetType` `"SELECTION"`: `selector` is a model selection name (validated against live
`selectionNames vehicle`); `action` `HIDE` or `SHOW`.

## Finding real texture slots and selection names

Always route through **Vehicle Customisation - Inspect** (or `Waldo_fnc_VehicleAppearanceInspect`
directly) before typing a texture-slot index or selection name — never guess or recall one from
memory. It reports every slot's current texture and every named selection the model exposes (merged
with the weapon/pylon report), and the ZEN module copies the plain selection-name list to the
clipboard.

## Zeus modules

Both appearance actions live as tabs inside the same **Vehicle Customisation - Editor** / **Vehicle
Customisation - Inspect** modules documented in full in `vehicle-weapon-loadout.md` (category
**WMP Vehicle Customisation**; must be placed **directly on the vehicle**), not as separate modules:

- **Appearance tab** — texture-slot list discovered live from `hiddenSelections[]`; Solid Color
  (four fields) or Custom Texture Path modes, or Restore Default. Queues into the same Pending
  Changes list as Turret/Pylon rows.
- **Component tab** — offers `Waldo_fnc_VehicleComponentHeuristicScan`'s live, best-effort candidates
  for the placed vehicle as a picker (auto-fills Selection Name and Linked Turret Path), or a typed
  fallback; Remove also clears a linked turret's weapon, Restore only re-shows the part.
- **Vehicle Customisation - Inspect** — read-only, no dialog, reports slots/selections via `hint`
  merged with the weapon/pylon report, copies the comma-joined selection names to the clipboard
  (never the full prose report — see paste safety below).

Apply routes through the consolidated `Waldo_fnc_ZenVehicleCustomizationServer` bridge (one
curator-authentication check for the whole Pending list, not one per feature) to
`Waldo_fnc_VehicleAppearanceApply` / `Waldo_fnc_VehicleComponentRemove`.

## Paste safety (Eden init fields)

A mission maker pasted a multi-line, `//`-commented row example directly into a vehicle's Eden init
field and hit `Invalid number in expression` — the inline comment swallowed the rest of the statement
once the paste lost real line breaks. Every clipboard payload this feature (and Vehicle Weapon
Loadout) produces is single-statement and comment-free by design. Never hand-build a multi-line,
commented example for a mission maker to paste directly into an init field — strip comments first.

## Notes

- Works on any `AllVehicles`-derived object, excluding `Man`.
- One-shot apply, not a persistent profile — see `persistence.md` for saving/restoring vehicle state.
- Diagnostics: `[WMP VEHAPP]`, `[WMP VEHAPP COMPONENT]`, `[WMP VEHCUST INSPECT]` RPT lines.
