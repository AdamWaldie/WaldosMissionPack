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
["Waldo_DynamicAA_MaximumFighters", 12, false],
["Waldo_DynamicAA_MaxSlopeDegrees", 12, false]
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
disabled assets rather than deleting them).

### Eden composition (beginner drop-in)

`WMP_Compositions/[WMP]Dynamic_AA_Example_Minimal` anchors a system to a
placed object with only `id` and `centre` set — every other key (side,
radius, altitude, asset counts) takes its default above. `_Full` shows
every option explicitly on the same anchor object. Both need real open,
reasonably flat ground nearby — see the Gotchas section above if placement
is rejected.

Full key table in
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
- If a user reports "rejected placement" on ground that looks open and
  flat, the two things to check are `Waldo_DynamicAA_MaxSlopeDegrees`
  (default 12° — a component whose exact candidate spot is steeper than
  this is rejected the same way a nearby tree/building would be, and the
  ring search keeps walking outward for a flatter shelf) and per-component
  clearance, which is derived from `sizeOf` (a map-icon-size estimate, not
  true physical geometry) scaled conservatively rather than generously so a
  large map-icon class like `Land_Radar_F` doesn't reject placement across
  an entire search radius; the object-blocker check also ignores nearby
  units/curator logic objects rather than treating anything nearby as an
  obstruction. The RPT/ZEN error names which component failed.
