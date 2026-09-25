# Mission UI Text Overlays

> **Use this page when:** you need a short on-demand message or the automatic text shown after respawn.

WMP has three older text helpers. `Waldo_fnc_DynamicText` now sends a standard WMP notification
at the top right. `Waldo_fnc_TimedHint` still uses Arma's local hint display. Respawn text runs
automatically. For new mission messages, use [Custom UI Notifications](Custom-UI-Notifications):
it has explicit audiences, channels, states and queue handling.

## Send a short WMP message

```sqf
["Supplies ready", _player, "QUARTERMASTER"] call Waldo_fnc_DynamicText;
```

| Position | Type | Default | What to supply |
|---:|---|---|---|
| 0 `message` | String | required | Short text for the card. |
| 1 `target` | Player Object, Array of player Objects or remote-execution target Number | required | Recipient. Use a player object for a private message; use `-2` only for a deliberate all-client notice. |
| 2 `title` | String | `"MISSION UPDATE"` | Heading. Use the name of the calling feature, such as `"QUARTERMASTER"`. |

This is a compatibility helper for older calls. It returns `true` after sending a request and does
not wait for the recipient's display. The card uses `INFO`, four seconds, the `TOP_RIGHT` region
and a replacement channel based on the title. It is transient, so it is not replayed to JIP.
The function can run on the server or a client; the target client's interface draws the card.

## Show a local timed hint

```sqf
["Rendezvous respawn activated", 10] spawn Waldo_fnc_TimedHint;
```

| Position | Type | Default | What to supply |
|---:|---|---|---|
| 0 `message` | String | required | Hint text. |
| 1 `duration` | Number (seconds) | `10` | Time before this hint clears. |
| 2 `owner` | String | `""` | Internal owner label used by older WMP callers; mission scripts can omit it. |

This legacy helper calls Arma `hint` on the machine where it runs and sleeps before clearing that
hint. Use `spawn`, because the wait needs a scheduled script. A new call replaces the old hint's
clear token, so an earlier timer cannot clear the newer hint. The function returns no useful value.
To send it to one player from the server, use a scheduled remote call:

```sqf
["Convoy inbound", 15] remoteExec ["Waldo_fnc_TimedHint", owner _player];
```

For ordinary feature feedback, prefer `Waldo_fnc_SendNotification`. It uses WMP's accessible card
and chooses its recipients explicitly. A timed hint is local and is not replayed to JIP.

## Respawn text

`Waldo_fnc_RespawnText` runs from `initPlayerLocal.sqf` after a player respawns. It shows the
current in-game time, date and the player's new grid reference. There is no mission-maker setup
or positional argument. To show it again on one client:

```sqf
[] spawn Waldo_fnc_RespawnText;
```

The display waits for that client's player object and mission clock. Run a manual call where the
player has an interface; a server-only call cannot draw it on every screen. It does not change
mission state or replay a past display to JIP.

## If no text appears

Check that the target is a player with an interface. For `DynamicText`, pass the player Object or a
valid remote-execution target. For `TimedHint` and `RespawnText`, run the function on the player's
client. If several systems need to show cards at once, use a separate channel per system in
[Custom UI Notifications](Custom-UI-Notifications).

## See also

- [Mission Intro and Title Text](Mission-Intro-Or-Title-Text)
- [Custom UI Notifications](Custom-UI-Notifications)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
