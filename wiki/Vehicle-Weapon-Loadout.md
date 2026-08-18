# Vehicle Weapon Loadout

> **Use this page when:** you want to arm, rearm, disarm, or swap the weapons/ammo on a specific vehicle - a turret weapon, its magazines, or an aircraft pylon's ordnance - through a script call or Zeus, instead of hand-writing `removeWeaponTurret`/`addWeaponTurret`/`setPylonLoadOut`.

_Associated Files: `MissionScripts\CombatSystems\VehicleWeaponLoadout\vehicleWeaponLoadoutApply.sqf`, `vehicleWeaponLoadoutInspect.sqf`, `MissionScripts\ZenModules\Zen_vehicleWeaponLoadoutModule.sqf`, `zenVehicleWeaponLoadoutServer.sqf`, `Zen_vehicleWeaponLoadoutInspectModule.sqf`, `Waldo_fnc_VehicleWeaponLoadoutApply`, `Waldo_fnc_VehicleWeaponLoadoutInspect`, `Waldo_fnc_ZenVehicleWeaponLoadout`, `Waldo_fnc_ZenVehicleWeaponLoadoutServer`, `Waldo_fnc_ZenVehicleWeaponLoadoutInspect`_

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
    ["TURRET", [-1], -1, "REPLACE", "arifle_MX_F", "30Rnd_65x39_caseless_mag", 6]
]] call Waldo_fnc_VehicleWeaponLoadoutApply;
```

Each row is `[targetType, turretPath, pylonIndex, action, weaponClass, magazineClass, magazineCount]`:

| Field | Type | Meaning |
|---|---|---|
| `targetType` | STRING | `"TURRET"` or `"PYLON"` |
| `turretPath` | ARRAY | Required for TURRET rows, e.g. `[-1]` (main/driver weapon), `[0]`, `[0,0]`. Ignored for PYLON rows. |
| `pylonIndex` | NUMBER | Required for PYLON rows, 1-based hardpoint index. Ignored for TURRET rows. |
| `action` | STRING | TURRET: `ADD`, `REPLACE` (strips the turret first), `REMOVE` (one named weapon/magazine), `CLEAR` (whole turret). PYLON: `SET` (aliases `ADD`/`REPLACE` accepted), `CLEAR`. |
| `weaponClass` | STRING | `CfgWeapons` class - TURRET rows only. |
| `magazineClass` | STRING | `CfgMagazines` class - the turret magazine to load (TURRET, optional) or the pylon's ordnance itself (PYLON, required for `SET`). |
| `magazineCount` | NUMBER | Rounds loaded for a TURRET magazine (default 1). Ignored for PYLON rows - a pylon is always explicitly loaded to its full `CfgMagazines`-defined ammo count via `setAmmoOnPylon` (`setPylonLoadOut`'s own third argument is a `forced`-compatibility flag, not an ammo-load flag, and never loads ammo by itself). |

Multiple rows apply independently in one call - a bad row (unknown classname, non-existent turret
path/pylon index) is reported for that row only and never blocks the rest. The return value is
`[[ok, detail], ...]`, one entry per row, in the same order.

```sqf
// Strip a coax MG off turret [0] (exact coax classname varies per vehicle family - confirm
// it with Inspect below rather than assuming "LMG_Coax" is universal), and load pylon 1 with a
// GBU-12 pod:
[this, [
    ["TURRET", [0], -1, "REMOVE", "LMG_Coax", "", 0],
    ["PYLON", [-1], 1, "SET", "", "6Rnd_GBU12_x_AGM_65E2_Pylon", 0]
]] call Waldo_fnc_VehicleWeaponLoadoutApply;

// Clear a turret completely:
[this, [["TURRET", [-1], -1, "CLEAR", "", "", 0]]] call Waldo_fnc_VehicleWeaponLoadoutApply;
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
list against. This means classnames are always typed in, never picked from a guaranteed-compatible
list - which is exactly the beginner pain point this section (and the **Inspect** module below) exist
to solve.

**Fastest option - copy from a vehicle you already like:** place **Vehicle Weapon Loadout - Inspect**
directly on any vehicle (a stock/vanilla one works great - you don't need to own or have configured
it) and it prints every turret's and pylon's exact current classnames as a full-screen `hint`, each
followed by a ready-to-paste row, in this format (illustrative - the exact classnames always come from
whatever vehicle you actually inspect, not from this page; the pairing shown here, a tank cannon plus
its HE round, is the one Bohemia's own `addWeaponTurret` documentation example uses):

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

**Other official ways to find a classname**, in order of how likely a beginner is to already have
them available:
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
| Turret | Which turret path to change (used when target is Turret weapon) |
| Turret Action | Add Weapon / Replace Turret / Remove Weapon / Clear Turret |
| Weapon Classname | `CfgWeapons` class to add/replace/remove - ignored for Clear and for pylons |
| Magazine Classname | `CfgMagazines` class - a turret's magazine, or a pylon's ordnance |
| Magazine Count | Rounds loaded into a turret magazine - ignored for pylons and for Remove/Clear |
| Pylon | Which hardpoint to change (used when target is Aircraft pylon) |
| Pylon Action | Set Ordnance / Clear Pylon |

Weapon and magazine classnames are still typed in rather than picked from a filtered list - see
[Finding the exact classnames](#finding-the-exact-classnames-beginner-friendly) above, especially the
**Inspect** module below, before typing one in from memory.

Submitting the dialog routes through the curator-authenticated `Waldo_fnc_ZenVehicleWeaponLoadoutServer`
bridge (same pattern as **Plant Signal Tracker**'s `Waldo_fnc_ZenTrackerServer`) before calling the
same public `Waldo_fnc_VehicleWeaponLoadoutApply` API mission scripts use directly, and reports the
outcome back to the curator as a WMP notification card.

**Vehicle Weapon Loadout - Inspect** (same category, same placed-directly-on-the-vehicle convention)
is the read-only companion module described above under [Finding the exact
classnames](#finding-the-exact-classnames-beginner-friendly) - no dialog, acts immediately, and shows
the report as a full-screen `hint` on the curator's own client. Unlike **Configure** it needs no
curator-authentication bridge and never touches the server, because it never changes anything.

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
- **Out of scope: vehicle appearance.** Recoloring a vehicle (a "pink tank") or hiding part of its
  physical model (e.g. a turret cupola) is a completely different, unrelated Arma system - cosmetic
  model state, not weapon/ammo content - and neither this feature nor any current WMP script covers
  it. Recoloring is done with
  [`setObjectTextureGlobal [selection, texturePath]`](https://community.bistudio.com/wiki/setObjectTextureGlobal),
  where `selection` is an index/name from the vehicle's own config-declared
  [`hiddenSelections[]`](https://community.bistudio.com/wiki/CfgVehicles_Config_Reference) array (a
  vehicle can only be recolored on selections its own model/config actually exposes - there's no
  universal "paint any vehicle pink" texture slot). Hiding a named model part uses
  [`hideSelection ["name", true]`](https://community.bistudio.com/wiki/hideSelection), which likewise
  only works for a selection name the model's original author actually gave that part - discover
  either with [`selectionNames vehicle`](https://community.bistudio.com/wiki/selectionNames). WMP's
  closest existing feature is `Waldo_fnc_VehicleCamoSetup`, see [Vehicle Ambush Script And Vehicle
  Camo](Vehicle-Ambush-Script-And-Vehicle-Camo) - and it works by attaching physical deployable camo
  objects, not by texture-swapping the vehicle itself. If your mission wants scripted vehicle
  recoloring/part-hiding as a WMP feature rather than hand-rolled script, that would be a new,
  separate feature request.

## See also

- [Airborne Gunship Support](Airborne-Gunship-Support) - turret *profiles* for crew assignment on a
  managed gunship, a different concern from editing what's actually mounted.
- [Persistence](Persistence) - saving/restoring a vehicle's state (including ammo) across a mission.
- [Zeus and Script API Parity](Zeus-And-Script-API-Parity) - how WMP keeps every Zeus module and its
  underlying script API in sync.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
