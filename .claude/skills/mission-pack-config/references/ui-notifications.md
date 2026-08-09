# WMP UI notifications and recovery

Padded, safe-zone-aware notification card. `Waldo_fnc_ShowUiNotification`
shows a card **only on the machine that calls it** — it does not pick an
audience for you:

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
  distinct placements or accept the replace-on-newer behaviour. Valid
  placements: `TOP_RIGHT`, `CENTER`, `BOTTOM_LEFT`, `BOTTOM_CENTER`,
  `BOTTOM_RIGHT`. `TOP` is reserved for mission-flow banners (Safestart,
  ENDEX) — don't route ordinary feature notifications there.
- Client-local, dedicated-server safe.
- Two more positional args exist beyond `source`: `policy` (`AUTO`/`FIFO`/
  `REPLACE` — `AUTO` picks `REPLACE` for a persistent card and `FIFO` for a
  timed one) and `priority`/`allowLocalOverride` — see
  `wiki/Custom-UI-Notifications.md` if a mission needs to override the
  default stacking/placement-override behaviour rather than just show a
  card.
- `["CHANNEL"] call Waldo_fnc_DismissUiNotification;` clears one channel's
  active/queued card locally and returns whether anything was removed.

## Sending to an audience, not just the calling machine

`Waldo_fnc_ShowUiNotification` never resolves *who* sees a card — for that,
use one of these two (both wrap the same broadcast backend):

### `Waldo_fnc_SendNotification` — the beginner-friendly mission-script call

Safe to call from **any** machine (a trigger, an object init field,
`initServer.sqf`, another script) with no `isServer` wrapper — a client
call forwards to the server automatically, same pattern as
`Waldo_fnc_Jammer`:

```sqf
["COMMAND", "Move to the marked assembly area.", "INFO"] call Waldo_fnc_SendNotification;
["FALL BACK", "Return to base.", "WARNING", west, 10] call Waldo_fnc_SendNotification;
["ORDERS", "Move to Checkpoint Blue.", "INFO", group player] call Waldo_fnc_SendNotification;
["DRIVER", "Your vehicle is ready.", "SUCCESS", _driver] call Waldo_fnc_SendNotification;
```

Args: `[title, message, type, recipients, duration, placement, channel,
source]` — only `title`/`message` are required. `recipients` (default
`"ALL"`) accepts `"ALL"`, a side (`west`/`east`/`independent`/`civilian`),
a `GROUP`, one player `OBJECT`, or an `ARRAY` of player objects;
non-player/null entries are ignored. `duration` defaults `8`, clamped
`1-60` (`0` persists). Invalid `type`/`placement` values are silently
replaced with `INFO`/`TOP_RIGHT` (logged to RPT) rather than erroring.
These cards are live-only and are **not** replayed to players who join
later.

### `Waldo_fnc_NotificationBroadcast` — named audiences, exact reached-count

Server-authoritative (same self-forwarding pattern). Use this instead of
`SendNotification` when you need `GROUP`-by-name matching, an explicit
`UNITS` array, or the exact number of players actually reached back as a
return value:

```sqf
[createHashMapFromArray [
    ["title", "FALL BACK"], ["message", "Regroup at the rally point."], ["state", "WARNING"],
    ["duration", 10], ["placement", "TOP"], ["audience", "SIDE"], ["side", west]
]] call Waldo_fnc_NotificationBroadcast;
```

One HashMap argument: every `Waldo_fnc_ShowUiNotification` field
(`title`/`message`/`state`/`duration`/`placement`/`channel`/`source`) plus
`audience` (`ALL` default / `SIDE` / `GROUP` / `UNITS`), `side` (read for
`SIDE`), `group` (group callsign, matched case-insensitively against
`groupId`, read for `GROUP`), and `units` (array of player objects, read
for `UNITS`). Returns the number of distinct players reached.

### Eden composition (beginner drop-in)

**Waldos Mission Pack Compositions - Interface > `[WMP] Notification
Trigger`** places a ready-made 25 m any-player notification area. The
visible entity is an empty-helipad anchor (not a raw Eden Trigger — WMP
creates the real trigger on the server, which also avoids an Arma/Eden
native crash seen with a hand-authored SQE Trigger entity); move the
anchor to move the area, edit its **Init** field to change radius/title/
message/type:

```sqf
[this, 25, "MESSAGE FROM COMMAND", "Move to the marked assembly area.", "INFO"]
    call Waldo_fnc_NotificationTrigger;
```

Positions: anchor object, radius (metres), title, message, type. Optional
later positions accept recipients, duration, repeatable, placement,
channel, source — full typed list in `notificationTrigger.sqf`'s header.
Re-running setup on the same anchor safely replaces its old server
trigger.

### Zeus module

**Waldos Mission Modules > Mission Flow: Send Notification** — title/
message fields, a type selector, a duration slider, a placement selector,
a **Send to all players** checkbox, and one ZEN-native **OWNERS**
recipient picker (its own Sides/Groups/Players tabs, live multi-select, no
typed callsign) covering everything short of "everyone." Mixed selections
(a side plus extra individual players) are resolved into one deduplicated
unit list so nobody is notified twice; checking **Send to all players**
ignores the picker entirely; dropping the module directly on a player
pre-selects them. Routes through the curator-authenticated
`Waldo_fnc_ZenNotifyServer` bridge before calling
`Waldo_fnc_NotificationBroadcast` — same authorization pattern as the EMP
and Signal Tracker modules.

## Flow tuning (`MissionConfig\interfaceConfig.sqf` — player local)

Queue/reflow/stacking internals are exposed but are ADVANCED TUNING — leave
alone for a normal mission: `Waldo_UiNotification_MaximumQueued`,
`Waldo_UiNotification_QueueLifetime`, `Waldo_UiNotification_MinimumDuration`,
`Waldo_UiNotification_CharactersPerSecond`,
`Waldo_UiNotification_MaximumPerPlacement`,
`Waldo_UiNotification_ReflowDuration`,
`Waldo_UiNotification_AllowPlacementOverflow`,
`Waldo_UiNotification_OverflowPlacements`. `Waldo_UI_PanelPlacements` is the
MISSION MAKER-facing one: feature-channel → placement routing.

Persistent specialist HUDs (Safestart banner, electronic-warfare panel,
hazard exposure panel) reserve their own screen regions through
`Waldo_fnc_RegisterUiReservationLocal` rather than using the notification
stack — see `wiki/UI-Visual-Themes.md`'s "Concurrent HUD ownership" section
if a user asks why two panels can coexist without overlapping.

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
