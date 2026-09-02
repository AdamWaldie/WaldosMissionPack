# Zeus END-key kill restore

Associated files: `MissionScripts\MissionFlowAndUi\killHotkeyInit.sqf` (`Waldo_fnc_KillHotkeyInit`).
No `MissionConfig` file, no scripting API, no ZEN module — this is a small additive Zeus input
fallback with nothing for a mission maker to configure or call.

## What it does

Vanilla Zeus binds **Destroy entity** to END, but modded units/objects don't always respond to that
action consistently. WMP adds a fallback: on plain END (no Shift/Ctrl/Alt — those combinations are
left entirely to Arma/loaded addons), it snapshots `curatorSelected select 0`, returns `false` so
Arma's and any ZEN's own normal END processing still runs unmodified, then on the next scheduled
frame applies `setDamage 1` only to captured objects that remain alive. It never targets the hovered-
but-unselected object, groups, waypoints, or markers — selected objects only, matching normal Zeus
multi-select.

## Setup

None needed — `initPlayerLocal.sqf` starts one local watcher per player (including JIP) via
`Waldo_fnc_KillHotkeyInit`. It waits for the Zeus display (312) and installs one tracked `KeyDown`
handler each time the curator interface opens; closing and reopening Zeus gets a fresh handler rather
than accumulating copies. Client-triggered by design — curator selection and the Zeus display only
exist on that client, and `setDamage` accepts remote objects and publishes globally, so no public
server remote-exec endpoint is needed.

## Gotchas

- This damages the object (`setDamage 1`); it does not delete it — a destroyed vehicle wreck, not a
  disappearance.
- Damage-disabled units/objects, or ones with no real destruction behaviour, may still show no
  visible response depending on their own mod's config — this is an engine/addon limitation, not
  something WMP can force past.
- Nothing to break by "not configuring" this — if a mission maker asks why END sometimes doesn't
  finish off a selected object, this fallback is already active by default; the answer is almost
  always the addon's own damage handling, not a missing setup step.
