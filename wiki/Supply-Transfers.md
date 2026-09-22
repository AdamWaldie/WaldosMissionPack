# Supply transfers and crate options

> **Use this page when:** adding two-way inventory transfers or ACE loading choices to crates and vehicles.

Set `Waldo_SupplyTransfers_Enable` to `true` in `MissionConfig/logisticsConfig.sqf`. Quartermaster
crates and WMP supply or medical crates then get ACE transfer and merge actions automatically. That
includes crates from WMP's Zeus modules, loadout-save fallback, field resupply and crate
compositions. Starter crates keep their existing setup.

For a crate or cargo-capable vehicle you placed in Eden, put this in its **Init** field:

```sqf
[this] call Waldo_fnc_SupplyTransfersRegister;
```

The **Supply Transfers and Physical Cargo Example** already has this call on its two crates and NATO
Prowler/DAGOR. Copy the objects or change their Init fields for your mission. The object needs
inventory capacity. WMP registers it on the server and gives the actions to players who join later.

The same call works from `initServer.sqf` with a named object:

```sqf
[supplyTruck] call Waldo_fnc_SupplyTransfersRegister;
```

## Move supplies in-game

To merge the whole inventory:

1. Open ACE **Crate logistics > Supplies** on the box you want to empty.
2. Choose **Select this box for merge / vehicle transfer**. A bottom-right notification confirms it.
3. Open ACE on the destination and choose **Merge selected source into this box**.

The merge moves the inventory in one request and leaves the empty source box in place. It does not
open the transfer window. The destination must be in range and have enough space.

For specific items, choose **Transfer from this box...**. Pick a nearby box or cargo-capable vehicle
in the window. Add item types and quantities, review the list, then submit it. **All of type** adds
every available copy of the highlighted item. You can remove a line or clear the list before sending.

Registered vehicles use **Vehicle logistics**. **Transfer from this vehicle...** opens the same
window with the vehicle as source. **Select this vehicle as supply source** and **Merge selected
source into this vehicle** follow the same ACE selection flow as crates. A crate's transfer window
can also send items into a vehicle. A vehicle with cargo space can receive transfers before
registration. Register it to transfer supplies out or merge from it.

**Container handling** on a registered crate contains ACE-loading controls and **Remove empty
container**. WMP rejects removal when items remain inside. Vehicles have neither action.

Stand within 6 metres of the object whose ACE menu you open. The source and destination may be up to `Waldo_SupplyTransfers_Range` metres apart: 20 by default, configurable from 2 to 50. The server checks the player, distance and destination capacity when it receives the request.

The transfer snapshot keeps weapon attachments, rounds remaining in each magazine and contents of nested backpacks. The server rebuilds and checks the destination before changing the source. A failed rebuild restores the original snapshots. The engine's cargo-capacity and nested-container behaviour varies by class and mod. Try a transfer with the exact crates and vehicles your mission uses before relying on it in play.

Registered crates also expose **Enable ACE loading** and **Disable ACE loading**. These switch that crate's ACE cargo size through ACE's public API. They do not switch off ACE carry. A logistics player can leave loading disabled for an easy physical mount, then enable it for an internal ACE Cargo load. WMP remembers the previous positive ACE size and restores it when the player enables loading. This is a per-crate choice, not a global vehicle setting.

You can register a crate without setting up a quartermaster. Empty containers remain until a player removes them.

Place ZEN **Supply Transfers - Register or Inspect** directly on a crate or cargo-capable vehicle. It registers the object or reports its role and capacity. The feature flag must be on, and registration needs nonzero inventory capacity. A success notification means the server accepted it.

WMP installs each client's ACE actions once and broadcasts registry changes. Transfers exchange requests and results only when used. The window reads the selected inventory locally. On submission, the server snapshots both inventories. Large inventories or many registered boxes can still cost time and bandwidth. Test the counts your mission uses.

For modded containers, check that the destination retains attachments, partial magazines and nested
backpack contents. If the server rejects a transfer, both inventories should stay unchanged.

## See also

- [Physical Cargo](Physical-Cargo)
- [Logistics, Starter Crates, and Quartermaster](Logistics-System,-Starter-Crates-And-Quartermaster)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
