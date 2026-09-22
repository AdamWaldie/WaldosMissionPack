# Physical cargo

> **Use this page when:** placing ACE-carried crates and props visibly on vehicles.

ACE and CBA are required. `Waldo_PhysicalCargo_Enable` is already `true` in
`MissionConfig/logisticsConfig.sqf`. WMP supply crates qualify without another setup call. Carry a
crate with ACE, then release it while aiming at a nearby vehicle. The crate stays where you held it.
Release it away from the vehicle to drop it on the ground. ACE's menu still loads the crate inside
ACE Cargo. The [crate options](Supply-Transfers) can enable or disable that loading choice per crate.

For another non-weapon prop, put this in the prop's Eden **Init** field:

```sqf
[this] call Waldo_fnc_PhysicalCargoRegister;
```

The same call works in `initServer.sqf` with a named object in place of `this`. WMP also asks ACE to
make that prop carryable. WMP rejects visible mounts for static weapons after an HMG flipped a test vehicle.
Players can still use ACE Carry, ground drop and ACE Cargo for static weapons. WMP has no working
weapon mount or gun-entry action.

Place ZEN **Physical Cargo - Eligibility** directly on a carryable prop or crate to allow future
mounts, disallow them or inspect the current state. The module rejects static weapons, vehicles,
aircraft and boats. It cannot change eligibility while the object has a mount. ACE Carry and Cargo
remain available.

WMP-issued supply and medical crates, including crate compositions, follow the global flag. Starter
crates do not receive logistics registration, but still qualify if their class inherits from
`ReammoBox_F`.

WMP accepts a valid contact hit on land, air or sea vehicles. Test each crate and vehicle combination
in Arma before using it in a mission.

## Seats covered by cargo

`Waldo_PhysicalCargo_BlockSeats` defaults to `true`. The **Supply Transfers and Physical Cargo
Example** has six measured seat positions for its vanilla NATO Prowler/DAGOR. With another vehicle,
measure the seat positions on that exact model. WMP leaves unmapped seats available.

For ordinary cargo seats or fire-from-vehicle (FFV) seats, set model-space points on the vehicle:

```sqf
myTruck setVariable ["Waldo_PhysicalCargo_SeatPoints", [
    ["CARGO", 0, [0.8, -0.5, 0.6]],
    ["TURRET", [1, 0], [-0.8, -0.5, 0.6]]
], true];
```

The coordinates and turret path above only show the data shape. WMP locks a free cargo seat with
`lockCargo`, or a verified FFV person-turret with `lockTurret`, when its point lies inside the
mounted object's oriented footprint. Edge contact does not lock a seat. WMP tracks multiple crates
covering one seat and releases only its own locks. The older `[cargoIndex, point]` form still works
for cargo seats.

Seat points depend on the vehicle model. Do not copy the example coordinates onto another vehicle
without measuring it: an incorrect point can lock the wrong seat or leave an occupied seat open.

## Carrying cargo away

Stand near the crate and the intended contact point. Stop the vehicle before mounting. If the click
misses the vehicle or the mount fails, the crate drops and remains available. Use ACE **Carry** to
remove mounted cargo, then put it on clear ground or another vehicle. A direct unload could leave the
crate inside the vehicle model, so there is no player **Unload physical cargo** action. Server scripts
can call `Waldo_fnc_PhysicalCargoUnmountServer` when they need a checked ground position.

WMP attaches the object at its carried position and restores its previous simulation and collision
state after pickup or ACE Cargo loading. It uses ACE's carry-release callback only when the expected
function and action ID exist. That callback is not public ACE API. If ACE changes it, native ACE
release stays available until WMP supports the new callback.

Check the behaviour on every crate and vehicle class your mission uses. A first ACE-menu opening
may briefly hitch. The cause has not been confirmed. Do not assume a static-weapon
mount is safe: WMP deliberately does not offer one.

## See also

- [Supply Transfers](Supply-Transfers)
- [Logistics System, Starter Crates and Quartermaster](Logistics-System,-Starter-Crates-And-Quartermaster)
- [Vehicle Recovery and Squad Rally Points](Vehicle-Recovery-And-Squad-Rallies)
- [Mission Configuration Reference](Mission-Configuration-Reference)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
