# Optional Headless Client & Player Markers

> **Use this page when:** you need to enable or configure the optional headless-client or player-marker integrations.

_Associated Files: `MissionScripts\ThirdPartyScripts\ThirdPartyScriptInit.sqf`, `WerthlesHeadless.sqf`, `player_markers.sqf`_

WMP includes optional headless-client distribution and player-marker scripts, kept separate from the pack's normal systems and **disabled by default**. They are loaded through a single entry point so the main `init.sqf` stays clean.

## Enabling them

They are off by default. In `init.sqf`, uncomment the loader line:

```sqf
// Remove the // to enable headless client and/or player markers
[] execVM "MissionScripts\ThirdPartyScripts\ThirdPartyScriptInit.sqf";
```

`ThirdPartyScriptInit.sqf` is a "hollow" launcher: inside it, each script's own call line is commented out. Open the file and uncomment whichever you want to use. This keeps third-party setup in one place instead of cluttering `init.sqf`.

---

## Player Markers

Draws dynamic map markers for players (and optionally AI), showing driver/pilot, vehicle name and passenger count, with click-to-expand passenger lists. **Best used when ACE map markers are not an option** for your group.

Inside `ThirdPartyScriptInit.sqf`, uncomment and tune the call:

```sqf
0 = ["players"] execVM "MissionScripts\ThirdPartyScripts\player_markers.sqf";
```

### Options

| Option | Effect |
|---|---|
| `"players"` | Show players. |
| `"ais"` | Show AI. |
| `"allsides"` | Show all sides, not just the player's own side. |
| `"all"` | Enable all of the above. |
| `"stop"` | Stop the script. |

You can combine options, e.g. `["players", "ais"] execVM "...player_markers.sqf";`. Calling the script again replaces the previous run; `["stop"]` halts it. Markers are created **locally** on each client.

---

## Headless Client

Offloads AI groups onto one or more **Headless Client** instances to ease server load, splitting AI groups evenly across the available HCs. Runs in **multiplayer only**.

### Requirements

* A **Headless Client** entity in the mission (a virtual HC slot), and a server/host able to connect headless clients.

### Enabling

Inside `ThirdPartyScriptInit.sqf`, uncomment the call (recommended to leave the parameters as shipped):

```sqf
[true, 30, false, true, 30, 10, true, []] execVM "MissionScripts\ThirdPartyScripts\WerthlesHeadless.sqf";
```

### Parameters

| # | Default | Meaning |
|---|---|---|
| 0 | `true` | Run recurrently (keep redistributing AI over time). |
| 1 | `30` | Seconds between each redistribution check. |
| 2 | `false` | Debug available to everyone (`true`) or admin only (`false`). |
| 3 | `true` | Use the advanced AI-distribution method. |
| 4 | `30` | Start delay (seconds) before the first run. |
| 5 | `10` | Pause between each `setGroupOwner` (longer aids syncing). |
| 6 | `true` | Print a setup report. |
| 7 | `[]` | Extra "bad name" substrings — groups/units whose name contains one of these are ignored and never transferred. |

Detailed documentation lives in the header of `WerthlesHeadless.sqf` itself. For most missions the defaults above are a sensible starting point.

---

## See also

* [Mission Configuration Reference](Mission-Configuration-Reference) — where the loader line lives in `init.sqf`
* [Waldos AI Tweak](Waldos-AI-Tweak) — AI skill tuning that works alongside headless offloading
* [AI Convoy System](AI-Convoy-System)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
