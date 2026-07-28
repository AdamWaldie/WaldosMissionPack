# Dynamic Anti-Air

> **Use this page when:** you need a configurable radar-controlled air-defence zone through script or Zeus.

_Associated Files: `MissionScripts/CombatSystems/DynamicAA/`; `MissionScripts/ZenModules/Zen_initModules.sqf`_

Dynamic Anti-Air creates any number of named, server-authoritative air-defence zones. Each system has a central radar: while it is alive, hostile aircraft at or above the configured altitude floor activate the otherwise dormant defences. Destroying the radar takes that system offline.

Detection remains server-owned, while AI state, target revelation and ammunition changes are dispatched to each defence group's or vehicle's current owner. Systems therefore continue to activate correctly after AI is transferred to a headless client.

Altitude mode can be `ATL`, `ASL`, or `AUTO`. Automatic mode uses height above terrain over land and height above sea level over water.

## Zeus setup

1. Place **Waldos Mission Modules → Dynamic AA - Create** at the centre of the detection zone.
2. Choose the system ID, faction, radius, altitude floor and response counts.
3. Select the central radar position on the map.
4. Select each requested static-site and mobile-system position.
5. Fly a hostile aircraft through the zone to verify activation.

Each static site selects one configured site template. Mobile launchers and scrambled fighters are independently selected from the resolved side or faction pool, allowing repeated systems to use different valid assets. Fighters spawn outside the zone and engage the detected aircraft. Use **Dynamic AA - Remove Nearest** to remove or disable the nearest named system.

The optional **Asset faction/pool key** selects a mission-defined entry from `Waldo_DynamicAA_FactionAssetPools`. Leaving it blank uses the selected side's `WEST`, `EAST` or `INDEPENDENT` pool.

## Scripted setup

```sqf
private _aa = createHashMapFromArray [
    ["id", "north_sector"],
    ["centre", getMarkerPos "aa_zone_north"],
    ["radarPosition", getMarkerPos "aa_radar_north"],
    ["side", east],
    ["faction", "my_opfor_faction"],
    ["radius", 2500],
    ["minimumAltitude", 80],
    ["altitudeMode", "AUTO"],
    ["staticPositions", [getMarkerPos "aa_static_1"]],
    ["mobilePositions", [getMarkerPos "aa_mobile_1"]],
    ["fighterCount", 2],
    ["createMarkers", true],
    ["cleanupOnRadarLoss", false],
    ["announce", true]
];
[_aa] call Waldo_fnc_DynamicAACreate;
```

Run scripted creation on the server. Reusing an ID safely replaces that system. Remove it with:

```sqf
["north_sector", true] call Waldo_fnc_DynamicAADestroy;
```

## Configuration keys

| Key | Default | Purpose |
|---|---:|---|
| `id` | required | Unique stable system ID |
| `centre` | required | Detection centre |
| `radarPosition` / `radarPositions` | centre | One radar position, or an array of positions for redundant radars |
| `side` | `east` | `west`, `east`, or `independent` |
| `faction` | `""` | Optional key in `Waldo_DynamicAA_FactionAssetPools`; blank uses the side pool |
| `radius` | `2000` | Detection radius in metres |
| `minimumAltitude` | `50` | Detection altitude floor |
| `maximumAltitude` | unlimited | Optional detection altitude ceiling |
| `altitudeMode` | `AUTO` | `AUTO`, `ATL`, or `ASL` |
| `engagementRadius` | detection radius | Smaller radius within which enabled defences may engage |
| `detectionDwell` | `0` | Continuous detection time before activation |
| `clearDelay` | `0` | Clear time before defences stand down |
| `requiredOperationalRadars` | `1` | Number of surviving radars required to remain online |
| `radarClasses` | side/faction pool | Candidate central-radar classes; one is selected per system |
| `staticSitePools` | side/faction pool | Candidate site templates; one template is selected independently for each static position |
| `mobileClasses` | side/faction pool | Candidate mobile-AA classes; one is selected per position |
| `fighterClasses` | side/faction pool | Candidate fighter classes; one is selected per scrambled aircraft |
| `radarClass`, `staticClasses`, `mobileClass`, `fighterClass` | unset | Backwards-compatible singular/template overrides |
| `assetPool` | unset | Per-system Dynamic AA pool overrides |
| `staticPositions` | `[]` | One centre position per static triplet |
| `mobilePositions` | `[]` | Mobile AA spawn positions |
| `fighterCount` | `0` | Fighters per scramble wave |
| `fighterMaximumWaves` | `1` | Maximum waves per system; use a negative value for unlimited |
| `fighterCooldown` | `300` | Minimum seconds between fighter waves |
| `fighterSpawnRangeMultiplier` | `2` | Spawn distance as a radius multiplier |
| `initialAmmoFraction` | `1` | Starting ammunition fraction for spawned defence systems |
| `rearmOnActivation` | `false` | Restore configured ammunition when a dormant system activates |
| `detectionInterval` | `1` | Detector interval, minimum `0.25` seconds |
| `detectionFilter` | `{}` | Optional server callback returning whether a candidate aircraft is detectable |
| `onStateChanged` | `{}` | Optional server callback for detected/engaged transitions |
| `cleanupOnRadarLoss` | `false` | Delete assets instead of leaving them disabled |
| `announce` | `true` | Publish detection state changes in chat |

Classnames are validated before anything spawns. Spawned objects, groups, markers and detector handles are retained in the server registry for deterministic cleanup.

The dwell and clear-delay settings provide hysteresis, preventing an aircraft skimming the boundary from rapidly toggling the network. Detection range and engagement range are separate. The model deliberately does not claim perfect terrain masking: Arma's scripted visibility and sensor state cannot reproduce every radar and datalink behaviour consistently.

## Side and faction asset pools

Side pools are configured server-side in `initServer.sqf` through `Waldo_DynamicAA_SideAssetPools`. A faction pool overrides only the keys it defines, falling back to its selected side for the rest:

```sqf
Waldo_DynamicAA_FactionAssetPools set ["my_opfor_faction", createHashMapFromArray [
    ["radarClasses", ["Land_Radar_F", "Land_Radar_Small_F"]],
    ["staticSitePools", [
        ["B_Radar_System_01_F", "B_SAM_System_01_F", "B_AAA_System_01_F"],
        ["B_SAM_System_02_F", "B_AAA_System_01_F"]
    ]],
    ["mobileClasses", ["O_APC_Tracked_02_AA_F", "O_T_APC_Tracked_02_AA_ghex_F"]],
    ["fighterClasses", ["O_Plane_Fighter_02_F", "O_Plane_Fighter_02_Stealth_F"]]
]];
```

Unavailable pool entries are discarded during resolution, with the selected side's vanilla assets used if an entire category becomes empty. Explicit legacy overrides remain strict and reject invalid classnames.

## See also

- [Optional Feature Systems](Optional-Feature-Systems)
- [Optional Feature Extensions](Optional-Feature-Extensions)
- [Waldos Mission Pack Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
