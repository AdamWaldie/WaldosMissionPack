# Mission Intro and Title Text

> **Use this page when:** you need a configurable animated title sequence at mission start.

_Associated Files: MissionScripts\MissionFlowAndUi\infoText.sqf, MissionConfig\interfaceConfig.sqf_

Displays an animated title sequence when a player loads into the mission. It fades the screen to black, types out the current in-game time and date, then reveals the mission title and location. It finishes with the player's grid reference, rank, name, and group, in a colour matching their side.

The sequence runs automatically from `initPlayerLocal.sqf` with no required setup. Mission makers can optionally customise the title text, location name, date format, and a player animation.

**Displayed information:**
1. Mission title: pulled from `description.ext` automatically, or overridden by the mission maker
2. In-game time and date: automatic (short or long format)
3. Map name: pulled from `worldName`, or overridden
4. Player's grid reference at the time of the intro: automatic
5. Player rank, name, and group ID: automatic, colour-coded by side

---

## Settings (`MissionConfig\interfaceConfig.sqf`)

The automatic mission-start intro reads its content and timing from `playerLocal` settings, not from call-site arguments. Edit these in `MissionConfig\interfaceConfig.sqf`, the same file as UI theme and other player-local settings:

| Setting | Type | Default | Description |
|---|---|---|---|
| `Waldo_InfoText_Title` | STRING | `""` | Custom mission title. Leave empty to use `onLoadName` from `description.ext` |
| `Waldo_InfoText_Locale` | STRING | `""` | Custom location name. Leave empty to use the map's `worldName` |
| `Waldo_InfoText_LongDate` | BOOL | `false` | `true` = long date format ("3rd November 2024"), `false` = short ("3/11/2024") |
| `Waldo_InfoText_Animation` | STRING | `"NONE"` | Player animation to play during the intro (see below) |
| `Waldo_InfoText_FakeLoadHold` | NUMBER | `0` | Optional extra seconds for WMP's setup cover after the playable client is ready. Normally leave at `0` |
| `Waldo_InfoText_SkipFakeLoad` | BOOL | `false` | `true` skips the fake loading screen and its fades entirely (see Timing) |

```sqf
// MissionConfig\interfaceConfig.sqf
["Waldo_InfoText_Title", "Operation Iron Fist"],
["Waldo_InfoText_Locale", "Altis"],
["Waldo_InfoText_LongDate", true],
["Waldo_InfoText_Animation", "WAKE"],
```

---

## One-Off Custom Calls

`Waldo_fnc_InfoText` still accepts the same four values as positional arguments, falling back to the config setting above for any argument left out. This is for a one-off custom run - for example a trigger that re-shows the intro mid-mission with a different title without touching the mission-wide config - not for the normal mission-start intro:

```sqf
["Operation Iron Fist", "Altis", true, "WAKE"] spawn Waldo_fnc_InfoText;
```

---

## Animation Options

| Value | Description |
|---|---|
| `"NONE"` | No animation (default) |
| `"WALK"` | Slow walk forward |
| `"SIT"` | Stand up from sitting on the floor |
| `"WAKE"` | Wake up and stand |
| `"WAKESLOW"` | Longer, more cautious version of WAKE |
| `"COFFIN"` | Rise from the ground (meme input) |

---

## Date Format Override

Want a completely custom date string, for a fictional setting like Star Wars or Warhammer 40k? Edit the commented `_date = "";` line near the top of `infoText.sqf` and set it directly:

```sqf
_date = "Day 14 of the Third Month, 994.M41";
```

---

## Timing

The engine's real loading screen owns startup. WMP does not use the pre-mission briefing state as a gate and does not guess that a fixed number of seconds means loading has finished. On each client, the automatic intro waits until:

1. Arma has completed its mission initialisation (`BIS_fnc_init` is true).
2. The in-game display and that client's local player object exist.
3. The playable mission has produced a live simulation tick.

Only then does WMP open its own short cover, hide the optional animation setup, close that cover, and start the title. The title therefore cannot begin underneath the engine loading screen. The title and optional animation are cosmetic: WMP does not explicitly lock player input while they run and does not wait for crates, radios, logistics scans, or `WALDO_INIT_COMPLETE`.

`Waldo_InfoText_FakeLoadHold` is an optional extra hold inside WMP's cover. Its default is `0`, and most missions should leave it there. It is not a loading detector or a requirement:

```sqf
["Waldo_InfoText_FakeLoadHold", 0], // recommended default: no artificial hold
```

The remaining short fade durations are internal presentation constants in `infoText.sqf`. The text waits on its real reveal script rather than a guessed text duration, but that wait only controls the intro's own `Active`/`Complete` state; it does not withhold player control.

Want no fake loading screen at all? Set this in `MissionConfig\interfaceConfig.sqf` to skip it (and both fades) entirely, so the title text draws straight over whatever is already on screen:

```sqf
["Waldo_InfoText_SkipFakeLoad", true],
```

This is useful for separating WMP's presentation from the engine lifecycle during testing, and is also a legitimate permanent choice if a mission should have no fake-cover presentation.

Every stage is measured per client. [Mission Diagnostics](Mission-Diagnostics)'s `mission-flow`/`infotext-timing` check reports the readiness wait, fake-cover duration, point at which control was available, and remaining title-reveal duration. `clientStateAtRelease` is recorded only as evidence; briefing/client state is not a readiness gate.

---

## Related Functions

For runtime text overlays elsewhere in the mission, see [Mission UI Text Overlays](Mission-UI-Text-Overlays).

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
