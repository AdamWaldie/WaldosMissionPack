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
| `Waldo_InfoText_FakeLoadHold` | NUMBER | `5` | Seconds held on the fake loading screen before the intro starts (see Timing) |
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

The intro is short by default: a quick fade in, the title text, then control returns. Two things decide when a player gets control back.

- **No animation** (the default): control returns as soon as the fade-in finishes and the rest of the mission has started up. The title text keeps typing itself out in the background, so reading it doesn't hold up gameplay.
- **An animation** (`WALK`, `SIT`, or `COFFIN`): control waits for that animation to finish, so the player never interrupts it mid-move. `WAKE` and `WAKESLOW` have no fixed length. Control returns for those once the rest of the sequence finishes.

A player never gets control before the mission's own startup (crates, radios, and other features) has finished, even on a fast-loading mission. The title text doesn't start typing until that same point either. On a slower-starting mission, text that started earlier could finish and disappear before the player was ever able to see it.

Arma has no way for a script to know when a specific player's own game has finished loading in. A heavy mod list or large terrain can leave a client streaming in models and textures for a few seconds after the mission has technically started. No script, including this one, can check for that finishing. The first couple of seconds before the title text appears cover that gap. If the world still looks like it's loading when the title text starts, raise `Waldo_InfoText_FakeLoadHold` in `MissionConfig\interfaceConfig.sqf`:

```sqf
["Waldo_InfoText_FakeLoadHold", 8], // seconds; shipped default is 5
```

Want the rest of the intro shorter or longer? The remaining fade durations sit as named constants near the top of `infoText.sqf` (`_blackoutFade`, `_postLoadBuffer`, and so on), each with a comment explaining what it controls. The text itself waits on its own actual reveal animation finishing, not a guessed duration, so there's no separate hold time to tune for it.

Want no fake loading screen at all? Set this in `MissionConfig\interfaceConfig.sqf` to skip it (and both fades) entirely, so the title text draws straight over whatever is already on screen:

```sqf
["Waldo_InfoText_SkipFakeLoad", true],
```

Useful for telling apart two different causes if the title text seems to appear too early or too late: our own transition timing, or the world itself not being ready yet. With it set, anything still streaming in is visible directly, with nothing covering it. If the text still cuts into an unsettled-looking world with this set, that's real streaming, not our transition. It's also a legitimate permanent choice if you don't want any loading-screen presentation.

Every stage above is also measured, not guessed at. [Mission Diagnostics](Mission-Diagnostics)'s `mission-flow`/`infotext-timing` check reports the real seconds each client spent in the display wait, the streaming-settle wait, the fake load screen, and the `WALDO_INIT_COMPLETE` wait, so a report of "the intro is slow" can be traced to one specific stage instead of the whole sequence.

---

## Related Functions

For runtime text overlays elsewhere in the mission, see [Mission UI Text Overlays](Mission-UI-Text-Overlays).

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
