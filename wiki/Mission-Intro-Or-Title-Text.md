_Associated Files: MissionScripts\MissionFlowAndUi\infoText.sqf_

Displays an animated title sequence when a player loads into the mission. It fades the screen to black, types out the current in-game time and date, then reveals the mission title, location, player's grid reference, rank, name, and group — colour-coded by side.

The sequence runs automatically from `init.sqf` with no required setup. Mission makers can optionally customise the title text, location name, date format, and a player animation.

**Displayed information:**
1. Mission title — pulled from `description.ext` automatically, or overridden by the mission maker
2. In-game time and date — automatic (short or long format)
3. Map name — pulled from `worldName`, or overridden
4. Player's grid reference at the time of the intro — automatic
5. Player rank, name, and group ID — automatic, colour-coded by side

---

## Parameters

| # | Type | Default | Description |
|---|---|---|---|
| 0 | STRING | `""` | Custom mission title. Leave empty to use `onLoadName` from `description.ext` |
| 1 | STRING | `""` | Custom location name. Leave empty to use the map's `worldName` |
| 2 | BOOL | `false` | `true` = long date format ("3rd November 2024"), `false` = short ("3/11/2024") |
| 3 | STRING | `"NONE"` | Player animation to play during the intro (see below) |

---

## Basic Usage

Minimum call — title and location pulled automatically from `description.ext` and `worldName`:

```sqf
[] spawn Waldo_fnc_InfoText;
```

Custom title and location:

```sqf
["Operation Iron Fist", "Altis"] spawn Waldo_fnc_InfoText;
```

Long date format:

```sqf
["Operation Iron Fist", "Altis", true] spawn Waldo_fnc_InfoText;
```

With an intro animation:

```sqf
["Operation Iron Fist", "Altis", false, "WAKE"] spawn Waldo_fnc_InfoText;
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

To display a completely custom date string — useful for fictional settings (Star Wars, Warhammer 40k) — edit line 91 of `infoText.sqf` and set the `_date` variable directly:

```sqf
_date = "Day 14 of the Third Month, 994.M41";
```

---

## Related Functions

For runtime text overlays during the mission (not just mission start), see [Mission UI Text Overlays](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Mission-UI-Text-Overlays).
