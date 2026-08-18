# Vehicle Weapon Loadout

> **Use this page when:** you want to arm, rearm, disarm, or swap the weapons/ammo on a specific vehicle - a turret weapon, its magazines, or an aircraft pylon's ordnance - through a script call or Zeus, instead of hand-writing `removeWeaponTurret`/`addWeaponTurret`/`setPylonLoadOut`.

_Associated Files: `MissionScripts\CombatSystems\VehicleWeaponLoadout\vehicleWeaponLoadoutApply.sqf`, `MissionScripts\ZenModules\Zen_vehicleWeaponLoadoutModule.sqf`, `MissionScripts\ZenModules\zenVehicleWeaponLoadoutServer.sqf`, `Waldo_fnc_VehicleWeaponLoadoutApply`, `Waldo_fnc_ZenVehicleWeaponLoadout`, `Waldo_fnc_ZenVehicleWeaponLoadoutServer`_

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
| `magazineCount` | NUMBER | Rounds loaded for a TURRET magazine (default 1). Ignored for PYLON rows - `setPylonLoadOut`'s own ammo flag always loads a pylon to its full config-defined count. |

Multiple rows apply independently in one call - a bad row (unknown classname, non-existent turret
path/pylon index) is reported for that row only and never blocks the rest. The return value is
`[[ok, detail], ...]`, one entry per row, in the same order.

```sqf
// Strip a coax MG off turret [0], and load pylon 1 with a GBU-12 pod:
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

### Magazine/weapon compatibility

A magazine's fit against the requested weapon is checked with `compatibleMagazines` and logged if it
looks wrong - but this is **only a warning**, never a hard rejection. `compatibleMagazines` is
muzzle-specific (a weapon can carry more than one muzzle, e.g. a rifle plus an underslung grenade
launcher) and a loadout row doesn't ask which muzzle is meant, so a combination that looks wrong
against the primary muzzle can still be exactly right against a secondary one. If a row is rejected
outright, it's always because the weapon or magazine classname itself doesn't exist in the loaded
modset - check the RPT (`[WMP VEHWPN]`) for the exact per-row reason.

## Zeus module

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

There's no in-game "what weapons fit this turret" query in Arma itself, so weapon and magazine
classnames are still typed in rather than picked from a filtered list - look up the exact classname
from the vehicle's config, a modded weapon's documentation, or the Bohemia Interactive Community
wiki before typing it in.

Submitting the dialog routes through the curator-authenticated `Waldo_fnc_ZenVehicleWeaponLoadoutServer`
bridge (same pattern as **Plant Signal Tracker**'s `Waldo_fnc_ZenTrackerServer`) before calling the
same public `Waldo_fnc_VehicleWeaponLoadoutApply` API mission scripts use directly, and reports the
outcome back to the curator as a WMP notification card.

## Notes and limitations

- Works on any `AllVehicles`-derived object with turrets and/or pylons - cars, tanks, boats, static
  weapons, aircraft.
- Safe to call again later on the same vehicle for further changes; each call is independent and
  nothing from a prior call is cached or assumed.
- This is a one-shot apply, not a saved/restorable profile - to persist a vehicle's full state across
  a mission (including weapon/ammo state) see [Persistence](Persistence) instead.
- Diagnostics/troubleshooting: every apply logs one `[WMP VEHWPN]` RPT line per call summarising every
  row's outcome; per-row failures name exactly which classname or turret/pylon reference was invalid.

## See also

- [Airborne Gunship Support](Airborne-Gunship-Support) - turret *profiles* for crew assignment on a
  managed gunship, a different concern from editing what's actually mounted.
- [Persistence](Persistence) - saving/restoring a vehicle's state (including ammo) across a mission.
- [Zeus and Script API Parity](Zeus-And-Script-API-Parity) - how WMP keeps every Zeus module and its
  underlying script API in sync.
