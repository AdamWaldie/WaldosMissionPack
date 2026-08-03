# Dynamic Anti-Air

> **Use this page when:** you need a configurable radar-controlled air-defence zone through script or Zeus.

_Associated Files: `MissionScripts/CombatSystems/DynamicAA/`; `MissionScripts/ZenModules/Zen_initModules.sqf`_

Dynamic Anti-Air creates any number of named, server-authoritative air-defence zones. Each system has a central radar: while it is alive, hostile aircraft at or above the configured altitude floor activate the otherwise dormant defences. Destroying the radar takes that system offline.

Detection remains server-owned, while AI state, target revelation and ammunition changes are dispatched to each defence group's or vehicle's current owner. Systems therefore continue to activate correctly after AI is transferred to a headless client.

Altitude mode can be `ATL`, `ASL`, or `AUTO`. Automatic mode uses height above terrain over land and height above sea level over water.

## Zeus setup

1. Place **WMP Combat Systems → Dynamic AA - Create** at the centre of the detection zone.
2. Choose the operational side. This controls crew allegiance and hostile detection only.
3. Choose **Faction profile** for a reusable pool, or **Exact mixed assets** to choose each requested asset independently. Physical equipment may come from any configured faction and does not change its operational side.
4. Configure the response counts, detection range and altitude envelope in the short first dialog. A count of zero disables that response. WMP generates the internal system ID automatically.
5. The second dialog shows only settings relevant to the chosen workflow. Profile mode shows the content profile. Exact mode asks for one class per requested slot, allowing mixed radars, static weapons, vehicles and fighters in one system. Select **Use for remaining** when the remaining slots should repeat the current class.
6. Optionally enable the player radar-shutdown objective. Its procedure and difficulty appear in a separate dialog only when enabled.
7. Select every requested radar, static-AA and mobile-AA position on the map. Fighters do not need map positions.
8. Fly a crewed hostile aircraft through the zone at an eligible altitude to verify activation.

Each static site selects one configured site template. Mobile launchers and scrambled fighters are independently selected from the resolved side or faction pool, allowing repeated systems to use different valid assets. Fighters spawn outside the zone and engage the detected aircraft. Use **Dynamic AA - Remove Nearest** to remove or disable the nearest named system.

The ZEN profile selector is populated from `Waldo_DynamicAA_FactionAssetPools`. Profiles are content catalogues, not allegiance restrictions. The default choice uses the operational side's `WEST`, `EAST` or `INDEPENDENT` fallback pool. Exact selectors combine valid classes from every configured side and faction pool and show both display name and classname.

The generated system ID is an internal registry key used for replacement, cleanup and state publication; it is not an Arma object ID. Scripted setup still supplies an explicit stable ID, while the creation module hides this implementation detail.

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
    ["announce", true],
    ["shutdownInteraction", true],
    ["shutdownChallenge", "circuit"],
    ["shutdownDifficulty", "standard"]
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
| `faction` | `""` | Optional content-profile key in `Waldo_DynamicAA_FactionAssetPools`; independent of `side` |
| `radius` | `2000` | Detection radius in metres |
| `minimumAltitude` | `50` | Detection altitude floor |
| `maximumAltitude` | unlimited | Optional detection altitude ceiling |
| `altitudeMode` | `AUTO` | `AUTO`, `ATL`, or `ASL` |
| `engagementRadius` | detection radius | Smaller radius within which enabled defences may engage |
| `detectionDwell` | `0` | Continuous detection time before activation |
| `clearDelay` | `0` | Clear time before defences stand down |
| `requiredOperationalRadars` | `1` | Number of surviving radars required to remain online |
| `maximumOperationalRadarDamage` | `0.8` | Radar damage at or above this fraction takes the whole system offline |
| `radarOperationalCondition` | `{}` | Optional server callback receiving `[radar, state, config]`; return false to model power, repairs or objective-specific disable states |
| `radarClasses` | side/faction pool | Candidate central-radar classes; one is selected per radar position |
| `staticSitePools` | side/faction pool | Candidate site templates; one template is selected independently for each static position |
| `mobileClasses` | side/faction pool | Candidate mobile-AA classes; one is selected per position |
| `fighterClasses` | side/faction pool | Candidate fighter classes; one is selected per scrambled aircraft |
| `radarAssignments`, `staticAssignments`, `mobileAssignments`, `fighterAssignments` | unset | Exact per-slot arrays used by ZEN. Lengths must match radar positions, static positions, mobile positions and fighter count. Entries may repeat or mix freely. |
| `radarClass`, `staticClass`, `mobileClass`, `fighterClass` | unset | Convenient scripted whole-system overrides; `staticClass` creates one selected weapon at each static position |
| `staticClasses` | unset | Exact integrated-site template override when one static position should create several components |
| `assetPool` | unset | Per-system Dynamic AA pool overrides |
| `staticSiteSpacing` | `30` | Metres between a static-site anchor and each spawned component; clamped to `10`–`200` to prevent radar/SAM/AAA collision starts |
| `staticPositions` | `[]` | One centre position per static triplet |
| `mobilePositions` | `[]` | Mobile AA spawn positions |
| `fighterCount` | `0` | Fighters per scramble wave |
| `fighterMaximumWaves` | `1` | Maximum waves per system; use a negative value for unlimited |
| `fighterCooldown` | `300` | Minimum seconds between fighter waves |
| `fighterSpawnRangeMultiplier` | `2` | Spawn distance as a radius multiplier |
| `initialAmmoFraction` | `1` | Starting ammunition fraction for spawned defence systems |
| `rearmOnActivation` | `false` | Restore configured ammunition when a dormant system activates |
| `detectionInterval` | `1` | Detector interval, minimum `0.25` seconds |
| `detectionFilter` | `{true}` | Optional server callback returning a Boolean for whether a candidate aircraft is detectable |
| `onStateChanged` | `{}` | Optional server callback for detected/engaged transitions |
| `cleanupOnRadarLoss` | `false` | Delete assets instead of leaving them disabled |
| `announce` | `true` | Publish detection state changes in chat |
| `shutdownInteraction` | `false` | Attach an optional player procedure to the central radar. Existing systems retain ordinary destroy-to-disable behaviour by default. |
| `shutdownChallenge` | `"circuit"` | Semantic procedure used for radar shutdown; Zeus offers circuit, wire isolation, command authentication and signal alignment. |
| `shutdownDifficulty` | `"standard"` | Shared `easy`, `standard`, `hard` or `expert` difficulty profile. |

When the optional procedure succeeds, the server disables the named system through
`Waldo_fnc_DynamicAADestroy` without deleting its assets. Detection stops, defence groups stand down,
markers show the disabled state, and JIP clients receive the terminal interaction state. Destroying the
radar remains a separate physical route and follows `cleanupOnRadarLoss`.

Classnames are validated before anything spawns. Spawned objects, groups, markers and detector handles are retained in the server registry for deterministic cleanup.

The dwell and clear-delay settings provide hysteresis, preventing an aircraft skimming the boundary from rapidly toggling the network. Detection range and engagement range are separate. The model deliberately does not claim perfect terrain masking: Arma's scripted visibility and sensor state cannot reproduce every radar and datalink behaviour consistently.

## Side and faction asset pools

Side and faction pools are shared pure data in `MissionConfig\airOperationsConfig.sqf`: the curator client reads them to build selectors, and the server independently validates them before spawning. A faction pool overrides only the keys it defines, falling back to the chosen operational side for missing categories:

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

Unavailable pool entries are discarded during resolution, with the selected side's vanilla assets used if an entire profile category becomes empty. Exact overrides remain strict and reject invalid classnames. `Land_Radar_F` and similar buildings remain uncrewed; radar vehicles and static radar weapons receive AI crew belonging to the operational side.

## See also

- [Optional Feature Systems](Optional-Feature-Systems)
- [Optional Feature Extensions](Optional-Feature-Extensions)
- [Waldos Mission Pack Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
