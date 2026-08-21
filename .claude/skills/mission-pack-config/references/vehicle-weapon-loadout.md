# Vehicle Weapon Loadout (custom turret/pylon add, replace, remove)

Associated files: `MissionScripts\CombatSystems\VehicleWeaponLoadout\vehicleWeaponLoadoutApply.sqf`
(`Waldo_fnc_VehicleWeaponLoadoutApply`), `vehicleWeaponLoadoutInspect.sqf`
(`Waldo_fnc_VehicleWeaponLoadoutInspect`), `vehicleWeaponLoadoutCopy.sqf`
(`Waldo_fnc_VehicleWeaponLoadoutCopy`), `vehicleWeaponLoadoutCopyBuildRows.sqf`,
`vehicleWeaponLoadoutCopyPreview.sqf` (`Waldo_fnc_VehicleWeaponLoadoutCopyPreview`),
`MissionScripts\CombatSystems\VehicleCustomization\vehicleCustomizationPromptEditor.sqf`
(`Waldo_fnc_VehCust_promptEditor`, plus its collector/pending-list files),
`vehicleCustomizationInspect.sqf` (`Waldo_fnc_VehicleCustomizationInspect`),
`MissionScripts\ZenModules\Zen_vehicleCustomizationEditorModule.sqf`
(`Waldo_fnc_ZenVehicleCustomizationEditor`), `Zen_vehicleCustomizationInspectModule.sqf`
(`Waldo_fnc_ZenVehicleCustomizationInspect`), `zenVehicleCustomizationServer.sqf`
(`Waldo_fnc_ZenVehicleCustomizationServer`). No `MissionConfig` file — this is a call/ZEN-only
feature, not a global setting to tune.

## What it does

Adds, replaces, removes, or clears a vehicle's turret weapons/magazines, and separately sets or
clears aircraft pylon ordnance — a mission maker can arm/disarm/reload a specific vehicle without
hand-writing `removeWeaponTurret`/`addWeaponTurret`/`setPylonLoadOut` calls. Server-authoritative;
callable from an object's own Eden init field with no `isServer` wrapper (same convention as
`Waldo_fnc_Jammer`), and reachable in-Zeus.

## Script API

```sqf
[this, [
    ["TURRET", [-1], -1, "REPLACE", "arifle_MX_F", "30Rnd_65x39_caseless_mag", 30, 4]
]] call Waldo_fnc_VehicleWeaponLoadoutApply;
```
`Waldo_fnc_VehicleWeaponLoadoutApply` takes `[vehicle, rows]`. Each row:
`[targetType, turretPath, pylonIndex, action, weaponClass, magazineClass, magazineCount, magazineQuantity]`.

- `targetType`: `"TURRET"` or `"PYLON"`.
- `turretPath`: e.g. `[-1]` (main/driver weapon), `[0]`, `[0,0]` — required for TURRET rows.
  Discover real paths with `[[-1]] + (allTurrets [vehicle, true])` (`allTurrets` never includes `[-1]`
  itself, per Bohemia's own documentation).
- `pylonIndex`: 1-based hardpoint number — required for PYLON rows. Discover the count with
  `count (getPylonMagazines vehicle)`.
- `action` for TURRET: `"ADD"`, `"REPLACE"` (strips the turret first), `"REMOVE"` (takes one named
  weapon/magazine off), `"CLEAR"` (strips the whole turret).
- `action` for PYLON: `"SET"` (aliases `"ADD"`/`"REPLACE"` accepted) or `"CLEAR"`.
- `weaponClass` / `magazineClass`: exact `CfgWeapons` / `CfgMagazines` classnames. For a pylon row,
  `magazineClass` is the ordnance/pod itself (pylons carry no separate weapon classname).
- `magazineCount`: rounds loaded into EACH magazine instance (optional, default 1, TURRET only) —
  clamped **down** to that magazine class's own `CfgMagazines` `count` if it exceeds it (a magazine
  can't hold more rounds than its own config allows — the engine itself enforces this), never forced
  up, so a value below the max produces a genuinely partial magazine. For a PYLON row this field means
  something different — it's the pylon's *exact* ammo override: `0`/omitted loads the pylon's full
  `CfgMagazines`-defined count via `setAmmoOnPylon` (`setPylonLoadOut`'s own third argument is a
  `forced`-compatibility flag, not an ammo-load flag, and never loads ammo by itself); a positive value
  loads exactly that many rounds, clamped to the magazine's own full count.
- `magazineQuantity`: how many separate magazine instances to add (optional, default 1, TURRET
  ADD/REPLACE only). `addMagazineTurret` adds exactly one magazine instance per call, so this loops it
  that many times — e.g. `magazineCount=30, magazineQuantity=4` means four separate 30-round
  magazines (a real 120-round reserve), not one oversized magazine.

Multiple rows in one call apply independently — a bad row (unknown classname, non-existent turret
path/pylon index) is reported per-row and never blocks the others. Return value is
`[[ok, detail], ...]`, one entry per row, in order.

A magazine's compatibility with a weapon is checked via `compatibleMagazines` only as a **logged
warning**, never a hard rejection — `compatibleMagazines` is muzzle-specific (a weapon can have more
than one muzzle, e.g. a rifle plus an underslung grenade launcher) and this call doesn't ask which
muzzle is meant, so a mismatch against the primary muzzle can still be a real, valid combination
against a secondary one.

## Finding exact classnames (beginner question — always route here first)

There is no engine query for "what weapons/magazines fit this turret", so a mission maker always has
to get a real classname from somewhere. Point them at these, in order — the first fully avoids typing
one at all:

1. **`Waldo_fnc_VehicleWeaponLoadoutCopy`** / Zeus **"Vehicle Customisation - Editor"**'s
   **Copy From Nearby Vehicle...** button (Turret tab) — placed on the *target* vehicle, picks a
   nearby *source* vehicle (discovered live within 100m) and pushes its real turret/pylon loadout
   straight into the Pending Changes list, including the source's exact remaining pylon ammo via
   `ammoOnPylon`. No classname is ever seen or typed by anyone. This is the right default whenever
   "make this vehicle armed like that one" is the actual goal, not "I want to see/tweak the
   classname."
2. **`Waldo_fnc_VehicleWeaponLoadoutInspect`** / Zeus **"Vehicle Customisation - Inspect"** — placed
   directly on ANY vehicle (a stock/vanilla one is fine), it prints every turret's and pylon's exact
   current weapon/magazine classnames as part of a full-screen `hint` (merged with the appearance
   report), each weapon row followed by a ready-to-paste `Waldo_fnc_VehicleWeaponLoadoutApply` row.
   Use this over Copy when the mission maker wants to see or edit the classname before applying it.
   Read-only, no server round-trip, no curator-auth bridge (nothing it reports isn't already visible
   by looking at the vehicle in Eden). Also logs the same report to that client's RPT under
   `[WMP VEHCUST INSPECT]`.
3. **Eden Editor's built-in Debug Console** (`Tools > Debug Console`, ships with the base game) — e.g.
   `hint str (vehicle weaponsTurret [-1]);`.
4. **Official Bohemia references**: [Arma 3 Assets](https://community.bistudio.com/wiki/Arma_3_Assets)
   (canonical classname index) and
   [Arma 3: CfgWeapons Vehicle Weapons](https://community.bistudio.com/wiki/Arma_3:_CfgWeapons_Vehicle_Weapons)
   (vehicle-mounted turret weapons by faction).

Never hand a mission maker a guessed classname presented as fact — a wrong one fails silently at apply
time (a rejected row, not a crash). Point them at Copy/Inspect or the biki instead of recalling one
from memory.

## Zeus modules

**"Vehicle Customisation - Editor"** (category **WMP Vehicle Customisation**) — must be placed
**directly on the vehicle** to edit, same convention as **Plant Signal Tracker**; placing it on open
ground or any other object is rejected with an on-screen notice. Replaces the old one-shot
"Configure" / "Copy From Nearby Vehicle" / "Register Component" / "Remove/Restore Component" modules
with one persistent, four-tab dialog (Turret / Pylon / Appearance / Component) plus a permanent
**Pending Changes** list visible on every tab. The Turret and Pylon tabs' option lists, current-loadout
labels, and **"Copy Weapon From"** / **"Copy Ordnance From"** pickers (on-vehicle pairings plus a
pack-wide catalog via `Waldo_fnc_VehicleWeaponLoadoutCatalogBuild`) work exactly as before — see
"Finding exact classnames" above. Each tab's own **Add \<Tab\> Row** button routes through a
dedicated, validation-gated collector before anything is queued, so a blank or incomplete row can
never reach Pending (the direct fix for a confirmed bug in the old Configure module's own queue
feature, which used to rebuild a row from blank form fields). **Apply All Pending** sends the whole
list in one authenticated request to the consolidated `Waldo_fnc_ZenVehicleCustomizationServer`
bridge, which dispatches turret/pylon rows to `Waldo_fnc_VehicleWeaponLoadoutApply`, appearance rows
to `Waldo_fnc_VehicleAppearanceApply`, and component rows to `Waldo_fnc_VehicleComponentRemove` — one
curator-authentication check total, not one per feature. **Export All Pending To Clipboard** is
purely client-side: builds one ready-to-paste multi-statement Eden-init-field snippet from whatever is
pending, applies nothing, keeps the list. **Copy From Nearby Vehicle...** (Turret tab) opens an
in-dialog picker of vehicles within 100m and pushes the picked source's real turret/pylon rows
straight into Pending via the read-only `Waldo_fnc_VehicleWeaponLoadoutCopyPreview` — no classname
typed, no server call until Apply. Every mutating turret action is refused with a notice if the
selected turret's only weapon is the vehicle's horn — pick a different turret.

**"Vehicle Customisation - Inspect"** (same category, same placed-directly-on-the-vehicle
convention) — the read-only companion, merging what used to be two separate Inspect modules via
`Waldo_fnc_VehicleCustomizationInspect`. No dialog; acts immediately, copies the combined report to
the curator's clipboard, logs it to RPT under `[WMP VEHCUST INSPECT]`, confirms both with a fast
notification card, and shows the full report via `hint`. A horn-only turret is reported but never
gets a paste-ready row.


## Not covered here: vehicle appearance

Recoloring a vehicle ("a pink tank") or hiding part of its physical model (e.g. a turret cupola) is a
different, unrelated Arma system — cosmetic model state, not weapon/ammo content. See
`vehicle-appearance.md` for that feature (`Waldo_fnc_VehicleAppearanceApply`,
`Waldo_fnc_VehicleComponentRemove`). WMP's other closest existing feature is
`Waldo_fnc_VehicleCamoSetup` (`misc-mission-maker-tools.md` → Vehicle Ambush & Camo), which works via
physical deployable camo objects, not texture-swapping.

## Notes

- `"AllVehicles"` gate: works on any turreted or pylon-equipped vehicle — cars, tanks, boats, static
  weapons, aircraft. `Man` (soldiers/AI) is explicitly excluded even though it technically inherits
  from `AllVehicles` too in Arma 3's own config tree — point a mission maker at ACE Arsenal or the
  loadout/logistics system for a unit's own weapons instead.
- Safe to call again later on the same vehicle for further changes; each call is independent, nothing
  is cached from a prior call.
- This is a one-shot apply, not a persistent profile system — for saving/restoring a full vehicle
  state across sessions, see `persistence.md` instead.
- The horn is never treated as a weapon. `Waldo_fnc_VehicleWeaponLoadoutApply` itself refuses every
  mutating TURRET action against a horn-only turret — the single authoritative check, enforced
  regardless of caller (script call, Eden init field, or ZEN). The Editor/Copy/Inspect add their own
  client-side labeling/skipping on top purely to avoid a wasted round-trip, not as the real guard.
- `[-1]` (the main/driver weapon slot) is always offered as a turret path since `allTurrets` never
  returns it itself, but it isn't guaranteed to have a real weapon mount — some vehicles' own class
  declares no root `weapons[]` array at all. `Waldo_fnc_VehicleWeaponLoadoutApply` refuses ADD/REPLACE
  against a mount-less `[-1]` rather than silently doing nothing (WMP cannot create a physical mount
  point that needs model/config authoring work). The Editor labels it `(no weapon mount on this
  vehicle)` and never defaults to it. A real path from `allTurrets` never has this problem.
