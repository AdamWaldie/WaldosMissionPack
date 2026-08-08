# Optional Feature Systems

> **Use this page when:** you need to enable, configure, or operate WMP's opt-in mission systems with correct locality and runtime state handling.

_Associated Files: `MissionConfig/`, `init.sqf`, `initPlayerLocal.sqf`, `initServer.sqf`; feature implementations under their matching `MissionScripts/` domains_

These mission-maker systems are repeat-safe, configured outside their implementation files, and provide explicit stop or cleanup functions. Semantic pure-data settings live under `MissionConfig`; [Feature Configuration Files](Feature-Configuration-Files) lists every setting and scope. The init files retain activation and locality handling. Most systems are disabled by default. The accessibility aid is enabled only for its original allowlisted recipient.

The server owns mutable mission state, registries, persistence I/O and world changes. Player machines own actions, displays and local event listeners. AI rebalance and explosive breaching deliberately initialise on every machine because AI and relevant events can be local to the server, a player client or a headless client. Runtime ZEN changes publish public state and send one ordered setting bundle before the matching initializer. Joining machines request an authoritative server snapshot before locality-sensitive activation, and keyed JIP entries replay or clear initializers as required. Snapshot requests validate the current player or headless-client owner and retry for 30 seconds; if authority never becomes available, optional runtime features fail closed on that machine instead of starting from local defaults. Guarded defaults therefore cannot replace live mid-mission settings during join.

## Runtime Zeus controls

When Zeus Enhanced is loaded, the categorized WMP palette includes focused runtime controls for persistence, persistent-object registration, hazardous-zone creation/removal, transport services, airborne gunships and AI rebalance. These modules validate the assigned curator on the server and remove the need to pre-plan those features in Eden. Hazard dialogs can also copy equivalent setup calls to the curator's clipboard for permanent configuration later. Treatment feedback, tree felling, WMP HUD, emergency dismount and breaching remain script-configured and intentionally have no ZEN modules.

## Persistence

Save/restore player state (and specific registered world objects) across a database, backed by the INIDBI2 extension. Quickest working setup:

1. Install the INIDBI2 extension on the **server** (not required on clients) — see its own release for that step; WMP does not bundle it.
2. Open `MissionConfig\persistenceConfig.sqf` and set `Waldo_Persistence_Enable` to `true`.
3. Launch the mission on a server that has INIDBI2 installed. The server probes for a real, loaded extension (not just a declared dependency) and disables itself cleanly if the probe fails — check the RPT for `[WMP DIAG]` persistence lines if nothing is saving.
4. Play, disconnect and reconnect (or use `Waldo_fnc_PersistenceStop` then restart the mission) to confirm loadout/medical state is restored.

Database access remains server-only; clients only capture/apply their own state.

| Setting | Default | Purpose |
|---|---|---|
| `Waldo_Persistence_Enable` | `false` | Master opt-in; requires a working server INIDBI2 extension |
| `Waldo_Persistence_SaveLoadout` | `true` | Filtered inventory (unique ACRE radio IDs stripped) |
| `Waldo_Persistence_SaveMedical` | `true` | ACE medical state |
| `Waldo_Persistence_SaveFoodWater` | `false` | Hunger/thirst state |
| `Waldo_Persistence_SavePosition` | `false` | Off by default — can bypass mission flow (e.g. skip an intro area) |
| `Waldo_Persistence_SaveRadios` | `false` | Per-player ACRE channel/spatial state |
| `Waldo_Persistence_Scope` | `"MISSION"` | `"MISSION"` isolates records by mission+terrain; `"CAMPAIGN"` shares by database name across missions |
| `Waldo_Persistence_DatabaseName` | `"WaldosMissionPack"` | Database identity; only matters when `Scope` is `"CAMPAIGN"` |
| `Waldo_Persistence_DefaultCustomVariables` | `[]` | Extra variable names saved alongside the built-in fields — see [Optional Feature Extensions](Optional-Feature-Extensions) |

Zeus can use **Persistence - Control** to start, reconfigure or stop the system, and **Persistence - Register Object** near an object to assign its stable key and saved fields during play. **Persistence - Save Now** requests an immediate state capture from connected players and writes selected registered objects without stopping persistence. It reports cleanly when the required runtime is not active.

Player persistence can independently save loadout, ACE medical state, food/water, position and supported radio state. Loadout and medical state are enabled by default; the more mission-sensitive fields are not. Tune the shared `Waldo_Persistence_*` values in `MissionConfig\persistenceConfig.sqf`. The server starts the database branch from `initServer.sqf`; each player starts only capture/apply work from `initPlayerLocal.sqf`.

Player records are separated by Steam UID and, by default, database name + mission name + terrain.
Keep `Waldo_Persistence_Scope = "MISSION"` for ordinary missions. Use `"CAMPAIGN"` only when
several missions using the same `Waldo_Persistence_DatabaseName` intentionally share progress. The
server validates the identity stored inside a record before sending it to a client.

ACRE-aware persistence filters unique `_ID_n` radio classes before storage. When `Waldo_Persistence_SaveRadios` is enabled, channel and spatial state are stored separately by base radio class and same-type ordinal. A restore creates fresh unique radios first and then reapplies persisted state; when disabled, the current side/group mission plan is applied instead. ACRE being absent leaves ordinary loadouts unchanged.

Register an editor object from `initServer.sqf` or its init field:

```sqf
[supplyCrate, "base_supply_1", [true, false, false, false, false]] call Waldo_fnc_PersistenceRegisterObject;
```

The five booleans control cargo, damage, fuel, ammunition/pylons and position. Keys must be stable and unique. Registrations made while the database starts are queued. Call `Waldo_fnc_PersistenceStop` to save registered objects and stop the system without deleting its database.

## Patient treatment feedback

Requires ACE Medical. Quickest working setup:

1. Open `MissionConfig\interfaceConfig.sqf` and set `Waldo_TreatmentFeedback_Enable` to `true`.
2. Have one player treat another (e.g. bandage a wound) with ACE Medical.
3. The patient sees a WMP notification card at treatment start, completion and interruption — not the medic, since this is patient-facing feedback. ACE emits these events locally to the treating unit, so the feature securely forwards them to the patient's owning machine. Self-treatment remains local.

Start, success and failure notifications can be enabled independently. Patient notification is enabled by default; optional medic feedback, medic names and body-region labels can be selected separately. Treatment cards replace one another in a dedicated padded bottom-centre region, so they do not consume the general notification stacks; `Waldo_TreatmentFeedback_Duration` controls their short post-event lifetime and defaults to three seconds. Titles, body-region names and treatment-class display-name overrides are configured through the player-local `Waldo_TreatmentFeedback_*` values in `MissionConfig\interfaceConfig.sqf`; colours follow the standard WMP semantic states.

Call `Waldo_fnc_TreatmentFeedbackInit` or `Waldo_fnc_TreatmentFeedbackStop` on interface clients after changing the player-local settings. This feature intentionally has no ZEN module. The ACE event identifier `ace_treatmentSucceded` is intentionally retained exactly as defined.

## Hazardous environments

Repeatable exposure zones (radiation is the shipped preset family) with real damage, protection and a HUD. Quickest working setup, using a shipped preset — no profile authoring needed:

1. Open `MissionConfig\environmentConfig.sqf` and set `Waldo_Hazard_Enable` to `true`.
2. Place a trigger or marker in Eden marking the danger area, e.g. name a marker `reactor_zone`.
3. In `initServer.sqf`, register it against a shipped preset with one call:
   ```sqf
   ["reactor_leak", "reactor_zone", "MODERATE_RADIATION"] call Waldo_fnc_HazardRegisterPresetZone;
   // [key, area, presetKey] - LOW_RADIATION / MODERATE_RADIATION / SEVERE_RADIATION are ready to use
   ```
4. Walk into the marked area. A continuous lower-left exposure panel appears, followed by damage once exposure crosses a threshold.

For a custom (non-preset) profile, or to override specific preset fields, see the manual `Waldo_fnc_HazardRegisterZone` call and key table below. Set `Waldo_Hazard_Enable = true`, then register any number of zones from `initServer.sqf`. A zone accepts a trigger, marker name, moving object emitter, `[position, radius]`, or `[position, axisA, axisB, angle, rectangle]`, plus an extensible profile hash map. The server publishes enablement and the complete registry as one ordered snapshot, so connected players and JIP clients start against the same state. Do not register shared zones separately on every client.

**Hazard - Create** builds a circular zone at the module position. After choosing a mission preset, the curator can give it a custom RP-facing name and entry/exit wording, choose linear or constant intensity, and configure range, exposure/recovery, exposure cap, damage, fatal threshold, vehicle/interior protection and entry/exit notifications. A zero damage value and zero fatal threshold produce a non-injuring roleplay zone; non-zero values create real ACE wounds (or vanilla damage without ACE). **Hazard - Remove Nearest** removes the nearest registered zone. Scripted profiles remain available for multiple damage tiers, custom protective-equipment rules and callbacks.

`Waldo_Hazard_NotifyTransitions` enables player-local WMP notification cards on zone entry and exit and defaults to `true`; `Waldo_Hazard_NotificationDuration` defaults to six seconds. Live exposure defaults on (`Waldo_Hazard_ShowStatus = true`) and appears in one continuously updated lower-left specialist panel. It never creates repeated cards or consumes notification lanes. The Electronic Warfare panel remains lower-right; both register with WMP's global UI reservations, so they can be visible together and ordinary notification stacks reflow around them. A profile may override `showStatus`, transition wording and duration.

Hazard information can be conditional. `detectorItems` requires at least one listed carried, worn or assigned classname. `detectorObjects` plus `detectorObjectRange` requires a nearby detector object. Advanced missions may set `awarenessCondition` to CODE locally or a missionNamespace function-name string for JIP-safe profiles. When any detector/condition is configured, both continuous status and transition/damage notices require awareness by default. Set `requireAwarenessForStatus` or `requireAwarenessForNotifications` to `false` to exempt that UI. These settings never provide protection: an unaware player still accumulates exposure and takes configured damage.

The shipped `LOW_RADIATION`, `MODERATE_RADIATION` and `SEVERE_RADIATION` presets are ready-to-use ionising-radiation examples. All three use the packaged Geiger and injury-cough audio; their dose rate, recovery, shielding factors, injury thresholds, fatal dose and audio cadence increase by severity. `audioEnabled`, `audioRequiresAwareness`, `geigerLowSounds`, `geigerHighSounds`, `geigerMinimumInterval`, `geigerMaximumInterval`, `coughSounds` and `coughCooldown` control that local feedback. Intensity shortens the Geiger interval and chooses the low/high pool; coughing occurs only after actual configured damage. Audio timers are local and keyed per zone, so they create no recurring network traffic. Custom profiles may still represent toxins, heat, vacuum or other roleplay hazards, but those are no longer misleadingly presented as ready-made defaults.

With ACE Interact, **Hazard Equipment** self/other actions can read current exposure and apply configured treatment items. `Waldo_Hazard_DosimeterItems` controls who may read exposure, while `Waldo_Hazard_Treatments` contains `[consumed item classname, readable name, exposure reduction]` rows and `Waldo_Hazard_TreatmentDuration` controls progress time. Treatment removes the carried item on the giver's machine and reduces exposure only on the patient-owning machine. Leave either list empty to disable that part without disabling hazards.

```sqf
private _profile = (missionNamespace getVariable ["Waldo_Hazard_Presets", createHashMap])
    getOrDefault ["MODERATE_RADIATION", createHashMap];
["reactor_leak", "reactor_zone", _profile] call Waldo_fnc_HazardRegisterZone;
```

Profiles can represent contamination, toxic gas, extreme temperature, vacuum or custom hazards. `damageThresholds` are ordered `[exposure, damage-per-evaluator-tick]` tiers; `fatalExposure` forces death at the configured exposure, or `-1` disables it. Crossing a new damaging tier produces one WMP warning by default; override `notifyDamageStages`, `damageMessage` or `damageStageMessages` for the scenario. Protection can come from equipment, vehicles or interiors. For dedicated-safe `onEnter`, `onExit` or `onTick` behaviour, store the callback function in `missionNamespace` and put its function-name string in the profile; raw CODE callbacks are intentionally not transmitted as JIP state. For a moving source, use `[_key, _object, _radius, _profile] call Waldo_fnc_HazardRegisterEmitter`. Unregister on the server with `Waldo_fnc_HazardUnregisterZone`, or stop only the current client's evaluation with `Waldo_fnc_HazardStop`.

### Profile key quick reference

The most commonly-tuned keys of a hazard profile hash map — a preset already sets sensible values for all of these, this table is for building a custom profile or overriding a preset:

| Key | Default | Purpose |
|---|---|---|
| `label` | `""` | RP-facing name shown in entry/exit cards and the status panel |
| `intensityMode` | `"LINEAR"` | `LINEAR` fades toward the edge; `CONSTANT` is full intensity everywhere inside the zone |
| `rate` | `1` | Exposure gained per second while inside, at full intensity |
| `decay` | `0.1` | Exposure lost per second while outside the zone |
| `decontaminationRate` | `1` | Exposure lost per second while protected/decontaminating inside the zone |
| `maximumExposure` | `1e10` (effectively uncapped) | Hard cap on accumulated exposure |
| `damageThresholds` | `[]` | Ordered `[exposure, damage-per-tick]` tiers |
| `fatalExposure` | unset | Exposure that forces death; `-1` disables it |
| `protectIndoors` / `protectInVehicles` | preset-dependent | Whether being inside a building/vehicle reduces exposure |
| `showStatus` | `true` (global default) | Per-profile override of the continuous lower-left panel |
| `notifyTransitions` | `true` (global default) | Per-profile override of entry/exit cards |
| `markerEnabled` | `false` | Registers a `Waldo_fnc_Create3DMarker` world marker — see below |
| `detectorItems` / `detectorObjects` | unset | Restrict awareness (status/notices only, never protection) to players with a listed item or near a listed object |

### Tying a hazard to a world marker

The per-player HUD and entry/exit cards only tell the currently-exposed player something is wrong. Set `["markerEnabled", true]` in a profile to also register a `Waldo_fnc_Create3DMarker` world marker anchored to the zone's own area - for a moving emitter (`Waldo_fnc_HazardRegisterEmitter`), the marker is anchored directly to the source object and tracks it live, so anyone on the marker's visible sides can see where the danger actually is without needing to be inside it. Fixed-area zones resolve to their static centre position instead. Optional `["marker", HASHMAP]` supplies any `Waldo_fnc_Create3DMarker` option (`icon`, `colour`, `text`, `offset`, `distance`, `sides`); anything left unset defaults to a warning icon, the profile's `label`, and a 200 m view distance. The marker is created once when the zone registers and removed automatically by every removal path (`Waldo_fnc_HazardUnregisterZone`, the ZEN remove module, and an emitter's own destroy/delete cleanup) - it adds nothing to the per-tick evaluation loop. The shipped Hazard Emitter Moving Example composition uses this option.

```sqf
_profile set ["markerEnabled", true];
["leaking_truck", truck1, 8, _profile] call Waldo_fnc_HazardRegisterEmitter;
```

## Tree felling

Arma 3 does not include a vanilla hand-held axe. You need an axe or hatchet weapon from a mod or
your own mission content. The quickest working setup is:

1. Open `MissionConfig/environmentConfig.sqf`.
2. Change `Waldo_TreeFelling_Enable` from `false` to `true`.
3. Find the axe weapon's classname. If it contains `axe` or `hatchet`, the shipped patterns already
   recognise it. Otherwise add a distinctive part of its classname to
   `Waldo_TreeFelling_WeaponPatterns`.
4. Equip the axe, look at a tree within 3 metres, and use **Fell Tree / Clear Brush**.

For example, both `MyMod_FireAxe` and `myMod_small_axe` match the pattern `"axe"`; comparison ignores
capital letters. `Waldo_TreeFelling_ToolEfficiency` uses the same kind of fragments. A value of `2`
makes a matching tool twice as effective, while `0.5` makes it half as effective. An exact classname
wins over a fragment, and the longest matching fragment wins when several match.

The general `FallenClasses` list is used unless the appropriate small, medium or large list contains
objects. The two `SizeThresholds` values mean "end of small" and "end of medium": `[7, 15]` treats a
6 m tree as small, a 10 m tree as medium and a 20 m tree as large. `RANDOM`, `STRIKE`, and `ORIGINAL`
choose the replacement log's direction. `ProtectedAreas` normally contains Eden marker names, such
as `["base_no_logging", "town_safe_zone"]`. `Yields` contains `[object classname, count]` rows, such
as `[["Land_WoodenLog_F", 2]]`. A positive `RegrowSeconds` restores the original tree during the
current mission; `-1` or `0` disables regrowth.

Start and stop the automatic client action with `Waldo_fnc_TreeFellingInit` and
`Waldo_fnc_TreeFellingStop`. Tree felling intentionally has no ZEN module.

## Emergency dismount

Automatically extracts a player from an overturned or destroyed land vehicle/boat. Quickest working setup:

1. Open `MissionConfig\environmentConfig.sqf` and set `Waldo_EmergencyDismount_Enable` to `true`.
2. Play, roll a land vehicle onto its roof (or destroy it) with a player inside.
3. The occupant is automatically extracted to a clear nearby position, with a short configurable damage-protection window.

No further setup is required for ordinary land vehicles/boats — aircraft are excluded by default (see below). Use the `Waldo_EmergencyDismount_*` settings to select overturn/destruction triggers, normal exit versus eject, clear-exit geometry checks, momentum preservation, safe-position radius, bounded damage protection and unconscious recovery. Start and stop it with `Waldo_fnc_EmergencyDismountInit` and `Waldo_fnc_EmergencyDismountStop`; it intentionally has no ZEN module.

Land vehicles also receive a local **Set Vehicle Upright** action on the vehicle itself when tipped and nearly stationary. The server validates proximity, forwards the operation to the vehicle's owning machine and places it above the terrain using its real model bounds and the local surface normal. Vehicle simulation must remain enabled for both the emergency extraction and upright mechanics.

## WMP HUD

WMP HUD retains its dual purpose. Steam UIDs listed in `Waldo_WmpHud_AccessibilityUIDs` qualify without equipment, preserving the original accessibility use in any campaign. High-technology missions can independently grant the same HUD through configured headgear, facewear or NVGs/HMDs. Excluded UIDs override both routes; `AllowEveryone` is an explicit mission-wide bypass.

The presentation remains friendly-only, line-of-sight aware and local. It does not alter side relations or reveal enemies. The persistent icon remains visible to icon range and full name/role text appears inside name range. A tight contrast outline and capped distance scaling preserve clarity without replacing the icon or growing excessively at range. Use `Waldo_fnc_WmpHudToggle` from another local UI, and `Waldo_fnc_WmpHudStop` for cleanup.

| Setting | Default | Purpose |
|---|---|---|
| `Waldo_WmpHud_Font` | `"PuristaBold"` | Arma font used for overhead tags. |
| `Waldo_WmpHud_TextScale` | `0.035` | Near-range base text size. |
| `Waldo_WmpHud_TextDistanceGrowth` | `0.00025` | Gentle text-size increase per metre. |
| `Waldo_WmpHud_TextMaximumScale` | `0.05` | Hard cap on distance scaling. |
| `Waldo_WmpHud_TextHeadOffset` | `0.30` | Animated head-relative name height. |
| `Waldo_WmpHud_IconHeadOffset` | `0.75` | Animated head-relative chevron height. |
| `Waldo_WmpHud_OutlineScale` | `1.12` | Size of the dark outline pass relative to the foreground. |
| `Waldo_WmpHud_OutlineColour` | `[0.03, 0.03, 0.03, 1]` | Outline colour; alpha follows distance fade. |

The label foreground still comes from the current WMP theme and the player's personal colour-vision profile. Both anchors follow the model's animated `head` selection through `modelToWorldVisual`, with a safe origin-based fallback for unusual unit models. The two text passes use no engine shadow, avoiding the offset double-exposure effect produced by combining a manual outline with `drawIcon3D` shadow mode.

Eligible players can show or hide it through **ACE Self Interact > WMP Interface > Toggle WMP HUD**, with a blue vanilla addAction fallback. The Accessibility category beneath WMP Interface continues to own Colour Vision Settings. Configure WMP HUD eligibility and presentation player-locally; it intentionally has no ZEN module. See the [complete WMP HUD guide](WMP-HUD).

Colour-vision profiles are personal rather than mission-authoritative. Standard, red-green-aware, protan-aware, blue-yellow-aware and high-contrast monochrome palettes remap semantic/focus colours while retaining words, icons, shapes and patterns. The choice persists in the player's Arma profile and does not alter other players or the mission's era theme.

## Explosive wall breaching

Breaching requires ACE Explosives. WMP ships a disabled, ready-to-test profile for the vanilla
`Land_City2_8m_F` 8 m City Wall. To test it:

1. Place that wall in Eden.
2. In `MissionConfig/environmentConfig.sqf`, change `Waldo_Breaching_Enable` to `true`.
3. Place and detonate an ACE M112 demolition block or satchel within 5 metres of the wall.

Only that exact wall class reacts. Enabling the feature does not affect unrelated walls or buildings.
The shipped profile opens the full 8 m section and keeps the hidden original available for a reset.
Successful breaches are silent by default and do not occupy a WMP notification lane. Set
`Waldo_Breaching_ShowNotifications` to `true` only when the player who placed the successful charge
should receive a confirmation card.

This is the complete beginner profile from the config:

```sqf
Waldo_Breaching_Profiles = createHashMapFromArray [
    ["Land_City2_8m_F", createHashMapFromArray [ // exact target object classname
        ["radius", 5],                            // charge must explode within 5 metres
        ["explosives", [                          // allowed CfgAmmo classnames
            "DemoCharge_Remote_Ammo",
            "SatchelCharge_Remote_Ammo"
        ]],
        ["requiredStrength", 1],                  // accumulated force needed to breach
        ["destroyOriginal", true],                // damage the original wall
        ["hideOriginal", true],                   // hide it and clear the opening
        ["deleteOriginal", false],                // false allows Waldo_fnc_BreachingReset
        ["replacements", []]                      // no debris or partial wall sections
    ]]
];
```

The number beside each explosive in `Waldo_Breaching_ExplosiveStrengths` is the force contributed by
one detonation. The shipped demo charge is `1`; the satchel is `3`. A profile with
`requiredStrength = 2` therefore needs two demo charges or one satchel. Scripted subclasses inherit
their configured base ammo class's strength. These are **CfgAmmo** names, not inventory magazine
names: use `DemoCharge_Remote_Ammo`, not `DemoCharge_Remote_Mag`.

To add another breachable class, copy the entire target/profile block, put a comma between the two
blocks, and replace only the first target classname for the initial test. Keep `replacements = []`
until the basic breach works. A malformed classname affects no object; WMP diagnostics reports the
profile count and ACE dependency state.

The server validates the detonation and applies each target only once. `destroyOriginal` applies
damage, `hideOriginal` guarantees the opening is clear, and `deleteOriginal` permanently removes the
object. Keep `deleteOriginal` false unless permanent deletion is specifically required. Stop the
system with `Waldo_fnc_BreachingStop`.

Replacement objects are an advanced option. Each row is:

```sqf
["CfgVehicles_Classname", [leftRight, forwardBack, upDown], yaw, "CAN_COLLIDE", "ATL", scale]
```

Offsets use the original wall's model axes and are measured in metres. `yaw` is added to the old
wall direction. The placement mode, position mode and scale may be omitted; their safe defaults are
`"CAN_COLLIDE"`, `"ATL"`, and `1`. Complex debris layouts require in-game testing because WMP cannot
cut a new hole into arbitrary model collision geometry. Breaching intentionally has no ZEN module.

## Object scaling

Resizes a placed object at runtime — for a giant/miniature prop, or an intentionally undersized/oversized decoration. Two ways to use it:

1. **Zeus (no scripting):** place **Scale Object** on the target, choose the scale, and explicitly permit decorative conversion if the target isn't already a Simple Object.
2. **Script**, one call on the server:
   ```sqf
   private _scaledStatue = [statue, 1.75, true] call Waldo_fnc_ObjectScale;
   // [object, scale, allowDecorativeConversion]
   ```

**Always keep the returned object** — the third argument (`true`) converts an ordinary empty grounded decorative target into a Simple Object so scaling is actually supported; that conversion removes simulation, damage, inventory, crew, object-bound `addAction` entries and the original object reference, so the object your script/Eden variable name pointed at is gone and replaced.

Arma officially supports runtime scaling for Simple Objects and attached objects only — merely disabling simulation on an ordinary object does not make scaling supported. Direction/orientation commands reset scale and must run first. Limits default to `0.1`–`10` and are server-owned in `initServer.sqf`. Remote requests are curator-only unless explicitly relaxed. For batches, tag objects with `Waldo_ObjectScale` and call `Waldo_fnc_ObjectScaleTagged`.

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
