_Associated Files:_
- _MissionScripts\MissionFlowAndUi\dynamicText.sqf_
- _MissionScripts\MissionFlowAndUi\timeBasedhint.sqf_
- _MissionScripts\MissionFlowAndUi\respawnText.sqf_

Three functions for displaying runtime text to players during a mission. They complement the mission intro (`Waldo_fnc_InfoText`) by providing on-demand overlays for events such as objective updates, respawn notifications, and timed callouts.

---

## Dynamic Text — `Waldo_fnc_DynamicText`

Displays a short centred line of text across the screen, then fades it out. Delivered to a specific target via `remoteExec`, so it can be pushed to one player or all clients.

### Parameters

| # | Type | Description |
|---|---|---|
| 0 | STRING | The text to display |
| 1 | OBJECT / NUMBER | Target: a player object, a machine number, or `-2` for all clients |

### Examples

```sqf
// Display to a specific player
["Objective Alpha secured", player] call Waldo_fnc_DynamicText;

// Display to all clients
["Reinforcements inbound — grid 041 122", -2] call Waldo_fnc_DynamicText;
```

### Notes

- Text displays for approximately 3 seconds at size 0.8, with a short fade
- Best for brief, mission-critical messages — not suited to long text
- Can be called from a trigger, script, or Zeus module

---

## Timed Hint — `Waldo_fnc_TimedHint`

Pushes a hint to the local client's screen for a configurable duration, then clears it automatically.

### Parameters

| # | Type | Default | Description |
|---|---|---|---|
| 0 | STRING | — | Text to display in the hint |
| 1 | NUMBER | 10 | Duration in seconds before the hint clears |

### Examples

```sqf
// 10-second hint (default duration)
["Rendezvous respawn activated"] spawn Waldo_fnc_TimedHint;

// Custom duration
["Resupply point active — 45 seconds remaining", 45] spawn Waldo_fnc_TimedHint;
```

### Notes

- Must be called with `spawn` — the function sleeps internally and will block if called with `call`
- Clears the hint automatically on expiry (no leftover hint text)
- Runs locally on the machine it is called on — use `remoteExec` to push to other machines:

```sqf
[["Convoy inbound — stand by", 15], "Waldo_fnc_TimedHint", -2] remoteExec ["spawn"];
```

---

## Respawn Text — `Waldo_fnc_RespawnText`

Displays an animated two-part text sequence each time a player respawns. Runs automatically via `initPlayerLocal.sqf` and requires no manual setup.

**Sequence:**
1. Current in-game time and date (typewriter animation)
2. Player rank, name, group ID, and grid position — colour-coded by side (blue = BLUFOR, red = OPFOR, green = INDEP, purple = CIV)

### Manual Call

If you need to trigger the respawn text outside of the respawn flow:

```sqf
[] spawn Waldo_fnc_RespawnText;
```

### Notes

- Waits until the player object exists and the mission clock is running before displaying, avoiding errors on initial load
- Grid position reflects where the player actually spawned
- The animated display uses `BIS_fnc_typeText` for the typewriter effect
