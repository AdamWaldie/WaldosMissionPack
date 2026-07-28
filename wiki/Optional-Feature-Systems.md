# Optional Feature Systems

> **Use this page when:** you need to enable, configure, or operate WMP's opt-in mission systems with correct locality and runtime state handling.

_Associated Files: `init.sqf`, `initPlayerLocal.sqf`, `initServer.sqf`; feature implementations under their matching `MissionScripts/` domains_

These mission-maker systems are repeat-safe, configured outside their implementation files, and provide explicit stop or cleanup functions. Shared settings live in the **Optional feature systems** block in `init.sqf`; interface-only settings live in `initPlayerLocal.sqf`; server-only limits and asset pools live in `initServer.sqf`. Most are disabled by default. The accessibility aid is enabled only for its original allowlisted recipient.

The server owns mutable mission state, registries, persistence I/O and world changes. Player machines own actions, displays and local event listeners. AI rebalance and explosive breaching deliberately initialise on every machine because AI and relevant events can be local to the server, a player client or a headless client. Runtime ZEN changes publish public state and send one ordered setting bundle before the matching initializer. Joining machines request an authoritative server snapshot before locality-sensitive activation, and keyed JIP entries replay or clear initializers as required. Snapshot requests validate the current player or headless-client owner and retry for 30 seconds; if authority never becomes available, optional runtime features fail closed on that machine instead of starting from local defaults. Guarded defaults therefore cannot replace live mid-mission settings during join.

## Runtime Zeus controls

When Zeus Enhanced is loaded, **Waldos Mission Modules** includes focused runtime controls for persistence, treatment feedback, persistent-object registration, hazardous-zone creation/removal, tree felling, emergency dismount, accessibility PID, breaching profiles, airborne gunships and AI rebalance. These modules validate the assigned curator on the server and remove the need to pre-plan the feature in Eden. Hazard and breaching dialogs can also copy equivalent setup calls to the curator's clipboard for permanent configuration later.

## Persistence

Set `Waldo_Persistence_Enable = true`. The server then looks for an available INIDBI2 runtime and disables persistence cleanly if none can be initialised. Database access remains server-only.

Zeus can use **Persistence - Control** to start, reconfigure or stop the system, and **Persistence - Register Object** near an object to assign its stable key and saved fields during play. **Persistence - Save Now** requests an immediate state capture from connected players and writes selected registered objects without stopping persistence. It reports cleanly when the required runtime is not active.

Player persistence can independently save loadout, ACE medical state, food/water, position and supported radio state. Loadout and medical state are enabled by default; the more mission-sensitive fields are not. Tune the shared `Waldo_Persistence_*` values in `init.sqf`. The server starts the database branch from `initServer.sqf`; each player starts only capture/apply work from `initPlayerLocal.sqf`.

Register an editor object from `initServer.sqf` or its init field:

```sqf
[supplyCrate, "base_supply_1", [true, false, false, false, false]] call Waldo_fnc_PersistenceRegisterObject;
```

The five booleans control cargo, damage, fuel, ammunition/pylons and position. Keys must be stable and unique. Registrations made while the database starts are queued. Call `Waldo_fnc_PersistenceStop` to save registered objects and stop the system without deleting its database.

## Patient treatment feedback

Set `Waldo_TreatmentFeedback_Enable = true` to display ACE treatment start, completion and interruption events through the pack notification UI. ACE emits these events locally to the treating unit, so the feature securely forwards patient feedback to the patient's owning machine. Self-treatment remains local.

Start, success and failure notifications can be enabled independently. Patient notification is enabled by default; optional medic feedback, medic names and body-region labels can be selected separately. Titles, body-region names and treatment-class display-name overrides are configured through the player-local `Waldo_TreatmentFeedback_*` values in `initPlayerLocal.sqf`; colours follow the standard WMP semantic states.

**Treatment Feedback - Control** applies the simple global switches during play. Call `Waldo_fnc_TreatmentFeedbackStop` to remove the event handlers. The ACE event identifier `ace_treatmentSucceded` is intentionally retained exactly as defined.

## Hazardous environments

Set `Waldo_Hazard_Enable = true`, then register any number of zones. A zone accepts a trigger, marker name, or `[position, radius]`, plus an extensible profile hash map.

**Hazard - Create** builds a circular zone at the module position with configurable exposure, recovery, damage, vehicle/interior protection and protective equipment. **Hazard - Remove Nearest** removes the nearest registered zone. Scripted profiles remain available for multiple damage tiers and custom callbacks.

```sqf
private _profile = createHashMapFromArray [
    ["type", "NO_OXYGEN"],
    ["label", "Unpressurised Area"],
    ["rate", 8],
    ["decay", 2],
    ["protectInVehicles", true],
    ["vehicleFactor", 0],
    ["protectiveItems", createHashMapFromArray [
        ["headgear", ["H_PilotHelmetFighter_B"]]
    ]],
    ["damageThresholds", [[30, 0.01], [60, 0.04]]]
];
["hangar_vacuum", "vacuum_zone", _profile] call Waldo_fnc_HazardRegisterZone;
```

Profiles can represent contamination, toxic gas, extreme temperature, vacuum or custom hazards. Protection can come from equipment, vehicles or interiors; `onTick` provides a custom callback. Unregister with `Waldo_fnc_HazardUnregisterZone`, or stop all local evaluation with `Waldo_fnc_HazardStop`.

## Tree felling

Set `Waldo_TreeFelling_Enable = true`. Players receive a contextual **Fell Tree / Clear Brush** action when an allowed axe/hatchet pattern is equipped. Repeated validated swings fell trees on the server; optional brush clearing removes nearby bushes. Fallen assets can be configured globally or as small, medium and large height tiers. The system also chains an existing melee swing callback when present.

Tune range, weapon-name patterns, hit scaling, cooldown, brush radius, size thresholds, fall direction and replacement classes with `Waldo_TreeFelling_*`, or use **Tree Felling - Control** during play. Stop locally with `Waldo_fnc_TreeFellingStop`.

## Emergency dismount

Set `Waldo_EmergencyDismount_Enable = true`. The local occupant monitor can extract a player from an overturned or destroyed land vehicle or boat, choose a clear nearby position, optionally preserve velocity and provide a short configurable damage-protection window.

Use the `Waldo_EmergencyDismount_*` settings or **Emergency Dismount - Control** to select overturn/destruction triggers, normal exit versus eject, clear-exit geometry checks, momentum preservation, safe-position radius, bounded damage protection and unconscious recovery. Stop with `Waldo_fnc_EmergencyDismountStop`.

## Friendly identification accessibility aid

The aid is enabled by default for its original intended recipient (`76561198094931408`) through `Waldo_AccessibilityPID_AllowedUIDs` in `initPlayerLocal.sqf`. Other players do not install the overlay. Add further UIDs as needed, set the array to `[]` to permit everyone, or set `Waldo_AccessibilityPID_Enable = false` to disable it entirely. Eligible players receive a line-of-sight-aware friendly marker with separate icon and name ranges.

The aid is presentation-only and does not alter side relations or reveal enemies. Players can toggle it when `Waldo_AccessibilityPID_AllowToggle` is enabled. Use `Waldo_fnc_AccessibilityPIDToggle` from another UI if desired, and `Waldo_fnc_AccessibilityPIDStop` for cleanup.

**Accessibility PID - Control** can enable or disable the aid and change icon/name ranges, line-of-sight policy, AI inclusion and player toggling during play. `Waldo_AccessibilityPID_AllowedUIDs` remains available for pre-planned per-player eligibility.

## Explosive wall breaching

Breaching requires ACE explosives and remains inactive unless `Waldo_Breaching_Enable` is true. Define an explicit profile for each breachable object class; an empty profile map breaches nothing.

```sqf
Waldo_Breaching_Profiles set ["Land_City2_8m_F", createHashMapFromArray [
    ["radius", 5],
    ["explosives", ["DemoCharge_Remote_Ammo"]],
    ["destroyOriginal", true],
    ["hideOriginal", true],
    ["replacements", [
        ["Land_City2_4m_F", [-2, 0, 0], 0, "CAN_COLLIDE"],
        ["Land_City2_4m_F", [2, 0, 0], 0, "CAN_COLLIDE"]
    ]]
]];
```

The server validates the detonation, applies each target once, and can spawn replacements relative to the original wall. Profiles also support `deleteOriginal` and an `onBreach` callback. Stop with `Waldo_fnc_BreachingStop`.

Replacement specifications support model-relative offsets, yaw or full `[pitch, bank, yaw]` rotation, collision placement mode, `ATL`/`ASL`/`ASLW` positioning and scale. **Breaching - Configure Class** can add, update, remove and export a simple profile from an object selected during play; complex debris layouts remain scripted.

## Object scaling

Scale one object on the server:

```sqf
[statue, 1.75, false] call Waldo_fnc_ObjectScale;
```

The third argument optionally converts the result to a simple object. Limits default to `0.1`–`10` and are server-owned in `initServer.sqf`. Remote requests are curator-only unless explicitly relaxed. For batches, tag objects with `Waldo_ObjectScale` and call `Waldo_fnc_ObjectScaleTagged`. Zeus can place **Scale Object** near a target and choose the value in a dialog.

## See also

- [Vehicle Recovery and Squad Rally Points](Vehicle-Recovery-And-Squad-Rallies)
- [Airborne Gunship Support](Airborne-Gunship-Support)
- [Optional Feature Extensions](Optional-Feature-Extensions)
- [Dynamic Anti-Air](Dynamic-Anti-Air)
- [Waldos AI Rebalance](Waldos-AI-Tweak)
- [Mission Configuration Reference](Mission-Configuration-Reference)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
