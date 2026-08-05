# Mod detection

WMP features guard themselves at the top of their scripts with a
`CfgPatches` check and silently no-op (sometimes with a `systemChat` notice,
sometimes fully silent) if the mod isn't loaded. Configuring a feature whose
mod isn't present isn't harmful, but it is wasted effort and can confuse a
mission maker who doesn't understand why nothing happened.

## Required (assume present, don't ask)

- **CBA_A3** — event system backbone, used everywhere.
- **ACE3** — interaction menus, medical, arsenal, cargo/dragging, fortify,
  safe-mode locking. ~80 call sites across the pack.

## Optional (ask the user, or check their mod list / server config)

| Mod | CfgPatches class checked | Powers |
|---|---|---|
| ACRE2 | `acre_main` | Radio channel auto-assignment, jamming's custom signal hook |
| TFAR | `task_force_radio` or `tfar_core` | Jamming's distance-multiplier throttle (no scripting setup needed otherwise — Eden Editor native) |
| Zeus Enhanced (ZEN) | `zen_main` | The entire "Waldos Mission Modules" Zeus menu, all Economy Zeus authoring |
| LAMBS series | (varies by module) | Not directly integrated by WMP scripts; complements AI behaviour generally |

## How to check in a live project

```sqf
if (isClass(configFile >> "CfgPatches" >> "acre_main")) then { ... };
```

If you have shell access to the mission's mod list / server launch config,
grep for these mod folder names instead of asking. Otherwise just ask the
user which of ACRE2 / TFAR / ZEN they're running — it's a fast question and
avoids configuring dead code.

## Consequences for common combinations

- **No ZEN**: Economy Systems still runs server-side (income, research,
  production, request handling) but has zero in-game authoring UI — the user
  must hand-author `MissionConfig/economyConfig.sqf` instead. All 15 core +
  19 Economy Zeus modules simply don't register. Same story for every other
  feature's ZEN modules (Dynamic AA, gunship, transport services,
  persistence, hazards, vehicle recovery, jammer, etc.) — the underlying
  script APIs and `MissionConfig` settings still work without ZEN, only the
  in-Zeus authoring/runtime-control menus disappear.
- **No ACRE2, no TFAR**: jamming's engines never install (both are gated),
  so `Waldo_fnc_Jammer` etc. can still be placed but have no radios to
  affect.
- **ACE2 signal model set to "LOS Simple"**: ACRE2 jamming's custom hook is
  never called even with ACRE2 present — the signal model must be
  *LOS Multipath* (default) or *Arcade*. Worth checking explicitly if a user
  reports jamming "not working" with ACRE2 installed.
