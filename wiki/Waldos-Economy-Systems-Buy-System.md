_Associated Files: MissionScripts\EconomySystems\Buy\ (`Waldo_fnc_EcoBuy_*`)_

The Buy System lets players **purchase vehicles** with their side's [resources](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Resource-System), once any [research](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Research-System) or [building](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Build-System) requirements are met. Purchases are made at a terminal and the vehicle appears at a configured drop point.

## Purchase terminals

Players buy from a **purchase terminal** (`Land_Laptop_unfolded_F`) via the ACE interaction menu. Spawn one in Zeus (**Waldos Economy Systems → Buy → Spawn Purchase Terminal**), from script, or designate an editor-placed laptop:

```sqf
[this] call Waldo_fnc_EcoBuy_registerTerminal;   // in a placed Land_Laptop_unfolded_F's init field
```

## Drop points

A **drop point** is where purchased vehicles spawn, typed by **Ground**, **Air** or **Naval** so each kind of vehicle appears somewhere sensible (a motor pool, a helipad, a dock). Drop points can be restricted by side. Create them in Zeus (**Buy → Create Drop Point**) or from script:

```sqf
// [position, "Ground"/"Air"/"Naval", direction, "ANY"/side]
[getMarkerPos "motorpool", "Ground", 0, "ANY"] call Waldo_fnc_EcoBuy_createDropPoint;
[getMarkerPos "helipad_1", "Air", 90, "WEST"] call Waldo_fnc_EcoBuy_createDropPoint;
```

When a vehicle is purchased, the system finds an available drop point of the matching type for the buyer's side and spawns the vehicle there.

## Defining purchases

Each purchase entry has a **name**, **description**, **cost**, **requirements**, the vehicle **classname**, a **type** (Ground/Air/Naval, which selects the drop point), and a **side** restriction (`EVERYONE` or a specific side).

In Zeus: **Buy → Configure Purchases**. From script:

```sqf
// [name, description, costRows, requirementList, "ClassName", "Ground"/"Air"/"Naval", "EVERYONE"/side]
[[
    ["Transport Truck", "A cargo truck.",      [["Money", 10]], ["Vehicle Depot"], "B_Truck_01_transport_F", "Ground", "EVERYONE"],
    ["Transport Heli",  "A light helicopter.", [["Money", 25]], ["Air Doctrine"],  "B_Heli_Light_01_F",      "Air",    "WEST"]
]] call Waldo_fnc_EcoBuy_setPurchaseCatalog;
```

* `costRows` — `[["Resource", amount], ...]`
* `requirementList` — completed research or built structures that gate the purchase

## See also

* [Setup & Configuration](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Setup-And-Configuration)
