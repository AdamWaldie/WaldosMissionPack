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

| Option | Type and default | Effect |
|---|---|---|
| `"players"` | String in the argument Array; default with empty Array | Show players. |
| `"ais"` | String in the argument Array; defaults on only in single-player when the Array is empty | Show AI. |
| `"allsides"` | String in the argument Array; off by default | Show all sides, including those other than the local player's. |
| `"all"` | String in the argument Array | Enable all of the above. |
| `"stop"` | String in the argument Array | Stop the local marker script. |

You can combine options, e.g. `["players", "ais"] execVM "...player_markers.sqf";`. Calling the script again replaces the previous run; `["stop"]` halts it. Markers are created **locally** on each client.

`execVM` returns a Script handle for the launched file, not a marker or a WMP success
value. The marker script exits on machines without a player interface. Each joining
player runs their own optional loader when `init.sqf` is enabled; no server marker
registry is published.

---

## If player markers do not appear

Check that the optional loader line is active in `init.sqf` and that the third-party marker script is present. Headless-client support is a separate WMP feature and does not enable player markers. Test a fresh joining player as well as the host before assuming the loader ran for everyone.

## See also

* [Headless Client Support](Headless-Client-Support): the native, opt-in replacement for the legacy headless-client script
* [Mission Configuration Reference](Mission-Configuration-Reference): where the loader line lives in `init.sqf`
* [Waldos AI Tweak](Waldos-AI-Tweak): AI skill tuning that works alongside headless offloading
* [AI Convoy System](AI-Convoy-System)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
