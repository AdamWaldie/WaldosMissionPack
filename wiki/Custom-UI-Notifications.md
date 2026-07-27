# Custom WMP UI Notifications

`Waldo_fnc_ShowUiNotification` exposes the padded, safe-zone-aware visual language used by SafeStart, Electronic Warfare and Economy feedback.

```sqf
[
    "SUPPLY DELIVERED",
    "The forward crate is ready for collection.",
    "SUCCESS",
    8,
    "TOP",
    "LOGISTICS",
    "WMP OPERATIONS // LOGISTICS"
] call Waldo_fnc_ShowUiNotification;
```

Arguments are `[title, message, state, duration, placement, channel, source, policy, priority, allowLocalOverride]`.

| Argument | Values |
|---|---|
| `state` | `INFO`, `SUCCESS`, `WARNING`, `ERROR`. Every state includes a text symbol as well as colour. |
| `duration` | Seconds. Use `0` for a persistent card. |
| `placement` | `TOP`, `TOP_RIGHT`, `CENTER`, `BOTTOM_LEFT`, `BOTTOM_RIGHT`. |
| `channel` | Ownership key. It separates persistent system state and transient message queues. |
| `source` | Small equipment, system or mission label above the title. |
| `policy` | `AUTO`, `FIFO`, or `REPLACE`. `AUTO` queues timed notices and replaces persistent notices. |
| `priority` | Reserved numeric mission priority. Use `REPLACE` for a notice that must immediately supersede its channel. |
| `allowLocalOverride` | Uses a permitted local player placement override when `true`. The mission must explicitly allow that channel first. |

Cards from different channels can coexist. The renderer stacks up to three cards in a placement with measured spacing and queues overflow. Timed cards in the same channel are shown FIFO. Duplicate queued messages are coalesced. Persistent status cards use replacement semantics so an updated status never leaves an obsolete copy behind.

## Mission-authored placement

The placement passed to `Waldo_fnc_ShowUiNotification` is the default for that call. A mission can establish a reusable channel default during initialization:

```sqf
// [channel, placement, allowLocalPlayerOverride, publish]
["ELECTRONIC_WARFARE", "BOTTOM_RIGHT", false, true]
    call Waldo_fnc_SetUiPanelPlacement;
```

This lets a mission maker reserve screen regions without editing WMP internals. When the third argument is `true`, a player may opt into a local position:

```sqf
["ELECTRONIC_WARFARE", "BOTTOM_LEFT", true]
    call Waldo_fnc_SetLocalUiPanelPlacement;
```

The local helper refuses changes unless the mission has allowed them. Local choices are stored in the player's profile. Pass `allowLocalOverride = true` in the notification call to use the permitted choice; otherwise the mission position remains authoritative.

The function is local by design. To show a card to every current client:

```sqf
[
    "OBJECTIVE UPDATED",
    "Secure the relay station.",
    "INFO",
    10,
    "TOP",
    "OBJECTIVE",
    "JOINT OPERATIONS"
] remoteExecCall ["Waldo_fnc_ShowUiNotification", -2];
```

Target a client owner instead of `-2` when only one player should see it. Dedicated servers safely return without creating controls.

## Emergency cleanup

```sqf
[] call Waldo_fnc_ClearUiPanels;
```

Cleanup is local and repeat-safe. It removes WMP-owned notification cards, HUD controls, party displays and interaction-equipment displays without touching Arma, ACE, ACRE2, TFAR or mission-maker controls. Closing an active procedure display may abandon that attempt, so this is a recovery action rather than normal navigation.

Every player also receives **WMP Interface > Clear Stuck WMP UI** under ACE self-interaction. If ACE interaction is unavailable, a low-priority vanilla action is installed instead. It is reinstalled on respawn and requires no server scheduler or public state.
