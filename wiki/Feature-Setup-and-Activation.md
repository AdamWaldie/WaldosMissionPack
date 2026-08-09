# Feature Setup and Activation

> **Use this page when:** you know which WMP feature you want, but need to know whether editing its
> config is enough, which values are ordinary mission choices, and where any setup call belongs.

WMP separates **settings**, **lifecycle**, and **feature instances**:

1. A file under MissionConfig supplies guarded defaults.
2. WMP's init files load those defaults on the machines that need them.
3. Automatic features start themselves.
4. Object, zone, and spawned-system features still need an instance registered or created.

Do not assume that an Enable switch spawns an object. It may only permit a feature or start its
evaluator.

## The four setup patterns

| Pattern | Meaning | Example |
|---|---|---|
| Automatic | Enable/configure it and WMP starts it | AI rebalance, rally, WMP HUD |
| Enable + register | WMP starts support, but needs a world object/zone/unit | jammer, hazards, field resupply |
| Call-driven | Config supplies pools/defaults/bounds; a call creates each instance | Dynamic AA, paradrop, gunship |
| Consumed setting | Another existing feature reads the value | logistics crate class, UI placement |

## Where custom calls belong

### initServer.sqf - normal place for pre-planned world setup

Use this for named registries, zones, spawned systems and authoritative objects:

    [recoveryWorkshop, "FOB_ALPHA", 50, west] call Waldo_fnc_RecoveryRegisterWorkshop;
    [recoveryTruck, 10, "AUTO", 2] call Waldo_fnc_RecoveryRegisterCarrier;

initServer.sqf runs once on the server. Public functions publish state/actions for current players
and JIP where required. An additional `if (isServer)` wrapper inside initServer.sqf is redundant and
makes a beginner's setup harder to read. Do not copy the same block into init.sqf.

### Editor object init - only where the API explicitly supports it

Object init is convenient for a function designed to receive this and route/reject duplicate work:

    [this] call Waldo_fnc_Jammer;
    [this, 10, "AUTO", 2] call Waldo_fnc_RecoveryRegisterCarrier;

Follow the function header or feature page. Do not infer that every public function belongs in an
object init.

### initPlayerLocal.sqf - custom per-player interface work only

Use this only when your own mission code must run separately for each human player's local
interface/player object. Do not create Dynamic AA, recovery workshops, hazards or shared world
state here. WMP already starts automatic local UI/accessibility handlers; do not call them twice.

### init.sqf - not a general setup bucket

init.sqf runs on the server, headless clients and clients. WMP uses it for deliberately all-machine
lifecycle. Do not put authoritative world creation, mutable public defaults or per-player UI setup
here. A JIP machine executing it later must not replace current server state.

### Triggers, scripts and ZEN

For runtime creation, run the trigger/script on the server or use a public API documented to route
to it. ZEN is the live curator path where a module exists. Runtime state remains authoritative and
is replayed to JIP by the feature.

## Setup matrix

| Feature | Settings file | Config action | Instance/setup action |
|---|---|---|---|
| ACRE2 + Babel | acreConfig.sqf | Enable and author nets/groups/languages | None |
| AI rebalance | aiConfig.sqf | Enable, profile, mode, filters | None |
| Improved helicopter landing | aiConfig.sqf | Enable | Give AI a supported landing waypoint |
| Gunship | airOperationsConfig.sqf | Enable, pools, service policy | Register/spawn by call or ZEN |
| Paradrop | airOperationsConfig.sqf | Aircraft/chute/boarding pools and envelopes | Create drop zone by call or ZEN |
| Dynamic AA | airOperationsConfig.sqf | Side/faction pools and safety maxima | Create named system by call or ZEN |
| Jammer | electronicWarfareConfig.sqf | Enable and gameplay policy | Register/create jammer or use ZEN |
| EMP / tracker | electronicWarfareConfig.sqf | Shared EW policy where applicable | Invoke on demand |
| Hazard | environmentConfig.sqf | Enable and define presets | Register zone/emitter or use ZEN |
| Tree felling | environmentConfig.sqf | Enable, tools/classes/protection | None |
| Breaching | environmentConfig.sqf | Enable and define profiles/strengths | None; only matching objects react |
| UI theme/notifications | interfaceConfig.sqf | Theme and routing | None |
| Treatment / dismount / PID | interfaceConfig.sqf | Enable and policy | None |
| Tactical display | interfaceConfig.sqf | Access/knowledge defaults | Register compatible object or use ZEN |
| Field resupply | logisticsConfig.sqf | Content and balance | Register hub and assign carriers |
| Vehicle recovery | logisticsConfig.sqf | Packages/markers/safety | Register workshop, vehicles, carriers |
| Object scaling | logisticsConfig.sqf | Min/max/authority bounds | Scale by call or ZEN |
| Rally / minigames / corpse traps | missionSystemsConfig.sqf | Enable and policy | None |
| Economy | missionSystemsConfig.sqf plus economy config | Enable runtime | Configure economy preset/catalogues |
| Diagnostics / safestart | missionSystemsConfig.sqf | Safestart starts inactive; review server policy | Use WMP Mission Flow Zeus controls when needed |
| Persistence | persistenceConfig.sqf | Enable/save policy/database | Install INIDBI2; register world objects |

## Config-by-config recipes

### acreConfig.sqf

**Normally edit:** enabled, PRC-343 policy, named displays, side nets, group mappings, explicit
same-type radio assignments, player/role overrides and Babel.

**Normally leave:** strict validation and advanced third-party
profile extensions. Built-in capability profiles are code-owned. No init call is needed.

Explicit entries support multiple same-type radios and independent ears:

    ["ACRE_PRC343", 1, [5, 16], "LEFT"]
    ["ACRE_PRC343", 2, [6, 3], "RIGHT"]
    ["ACRE_PRC152", 1, "PLT1", "RIGHT"]

Occurrence is 1-based among radios of the same base type. Explicit rows are optional templates and
are skipped when that occurrence is absent. Each radio independently uses a compatible net; extra,
captured and unsupported radios remain untouched. WMP does not change alternate PTT defaults.

### aiConfig.sqf

**Normally edit:** enable switches, AI profile/mode/application population and filters.

**Normally leave:** variance/restoration and helicopter control geometry/rates/timers. No call is
required. Improved landing still requires a LAND, UNLOAD, TRANSPORT UNLOAD or GET OUT waypoint.

### airOperationsConfig.sqf

**Normally edit:** gunship enablement/pools, paradrop content, AA assets and jump envelopes.

**Normally leave:** monitor cadence, service thresholds and server maximum bounds. Nothing is
spawned by this file. Example pre-planned Dynamic AA:

    private _aa = createHashMapFromArray [
        ["id", "AA_NORTH"],
        ["centre", getMarkerPos "aa_north"],
        ["radarPosition", getMarkerPos "aa_north_radar"],
        ["side", east],
        ["radius", 2500],
        ["engagementRadius", 2000],
        ["minimumAltitude", 80],
        ["maximumAltitude", 3000]
    ];
    [_aa] call Waldo_fnc_DynamicAACreate;

Example paradrop:

    private _drop = createHashMapFromArray [
        ["id", "DZ_ALPHA"],
        ["name", "DZ ALPHA"],
        ["centre", getMarkerPos "dz_alpha"],
        ["side", west],
        ["aircraftClass", "B_T_VTOL_01_infantry_F"],
        ["altitude", 300],
        ["maximumSpeed", 300]
    ];
    [_drop] call Waldo_fnc_ParadropCreateDropZone;

Gunship registration accepts one HashMap and a safe unique id. See
[Airborne Gunship Support](Airborne-Gunship-Support) for the full orbit/service schema.

### electronicWarfareConfig.sqf

**Normally edit:** enablement, player feedback, LOS/burn-through/destruction/toggle rules and the
optional disable challenge.

**Normally leave:** attenuation/RDF math and GM diagnostics. The master switch creates no jammer:

    [this, 500, "EAST"] call Waldo_fnc_Jammer;
    [getPosATL empTarget, 200, 30] call Waldo_fnc_EMP;
    [this] call Waldo_fnc_EMPImmune;
    [enemyTruck, west, "Convoy Lead"] call Waldo_fnc_Tracker;

### environmentConfig.sqf

**Normally edit:** switches, hazard presets, tools/content, tree protection and breach profiles.

**Normally leave:** tick/cooldown/scheduler and geometry tolerances. Hazard evaluation alone causes
no exposure. Register a pre-planned marker/trigger/area on the server:

    private _profile = (missionNamespace getVariable ["Waldo_Hazard_Presets", createHashMap])
        getOrDefault ["SEVERE_RADIATION", createHashMap];
    ["reactor", "reactor_zone", _profile] call Waldo_fnc_HazardRegisterZone;
    ["leaking_truck", leakingTruck, 8, _profile] call Waldo_fnc_HazardRegisterEmitter;

Tree felling and breaching initialise automatically, but each still needs usable content. Arma has
no vanilla axe: the player's equipped weapon classname must contain one of the configured tree-tool
patterns. For a first breaching test, place the vanilla `Land_City2_8m_F` wall, change only
`Waldo_Breaching_Enable` to `true`, and detonate an ACE demo charge within 5 m. The shipped profile
already handles that exact wall; no other object class becomes breachable. Neither feature has a
ZEN setup module. The full setting-by-setting examples are in
[Optional Feature Systems](Optional-Feature-Systems#tree-felling).

### interfaceConfig.sqf

**Normally edit:** theme, notification routing, treatment, emergency dismount and PID policy.

**Normally leave:** queue/reflow internals, knowledge bounds, safety geometry and Draw3D fine tuning.
Local systems start automatically. Tactical display is the exception:

    [mapBoard, west, 2000, true] call Waldo_fnc_TacticalDisplayRegister;

Use a whiteboard/map board or suitable terminal. It opens a local tactical map; it does not paint a
texture on an arbitrary infostand.

### logisticsConfig.sqf

**Normally edit:** resupply content, recovery packages/markers, scale bounds and crate classes.

**Normally leave:** scan cadence, placement geometry, client scale authority and dependency
fallbacks. Example setup:

    [supplyHub, west, -1] call Waldo_fnc_FieldResupplyRegisterHub;
    [squadLeader, 1, 2] call Waldo_fnc_FieldResupplyAssignCarrier;
    [repairDepot, "FOB_ALPHA", 50, west, 100, true] call Waldo_fnc_RecoveryRegisterWorkshop;
    [damagedTruck, "FOB_ALPHA", 0.55, true, true] call Waldo_fnc_RecoveryRegisterVehicle;
    [recoveryTruck, 10, "AUTO", 2] call Waldo_fnc_RecoveryRegisterCarrier;
    [statue, 1.75, true] call Waldo_fnc_ObjectScale;

### missionSystemsConfig.sqf

**Normally edit:** rally rules, optional system switches, diagnostics and safestart.

**Normally leave:** rally safe-position search and global ACE handling values. These start through
the existing lifecycle. Economy enablement starts runtime support, but resources/catalogues still
come from [Economy Setup and Configuration](Waldos-Economy-Systems-Setup-And-Configuration).

### persistenceConfig.sqf

**Normally edit:** enablement, Save choices and database name.

**Normally leave:** intervals and the custom-variable allowlist. WMP starts persistence, but only a
working server-side INIDBI2 extension passes the dependency gate. Register world objects on server:

    [supplyCrate, "base_supply_1", [true, false, false, false, false]]
        call Waldo_fnc_PersistenceRegisterObject;

The five Booleans select cargo, damage, fuel, ammo/pylons and position. Player state needs no
registration.

## Live changes, authority and JIP

- Edit config for mission-start policy; use runtime calls/Zen for mid-mission changes.
- Server-owned state must be changed and published by the server.
- Do not broadcast the same default from every JIP client's init.sqf.
- Player-local presentation consumes current published state when joining.
- Stable IDs/keys identify a logical system; reuse may replace/update instead of duplicate.
- Never add publicVariable, remote execution, handlers or waits to a config file.

## Related pages

- [Feature Configuration Files](Feature-Configuration-Files) - every setting and unit
- [Mission Configuration Reference](Mission-Configuration-Reference) - entry-file ownership
- [Zeus and Script API Parity](Zeus-And-Script-API-Parity) - modules and calls
- [Mission Diagnostics](Mission-Diagnostics) - checking the resulting setup

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
