_Associated Files: `MissionScripts\Logistics\LogiHelpers\teleport.sqf` (`Waldo_fnc_Teleport`), `MissionScripts\Paradrop\moveInCargoPlane.sqf` (`Waldo_fnc_MoveInCargoPlane`)_

# Teleportation & Move-Into-Cargo Interactions

Two small "get me there" helpers, grouped here for convenience. Both add a scroll-wheel **addAction** to an object:

* **Teleport** — move whoever uses the action to a marker, object, location, group or task.
* **Move-Into-Cargo** — board an aircraft that is already airborne, so jumpers don't have to wait through a long taxi/climb.

---

## Teleport Object — `Waldo_fnc_Teleport`

Adds a green **"Teleport"** (or custom-labelled) action to an object that moves the user to a destination. The destination can be almost anything with a position; for markers, locations and tasks the Z height is treated as ground level (0).

### Parameters

| # | Parameter | Type | Default | Purpose |
|---|---|---|---|---|
| 0 | Object | Object | — | The object the action is added to (often `this`). |
| 1 | Label | String | `"Teleport"` | Text shown in the scroll-wheel action. |
| 2 | Destination | Marker / Object / Location / Group / Task | the object itself | Where the user is teleported to. |

The destination must have a **variable name** (or be a named marker/location) so it can be referenced.

### Examples

```sqf
[this, "Teleport - Airfield", Airstrip]      call Waldo_fnc_Teleport;  // Arma map Location object
[this, "Teleport - Base", MyBase]            call Waldo_fnc_Teleport;  // a placed object
[this, "Teleport - Bart", "FOB_Bart"]        call Waldo_fnc_Teleport;  // predefined map location name
[this, "Teleport - Base", "respawn_west"]    call Waldo_fnc_Teleport;  // marker variable name
```

---

## Move-Into-Cargo Object — `Waldo_fnc_MoveInCargoPlane`

Adds a **"Board Into _X_"** action to an object that moves the user straight into the cargo of a named aircraft — even one already in the air. Useful for cutting paradrop wait times: spawn/fly the aircraft, and let jumpers board it from the ground via this teleporter.

### Parameters

| # | Parameter | Type | Default | Purpose |
|---|---|---|---|---|
| 0 | Teleporter | Object | — | The object the action is added to (often `this`). |
| 1 | Aircraft | Object | — | Variable name of the aircraft to board. |
| 2 | Custom name | String | `"Plane"` | Text shown in the **"Board Into _X_"** action. |

The aircraft must have a **variable name** to be referenced.

### Examples

```sqf
[this, aircraft] call Waldo_fnc_MoveInCargoPlane;               // "Board Into Plane"
[this, aircraft, "ARGUS 1-4"] call Waldo_fnc_MoveInCargoPlane;  // "Board Into ARGUS 1-4"
```

---

## See also

* [Vehicle Actions & Paradrop](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Vehicle-Actions-&-Paradrop) — the HALO / static-line jump system you'd board the aircraft for
* [Map Location Tools](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Map-Location-Tools) — create named map locations to teleport to
* [Mobile Command Post](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Mobile-Command-Post-With-Integrated-Logistics-System)
