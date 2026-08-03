# Performance And Optimisation Audit

> **Use this page when:** you need to understand the static performance guardrails, reviewed findings, or required in-engine verification.

_Associated Files: `releaseVerificationAndDeployment/performance_audit.py`, `performance_baseline.json`, `MissionScripts/MiniGames/engine/core.sqf`, `MissionScripts/EconomySystems/Core/startRequestScheduler.sqf`_

This audit protects WaldosMissionPack from accidental scheduler, world-scan, UI-redraw and network regressions. It is based on static SQF evidence: it counts opportunities for expensive work, but it does **not** claim measured FPS, bandwidth or dedicated-server timing improvements. Those measurements require an in-engine multiplayer test.

## What changed

| Area | Pre-audit baseline | Audited implementation | Static effect |
|---|---:|---:|---|
| Scanner findings | 82 | 69 | 13 recurring-pattern findings removed |
| High-severity findings | 12 | 6 | 6 removed; all remaining findings have reviewed reasons |
| Recurring world-scan findings | 17 | 8 | 9 removed |
| Loops without a nearby recognised single-start guard | 50 | 45 | 5 removed; remaining medium findings require human review |
| Economy request schedulers | 6 | 1 | One ordered authority pass replaces six independent pollers |
| High-frequency economy object world scans | 4 `allMissionObjects` plus 1 `vehicles` | 0 | Typed registries are used between 10-second recovery scans |
| Party-table game dispatches per 0.5-second authority tick | 16 calls for every table | 0 in lobby; 1 reconcile plus an optional game-specific progression call | Work scales with the active game instead of the catalogue |
| Unchanged table-consensus publication | 8 broadcasts | 0 broadcasts | Values are compared before publication; revision changes once per logical update |

The scanner total includes intentional animated interfaces and optional bundled scripts, so the goal is not zero findings. The goal is to prevent unexplained or expanding high-risk patterns.

## Party games

The server still validates seats every authority tick and still processes the existing tokenized request variables. Game-specific departure reconciliation and timed progression now dispatch through the active game ID. A lobby table therefore performs no game reconciliation, while a running table invokes only the selected ruleset.

Table consensus variables remain JIP-safe public object variables. The server now publishes an individual value only when it changed and advances `Waldo_MG_TableRevision` once if any consensus value changed. Five-Card Draw and Liar's Dice also use public revision plus private-hand/dice render keys to avoid repainting unchanged controls without suppressing private-state resynchronization.

No seating, voting, readiness, spectator, game-rule, request-token or hidden-state contract changed.

## Economy systems

The economy remains off by default. When enabled, live objects are registered under these internal JIP-safe collections:

| Registry | Contents |
|---|---|
| `CRATES` | Resource crates |
| `RESEARCH_CENTERS` | Research and construction terminals |
| `CONSTRUCTION_VEHICLES` | Mobile construction sources |
| `PURCHASE_TERMINALS` | Buy-system laptops |
| `BUILDINGS` | Spawned economy buildings |

Creation and mission-maker registration functions add objects immediately; deletion handlers remove them. A server recovery pass every 10 seconds discovers tagged editor, Zeus or external-script objects and prunes invalid entries. This recovery behavior protects JIP and dynamic missions without searching the complete world every 0.25 seconds.

The consolidated authority scheduler preserves the previous order and request variables: player zone/research requests, zone anchors, crates, research centres, construction vehicles, buildings and purchase terminals. Client actions update when the registry revision changes and receive a 10-second repair pass in case another script removed an action.

Mission makers do not need to change existing calls such as `Waldo_fnc_EcoResearch_registerCenter`, `Waldo_fnc_EcoBuild_registerConstructionVehicle` or `Waldo_fnc_EcoBuy_registerTerminal`.

## Interaction procedures and UI

Interaction loops were reviewed separately from state redraws. Lockpick motion remains at its existing physical update rate; wire-cut, minesweeper and shared completion effects remain short-lived and display-guarded. The exclusive interaction watchdog exits on resolution, object loss, disconnect, death or timeout, while the client watchdog exits on resolution or display loss and clears its attempt-local state.

These loops are intentionally retained because lowering them without frame-time measurements risks making equipment less responsive. The authoritative `IDLE` / `RUNNING` / `SUCCESS` / `FAILURE` state contract and ACE-first integration are unchanged.

## Repository-wide review

| Subsystem | Static review result |
|---|---|
| Mission startup and configuration | Loadout, class/config and ACRE setup scans are one-shot. No recurring change was justified without runtime evidence. |
| AI, SafeStart and mission flow | Persistent work is feature-gated and delayed; no public timing or behavior was changed. |
| Logistics and VVD | Interactive display/damage loops are bounded by display, vehicle or completion state. VVD remains WIP and needs in-engine profiling before cadence changes. |
| Party games | Active-game dispatch, change-gated consensus and safe hidden-state redraw gating applied. |
| Interaction equipment | Temporary display and ownership watchdogs have explicit terminal conditions; physical update rates retained. |
| Economy | High-frequency object searches replaced by registries and six request pollers consolidated. |
| Network/locality/JIP | Public state remains server-authored and broadcast only where required; private cards/dice and attempt ownership remain owner-targeted. |
| Optional bundled scripts | Findings recorded separately; behavior remains untouched and the systems remain off by default. |

## Automated guardrail

Run the same checks as CI from the repository root:

```text
python3 releaseVerificationAndDeployment/performance_audit.py
python3 -m unittest discover -s releaseVerificationAndDeployment -p "test_performance_audit.py" -v
```

The scanner removes comments and string contents before analysing `while` bodies. Findings are assigned to a path and enclosing named SQF function. It detects unbounded schedulers, tight loops, recurring broad searches, recurring broadcasts/remote execution and high-frequency control redraws.

`performance_baseline.json` accepts only reviewed high-severity findings. A new finding, an increased count, or a placeholder explanation fails CI. Do not regenerate the baseline merely to make CI green: remove the regression or document why the pattern is required.

## Remaining findings and follow-ups

- The consolidated economy scheduler still inspects `allPlayers` every 0.25 seconds because the backward-compatible public contract stores requests on player objects. Replacing that contract with server events is a higher-risk follow-up.
- The interaction lock watchdog contains terminal remote calls inside a recurring block. They are exactly-once exit branches, not unconditional per-tick traffic.
- The optional player-marker and headless-client packages retain their existing polling behavior. They are reported but were not modified.
- VVD and several equipment displays intentionally refresh during an active, visible operation. In-engine profiling is required before changing their cadence.

## Manual runtime verification still required

Before describing these static reductions as measured performance gains, test a dedicated server with representative player, table, zone and equipment counts. Record server FPS, scheduled script time and network traffic during idle, active-game and economy-load scenarios; include JIP, disconnects, deleted objects and long-session cleanup. Test 30, 60 and 120 client FPS for interaction smoothness.

## See also

- [Mission Diagnostics](Mission-Diagnostics)
- [Waldos Economy Systems](Waldos-Economy-Systems)
- [Waldos Mini Games](Waldos-Mini-Games)
- [Third-Party Scripts](Third-Party-Scripts-Headless-Client-And-Player-Markers)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
