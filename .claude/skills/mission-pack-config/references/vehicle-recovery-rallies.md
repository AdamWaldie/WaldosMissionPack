# Vehicle recovery + squad rally points

Two related but independent systems, both server-registry/player-presentation
split, both replayed safely for JIP. Ask which the user means.

## Vehicle recovery ("register" pattern)

Opt-in per object. A damaged, empty, stationary registered vehicle can be
packaged into a transportable cargo object; delivering an unloaded grounded
package to a matching workshop restores the vehicle at a clear position.

```sqf
[repairDepot, "FOB_ALPHA", 50, west] call Waldo_fnc_RecoveryRegisterWorkshop;
[damagedTank, "FOB_ALPHA", 0.55, true, true, "B_Slingload_01_Cargo_F", true, 1]
    call Waldo_fnc_RecoveryRegisterVehicle;
[recoveryTruck, 10, "AUTO", 2] call Waldo_fnc_RecoveryRegisterCarrier;  // carrier mode: AUTO | VIRTUAL | PHYSICAL
```

Workshops take a key, delivery radius, serviced side (`sideUnknown` = all).
`RecoveryRegisterVehicle` args: workshop key, living-vehicle damage
threshold, accept-destroyed flag, engineer-required flag, package class,
inventory-preservation flag, restored fuel fraction, optional interaction
HashMap (below). A destroyed vehicle can't be resurrected as the same
object — recovery creates a replacement, restores its Eden variable name,
copies the configured custom-variable allowlist, and invokes
`Waldo_Recovery_OnRestored` for mission-specific rebinding. A living vehicle
is retained hidden and restored as the exact same object (identity,
handlers, actions preserved).

### Config (`MissionConfig\logisticsConfig.sqf`)

```sqf
["Waldo_Recovery_ScanInterval", 3],                  // seconds; ADVANCED
["Waldo_Recovery_NotificationRadius", 100],
["Waldo_Recovery_CreateWorkshopMarkers", true],
["Waldo_Recovery_PlacementClearance", 3],
["Waldo_Recovery_DefaultCustomVariables", ["Waldo_TransportService_Registration"]],
["Waldo_Recovery_PackageClasses", ["B_Slingload_01_Cargo_F", "Land_Pallet_MilBoxes_F"]]
```

### Optional recovery-prep interaction procedure

```sqf
private _interaction = createHashMapFromArray [
    ["enabled", true], ["challengeId", "repair"], ["difficulty", "standard"]
];
[damagedTank, "FOB_ALPHA", 0.55, true, true, "B_Slingload_01_Cargo_F", true, 1, _interaction]
    call Waldo_fnc_RecoveryRegisterVehicle;
```

Replaces immediate packaging with **Prepare Vehicle for Recovery**; on
success the same server-owned `PACK` request still runs every workshop/
damage/occupancy/movement/distance/engineer check.

### Zeus

**Vehicle Recovery - Register Workshop**, **- Register Vehicle** (policy +
optional prep procedure), **- Register Carrier** (Automatic/Virtual
Manifest/Physical Cargo Bay, 1–10 package capacity).

## Squad rally points ("automatic" pattern)

Temporary group-owned respawn positions the current group leader can
deploy/pack — respawn ownership and cooldown live on the *group*, so leader
death/reassignment doesn't orphan the state.

### Config (`MissionConfig\missionSystemsConfig.sqf`)

```sqf
["Waldo_Rally_Enable", false],
["Waldo_Rally_ObjectClass", "Land_SatelliteAntenna_01_F"],
["Waldo_Rally_Duration", 180], ["Waldo_Rally_DeploymentTime", 15], ["Waldo_Rally_Cooldown", 300],
["Waldo_Rally_EnemyExclusionRadius", 100], ["Waldo_Rally_MinimumGroupMembers", 2],
["Waldo_Rally_PlacementDistance", 2], ["Waldo_Rally_MaximumSlope", 20],
["Waldo_Rally_RespawnClearance", 2.5], ["Waldo_Rally_RespawnSearchDistance", 15],  // ADVANCED
["Waldo_Rally_AllowRegroup", false]  // direct movement to the rally, bypasses normal respawn flow — off by default
```

Server checks: leader alive, on foot, dry/level ground, outside the hostile
exclusion radius, minimum living group members. The rally marker is created
locally only for current group members and stays hidden from opposing
players.

### Zeus

**Respawn - Squad Rally Control** enables the feature; live changes publish
as an ordered setting bundle before player-local actions start.

## Gotchas

- Recovery: package discovery measures loading range between real bounding
  footprints, not model origins, so a large container beside a smaller
  vehicle isn't wrongly rejected.
- Recovery: crew and attached objects are **not** recreated for a destroyed
  vehicle — use `persistence.md` separately for long-term mission saves.
- Rally: enabling `AllowRegroup` bypasses the normal respawn flow — make
  sure that's actually wanted before turning it on.
