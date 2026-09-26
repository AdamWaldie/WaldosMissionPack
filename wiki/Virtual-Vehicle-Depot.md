# Virtual Vehicle Depot

> **Use this page when:** you need to configure or operate WMP's virtual garage and deployment point.

_Associated files: `MissionScripts\Logistics\VirtualVehicleDepot\VVDInit.sqf`, `VVDRequestOpenServer.sqf`, `VVDOpen.sqf` and `description.ext`_

> **Work in progress:** test the garage with the vehicle mods and spawn area you intend to use.

The Virtual Vehicle Depot puts a garage on a placed object. Players use it to choose a vehicle, configure supported options, and spawn it at a separate pad. The terminal and pad are both required.

---

## Features

- Browse all vehicles of the configured type(s) available in loaded mods
- Configure **damage** per hitpoint to spawn a vehicle with damage
- Configure a **damage delay** to apply that damage after spawn
- Modify **weapon loadouts and pylons** where the vehicle's mod config supports it
- Adjust **cosmetics** (textures, camo)
- Toggle **AI crew** per seat
- Apply **unit insignias** to the spawned vehicle

---

## Quick start in Eden

1. Place a **terminal** such as a laptop. This is what players interact with.
2. Place a **spawn-point object** on open, flat ground. Give it a variable name such as `depotPad`. Leave at least 20 metres clear around it because the garage rejects a pad occupied by another vehicle.
3. Put the call below in the terminal's Eden init field. Change `depotPad` to your spawn-point object's variable name.

```sqf
[this, depotPad] call Waldo_fnc_VVDInit;
```

The call runs on each machine from an Eden init field. The server publishes the terminal and pad state. Current clients and JIP clients receive the local interaction. There is no mission-wide enable flag for this placed-object setup.

A `[WMP]` composition also provides a placed example. Check its terminal and pad positions before use.

---

## Call: `Waldo_fnc_VVDInit`

```sqf
[spawnerObject, spawnPad, types, allowedSides, enforcePlayerSide, limitToSideVehicles, removeUavs, range, script]
    call Waldo_fnc_VVDInit;
```

| # | Parameter | Type | Default | Use |
|---|---|---|---|---|
| 0 | `spawnerObject` | Object | Required | Terminal the player uses. A null object rejects setup |
| 1 | `spawnPad` | Object | Required | Object that marks the spawn point. A null object rejects setup |
| 2 | `types` | Array of Strings | `["Auto"]` | Vehicle categories to list; see below |
| 3 | `allowedSides` | Array of Strings | `["ALL"]` | Side labels used by the terminal's access check |
| 4 | `enforcePlayerSide` | Boolean | `false` | Check the player's group side against `allowedSides` before requesting the garage |
| 5 | `limitToSideVehicles` | Boolean | `false` | Pass a side filter to the garage list. Check results with your vehicle mods |
| 6 | `removeUavs` | Boolean | `false` | Pass the UAV filter to the garage list. Check results with your vehicle mods |
| 7 | `range` | Number (metres) | `10` | Terminal use range. The server enforces at least 1 metre |
| 8 | `script` | String of SQF code | `""` | Extra code compiled and run after a vehicle spawns. Leave empty unless you need it |

**Return:** Boolean. `false` means the terminal or pad is null. A valid setup returns `true`, including repeat calls where local actions are already installed. One client's result does not prove that another client has finished installing ACE actions. The server publishes setup for JIP.

### Vehicle Type Options (`types`)

| Value | Shows |
|---|---|
| `"Auto"` | Uses the pad's surface: cars, tanks, helicopters, planes and static weapons on land; ships on water |
| `"All"` | All vehicle types |
| `"Ground"` | Cars, tanks, helicopters, planes and static weapons; this is the current source behaviour |
| `"Car"` | Wheeled vehicles |
| `"Tank"` | Tracked armour |
| `"Helicopter"` | Rotary wing |
| `"Plane"` | Fixed wing |
| `"Ship"` | Naval |
| `"StaticWeapon"` | Static weapons only |

Multiple types can be combined: `["Car", "Tank"]`

### Side Options (`allowedSides`)

Use labels such as `["BLUFOR"]`, `["OPFOR"]`, `["INDEP"]`, `["CIV"]` or the default `["ALL"]`. The local terminal action checks the player's side. Scripts that call the server request function directly do not pass through that check.

---

## Example Calls

```sqf
// All vehicles, all sides, 10 m range
[this, Circle_Helipad, ["All"], ["ALL"], false, false, false, 10, ""] call Waldo_fnc_VVDInit;

// BLUFOR players, ground vehicles, enforce the terminal's side check
[this, Circle_Helipad, ["Ground"], ["BLUFOR"], true, false, false, 15, ""] call Waldo_fnc_VVDInit;

// Air vehicles with an extra script. This script runs after spawn with _veh in scope.
[this, Helipad_1, ["Helicopter","Plane"], ["ALL"], false, false, false, 10, "[_veh] call myMission_fnc_prepareAircraft;"] call Waldo_fnc_VVDInit;
```

---

## During play

With ACE loaded, the terminal has an ACE **Virtual Vehicle Depot** menu. Without ACE, it has two vanilla actions. The server owns a lock so only one player opens a given pad at a time.

| Action | Description |
|---|---|
| **Open Vehicle Garage** | Requests the garage GUI. The server checks the player, terminal, range, pad occupancy and current lock |
| **Clear Depot Spawn Area** | Removes nearby vehicles not marked as default vehicles. This can delete a vehicle and its crew; use it carefully |

---

## Damage Configuration (VVDVehicleDamage)

The garage can apply damage to selected hitpoints after spawn. A delay range lets that damage appear later. Keep both delay values at zero to apply it immediately.

The delay is randomised within a configured min/max range. If `min == max`, the delay is exact.

---

## Limitations and troubleshooting

| Issue | Notes |
|---|---|
| UAV removal | The filter depends on the vehicle's mod configuration. Confirm the list in play |
| Side vehicle limiting (`limitToSideVehicles`) | The garage list uses mod vehicle metadata. Confirm the list in play |
| Spawn area | A non-man vehicle within 20 m prevents the garage opening. Keep the area clear |
| Extra script | Runs compiled SQF after spawn. Use `_veh` for the spawned vehicle; the `this` keyword is not supplied as a vehicle variable |
| UI appearance | Work in progress |
| Pylon/weapon config | Only works for vehicles whose mod exposes pylon config to the garage system |

If the menu does not appear, check that both Eden object references exist and that ACE has loaded. If the garage refuses to open, clear the 20 m spawn area and check that another player is not using this pad. The display also requires the garage include in WMP's `description.ext`.

## See also

- [Vehicle Recovery](Vehicle-Recovery)
- [Vehicle Appearance](Vehicle-Appearance)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
