# Economy — core / bootstrap / authority model

## Enabling (OFF by default — missions that don't use it pay no cost)

`Waldo_Economy_Enable` now lives in `MissionConfig\missionSystemsConfig.sqf`
(a `shared` entry, loaded automatically on every machine — do not paste the
old `if (Waldo_Economy_Enable) then { [] spawn Waldo_fnc_EcoInit; }`
lifecycle block into `init.sqf` yourself, WMP already runs it):

```sqf
["Waldo_Economy_Enable", false],  // BOOL: starts economy runtime; catalogue/resources still need setup
```

Or drop the **`[WMP] Waldos Economy Systems`** composition (in
`WMP_Compositions/`) into the editor — its object boots the suite from its
own init field independent of this flag. This is the simplest path for a
mission maker who just wants it running — mention it as the default
recommendation over hand-editing `init.sqf` unless they want more control.

**Place only one Economy Systems object per mission** — this is an Eden
Editor placement rule (instruction mode).

## Editor / script-time setup (no Zeus needed)

`Waldo_fnc_EcoInit` calls `Waldo_fnc_EcoCore_applyMakerConfig`, which reads
optional maker variables once on the server authority (broadcast, so
JIP/rejoining players inherit them) and applies them via the existing
import/preset functions. Set in `initServer.sqf`:

```sqf
// A bundled preset:
missionNamespace setVariable ["Waldo_Economy_Preset", "MEDIUM", true];   // LOW | MEDIUM | HIGH
missionNamespace setVariable ["Waldo_Economy_PresetSides", [["WEST","NATO"],["EAST","CSAT"],["GUER","AAF"]], true];
// or a full configuration exported from the Zeus "Export" tool (wins over a preset):
missionNamespace setVariable ["Waldo_Economy_ConfigString", "...", true];
// optional perf toggle:
missionNamespace setVariable ["Waldo_Economy_CommitmentMode", true, true];
```

For drag-and-go, the preset-specific compositions **`[WMP] Waldos Economy
Systems - Low/Medium/High Preset`** set `Waldo_Economy_Preset` in their
object init and boot the suite — recommend these over manual variable
setting for a mission maker who just wants a working default fast.

## Full hand-authored economy (`MissionConfig/economyConfig.sqf`)

The dedicated authoring file (registered as `Waldo_fnc_EcoMakerSetup`, run
once on the authority by `applyMakerConfig` after presets). Defines catalogs
and places world objects via server-authoritative helpers:
`addResourceType`, `setResearchCatalog`, `setBuildCatalog`,
`setPurchaseCatalog`, `createResourceZone`, `spawnResourceCrate`,
`spawnResearchCenter`, `createDropPoint`. Ships a gated worked example
(`_useExample`) — point the user at it as a template rather than writing a
catalog from scratch.

Editor-placed vanilla objects can be designated from their init field (no
addon required — true Eden modules would need one, which WMP is not):

```sqf
[this] call Waldo_fnc_EcoResearch_registerCenter;         // on a Land_Research_HQ_F
[this] call Waldo_fnc_EcoBuy_registerTerminal;             // on a Land_Laptop_unfolded_F
[this] call Waldo_fnc_EcoBuild_registerConstructionVehicle; // on any vehicle
```

## Authority model (read this before editing any Economy code)

All shared state (catalogs, side resources, zones, jobs) and all global
world-object/marker creation are gated by
`Waldo_fnc_EcoCore_canRunAuthority` / `canRunBackgroundAuthority`, which
return **`isServer`** — the server is the single authority, background
loops (income, production, research progress, request processing) run
exactly once. Client-only work (ZEN module registration, ACE action setup,
dialogs, request *publishing*) is gated by `hasInterface`.

Because ZEN custom-module code runs on the **curator's client**, the seven
object-creation functions (research center, resource crate, resource zone,
building, construction vehicle, purchase laptop, drop point) forward
themselves to the server via `remoteExec [..., 2]` when called off the
authority — this is what makes placement work on a **dedicated** server, not
just SP/listen-host. If extending Economy code: mutate shared state only
under `canRunAuthority` and broadcast it; never gate client-local work on
`canRunAuthority`; route any new world-object creation through the
authority the same way.

## Operational notes

- `Waldo_fnc_EcoCore_isActive` — whether the suite is running; gate
  dependent scripts on this.
- Failed player actions (insufficient resources / unmet requirements / no
  drop point) report via `systemChat` to the actor
  (`Waldo_fnc_EcoCore_notifyActor`) — not silent failure.
- **Commitment mode** is a performance toggle only: ON freezes live
  config-catalog refresh polling in the Zeus menus to cut server load. Turn
  it on once the economy is configured; it doesn't affect gameplay.
- **Purge** removes the suite for the rest of the mission (sets a broadcast
  purged flag that also stops JIP re-init) — it is not a reset. Restart the
  mission to run the economy again after a purge. Don't suggest Purge as a
  way to "reload" the economy mid-mission.
- **Economy Setup Builder** (Resource/Research/Construction/Purchasing
  domain builders) translates Zeus-authored settings/placements into
  readable calls to the same public functions used in
  `economyConfig.sqf` — good for a mission maker who authored live in Zeus
  and now wants a permanent, restart-safe config file. Portable catalogue
  strings remain available via Config Copy and Import.
