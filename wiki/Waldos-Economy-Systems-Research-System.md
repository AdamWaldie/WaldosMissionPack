_Associated Files: MissionScripts\EconomySystems\Research\ (`Waldo_fnc_EcoResearch_*`)_

The Research System adds a **tech tree** to [Waldos Economy Systems](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems). A side spends [resources](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Resource-System) at a Research Center to unlock research, which in turn gates what they can [build](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Build-System) and [buy](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Buy-System).

## The Research Center

Research is conducted at a Research Center (`Land_Research_HQ_F`). Players interact with it through the ACE menu to view available research and start it. Place one in Zeus (**Waldos Economy Systems → Research → Spawn Research Center**), from script, or designate an editor-placed `Land_Research_HQ_F`:

```sqf
[getMarkerPos "research_1"] call Waldo_fnc_EcoResearch_spawnResearchCenter;   // spawn
// or, in a placed Land_Research_HQ_F's init field:
[this] call Waldo_fnc_EcoResearch_registerCenter;
```

## Defining research

Each research entry has a **name**, **description**, **cost** (resource rows), **requirements** (other research/buildings that must exist first), and a **time** in seconds. You can also make entries **mutually exclusive**, so choosing one locks out another (doctrine choices).

In Zeus: **Research → Configure Research**. From script (entry shape — trailing fields are optional):

```sqf
// [name, description, costRows, requirementList, timeSeconds, icon, color, alreadyResearched, exclusiveWithList]
[[
    ["Logistics I",   "Basic supply handling.",        [["Money", 10]], [],              60],
    ["Vehicle Depot", "Unlocks transport purchases.",  [["Money", 20]], ["Logistics I"], 120],
    ["Doctrine: Armor", "Heavy armor focus.",          [["Money", 30]], ["Logistics I"], 120, "", "", false, ["Doctrine: Air"]]
]] call Waldo_fnc_EcoResearch_setResearchCatalog;
```

* `costRows` — `[["Resource", amount], ...]`
* `requirementList` — `["Some Research", "Some Building"]` (names of completed research or built structures)
* `exclusiveWithList` — names of research that cannot coexist with this one

## How it plays

1. A player (or [Ground Command](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Ground-Command-And-Tools)) selects a research at the Research Center.
2. If the side can afford it and the prerequisites are met, the cost is deducted and the research enters progress.
3. After the time elapses it completes for that side, unlocking anything that required it.

Build-system structures can grant **research-speed boosts**, shortening research time while they stand.

## See also

* [Build System](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Build-System) — buildings that require research and boost research speed.
* [Setup & Configuration](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Setup-And-Configuration)
