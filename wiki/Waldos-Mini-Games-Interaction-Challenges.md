_Associated Files: `MissionScripts\InteractionsMinigames\`, `Waldo_fnc_MiniGameInteractionSetup`, `Waldo_fnc_MiniGameInteraction`, `Waldo_fnc_MiniGameInteractionTableSetup`, `Waldo_fnc_BombDefuseSetup`, `Waldo_fnc_MiniGameChallenge`_

# Field Equipment Interaction Procedures

Field equipment procedures are single-player interactions that resolve to pass or fail. They use the
same callback contract as the earlier interaction challenges, but the player-facing presentation is
diegetic: players inspect an EOD controller, maintenance hatch, radio, manifold, access terminal, or
other physical equipment instead of opening a generic minigame window.

They register on first use and work even when the seated table-game engine is disabled.

## One-line Eden setup

Place this in an object's Eden **Initialization** field:

```sqf
[this, "repair"] call Waldo_fnc_MiniGameInteractionSetup;
```

Available procedure ids are `wirecut`, `minesweeper`, `keypad`, `lockpick`, `circuit`, `repair`,
`radiotune`, `pressure`, and `sequence`.

The helper supplies a suitable action, equipment identity, icon, and balanced configuration. Failure
allows another attempt by default; success consumes the interaction. It broadcasts:

| Variable | Meaning |
|---|---|
| `Waldo_MG_InteractionComplete` | `true` after the latest successful attempt. |
| `Waldo_MG_InteractionFailed` | `true` after the latest failed attempt; reset on success. |
| `Waldo_MG_<id>Complete` | Procedure-specific completion flag, such as `Waldo_MG_repairComplete`. |

## Immersive equipment profiles

Use a hashmap when customizing the equipment identity. Layout positions are template-owned so mission
overrides cannot break the interface.

```sqf
[
    this,
    "circuit",
    createHashMapFromArray [
        ["preset", "generatorBreaker"],
        ["actionTitle", "Inspect Generator Cabinet"],
        ["manufacturer", "NATO FIELD POWER SYSTEMS"],
        ["model", "AUX BUS CONTROL UNIT"],
        ["title", "GENERATOR BUS B"],
        ["skin", "hazard"],
        ["briefing", "GENERATOR ISOLATION PROCEDURE"],
        ["objective", "Route each isolated breaker to its matching distribution bus."],
        ["controls", "Select a labelled breaker, then its matching bus."],
        ["hint", "Match both the terminal symbol and its engraved label."],
        ["statusText", "[LIVE] AUXILIARY BUS ENABLED"],
        ["successText", "Bus synchronized. Generator output restored."],
        ["config", [4, 3, 0, "GENERATOR BUS B"]]
    ]
] call Waldo_fnc_MiniGameInteractionSetup;
```

Presentation keys are `preset`, `actionTitle`, `manufacturer`, `model`, `title`, `skin`, `objective`,
`briefing`, `activation`, `controls`, `hint`, `statusText`, `successText`, `failureText`, `timeoutText`,
`abortText`, `icon`, `texture`, and `soundProfile`. Operational keys remain `config`, `successVariable`, `failureVariable`,
`retryOnFailure`, `repeatable`, `distance`, `condition`, `onSuccess`, and `onFailure`.

`skin` accepts `default`, `olive`, `charcoal`, `sand`, `naval`, or `hazard`. `soundProfile` accepts
`equipment` or `silent`. Unknown values safely fall back to `default` and `equipment`. A texture may
be a mission-relative or vanilla Arma path and is drawn as a faint equipment overlay; it never
replaces labels or semantic state symbols. Mission makers cannot provide raw control positions or
semantic colours, so presentation changes cannot remove protected contrast or break the layout.

### Presentation option reference

| Key | Type | Purpose |
|---|---|---|
| `preset` | String | Selects a curated equipment identity and terminology. |
| `actionTitle` | String | Text shown on the world interaction, such as `Service Cooling Manifold`. |
| `icon` | String | ACE interaction icon path. Vanilla `addAction` ignores the icon. |
| `manufacturer` / `model` | String | Engraved equipment identification plate. |
| `title` | String | Main equipment faceplate title. Hashmap setups only; legacy arrays retain their old meaning. |
| `briefing` | String | Heading on the pre-operation procedure card and help card. |
| `objective` | String | The operational goal presented before and during use. |
| `activation` | String | Contextual start control; the timer does not begin before this is pressed. |
| `controls` | String | Short footer and procedure-card control reminder. |
| `hint` | String | Longer procedure note shown by the help control. |
| `statusText` | String | Initial live-equipment status after activation. |
| `successText` / `failureText` | String | Final explicit result wording. |
| `timeoutText` / `abortText` | String | Operating-window and confirmed-abort wording. |
| `skin` | String | Curated casing palette: `default`, `olive`, `charcoal`, `sand`, `naval`, or `hazard`. |
| `texture` | String | Vanilla or mission texture path. Set to `""` to disable the material overlay. |
| `textureOpacity` | Number | Decorative overlay opacity, clamped to `0..0.32`; default `0.18`. |
| `soundProfile` | String | `equipment` for built-in UI cues or `silent`. |

All string values are type-checked. Invalid types are ignored, unknown skins use the equipment
default, unknown sound profiles use `equipment`, and texture opacity is clamped. Generated textures
remain decorative: interactive controls, captions, patterns, labels, and state symbols are separate
Arma controls drawn above them.

### Included original material textures

WMP includes four original generated material sheets, converted to power-of-two 1024px JPEGs for
compact mission distribution. They contain no operational text or gameplay state and are applied at
low opacity according to equipment family.

| Olive equipment casing | Charcoal breaker steel |
|---|---|
| ![Olive equipment casing](../raw/master/MissionScripts/InteractionsMinigames/Themes/Textures/equipment_olive.jpg) | ![Charcoal breaker steel](../raw/master/MissionScripts/InteractionsMinigames/Themes/Textures/equipment_charcoal.jpg) |
| Naval communications aluminium | Sand maintenance hatch |
| ![Naval communications aluminium](../raw/master/MissionScripts/InteractionsMinigames/Themes/Textures/equipment_naval.jpg) | ![Sand maintenance hatch](../raw/master/MissionScripts/InteractionsMinigames/Themes/Textures/equipment_sand.jpg) |

Default assignments are olive for EOD and pressure equipment, charcoal for diagnostic/access/power
equipment, naval for communications and authorization consoles, and sand for maintenance and lock
hardware. Selecting a non-default skin selects its matching texture unless `texture` was explicitly
provided. The `hazard` skin uses charcoal steel beneath procedural warning accents.

All wording fields are optional. Keep `controls` short enough for the footer and use `hint` for the
longer help-card explanation. Gameplay remains controlled by `config`; changing a title or skin does
not change difficulty, timing, callbacks, or success rules.

Legacy option arrays remain compatible; in a legacy array, `title` continues to mean the world action
text. Use a hashmap for the new equipment faceplate fields.

### Curated presets

| Procedure | Default equipment | Additional presets |
|---|---|---|
| `wirecut` | Rugged EOD controller | `vehicleCharge`, `navalCharge` |
| `minesweeper` | Ordnance diagnostic tablet | `mineDetector` |
| `keypad` | Industrial access terminal | `safeController`, `bunkerTerminal` |
| `lockpick` | Cutaway cylinder | `safeLock`, `vehicleIgnition` |
| `circuit` | Generator breaker cabinet | `communicationsRelay`, `facilityFusePanel` |
| `repair` | Open maintenance hatch | `armourPlate`, `fieldGenerator` |
| `radiotune` | NATO receiver | `antennaController`, `distressBeacon` |
| `pressure` | Hydraulic manifold | `fuelRegulator`, `coolantControl` |
| `sequence` | Secure control console | `authorizationConsole` |

## Procedures and controls

Every procedure first opens an integrated field operating card. The timer starts only after its
contextual activation button is pressed. A compact control reminder remains visible, and
**Field Procedure** reopens the complete instructions.

| Id | Equipment and operation | Config | Controls |
|---|---|---|---|
| `wirecut` | EOD controller: isolate the identified lead | `[wireCount(3-6,5), timeLimit(20), title]` | Click a numbered, patterned wire |
| `minesweeper` | Trigger analyser: survey an explosive matrix | `[size(4-8,5), mineCount(5), timeLimit(0), title]` | Left reveal; right flag |
| `keypad` | Access terminal: recover its authorization code | `[digits(3-6,4), maxGuesses(6), timeLimit(0), title]` | Mouse or numbers; Backspace; Enter |
| `lockpick` | Cutaway cylinder: set pins at the shear line | `[pins(1-6,3), period(1.4), zoneWidth(0.16), timeLimit(0), title]` | Mouse or Space applies tension |
| `circuit` | Breaker cabinet: route terminals to matching buses | `[pairs(3-6,4), maxMistakes(3), timeLimit(0), title]` | Select labelled left and right terminals |
| `repair` | Maintenance hatch: torque every fastener | `[boltCount(3-6,4), turns(1-4,2), maxMistakes(3), timeLimit(30), title]` | Select bolt; circle wrench clockwise |
| `radiotune` | Communications unit: acquire and hold carriers | `[channels(1-5,3), tolerance(0.02-0.15,0.05), holdTime(1), timeLimit(30), title]` | Wheel, buttons, or Left/Right |
| `pressure` | Manifold: stabilize all coupled lines | `[valves(2-4,3), difficulty(1-3,1), settleTime(2), timeLimit(45), title]` | Open/close labelled valves |
| `sequence` | Secure console: repeat authorization signals | `[pads(3-6,4), rounds(1-8,4), speed(0.25-1.5,0.6), timeLimit(0), title]` | Mouse or number keys 1-6 |

### Bomb defusal (`wirecut`)

The EOD controller identifies one numbered and patterned lead. Cutting the correct lead succeeds;
the wrong lead or expired timer fails immediately. The player must match both number and pattern, so
wire colour is supplementary. Presets can reinterpret the controller as a vehicle or naval charge
unit without changing the established `[wireCount, timeLimit, title]` contract.

### Ordnance diagnostics (`minesweeper`)

The tablet presents an explosive-circuit matrix. The first probe is always safe, empty regions flood
open, right click toggles explicit probe markers, and a loss reveals the complete fault map. Mine and
flag counters remain visible. This procedure uses the established `[size, mineCount, timeLimit,
title]` order.

### Industrial access terminal (`keypad`)

Players enter a hidden authorization code with mouse or keyboard input. Backspace and Enter work,
invalid actions are disabled, and each attempt reports labelled `EXACT` and `MISPLACED` counts in a
readable history. The procedure locks out when guesses or time expire.

### Cutaway lock cylinder (`lockpick`)

The view exposes pins, pick, shear line, set window, tension state, and cylinder progress. Mouse or
Space applies tension when the moving pick is inside the labelled window. Each successful pin
increases the mechanism speed while explicit `SET`/`UNSET` labels preserve monochrome readability.

### Breaker and relay cabinet (`circuit`)

Select a labelled terminal on the isolated side and then its matching distribution bus. Terminal
symbols and labels duplicate colour coding; routed cable paths and connected states remain visible.
The maximum-mistake and timer settings are mission controlled.

### Maintenance hatch (`repair`)

Select a loose bolt and hold the left mouse button over the wrench. Move clockwise around the tool
centre to build torque. Display-level pointer capture prevents stale drag state when the cursor leaves
the original tool control. Reversing, slipping, or continuing past a seated bolt records a mistake;
the bolt label reports its exact percentage and `TORQUED` state.

### Communications tuning (`radiotune`)

Tune with the mouse wheel, buttons, or Left/Right keys until the needle is inside the labelled target
band, then hold the signal for the configured time. Each acquired carrier advances the channel
selector. The numeric frequency, target band, needle, lock wording, and audio caption provide
redundant feedback.

### Pressure manifold (`pressure`)

Each valve changes its own gauge and couples into neighbouring lines. Bring all gauges inside their
labelled safe bands and hold the system for the settle period. Every gauge reports `LOW`, `SAFE`, or
`HIGH` alongside its needle position; difficulty narrows the permitted band without changing input
behavior.

### Secure control sequence (`sequence`)

Observe progressively longer control-lamp sequences and reproduce them by mouse or number keys.
Pads carry numbers, shapes, and names in addition to illumination. Playback, player-input, accepted,
and rejected stages are explicitly labelled. A zero time limit keeps the procedure round-driven.

Colour is never the only signal: wires have numbers and patterns, terminals have symbols, sequence
pads have names and shapes, gauges show LOW/HIGH/SAFE labels, and results include explicit symbols
and text. Press Escape once for a visible warning and again within three seconds to confirm failure.
For bomb defusal, confirmed abort retains the configured detonation behavior.

## Accessibility preferences

Presentation preferences are local and do not alter mission difficulty or timers:

```sqf
[
    ["highContrast", true],
    ["colourblind", true],
    ["largeText", true],
    ["strongOutlines", true],
    ["reducedMotion", true],
    ["audioCaptions", true]
] call Waldo_fnc_MiniGameAccessibility;
```

Call `[] call Waldo_fnc_MiniGameAccessibility` to read the current preferences.

| Preference | Effect |
|---|---|
| `highContrast` | Uses a darker casing and bright protected accent while retaining equipment identity. |
| `colourblind` | Uses colourblind-safe semantic hues in addition to existing symbols and wording. |
| `largeText` | Enlarges equipment, briefing, result, and dynamically opened help text within safe limits. |
| `strongOutlines` | Adds a clear perimeter to the protected equipment inspection area. |
| `reducedMotion` | Shortens completion transitions without changing timing or difficulty. |
| `audioCaptions` | Adds visible start, confirmation, and fault-tone captions. |

Preferences are stored in the local player profile and therefore do not require mission-maker or
server configuration. Colour is never the only carrier of meaning, even when `colourblind` is false.

## Object lifecycle, callbacks, and locality

The setup helper keeps world-state ownership server-side while equipment UI runs only for the local
actor. Success and failure callbacks receive `[object, actor, result]` on the server after the
broadcast completion variables are updated.

```sqf
[
    this,
    "pressure",
    createHashMapFromArray [
        ["actionTitle", "Stabilize Coolant Loop"],
        ["preset", "coolantControl"],
        ["config", [4, 2, 3, 60, "REACTOR COOLANT LOOP"]],
        ["successVariable", "coolingRestored"],
        ["failureVariable", "coolingServiceFailed"],
        ["retryOnFailure", true],
        ["repeatable", false],
        ["condition", {alive _this}],
        ["onSuccess", {
            params ["_equipment", "_engineer"];
            _equipment animateSource ["valve_source", 1];
            [format ["Cooling restored by %1", name _engineer]] remoteExec ["systemChat", 0];
        }],
        ["onFailure", {
            params ["_equipment", "_engineer"];
            _equipment setVariable ["requiresSupervisor", true, true];
        }]
    ]
] call Waldo_fnc_MiniGameInteractionSetup;
```

`retryOnFailure` defaults to `true`; `repeatable` defaults to `false`. A successful non-repeatable
procedure removes access for every client. The shared active-equipment guard prevents two different
procedures from stacking on one player, and exactly-once resolution prevents duplicate callbacks.

ACE interaction is used when ACE Interact Menu is available. Otherwise the same setup creates a
vanilla `addAction`, using the configured distance and condition.

## Optional party-table picker

This adds a separate **Field Equipment** action and picker. Procedures launch locally and never join
the party table's voting, ready, seating, or active-game state.

```sqf
[this, ["repair", "radiotune", "circuit"]] call Waldo_fnc_MiniGameInteractionTableSetup;
```

Entries can supply configuration and presentation:

```sqf
[this, [
    ["circuit", [4, 3, 0], [["preset", "facilityFusePanel"]]],
    ["radiotune", [3, 0.05, 1, 30], [["preset", "antennaController"]]]
], createHashMapFromArray [
    ["actionTitle", "Inspect Training Equipment"],
    ["distance", 5]
]] call Waldo_fnc_MiniGameInteractionTableSetup;
```

The picker options hashmap accepts `actionTitle`, `icon`, and `distance`. Each entry retains its own
challenge configuration and presentation profile.

Existing party tables are unchanged unless this function is called.

## Generic and standalone APIs

`Waldo_fnc_MiniGameInteraction` keeps the established signature:

```sqf
[object, id, config, onSuccess, onFailure, options] call Waldo_fnc_MiniGameInteraction;
```

Callbacks run on the server and receive `[object, actor, success]`. The options array additionally
accepts `["presentation", profilePairs]`.

Run a procedure without an object with:

```sqf
["keypad", [4, 6], {hint "Safe open."}, {hint "Locked out."}] call Waldo_fnc_MiniGameChallenge;
```

Its optional seventh argument is an equipment presentation array or hashmap. For visual review,
`[] call Waldo_fnc_MiniGameEquipmentGallery` opens all nine procedures with stable showcase configs.

### Developer gallery and visual review

The gallery is intentionally separate from gameplay and provides deterministic sample data for all
nine equipment classes. Use it in the editor debug console:

```sqf
[] call Waldo_fnc_MiniGameEquipmentGallery;
```

Review briefing, active, warning, success, failure, timeout, help, and abort states at the mission's
supported resolutions and UI scales. Repeat with local accessibility settings enabled. Static SQF
validation cannot prove in-engine font metrics or texture availability, so mission release testing
should still include 4:3, 16:10, 16:9, ultrawide, reduced resolution, and common Arma UI scales.

## Subsystem structure

| Folder | Responsibility |
|---|---|
| `InteractionsMinigames/Core` | Registry, launch lifecycle, safe-zone shells, help, accessibility, and exactly-once results. |
| `InteractionsMinigames/Equipment` | Equipment decoration and integrated pre-operation briefing. |
| `InteractionsMinigames/Challenges` | Isolated state and mechanics for the nine procedures. |
| `InteractionsMinigames/Integration` | Object setup, ACE/vanilla actions, server results, gallery, bomb wrapper, and table picker. |
| `InteractionsMinigames/Themes` | Validated profiles, curated palettes, presets, and packaged material textures. |

The subsystem is registered as the separate `InteractionMiniGames` CfgFunctions group while keeping
the existing `Waldo_fnc_MiniGame*` public function names. The seated party-game engine and lobby are
not used by field procedures.

## Bomb defusal

```sqf
[this] call Waldo_fnc_BombDefuseSetup;
```

The existing bomb wrapper remains compatible. The EOD controller succeeds by cutting the correct
lead; a wrong lead, timeout, or confirmed abort follows the configured failure/detonation callback.

## See also

* [Waldos Mini Games](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games)
* [Table Games](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games-Table-Games)
