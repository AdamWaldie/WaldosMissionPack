# Zeus END-Key Kill Restore

> **Use this page when:** pressing END in Zeus no longer instantly kills a unit or object.

_Associated files: `MissionScripts\MissionFlowAndUi\killUnit.sqf`, `killHotkeyInit.sqf`, `Waldo_fnc_KillUnit`, `Waldo_fnc_KillHotkeyInit`_

## Why this exists

A later Arma 3 engine update changed the vanilla Zeus "press END to instantly kill whatever's under
the cursor" shortcut to respect `allowDamage`. Any unit or object that has had damage disabled -
including WMP's own SafeStart and ENDEX freezes, or any mission-specific `allowDamage false` - simply
stops dying to END, with no error or feedback at all. This is a widely reported Arma engine change,
not a WMP bug, and it affects every mission, modded or not.

WMP restores the original one-key behaviour itself instead of relying on a third-party fix.

## What it does

- Installed unconditionally from `initPlayerLocal.sqf` via `Waldo_fnc_KillHotkeyInit` - no
  configuration, no toggle. It does not depend on Zeus Enhanced at all: every command it uses
  (`curatorSelected`, `curatorMouseOver`, `getAssignedCuratorLogic`) is vanilla Arma, so it works
  under plain Zeus too. ZEN's own source was checked directly (its editor key-handling, damage,
  context-action and context-menu code, plus its release notes) and it implements no force-kill or
  force-destroy bypass of its own - there is no ZEN system for this to route through.
- Only acts while this client's own Zeus interface is open; END is never intercepted anywhere else
  (menus, chat, in-game player controls).
- Pressing END kills everything at once, not one or the other: any entities you have box-selected in
  Zeus (`curatorSelected`) **and** whatever is directly under the Zeus cursor (`curatorMouseOver`) are
  combined into one deduplicated target list every press.
- Every kill goes through `Waldo_fnc_KillUnit`, which forces `allowDamage true` on the target first,
  so it works even on something that had damage disabled. A living ACE-medical person is killed
  through `ace_medical_status_fnc_setDead` - an internal ACE function (its own header marks it
  `Public: No`, so ACE gives no compatibility guarantee on it across versions), but the standard
  community technique for a medical-aware forced kill, since ACE ships no public equivalent and a bare
  `setDamage`/`setHit` routinely fails to actually kill a unit under ACE Advanced Medical (it
  critically wounds instead). Going through it means unconscious/bleedout state, revive eligibility,
  and Obituary/AAR kill hooks all resolve exactly as a real death would. Everything else (a vehicle, a
  non-ACE AI unit, no ACE medical loaded) falls back to a plain `setDamage 1`. This ACE-aware branch is
  the only part of the behaviour that changes by mod load - never by mission configuration.

## Scripting it directly

```sqf
[cursorTarget] call Waldo_fnc_KillUnit;
```

Server-authoritative and self-forwarding (like `Waldo_fnc_Jammer`), so it is safe to call from a
script, trigger, or an object's own Eden init field with no `isServer` wrapper. Returns `true` once
the target is confirmed dead.

## See also

- [Safestart](Safestart)
- [ENDEX and After-Action Report](ENDEX-Script-&-Custom-End-Screen)
- [Waldos Mission Pack Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
---
