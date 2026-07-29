# Vehicle Recovery and Squad Rally Points

> **Use this page when:** you want recoverable vehicle logistics or temporary squad-owned respawn positions.

Both systems keep authoritative registries and world mutation on the server and presentation on player machines. Only client-consumed object/group state is broadcast. Their actions are replayed safely for joining players, requests are checked against the requesting player's network owner, and normal feedback uses the WMP notification cards.

## Vehicle recovery

Vehicle recovery is opt-in per object. Register one or more workshops, recoverable vehicles and optional carrier vehicles. A damaged, empty and stationary registered vehicle can be packaged into a transportable cargo object. When an unloaded, grounded package enters a workshop with the matching key, the server restores the vehicle at a clear position.

```sqf
[repairDepot, "FOB_ALPHA", 50, west] call Waldo_fnc_RecoveryRegisterWorkshop;
[damagedTank, "FOB_ALPHA", 0.55, true, true, "B_Slingload_01_Cargo_F", true, 1]
    call Waldo_fnc_RecoveryRegisterVehicle;
[recoveryTruck, 10] call Waldo_fnc_RecoveryRegisterCarrier;
```

Workshops accept a key, delivery radius and serviced side (`sideUnknown` permits all sides). `RecoveryRegisterVehicle` accepts the workshop key, living-vehicle damage threshold, whether destroyed vehicles are accepted, whether an engineer is required, package class, inventory-preservation policy and restored fuel fraction. The system also restores textures and pylon magazines. A registered recovery carrier remains a carrier after it is recovered.

The server uses one configurable scan loop (`Waldo_Recovery_ScanInterval`, default 3 seconds) for all packages. Registration is repeat-safe. Actions are object-keyed for JIP and disappear with the deleted original/package object. Packaging, loading and unloading feedback is sent only to the operator performing that action. A completed workshop restoration notifies only friendly players within `Waldo_Recovery_NotificationRadius` (default 100 metres); an individual workshop can override that radius through the optional fifth registration argument. Registered workshops create two global engine markers by default: a shaded circle showing the delivery radius and a labelled point showing the workshop's exact position. Their colour follows the serviced side. Set `Waldo_Recovery_CreateWorkshopMarkers` to `false`, or pass `false` as the optional sixth registration argument, to suppress both markers.

ZEN provides three modules:

- **Vehicle Recovery - Register Workshop** configures a nearby object's key and radius and can export its setup call.
- **Vehicle Recovery - Register Vehicle** configures the nearest vehicle's recovery policy.
- **Vehicle Recovery - Register Carrier** enables package loading and unloading on the nearest vehicle.

Recovery deliberately creates a repaired replacement rather than preserving live simulation damage. Crew, attached objects and arbitrary mission-script variables are not copied. Use persistence separately for long-term mission saves.

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

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
