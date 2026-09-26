# Physical cargo

> **Use this page when:** mounting an ACE-carried crate or prop visibly on a vehicle.

Physical cargo lets a player carry a crate with ACE and leave it visibly attached to a vehicle.
ACE and CBA are required. The feature is on by default through `Waldo_PhysicalCargo_Enable` in
`MissionConfig/logisticsConfig.sqf`.

The server owns eligibility and mount records. Each object's owner applies its attachment, while the vehicle owner applies seat locks. Players who join later receive the current mounts. `Waldo_PhysicalCargo_BlockSeats` is on by default; set it to `false` in the same config file if the mission should never block seats.

## Try it in a mission

1. Place an inventory crate and a vehicle in Eden. You do not need an Init call on the vehicle.
2. Start the mission and use ACE **Carry** on the crate.
3. Aim at the part of the vehicle where you want it and release the crate. WMP keeps its carried
   position and shows a notification when the mount succeeds.
4. Use ACE **Carry** again to remove it. Release it on clear ground or on another vehicle.

Release the crate away from a vehicle for an ordinary ground drop. ACE's menu can still load it
inside ACE Cargo. [Crate options](Supply-Transfers) can change that loading choice for a registered
crate. A rejected mount requests a checked ground position on the cargo owner. If no clear
position exists, WMP retains the near-zero-mass attachment and asks you to recover it with ACE Carry.

Any object a player can ACE Carry is eligible by default: crates, Quartermaster spare wheels and
tracks, fuel barrels, jerrycans and your own props. People, static weapons, vehicles, aircraft and
boats and starter crates are excluded. To keep one object on plain ACE Carry and Cargo, use **Disallow physical mounting**
in the Zeus module below. WMP registers placed `ReammoBox_F` crates at startup and its own issued
stores when they spawn, which also gives them ACE Drag and Carry regardless of weight.
The feature flag controls mounting and seat effects. [ACE Cargo and object handling](ACE-Cargo-And-Object-Handling)
controls Drag, Carry, loading size and storage space independently.

For another non-weapon prop, put this in the prop's Eden **Init** field:

```sqf
[this] call Waldo_fnc_PhysicalCargoRegister;
```

The same call works in `initServer.sqf` with a named object in place of `this`. It marks the prop
eligible and asks ACE to make it carryable; you need it only for a prop ACE cannot already carry.

`[object] call Waldo_fnc_PhysicalCargoRegister;` takes one existing non-weapon prop or crate. It returns `true` when the server accepts the object or queues it until settings load. It returns `false` if the feature is off, the object is unsupported or a client calls it directly. Repeating the call does not add another ACE event. WMP-issued crates already qualify; use this call for a prop you placed yourself.

WMP rejects visible mounts for static weapons after an HMG flipped a test vehicle. Players can
still use ACE Carry, ground drop and ACE Cargo for static weapons. WMP has no working weapon mount
or gun-entry action.

Place ZEN **Physical Cargo - Eligibility** directly on a carryable prop or crate to allow future
mounts, disallow them or inspect the current state. The module rejects static weapons, vehicles,
aircraft and boats. It cannot change eligibility while the object has a mount. ACE Carry and Cargo
remain available.

WMP also registers every Quartermaster issue, including wheels, tracks, fuel barrels and jerrycans,
for the physical carry-release path.

While mounted, an object keeps the near-zero physics mass ACE gives it during a carry. It gets its
saved mass back through ACE on the next ground drop, or after the cargo owner acknowledges a
checked set-down. The server recovery worker runs outside the remote request context. A failed
clear-position search keeps the cargo inert; it never falls back to waking it inside the vehicle.
These changes still require dedicated-server physics testing with the mission's ACE version.

WMP accepts a valid contact hit on land, air or sea vehicles. Test each crate and vehicle combination
in Arma before using it in a mission.

## Seats covered by cargo

`Waldo_PhysicalCargo_BlockSeats` defaults to `true`. A crate placed over a verified seat blocks
that seat until a player carries the crate away. Clear seats remain available. A vehicle needs no
seat coordinates or extra Init call.

On the first mount of each vehicle class, the server reads its model seat points and seat config,
then caches the match. If a mod does not expose enough information, WMP leaves that seat available
and logs the reason.

An experienced mission maker can supply a measured override for an unusual model:

```sqf
myTruck setVariable ["Waldo_PhysicalCargo_SeatPoints", [
    ["CARGO", 0, [0.8, -0.5, 0.6]],
    ["TURRET", [1, 0], [-0.8, -0.5, 0.6]]
], true];
```

The coordinates and turret path above only show the data shape. WMP locks a free cargo seat with
`lockCargo`, or a matched FFV person-turret with `lockTurret`, when its point lies inside the
mounted object's oriented footprint. Edge contact does not lock a seat. WMP tracks multiple crates
covering one seat and releases only its own locks. The older `[cargoIndex, point]` form still works
for cargo seats.

Only use an override after checking the exact model. An incorrect point can lock the wrong seat
or leave a covered seat open. The **Supply Transfers and Physical Cargo Example** uses the normal
automatic lookup. Its Prowler Init field contains only supply-transfer registration.

## Server and network cost

The seat-proxy lookup runs on the server on the first mount of each vehicle class. WMP caches the
result. Each later mount checks the crate against that vehicle's stored seat points. Opening the ACE
menu does not run this lookup.

Ordinary entity deletion releases the mount's owned seat locks at once. A three-second server
monitor catches deletion paths that do not emit that event, checks active mounts and verifies their
owned seat locks. A missing lock gets at most three retries per vehicle owner. Successful locks
generate no repeat traffic. The work grows with active mounts, not players.

Mount and unmount events go to current clients. WMP keeps the full mount list on the server and
sends it once to a joining player on request. It does not rebroadcast the growing list for every
crate.

Seat-point, seat-lock and restore bookkeeping stays on the server. The server sends seat-lock
changes to the vehicle owner, where Arma applies them. Object attachment state and actual seat
locks still synchronize through Arma. These are design limits, not measured byte or frame-time
figures. Test a heavily loaded mission on its intended server before relying on them.

## Carrying cargo away

Stand near the crate and the intended contact point. Stop the vehicle before mounting. If the click
misses the vehicle, the crate drops normally. A rejected mount uses the checked recovery path above. Use ACE **Carry** to
remove mounted cargo, then put it on clear ground or another vehicle. A direct unload could leave the
crate inside the vehicle model, so there is no player **Unload physical cargo** action. Server scripts
can call `Waldo_fnc_PhysicalCargoUnmountServer` when they need a checked ground position.

WMP attaches the object at its carried position and restores its previous simulation and collision
state after pickup or ACE Cargo loading. The empty-crate delete action clears a mount before deleting
the crate. Other deletion methods use the deletion listener and monitor fallback to release seats.
WMP uses ACE's carry-release callback only when the expected
function and action ID exist. That callback is not public ACE API. If ACE changes it, native ACE
release stays available until WMP supports the new callback.

Check the behaviour on every crate and vehicle class your mission uses. A first ACE-menu opening
may briefly hitch. The cause has not been confirmed. Do not assume a static-weapon
mount is safe: WMP deliberately does not offer one.

## If a mount or seat fails

- **No ACE Carry:** Check ACE, the object's handling values and whether WMP has marked the object eligible. [ACE Cargo and Object Handling](ACE-Cargo-And-Object-Handling) can set Drag and Carry independently.
- **Object drops instead of mounting:** Aim at a usable part of the vehicle while close to it, and stop the vehicle. WMP leaves rejected cargo recoverable.
- **Covered seat stays usable:** Some modded models do not expose a trustworthy seat position. WMP leaves those seats unchanged and logs the reason instead of guessing.
- **Seat remains locked after removal:** Carry or ACE-load the object, then test again. If it persists, record the vehicle class, crate class and server RPT; WMP also checks active mounts for missed deletion events.

## See also

- [ACE Cargo and Object Handling](ACE-Cargo-And-Object-Handling)
- [Supply Transfers](Supply-Transfers)
- [Quartermaster](Quartermaster)
- [Vehicle Recovery](Vehicle-Recovery)
- [Mission Configuration Reference](Mission-Configuration-Reference)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
