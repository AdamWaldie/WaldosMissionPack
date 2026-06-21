_Associated Files: `MissionScripts\ThirdPartyScripts\ThirdPartyScriptInit.sqf`, `WerthlesHeadless.sqf` (Werthles' Headless Kit), `player_markers.sqf` (aeroson)_

# Third-Party Scripts: Headless Client & Player Markers

WMP bundles two well-known community scripts for mission makers who want them, kept separate from the pack's own systems and **disabled by default**. They are loaded through a single tidy entry point so the main `init.sqf` stays clean.

> **Attribution:** these are third-party scripts included unmodified in spirit — the **Headless Kit is by Werthles** (v2.3) and **player markers are by aeroson** (v2.7.1, "Dynamic Player Markers"). WMP only provides the wiring to call them. Please credit the original authors.

## Enabling them

They are off by default. In `init.sqf`, uncomment the loader line:

```sqf
// Remove the // to enable headless client and/or player markers
[] execVM "MissionScripts\ThirdPartyScripts\ThirdPartyScriptInit.sqf";
```

`ThirdPartyScriptInit.sqf` is a "hollow" launcher: inside it, each script's own call line is commented out. Open the file and uncomment whichever you want to use. This keeps third-party setup in one place instead of cluttering `init.sqf`.

---

## Player Markers (aeroson)

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

## Headless Client (Werthles' Headless Kit)

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

* [Mission Configuration Reference](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Mission-Configuration-Reference) — where the loader line lives in `init.sqf`
* [Waldos AI Tweak](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-AI-Tweak) — AI skill tuning that works alongside headless offloading
* [AI Convoy System](https://github.com/AdamWaldie/WaldosMissionPack/wiki/AI-Convoy-System)
