# Optional Third-Party Scripts (Player Markers)

> **Use this page when:** you need to enable or configure the optional player-marker integration.

_Associated Files: `MissionScripts\ThirdPartyScripts\ThirdPartyScriptInit.sqf`, `player_markers.sqf`_

WMP includes an optional player-marker script, kept separate from the pack's normal systems and
**disabled by default**. It is loaded through a single entry point so the main `init.sqf` stays
clean.

Headless-client distribution is provided by WMP's native headless-client system. It needs no
third-party script or `init.sqf` entry. See [Headless Client Support](Headless-Client-Support).

## Enabling player markers

Off by default. In `init.sqf`, uncomment the loader line:

```sqf
// Remove the // to enable optional third-party scripts
[] execVM "MissionScripts\ThirdPartyScripts\ThirdPartyScriptInit.sqf";
```

`ThirdPartyScriptInit.sqf` is a "hollow" launcher: inside it, each script's own call line is
commented out. Open the file and uncomment the player-markers call. This keeps third-party setup in
one place instead of cluttering `init.sqf`.

---

## Player Markers

Draws dynamic map markers for players (and optionally AI), showing driver/pilot, vehicle name and
passenger count, with click-to-expand passenger lists. **Best used when ACE map markers are not an
option** for your group.

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

## See also

* [Headless Client Support](Headless-Client-Support) — the native, opt-in replacement for the legacy headless-client script
* [Mission Configuration Reference](Mission-Configuration-Reference) — where the loader line lives in `init.sqf`
* [Waldos AI Tweak](Waldos-AI-Tweak) — AI skill tuning that works alongside headless offloading
* [AI Convoy System](AI-Convoy-System)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
