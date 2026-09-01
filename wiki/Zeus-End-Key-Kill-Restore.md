# Zeus END-Key Kill Restore

> **Use this page when:** a selected object remains alive after pressing END in Zeus.

_Associated files: `MissionScripts\MissionFlowAndUi\killHotkeyInit.sqf`, `Waldo_fnc_KillHotkeyInit`_

## Purpose

Vanilla Zeus binds **Destroy entity** to END. Modded units and objects do not always respond to that
action consistently. WMP adds a small selected-object damage fallback while preserving the native
action and any ZEN behaviour attached to the same key.

## Behaviour

- `initPlayerLocal.sqf` starts one local watcher through `Waldo_fnc_KillHotkeyInit` for every player,
  including JIP players.
- The watcher waits for display 312 and installs one tracked `KeyDown` handler each time the curator
  interface opens. Closing and reopening Zeus receives a fresh handler without accumulating copies.
- Only plain END is observed. Shift, Ctrl or Alt combinations are left entirely to Arma and loaded
  addons.
- The handler snapshots the object array from `curatorSelected`. It does not add the object under the
  cursor, groups, waypoints or markers.
- The handler always returns `false`, allowing the original key press to continue through normal
  vanilla and ZEN processing.
- On the next scheduled frame, WMP applies `setDamage 1` only to captured objects that are still
  alive. Objects already handled by the native action are left alone.

The fallback is client-triggered because the curator selection and display exist only on that
client. Arma's `setDamage` command accepts remote objects and publishes its effect globally, so this
does not require a public server remote-execution function.

## Scope and limitations

- Multiple selected objects are handled together, matching Zeus multi-selection workflows.
- A hovered but unselected object is never targeted by WMP.
- Damage-disabled units or objects with no destruction behaviour may still ignore or show no visible
  response to scripted damage, depending on their engine and mod configuration.
- This feature damages an object; it does not delete it.
- There is no separate scripting API. The feature exists only as an additive Zeus input fallback.

## See also

- [Safestart](Safestart)
- [ENDEX and After-Action Report](ENDEX-Script-&-Custom-End-Screen)
- [Waldos Mission Pack Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
---
