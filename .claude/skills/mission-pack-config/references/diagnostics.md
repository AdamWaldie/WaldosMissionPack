# Mission diagnostics

Read-only server + client health check at mission start, run after the
loadout scan. Every RPT entry uses one searchable frame:

```
[WMP DIAG][run=...][node=SERVER|CLIENT:<owner>][area=...][feature=...][level=...][event=...]
```

A hosted (listen-server) host also surfaces warnings and the completion summary via `systemChat`
directly. On a genuine dedicated server (no console of its own), the same lines are instead
remote-executed to every currently assigned curator's client, so an admin watching through Zeus
still gets in-game visibility rather than only RPT — see `Waldo_fnc_HeadlessDebugLog` for the
identical pattern used by headless-client debug output.

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

A respawn-focused client check, `respawn`/`loadout-restore`, reports the last
respawn's identity-match outcome and restored item count (`UNCONFIGURED`
before this client's first respawn, `ERROR` on an identity mismatch).

Separately, not a diagnostics row: `initPlayerLocal.sqf` also calls
`Waldo_fnc_AceSetNameRespawnBindingRepair` after CBA/ACE initialise, which
patches a real ACE 3.21.1 bug (its own respawn hook forwarding `[unit,
corpse]` wholesale into `ace_common_fnc_setName`, throwing "Type Object,
expected Bool" on every scripted respawn - fixed upstream in
`community/ACE3#11470`, targeted for 3.21.2) rather than only reporting it.
It recognises ACE's own fixed callback text as already safe, so it is a
no-op once a mission's ACE build already has the fix. Check RPT for
`[WMP ACE COMPAT]` lines to confirm it ran.

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
