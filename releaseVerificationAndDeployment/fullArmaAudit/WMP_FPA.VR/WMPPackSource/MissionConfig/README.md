# WMP feature configuration

This directory is the mission maker's settings layer. The files return data only: they do not
spawn assets, register world objects, add event handlers, or transfer authority. WMP's existing
init lifecycle reads that data at the correct stage.

## If you are new to Arma mission scripting

You do not need to understand SQF programming to change the normal settings. Most lines look like:

```sqf
["Waldo_Rally_Duration", 180], // Rally remains active for 180 seconds.
```

- The quoted name on the left tells WMP which setting this is. **Do not rename it.**
- The value on the right is what you may change: `180` in this example.
- Text values keep quotation marks: `"DAY"`, not `DAY`.
- `true` means on/yes; `false` means off/no.
- `[]` is an empty list. Its nearby comment says whether that means none, unrestricted or automatic.
- Lines beginning with `//`, and text between `/*` and `*/`, are explanations and are not executed.
- Keep the surrounding brackets, quotation marks and commas unless the example explicitly tells you
  to copy a complete block.
- Start with settings marked `MISSION MAKER`. Leave `ADVANCED` settings unchanged until you have a
  specific tested reason to alter them.

Longer entries are written vertically and number their fields as `0`, `1`, `2`, and so on. Read the
comments beside those fields from top to bottom. The comments describe what players will experience,
not only the underlying data type.

Every editable setting follows this documentation pattern in its own config file. The explanation
is part of the setting: do not delete it when copying or changing the active value.

Every `.sqf` config also includes a searchable **SETTING-BY-SETTING GUIDE**. The repository
validator requires that guide and requires every named WMP/ACE/Logistics setting to appear in
`wiki/Feature-Configuration-Files.md`. Adding a setting without updating both layers fails CI.

```sqf
// SETTING: Waldo_AIRebalance_Mode (MISSION MAKER)
// WHAT IT CHANGES: which lighting-condition skill variant AI use.
// VALUES: "DAY" or "NIGHT"; STRING; shipped default "DAY".
// EXAMPLE/RESULT: "NIGHT" applies low-light values; equipped NVG/HMD may add the configured offset.
["Waldo_AIRebalance_Mode", "DAY"],
```

The value on the final line is the active mission value. The example may deliberately show a
different value to demonstrate a common alternative; copy only the final setting line unless the
comment tells you to copy a complete block.

The same two-layer standard applies to callable scripts. A plain-English introduction comes first,
but it never replaces the technical contract. Script headers retain the exact numbered calling
arguments, types, defaults, return value, locality/authority, copyable example, expected result and
current callers. See [Coding and Documentation Standards](../wiki/Coding-Standards.md) for the
canonical templates.

The most important rule is: **a setting and a feature instance are not the same thing**. Setting an
`Enable` value can start an automatic handler, permit a registered-object system, or merely make a
later script call available. Read the `ACTIVATION MODEL` block at the top of the relevant file.

Every config is intended to be understandable without opening an implementation script. Its header
defines the row shapes, valid IDs, units, activation and caller. Inline comments beside each setting
identify whether it is a normal mission choice or advanced tuning. Positional arrays and nested
HashMaps have a local field-by-field legend plus a worked example where ambiguity is likely.

## Start here for each feature

1. Find the feature in the activation table below.
2. Open its named config file and review only `EDIT FOR A NORMAL MISSION` first.
3. Set its enable/availability switch if it has one.
4. If the table says **register** or **create**, add the documented call in `initServer.sqf`, a
   supported object init, a server-owned trigger/script, or use ZEN.
5. Leave `ADVANCED`, `COMPATIBILITY`, timing, geometry, parser and authority values unchanged until
   a tested mission requirement justifies them.

## Activation models

| Model | What changing the config does | Additional setup |
|---|---|---|
| Automatic | Starts the existing WMP lifecycle when enabled | None |
| Enable + register | Starts support/evaluation but creates no usable world instance | Register the required zone/object/unit |
| Call-driven | Supplies pools, defaults and safety bounds | Create each system through its public script call or ZEN |
| Mixed | Different features in the same file use different models | Follow the feature row below |

## Feature activation table

| Feature | Config | Activation | Normal mission setup |
|---|---|---|---|
| ACRE2 radio plan and Babel | `acreConfig.sqf` | Automatic | Edit this file only; no init call |
| AI rebalance | `aiConfig.sqf` | Automatic | Enable and select profile/mode/filters |
| Improved AI helicopter landing | `aiConfig.sqf` | Automatic | Enable; provide supported landing waypoints |
| Airborne gunship | `airOperationsConfig.sqf` | Call-driven | Permit it, then call `Waldo_fnc_GunshipRegister` or use ZEN |
| Dynamic paradrop | `airOperationsConfig.sqf` | Call-driven | Call `Waldo_fnc_ParadropCreateDropZone` or use ZEN |
| Dynamic AA | `airOperationsConfig.sqf` | Call-driven | Call `Waldo_fnc_DynamicAACreate` or use ZEN |
| Radio jammer | `electronicWarfareConfig.sqf` | Enable + register | Enable, then register/create jammer objects or use ZEN |
| EMP / tracker | `electronicWarfareConfig.sqf` | On demand | Use their documented public calls or ZEN |
| Hazardous environments | `environmentConfig.sqf` | Enable + register | Enable, then register zones/emitters or use ZEN |
| Tree felling | `environmentConfig.sqf` | Automatic | Enable and configure valid tool/content classes |
| Explosive breaching | `environmentConfig.sqf` | Automatic + profiles | Enable and provide matching breach profiles/explosives |
| Theme / notification flow | `interfaceConfig.sqf` | Automatic | Select theme and optional channel routing |
| Simple Dialogue / Advanced Conversations | `dialogueConfig.sqf` | Object call, safe configured definitions, or ZEN | Put a simple call in an NPC Init field, paste Conversation Author exports into the configured definition array, or register/assign live through ZEN |
| Treatment feedback | `interfaceConfig.sqf` | Automatic | Enable and select recipients/content |
| Emergency dismount | `interfaceConfig.sqf` | Automatic | Enable and select policy |
| WMP HUD | `interfaceConfig.sqf` | Automatic | Configure equipment access, accessibility UIDs and presentation |
| Tactical display | `interfaceConfig.sqf` | Register | Register a suitable display object or use ZEN |
| Field resupply | `logisticsConfig.sqf` | Register | Register hubs and assign carriers, or use ZEN |
| Vehicle recovery | `logisticsConfig.sqf` | Register | Register workshop, vehicles and optional carriers, or use ZEN |
| Object scaling | `logisticsConfig.sqf` | Call-driven | Call `Waldo_fnc_ObjectScale` or use ZEN |
| Logistics crate classes | `logisticsConfig.sqf` | Consumed defaults | Existing spawners use them; they spawn nothing alone |
| Rally / minigames / corpse traps | `missionSystemsConfig.sqf` | Automatic | Enable and configure the feature |
| Economy | `missionSystemsConfig.sqf` | Automatic runtime + content setup | Enable, then configure the dedicated economy preset/catalogue |
| Economy authored catalogues/layout | `economyConfig.sqf` | Server call-driven | Enable economy, then edit the worked public setup calls in this file |
| Diagnostics / safestart | `missionSystemsConfig.sqf` | Automatic availability; Safestart starts inactive | Review policy; Zeus can enable it during play |
| Persistence | `persistenceConfig.sqf` | Automatic + dependency gate | Enable; install INIDBI2 server-side; register world objects separately |

## Where custom calls belong

- `initServer.sqf`: preferred for pre-planned world systems, registries, authoritative objects,
  zones and state. Examples include Dynamic AA, gunships, paradrop zones, recovery workshops,
  field-resupply hubs, hazardous zones and persistent objects.
- `initPlayerLocal.sqf`: only for custom work that must exist separately on each human interface.
  Do not place server-world creation here. WMP's automatic UI and accessibility systems already
  initialise here and must not be started a second time.
- `init.sqf`: runs on every machine. Do not use it as a general feature setup file and do not put
  server authority or mutable public defaults here. WMP uses it only where all-machine/shared
  lifecycle is intentional.
- Editor object init: use only when the public function documents object-init use and is repeat-safe
  or server-routed, such as `[this] call Waldo_fnc_Jammer;`. Otherwise prefer `initServer.sqf`.
- Trigger/script: use a server-owned trigger or execute on the server for later creation. Public
  calls that accept curator requests still validate and route authority; that is not permission to
  run the same setup on every client.
- ZEN: appropriate for live, curator-driven creation/control where a module exists. A ZEN change is
  runtime authority and should not be countermanded by a repeating init default.

See `Wiki/Feature-Setup-and-Activation.md` for copy-ready examples and the feature pages for every
function parameter.

## Customisation levels

- **MISSION MAKER**: review per mission. Enables features, selects content, names, sides, policies
  and player-facing behavior.
- **ADVANCED TUNING**: supported but normally retain the shipped value. Change for a specific tested
  requirement only. This includes scheduler intervals, safety bounds, UI layout internals and
  control loops.
- **COMPATIBILITY / INFRASTRUCTURE**: do not edit for ordinary mission setup. These values preserve
  schema, dependency or older integration behavior.

## Files and loader schema

`featureConfigManifest.sqf` is infrastructure. Do not add activation code to it or reorder it unless
you are adding a new semantic config file and updating validation/documentation.

Ordinary files return a HashMap containing:

- `featureFamilies`: documentation names only.
- `shared`: `[variableName, defaultValue]`, guarded and loaded on every machine from `init.sqf`.
- `server`: `[variableName, defaultValue, publishForJip]`, loaded by `initServer.sqf` only.
- `playerLocal`: `[variableName, defaultValue]`, loaded only for a human interface client.
- `aliases`, `fallbacks`, `conditional`: compatibility/dependency forms documented in the loader;
  mission makers normally leave these alone.

Existing variables win. Server-published values remain available to JIP clients. Configuration
files must remain pure data: activation calls, waits, handlers, world mutation and remote execution
belong in lifecycle or feature scripts.

## Loadout saving and ACRE radio state

An inventory contains ACRE radio items, but a live radio's channel and ear are player-local state on
its temporary unique `_ID_n` instance. They are not safely represented by the inventory classname.
WMP therefore keeps two explicit paths:

- **Normal Save Respawn Loadout:** filters every unique radio back to its base class and stores the
  player's supported radio settings separately. Respawn creates fresh unique radios, then restores
  the channels/frequencies, ears, volume, audio source and selected radio from the last save. The
  current `acreConfig.sqf` plan is the initial setup and missing/failed-snapshot fallback.
- **INIDBI2 persistence with `Waldo_Persistence_SaveRadios = true`:** stores supported radio state
  separately per player using base class plus same-type occurrence, then restores it after fresh
  unique radios exist. The restored persistent state becomes the local respawn snapshot too.

Neither path repeatedly retunes radios during ordinary play, and neither changes player PTT defaults.
The detailed schemas and examples live directly in `acreConfig.sqf` and `persistenceConfig.sqf`.
