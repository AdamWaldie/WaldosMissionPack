# Dynamic AO Generation

> **Use this page when:** Zeus or a server script needs to build and later remove a complete randomized area of operations during a running mission.

_Associated Files: `MissionScripts/CombatSystems/DynamicAO/`; `MissionScripts/ZenModules/Zen_initModules.sqf`_

Dynamic AO is a runtime-only, server-authoritative generator. It does not require compositions, pre-placed units or an editor module. One request can independently create infantry patrols, building garrisons, manned static weapons, weighted ground and air patrols, civilians, parked civilian cars, minefields, roadblocks and global AO markers.

## Zeus workflow

Open **Modules → WMP Combat Systems → Dynamic AO - Create** and place it at the intended centre. The dialog uses a live **enemy faction and side** selector. Entries are friendly names such as `[OPFOR] CSAT`; no config classname or separate side selection is required, so the two values cannot contradict each other.

Vehicle and air percentages are relative weights. They do not need to total 100. Empty categories automatically fall through to a non-empty category belonging to the selected faction. Generated units use WMP's active AI profile (Line by default), including its faction, role, night-equipment and locality handling; Dynamic AO does not maintain a competing skill slider. Ground patrols begin in SAFE behaviour at LIMITED speed so they walk or drive as an ambient patrol until contact changes their state. Infantry select column, staggered column or wedge once per route; aircraft retain AWARE/NORMAL flight behaviour. The create module exposes every bounded AO option listed below.

Use **Dynamic AO - Remove** to select a live AO by friendly name; the AO nearest the module is preselected. You can also delete the invisible AO centre anchor through Zeus to invoke the same complete cleanup. Each generated minefield has its own curator anchor, allowing that field to be removed without deleting the rest of the AO.

The modules are registered only when Zeus Enhanced is available. The script API does not require Zeus Enhanced.

## Scripted creation

Call the generator on the server. A non-server call is forwarded to the server, but remote player requests are accepted only from an assigned curator.

Unlike most other keys, **`faction` has no default and is genuinely required** alongside `id` and
`center` — omitting it makes the whole call silently do nothing (no error, no spawned assets). The
smallest working call is:

```sqf
[createHashMapFromArray [
    ["id", "AO_NORTH"], ["center", getMarkerPos "ao_north"], ["faction", "OPF_F"]
]] call Waldo_fnc_DynamicAOCreate;
```

For every other option set explicitly:

```sqf
private _config = createHashMapFromArray [
    ["id", "AO_NORTH"], ["center", getMarkerPos "ao_north"],
    ["side", east], ["faction", "OPF_F"], ["radius", 700],
    ["patrolGroups", 4], ["garrisonGroups", 6], ["staticTurrets", 2],
    ["vehiclePatrols", 3], ["vehicleMix", [50, 35, 15]],
    ["airPatrols", 1], ["airMix", [50, 20, 20, 10]],
    ["civilianFaction", "CIV_F"], ["civilianPatrols", 10],
    ["civilianGarrisons", 6], ["civilianCars", 4],
    ["minefields", 2], ["showMineMarkers", false],
    ["roadblocks", 2], ["showMarker", true]
];
[_config] call Waldo_fnc_DynamicAOCreate;
```

Cleanup is repeat-safe:

```sqf
["AO_NORTH"] call Waldo_fnc_DynamicAODestroy;
["AO_NORTH", 0] call Waldo_fnc_DynamicAODestroyMinefield;
```

## Configuration reference

| Key | Default | Bounds or meaning |
|---|---:|---|
| `id` | required | Stable letters/numbers/underscore/hyphen key; recreating the same id safely replaces the old AO |
| `center` | required | ATL centre position |
| `side` | `east` | `west`, `east`, `independent` or `civilian`; must match the faction configuration |
| `faction` | required | Runtime `CfgFactionClasses` classname containing public assets |
| `radius` | `500` | 100–2000 m |
| `patrolGroups` | `3` | 0–12; four to eight infantry per group |
| `garrisonGroups` | `3` | 0–30; two to four infantry per building, capped by usable buildings |
| `staticTurrets` | `0` | 0–20 manned faction static weapons |
| `vehiclePatrols` | `0` | 0–10 |
| `vehicleMix` | `[34,33,33]` | Car/APC/tank relative weights |
| `airPatrols` | `0` | 0–8 |
| `airMix` | `[25,25,25,25]` | Helicopter/jet/drone/plane relative weights |
| `heliPatrolRange` | `1000` | 200–3000 m |
| `planePatrolRange` | `2000` | 200–4000 m |
| `simplePathing` | `false` | Two movement points plus cycle instead of four randomized points |
| `civilianFaction` | empty | Civilian faction classname; empty disables civilian generation |
| `civilianPatrols` | `0` | 0–50 individual wandering civilians |
| `civilianGarrisons` | `0` | 0–50 individual building civilians |
| `civilianCars` | `0` | 0–30 empty parked cars |
| `minefields` | `0` | 0–15 outer-ring mine clusters |
| `showMineMarkers` | `false` | Global red border around each field |
| `roadblocks` | `0` | 0–12 manned checkpoints on roads inside the AO |
| `displayName` | `id` | Human-readable AO name used by the centre marker and ZEN removal list |
| `showMarker` | script default `true`; Zeus default off | Global side-coloured border and the configured `displayName` centre marker. Enable **Show AO marker** in Zeus when the AO should be public. |

## Runtime discovery and classification

`Waldo_fnc_DynamicAOGetFactions` scans `CfgFactionClasses` and public `CfgVehicles`, then caches friendly faction choices. `Waldo_fnc_DynamicAOResolvePools` classifies the selected faction through engine inheritance:

- infantry: `CAManBase`;
- cars: `Car`;
- APCs and tanks: `Tank`, split using transport capacity;
- statics: `StaticWeapon`;
- helicopters and fixed-wing aircraft: `Helicopter` and `Plane`;
- drones: any supported air asset with `isUav = 1`;
- jets: fixed-wing maximum speed at or above 600 km/h; slower assets are planes.

The pool cache is local to each machine's immutable runtime configuration. Creation validates the faction and pools again on the server before mutating the world.

## Authority, JIP and cleanup

Only the server owns the full registry of objects, groups, mines and markers. Clients receive `Waldo_DynamicAO_PublicSystems`, a compact JIP-safe summary used by the remove dialog and diagnostics. Arma global markers handle their own JIP synchronization.

Every generated object is added to current curator editable objects. Whole-AO cleanup removes the registry entry first, then deletes tracked mines, field anchors, objects, units, groups and markers. This order makes deletion-event cleanup repeat-safe. Patrol generation is server-local, enables movement/pathing, leaves Arma's engine-created waypoint lifecycle intact and appends the MOVE/CYCLE route without a competing direct movement order. Infantry in a new patrol receive placement clearance around the group start instead of sharing one exact position; this prevents collision-locked squads on dedicated servers. Generated AI are passed through `Waldo_fnc_AIApplyProfile` after their final group assignment and remain eligible for the handler's new-unit and locality-change paths. The active WMP profile is therefore authoritative. A legacy scripted config may still contain `skill`; it is accepted for compatibility but ignored.

## Engine and terrain boundaries

Open terrain legitimately produces fewer garrisons, parked cars and roadblocks because those features require suitable buildings, open positions or roads. The generator caps them rather than fabricating unsuitable locations. `BIS_fnc_findSafePos` reduces overlap risk but cannot guarantee a perfect placement in extremely dense custom terrain; use cleanup and regenerate at a clearer centre if required.

The audit mission includes a dedicated **Dynamic AO** station. Its VR test deliberately requests building and road features on a map with neither, proving the cap/cleanup behavior while still generating patrols, faction assets, civilians, a minefield and markers. The station requires every generated patrol route to be active and reports how many routed groups physically moved during a 15-second observation window.

## Related pages

- [WMP Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)
- [Dynamic Anti-Air](Dynamic-Anti-Air)
- [Waldo's AI Tuning](Waldos-AI-Tweak)
- [Mission Diagnostics](Mission-Diagnostics)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
