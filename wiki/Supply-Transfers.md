# Supply transfers and crate options

> **Use this page when:** your logistics team needs to move selected supplies, consolidate boxes, or choose whether a crate can use ACE internal loading.

Set `Waldo_SupplyTransfers_Enable` to `true` in `MissionConfig/logisticsConfig.sqf`. WMP-issued quartermaster crates and containers spawned by WMP's supply/medical Zeus modules, loadout-save fallback and field-resupply system register automatically. Supply/medical crate compositions also enrol through their population calls. Mission-start starter crates are deliberately excluded. To include a mission-placed container, call this on the server:

```sqf
[mySupplyCrate] call Waldo_fnc_SupplyTransfersRegister;
```

For an Eden object, either give it a variable name and put the call in `initServer.sqf`, or put `[this] call Waldo_fnc_SupplyTransfersRegister;` directly in that object's Init field. The Init call is repeat-safe: only the server registers it after shared config is ready, and clients/JIP receive the current registry. Registration needs nonzero Arma inventory capacity. The same call registers a cargo-capable vehicle for two-way transfer and merge; it does not replace ACE carry/physical cargo:

```sqf
[supplyTruck] call Waldo_fnc_SupplyTransfersRegister;
```

Open the icon-marked **Crate logistics** ACE submenu. For a whole-box merge, use **Supplies > Select this box for merge / vehicle transfer** on the box you want to empty. A bottom-right notification confirms the selection. Then use **Supplies > Merge selected source into this box** on the destination box. This commits the whole inventory in one server-checked request without opening a window. The source box remains in place. For selective moves, use **Transfer from this box...**; its review window lets you choose a nearby registered crate or cargo-capable vehicle, queue several item types and quantities, remove lines or clear the list, then transfer everything in one server-checked operation. **All of type** adds every available copy of the highlighted type; it does not merge the whole box. **Container handling** holds ACE-loading controls and **Remove empty container**. Removal is rejected unless the container is empty.

Registered vehicles get a **Vehicle logistics** ACE branch. **Transfer from this vehicle...** opens the same multi-line review window as a crate, using the vehicle's inventory as the source. To transfer *into* it, open **Transfer from this box...** on a source crate and select the vehicle as destination; a second vehicle-side transfer-in action is not needed. **Select this vehicle as supply source** lets another registered container or vehicle receive its contents. **Merge selected source into this vehicle** makes a one-action whole-inventory move, with the same capacity checks as box merges; the emptied source remains in the world. A merge can also target a registered box after selecting a vehicle as source. Unlike crates, vehicles have no **Remove empty container** or ACE-loading toggle. An unregistered cargo-capable vehicle can already appear as a destination in a crate's transfer window; registration adds the vehicle-side source/merge branch. The player must be within 6 metres of the ACE interaction object; source and destination can be up to `Waldo_SupplyTransfers_Range` metres apart (default 20, configurable from 2 to 50). The server checks identity, distance and destination capacity again when the request arrives.

The transfer snapshot keeps weapon attachments, rounds remaining in each magazine and contents of nested backpacks. The server rebuilds and checks the destination before changing the source. A failed rebuild restores the original snapshots. The engine's cargo-capacity and nested-container behaviour varies by class and mod, so acceptance tests must include the exact crates used by the mission.

Registered crates also expose **Enable ACE loading** and **Disable ACE loading**. These switch that crate's ACE cargo size through ACE's public API. They do not switch off ACE carry. A logistics player can leave loading disabled for an easy physical mount, then enable it for an internal ACE Cargo load. WMP remembers the previous positive ACE size and restores it when the player enables loading. This is a per-crate choice, not a global vehicle setting.

The crate menu and merge logic are separate functions. A mission can use the registration call independently of a quartermaster. Empty containers remain in the world until a player explicitly removes them.

ZEN **Supply Transfers - Register or Inspect** must be placed directly on a crate or vehicle. It enrols the object or reports its current role/capacity; it requires the supply-transfers flag and nonzero inventory capacity to register. It does not open a duplicate Zeus transfer UI. Registration is acknowledged after server application, so a success message means the server accepted the object. WMP installs actions once per client; new registrations retain existing actions rather than rebuilding every object's ACE menu. The server broadcasts the registered-object list when a new object is added, and transfers send a request/result only when used. Opening the transfer window snapshots the selected inventory locally; a submitted transfer snapshots and validates both inventories on the server. Very large inventories or many boxes can still cost time and network bandwidth when registered or moved, so test your mission's actual crate counts.

Dedicated-server, competing-request and nested-cargo acceptance is still required for this new system. A syntax check cannot prove that a particular modded backpack survives a transfer.

## See also

- [Physical Cargo](Physical-Cargo)
- [Logistics, Starter Crates, and Quartermaster](Logistics-System,-Starter-Crates-And-Quartermaster)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
