# Dynamic Anti-Air

> **Use this page when:** you need a configurable radar-controlled air-defence zone through script or Zeus.

_Associated Files: `MissionScripts/CombatSystems/DynamicAA/`; `MissionScripts/ZenModules/Zen_initModules.sqf`_

Dynamic Anti-Air creates any number of named, server-authoritative air-defence zones. Each system has
one or more required radars. While enough radars are alive, hostile crewed aircraft must pass **all**
of these gates before a defence may target it:

1. It is horizontally inside the circular detection radius shown on the map.
2. Its selected ATL/ASL altitude is at or above the floor and at or below the ceiling.
3. Its crew is hostile to the operational AA side.
4. It passes any optional mission-authored detection filter.
5. It is also inside the engagement radius before WMP supplies it to the weapons.

Ground vehicles never pass the aircraft gate. When an aircraft leaves any gate, WMP closes the
defence group, clears its assigned target, makes the group forget/ignore engine-known targets and
blocks remote datalink targets. A final owner-local fired-projectile gate uses that same server-
approved aircraft list, preventing Arma from firing at a ground, low, high or out-of-zone target
after a different eligible aircraft has activated the site. Destroying or disabling the required
radar takes the system offline.

Detection remains server-owned, while AI state, target revelation and ammunition changes are dispatched to each defence group's or vehicle's current owner. Systems therefore continue to activate correctly after AI is transferred to a headless client.

Altitude mode can be `ATL`, `ASL`, or `AUTO`. Automatic mode uses height above terrain over land and height above sea level over water.

## Beginner quick start

For the first test, place **Dynamic AA Example (Full)** on open, flat ground and do not edit its init.
It teaches the script setup and creates one radar, one integrated static site and one mobile system.
Spawn a hostile crewed aircraft above the displayed floor and inside the displayed circle. Then test
the three boundaries separately: fly below the floor, above the ceiling and outside the engagement
circle. The weapons must stand down in every case. Finally destroy the required radar; retained AA
objects must remain unable to fire.

The composition is for a pre-planned system. Use the ZEN module when Zeus needs to create or replace
a system during play. Both routes feed the same server-owned detector and enforce the same horizontal
radii and altitude limits. The ZEN route makes an explicit server-authority handoff before closing the
weapons and starting that detector; the curator player's network identity therefore cannot prevent the
initial safety gate from being installed. Do not place the composition and a ZEN system on the same
centre for one test.

## Zeus setup

1. Place **WMP AI & Combat → Dynamic AA - Create** at the centre of the detection zone.
2. Enter a human-readable **System and marker name**, such as `Northern Air Defence`. This is independent from the generated internal cleanup ID.
3. Choose the operational side. This controls crew allegiance and hostile detection only.
4. Choose **Faction profile** for a reusable pool, or **Exact mixed equipment** for direct class selection. Physical equipment may come from any configured faction and does not change its operational side.
5. Configure detection, altitude and behaviour in the first dialog. **Map markers** controls whether markers exist. The separate, default-on **Show range and altitude limits** option controls whether their label shows detection range, floor and ceiling. Turning it off leaves only the custom system name. WMP generates the internal system ID automatically.
6. The equipment page uses the original readable class lists. Profile mode shows only the content profile and response counts. Exact mode shows radar, static-AA, mobile-AA and fighter class lists with a quantity beside each.
7. To mix more than one class in a category, enable **Add another mixed equipment set**. The same equipment page opens again; set unused categories to zero and add the additional class quantities. Finish with the option cleared.
8. Optionally enable the player radar-shutdown objective and select its procedure and difficulty in the common settings.
9. Confirm the equipment page. The dedicated server automatically places the requested radar, static-AA and mobile-AA assets in a spaced, terrain-safe layout around the module position. No additional map clicks are required.
10. Fly a crewed hostile aircraft through the zone at an eligible altitude to verify activation.

The client and server RPT record the requested detection radius, engagement radius, floor, ceiling,
altitude mode and centre when Zeus confirms the module. The server then records the normalized values
used by the detector. If a test behaves differently from the dialog, compare those two lines first;
they distinguish a dialog/payload problem from an aircraft altitude or AI-locality problem.

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
| `radius` | `2000` | Horizontal detection radius in metres; altitude does not shrink this map circle |
| `minimumAltitude` | `60` | Inclusive detection/engagement altitude floor in metres |
| `maximumAltitude` | configured pack maximum | Inclusive detection/engagement altitude ceiling in metres |
| `altitudeMode` | `AUTO` | `AUTO`, `ATL`, or `ASL` |
| `engagementRadius` | detection radius | Horizontal firing radius. It is clamped to the detection radius and may be smaller. |
| `detectionDwell` | `0` | Continuous detection time before activation |
| `clearDelay` | `5` | Seconds of detection-state grace. The firing gate still closes immediately when no aircraft remains engagement-eligible. |
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
| `announce` | `true` | Send WMP detection/clear notifications to connected players on the operational AA side. No empty-audience remote call is made. |
| `shutdownInteraction` | `false` | Attach an optional player procedure to the central radar. Existing systems retain ordinary destroy-to-disable behaviour by default. |
| `shutdownChallenge` | `"circuit"` | Shared interaction procedure used for radar shutdown. Zeus offers every built-in WMP procedure plus registered custom procedures. |
| `shutdownDifficulty` | `"standard"` | Shared `easy`, `standard`, `hard` or `expert` difficulty profile. |

When the optional procedure succeeds, the server disables the named system through
`Waldo_fnc_DynamicAADestroy` without deleting its assets. Detection stops, defence groups stand down,
markers show the disabled state, and JIP clients receive the terminal interaction state. Destroying the
radar or disabling its simulation also takes it out of the operational count and follows
`cleanupOnRadarLoss`. Radar loss immediately clears assigned targets and ammunition from retained
defences, so a disabled installation cannot continue firing.

Classnames are validated before anything spawns. Creation now builds a complete two-pass asset plan:
the engine checks every selected class against existing world objects with `findEmptyPosition`, while a
separate `sizeOf`-based reservation checks it against every other planned AA component that does not yet
exist. Integrated sites are expanded into their individual radar/SAM/AAA positions before validation.
Each candidate is also rejected if it sits on terrain steeper than `Waldo_DynamicAA_MaxSlopeDegrees`
(default 12°) - the same rejection path as a nearby tree, rock or building - so a search that starts on
a hillside keeps stepping outward (up to 16 rings, roughly 35 m apart) toward an actually flat shelf
instead of leaving a radar or launcher visibly tilted. No vehicle is created until every final footprint
passes.

Per-component clearance comes from `sizeOf` - the only size query that works on a bare classname before
anything is actually spawned to measure with `boundingBoxReal` - which Bohemia's own documentation
describes as a map-icon-size approximation, not a physical footprint. Scaled and capped conservatively
(not generously) so a large icon size on an installation-style class like `Land_Radar_F` cannot demand
an unrealistically large fully-clear circle. The "anything nearby blocks placement" check also ignores
units and curator/logic objects, since a curator's own body standing at the drop point (or any
player/AI passing through later rings) is not a real obstruction. Both changes exist because the
combination previously rejected placement across an entire large search even on genuinely open,
non-manicured terrain.

If planning fails, nothing spawns; if an
unexpected materialisation failure occurs, every partial object and crew is rolled back. This is
sequential server placement, not a placement race. Explicit scripted positions are also resolved safely. Spawned
objects, crew, groups, markers and detector handles are retained in the server registry for
deterministic cleanup and are added to every available curator.

An Eden object-init call can occur while a dedicated server is still turning mission entities into
network objects. WMP queues that pre-planned creation until its server initialization sentinel is
ready, creates crew directly on the requested operational side, explicitly associates each vehicle
with that group, and waits for vehicle and crew network IDs before adding them to Zeus. A Zeus-created
system already runs after mission start, so it uses the same creator without the startup queue. Its
creation request is received from the curator, but detector startup and the initial weapon-safe state
are deliberately handed back through server owner 2. This prevents the curator's inherited
`remoteExecutedOwner` from being mistaken for an unauthorized client by the owner-local fire gate.

The dwell and clear-delay settings provide detection-state hysteresis, preventing an aircraft
skimming the boundary from rapidly toggling announcements and fighter waves. They do not grant a
weapon permission extension: firing requires an aircraft to be engagement-eligible on the current
server pass. Detection and engagement are horizontal map radii; altitude is evaluated separately.
WMP disables ordinary auto-targeting, removes remembered non-eligible targets and disables remote
target sharing on the AI-owning machine, including after headless-client migration. The model does
not claim perfect terrain masking: Arma's visibility and sensor simulation cannot reproduce every
real radar behaviour consistently.

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
