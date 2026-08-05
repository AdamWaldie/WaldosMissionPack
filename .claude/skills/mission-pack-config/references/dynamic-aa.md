# Dynamic Anti-Air

Named, server-authoritative radar-controlled air-defence zones. While its
radar is alive, hostile aircraft at/above the configured altitude floor
activate otherwise-dormant defences. Destroying the radar takes that system
offline. "Call-driven" pattern: config supplies asset pools/safety bounds,
a call or ZEN module creates each named system.

## Config (`MissionConfig\airOperationsConfig.sqf`)

```sqf
["Waldo_DynamicAA_SideAssetPools", createHashMapFromArray [ /* WEST/EAST/INDEPENDENT -> radarClasses/staticSitePools/mobileClasses/fighterClasses */ ]],
["Waldo_DynamicAA_FactionAssetPools", createHashMapFromArray [ /* optional narrower faction-keyed pools, independent of side */ ]],
// server, ADVANCED safety bounds:
["Waldo_DynamicAA_DefaultDetectionInterval", 1, false],
["Waldo_DynamicAA_MaximumRadius", 50000, false],
["Waldo_DynamicAA_MaximumAltitude", 10000, false],
["Waldo_DynamicAA_MaximumFighters", 12, false]
```

A faction pool overrides only the keys it defines; missing categories fall
back to the chosen operational side's pool.

## Scripted creation (`initServer.sqf`)

```sqf
private _aa = createHashMapFromArray [
    ["id", "north_sector"], ["displayName", "Northern Air Defence"],
    ["centre", getMarkerPos "aa_zone_north"], ["side", east],
    ["radius", 2500], ["minimumAltitude", 80], ["altitudeMode", "AUTO"],
    ["staticCount", 1], ["mobileCount", 1], ["fighterCount", 2]
];
[_aa] call Waldo_fnc_DynamicAACreate;
["north_sector", true] call Waldo_fnc_DynamicAADestroy;
```

Reusing an `id` safely replaces that system. `altitudeMode`: `AUTO`
(terrain-relative over land, sea-level over water), `ATL`, `ASL`. Key
defaults worth knowing: `radius` 2000m, `minimumAltitude` 50m,
`requiredOperationalRadars` 1, `maximumOperationalRadarDamage` 0.8,
`fighterCooldown` 300s, `cleanupOnRadarLoss` false (defaults to leaving
disabled assets rather than deleting them). Full key table in
`wiki/Dynamic-Anti-Air.md`.

## Optional radar shutdown objective

`shutdownInteraction: true` attaches an interaction-equipment procedure
(default `shutdownChallenge: "circuit"`, `shutdownDifficulty: "standard"`)
to the central radar as a non-destructive disable path, alongside the
default destroy-to-disable behaviour.

## Zeus

**WMP Combat Systems > Dynamic AA - Create** (system name, side, faction
profile or exact mixed equipment, detection/altitude/behaviour, map markers,
optional radar-shutdown objective — the server auto-places radar/static/
mobile assets in a spaced terrain-safe layout, no map clicks needed) and
**Dynamic AA - Remove Nearest**.

## Gotchas

- Detection is server-owned; AI state/targeting/ammo dispatch to each
  group's current owner, so systems keep working after AI moves to a
  headless client.
- Classnames are validated and two-pass placement-checked before anything
  spawns — if planning fails, nothing spawns; a materialisation failure
  rolls back every partial object/crew.
- `dwell`/`clearDelay` provide hysteresis so a boundary-skimming aircraft
  doesn't rapidly toggle the network.
