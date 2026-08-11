# Mission diagnostics

Read-only server + client health check at mission start, run after the
loadout scan. Every RPT entry uses one searchable frame:

```
[WMP DIAG][run=...][node=SERVER|CLIENT:<owner>][area=...][feature=...][level=...][event=...]
```

A hosted server also surfaces warnings via `systemChat`.

## Config (`MissionConfig\missionSystemsConfig.sqf`)

```sqf
// Set false to silence startup diagnostics in a released mission.
["Waldo_RunDiagnostics", true, true],  // server entry, JIP-published
```

This is a `server` entry loaded by `initServer.sqf` — edit the config file,
don't paste a `setVariable` call into `initServer.sqf` yourself.

For a released/live mission (not QA), it's reasonable to suggest setting
this `false` to avoid RPT noise and player-facing warning chat — mention
this as an option rather than a default recommendation, since it's also
useful for the user to leave on while first configuring the pack.

## What it checks

Distinguishes `LOADED`, `ACTIVE`, `DISABLED`, `UNCONFIGURED`,
`UNAVAILABLE`, `ERROR`. Covers representative public APIs, mod dependencies,
loadouts, configured classes, mission flow, MHQ, VVD, electronic warfare,
party games, interaction equipment, Economy, Headless Client, Obituary,
Zeus registration, the Feature Runtime Control snapshot handshake, Object
Scaling, UI Theme, Accessibility, Emergency Dismount, Corpse Traps, local
HUD state, 3D markers, and ACE-vs-vanilla actions.

The latest report broadcasts as `Waldo_Diagnostics_LastReport`:
`[warningCount, finishedAt, serverChecks, clientReports, runId]` — useful if
scripting something that should wait for or react to the diagnostic pass.

## Assistive hints

Every `ERROR` check names the actual variable/function/file to go fix, not
just that something is wrong — folded into the same `detail` text as
`"; fix: <hint>"` (`Waldo_fnc_DiagnosticFoldHint`). When walking a user
through a failing check, read and relay that `fix:` clause directly instead
of guessing at a remediation — it's already written for a newcomer.
`DISABLED`/`UNCONFIGURED` are expected, not failures, and never carry one.
