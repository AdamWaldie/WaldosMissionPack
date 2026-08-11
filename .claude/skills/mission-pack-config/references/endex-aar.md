# ENDEX / mission end + After-Action Report

```sqf
[] spawn Waldo_fnc_ENDEX;
```

Freezes the mission: broadcasts "ENDEX ENDEX ENDEX", locks all weapons (ACE
safety mode), heals all players, deletes fired rounds, sets all AI to
CARELESS/BLUE, makes all players invincible. Also reachable via the Zeus
Enhanced **Call Endex** module.

## AAR is part of the same flow, not a separate feature

The ENDEX hint shows an After-Action Report automatically if AAR tracking is
running. Tracking starts on its own from `initServer.sqf` via
`[] call Waldo_fnc_AARTrack`, which registers a single `EntityKilled`
handler (fires on all machines, so server-side registration still captures
every kill). If `Waldo_AAR_StartTime` is unset, ENDEX just omits the AAR
block — no separate toggle needed for the common case.

```sqf
Waldo_ENDEX_ReportDuration // seconds the combined end report stays visible, default 45
```

## What the AAR reports

Duration, KIA per side, player losses, vehicles lost per side, WIA per side,
friendly-fire incidents, confirmed deaths, an objective summary, and a
top-fraggers leaderboard. Each line is omitted automatically when its tally
is empty — nothing to configure there.

- Vehicle losses / friendly fire / fraggers all come from the same
  `EntityKilled` handler reading `_killer`/`_instigator`: same-side kill =
  friendly fire; enemy kill by a human player feeds the leaderboard
  (`Waldo_AAR_Frags`).
- Confirmed deaths (`Waldo_AAR_Obituary`) is a separate, later tally fed by
  the medic "Pronounce Dead" action, not by `EntityKilled` — see
  `obituary.md`. Listed alphabetically by victim name with a count, not as a
  leaderboard.
- **WIA requires ACE medical.** An `ace_unconscious` listener in `init.sqf`
  forwards each unit's first unconsciousness to the server via
  `Waldo_fnc_AARWound`. Without ACE medical loaded, WIA simply won't count —
  not a bug, just a dependency to be aware of.
- Objective summary populates automatically from `Waldo_fnc_CreateObjective`
  / `Waldo_fnc_SetObjectiveState` (see `tasks.md`) — no separate wiring.

## Custom end screen

Configure `CfgDebriefing` → `End1` in `description.ext`, then trigger with:

```sqf
[[], "End1"] call BIS_fnc_endMission;
```

## Relationship to Safestart

ENDEX and Safestart keep separate authoritative state — a Safestart lift
never removes an active ENDEX freeze. For rehearsals/QA,
`[] call Waldo_fnc_ENDEXReset` removes ENDEX-owned handlers without lifting
an active Safestart. See `safestart.md`.
