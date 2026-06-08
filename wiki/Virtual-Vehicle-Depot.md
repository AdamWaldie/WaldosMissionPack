_Associated Files: MissionScripts\Logistics\VirtualVehicleDepot_

> **This feature is Work In Progress.** It is functional for general use but has known limitations documented below. Test thoroughly with your mod set before using in a live mission.

The VVD (Virtual Vehicle Depot) provides an in-mission vehicle spawner with a graphical garage interface. Players interact with a placed object to browse, configure, and spawn vehicles onto a designated spawn pad.

---

## Features

- Browse all vehicles of the configured type(s) available in loaded mods
- Configure **damage** per hitpoint — set a vehicle to spawn already damaged (e.g. battle-worn trucks)
- Configure a **damage delay** — vehicle spawns undamaged and takes the set damage after a specified time
- Modify **weapon loadouts and pylons** where the vehicle's mod config supports it
- Adjust **cosmetics** (textures, camo)
- Toggle **AI crew** per seat
- Apply **unit insignias** to the spawned vehicle

---

## Eden Setup

1. Place the **interaction object** (e.g. a laptop) and give it a variable name. This is what players click on.
2. Place a **helipad** (or any flat object) where the vehicle will spawn. Give it a variable name (e.g. `Circle_Helipad`). Vehicles spawn on top of it.
3. In the interaction object's init, call `Waldo_fnc_VVDInit` (see parameters below).

![Example of mission pack setup](https://i.imgur.com/0DkSWJl.png)

A pre-built composition with this setup is included in the WMP Compositions download.

---

## Parameters

```sqf
[spawnerObject, spawnPad, types, allowedSides, enforcePlayerSide, limitToSideVehicles, removeUavs, range, script]
    call Waldo_fnc_VVDInit;
```

| Parameter | Type | Description |
|---|---|---|
| `spawnerObject` | OBJECT | The object players interact with to open the garage |
| `spawnPad` | OBJECT | Helipad or flat surface where vehicles spawn |
| `types` | ARRAY of STRING | Vehicle categories to show — see table below |
| `allowedSides` | ARRAY of STRING | Sides allowed to use the spawner |
| `enforcePlayerSide` | BOOL | If true, player's side must match `allowedSides` |
| `limitToSideVehicles` | BOOL | Limit spawnable (not viewable) vehicles to player's side. Unreliable — recommend `false` |
| `removeUavs` | BOOL | Attempt to hide UAVs from the list. Works ~80% of the time depending on mod config |
| `range` | NUMBER | Distance in metres from which the interactions are visible |
| `script` | STRING | SQF code string to execute on the spawned vehicle. Bypasses garage if non-empty |

### Vehicle Type Options (`types`)

| Value | Shows |
|---|---|
| `"Auto"` | Detects surface — ground vehicles on land, ships on water |
| `"All"` | All vehicle types |
| `"Ground"` | Cars, tanks, static weapons |
| `"Car"` | Wheeled vehicles |
| `"Tank"` | Tracked armour |
| `"Helicopter"` | Rotary wing |
| `"Plane"` | Fixed wing |
| `"Ship"` | Naval |
| `"StaticWeapon"` | Static weapons only |

Multiple types can be combined: `["Car", "Tank"]`

### Side Options (`allowedSides`)

`["BLUFOR"]`, `["OPFOR"]`, `["INDEP"]`, `["CIV"]`, `["ALL"]`

---

## Example Calls

```sqf
// Fully unrestricted — all vehicles, all sides, 10 m range
[this, Circle_Helipad, ["All"], ["ALL"], false, false, false, 10, ""] call Waldo_fnc_VVDInit;

// BLUFOR only, ground vehicles, enforce side check
[this, Circle_Helipad, ["Ground"], ["BLUFOR"], true, false, false, 15, ""] call Waldo_fnc_VVDInit;

// Air only, auto-run a script on each spawned vehicle
[this, Helipad_1, ["Helicopter","Plane"], ["ALL"], false, false, false, 10, "[this] call someFunction;"] call Waldo_fnc_VVDInit;
```

---

## Spawner Interactions

Three ACE scroll-wheel actions are added to the spawner object:

| Action | Description |
|---|---|
| **Open Garage [name]** | Opens the garage GUI to browse and configure vehicles |
| **Delete Vehicles [name]** | Deletes all non-default vehicles within 10 m of the spawn pad |
| **Reset Garage Flag** | Clears a stuck "garage open" state if the garage UI was closed incorrectly |

---

## Damage Configuration (VVDVehicleDamage)

When configuring damage in the garage, vehicles can be set to spawn with pre-applied damage to specific hitpoints. An optional **damage delay** allows the vehicle to spawn in its full state and degrade after a set time window — useful for simulating vehicles that have been running for hours.

The delay is randomised within a configured min/max range. If `min == max`, the delay is exact.

---

## Known Limitations

| Issue | Notes |
|---|---|
| UAV removal | Works ~80% of the time — mod config dependent |
| Side vehicle limiting (`limitToSideVehicles`) | Works ~50% of the time — recommend leaving `false` |
| UI appearance | Functional but not polished — this is explicitly WIP |
| Pylon/weapon config | Only works for vehicles whose mod exposes pylon config to the garage system |
