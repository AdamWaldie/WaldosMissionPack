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

- representative public APIs from mission flow, logistics, world UI, electronic warfare, party games, interaction equipment, and the economy;
- required and optional mod patches;
- mission loadout scraping and playable-side results;
- configured crate, parachute, and paradrop values;
- ACRE2 channel configuration;
- Economy, party-game, interaction-procedure, jamming, SafeStart, AAR/ENDEX, and custom 3D-marker state;
- configured MHQ and VVD equipment;
- ACE and Zeus integration availability.

Each interface client reports:

- its own CBA, ACE, ZEN, ACRE2, and TFAR patch state;
- SafeStart state, loop, timer, and HUD;
- jamming factor, registry, client loop, and HUD;
- core and Economy Zeus module registration counts;
- the custom 3D-marker renderer;
- ACE or vanilla interaction installation on registered audit fixtures.

The server rejects stale reports and reports whose claimed owner does not match the sending client. Missing client responses become warnings after four seconds.

## Enabling diagnostics

Diagnostics are enabled by default:

```sqf
missionNamespace setVariable ["Waldo_RunDiagnostics", true, true];
```

Set the value to `false` in `initServer.sqf` if you do not want the startup report in a released mission.

Run the check again from server code with:

```sqf
private _warningCount = [] call Waldo_fnc_RunDiagnostics;
```

The function returns the number of warnings. If it is called from unscheduled server code, it starts the check in a scheduled thread and returns `0` immediately.

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
```

Each returns `[featureName, checks]`; every check is `[area, feature, state, detail]`. The interaction helper optionally accepts an array of configured equipment objects. `RunDiagnostics` consumes these same helpers, preventing its interpretation from drifting away from the feature's own health report.

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
