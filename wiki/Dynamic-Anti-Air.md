# Dynamic Anti-Air

> **Use this page when:** you need a configurable radar-controlled air-defence zone through script or Zeus.

_Associated Files: `MissionScripts/CombatSystems/DynamicAA/`; `MissionScripts/ZenModules/Zen_initModules.sqf`_

Dynamic Anti-Air creates any number of named, server-authoritative air-defence zones. Each system has a central radar: while it is alive, hostile aircraft at or above the configured altitude floor activate the otherwise dormant defences. Destroying the radar takes that system offline.

Detection remains server-owned, while AI state, target revelation and ammunition changes are dispatched to each defence group's or vehicle's current owner. Systems therefore continue to activate correctly after AI is transferred to a headless client.

Altitude mode can be `ATL`, `ASL`, or `AUTO`. Automatic mode uses height above terrain over land and height above sea level over water.

## Zeus setup

1. Place **WMP Combat Systems → Dynamic AA - Create** at the centre of the detection zone.
2. Enter a human-readable **System and marker name**, such as `Northern Air Defence`. This is independent from the generated internal cleanup ID.
3. Choose the operational side. This controls crew allegiance and hostile detection only.
4. Choose **Faction profile** for a reusable pool, or **Exact mixed equipment** for direct class selection. Physical equipment may come from any configured faction and does not change its operational side.
5. Configure detection, altitude and behaviour in the first dialog. **Map markers** controls whether markers exist. The separate, default-on **Show range and altitude limits** option controls whether their label shows detection range, floor and ceiling. Turning it off leaves only the custom system name. WMP generates the internal system ID automatically.
6. The equipment page uses the original readable class lists. Profile mode shows only the content profile and response counts. Exact mode shows radar, static-AA, mobile-AA and fighter class lists with a quantity beside each.
7. To mix more than one class in a category, enable **Add another mixed equipment set**. The same equipment page opens again; set unused categories to zero and add the additional class quantities. Finish with the option cleared.
8. Optionally enable the player radar-shutdown objective and select its procedure and difficulty in the common settings.
9. Confirm the equipment page. The dedicated server automatically places the requested radar, static-AA and mobile-AA assets in a spaced, terrain-safe layout around the module position. No additional map clicks are required.
10. Fly a crewed hostile aircraft through the zone at an eligible altitude to verify activation.

Each static site selects one configured site template. Mobile launchers and scrambled fighters are independently selected from the resolved side or faction pool, allowing repeated systems to use different valid assets. Fighters spawn outside the zone and engage the detected aircraft. Use **Dynamic AA - Remove Nearest** to remove or disable the nearest named system.

The ZEN profile selector is populated from `Waldo_DynamicAA_FactionAssetPools`. Profiles are content catalogues, not allegiance restrictions. The default choice uses the operational side's `WEST`, `EAST` or `INDEPENDENT` fallback pool. Exact selectors combine valid classes from every configured side and faction pool and show both display name and classname.

The generated system ID is an internal registry key used for replacement, cleanup and state publication; it is not an Arma object ID. Scripted setup still supplies an explicit stable ID, while the creation module hides this implementation detail.

## Scripted setup

```sqf
private _aa = createHashMapFromArray [
    ["id", "north_sector"],
    ["displayName", "Northern Air Defence"],
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
    ["showMarkerDetails", true],
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
| `displayName` | system ID | Human-readable marker and Zeus-removal name. It may contain spaces and common punctuation without changing the internal ID. |
| `centre` | required | Detection centre |
| `radarPosition` / `radarPositions` | generated | Optional authored radar position(s). When omitted, `radarCount` creates a server-generated layout around the centre. |
| `radarCount` | `1` | Number of server-placed radar objects when authored radar positions are omitted |
| `side` | `east` | `west`, `east`, or `independent` |
| `faction` | `""` | Optional content-profile key in `Waldo_DynamicAA_FactionAssetPools`; independent of `side` |
| `radius` | `2000` | Detection radius in metres |
| `minimumAltitude` | `50` | Detection altitude floor |
| `maximumAltitude` | configured pack maximum | Detection altitude ceiling |
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
| `staticSiteSpacing` | `30` | Requested minimum metres between a static-site anchor and each component. Generated layouts automatically increase it when the selected classes need more physical clearance. |
| `staticPositions` | generated | Optional authored static-site positions; when omitted, `staticCount` positions are generated on the server |
| `staticCount` | `0` | Number of automatically placed static sites when authored positions are omitted |
| `mobilePositions` | generated | Optional authored mobile-AA positions; when omitted, `mobileCount` positions are generated on the server |
| `mobileCount` | `0` | Number of automatically placed mobile systems when authored positions are omitted |
| `fighterCount` | `0` | Fighters per scramble wave |
| `fighterMaximumWaves` | `1` | Maximum waves per system; use a negative value for unlimited |
| `fighterCooldown` | `300` | Minimum seconds between fighter waves |
| `fighterSpawnRangeMultiplier` | `2` | Spawn distance as a radius multiplier |
| `initialAmmoFraction` | `1` | Starting ammunition fraction for spawned defence systems |
| `rearmOnActivation` | `false` | Restore configured ammunition when a dormant system activates |
| `detectionInterval` | `1` | Detector interval, minimum `0.25` seconds |
| `detectionFilter` | `{true}` | Optional server callback returning a Boolean for whether a candidate aircraft is detectable |
| `onStateChanged` | `{}` | Optional server callback for detected/engaged transitions |
| `createMarkers` | `true` | Create the area and centre markers. This is independent of the label-detail setting below. |
| `showMarkerDetails` | `true` | When markers exist, include detection range, floor and ceiling in the centre-marker label. Turn this off to leave only the system name without hiding the markers. |
| `cleanupOnRadarLoss` | `false` | Delete assets instead of leaving them disabled |
| `announce` | `true` | Publish detection state changes in chat |
| `shutdownInteraction` | `false` | Attach an optional player procedure to the central radar. Existing systems retain ordinary destroy-to-disable behaviour by default. |
| `shutdownChallenge` | `"circuit"` | Shared interaction procedure used for radar shutdown. Zeus offers every built-in WMP procedure plus registered custom procedures. |
| `shutdownDifficulty` | `"standard"` | Shared `easy`, `standard`, `hard` or `expert` difficulty profile. |

When the optional procedure succeeds, the server disables the named system through
`Waldo_fnc_DynamicAADestroy` without deleting its assets. Detection stops, defence groups stand down,
markers show the disabled state, and JIP clients receive the terminal interaction state. Destroying the
radar or disabling its simulation also takes it out of the operational count and follows
`cleanupOnRadarLoss`. Radar loss immediately clears assigned targets and ammunition from retained
defences, so a disabled installation cannot continue firing.

Classnames are validated before anything spawns. Generated layouts calculate conservative clearance
from each selected class with `sizeOf`, reserve the entire integrated static-site footprint rather than
only its centre, and increase internal component spacing when needed. If enough clear positions cannot
be found, creation is rejected instead of falling back to overlapping coordinates. This is sequential
server placement, not a placement race. Explicit scripted positions remain under the mission maker's control. Spawned
objects, crew, groups, markers and detector handles are retained in the server registry for
deterministic cleanup and are added to every available curator.

The dwell and clear-delay settings provide hysteresis, preventing an aircraft skimming the boundary
from rapidly toggling the network. Detection range and engagement range are separate. WMP keeps
ordinary AI auto-targeting disabled and assigns only the detector's currently eligible aircraft, so
activation cannot leak into ground targets or aircraft outside the configured altitude band. The
model deliberately does not claim perfect terrain masking: Arma's scripted visibility and sensor
state cannot reproduce every radar and datalink behaviour consistently.

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
