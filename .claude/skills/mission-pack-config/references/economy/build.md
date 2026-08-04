# Economy — Build system

Read `core.md` first for the enable flow and authority model.

## What it does

A build catalog (classname/cost/requirements/upkeep/production/storage/
speed boosts), construction jobs, upgrades, build limits, plus a RADAR
feature.

## Setup entry points

```sqf
setBuildCatalog       // define buildable classes and their cost/requirement/upkeep profile
```

Or designate an existing Eden-placed vehicle as a construction vehicle:

```sqf
[this] call Waldo_fnc_EcoBuild_registerConstructionVehicle;   // any vehicle
```

**Construction intentionally converts and consumes its source vehicle** —
this is deliberate, not a bug to work around. The confirmation UI warns
before the action, and a timed notice names the vehicle consumed afterward.
If a user is surprised their construction vehicle "disappeared," this is
why.

## Function namespace

Callable as `Waldo_fnc_EcoBuild_*`. Full function list isn't enumerated in
`CLAUDE.md` — check script headers under `MissionScripts/EconomySystems/Build/`
or the wiki for exhaustive param detail beyond the entry points above.
