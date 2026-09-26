# Economy Build System

> **Use this page when:** you need construction vehicles, build catalogues, placement, upgrades, limits, or RADAR.

_Associated Files: MissionScripts\EconomySystems\Build\ (`Waldo_fnc_EcoBuild_*`)_

![Construction catalog](images/economy/economy-build.png)

The Build System lets players construct and upgrade buildings. Buildings can produce [resources](Waldos-Economy-Systems-Resource-System), raise storage, speed up [research](Waldos-Economy-Systems-Research-System) and construction, or reveal enemies.

## Quick setup: construction vehicles

Players build using a **construction vehicle**. From it they pick a building from the catalog, place it, and a construction job runs to completion. Designate any vehicle as a construction vehicle in Zeus (**WMP Economy Systems → Build → Spawn Construction Vehicle**), from script, or via an editor-placed vehicle's init field:

```sqf
[this] call Waldo_fnc_EcoBuild_registerConstructionVehicle;
```

> **The source vehicle is consumed.** Confirming placement converts the
> construction vehicle into the construction site; it is not returned after the
> job. The action is labelled **Deploy + Consume**, the placement view repeats
> the warning, and a timed completion notice names the vehicle that was
> converted. Reusable construction bases are not consumed and do not show this warning.

The same build controls are available through ACE and a vanilla interaction.
All player Economy dialogs are constrained to the protected screen area and use
the WMP operations-console visual treatment.

## Settings: defining buildings

Each build entry names the object to construct, its cost, requirements and build
time. Optional fields control production, storage, speed boosts, upkeep, side
access, limits and upgrades.

In Zeus: **Build → Configure Buildings** (a tabbed editor for the many fields). From script, trailing fields are optional and default sensibly:

```sqf
// [name, desc, costRows, requirementList, buildTime, icon, color, false, "ClassName", produceResource, produceAmount, produceInterval, ...]
[[
    ["Generator",    "Produces electricity over time.",  [["Money", 15]], [],              90, "", "", false, "Land_PowerGenerator_F", "Electricity", 2, 20],
    ["Supply Depot", "Raises supply storage.",           [["Money", 10]], [],              60, "", "", false, "Land_Cargo_HQ_V1_F"],
    ["Radar Station","Reveals enemy units periodically.",[["Money", 25]], ["Logistics I"], 120,"", "", false, "Land_Radar_Small_F"]
]] call Waldo_fnc_EcoBuild_setBuildCatalog;
```

* `costRows`: `[["Resource", amount], ...]`. `requirementList`: research/building names that must exist first
* Production: a building can output a resource every N seconds while it stands (subject to the side's storage cap).
* Boosts: buildings can shorten research and construction times, and raise resource storage caps.
* Upkeep: a building can consume resources over time to keep running.

### Full row reference

Every field beyond `name` is optional. The example above sets the first 12:

| # | Field | Type | Default | Purpose |
|---|---|---|---|---|
| 0 | `name` | String | required | Catalogue key and display name |
| 1 | `description` | String | `""` | Shown in the build menu |
| 2 | `costRows` | Array of `[resource String, amount Number]` rows | `[]` | Resource cost |
| 3 | `requirements` | Array of name Strings | `[]` | Research/building names that must exist first |
| 4 | `buildTime` | Number, seconds | `60` | Minimum `1` |
| 5 | `icon` | Image-path String | resource default icon | Menu icon |
| 6 | `color` | Hex-colour String | resource default colour | Menu accent colour |
| 7 | *(reserved)* | Boolean | `false` | Normalizer forces `false`; leave this slot in long rows |
| 8 | `className` | `CfgVehicles` class String | `""` | Object spawned on completion |
| 9 | `produceResource` | Resource-name String | `""` | Resource generated while standing |
| 10 | `produceAmount` | Number | `0` | Amount produced per interval |
| 11 | `produceInterval` | Number, seconds | `0` | Time between production ticks |
| 12 | `researchSpeedBoost` | Number | `0` | Reduces research time while standing |
| 13 | `buildSpeedBoost` | Number | `0` | Reduces construction time while standing |
| 14 | `detectorRange` | Number, metres | `0` | Non-zero makes this a RADAR building |
| 15 | `upkeepCosts` | Array of `[resource String, amount Number]` rows | `[]` | Consumed per upkeep interval |
| 16 | `upkeepInterval` | Number, seconds | `0` | Time between upkeep charges |
| 17 | `storageRows` | Array of `[resource String, capacity boost Number]` rows | `[]` | Raises storage cap |
| 18 | `upgradeTo` | Catalogue-name String | `""` | Entry this building can upgrade into |
| 19 | `buildLimit` | Number | `0` | Maximum standing count per side; zero is unlimited |
| 20 | `availability` | Array of side-name Strings | `["ALL"]` | Sides allowed to build this entry |
| 21 | `category` | String | `""` | Optional menu grouping label |

`Waldo_fnc_EcoBuild_setBuildCatalog` takes one Array of these rows, replaces
the server-owned catalogue and returns nothing. Put authored calls in
`MissionConfig/economyConfig.sqf`. The
`Waldo_fnc_EcoBuild_registerConstructionVehicle` call takes one existing vehicle
Object, tags it for client/JIP actions and has no documented return value.

## Upgrades & limits

Buildings can be **upgraded** into a higher tier, and you can cap how many of a building a side may have (**build limits**). Availability can be restricted per side.

## RADAR

A building flagged as a RADAR periodically reveals enemy units on the map for its side. It can have an upkeep cost.

## If a building is unavailable

Check its catalogue entry, required research, side access, resource cost and build limit. A valid object class still needs a clear placement area. The [Economy Setup](Waldos-Economy-Systems-Setup-And-Configuration) guide explains how to preserve a Zeus-authored definition for the next mission run.

## See also

* [Resource System](Waldos-Economy-Systems-Resource-System): production and storage feed the Build System.
* [Setup & Configuration](Waldos-Economy-Systems-Setup-And-Configuration)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
