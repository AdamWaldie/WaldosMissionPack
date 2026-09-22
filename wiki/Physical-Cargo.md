# Physical cargo

> **Use this page when:** placing ACE-carried crates and props visibly on vehicles.

`Waldo_PhysicalCargo_Enable` in `MissionConfig/logisticsConfig.sqf` retains the pack's existing default of `true`. ACE and CBA are required. Carry an eligible object with ACE and aim the normal release click at a nearby vehicle surface. WMP traces the vehicle, then keeps the object's visible carried position and orientation when attaching it. It does not shift the object according to its bounding box. Aim elsewhere for an ordinary ground drop. The ACE interaction menu remains the route into internal ACE Cargo. The [supply crate options](Supply-Transfers) can turn ACE loading on or off for an individual registered crate.

WMP replaces ACE's carry-release callback only when it finds the expected callback and action ID. Otherwise native ACE release stays in place. The adapter uses a non-public ACE function, so check it after ACE updates. It does not infer player intent from ACE's stopped-carry event.

`ReammoBox_F` descendants are eligible by default. To register another non-weapon carryable object, call from `initServer.sqf`:

```sqf
[myObject] call Waldo_fnc_PhysicalCargoRegister;
```

Registration also asks ACE to make the object carryable unless WMP has already set it. The server keeps the mount record. Picking up the object or loading it into ACE Cargo restores its previous simulation and physics-collision state. WMP excludes static weapons from physical mounts after an HMG flipped a truck in testing. ACE Carry, ground drop and ACE Cargo remain available for them. WMP offers no working-weapon mount or gun-entry action.

Place ZEN **Physical Cargo - Eligibility** directly on a carryable prop or crate. It can allow or disallow future physical mounts, or report the object's current state. It rejects static weapons, vehicles, aircraft and boats. It cannot change eligibility while an object has a physical mount. Normal ACE Carry and Cargo remain available.

WMP-issued supply and medical crates, including crate compositions, follow the global flag. Starter crates receive no WMP logistics registration. They can still qualify through the ordinary `ReammoBox_F` class fallback while physical cargo is on.

WMP accepts a valid contact hit on land, air or sea vehicles. Test each intended cargo and vehicle combination in Arma before release.

`Waldo_PhysicalCargo_BlockSeats` defaults to `true`, but WMP will not guess seat indices or turret paths. A mission maker may provide verified model-space points for ordinary cargo seats and fire-from-vehicle (FFV) person-turret seats on a particular vehicle:

```sqf
myTruck setVariable ["Waldo_PhysicalCargo_SeatPoints", [
    ["CARGO", 0, [0.8, -0.5, 0.6]],
    ["TURRET", [1, 0], [-0.8, -0.5, 0.6]]
], true];
```

Those coordinates and turret path are examples. Measure them on the exact vehicle model. WMP locks a free cargo seat with `lockCargo` or a verified FFV person-turret with `lockTurret` when the seat point lies inside the mounted object's oriented footprint. Edge contact alone does not lock a seat. WMP tracks overlapping locks and releases only its own. Without verified points, seating stays unchanged. The legacy `[cargoIndex, point]` row remains valid for cargo seats.

The audit seat station uses a small crate and the NATO Prowler/DAGOR. It measures empty seat positions with a temporary hidden occupant at startup. It publishes positions confirmed by Arma. Use **REPORT VERIFIED SEATS** to check calibration. Mount the crate over a seat, then try that seat and a clear one. **CAPTURE MY OCCUPIED CARGO SEAT** can replace one measurement for diagnosis.

The first HEMMT and Polaris tests had empty seat maps and locked nothing. Later Polaris and NATO Prowler tests blocked the covered seat and left a clear seat usable. The **Supply Transfers and Physical Cargo Example** composition includes the six measured points for its exact vanilla Prowler class; those coordinates must not be copied to a different vehicle model. Other models and locality changes still need testing.

The carrier must stand near the object and contact point. The vehicle must be almost stationary. A bad or missing hit gives an ordinary ground drop. A rejected mount must leave the object recoverable. Use ACE **Carry** to take mounted cargo off, then drop it on clear ground or mount it elsewhere. Direct detachment could clip the object into the vehicle, so there is no **Unload physical cargo** action. Scripts can call `Waldo_fnc_PhysicalCargoUnmountServer` for controlled removal.

Dedicated-server, JIP, ownership migration, moving-vehicle, deletion and representative modded-vehicle checks remain outstanding. The first ACE-menu opening on a physical-cargo crate has sometimes hitched. The changes to duplicate ACE carry setup and WMP menu actions still need an in-game retest.

## See also

- [Supply Transfers](Supply-Transfers)
- [Logistics System, Starter Crates and Quartermaster](Logistics-System,-Starter-Crates-And-Quartermaster)
- [Vehicle Recovery and Squad Rally Points](Vehicle-Recovery-And-Squad-Rallies)
- [Mission Configuration Reference](Mission-Configuration-Reference)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
