# Vehicle Weapon Loadout

> **Use this page when:** you want to arm, rearm, disarm, or swap the weapons/ammo on a specific vehicle - a turret weapon, its magazines, or an aircraft pylon's ordnance - through a script call or Zeus, instead of hand-writing `removeWeaponTurret`/`addWeaponTurret`/`setPylonLoadOut`.

_Associated Files: `MissionScripts\CombatSystems\VehicleWeaponLoadout\vehicleWeaponLoadoutApply.sqf`, `vehicleWeaponLoadoutInspect.sqf`, `vehicleWeaponLoadoutCopy.sqf`, `MissionScripts\ZenModules\Zen_vehicleWeaponLoadoutModule.sqf`, `zenVehicleWeaponLoadoutServer.sqf`, `Zen_vehicleWeaponLoadoutInspectModule.sqf`, `Zen_vehicleWeaponLoadoutCopyModule.sqf`, `zenVehicleWeaponLoadoutCopyServer.sqf`, `Waldo_fnc_VehicleWeaponLoadoutApply`, `Waldo_fnc_VehicleWeaponLoadoutInspect`, `Waldo_fnc_VehicleWeaponLoadoutCopy`, `Waldo_fnc_ZenVehicleWeaponLoadout`, `Waldo_fnc_ZenVehicleWeaponLoadoutServer`, `Waldo_fnc_ZenVehicleWeaponLoadoutInspect`, `Waldo_fnc_ZenVehicleWeaponLoadoutCopy`, `Waldo_fnc_ZenVehicleWeaponLoadoutCopyServer`_

There is no `MissionConfig` file for this feature - it's a call/ZEN-only tool, not a global setting.

---

## Overview

Custom weapon/ammo change-out for a single vehicle: add a weapon to a turret, replace what's already
mounted, remove one specific weapon, or strip a turret entirely - and, separately, set or clear an
aircraft pylon's ordnance. Server-authoritative, like the rest of WMP's object-anchored features
(`Waldo_fnc_Jammer`, `Waldo_fnc_Tracker`): safe to call from a vehicle's own Eden init field with no
`isServer` wrapper, since the call forwards itself to the server automatically.

Turret weapons and aircraft pylons are two genuinely separate Arma systems under the hood -
`removeWeaponTurret`/`addWeaponTurret`/`addMagazineTurret` for turrets, `setPylonLoadOut` for pylons -
and this feature keeps that same split rather than papering over it, since a "weapon" on a pylon is
really just an ordnance/magazine classname with no separate weapon class of its own.

## Scripting

```sqf
// [vehicle, rows]
[this, [
    ["TURRET", [-1], -1, "REPLACE", "arifle_MX_F", "30Rnd_65x39_caseless_mag", 30, 4]
]] call Waldo_fnc_VehicleWeaponLoadoutApply;
```

Each row is `[targetType, turretPath, pylonIndex, action, weaponClass, magazineClass, magazineCount, magazineQuantity]`:

| Field | Type | Meaning |
|---|---|---|
| `targetType` | STRING | `"TURRET"` or `"PYLON"` |
| `turretPath` | ARRAY | Required for TURRET rows, e.g. `[-1]` (main/driver weapon), `[0]`, `[0,0]`. Ignored for PYLON rows. |
| `pylonIndex` | NUMBER | Required for PYLON rows, 1-based hardpoint index. Ignored for TURRET rows. |
| `action` | STRING | TURRET: `ADD`, `REPLACE` (strips the turret first), `REMOVE` (one named weapon/magazine), `CLEAR` (whole turret). PYLON: `SET` (aliases `ADD`/`REPLACE` accepted), `CLEAR`. |
| `weaponClass` | STRING | `CfgWeapons` class - TURRET rows only. |
| `magazineClass` | STRING | `CfgMagazines` class - the turret magazine to load (TURRET, optional) or the pylon's ordnance itself (PYLON, required for `SET`). |
| `magazineCount` | NUMBER | Rounds loaded **into each magazine instance** (default 1, TURRET only) - can be less than the magazine's full capacity for a genuinely partial magazine, or omitted/left low for a full one; clamped **down** if it exceeds the magazine's own `CfgMagazines` `count` (a magazine can't hold more rounds than its own config allows - the engine itself enforces this, same as `addMagazine`), never forced up. For a PYLON row this field means something different - it's the pylon's *exact* ammo count instead: `0` (or omitted) loads the pylon's full `CfgMagazines`-defined count via `setAmmoOnPylon` (`setPylonLoadOut`'s own third argument is a `forced`-compatibility flag, not an ammo-load flag, and never loads ammo by itself); a positive value loads exactly that many rounds, clamped to the magazine's own full count. |
| `magazineQuantity` | NUMBER | How many separate magazine instances to add (default 1, TURRET ADD/REPLACE only, ignored elsewhere). `addMagazineTurret` adds exactly one magazine instance per call, so this loops it that many times to build a real reserve ammo pool - e.g. `magazineCount=30, magazineQuantity=4` means four separate 30-round magazines, not one 120-round magazine. |

Multiple rows apply independently in one call - a bad row (unknown classname, non-existent turret
path/pylon index) is reported for that row only and never blocks the rest. The return value is
`[[ok, detail], ...]`, one entry per row, in the same order.

```sqf
// Strip a coax MG off turret [0] (exact coax classname varies per vehicle family - confirm
// it with Inspect below rather than assuming "LMG_Coax" is universal), and load pylon 1 with a
// GBU-12 pod at its full ammo count (0 = full):
[this, [
    ["TURRET", [0], -1, "REMOVE", "LMG_Coax", "", 0],
    ["PYLON", [-1], 1, "SET", "", "6Rnd_GBU12_x_AGM_65E2_Pylon", 0]
]] call Waldo_fnc_VehicleWeaponLoadoutApply;

// Load the same pod but with only 2 of its rounds instead of a full load:
[this, [["PYLON", [-1], 1, "SET", "", "6Rnd_GBU12_x_AGM_65E2_Pylon", 2]]]
    call Waldo_fnc_VehicleWeaponLoadoutApply;

// Clear a turret completely:
[this, [["TURRET", [-1], -1, "CLEAR", "", "", 0]]] call Waldo_fnc_VehicleWeaponLoadoutApply;

// Four separate 12-round tank cannon magazines (a real 48-round reserve), not one 12-round magazine:
[this, [["TURRET", [0], -1, "REPLACE", "cannon_125mm", "12Rnd_125mm_HE_T_Red", 12, 4]]]
    call Waldo_fnc_VehicleWeaponLoadoutApply;
```

### Copying a whole loadout from another vehicle

```sqf
// Give myJeep the exact turret/pylon loadout of referenceVehicle - no classname typed:
[referenceVehicle, myJeep] call Waldo_fnc_VehicleWeaponLoadoutCopy;
// [copiedTurretPaths, copiedPylonIndices, applyResults] - only turret paths present on BOTH
// vehicles are copied, and pylons are copied by index (1st to 1st, 2nd to 2nd, ...) including the
// source's exact remaining ammo via ammoOnPylon.
```

### Discovering real turret paths and pylon counts

```sqf
private _turrets = [[-1]] + (allTurrets [vehicle, true]);   // allTurrets never includes [-1] itself
private _pylonCount = count (getPylonMagazines vehicle);     // 0 = no pylons on this vehicle
```

## Finding the exact classnames (beginner-friendly)

There is no engine query for "what weapons/magazines fit this turret" - a turret's weapon slot
genuinely accepts almost any vehicle-mounted weapon class regardless of the vehicle's own original
armament (that's the whole point of `addWeaponTurret`), so there is nothing for the game to filter a
list against. This means classnames are always typed in somewhere, never picked from a
guaranteed-compatible list - which is exactly the beginner pain point this section, and the two
helper modules below, exist to solve. In order of how completely each one avoids typing a classname:

**Never type a classname at all - copy the loadout directly.** Place **Vehicle Weapon Loadout - Copy
From Nearby Vehicle** directly on the vehicle you want to *receive* a loadout, pick another vehicle
within 100m to copy *from* (a stock/vanilla one works great - you don't need to own or have configured
it), and confirm. Every classname is read straight off the source vehicle and applied to the target -
nobody ever sees or types one. It only touches turret paths that exist on both vehicles (so copying a
tank's cannon onto a car copies nothing for that turret, reported not silently skipped) and copies
pylons by index including the source's *exact* remaining ammo, not just a fresh reload. This is the
right choice whenever "make this vehicle armed like that one" is really the goal.

**Want to see the classnames, or tweak just one thing?** Place **Vehicle Weapon Loadout - Inspect**
directly on any vehicle and it prints every turret's and pylon's exact current classnames as a
full-screen `hint`, each followed by a ready-to-paste row, in this format (illustrative - the exact
classnames always come from whatever vehicle you actually inspect, not from this page; the pairing
shown here, a tank cannon plus its HE round, is the one Bohemia's own `addWeaponTurret` documentation
example uses):

```
--- <vehicle display name> (<vehicle class>) ---
Turret [0]: weapon=cannon_125mm magazines=["12Rnd_125mm_HE_T_Red"]
["TURRET", [0], -1, "REPLACE", "cannon_125mm", "12Rnd_125mm_HE_T_Red", 1],
```

Copy the row, adjust the magazine count, and paste it straight into `Waldo_fnc_VehicleWeaponLoadoutApply`
or read the classnames off into the **Configure** dialog's Weapon/Magazine fields. The report is also
written to that client's own RPT under `[WMP VEHWPN INSPECT]` if you want a permanent copy. This is
purely read-only - it never changes the inspected vehicle - and needs no curator authentication since
it tells you nothing you couldn't already see by looking at the vehicle in Eden.

**Other official ways to find a classname**, for the rare case neither helper covers, in order of how
likely a beginner is to already have them available:
- **Eden Editor's built-in Debug Console** (`Tools > Debug Console` in the 3D Editor) - run
  `hint str (vehicle weaponsTurret [-1]);` or `hint str (getPylonMagazines vehicle);` against a
  selected vehicle. Confirmed shipped with the base game, not a mod.
- **[Arma 3 Assets](https://community.bistudio.com/wiki/Arma_3_Assets)** - Bohemia's own canonical,
  kept-current classname index for the whole game.
- **[Arma 3: CfgWeapons Vehicle Weapons](https://community.bistudio.com/wiki/Arma_3:_CfgWeapons_Vehicle_Weapons)**
  - specifically vehicle-mounted turret weapons, organised by faction (BLUFOR/OPFOR/Independent/Civilian).

### Magazine/weapon compatibility

A magazine's fit against the requested weapon is checked with `compatibleMagazines` and logged if it
looks wrong - but this is **only a warning**, never a hard rejection. `compatibleMagazines` is
muzzle-specific (a weapon can carry more than one muzzle, e.g. a rifle plus an underslung grenade
launcher) and a loadout row doesn't ask which muzzle is meant, so a combination that looks wrong
against the primary muzzle can still be exactly right against a secondary one. If a row is rejected
outright, it's always because the weapon or magazine classname itself doesn't exist in the loaded
modset - check the RPT (`[WMP VEHWPN]`) for the exact per-row reason. The **Inspect** module above is
also the fastest way to confirm a magazine is genuinely compatible: if it's currently loaded on a real
vehicle, it's compatible.

## Zeus modules

**Vehicle Weapon Loadout - Configure** (category **WMP AI & Combat**) must be placed **directly on
the vehicle** you want to edit - the same convention as **Plant Signal Tracker**. Dropping it
anywhere else (open ground, a different object) is rejected with an on-screen notice instead of
silently doing nothing.

The dialog's **Turret** and **Pylon** option lists are built fresh every time it opens, discovered
live from that exact vehicle (`allTurrets`, `getPylonMagazines`, and the vehicle's own
`TransportPylonsComponent` config for pylon display names) - never a hand-typed list, so only choices
that vehicle genuinely supports are ever shown, and each option's label shows what's currently
mounted there.

| Control | Meaning |
|---|---|
| Loadout Target | Turret weapon, or Aircraft pylon (only offered when the vehicle actually has pylons) |
| Turret | Which turret path to change (used when target is Turret weapon). A turret whose only weapon is the horn is labelled `(horn - not editable here)` and is never the default selection. |
| Turret Action | Add Weapon / Replace Turret / Remove Weapon / Clear Turret |
| Copy Weapon From | Pick a weapon+magazine pairing already mounted somewhere on this exact vehicle, or from the pack-wide catalog (see below), instead of typing one below (excludes the horn); default "Type manually" leaves the two fields below in charge |
| Weapon Classname | `CfgWeapons` class to add/replace/remove - ignored for Clear, for pylons, and when Copy Weapon From picked something |
| Magazine Classname | `CfgMagazines` class - a turret's magazine, or a pylon's ordnance - ignored when Copy Weapon From/Copy Ordnance From picked something |
| Rounds Per Magazine | Rounds loaded into EACH magazine instance, clamped to that magazine's own full capacity - ignored for pylons, for Remove/Clear, and when Copy Weapon From picked something |
| Number Of Magazines | How many separate magazine instances to add - the turret's real reserve ammo pool, not just one oversized magazine - ignored for pylons, for Remove/Clear, and when Copy Weapon From picked something |
| Pylon | Which hardpoint to change (used when target is Aircraft pylon) |
| Copy Ordnance From | Pick ordnance already mounted on this vehicle, or from the pack-wide catalog, instead of typing the Magazine Classname field above - pylons only |
| Pylon Action | Set Ordnance / Clear Pylon |
| Session Action | Apply Now (default, the original one-shot behaviour), Queue This Action, Apply All Queued, Export Queue To Clipboard, or Clear Queue - see "Queuing multiple actions" below |

### Pack-wide catalog

Both Copy pickers extend beyond "what's already on this one vehicle" with a catalog discovered live
across **every vehicle class in the currently loaded modset** - `Waldo_fnc_VehicleWeaponLoadoutCatalogBuild`
recursively scans every `CfgVehicles` turret entry for its `weapons[]`/`magazines[]` arrays, and every
`CfgMagazines` entry carrying a `pylonWeapon` property, for the turret and pylon catalogs
respectively. That scan is real work on a large modset, so it never runs synchronously inside this
dialog: `Waldo_fnc_ZenInitModules` kicks it off in the background at mission start and caches the
result for the rest of the mission (config data is immutable during one, the same justification
`Waldo_fnc_ResolveVehicleClassPool` already uses for its own cache). If a curator opens the dialog
before that background scan finishes, the pack-wide section is simply absent that one time - "Type
manually" says so directly, and reopening the module shortly after picks it up once ready. Each
picker also caps how many pack-wide entries it renders and truncates long labels, so a modset with
thousands of distinct turret weapons never turns the list itself into an unusably slow, overrunning
control - the underlying cached catalog is not capped, only what one dialog open renders from it.

### Queuing multiple actions

**Session Action** turns single-shot editing into a small builder for when several changes belong to
the same vehicle-configuration pass:

- **Apply Now** - the original behaviour: apply this one row immediately.
- **Queue This Action** - stash this row in a client-local queue kept per vehicle, and leave the
  dialog free to be reopened for another action on the same vehicle. Nothing is applied yet.
- **Apply All Queued** - submit every queued row plus this dialog's own current row in one call
  (`Waldo_fnc_VehicleWeaponLoadoutApply` already accepts multiple rows per call), then clear the
  queue.
- **Export Queue To Clipboard** - build one ready-to-paste multi-row
  `[this, [...]] call Waldo_fnc_VehicleWeaponLoadoutApply;` block from the queue plus this row, copy
  it to the clipboard for a unit's Eden init field, and apply nothing - the queue is kept afterward.
- **Clear Queue** - drop any rows queued for this vehicle. This dialog's own current row is not
  applied either.

The queue is interface-client-local only (keyed by the vehicle's `netId`) - nothing is queued or
applied server-side until Apply/Export is actually chosen, and it is never synchronised between
curators.

Weapon and magazine classnames can be typed in directly, picked from **Copy Weapon From**/**Copy
Ordnance From**, or found with the **Inspect** module below - see [Finding the exact
classnames](#finding-the-exact-classnames-beginner-friendly) above before typing one in from memory.
Whichever way a turret's weapon is chosen, **every mutating turret action is refused with a notice if
that turret's current weapon is only the vehicle's horn** - pick a different turret instead; the horn
is never treated as a combat weapon by this feature.

Submitting the dialog (when not exporting) routes through the curator-authenticated
`Waldo_fnc_ZenVehicleWeaponLoadoutServer` bridge (same pattern as **Plant Signal Tracker**'s
`Waldo_fnc_ZenTrackerServer`) before calling the same public `Waldo_fnc_VehicleWeaponLoadoutApply` API
mission scripts use directly, and reports the outcome back to the curator as a WMP notification card.

**Vehicle Weapon Loadout - Inspect** (same category, same placed-directly-on-the-vehicle convention)
is the read-only companion module described above under [Finding the exact
classnames](#finding-the-exact-classnames-beginner-friendly) - no dialog, acts immediately, logs the
full report to RPT, and shows it as a full-screen `hint`. The **clipboard** gets something different
and deliberately narrower: every row combined into one single, comment-free, ready-to-paste
`[this, [...]] call Waldo_fnc_VehicleWeaponLoadoutApply;` statement - safe to paste directly into a
unit's Eden init field as-is. The full prose report is never what lands on the clipboard; pasting a
human-readable report (or any block with an inline `// comment`) straight into an init field is a
confirmed real-world failure mode (`Invalid number in expression`) if the paste doesn't keep real line
breaks, since the comment can swallow the rest of the statement. Unlike **Configure** it needs no
curator-authentication bridge and never touches the server, because it never changes anything. A
turret whose only weapon is the horn is still reported (informational) but never gets a row.

**Vehicle Weapon Loadout - Copy From Nearby Vehicle** must be placed directly on the vehicle that
should *receive* the copied loadout. Its dialog picks the *source* vehicle to copy from:

| Control | Meaning |
|---|---|
| Copy loadout from | Nearby vehicle to copy from, discovered live within 100m of the target, nearest first |
| Copy Turret Weapons | Copy every turret path that exists on both vehicles (default on) |
| Copy Pylon Ordnance | Copy every pylon by index, including exact remaining ammo (default on) |

Routes through the curator-authenticated `Waldo_fnc_ZenVehicleWeaponLoadoutCopyServer` bridge to
`Waldo_fnc_VehicleWeaponLoadoutCopy`, which reads the source vehicle's real state and builds the
equivalent `Waldo_fnc_VehicleWeaponLoadoutApply` rows itself - the same public apply/validation path
every other entry point uses, just with the rows assembled from a live vehicle instead of typed in.
A source turret whose only weapon is the horn is skipped entirely and never copied - it is never a
combat weapon a mission maker means to copy, and the matching target path could be a real weapon that
would otherwise get silently overwritten with nothing useful.

## Notes and limitations

- Works on any `AllVehicles`-derived object with turrets and/or pylons - cars, tanks, boats, static
  weapons, aircraft. `Man` (soldiers/AI) is explicitly excluded even though it technically inherits
  from `AllVehicles` too in Arma 3's own config tree - use ACE Arsenal or the loadout/logistics system
  for a unit's own weapons instead.
- Safe to call again later on the same vehicle for further changes; each call is independent and
  nothing from a prior call is cached or assumed.
- This is a one-shot apply, not a saved/restorable profile - to persist a vehicle's full state across
  a mission (including weapon/ammo state) see [Persistence](Persistence) instead.
- Diagnostics/troubleshooting: every apply logs one `[WMP VEHWPN]` RPT line per call summarising every
  row's outcome; per-row failures name exactly which classname or turret/pylon reference was invalid.
- **The horn is never treated as a weapon.** A vehicle's horn is an ordinary `CfgWeapons` entry to the
  engine (identified here by `CfgWeapons` `displayName`, since there is no other reliable "not a
  combat weapon" flag), but Configure refuses every mutating action against a horn-only turret, Copy
  skips copying one, and Inspect reports one without a paste-ready row - across every entry point, not
  just the ZEN dialog. `Waldo_fnc_VehicleWeaponLoadoutApply` itself is unaffected: a mission-authored
  row can still target a horn-only turret directly (e.g. to genuinely remove a vehicle's horn), since
  that call has no beginner-facing dialog to guard.
- **`[-1]` is not guaranteed to have a real weapon mount.** `allTurrets` never returns `[-1]` itself -
  it is always prepended by hand as "the main/driver weapon slot" - so unlike every other discovered
  turret path it was never actually confirmed to correspond to a real, model-backed mount. Some
  vehicles' own class declares no root `weapons[]` array at all (an ordinary unarmed car, for
  instance), meaning `[-1]` has no physical mount whatsoever on that vehicle. WMP cannot create a new
  weapon mount on a vehicle that never had one - that needs model/config authoring work, not a script
  - so `ADD`/`REPLACE` against `[-1]` is refused outright on such a vehicle (a clear per-row failure,
  never a silent no-op that only looks like it worked). Configure labels a mount-less `[-1]`
  `(no weapon mount on this vehicle)` and never defaults to it. A real turret path from `allTurrets`
  never has this problem, since `allTurrets` only ever reports turrets that genuinely exist.
- **Not covered here: vehicle appearance.** Recoloring a vehicle (a "pink tank") or hiding part of its
  physical model (e.g. a turret cupola) is a completely different, unrelated Arma system - cosmetic
  model state, not weapon/ammo content. See [Vehicle Appearance](Vehicle-Appearance) for that feature.
  WMP's other closest existing feature is `Waldo_fnc_VehicleCamoSetup`, see [Vehicle Ambush Script And
  Vehicle Camo](Vehicle-Ambush-Script-And-Vehicle-Camo), which works by attaching physical deployable
  camo objects rather than texture-swapping the vehicle itself.

## See also

- The **Vehicle Weapon Loadout And Appearance Example** composition (`WMP_Compositions/`) places two
  identically-armed Hunters side by side (deliberately the same variant, so their `turret[0]` paths
  genuinely match - Copy only ever moves a path that exists on both vehicles); one copies the other's
  real turret loadout via `Waldo_fnc_VehicleWeaponLoadoutCopy` (no classname typed) and is recolored
  via `Waldo_fnc_VehicleAppearanceApply` - a working editor-time starting point for both features at
  once.
- [Vehicle Appearance](Vehicle-Appearance) - recoloring and physical-component show/hide, a separate
  feature for a genuinely different Arma system (cosmetic model state, not weapon/ammo content).
- [Airborne Gunship Support](Airborne-Gunship-Support) - turret *profiles* for crew assignment on a
  managed gunship, a different concern from editing what's actually mounted.
- [Persistence](Persistence) - saving/restoring a vehicle's state (including ammo) across a mission.
- [Zeus and Script API Parity](Zeus-And-Script-API-Parity) - how WMP keeps every Zeus module and its
  underlying script API in sync.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
