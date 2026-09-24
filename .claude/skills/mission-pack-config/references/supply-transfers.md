# Supply transfers and crate options

Moves inventory between nearby registered boxes and cargo-capable vehicles
through ACE interactions: whole-box merges, selective item transfers, empty
container removal and a per-crate ACE-loading toggle. Requires ACE + CBA.
**Off by default.** Wiki: `wiki/Supply-Transfers.md`.

## Config (`MissionConfig\logisticsConfig.sqf`, `shared` rows)

```sqf
["Waldo_SupplyTransfers_Enable", false],            // BOOL: master switch
["Waldo_SupplyTransfers_Range", 20],                // METRES: max source↔destination separation (clamped 2-50)
["Waldo_SupplyTransfers_SourceTimeout", 120],       // SECONDS: selected merge source expires (clamped 15-600)
["Waldo_SupplyTransfers_IgnoreCapacity", false],    // BOOL: allow overloading; exact snapshot check still applies
["Waldo_SupplyTransfers_EmptyCrateCapacity", 400]   // capacity given to a registered ReammoBox/weapon-holder crate reporting maxLoad 0
```

Keep `IgnoreCapacity` `false` for normal play.

## Registering objects

WMP-issued crates (quartermaster, supply/medical crates, Zeus crate modules,
loadout-save fallback crate, field resupply, crate compositions) register
**automatically** when the feature is on. **Starter crates never register.**

For an Eden-placed box, or a vehicle you want to take supplies *out of*, put
this in its Init field (no `isServer` wrapper):

```sqf
[this] call Waldo_fnc_SupplyTransfersRegister;
```

Or from `initServer.sqf` with a named object:
`[supplyTruck] call Waldo_fnc_SupplyTransfersRegister;`

The object must have a real Arma inventory — decorative crates with no
inventory are rejected. A vehicle with cargo space can *receive* transfers
without registration; register it to transfer out of it or merge from it.
Registering an Eden crate also gives it ACE Drag/Carry.

## Player actions

Stand within 6 m of the object whose ACE menu you open.

- **Whole-box merge** — on the source: ACE **Crate logistics > Supplies >
  Select this box for merge / vehicle transfer**; on the destination: **Merge
  selected source into this box**. One request, no window; the empty source
  is left in place. **Deselect this merge source** cancels early.
- **Selective transfer** — **Transfer from this box...** opens a window:
  pick a nearby box or cargo-capable vehicle, add item types/quantities
  (**All of type** adds every copy), review, submit.
- **Vehicles** use **Vehicle logistics**: **Transfer from this vehicle...**,
  **Select this vehicle as supply source**, **Merge selected source into
  this vehicle**.
- **Container handling** (registered crates only): **Enable/Disable ACE
  loading** (switches that crate's ACE cargo size via ACE's public API,
  remembering the previous positive size; does not affect ACE carry) and
  **Remove empty container** (rejected while items remain).

Server-side the request is re-validated (player, distance, capacity unless
ignored). Snapshots keep attachments, partial magazine rounds and nested
backpack contents; the destination is rebuilt and verified before the
source changes, and a failed rebuild restores both. Modded container
behaviour varies — tell the mission maker to test their exact crates and
vehicles.

## Zeus: Supply Transfers - Register or Inspect (WMP Logistics)

Place directly on an inventory crate or cargo-capable vehicle. Reports
whether the server accepted it. A standard ammo box reporting zero capacity
gets `Waldo_SupplyTransfers_EmptyCrateCapacity`.

## Eden composition

**Supply Transfers and Physical Cargo Example** — two registered crates and
a NATO Prowler/DAGOR demonstrating transfers, merging, ACE-carry mounting
and automatic seat locks. Still requires `Waldo_SupplyTransfers_Enable =
true` in config — copying a composition never turns on a disabled feature.

## Performance notes

Client ACE actions install once; registry changes broadcast. Transfers
exchange traffic only when used; the window reads inventory locally and the
server snapshots on submit. Very large inventories or many registered boxes
still cost time/bandwidth — test at mission scale.

See also `physical-cargo.md` and `loadout-logistics.md` (Quartermaster).
