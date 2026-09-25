# Physical cargo (visible crate mounting)

Lets a player ACE-**Carry** a crate and release it onto a vehicle, where it
stays visibly attached at its carried position. Crates covering a seat can
lock that seat. Requires ACE + CBA. **On by default.** Wiki:
`wiki/Physical-Cargo.md`.

## Config (`MissionConfig\logisticsConfig.sqf`, `shared` rows)

```sqf
["Waldo_PhysicalCargo_Enable", true],      // BOOL: carried crate released at a nearby stopped vehicle mounts visibly
["Waldo_PhysicalCargo_BlockSeats", true]   // BOOL: lock only seats verified to be covered by a mounted crate
```

The flag controls mounting and seat effects only. **WMP-issued inventory
crates get ACE Drag/Carry on spawn even with this (and Supply Transfers)
off.** Server init waits for the shared-config sentinel before starting
(`Waldo_fnc_PhysicalCargoInitServer`); clients start from
`initPlayerLocal.sqf`; headless clients request the mount snapshot too.

## Using it

1. Place an inventory crate and a vehicle. **No vehicle Init call and no
   seat coordinates needed.**
2. In-game, ACE **Carry** the crate, aim at where on the stopped vehicle it
   should sit, release. A notification confirms the mount.
3. ACE **Carry** again to remove it; release on clear ground or another
   vehicle.

Releasing away from a vehicle is an ordinary ground drop; ACE Cargo
loading still works. A failed mount drops the crate and leaves it
available. There is deliberately **no "Unload physical cargo" action** (a
direct unload could leave the crate inside the vehicle model); server
scripts can call `Waldo_fnc_PhysicalCargoUnmountServer` for a checked
ground position.

## What is eligible

- **Any ACE-carryable prop is eligible by default** (`Waldo_fnc_PhysicalCargoIsEligible`):
  crates, quartermaster wheels/tracks, fuel barrels, jerrycans, mission props.
  People, static weapons, vehicles, aircraft and boats never are. ZEN
  **Disallow physical mounting** sets `Waldo_PhysicalCargo_Eligible = false` to opt one out.
- Placed `ReammoBox_F` crates register at startup; every WMP-issued store
  registers when it spawns, which also sets ACE Drag/Carry regardless of weight.
- A mounted object keeps ACE's near-zero carried mass; the real mass returns
  on pickup or once it is set down clear, so it can't throw the vehicle.
- **Starter crates are excluded** from automatic drag/carry and
  physical-cargo registration.
- Another non-weapon prop: `[this] call Waldo_fnc_PhysicalCargoRegister;` in
  its Init (or a named object from `initServer.sqf`) — also makes it
  ACE-carryable.
- **Static weapons are rejected** for visible mounts (an HMG flipped a test
  vehicle). They can still be ACE-carried, ground-dropped and ACE-Cargo
  loaded. There is no weapon-mount or gun-entry action.
- Land, air and sea vehicles accept a valid contact hit — test each
  crate/vehicle pair in Arma.

## Seat blocking

With `BlockSeats` on, the first mount of each vehicle class reads model
seat proxies + seat config on the server and caches the match. A crate
whose oriented footprint covers a verified seat point locks it
(`lockCargo`, or `lockTurret` for a matched FFV turret) until carried away;
edge contact doesn't lock. Unknown layouts leave seats unlocked and log why.
Multiple crates on one seat are tracked; WMP releases only its own locks.

Advanced override for an unusual model (measure first — a wrong point
locks the wrong seat):

```sqf
myTruck setVariable ["Waldo_PhysicalCargo_SeatPoints", [
    ["CARGO", 0, [0.8, -0.5, 0.6]],
    ["TURRET", [1, 0], [-0.8, -0.5, 0.6]]
], true];
```

The older `[cargoIndex, point]` form still works for cargo seats.

## Zeus modules (WMP Logistics)

- **Physical Cargo - Eligibility** — place on a carryable prop/crate to
  allow, disallow or inspect future mounts. Rejects static weapons,
  vehicles, aircraft, boats; can't change eligibility while mounted.
- **ACE Cargo - Set Object Handling** — place on a crate or vehicle: Can
  drag / Can carry, optional weight-limit overrides, **Change ACE cargo
  size** (`-1` disables being loaded) and **Change ACE cargo space** (`0`
  disables storage). Does not turn on physical mounting or transfers.

Script equivalent (server-side):

```sqf
[myCrate, -1, 2, true, true] call Waldo_fnc_SetCargoAttributes;
// [object, ACE cargo space (nil = keep), ACE cargo size (nil = keep), draggable, carryable,
//  ignoreDragWeight (false), ignoreCarryWeight (false)]
```

`Waldo_fnc_SetCargoAttributes` is server-only; unchanged repeat calls send
nothing, and ACE's global setters replay state to JIP clients.

## Cost / limitations

Seat lookup runs once per vehicle class, on first mount (not when opening
the ACE menu). A 3-second server monitor catches deletions that emit no
event and re-verifies owned seat locks (max three retries per owner).
Mount list is sent once to a joining player, not rebroadcast. WMP uses
ACE's carry-release callback, which is not public ACE API — if a future
ACE release changes it, native ACE release still works until WMP catches
up. A first ACE-menu opening may briefly hitch (cause unconfirmed).

See also `supply-transfers.md`, `loadout-logistics.md`.
