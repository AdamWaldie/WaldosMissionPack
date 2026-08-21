# Mission Diagnostics

> **Use this page when:** you need structured server/client checks, feature state, or RPT evidence for a WMP setup.

_Associated Files: `initServer.sqf`, `MissionScripts\MissionFlowAndUi\runDiagnostics.sqf`, `runDiagnosticsClient.sqf`, `diagnosticsReceiveClient.sqf`, `Waldo_fnc_RunDiagnostics`_


Mission Diagnostics is a read-only health check for WaldosMissionPack. The server starts each run, checks authoritative configuration and runtime state, requests a local report from every connected player, then publishes one structured result for audit tools and JIP clients.

Diagnostics never enables, disables, repairs, or resets a feature. A hosted server shows warnings in `systemChat`. A dedicated server writes the full report to its RPT.

## Log format

Every RPT line uses the same frame:

```text
[WMP DIAG][run=412-830114][node=SERVER][area=LOGISTICS][feature=MHQ-RUNTIME][level=INFO][event=CHECK] state=LOADED detail=configured=1 deployed=0
```

| Field | Meaning |
|---|---|
| `run` | One identifier shared by the server and every responding client. |
| `node` | `SERVER` or `CLIENT:<owner id>`. |
| `area` | The owning feature area, such as `LOGISTICS`, `ELECTRONIC-WARFARE`, or `INTERACTIONS`. |
| `feature` | The exact API, subsystem, or runtime surface being checked. |
| `level` | `INFO`, `WARN`, or `ERROR`. |
| `event` | `BEGIN`, `SECTION`, `CHECK`, `RECEIVED`, `SUMMARY`, `TIMEOUT`, `REJECT`, or `END`. |

Search by run ID to isolate one complete report. Search by `node=CLIENT:` for local UI and interaction failures, or by `level=WARN` and `level=ERROR` for action items.

## States

Each check reports one of these states in its message:

| State | Meaning |
|---|---|
| `LOADED` | Code is available and the feature is ready, but it is not currently active. |
| `ACTIVE` | The feature is running or has live mission state. |
| `DISABLED` | Mission configuration explicitly disabled the feature. |
| `UNCONFIGURED` | The feature is available, but the mission has no configured instance or data. |
| `UNAVAILABLE` | An optional dependency or expected runtime component is absent. |
| `ERROR` | Required code, configuration, initialization, UI state, or integration is broken. |

`DISABLED` and `UNCONFIGURED` are not failures. This distinction prevents an unused system from being reported as broken.

## Coverage

The server report checks:

- representative public APIs from mission flow, logistics, world UI, electronic warfare, party games, interaction equipment, the economy, headless-client support, object scaling and the feature runtime control bridge;
- required and optional mod patches;
- mission loadout scraping and playable-side results;
- configured crate, parachute, and paradrop values;
- ACRE2 configuration, authoritative plan schema/revision, group counts and Babel readiness;
- Economy, party-game, interaction-procedure, jamming, SafeStart, AAR/ENDEX, Obituary, headless-client, and custom 3D-marker state;
- configured MHQ, VVD and Field Hospital equipment;
- recovery workshops, carriers, attached/virtual package state, Field Resupply hubs/carriers and Tactical Displays;
- Hazard evaluator/audio state, typed helicopter/ground transport registries, and server/JIP registry parity for Dynamic AA, Dynamic AO and gunships;
- Paradrop, in its own dedicated section: static-line/HALO altitude and chute-class thresholds, how many auto-detected jump-capable aircraft in the mission carry a server-visible static/HALO hold-action versus neither, the split between `Waldo_fnc_AddVehicleFunctions` auto-detection and a mission maker's own explicit setup call, and Dynamic Drop Zone registry/JIP parity;
- the Feature Runtime Control snapshot handshake (`Waldo_FeatureRuntimeStateReady`) that JIP and headless clients depend on before activating locality-sensitive optional features;
- Object Scaling's configured min/max bounds and how many mission objects currently carry a non-default scale;
- Corpse Traps' `Waldo_CorpseTraps_Enable` state, its ACE Interact dependency, and how many corpses in the mission are currently rigged;
- ACE and Zeus integration availability.

Each interface client reports:

- its own CBA, ACE, ZEN, ACRE2, and TFAR patch state;
- its raw and normalized ACRE callsign, side/group plan match, carried unique radios, loadout generations and last presetting result;
- SafeStart state, loop, timer, and HUD;
- jamming factor, registry, client loop, and HUD;
- core and Economy Zeus module registration counts;
- the custom 3D-marker renderer;
- ACE or vanilla interaction installation on registered audit fixtures;
- Tactical Display actions, WMP HUD eligibility/runtime state, transport actions, Field Hospital action installation and Hazard snapshot/evaluator state;
- whether the Feature Runtime Control snapshot has arrived on this machine, and whether the locally applied UI Theme matches the authoritative one it carries;
- the Accessibility self-interaction menu's install mode (ACE/vanilla) and this player's resolved colour-vision profile;
- the Emergency Dismount monitor loop and, when Corpse Traps is enabled, whether this client actually installed the "Rig Corpse" interaction;
- Obituary's "Pronounce Dead" action install state (vanilla Medic trait or ACE Medic/Doctor role) and its local diary render loop;
- this client's full mission-critical loadout/respawn trace, six rows in the order the flow actually runs so a bad respawn can be pinpointed to the exact stage:
  - `respawn`/`baseline-capture`: whether `initPlayerLocal.sqf` has finished waiting for `player` to exist and captured the mission-start snapshot, plus how long it waited. This wait never gives up, so a stuck client shows `ERROR` here indefinitely rather than silently missing a baseline forever.
  - `respawn`/`triggers`: fire counts this session for each of the two independent restore triggers - Bohemia's local `"Respawn"` handler and a `CBA_fnc_addPlayerEventHandler "unit"` watchdog. `ERROR` specifically means this client has respawned successfully but only ever via the watchdog - restores still work, but it surfaces the known engine quirk where the native handler doesn't fire in some environments.
  - `respawn`/`snapshot`: the saved `Waldo_Player_RespawnSnapshot`'s age, source, loadout/radio entry counts, and whether it carries the apply-verification canary.
  - `respawn`/`loadout-restore`: whether the saved identity (UID+side) matched, how many loadout entries were restored, which trigger performed it, the snapshot's source/age at restore time, and the ACRE loadout generation - `UNCONFIGURED` before this client's first respawn of the session, `ERROR` on an identity mismatch (baseline retained instead of the saved loadout).
  - `respawn`/`loadout-apply-verify`: whether `setUnitLoadout` was confirmed to actually take effect - checked against a small set of stable, ACRE-independent equipment commands (not a raw `getUnitLoadout` comparison, which can't detect a no-op) - and how many retries it needed. `ERROR` only when it never took even after retrying.
  - `respawn`/`radio-restore`: whether the saved ACRE radio state reapplied, fell back to the current mission plan, or there was no complete radio snapshot to restore.
- this client's own intro-sequence timing (`mission-flow`/`infotext-timing`): real measured seconds waiting for Arma's initial local `PreloadFinished` event, the subsequent player/display readiness, WMP's short setup cover, when control was available, and how much longer the cosmetic title kept typing. The client state is recorded for diagnosis but is not used as a readiness gate. `ERROR` means the initial preload event or usable local player/display never arrived within its bounded wait. The intro does not wait for `WALDO_INIT_COMPLETE` or any unrelated feature. See [Mission Intro and Title Text](Mission-Intro-Or-Title-Text) for the sequence.

The server rejects stale reports and reports whose claimed owner does not match the sending client. Missing client responses become warnings after four seconds.

**Related, but not a diagnostic check:** `initPlayerLocal.sqf` also calls
`Waldo_fnc_AceSetNameRespawnBindingRepair` after CBA/ACE initialise, patching a real ACE 3.21.1 bug
rather than merely reporting it - ACE's own respawn hook forwarded the engine's `[unit, corpse]`
respawn payload wholesale into `ace_common_fnc_setName`, whose untyped `_forceSet` parameter then
received the corpse object and threw `Type Object, expected Bool` on every scripted respawn (a known
upstream issue, fixed directly by ACE in `community/ACE3#11470`, targeted for release 3.21.2). The
repair inspects the local player's compiled respawn callback and replaces it only if it still carries
the broken pattern; it also recognises ACE's own upstream-fixed callback text as already safe, so it
is a no-op once a mission's ACE build already has the fix. This is not surfaced as a diagnostics row -
check the RPT for `[WMP ACE COMPAT]` lines directly if you need to confirm it ran.

## Assistive hints

Every check that reports `ERROR` - across the server report, every interface client's report, and
every feature's own `*GetDiagnostics.sqf` - carries a short, plain-language remediation hint
alongside its terse `state=`/`detail=` pair: not just *that* something is wrong, but *what to go and
change*. This is systematic, not opt-in: a check that reports "the ACE dependency this optional
feature needs isn't loaded," "this client failed to install its local action," or "this registry and
its JIP mirror have drifted apart" always names the actual variable, function, or file to look at
next, aimed at a mission maker new to the pack rather than someone who already knows WMP's internals.
`DISABLED` and `UNCONFIGURED` states are not failures and never carry a hint - only a genuine `ERROR`
(or the rare `UNAVAILABLE` that reflects a real misconfiguration) does.

A hint is folded into the same `detail` text as `"; fix: <hint>"` by the shared
`Waldo_fnc_DiagnosticFoldHint` helper, so it reaches every existing consumer (RPT,
`Waldo_Diagnostics_LastReport`, the hosted-server `systemChat` line) without changing the
`[area, feature, state, detail]` report shape, and reads identically no matter which of the three
call sites folded it in:

```sqf
// A check built directly in runDiagnostics.sqf (server) or runDiagnosticsClient.sqf (client) passes
// the hint as the helper's own trailing argument:
[_category, _name, _state, _detail, _warn, _hint] call _status;   // runDiagnostics.sqf
[_area, _feature, _state, _detail, _hint] call _add;              // runDiagnosticsClient.sqf

// A feature's own *GetDiagnostics.sqf builds its check rows directly, so it folds the hint into its
// own detail string before pushing the row:
if (!_valid) then {_detail = [_detail, "Set Waldo_Example_Class to a real CfgVehicles class."] call Waldo_fnc_DiagnosticFoldHint;};
_checks pushBack ["area", "feature", _state, _detail];
```

For example, an invalid `WALDO_STATIC_STATICCHUTE` pointing at the RHS-only default without RHS
loaded reports the exact variable to change and the vanilla fallback class to use, instead of just
"class not found."

## Enabling diagnostics

Diagnostics are enabled by default:

```sqf
missionNamespace setVariable ["Waldo_RunDiagnostics", true, true];
```

Set `Waldo_RunDiagnostics` to `false` in `MissionConfig\missionSystemsConfig.sqf` if you do not want the startup report in a released mission.

Run the check again from server code with:

```sqf
private _warningCount = [] call Waldo_fnc_RunDiagnostics;
```

The function returns the number of warnings. If it is called from unscheduled server code, it starts the check in a scheduled thread and returns `0` immediately.

Zeus can run the same read-only check during play from **WMP Interface & QA > Diagnostics - Run Full Pack Audit**. The module does not repair or change feature state; it requests the server run and tells the curator where to inspect the correlated RPT entries.

For an ACRE presetting failure, find `feature=ACRE-PLAYER-PRESETTING` in the affected client's RPT. The detail shows the callsign before and after separator normalization, side/group match, plan revision, current unique radios, saved-loadout generations and `lastApplication`. This distinguishes a callsign/config mismatch from radios that were absent, not yet unique, or deliberately restored from a saved personal state. ACRE's own conversion of carried radios and WMP's own plan application are both bounded-but-asynchronous (default 120s, `readinessTimeoutSeconds`), so this check reports `LOADED` rather than `ERROR` while conversion is still genuinely in progress with no recorded failure yet - running Diagnostics again a few seconds later, or right after a respawn/side-switch, can catch this transitional state. It only escalates to `ERROR` once ACRE itself reports ready but the plan still didn't apply, or WMP's own bounded wait already timed out once.

Other WMP systems can write a line with the same frame without starting a full diagnostic run:

```sqf
["logistics", "custom-supply-point", "INFO", "READY", "crateCount=4"] call Waldo_fnc_DiagnosticLog;
```

The helper fills in the active run ID and local machine role. It returns the completed line after writing it to the local RPT.

## Feature diagnostic helpers

Individual systems expose read-only reports in the same normalized format. They are safe to call without changing mission state:

```sqf
private _safeStart = [] call Waldo_fnc_SafeStartGetDiagnostics;
private _endex = [] call Waldo_fnc_ENDEXGetDiagnostics;
private _economy = [] call Waldo_fnc_EcoCore_getDiagnostics;
private _equipment = [] call Waldo_fnc_MiniGameInteractionGetDiagnostics;
private _headless = [] call Waldo_fnc_HeadlessGetDiagnostics;
private _obituary = [] call Waldo_fnc_ObituaryGetDiagnostics;
```

Each returns `[featureName, checks]`; every check is `[area, feature, state, detail]`. The interaction helper optionally accepts an array of configured equipment objects. `RunDiagnostics` consumes these same helpers, preventing its interpretation from drifting away from the feature's own health report.

A feature small enough to be a single config flag (Corpse Traps, Object Scaling, Emergency
Dismount's client loop, the Feature Runtime Control snapshot, UI Theme, Accessibility) does not need
its own `*GetDiagnostics.sqf` - it adds one inline `[area, feature, state, detail]` row directly in
`runDiagnostics.sqf` (server) or `runDiagnosticsClient.sqf` (interface client), through the same
`_status`/`_add` helper every other row in that script already uses. Either shape ends up going
through `Waldo_fnc_DiagnosticLog`'s frame, so a new module's rows read exactly like every other
module's - the `area`/`feature` values are the only thing that should ever identify which module a
line belongs to.

## Structured result

The latest result is broadcast as `Waldo_Diagnostics_LastReport`:

```sqf
private _result = missionNamespace getVariable ["Waldo_Diagnostics_LastReport", []];
_result params ["_warningCount", "_finishedAt", "_serverChecks", "_clientReports", "_runId"];
```

The first three fields remain compatible with earlier consumers. A server check is:

```sqf
[area, feature, state, detail]
```

A client report is:

```sqf
[ownerId, playerName, playerUid, checks, receivedAt]
```

## See also

- [Logistics System, Starter Crates And Quartermaster](Logistics-System,-Starter-Crates-And-Quartermaster)
- [Mission Configuration Reference](Mission-Configuration-Reference)
- [Vehicle Actions & Paradrop](Vehicle-Actions-&-Paradrop)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
