# Waldos Mini Games — table games + interaction challenges

Two complementary but independent systems under one feature name. Ask which
one the user actually means — "minigames" is used for both, and they have
different enable flags and setup paths. Full tutorial:
https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games

## 1. Table games (multiplayer, seated)

Twelve games: Battleship, Who's Who: Vehicles, Shotgun Roulette, Blackjack,
Texas Hold'em, Five-Card Draw, Liar's Dice, Chess, Checkers, Connect Four,
Rock Paper Scissors, UNO. Players walk up to a supported table object, seat
(up to four), vote for a game, play. Server-authoritative; JIP-safe.

Enable via `Waldo_MiniGames_Enable` in `MissionConfig\missionSystemsConfig.sqf`
(a `shared` entry, loaded automatically on every machine from `init.sqf` —
default `true`, do not paste the old `if (Waldo_MiniGames_Enable) then {...}`
lifecycle block into `init.sqf` yourself, WMP already runs it):

```sqf
["Waldo_MiniGames_Enable", true],  // BOOL: installs the table-games engine
```

Tables are detected **by class**: `Land_CampingTable_F`,
`Land_CampingTable_small_F`, `Land_CampingTable_small_white_F`,
`Land_TablePlastic_01_F`. If the user wants a different table object to
work, that means adding its classname to `Waldo_MG_CFG_TABLE_CLASSES` in
`MissionScripts/MiniGames/engine/config.sqf` — not something achievable
purely from `init.sqf`. Other tuning constants (`Waldo_MG_CFG_*`) live in
the same file.

## 2. Field equipment procedures (single-player, generic interaction hook)

Ten pass/fail procedures that gate any object interaction: `wirecut`,
`minesweeper`, `keypad`, `lockpick`, `circuit`, `repair`, `radiotune`,
`pressure`, `sequence`, `commandinput`. Each has distinct diegetic
equipment, not a shared window. Works independently of table games —
`Waldo_MiniGames_Enable = false` doesn't disable these; they register on
first use.

### Simple setup (recommended default)

Eden Editor object init field:

```sqf
[this, "repair"] call Waldo_fnc_MiniGameInteractionSetup;
```

This wrapper supplies the action, equipment profile, icon, and default
config; allows retries after failure; consumes the action after success;
broadcasts `Waldo_MG_InteractionState` / `Waldo_MG_InteractionResult` (and
legacy `Waldo_MG_InteractionComplete` / `Waldo_MG_InteractionFailed`
booleans). Uses ACE where available, vanilla `addAction` as fallback with
matching state.

### Difficulty and presentation

`difficulty`: `easy` | `standard` | `hard` | `expert` — changes workload,
tolerance, and time, never legibility or accessible state cues. A supplied
positional `config` overrides the difficulty preset entirely.

Presentation hashmap (curated, doesn't touch difficulty): `preset`, `skin`
(`default`, `olive`, `charcoal`, `sand`, `naval`, `hazard`), `actionTitle`,
`manufacturer`, `model`, `title`, `briefing`, `objective`, `activation`,
`controls`, `hint`, `statusText`, result/abort wording, `soundProfile`
(`equipment` | `silent`), optional `texturePreset` (`olive`, `charcoal`,
`naval`, `sand`) or explicit `texture` with opacity clamped `0..0.32`
(default `0.14`). Never suggest exposing raw control positions or semantic
colours in a mission-maker config — those stay template-owned so
customization can't produce clipped or colour-only states.

### Ready-made wrapper: bomb defuse

```sqf
[this] call Waldo_fnc_BombDefuseSetup;
```

Adds a "Defuse Bomb" interaction (wire-cut challenge) with
detonate-on-failure. Pass an options array for `wireCount`, `timeLimit`,
`detonateOnFailure`, `explosive`, etc. if the default needs tuning.

`WMP_Compositions/[WMP]Bomb_Defusal_Example_Minimal` is a pre-placed object
with just the bare `[this] call Waldo_fnc_BombDefuseSetup;` call above.
`_Full` shows the options array set explicitly on the same object.

### Generic hook (for custom success/failure logic)

```sqf
[object, challengeId, config, onSuccess, onFailure, options] call Waldo_fnc_MiniGameInteraction;
```

Call from the object's **init field** (runs on all machines). Success/failure
callbacks run on the **server**, each receiving `[object, actor, success,
result]` — use this when the outcome needs to drive something authoritative
(spawning a follow-on event, changing an objective state) beyond the
built-in state broadcasts.

### Reading state (safe for ACE conditions — unscheduled, no side effects)

```sqf
[object] call Waldo_fnc_MiniGameInteractionGetState;
[object, "RUNNING"] call Waldo_fnc_MiniGameInteractionStateIs;
[object] call Waldo_fnc_MiniGameInteractionGetResult;
```

`Waldo_fnc_MiniGameInteractionReset` is server-only; normal reset refuses a
`RUNNING` attempt, forced reset invalidates it.

### Accessibility (per-player, never changes difficulty)

```sqf
[] call Waldo_fnc_MiniGameAccessibility;
```

Local high-contrast, colourblind, large-text, outlines, reduced-motion, and
audio-caption preferences.

### Standalone / custom challenges

- `Waldo_fnc_MiniGameChallenge` — run a challenge with no object, local
  callbacks.
- `Waldo_fnc_MiniGameRegisterChallenge` — register a new challenge (opener
  contract `[_config, _resolve]`) if the built-in ten don't fit.
- `Waldo_fnc_MiniGameInteractionTableSetup` — a separate opt-in Field
  Equipment picker placed on a table; stays local, does not enter table-game
  voting/seating/active-game state.
- `Waldo_fnc_MiniGameEquipmentGallery` — developer visual-review picker for
  all ten procedures, useful when a user wants to preview equipment styles
  before committing to one.

## 3. ACE Corpse Traps (related but separate feature)

Not part of "minigames" proper, but shares the same `missionSystemsConfig.sqf`
neighbourhood and player mental model ("another pass/fail interaction
system") — see `references/corpse-traps.md` if the user's request is
actually about rigging bodies with concealed throwables, not table games or
field-equipment procedures.
