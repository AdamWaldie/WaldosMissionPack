# Performance And Optimisation Audit

> **Use this page when:** you need to understand the static performance guardrails, reviewed findings, or required in-engine verification.

_Associated Files: `releaseVerificationAndDeployment/performance_audit.py`, `performance_baseline.json`, `MissionScripts/MiniGames/engine/core.sqf`, `MissionScripts/EconomySystems/Core/startRequestScheduler.sqf`_

This audit protects WaldosMissionPack from accidental scheduler, world-scan, UI-redraw and network regressions. It is based on static SQF evidence: it counts opportunities for expensive work, but it does **not** claim measured FPS, bandwidth or dedicated-server timing improvements. Those measurements require an in-engine multiplayer test.

## Engine and WMP boundary

Every optimisation must first identify which side owns the behaviour. Arma owns world-object replication, object/group locality, object-bound JIP lifetime and ordinary simulation transfer. WMP owns feature rules, server transactions, private game information, UI and the installation of client-local ACE actions. Boundary operations are executed once on the machine where the affected object, group or UI is local.

An optimisation may remove a WMP path only when an isolated test proves that the engine supplies the same state, audience, timing, JIP replay and cleanup. WMP must not continuously reproduce engine state, while engine replication must not be mistaken for client-local side effects such as adding an ACE action. Security, BattlEye and remote-execution policy are outside this performance audit.

## Documented implementation changes

| Date | Change | Engine intersection | Preserved behaviour | Evidence required |
|---|---|---|---|---|
| 31 August 2026 | Tree-felling ACE drag/carry JIP entries now use the fallen object as their JIP key instead of creating an independent permanent entry. | Arma owns the object's JIP lifetime and removes object-keyed replay when the object is deleted; WMP still requests ACE's local action setup. | Current and joining players can drag/carry the same eligible logs with the same offsets and size rule. Tree hits, yields and regrowth are unchanged. | Static regression assertion plus dedicated current-client/JIP drag, carry, deletion and regrowth checks. |
| 31 August 2026 | Removed the MiniGames public table-registry event listener that could request metadata already delivered by live registration. | Arma replays public table membership/object variables before JIP event scripts. WMP performs one canonical metadata request from `initPlayerLocal`; tables registered later still use the existing direct local-registration call. | Initial, JIP, hosted and runtime-created table actions use the same metadata and remain repeat-safe. Game state, rules and seating are unchanged. | Static single-request assertion plus dedicated initial/JIP/runtime-registration action checks. |
| 31 August 2026 | MiniGames registration now clears/publishes initial state only for games enabled on that table. | Arma replicates the custom variables WMP writes but does not choose the table's game catalogue. WMP uses the already validated `Waldo_MG_TableGames` list to decide which initial states exist. | Empty `games` still expands to all twelve games and follows the original full initialization path. A subset table exposes and initializes exactly that subset; rules and later transitions are unchanged. | Static all-game dispatch assertion plus dedicated all-games and subset-table registration/JIP checks. |
| 31 August 2026 | Economy bootstrap no longer publishes a default `ModulePurgedForJIP=false` value from every machine. | Arma replays the server's public purge value before JIP event scripts; WMP reads that value before local bootstrap instead of replacing it. A missing value still uses the existing fresh-mission default of false. | Fresh enabled missions initialize normally. Purged missions remain purged for current and joining clients. Economy calculations, UI and operator controls are unchanged. | Static no-client-write assertion plus dedicated fresh-start, purge, JIP-after-purge and re-enable checks. |

> **Current network verdict:** the seated MiniGames transport does not yet pass its network acceptance gate. The request endpoint and change notifications are targeted, but authoritative game state is still published through global, persistent object variables. Do not describe the MiniGames replacement as network-complete until that state transport is replaced and measured under representative multiplayer load.

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

Seated MiniGames now activate only through `Waldo_fnc_MiniGamesRegisterTable`; there is no automatic class discovery or mission-wide startup. With no registered table, the seated engine performs no runtime compilation, background work or state traffic.

Each player action uses one named server request. The authority authenticates the actor owner and validates the table, range, seat, phase, epoch, turn, payload and duplicate token before adding it to that table's drain-on-demand queue. Registered idle tables have no request poller or recurring reconciliation. Timed rules use epoch-guarded one-shot callbacks, and client UI refresh exists only while the corresponding display is open.

JIP table discovery and action requests use named functions rather than executable payloads. Private hand variables that use a player-owner target are correctly targeted. However, the 31 August 2026 static review found 532 three-argument `setVariable [..., true]` publication sites in the game files, including complete Battleship, Blackjack, Poker, Shotgun Roulette, Who's Who and UNO snapshots. Chess, Checkers, Connect Four, Liar's Dice and Rock Paper Scissors publish multiple individual fields globally during state changes. These values are persistent and therefore also enlarge JIP state.

This is WMP-created traffic, not engine object simulation that can safely be omitted. Arma automatically synchronises supported world-object properties; it cannot infer custom board rules, cards, turns or hidden information. WMP therefore needs custom transport, but that transport must be one server-private authoritative state plus compact, revisioned snapshots targeted only to seated players and subscribed spectators.

Registration currently adds an avoidable burst: marking a table clears and globally publishes empty state for all twelve games before a game is selected. The server also sends registration metadata directly while the public table-registry event can cause connected clients to request the same metadata again. Locality, deletion and display handlers do not themselves generate network traffic and must not be removed merely because they are handlers.

No seating, voting, readiness, spectator, game-rule or hidden-state intent changed. Runtime acceptance still requires dedicated-server, JIP, disconnect and headless-client locality tests under representative table load.

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
| Network/locality/JIP | Request authentication and owner-targeted private variables are present, but MiniGames public state is still broadcast more widely than required. Network acceptance failed pending targeted snapshots and multiplayer measurement. |
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
- MiniGames has 579 static three-argument global-publication sites across registration, core and game code; 532 are in game files. A source site may execute zero, one or many times, so this is not a packet count. It is direct evidence that the current design can fan state changes out to every client and persist them for JIP.
- An end-user report described average traffic of "6-9 MB" with "40-50 MB" peaks. Those values require the monitoring interval, direction and whether the unit means MB or Mb before they can be converted to throughput. They cannot represent individual network packet sizes. Existing audit `mpStatistics` logs contain aggregate engine message counts but no per-feature byte attribution, so the report is credible evidence of a serious symptom but not proof that MiniGames caused all of it.
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
