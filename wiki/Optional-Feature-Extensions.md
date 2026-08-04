# Optional Feature Extensions and Engine Boundaries

> **Use this page when:** you need the advanced extension points and deliberate engine boundaries of the optional systems.

_Associated Files: `init.sqf`; feature implementations under their matching `MissionScripts/` domains_

These extensions remain disabled by default, independently configurable and safe to initialise more than once. They use feature-specific settings rather than a mandatory common profile layer.

## Persistence interoperability

Registered objects can persist an allow-list of custom variables in addition to cargo, damage, fuel, ammunition and position. Pass variable names as the sixth registration option, or edit `Waldo_Persistence_DefaultCustomVariables`. Object scale, breach state and stable field-resupply state are included by default. Existing version-one object records remain loadable.

Dynamic objects are not recreated automatically. Register stable editor objects with unique keys; use mission-specific recreation logic for objects that do not exist when a save is loaded.

## Hazardous environments and contact emitters

Hazards support circles, rotated rectangles/ellipses, markers, triggers and moving object emitters. Profiles can set altitude floors/ceilings, constant or edge-falloff intensity, maximum exposure, optional WMP entry/exit cards, enter/exit callbacks and decontamination of selected exposure channels. `Waldo_Hazard_Presets` provides feature-specific presets, and `Waldo_fnc_HazardRegisterPresetZone` applies a preset with overrides. Use `Waldo_fnc_HazardRegisterEmitter` for a moving vehicle, wreck, carried device or contaminated object.

Arbitrary three-dimensional mesh volumes are not reliable in SQF; compose supported shapes or use an editor trigger. Consumable oxygen, filter durability and similar resources belong in callbacks because their inventory semantics are mission-specific.

## Tree felling

Tree felling supports protected markers/triggers, case-insensitive classname or fragment efficiency
overrides, random/original/strike fall direction, configurable resource yields and optional
session-only regrowth. Exact tool matches take priority; otherwise the longest matching fragment is
used. Terrain-object identities are not stable enough to promise restart-safe regrowth; persistence
should track authored objects or mission-level state instead.

## Emergency dismount

Allowed vehicle kinds and exact-class profiles can override the global trigger, exit, protection, recovery and damage settings. A minimum overturned duration prevents brief rolls from triggering extraction. Aircraft are excluded by default because general emergency ejection cannot be safe across every airframe; missions may explicitly opt in with a tested profile.

## Accessibility PID

The friendly aid can independently show icons and names, filter to the player's group, include/exclude incapacitated units and vehicle crew, scale its presentation and fade with distance. It remains friendly-only and line-of-sight-aware. Arma has no safe general-purpose friendly silhouette-through-walls primitive, so this feature does not simulate one.

## Explosive breaching

Explosive classes can have strengths, while each breach profile can require accumulated strength. This permits repeated small charges or one large charge. `Waldo_fnc_BreachingReset` restores hidden, non-deleted originals and removes tracked replacements. Deleted originals cannot be reconstructed safely. The feature creates replacement sections and debris; it cannot cut arbitrary directional holes into model collision geometry at runtime.

## Scaling and transforms

Helpers support reset, multiply, copy, bounded area scaling, full pitch/bank/yaw, ATL/ASL/ASLW placement and scripted spawning. Scale is uniform because `setObjectScale` has no per-axis mode. Visual and collision geometry may disagree on some assets, so unusual scales require in-game testing.

## AI rebalance

Profiles can target existing units, new units or both. Include/exclude filters cover sides, factions and classes; individual units can set `Waldo_AI_Exclude`. Bounded random variance is optional. Original named skills are captured and can be restored when the feature stops. Locality handlers reapply the profile after a unit moves to a server or headless client.

The system does not automatically alter difficulty in response to server performance or player success. Such feedback loops make results inconsistent and difficult to validate.

## Field resupply

This finite-resource ammunition feature lets a hub refill carrier crate allowances, carriers deploy charge-limited crates, players take validated magazine types, and crates be salvaged. All ACE controls sit beneath a **Field Resupply** category on the carrier, hub or deployed crate. An assigned carrier wearing a backpack receives **Check Resupply Crates** and **Deploy Field Resupply**, with scroll-wheel fallbacks only when ACE Interact is unavailable. Deployment is restricted to being on foot. A deployed crate derives logical supply rows from the carrier's compatible loaded/carried magazine classes, but its physical inventory stays empty so Gear access cannot bypass charge consumption. A WMP-blue informational addAction identifies the crate and reports its remaining charges. Server checks enforce ownership, distance, side access, stock and capacity. Focused Zeus modules register a nearby hub, assign a nearby carrier, or grant additional portable crates during play.

Mission scripts can grant crates with `[_carrier, _amount, _expandCapacity] call Waldo_fnc_FieldResupplyGrantCrates`. The default `false` expansion flag clamps the grant to the carrier's existing spare capacity; `true` raises capacity enough to fit the entire grant. The server broadcasts the updated count and informs only the receiving player. If a grant occurs during startup, its notification waits until the stock fake loading/title presentation has finished, with a 60-second safety release for missions that replace the intro without publishing completion.

Magazine allow/block lists, minimum magazine capacity, crate class, charge count, carry capacity and respawn retention are configurable. Capacity-based issue amounts default to 4 magazines for capacities up to 4 rounds, 3 up to 10, 8 up to 40, 3 up to 70 and 2 above 70; missions may replace those five amounts or select a fixed amount. Unused crates can be recovered by a carrier, while removing a partly consumed crate recovers no portable crate. It does not guess vehicle-ammunition compatibility or manufacture mod ammunition outside the configured rules.

Scripted setup is server-owned:

```sqf
if (isServer) then {
    [supplyHub, west, -1] call Waldo_fnc_FieldResupplyRegisterHub;
    [mule, 3, 3] call Waldo_fnc_FieldResupplyAssignCarrier;
};
```

## Tactical display

A registered world object provides a proximity- and line-of-sight-gated tactical map. It draws friendly units and only enemies already known to the player's group, within the configured radius. It closes when the display object is destroyed or the player leaves range. Use a map board or whiteboard-style object when the world fixture itself must visibly read as a tactical display; the full-pack audit uses a white map board rather than an infostand or data terminal.

Registration can optionally require a shared authentication procedure before the ordinary display
action becomes available. The semantic default is `commandinput / standard`; script and Zeus setup
can instead select keypad or physical lock bypass and another standard difficulty profile:

```sqf
private _interaction = createHashMapFromArray [
    ["enabled", true], ["challengeId", "commandinput"], ["difficulty", "standard"]
];
[mapBoard, west, 2000, true, _interaction] call Waldo_fnc_TacticalDisplayRegister;
```

Unlock state is server-authored and broadcast for JIP. When the option is disabled, access remains
immediate and behaves exactly as before.

Arma does not reliably project a fully interactive map control onto arbitrary object materials. The supported implementation uses the world object as the authenticated terminal and opens a normal client map display.

## Airborne gunship support

Named existing or dynamically spawned gunships use explicit controller assignment, turret profiles, combat/home orbits and configurable service policy. Side/faction aircraft pools and callbacks provide mission-specific extension without sharing Dynamic AA configuration. Focused Zeus modules cover registration, assignment, orbit placement and operational state. See [Airborne Gunship Support](Airborne-Gunship-Support).

## Deliberate exclusions

There is no broad Zeus manager for listing, editing, cloning or importing every live feature, and no mandatory standard profile framework. Focused Zeus actions exist only where runtime operation or setup is useful. Performance/economy balancing is unchanged except where required for correctness.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
