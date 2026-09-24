# Supply transfers and crate options

> **Use this page when:** moving inventory between crates and vehicles through ACE interactions.

Supply Transfers moves inventory between nearby boxes and vehicles. A **source** is the object
you take supplies from. A **destination** receives them. The feature requires ACE and CBA and is
off by default.

## Set up placed objects

1. Set `Waldo_SupplyTransfers_Enable` to `true` in `MissionConfig/logisticsConfig.sqf`.
2. Place two inventory boxes in Eden. For transfers involving a vehicle, place a vehicle with
   inventory capacity as well.
3. Put this in each placed box's **Init** field and in the vehicle's **Init** field if you want
   to take supplies back out of it:

```sqf
[this] call Waldo_fnc_SupplyTransfersRegister;
```

The **Supply Transfers and Physical Cargo Example** has this setup on two boxes and a NATO
Prowler/DAGOR. WMP registers each object on the server and gives the ACE actions to players who
join later.

The object must hold an Arma inventory. A decorative crate with no inventory cannot receive
supplies.

Quartermaster crates and WMP supply or medical crates register automatically when the feature is
on. This includes crates issued through WMP's Zeus modules, loadout-save fallback, field resupply
and crate compositions. Starter crates keep their existing setup.

Registering an Eden crate also gives it Drag and Carry.
For the Drag, Carry and ACE loading values on other objects, use
[ACE Cargo and Object Handling](ACE-Cargo-And-Object-Handling).

The same call works from `initServer.sqf` with a named object:

```sqf
[supplyTruck] call Waldo_fnc_SupplyTransfersRegister;
```

## Move a whole box in-game

To merge the whole inventory:

1. Open ACE **Crate logistics > Supplies** on the box you want to empty. This is the source.
2. Choose **Select this box for merge / vehicle transfer**. A bottom-right notification confirms it.
3. Open ACE on the receiving box and choose **Merge selected source into this box**.

The merge moves the inventory in one request and leaves the empty source box in place. It does not
open a window. The destination must be in range, and the server checks whether its inventory can
hold the items.

Selection expires after 120 seconds by default. To cancel sooner, return to the source box and
choose **Deselect this merge source**. Set `Waldo_SupplyTransfers_SourceTimeout` in
`MissionConfig/logisticsConfig.sqf` to change the timeout.

## Move selected items

On the source, choose **Transfer from this box...**. Pick a nearby box or cargo-capable vehicle
in the window. Add item types and quantities, review the list, then submit it. **All of type** adds
every available copy of the highlighted item. You can remove a line or clear the list before sending.

Registered vehicles use **Vehicle logistics**. **Transfer from this vehicle...** opens the same
window with the vehicle as source. **Select this vehicle as supply source** and **Merge selected
source into this vehicle** follow the same ACE selection flow as crates.

A crate's transfer window can also send items into a vehicle. A vehicle with cargo space can receive
transfers before registration. Register it to transfer supplies out or merge from it.

**Container handling** on a registered crate contains ACE-loading controls and **Remove empty
container**. WMP rejects removal when items remain inside. Vehicles have neither action.

Stand within 6 metres of the object whose ACE menu you open. The source and destination may be up to
`Waldo_SupplyTransfers_Range` metres apart: 20 by default, configurable from 2 to 50. The server
checks the player and distance when it receives the request. It also checks destination capacity
unless `Waldo_SupplyTransfers_IgnoreCapacity` is `true`. Keep that setting `false` for normal play.
If you allow overloaded inventories, WMP still rejects a transfer it cannot rebuild exactly.

The transfer snapshot keeps weapon attachments, rounds remaining in each magazine and contents of nested backpacks. The server rebuilds and checks the destination before changing the source. A failed rebuild restores the original snapshots. The engine's cargo-capacity and nested-container behaviour varies by class and mod. Try a transfer with the exact crates and vehicles your mission uses before relying on it in play.

Registered crates also expose **Enable ACE loading** and **Disable ACE loading**. These switch that crate's ACE cargo size through ACE's public API. They do not switch off ACE carry. A logistics player can leave loading disabled for an easy physical mount, then enable it for an internal ACE Cargo load. WMP remembers the previous positive ACE size and restores it when the player enables loading. This is a per-crate choice, not a global vehicle setting.

You can register a crate without setting up a quartermaster. Empty containers remain until a player removes them.

Place ZEN **Supply Transfers - Register or Inspect** directly on an inventory crate or cargo-capable
vehicle. A standard ammo box with zero reported capacity gets the value from
`Waldo_SupplyTransfers_EmptyCrateCapacity` when registered. The default is 400. Decorative crates
without Arma inventory storage still cannot take supplies. The module reports whether the server
accepted the object.

WMP installs each client's ACE actions once and broadcasts registry changes. Transfers exchange requests and results only when used. The window reads the selected inventory locally. On submission, the server snapshots both inventories. Large inventories or many registered boxes can still cost time and bandwidth. Test the counts your mission uses.

For modded containers, check that the destination retains attachments, partial magazines and nested
backpack contents. If the server rejects a transfer, both inventories should stay unchanged.

## See also

- [ACE Cargo and Object Handling](ACE-Cargo-And-Object-Handling)
- [Physical Cargo](Physical-Cargo)
- [Logistics, Starter Crates, and Quartermaster](Logistics-System,-Starter-Crates-And-Quartermaster)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
