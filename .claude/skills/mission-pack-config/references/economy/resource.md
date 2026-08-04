# Economy — Resource system

Read `core.md` first for the enable flow and authority model — this file
only covers what's specific to Resource.

## What it does

Define arbitrary resources (name/colour/icon/storage cap), spawn
collectable resource crates, and create capturable zones that passively
generate resources (with deposit caps). Per-side storage limits apply.

## Setup entry points

```sqf
addResourceType        // define a resource in the catalog (name/colour/icon/storage cap)
createResourceZone      // capturable zone, passive generation, deposit cap
spawnResourceCrate      // collectable world crate
```

These are called from `MissionConfig/economyConfig.sqf` (hand-authored) or
produced by the Zeus "Economy Setup Builder" export (see `core.md`). World
objects created this way are gated through the server authority — see
`core.md`'s authority section before adding new resource-related object
creation.

## Object tagging

Resource crates are tagged by class: `Land_PlasticCase_01_medium_F`.

## Function namespace

Callable as `Waldo_fnc_EcoResource_*`. The exhaustive function list isn't
enumerated in `CLAUDE.md` — if a specific function's exact params are
needed beyond the setup entry points above, check the script header in
`MissionScripts/EconomySystems/Resource/` if the project has it, or the
Waldos Economy Systems wiki pages.
