# Optional Third-Party Scripts (Player Markers)

> **Use this page when:** you need to enable or configure the optional player-marker integration.

_Associated Files: `MissionScripts\ThirdPartyScripts\ThirdPartyScriptInit.sqf`, `player_markers.sqf`_

WMP includes an optional player-marker script, kept separate from the pack's normal systems and
**disabled by default**. Its launcher belongs in player-local startup because its map markers exist
only on the executing player's client.

Headless-client distribution is provided by WMP's native headless-client system. It needs no
third-party script or player-marker entry. See [Headless Client Support](Headless-Client-Support).

## Quick setup: enabling player markers

Off by default. In `initPlayerLocal.sqf`, uncomment the loader line inside the `hasInterface` block:

```sqf
// Remove the // to enable optional third-party scripts
[] execVM "MissionScripts\ThirdPartyScripts\ThirdPartyScriptInit.sqf";
```

`ThirdPartyScriptInit.sqf` is a launcher with its own call still commented out. Open it and
uncomment the player-markers call too. Both lines must be active before markers appear.

---

## Settings: player markers

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
player runs their own optional loader when `initPlayerLocal.sqf` is enabled; no server marker
registry is published.

The legacy script assigns `onMapSingleClick` on each client. That can replace another mission's
map-click handler, and its `"stop"` path does not restore the previous handler. Test it alongside
other map tools before enabling it for players. WMP's own 3D markers are a separate system.

---

## If player markers do not appear

Check both commented lines: the launcher in `initPlayerLocal.sqf` and the marker call inside `ThirdPartyScriptInit.sqf`. Headless-client support does not enable player markers. Test a joining player as well as the host.

## See also

* [Headless Client Support](Headless-Client-Support): the native, opt-in replacement for the legacy headless-client script
* [Mission Configuration Reference](Mission-Configuration-Reference): player-local setup in `initPlayerLocal.sqf`
* [Waldos AI Tweak](Waldos-AI-Tweak): AI skill tuning that works alongside headless offloading
* [AI Convoy System](AI-Convoy-System)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
