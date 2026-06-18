_Associated Files: MissionScripts\EconomySystems\Build\ (`Waldo_fnc_EcoBuild_*`)_

The Build System is the most intricate part of [Waldos Economy Systems](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems). It lets players construct and upgrade buildings that shape the economy — producing [resources](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Resource-System), raising storage, speeding up [research](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Research-System)/construction, or revealing the enemy.

## Construction vehicles

Players build using a **construction vehicle**. From it they pick a building from the catalog, place it, and a construction job runs to completion. Designate any vehicle as a construction vehicle in Zeus (**Waldos Economy Systems → Build → Spawn Construction Vehicle**), from script, or via an editor-placed vehicle's init field:

```sqf
[this] call Waldo_fnc_EcoBuild_registerConstructionVehicle;
```

## Defining buildings

Each build entry is rich — you give it a **name**, **description**, **cost**, **requirements**, **build time**, the **classname** to spawn, and any of: **resource production** (resource + amount + interval), **storage capacity** boosts, **research-** and **construction-speed** boosts, **upkeep**, **side availability**, **build limits**, and upgrade targets.

In Zeus: **Build → Configure Buildings** (a tabbed editor for the many fields). From script, trailing fields are optional and default sensibly:

```sqf
// [name, desc, costRows, requirementList, buildTime, icon, color, false, "ClassName", produceResource, produceAmount, produceInterval, ...]
[[
    ["Generator",    "Produces electricity over time.",  [["Money", 15]], [],              90, "", "", false, "Land_PowerGenerator_F", "Electricity", 2, 20],
    ["Supply Depot", "Raises supply storage.",           [["Money", 10]], [],              60, "", "", false, "Land_Cargo_HQ_V1_F"],
    ["Radar Station","Reveals enemy units periodically.",[["Money", 25]], ["Logistics I"], 120,"", "", false, "Land_Radar_Small_F"]
]] call Waldo_fnc_EcoBuild_setBuildCatalog;
```

* `costRows` — `[["Resource", amount], ...]`  ·  `requirementList` — research/building names that must exist first
* Production: a building can output a resource every N seconds while it stands (subject to the side's storage cap).
* Boosts: buildings can shorten research and construction times, and raise resource storage caps.
* Upkeep: a building can consume resources over time to keep running.

## Upgrades & limits

Buildings can be **upgraded** into a higher tier, and you can cap how many of a building a side may have (**build limits**). Availability can be restricted per side.

## RADAR

A building flagged as a RADAR periodically reveals enemy units on the map for its side — a powerful, upkeep-worthy structure for map awareness.

## See also

* [Resource System](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Resource-System) — production and storage feed the Build System.
* [Setup & Configuration](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Setup-And-Configuration)
