# Economy — Research system

Read `core.md` first for the enable flow and authority model.

## What it does

A Research Center where a side spends resources on custom research entries
with costs, prerequisites, and mutual exclusivity.

## Setup entry points

```sqf
setResearchCatalog       // define the research catalog (cost/prereqs/exclusivity)
spawnResearchCenter       // world object hosting the research UI
```

Or designate an existing Eden-placed vanilla object:

```sqf
[this] call Waldo_fnc_EcoResearch_registerCenter;   // on a Land_Research_HQ_F
```

## Object tagging

Research center: `Land_Research_HQ_F`.

## Function namespace

Callable as `Waldo_fnc_EcoResearch_*`. As with Resource, the full function
list isn't enumerated in `CLAUDE.md` — go to the script headers under
`MissionScripts/EconomySystems/Research/` or the wiki for exhaustive param
detail beyond the entry points above.
