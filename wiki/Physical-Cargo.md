# Physical cargo

> **Use this page when:** you want ACE-carried objects to sit visibly on vehicles.

`Waldo_PhysicalCargo_Enable` in `MissionConfig/logisticsConfig.sqf` retains the pack's existing default of `true`. ACE and CBA are required. Carry an eligible object with ACE and aim the normal release click at a nearby vehicle surface. WMP traces the vehicle, then keeps the object's visible carried position and orientation when attaching it. It does not shift the object according to its bounding box. Aim elsewhere for an ordinary ground drop. The ACE interaction menu remains the route into internal ACE Cargo. The [supply crate options](Supply-Transfers) can turn ACE loading on or off for an individual registered crate.

WMP does not use ACE's stopped-carry event to infer intent. It replaces ACE's default carry-release callback only when the expected callback and action ID are present. If that contract is unavailable, native ACE release remains in place. This adapter uses an ACE function marked non-public, so test it again after ACE updates.

`ReammoBox_F` descendants are eligible by default. To register another non-weapon carryable object, call from `initServer.sqf`:

```sqf
[myObject] call Waldo_fnc_PhysicalCargoRegister;
```

Registration also asks ACE to make the object carryable, unless WMP has already published that ACE setting for the same object. The server retains the mount record. When a player picks up the object or loads it into ACE Cargo, WMP restores its prior simulation and physics-collision state. Static weapons are excluded from WMP physical mounting entirely: an HMG flipped a truck even when the intended mount was inert. Their native ACE Carry, ground drop and ACE Cargo paths remain available. WMP no longer offers a working-weapon mount or gun-entry action.

ZEN **Physical Cargo - Eligibility** can allow or disallow future physical mounts for a directly selected carryable prop/crate, or inspect its current state. It rejects static weapons and carrier vehicles, aircraft and boats; it cannot disable eligibility while an object is mounted, and it does not remove normal ACE Cargo or carry behaviour. WMP-issued supply/medical crates and crate compositions follow the global feature flag automatically; starter crates do not receive WMP logistics registration, though ordinary `ReammoBox_F` class fallback eligibility still applies when physical cargo is enabled.

WMP tries any land, air or sea vehicle with a valid contact hit. It does not maintain a mod-class whitelist. Test each intended cargo/vehicle combination in Arma before mission release.

`Waldo_PhysicalCargo_BlockSeats` defaults to `true`, but WMP will not guess seat indices or turret paths. A mission maker may provide verified model-space points for ordinary cargo seats and fire-from-vehicle (FFV) person-turret seats on a particular vehicle:

```sqf
myTruck setVariable ["Waldo_PhysicalCargo_SeatPoints", [
    ["CARGO", 0, [0.8, -0.5, 0.6]],
    ["TURRET", [1, 0], [-0.8, -0.5, 0.6]]
], true];
```

Those coordinates and turret path are examples, not universal geometry. Check them against that exact vehicle model. WMP locks a free indexed cargo seat with `lockCargo` or a free verified FFV person-turret with `lockTurret` only when its measured point lies clearly inside the mounted object's oriented footprint. Edge contact alone does not lock a seat. It tracks overlapping WMP locks and releases only its own locks. Without verified points, WMP leaves seating alone. The legacy `[cargoIndex, point]` row remains accepted for ordinary cargo seats.

The audit's seat station uses a small crate and, with `-IncludeRhsPolaris`, the installed RHSUSAF Polaris MRZR 4; otherwise it uses a vanilla Prowler. The disposable station measures its empty seat positions with a temporary hidden occupant at startup, and publishes only positions that Arma confirms. Use **REPORT VERIFIED SEATS** to confirm calibration, mount the crate over one of those seats, and try to enter that exact seat. The optional ACE self-action **CAPTURE MY OCCUPIED CARGO SEAT** can replace an individual measurement for diagnosis; it is not a required test step. The earlier HEMMT and Polaris screenshots were genuine failures: both vehicles had an empty seat map, so no lock was attempted. The revised automatic station calibration and lock paths still need live verification.

The carrier must stand near the object and contact point, and the vehicle must be almost stationary. A bad or missing surface hit causes an ordinary ground drop. A server-rejected mount must leave the object recoverable. To remove mounted cargo, use ACE **Carry**, then release it on clear ground or remount it elsewhere. The former **Unload physical cargo** menu action is gone because detaching directly could clip into the vehicle. `Waldo_fnc_PhysicalCargoUnmountServer` remains a script API for controlled use, but it is not a player interaction. Dedicated-server, JIP, ownership migration, moving-vehicle, deletion and representative modded-vehicle acceptance remains outstanding. The first ACE-menu opening on a physical-cargo crate has caused a visible hitch in testing; removing duplicate ACE carry setup and WMP's extra menu actions needs an in-engine retest before this can be called resolved.

## See also

- [Supply Transfers](Supply-Transfers)
- [Logistics System, Starter Crates and Quartermaster](Logistics-System,-Starter-Crates-And-Quartermaster)
- [Vehicle Recovery and Squad Rally Points](Vehicle-Recovery-And-Squad-Rallies)
- [Mission Configuration Reference](Mission-Configuration-Reference)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
