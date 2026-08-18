# Vehicle Weapon Loadout (custom turret/pylon add, replace, remove)

Associated files: `MissionScripts\CombatSystems\VehicleWeaponLoadout\vehicleWeaponLoadoutApply.sqf`
(`Waldo_fnc_VehicleWeaponLoadoutApply`), `MissionScripts\ZenModules\Zen_vehicleWeaponLoadoutModule.sqf`
(`Waldo_fnc_ZenVehicleWeaponLoadout`), `MissionScripts\ZenModules\zenVehicleWeaponLoadoutServer.sqf`
(`Waldo_fnc_ZenVehicleWeaponLoadoutServer`). No `MissionConfig` file — this is a call/ZEN-only
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
    ["TURRET", [-1], -1, "REPLACE", "arifle_MX_F", "30Rnd_65x39_caseless_mag", 6]
]] call Waldo_fnc_VehicleWeaponLoadoutApply;
```
`Waldo_fnc_VehicleWeaponLoadoutApply` takes `[vehicle, rows]`. Each row:
`[targetType, turretPath, pylonIndex, action, weaponClass, magazineClass, magazineCount]`.

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
- `magazineCount`: rounds loaded for a TURRET magazine (optional, default 1). Ignored for pylons —
  `setPylonLoadOut`'s own ammo flag always loads a pylon to its full config-defined count.

Multiple rows in one call apply independently — a bad row (unknown classname, non-existent turret
path/pylon index) is reported per-row and never blocks the others. Return value is
`[[ok, detail], ...]`, one entry per row, in order.

A magazine's compatibility with a weapon is checked via `compatibleMagazines` only as a **logged
warning**, never a hard rejection — `compatibleMagazines` is muzzle-specific (a weapon can have more
than one muzzle, e.g. a rifle plus an underslung grenade launcher) and this call doesn't ask which
muzzle is meant, so a mismatch against the primary muzzle can still be a real, valid combination
against a secondary one.

## Zeus module

**"Vehicle Weapon Loadout - Configure"** (category **WMP AI & Combat**) — must be placed **directly
on the vehicle** to edit, same convention as **Plant Signal Tracker**; placing it on open ground or
any other object is rejected with an on-screen notice. The dialog's turret list, pylon list, and
current-loadout labels are all discovered live from that exact vehicle (`allTurrets`,
`getPylonMagazines`, and the `TransportPylonsComponent` config for pylon display names) — never a
hand-typed list — so only choices that vehicle actually supports are ever shown. Weapon and magazine
classnames are still typed in (there's no general "what weapons fit this turret" engine query), so
get exact classnames from the vehicle's/weapon's config or a reference like the biki before typing
them in. Routes through the curator-authenticated `Waldo_fnc_ZenVehicleWeaponLoadoutServer` bridge
before calling the same public function mission scripts use directly.

## Notes

- `"AllVehicles"` gate: works on any turreted or pylon-equipped vehicle — cars, tanks, boats, static
  weapons, aircraft.
- Safe to call again later on the same vehicle for further changes; each call is independent, nothing
  is cached from a prior call.
- This is a one-shot apply, not a persistent profile system — for saving/restoring a full vehicle
  state across sessions, see `persistence.md` instead.
