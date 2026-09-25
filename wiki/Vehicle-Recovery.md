# Vehicle Recovery

> **Use this page when:** you want to package damaged vehicles and restore them at a workshop.

The server owns recovery state and vehicle changes. Each player, including a joining player, receives the local controls.

Vehicle recovery is opt-in per object. Register a workshop, a vehicle to recover, and optionally a carrier. Players can package a damaged, empty, stationary vehicle. Deliver its package to a workshop with the same key to restore it at a clear position.

## Set up a working example in Eden

1. Place a workshop object, a vehicle to recover, and a carrier such as a truck.
2. Put the matching line below in each object's own **Init** field. Each field gets one line, not the whole block.
3. Preview the mission. Damage the recovery vehicle, empty it, stop it, and use **Package for Recovery**.
4. Load the package on the carrier or move it to the workshop. The workshop restores a matching, grounded package.

The calls below use the default workshop key, radius, side, and carrier mode:

```sqf
[this] call Waldo_fnc_RecoveryRegisterWorkshop;   // in a repair depot's init field - key/radius/side all default
[this] call Waldo_fnc_RecoveryRegisterVehicle;    // in a damaged vehicle's init field - workshop key defaults too
[this] call Waldo_fnc_RecoveryRegisterCarrier;    // in a truck's init field - mode defaults to AUTO
```

The `[WMP]Vehicle_Recovery_Workshop_Example_Minimal` composition places all three objects with these calls. See [Eden Compositions](Eden-Compositions). Set an explicit workshop key and options when you need several independent recovery sites:

```sqf
[repairDepot, "FOB_ALPHA", 50, west] call Waldo_fnc_RecoveryRegisterWorkshop;
[damagedTank, "FOB_ALPHA", 0.55, true, true, "B_Slingload_01_Cargo_F", true, 1]
    call Waldo_fnc_RecoveryRegisterVehicle;
[recoveryTruck, 10, "AUTO", 2] call Waldo_fnc_RecoveryRegisterCarrier;
```

Workshops accept a key, delivery radius and serviced side (`"ALL"` permits all sides; use `west`, `east`, `independent` or `civilian` to restrict it). `RecoveryRegisterVehicle` accepts the workshop key, living-vehicle damage threshold, whether destroyed vehicles are accepted, whether an engineer is required, package class, inventory-preservation policy and restored fuel fraction. The system also restores textures and pylon magazines. `RecoveryRegisterCarrier` accepts loading range, cargo mode and package capacity. A registered recovery carrier remains a carrier with the same mode and capacity after it is recovered.

Carrier mode is `"AUTO"`, `"VIRTUAL"` or `"PHYSICAL"`. Automatic mode uses Arma's visible vehicle-in-vehicle cargo only when `vehicleCargoEnabled` and `canVehicleCargo` confirm that the selected package fits; otherwise it uses the virtual manifest. Virtual mode therefore works with ordinary trucks, MRAPs, boats and other registered vehicles that have no engine-configured cargo bay. Physical mode is intentionally strict and refuses packages that do not fit. Package discovery uses the authoritative server registry and measures loading range between the real bounding footprints of carrier and package, so a large container parked directly beside a smaller vehicle is not rejected because their model origins are farther apart. While virtually carried, the real server-owned package is hidden and simulation-disabled rather than deleted, preserving its recovery state. Unloading at the matching workshop queues restoration directly; unloading elsewhere searches for a complete clear package footprint beside the carrier. Carrier destruction spills virtual packages only when a clear position is available, and an obstructed package remains protected for a later retry.

The recovery object is independently configurable per recoverable vehicle through argument 5 of `Waldo_fnc_RecoveryRegisterVehicle`. For Zeus, extend `Waldo_Recovery_PackageClasses` with valid `CfgVehicles` classes before runtime configuration; the module converts that pool into a display-name dropdown. The default pool is `B_Slingload_01_Cargo_F` and `Land_Pallet_MilBoxes_F`. The server validates the selected class and falls back to the first valid configured entry.

Recovery preparation can optionally use the shared interaction procedures. The feature's semantic
default is `repair / standard`; script options can override it without changing the recovery API:

```sqf
private _interaction = createHashMapFromArray [
    ["enabled", true],
    ["challengeId", "repair"],
    ["difficulty", "standard"]
];
[damagedTank, "FOB_ALPHA", 0.55, true, true, "B_Slingload_01_Cargo_F", true, 1, _interaction]
    call Waldo_fnc_RecoveryRegisterVehicle;
```

When enabled, **Prepare Vehicle for Recovery** replaces immediate packaging. Successful completion
submits the same server-owned `PACK` request, so workshop, damage, occupancy, movement, distance and
engineer checks still run after the procedure. With the option disabled, the existing packaging action
is unchanged.

The server uses one configurable scan loop (`Waldo_Recovery_ScanInterval`, default 3 seconds) for all packages. Registration is repeat-safe. Actions are object-keyed for JIP and disappear with the deleted original/package object. Packaging, loading and unloading feedback is sent only to the operator performing that action. A completed workshop restoration notifies only friendly players within `Waldo_Recovery_NotificationRadius` (default 100 metres); an individual workshop can override that radius through the optional fifth registration argument. Registered workshops create two global engine markers by default: a shaded circle showing the delivery radius and a labelled point showing the workshop's exact position. Their colour follows the serviced side. Set `Waldo_Recovery_CreateWorkshopMarkers` to `false`, or pass `false` as the optional sixth registration argument, to suppress both markers.

Restoration samples bounded rings outside the workshop's real model bounds plus the recovered vehicle footprint and `Waldo_Recovery_PlacementClearance`. Candidates are terrain-snapped and rejected when ordinary or terrain objects occupy the full clearance area. If no safe point exists, the package remains for a later retry; the system never falls back to the workshop origin or creates a vehicle inside another object.

ZEN provides three modules:

- **Vehicle Recovery - Register Workshop** configures a nearby object's key and radius and can export its setup call.
- **Vehicle Recovery - Register Vehicle** configures the nearest vehicle's recovery policy and an optional simplified preparation procedure: enable, procedure and difficulty.
- **Vehicle Recovery - Register Carrier** enables package loading and unloading on the nearest vehicle and exposes Automatic, Virtual Manifest or Physical Cargo Bay handling plus a 1–10 package capacity.

With ACE Interact loaded, a registered recoverable vehicle receives **Package for Recovery** on the
vehicle and a carrier receives **Vehicle Recovery > Load Recovery Package / Unload Recovery
Package**. Without ACE Interact, the same controls appear as vanilla actions. Runtime registration,
re-registration and JIP all reinstall the expected local controls repeat-safely. The procedure option
is optional: when it is off, **Package for Recovery** submits the normal server PACK
request immediately.

The vehicle module also supports registration after destruction. Arma wrecks can retain dead crew
objects in `crew vehicle`. WMP counts only **living** occupants. That keeps an already-
destroyed Zeus-selected wreck eligible while still refusing a wreck or damaged vehicle containing a
living player or AI. The client RPT records `mode`, `eligibleNow`, `alive`, `crewTotal` and
`crewLiving` when the action is installed, which distinguishes a missing ACE action from an action
whose gameplay condition is currently false.

For troubleshooting, run `[] call Waldo_fnc_RunDiagnostics`. The server report checks orphaned
vehicles/packages and workshop keys; each client reports registered recovery objects missing their
expected ACE or vanilla actions. Every registration and PACK/LOAD/UNLOAD request also writes one
`[WMP RECOVERY]` RPT line naming the object, operation, owner and active mode.

Living vehicles are retained hidden while packaged and restored as the same object, preserving object identity, event handlers, actions, applied scripts and external references. A destroyed vehicle cannot be resurrected reliably, so that path creates a replacement, restores its Eden variable name, copies the configured custom-variable allowlist and invokes `Waldo_Recovery_OnRestored` for mission-specific rebinding. Crew and attached objects are not recreated. Use persistence separately for long-term mission saves.

## If recovery is unavailable

Check that the vehicle, carrier and workshop each completed registration and still exist. The vehicle must meet the configured damage gate, and the carrier must have space for the package. A workshop can restore only a package whose key and vehicle class it supports. Run [Mission Diagnostics](Mission-Diagnostics) and check the `[WMP RECOVERY]` RPT entry to find the rejected step.

## See also

- [Eden Compositions](Eden-Compositions)
- [Optional Feature Systems](Optional-Feature-Systems)
- [Transport Services](Transport-Services)
- [Mission Configuration Reference](Mission-Configuration-Reference)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
