# Dynamic AO Generation

> **Use this page when:** Zeus or a server script needs to build and later remove a complete randomized area of operations during a running mission.

_Associated Files: `MissionScripts/CombatSystems/DynamicAO/`; `MissionScripts/ZenModules/Zen_initModules.sqf`_

Dynamic AO is a runtime-only, server-authoritative generator. It does not require compositions, pre-placed units or an editor module. One request can independently create infantry patrols, building garrisons, manned static weapons, weighted ground and air patrols, civilians, parked civilian cars, minefields, roadblocks and global AO markers.

## Quick setup in Zeus

Open **Modules → WMP AI & Combat → Dynamic AO - Create** and place it at the intended centre. The dialog uses a live **enemy faction and side** selector. Entries are friendly names such as `[OPFOR] CSAT`; no config classname or separate side selection is required, so the two values cannot contradict each other.

Vehicle and air percentages are relative weights. They do not need to total 100. Empty categories automatically fall through to a non-empty category belonging to the selected faction. Generated units use WMP's active AI profile (Line by default), including its faction, role, night-equipment and locality handling; Dynamic AO does not maintain a competing skill slider. Ground patrols begin in SAFE behaviour at LIMITED speed so they walk or drive as an ambient patrol until contact changes their state. Infantry select column, staggered column or wedge once per route; aircraft retain AWARE/NORMAL flight behaviour. The create module exposes every bounded AO option listed below.

Use **Dynamic AO - Remove** to select a live AO by friendly name; the AO nearest the module is preselected. You can also delete the invisible AO centre anchor through Zeus to invoke the same complete cleanup. Each generated minefield has its own curator anchor, allowing that field to be removed without deleting the rest of the AO.

The modules are registered only when Zeus Enhanced is available. The script API does not require Zeus Enhanced.

## Scripted creation

Call the generator on the server. An Eden Init field runs on several machines; only its server copy creates the AO. A client script must supply the requesting curator player as the second argument. The server accepts that request only when the player belongs to the sending client and has an assigned curator. A client call without a requester exits without creating an AO.

`id`, `center` and `faction` are required. An incomplete request returns `false` on the server. When a requester was supplied, that player also receives an error notification. The smallest working call is:

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

| Public call | Position | Type | Default | Result |
| --- | --- | --- | --- | --- |
| `Waldo_fnc_DynamicAOCreate` | `0: config` | HashMap | Empty HashMap, rejected | Requires the `id`, `center` and `faction` entries below. Server returns `true` after accepting and registering the AO, `false` after rejection. |
| `Waldo_fnc_DynamicAOCreate` | `1: requester` | Player Object | `objNull` | Leave out for a server script or Eden Init. A remote curator supplies their player object so the server can verify authority and send feedback. |
| `Waldo_fnc_DynamicAODestroy` | `0: AO ID` | String | `""`, rejected | Server returns `true` when it removes a registered AO, `false` if absent. |
| `Waldo_fnc_DynamicAODestroyMinefield` | `0: AO ID` | String | `""`, rejected | Identifies the AO whose one minefield should be removed. |
| `Waldo_fnc_DynamicAODestroyMinefield` | `1: field index` | Number, zero-based whole index | `-1`, rejected | Server returns `true` for a live field removed, `false` if absent or already removed. Index 0 is the first generated field. |

Both destroy calls forward client requests and immediately return `true` there; that is a sent request, not a server success result. Their current callers are mission scripts, ZEN removal and generated deletion anchors. For creation, a non-server call also returns `true` before server work, so check the server RPT or published AO state when confirmation matters. The server validates the faction, side and bounds before it changes the world.

## Configuration reference

| Key | Type | Default | Bounds or meaning |
|---|---|---:|---|
| `id` | String | required | Stable letters/numbers/underscore/hyphen key; recreating the same id safely replaces the old AO |
| `center` | Position array `[x, y, z]` | required | ATL centre position in metres; `centre` is also accepted |
| `side` | Side | `east` | `west`, `east`, `independent` or `civilian`; must match the faction configuration |
| `faction` | String (`CfgFactionClasses` classname) | required | Runtime faction containing public assets |
| `radius` | Number (metres) | `500` | 100–2000 m |
| `patrolGroups` | Number (whole) | `3` | 0–12; four to eight infantry per group |
| `garrisonGroups` | Number (whole) | `3` | 0–30; two to four infantry per building, capped by usable buildings. With Smart AI and `Waldo_AIPass_Garrison_DynamicAO` enabled, garrisons watch outward, duck under fire and break at heavy losses |
| `staticTurrets` | Number (whole) | `0` | 0–20 manned faction static weapons |
| `vehiclePatrols` | Number (whole) | `0` | 0–10 |
| `vehicleMix` | Array of 3 numbers | `[34,33,33]` | Car/APC/tank relative weights |
| `airPatrols` | Number (whole) | `0` | 0–8 |
| `airMix` | Array of 4 numbers | `[25,25,25,25]` | Helicopter/jet/drone/plane relative weights |
| `heliPatrolRange` | Number (metres) | `1000` | 200–3000 m |
| `planePatrolRange` | Number (metres) | `2000` | 200–4000 m |
| `simplePathing` | Boolean | `false` | Two movement points plus cycle instead of four randomized points |
| `civilianFaction` | String (`CfgFactionClasses` classname) | empty | Empty disables civilian generation |
| `civilianPatrols` | Number (whole) | `0` | 0–50 individual wandering civilians |
| `civilianGarrisons` | Number (whole) | `0` | 0–50 individual building civilians |
| `civilianCars` | Number (whole) | `0` | 0–30 empty parked cars |
| `minefields` | Number (whole) | `0` | 0–15 outer-ring mine clusters |
| `showMineMarkers` | Boolean | `false` | Global red border around each field |
| `roadblocks` | Number (whole) | `0` | 0–12 manned checkpoints on roads inside the AO |
| `displayName` | String | `id` | Human-readable AO name used by the centre marker and ZEN removal list |
| `showMarker` | Boolean | script default `true`; Zeus default off | Global side-coloured border and the configured `displayName` centre marker. Enable **Show AO marker** in Zeus when the AO should be public. |

## Runtime discovery and classification

`Waldo_fnc_DynamicAOGetFactions` scans `CfgFactionClasses` and public `CfgVehicles`, then caches friendly faction choices. `Waldo_fnc_DynamicAOResolvePools` classifies the selected faction through engine inheritance:

- infantry: public `CAManBase` classes whose config `weapons[]` includes a primary weapon or launcher. If none qualify, handgun-armed classes are used and the fallback is logged. Classification uses equipment, so armed officers and pilots remain eligible. Civilian pools are unfiltered;
- cars: `Car`;
- APCs and tanks: `Tank`, split using transport capacity;
- statics: `StaticWeapon`;
- helicopters and fixed-wing aircraft: `Helicopter` and `Plane`;
- drones: any supported air asset with `isUav = 1`;
- jets: fixed-wing maximum speed at or above 600 km/h; slower assets are planes.

The pool cache is local to each machine and describes its loaded configuration. Creation resolves pools on the server. Patrol, garrison or roadblock requests require an eligible infantry pool; an empty pool rejects the request before an existing AO with the same id is removed. Set all three infantry counts to zero for vehicle, static, air, minefield or civilian-only requests that do not need enemy infantry.

Each selected class is spawned once. Dynamic AO preserves its initialization lifecycle and applies the active WMP AI profile. It does not delete units or change the cached class pool based on an immediate inventory check. Static, vehicle and air crews still use `createVehicleCrew` and keep their configured crew classes.

## Authority, JIP and cleanup

Only the server owns the full registry of objects, groups, mines and markers. Clients receive `Waldo_DynamicAO_PublicSystems`, a compact JIP-safe summary used by the remove dialog and diagnostics. Arma global markers handle their own JIP synchronization.

Every generated object is added to current curator editable objects. Whole-AO cleanup removes the registry entry first, then deletes tracked mines, field anchors, objects, units, groups and markers. This order makes deletion-event cleanup repeat-safe. Patrol generation is server-local, enables movement/pathing, leaves Arma's engine-created waypoint lifecycle intact and appends the MOVE/CYCLE route without a competing direct movement order. Infantry in a new patrol receive placement clearance around the group start instead of sharing one exact position; this prevents collision-locked squads on dedicated servers. Generated AI are passed through `Waldo_fnc_AIApplyProfile` after their final group assignment and remain eligible for the handler's new-unit and locality-change paths. The active WMP profile is therefore authoritative. A legacy scripted config may still contain `skill`; it is accepted for compatibility but ignored.

## Engine boundaries and terrain limits

The infantry filter checks config weapon slots only. It does not guarantee ammunition, a vest, a backpack or the final inventory after mod scripts run. A combat class with no config weapon and equipment supplied exclusively by a later script is excluded. A class with a config weapon can still become unarmed after spawning; that requires investigation of the selected class and its initialization.

The reported case is Spearhead 1944 US infantry with no additional AI loadout mods. The config filter and WMP integration have static coverage; verification of that faction in Arma remains pending. For a live retest, record the selected faction and unit classnames, their config weapons and inventories after initialization, and check repeat creation, cleanup, civilian generation and headless-client transfer. Include the ZEN request and JIP removal-list state.

Open terrain legitimately produces fewer garrisons, parked cars and roadblocks because those features require suitable buildings, open positions or roads. The generator caps them rather than fabricating unsuitable locations. `BIS_fnc_findSafePos` reduces overlap risk but cannot guarantee a perfect placement in extremely dense custom terrain; use cleanup and regenerate at a clearer centre if required.


## See also

- [Dynamic Anti-Air](Dynamic-Anti-Air)
- [WMP Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)
- [Waldo's AI Tuning](Waldos-AI-Tweak)
- [Mission Diagnostics](Mission-Diagnostics)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
