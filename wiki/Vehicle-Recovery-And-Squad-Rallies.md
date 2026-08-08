# Vehicle Recovery and Squad Rally Points

> **Use this page when:** you want recoverable vehicle logistics or temporary squad-owned respawn positions.

Both systems keep authoritative registries and world mutation on the server and presentation on player machines. Only client-consumed object/group state is broadcast. Their actions are replayed safely for joining players, requests are checked against the requesting player's network owner, and normal feedback uses the WMP notification cards.

## Vehicle recovery

Vehicle recovery is opt-in per object. Register one or more workshops, recoverable vehicles and optional carrier vehicles. A damaged, empty and stationary registered vehicle can be packaged into a transportable cargo object. When an unloaded, grounded package enters a workshop with the matching key, the server restores the vehicle at a clear position.

Quickest working setup — every call below only needs its first argument (the object), so a mission maker can drop three objects and go, then tighten the details later:

```sqf
[this] call Waldo_fnc_RecoveryRegisterWorkshop;   // in a repair depot's init field - key/radius/side all default
[this] call Waldo_fnc_RecoveryRegisterVehicle;    // in a damaged vehicle's init field - workshop key defaults too
[this] call Waldo_fnc_RecoveryRegisterCarrier;    // in a truck's init field - mode defaults to AUTO
```

The `[WMP]Vehicle_Recovery_Workshop_Example_Minimal` composition (see [Eden Compositions](Eden-Compositions)) places all three pre-wired this way. For explicit control over every option:

```sqf
[repairDepot, "FOB_ALPHA", 50, west] call Waldo_fnc_RecoveryRegisterWorkshop;
[damagedTank, "FOB_ALPHA", 0.55, true, true, "B_Slingload_01_Cargo_F", true, 1]
    call Waldo_fnc_RecoveryRegisterVehicle;
[recoveryTruck, 10, "AUTO", 2] call Waldo_fnc_RecoveryRegisterCarrier;
```

Workshops accept a key, delivery radius and serviced side (`sideUnknown` permits all sides). `RecoveryRegisterVehicle` accepts the workshop key, living-vehicle damage threshold, whether destroyed vehicles are accepted, whether an engineer is required, package class, inventory-preservation policy and restored fuel fraction. The system also restores textures and pylon magazines. `RecoveryRegisterCarrier` accepts loading range, cargo mode and package capacity. A registered recovery carrier remains a carrier with the same mode and capacity after it is recovered.

Carrier mode is `"AUTO"`, `"VIRTUAL"` or `"PHYSICAL"`. Automatic mode uses Arma's visible vehicle-in-vehicle cargo only when `vehicleCargoEnabled` and `canVehicleCargo` confirm that the selected package fits; otherwise it uses the virtual manifest. Virtual mode therefore works with ordinary trucks, MRAPs, boats and other registered vehicles that have no engine-configured cargo bay. Physical mode is intentionally strict and refuses packages that do not fit. Package discovery uses the authoritative server registry and measures loading range between the real bounding footprints of carrier and package, so a large container parked directly beside a smaller vehicle is not rejected because their model origins are farther apart. While virtually carried, the real server-owned package is hidden and simulation-disabled rather than deleted, preserving its recovery state. Unloading at the matching workshop queues restoration directly; unloading elsewhere searches for a complete clear package footprint beside the carrier. Carrier destruction spills virtual packages only when a clear position is available, and an obstructed package remains protected for a later retry.

The recovery object is independently configurable per recoverable vehicle through argument 5 of `Waldo_fnc_RecoveryRegisterVehicle`. For Zeus, extend `Waldo_Recovery_PackageClasses` with valid `CfgVehicles` classes before runtime configuration; the module converts that pool into a display-name dropdown. The default pool is `B_Slingload_01_Cargo_F` and `Land_Pallet_MilBoxes_F`. The server validates the selected class and falls back to the first valid configured entry.

Recovery preparation can optionally use the shared interaction procedures. The feature's semantic
default is `repair / standard`; script options can override it without changing the recovery API:

```sqf
private _interaction = createHashMapFromArray [
    ["enabled", true],
    ["challengeId", "repair"],
    ["difficulty", "standard"]
];
[damagedTank, "FOB_ALPHA", 0.55, true, true, "B_Slingload_01_Cargo_F", true, 1, _interaction]
    call Waldo_fnc_RecoveryRegisterVehicle;
```

When enabled, **Prepare Vehicle for Recovery** replaces immediate packaging. Successful completion
submits the same server-owned `PACK` request, so workshop, damage, occupancy, movement, distance and
engineer checks still run after the procedure. With the option disabled, the existing packaging action
is unchanged.

The server uses one configurable scan loop (`Waldo_Recovery_ScanInterval`, default 3 seconds) for all packages. Registration is repeat-safe. Actions are object-keyed for JIP and disappear with the deleted original/package object. Packaging, loading and unloading feedback is sent only to the operator performing that action. A completed workshop restoration notifies only friendly players within `Waldo_Recovery_NotificationRadius` (default 100 metres); an individual workshop can override that radius through the optional fifth registration argument. Registered workshops create two global engine markers by default: a shaded circle showing the delivery radius and a labelled point showing the workshop's exact position. Their colour follows the serviced side. Set `Waldo_Recovery_CreateWorkshopMarkers` to `false`, or pass `false` as the optional sixth registration argument, to suppress both markers.

Restoration samples bounded rings outside the workshop's real model bounds plus the recovered vehicle footprint and `Waldo_Recovery_PlacementClearance`. Candidates are terrain-snapped and rejected when ordinary or terrain objects occupy the full clearance area. If no safe point exists, the package remains for a later retry; the system never falls back to the workshop origin or creates a vehicle inside another object.

ZEN provides three modules:

- **Vehicle Recovery - Register Workshop** configures a nearby object's key and radius and can export its setup call.
- **Vehicle Recovery - Register Vehicle** configures the nearest vehicle's recovery policy and an optional simplified preparation procedure: enable, procedure and difficulty.
- **Vehicle Recovery - Register Carrier** enables package loading and unloading on the nearest vehicle and exposes Automatic, Virtual Manifest or Physical Cargo Bay handling plus a 1–10 package capacity.

Living vehicles are retained hidden while packaged and restored as the same object, preserving object identity, event handlers, actions, applied scripts and external references. A destroyed vehicle cannot be resurrected reliably, so that path creates a replacement, restores its Eden variable name, copies the configured custom-variable allowlist and invokes `Waldo_Recovery_OnRestored` for mission-specific rebinding. Crew and attached objects are not recreated. Use persistence separately for long-term mission saves.

## Squad rally points

Set `Waldo_Rally_Enable = true`, or enable the feature with **Respawn - Squad Rally Control**. The current leader of a qualifying group receives controls to deploy or pack the group's temporary rally. Respawn ownership and cooldown live on the group, so leader death or reassignment does not orphan the state.

The server checks that the leader is alive, on foot, over dry and sufficiently level ground, outside the configured hostile exclusion radius, and commands the minimum number of living group members. It chooses a clear position and adds a group-scoped respawn position. The rally marker is created locally only for current group members and is replayed safely for JIP without revealing it to opposing players. All state is removed when the object is destroyed, packed, expires, or the feature is disabled.

Primary settings in `init.sqf` are:

| Setting | Default | Purpose |
|---|---:|---|
| `Waldo_Rally_Enable` | `false` | Enables player-local squad rally controls |
| `Waldo_Rally_ObjectClass` | `Land_SatelliteAntenna_01_F` | Rally world object |
| `Waldo_Rally_Duration` | `180` | Active seconds |
| `Waldo_Rally_DeploymentTime` | `15` | Uninterrupted leader deployment time |
| `Waldo_Rally_Cooldown` | `300` | Group cooldown from deployment |
| `Waldo_Rally_EnemyExclusionRadius` | `100` | Hostile exclusion radius in metres |
| `Waldo_Rally_MinimumGroupMembers` | `2` | Living group members required |
| `Waldo_Rally_PlacementDistance` | `2` | Placement distance ahead of the leader |
| `Waldo_Rally_MaximumSlope` | `20` | Maximum surface angle in degrees |
| `Waldo_Rally_AllowRegroup` | `false` | Allows direct movement to the rally |

Direct regroup is disabled by default because it bypasses the normal respawn flow. When deliberately enabled, only a living member of the owning group can request it and the server selects a clear destination beside the active rally.

Runtime ZEN changes are published as an ordered setting bundle before client actions start. JIP clients request the latest server snapshot; disabling the system removes local actions, clears its keyed initializer and removes active rallies.

## See also

- [Eden Compositions](Eden-Compositions)
- [Optional Feature Systems](Optional-Feature-Systems)
- [Transport Services](Transport-Services)
- [Mission Configuration Reference](Mission-Configuration-Reference)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
