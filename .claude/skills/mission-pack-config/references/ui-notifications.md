# WMP UI notifications and recovery

Padded, safe-zone-aware notification card, callable directly by mission
makers:

```sqf
["OBJECTIVE UPDATED", "Secure the relay station.", "INFO", 10, "TOP", "OBJECTIVE", "JOINT OPERATIONS"]
    call Waldo_fnc_ShowUiNotification;
```

Args: `[title, message, state, duration, placement, channel, source]`.

- `state`: `INFO`, `SUCCESS`, `WARNING`, or `ERROR`.
- `duration`: `0` = persistent (stays until replaced or cleared).
- A screen `placement` has one owner — a newer card replaces rather than
  overlaps an older one in the same spot. If two features both want a
  persistent card in the same placement, they'll fight each other; pick
  distinct placements or accept the replace-on-newer behaviour.
- Client-local, dedicated-server safe.

## Recovery

```sqf
[] call Waldo_fnc_ClearUiPanels;
```

Repeat-safe local recovery of all WMP-owned overlays/displays — use this if
a player's screen has a stuck WMP panel rather than trying to hunt down
which specific feature left it there.

Players get **WMP Interface > Clear Stuck WMP UI** as an ACE self-action
already; vanilla `addAction` installs automatically only when ACE
interaction is unavailable. No setup needed — it runs on JIP and respawn
with no authority scheduler or public state to configure.
