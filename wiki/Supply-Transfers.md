# Supply transfers and crate options

> **Use this page when:** adding two-way inventory transfers or ACE loading choices to crates and vehicles.

Set `Waldo_SupplyTransfers_Enable` to `true` in `MissionConfig/logisticsConfig.sqf`. WMP-issued quartermaster crates and containers spawned by WMP's supply/medical Zeus modules, loadout-save fallback and field-resupply system register automatically. Supply/medical crate compositions also enrol through their population calls. Mission-start starter crates are deliberately excluded. To include a mission-placed container, call this on the server:

```sqf
[mySupplyCrate] call Waldo_fnc_SupplyTransfersRegister;
```

For an Eden object, give it a variable name and call the function in `initServer.sqf`. You can also put `[this] call Waldo_fnc_SupplyTransfersRegister;` in the object's Init field. Only the server registers it after shared config is ready. Clients, including JIP, receive the current registry.

Registration needs nonzero Arma inventory capacity. The same call registers a cargo-capable vehicle for two-way transfer and merge. ACE carry and physical cargo remain separate:

```sqf
[supplyTruck] call Waldo_fnc_SupplyTransfersRegister;
```

For a whole-box merge, open ACE **Crate logistics > Supplies** on the box you want to empty. Choose **Select this box for merge / vehicle transfer**. A bottom-right notification confirms the source. **Merge selected source into this box** then appears on eligible destinations within range. The server moves the inventory in one request and leaves the empty source box in place. No transfer window opens.

For selected items, choose **Transfer from this box...**. In the window, pick a nearby crate or cargo-capable vehicle. Add item types and quantities, then review and submit the transfer. You can remove a queued line or clear the list. **All of type** queues every available copy of the highlighted item type. **Container handling** contains the ACE-loading controls and **Remove empty container**. The server rejects removal if anything remains inside.

Registered vehicles use **Vehicle logistics**. **Transfer from this vehicle...** opens the same window with the vehicle as source. **Select this vehicle as supply source** and **Merge selected source into this vehicle** use the same ACE source/target flow as crates. You can also choose a vehicle as the destination in a crate's transfer window. Vehicles have no empty-container removal or ACE-loading toggle. A cargo-capable vehicle can appear as a destination before registration. Registration adds its source and merge actions.

Stand within 6 metres of the object whose ACE menu you open. The source and destination may be up to `Waldo_SupplyTransfers_Range` metres apart: 20 by default, configurable from 2 to 50. The server checks the player, distance and destination capacity when it receives the request.

The transfer snapshot keeps weapon attachments, rounds remaining in each magazine and contents of nested backpacks. The server rebuilds and checks the destination before changing the source. A failed rebuild restores the original snapshots. The engine's cargo-capacity and nested-container behaviour varies by class and mod, so acceptance tests must include the exact crates used by the mission.

Registered crates also expose **Enable ACE loading** and **Disable ACE loading**. These switch that crate's ACE cargo size through ACE's public API. They do not switch off ACE carry. A logistics player can leave loading disabled for an easy physical mount, then enable it for an internal ACE Cargo load. WMP remembers the previous positive ACE size and restores it when the player enables loading. This is a per-crate choice, not a global vehicle setting.

You can register a crate without setting up a quartermaster. Empty containers remain until a player removes them.

Place ZEN **Supply Transfers - Register or Inspect** directly on a crate or cargo-capable vehicle. It registers the object or reports its role and capacity. The feature flag must be on, and registration needs nonzero inventory capacity. A success notification means the server accepted it.

WMP installs each client's ACE actions once and broadcasts registry changes. Transfers exchange requests and results only when used. The window reads the selected inventory locally. On submission, the server snapshots both inventories. Large inventories or many registered boxes can still cost time and bandwidth. Test the counts your mission uses.

Dedicated-server, competing-request and nested-cargo acceptance is still required for this new system. A syntax check cannot prove that a particular modded backpack survives a transfer.

## See also

- [Physical Cargo](Physical-Cargo)
- [Logistics, Starter Crates, and Quartermaster](Logistics-System,-Starter-Crates-And-Quartermaster)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
