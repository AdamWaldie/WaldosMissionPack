# ACE vehicle services

> **Use this page when:** turning a selected vehicle into an ACE ammunition, fuel, repair or medical service vehicle.

One vehicle can provide any combination of these roles. A helicopter can be a medical vehicle, a truck can supply fuel and ammunition, and a boat can act as a repair vehicle. The selected ACE components and their mission settings control the actual service procedures. There is no new WMP feature flag.

## Set up a vehicle

In Zeus, place **WMP Logistics > ACE Vehicle Services - Configure** directly on the vehicle. Choose **Enable**, **Disable** or **Keep current** independently for each role. Applying the dialog preserves roles left at Keep current.

The module requires an existing live land vehicle, aircraft or boat. It rejects people, props and static weapons. It does not choose the nearest object or spawn a replacement.

| Role | What players receive | What the role does not supply |
|---|---|---|
| Ammunition supply / rearm | ACE ammunition-source interactions for vehicle and static-weapon rearming | Inventory magazines, Quartermaster crates or free firing ammunition |
| Fuel supply | ACE fuel-source hose and nozzle interactions | Fuel in the source vehicle's own engine tank |
| Repair vehicle | ACE repair-vehicle status for location-dependent repair work | Engineer qualification, tools, instant repair or spare parts |
| Medical vehicle | ACE medical-vehicle status for permitted treatment | Automatic healing, medical items or medic qualification |

Supply amounts must be whole numbers; the server rejects fractional values supplied through the function. The ZEN sliders display and submit whole numbers.

For a newly enabled source, select its initial ammunition points or fuel litres. Fuel can also be unlimited. For an already active source, these amount fields only take effect when **Refill ammunition now** or **Refill fuel now** is checked. Refills replace the remaining amount; they do not add to it. Return an active fuel nozzle before disabling or refilling its source.

Use [Quartermaster](Quartermaster) to issue crates, wheels and tracks. Use [Supply Transfers](Supply-Transfers) to move inventory, [Field Resupply](Field-Resupply) for portable resupply crates, and [ACE Cargo and Object Handling](ACE-Cargo-And-Object-Handling) to set storage capacity. Those features can share the vehicle and retain their own setup.

## Script API

Place this in a truck's Eden **Init** field:

```sqf
[this, [
    ["rearm", true], ["rearmSupply", 1500],
    ["refuel", true], ["fuelLitres", 2000],
    ["repair", true], ["medical", false]
]] call Waldo_fnc_VehicleServicesConfigure;
```

A medical helicopter needs only:

```sqf
[this, [["medical", true]]] call Waldo_fnc_VehicleServicesConfigure;
```

The same API accepts a named vehicle in a server script and accepts a HashMap in place of the key/value array. Client copies of Eden Init do nothing. Do not remote-execute this API directly; the ZEN module uses a separate authenticated bridge.

```sqf
// Server: replace this active source's remaining fuel with 3000 litres.
[myTruck, [["refillFuel", true], ["fuelLitres", 3000]]]
    call Waldo_fnc_VehicleServicesConfigure;

// Server: disable only its ammunition source. Other roles remain unchanged.
[myTruck, [["rearm", false]]] call Waldo_fnc_VehicleServicesConfigure;

// Server: re-enable with the stock saved when it was disabled.
[myTruck, [["rearm", true]]] call Waldo_fnc_VehicleServicesConfigure;
```

| Key | Type / default | Meaning |
|---|---|---|
| `rearm`, `refuel`, `repair`, `medical` | Boolean / omitted | Set that role; omission keeps current state |
| `rearmSupply` | Number / saved stock, otherwise `1000` | Initial or explicit replacement supply, from `0` to `1000000` |
| `fuelLitres` | Number / saved stock, otherwise `1000` | Initial or replacement litres, from `0` to `1000000`; `-10` means unlimited |
| `refillRearm`, `refillFuel` | Boolean / `false` | Replace stock even when already enabled |

Amounts alone do not enable a service. Refilling a disabled service requires enabling it in the same request. Repeating an enabled role without a refill preserves consumption. The ZEN dialog supplies its selected amount when enabling a role, including re-enabling a disabled source. To restore saved stock without selecting an amount, use the server API example above.

The function returns a Boolean indicating whether the request entered its queue. Application occurs after ACE settings and mission startup, with a 60-second readiness timeout. Check `Waldo_VehicleServices_LastResult` on the vehicle for `[success, message]`. `Waldo_VehicleServices_Ready` means its queue has drained; inspect LastResult to distinguish success from rejection.

## Authority, JIP and cleanup

The server validates the entire option set before changing roles. The ZEN bridge requires the curator's network owner to match the remote caller and requires an assigned curator. Accepted requests leave the remote execution context through CBA's next-frame queue and drain in order per vehicle.

ACE installs and replays the fuel and ammunition actions. WMP publishes the repair and medical flags. The diagnostic `Waldo_VehicleServices_State` contains `[revision, rearm, refuel, repair, medical]`; ACE retains live stock values on its own source variables. There is no WMP per-frame service loop or additional player action tree.

Disabling a source retains ACE's action installation but changes the state checked by its conditions. This avoids installing duplicate actions on re-enable. Re-enabling ammunition supply also replays ACE's deduplicated setup to current clients, including players who joined while it was disabled. ACE's action replay follows object lifetime. Public flags survive ownership migration and joining clients. WMP's automatic medical-class setup only supplies a missing flag on the server, so it cannot overwrite an explicit false setting during JIP.

The vehicle keeps its inventory, simulation setting, ownership, position and movement orders. These settings apply to that object. A replacement spawned after deletion needs a new setup call.

## Limitations and testing

ACE's global rearm policy remains authoritative. Unlimited and supply-point modes are supported; enabling an ammunition source in magazine-based mode is rejected. The module does not change the mission-wide policy. Fuel amounts are source stock; a native tanker may retain a larger configured tank capacity.

Medical treatment still depends on ACE's location, patient, qualification and item requirements. Repair still depends on ACE's repair rules. Enabling either role does not bypass those rules. Missing selected ACE components reject the whole patch. Disabling or refilling an in-use fuel source is rejected until its nozzle is returned.

The implementation follows ACE 3.21.2 source contracts. Source checks cannot establish action visibility, hose placement, treatment eligibility or multiplayer timing. Dedicated-server acceptance is still required: enable each role, combine roles, consume stock, reopen unchanged, disable/re-enable, refill explicitly, migrate locality and join another client. Repeat with native service vehicles and ordinary vehicles. Confirm an explicitly disabled medical role stays disabled after JIP.

The full-pack audit's `qa_transfer_vehicle` is a simulation-enabled HEMTT configured with all four roles and finite source stocks. Use it for the service tests and the actual ZEN dialog. Its WMP supply-transfer registration remains active.

## See also

- [Quartermaster](Quartermaster)
- [Supply Transfers](Supply-Transfers)
- [Field Resupply](Field-Resupply)
- [ACE Cargo and Object Handling](ACE-Cargo-And-Object-Handling)
- [WMP Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)
- [ACE Rearm framework](https://ace3.acemod.org/wiki/framework/rearm-framework)
- [ACE Refuel framework](https://ace3.acemod.org/wiki/framework/refuel-framework)
- [ACE Repair framework](https://ace3.acemod.org/wiki/framework/repair-framework)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) Â· [Quickstart](Quickstart-Guide) Â· [Feature index](Feature-Tutorials)
