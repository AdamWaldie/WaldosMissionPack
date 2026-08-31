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
| 31 August 2026 | Tree-felling ACE drag/carry replay now uses one combined WMP setup entry keyed to the fallen object. | Arma owns the object's JIP lifetime and removes object-keyed replay when the object is deleted. Because one object key is one replaceable slot, the combined local function applies both ACE properties without one replacing the other. | Current and joining players can drag/carry the same eligible logs with the same offsets and size rule. Tree hits, yields and regrowth are unchanged. | Static single-entry regression assertion plus dedicated current-client/JIP drag, carry, deletion and regrowth checks. |
| 31 August 2026 | Removed the MiniGames public table-registry event listener that could request metadata already delivered by live registration. | Arma replays public table membership/object variables before JIP event scripts. WMP performs one canonical metadata request from `initPlayerLocal`; tables registered later still use the existing direct local-registration call. | Initial, JIP, hosted and runtime-created table actions use the same metadata and remain repeat-safe. Game state, rules and seating are unchanged. | Static single-request assertion plus dedicated initial/JIP/runtime-registration action checks. |
| 31 August 2026 | MiniGames registration no longer constructs or publishes empty game instances. | Arma replicates WMP's custom game variables but does not need placeholder state for a game that has not started. The selected game's existing start function constructs its complete state immediately before activation. | Lobby discovery, voting and readiness are unchanged. Once a game starts, its state publication, transitions, UI and spectator viewing use the existing live path without a reduced cadence. | Static no-idle-initialisation assertion plus later all-games, subset-table, live-view and spectator-flow checks. |
| 31 August 2026 | Active MiniGames public game state now uses Arma's native owner-ID recipient arrays instead of global persistent publication. | Arma still transports each existing variable mutation, but only to seated player owners and explicitly subscribed spectator owners. Forty-one `TablePhase` publications remain global as the compact discovery/JIP summary. Spectators receive one targeted current-state snapshot before their display opens; snapshots contain only names previously registered by public game-state writes. | Every action, timer, turn, reveal, reset and revision retains its existing mutation and refresh timing. Live spectators receive the same deltas and state-change notifications. Server-only decks/hands/fleets/targets/dice and owner-targeted private values are unchanged. | Static 491-targeted/41-summary/private-state/subscription assertions plus all-twelve-game live spectator, JIP, disconnect and rematch validation. |
| 31 August 2026 | Economy bootstrap no longer publishes a default `ModulePurgedForJIP=false` value from every machine. | Arma replays the server's public purge value before JIP event scripts; WMP reads that value before local bootstrap instead of replacing it. A missing value still uses the existing fresh-mission default of false. | Fresh enabled missions initialize normally. Purged missions remain purged for current and joining clients. Economy calculations, UI and operator controls are unchanged. | Static no-client-write assertion plus dedicated fresh-start, purge, JIP-after-purge and re-enable checks. |
| 31 August 2026 | Economy player actions now send one non-persistent named function call directly to server authority instead of globally publishing request mailboxes and waiting for a quarter-second scanner. | Arma's remote-execution framework already provides direct server delivery and ordered execution. WMP retains the same request arrays, duplicate tokens, processors and transaction functions; the call is not stored for JIP. The ten-second runtime-registry recovery remains separate. | Zone capture, crate collection, research, construction, building claim/enable/disable/upgrade and purchasing retain their current UI, request payload and authoritative result paths. Existing processor function signatures are unchanged. | Static all-producer/dispatch/no-mailbox/no-poller assertions plus dedicated current-client, listen-host, JIP and repeated-request checks for every operation. |
| 31 August 2026 | Paradrop and Airborne Gunship live-marker refresh handlers now exist only while their published aircraft registries are non-empty. | Arma transports each custom registry but cannot create WMP's client-local markers or actions. One named registry-change listener covers either JIP arrival order without recurring idle work; the one-second marker refresh starts with the first entry and stops after the last. | Active aircraft retain the same live position/heading update cadence, side visibility, controller actions and JIP reconstruction. Empty missions and fully removed systems no longer run marker callbacks. | Static lifecycle/order assertions queued, followed by initial/JIP/create/remove/recreate and listen-host marker checks in the approved audit session. |
| 31 August 2026 | Breaching stop and empty Airborne Gunship publication now remove obsolete named JIP execution entries. | The engine retains named remote-execution entries until WMP replaces or removes them. A stopped feature or empty registry has no client-local activation to reconstruct; current clients still receive the existing disabled/cleanup state first. | Breaching remains disabled and its unremovable ACE bridge remains an inert no-op. Current gunship clients still remove markers/actions immediately; live gunship registration retains normal JIP reconstruction. | Static replay-removal assertions queued, followed by stop/remove-all, JIP-after-stop and re-enable/re-register checks in the approved audit session. |
| 31 August 2026 | Named starter-crate, Field Resupply and Tactical Display JIP action entries are now bound to their source object's deletion; deleted Field Resupply hubs also leave the public hub registry. | Arma offers one replaceable object-keyed JIP slot per object. These objects can require multiple independent persistent installers, so WMP retains distinct named entries and uses one server-side Deleted handler to remove every bound id. | Current/JIP actions, ACE/vanilla fallback, arsenal, hub stock, Tactical Display authentication and field-crate salvage are unchanged. Deletion no longer leaves dangling action payloads or hub membership for later joiners. | Static binding assertions queued, followed by normal/external deletion, JIP-after-delete and repeated registration checks in the approved audit session. |
| 31 August 2026 | Fallen trees now use one object-keyed WMP setup call that applies both ACE drag and optional carry policy. | Arma replaces an earlier JIP statement when the same object key is reused. Combining both local ACE operations into one call preserves automatic deletion cleanup without allowing carry setup to replace drag setup. | Current and joining players retain drag on every eligible fallen tree and carry on the existing under-eight-metre subset, with the same offsets and rotations. | Static single-call assertion queued, followed by large/small tree, current-client, JIP and deletion checks in the approved audit session. |
| 31 August 2026 | Economy object-action JIP entries now follow the lifetime of their crates, terminals, research centres, construction vehicles, buildings and zone anchors. | Economy requires multiple independent action replays on some objects, so it retains distinct named ids rather than colliding in Arma's one object-keyed slot. The shared deletion binder removes those ids when the object disappears; explicit action clearing also unbinds the id. | Economy calculations, catalogues, UI, ACE/vanilla actions, request formats, operator controls and object registration remain unchanged. Normal and external object deletion no longer leaves action installers for future joiners. | Static bind/unbind assertions queued, followed by each object type, external deletion, purge, JIP-after-delete and republish checks in the approved audit session. |
| 31 August 2026 | Economy testing-notice installation now reconciles current human players once and follows player connection and respawn events instead of scanning every player once per second for the mission lifetime. | Arma owns player connection and entity-respawn lifecycle events; WMP still owns installation of the client-local action. The server targets only the current player owner and stores no persistent JIP action because initial players, JIP and respawn are explicit lifecycle events. A bounded connection worker runs only until the joining player's object becomes available. Headless-client entities are excluded because they have no interface. | The same invisible, repeat-safe action, notice condition, token, text and audience are retained for initial players, human JIP and respawn. Other clients no longer receive setup for someone else's self-only action. Purge removes both handlers so re-enable cannot stack them. No Economy calculation, UI or operator workflow changes. | Static event/start/stop/owner-target/HC-exclusion assertions queued, followed by initial-player, JIP, respawn, HC, purge/re-enable and duplicate-action checks in the approved audit session. |
| 31 August 2026 | Economy client world-action reconciliation now responds to registry revision changes and uses an epoch-guarded ten-second repair callback instead of waking every half-second. | Arma transports the server's typed registries/revision, while WMP must still install ACE/vanilla actions locally. Remote clients respond to the revision event; a listen server requests the same coalesced refresh directly because publication does not replay to its publishing machine. Arma provides no removal command for public-variable event handlers, so one repeat-safe listener remains installed and is inert while the service is stopped. | Initial/JIP actions, runtime-created objects and the existing ten-second recovery from externally removed actions are retained. Same-frame registry bursts coalesce into one refresh. Purge disables the listener through the service-state guard and invalidates pending callbacks; re-enable performs a fresh reconciliation without adding another listener. | Static no-half-second-loop, single-listener, event, coalescing, listen-host and epoch-cleanup assertions passed; dedicated in-engine validation exposed and corrected the invalid removal assumption before the audit was rerun. |
| 31 August 2026 | Economy Ground Command identity publication now follows CBA's local player-unit event instead of checking identity every two seconds for the mission lifetime. | Arma/CBA owns the local player-object replacement lifecycle. WMP still publishes its derived owner/UID key, but only when initial/JIP setup, respawn or team switch requires it. A bounded 60-second one-shot retry chain preserves late UID resolution; generation and service epochs reject stale callbacks. | Ground Command keys and stored formats are unchanged. Initial players, JIP, respawn, team switch and fallback identities retain the same change-gated publication. Purge removes the exact CBA handler and re-enable republishes the current identity without duplicates. | Static event/removal/bounded-retry/change-gate assertions queued, followed by dedicated/listen initial, late-UID, respawn, team-switch, purge/re-enable and Ground Command permission checks. |

> **Current network verdict:** the known global MiniGames game-state fan-out has been removed in source, but network acceptance remains pending. Static evidence confirms targeted active-state delivery and non-persistent spectator snapshots; only representative dedicated multiplayer testing can establish bandwidth improvement and gameplay parity.

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
| Active game-state publication sites in game files | 532 global persistent sites | 491 seat/spectator-targeted sites plus 41 compact global `TablePhase` summary sites | Unrelated players and JIP clients no longer receive complete live game state |

The scanner total includes intentional animated interfaces and optional bundled scripts, so the goal is not zero findings. The goal is to prevent unexplained or expanding high-risk patterns.

## Party games

Seated MiniGames now activate only through `Waldo_fnc_MiniGamesRegisterTable`; there is no automatic class discovery or mission-wide startup. With no registered table, the seated engine performs no runtime compilation, background work or state traffic.

Each player action uses one named server request. The authority authenticates the actor owner and validates the table, range, seat, phase, epoch, turn, payload and duplicate token before adding it to that table's drain-on-demand queue. Registered idle tables have no request poller or recurring reconciliation. Timed rules use epoch-guarded one-shot callbacks, and client UI refresh exists only while the corresponding display is open.

JIP table discovery and action requests use named functions rather than executable payloads. Private hand variables that use a player-owner target are correctly targeted. The 31 August 2026 static review found 532 global persistent publication sites in the game files. Those sites represented WMP-created state rather than engine object simulation, so removing the state itself would break the games.

The game rules and variable readers remain unchanged. Of those 532 sites, 491 now pass an Arma machine-owner array as the native `setVariable` public target. The target list contains current seats plus server-private spectator subscriptions. The remaining 41 sites publish only `TablePhase`, which is the compact state required for an unseated client to discover that a game can be spectated and for JIP to reconstruct that summary. A spectator action first subscribes on the server, receives one non-JIP snapshot of the variable names that active public-state writers registered, opens only after applying it, and then receives every subsequent mutation and state-change notification. Closing the view unsubscribes immediately.

Server-only snapshots, decks, shoes, hands, fleets, targets, dice and choice data retain local/server storage. Owner-targeted private hand, fleet, peek, target and dice variables retain their existing owner targets. No update cadence was reduced, coalesced or delayed.

Registration previously added an avoidable burst by clearing and globally publishing empty game state before a game was selected. Registered tables now create only lobby state; the selected game's existing start function constructs the live instance when all required players ready. The server also no longer keeps a public table-registry event listener that could request metadata already delivered by direct registration. Locality, deletion and display handlers do not themselves generate network traffic and must not be removed merely because they are handlers.

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

Economy player actions now call one named server endpoint with the same target and request array previously placed in a public object variable. The endpoint dispatches immediately to the existing zone, crate, research, construction, building-management or purchase processor. Those processors keep their signatures, request-token windows and transaction functions. Requests are not global state and are not retained for JIP, so unrelated clients no longer receive request payloads or the later empty-value publication. The old quarter-second scanner no longer walks players and every Economy registry; its remaining startup adapter performs only the existing ten-second recovery of externally tagged objects.

Client actions update when the registry revision changes and receive a 10-second repair callback in case another script removed an action. Registry changes in the same frame are coalesced; clients no longer wake twice per second merely to compare an unchanged revision.

The optional server-testing notice no longer maintains a permanent one-second `allPlayers` loop.
Current players are reconciled once at Economy startup, while engine player-connect and respawn
events install the same action for later player objects. Installation is sent only to that player's
owner and is not retained in the JIP queue. This does not replace Economy request transport and does
not alter the notice shown to players.

Ground Command identity now publishes on initial setup and CBA's local `unit` lifecycle event. A
bounded readiness chain covers a multiplayer UID that is not available on the first frame. The
published `UID|...|OWNER|...` and `LOCAL|...` formats and all permission checks remain unchanged.

Mission makers do not need to change existing calls such as `Waldo_fnc_EcoResearch_registerCenter`, `Waldo_fnc_EcoBuild_registerConstructionVehicle` or `Waldo_fnc_EcoBuy_registerTerminal`.

## Interaction procedures and UI

Interaction loops were reviewed separately from state redraws. Lockpick motion remains at its existing physical update rate; wire-cut, minesweeper and shared completion effects remain short-lived and display-guarded. The exclusive interaction watchdog exits on resolution, object loss, disconnect, death or timeout, while the client watchdog exits on resolution or display loss and clears its attempt-local state.

These loops are intentionally retained because lowering them without frame-time measurements risks making equipment less responsive. The authoritative `IDLE` / `RUNNING` / `SUCCESS` / `FAILURE` state contract and ACE-first integration are unchanged.

## SafeStart JIP logic review

The reported stale-protection case is covered by the current ordered SafeStart state handshake.
`initPlayerLocal.sqf` requests one targeted server snapshot containing active state, reason, timer
deadline and revision. The client compares that revision with the last state it actually applied and
then applies either state, including an explicit inactive state that removes local weapon, damage,
confinement and HUD effects. This avoids depending on the arrival order of the public variables and
the earlier live transition call.

No recurring SafeStart network request or JIP executable entry was added. Respawn rebinds the
current locally applied state to the replacement player object. The dedicated/listen/JIP/reconnect
matrix remains queued because source inspection is not proof of the reported multiplayer outcome.

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

WMP does not install runtime performance telemetry. The repository scanner is an offline source
guardrail and does not execute in a mission. Runtime acceptance uses external engine/server
observations only during an explicitly approved test session, so the pack does not distort the
mission by continuously measuring itself.

Run the same checks as CI from the repository root:

```text
python3 releaseVerificationAndDeployment/performance_audit.py
python3 -m unittest discover -s releaseVerificationAndDeployment -p "test_performance_audit.py" -v
```

The scanner removes comments and string contents before analysing `while` bodies. Findings are assigned to a path and enclosing named SQF function. It detects unbounded schedulers, tight loops, recurring broad searches, recurring broadcasts/remote execution and high-frequency control redraws.

`performance_baseline.json` accepts only reviewed high-severity findings. A new finding, an increased count, or a placeholder explanation fails CI. Do not regenerate the baseline merely to make CI green: remove the regression or document why the pattern is required.

## Remaining findings and follow-ups

- MiniGames still has compact global registration, lobby and `TablePhase` state because unseated and JIP clients need to discover and interact with tables. Full active game state is now owner-targeted. Source-site counts are not packet counts; dedicated multiplayer measurement remains required.
- An end-user report described average traffic of "6-9 MB" with "40-50 MB" peaks. Those values require the monitoring interval, direction and whether the unit means MB or Mb before they can be converted to throughput. They cannot represent individual network packet sizes. Existing audit `mpStatistics` logs contain aggregate engine message counts but no per-feature byte attribution, so the report is credible evidence of a serious symptom but not proof that MiniGames caused all of it.
- The interaction lock watchdog contains terminal remote calls inside a recurring block. They are exactly-once exit branches, not unconditional per-tick traffic.
- The optional player-marker and headless-client packages retain their existing polling behavior. They are reported but were not modified.
- VVD and several equipment displays intentionally refresh during an active, visible operation. In-engine profiling is required before changing their cadence.

## Manual runtime verification still required

The first approved dedicated run exposed an invalid assumption that public-variable event handlers
could be removed. Economy now installs one guarded listener that remains inert while stopped, as the
engine requires. A focused Economy rerun also exposed an audit-only race: the server case started
before role assignment produced an interface player. Automated audits now wait for a fully initialized
client before diagnostics or server assertions, preventing a missing player from being reported as a
feature failure. Both corrections are covered by static tests and require the fresh in-engine reruns
listed below.

The approved run also showed an Economy collection notification at mission entry. This was generated
by the automated crate-consumption assertion using the joined player as its actor, not by Economy
startup. The assertion now uses a server-owned QA actor, preserving the real authoritative collection,
resource arithmetic, deletion and notification call without displaying audit activity to players.
The Paradrop audit fixture now follows the full marker-driven composition path: it creates the authored
drop-zone marker, a crewed aircraft and calls `Waldo_fnc_ParadropQuickFlightSetup` with route and live
aircraft markers enabled. The older action-only aircraft setup was removed from the client fixture.

Before describing these static reductions as measured performance gains, test a dedicated server with representative player, table, zone and equipment counts. Record server FPS, scheduled script time and network traffic during idle, active-game and economy-load scenarios; include JIP, disconnects, deleted objects and long-session cleanup. Test 30, 60 and 120 client FPS for interaction smoothness.

### Deferred acceptance queue — do not run without approval

The 31 August source changes are intentionally untested in-engine pending the mission owner's
approval. When approved, run the checks as one controlled pass:

1. Run the SQF validator, repository unit tests, wiki checks, Zeus/script parity checker, offline
   performance guardrail and generated-audit source-parity checks. Rebuild the disposable audit
   mission from the changed source before launching it.
2. Register an all-games table and subset table. Confirm registration creates lobby state only,
   then start every game and verify current-player and spectator views still update at every move,
   timed transition and reset. Repeat with active-game JIP, disconnect, respawn, table deletion and
   server/HC ownership changes.
3. Exercise SafeStart inactive JIP, active JIP, JIP after go-live, JIP during countdown, reconnect and
   respawn on dedicated and listen servers. A joining player must reconcile the server's latest
   revision and must never retain protection after the server is live.
4. Confirm Paradrop and Gunship marker handlers are absent with empty registries, start with the
   first live aircraft, retain their one-second active cadence, stop after removal of the final
   entry, and restart after later registration. Cover both public-state/setup arrival orders and JIP.
5. Stop Breaching and remove all gunships, then join a fresh client and confirm no obsolete runtime
   initializer is replayed. Re-enable/re-register and confirm normal actions return.
6. Delete starter crates, Field Resupply hubs/crates and Tactical Displays through their normal path
   and externally through Zeus/script deletion. Confirm their named JIP entries and hub membership
   disappear, then JIP and verify no dangling actions are installed.
7. Fell both carryable and drag-only trees. Confirm current and JIP clients receive drag on both and
   carry only on the existing small-tree case; delete the fallen objects and confirm replay cleanup.
8. Create and externally delete every Economy action-bearing object type, then purge and re-enable
   Economy. Confirm current players lose obsolete actions, JIP receives no deleted-object actions,
   and recreated objects regain the same UI and operations without duplicate actions. With the
   testing notice disabled and enabled, cover an initial player, JIP, respawn and purge/re-enable;
   confirm the same notice appears once per token and no player receives duplicate actions. On a
   dedicated client and listen host, create several registered objects in one frame, remove one
   action externally and confirm immediate registry-driven setup plus repair within ten seconds.
   Respawn and team-switch a Ground Command player, including one delayed-identity join; verify the
   same stored key format and permissions, then purge/re-enable and confirm one active handler.
9. Use the required dedicated launcher at 3840x2160 with `-noBattlEye`, verify real mission entry and
   clean RPTs, then perform the representative idle/active network comparison externally. Do not add
   self-measuring runtime telemetry to WMP.

### Prepared execution packet

Run the source gates sequentially from the repository root. Do not run scanners concurrently with
the generated audit builder because the builder refreshes its staged tree in place.

```text
python releaseVerificationAndDeployment/sqf_validator.py
python releaseVerificationAndDeployment/config_style_checker.py
python releaseVerificationAndDeployment/interaction_ui_checker.py
python releaseVerificationAndDeployment/drawn_ui_checker.py
python releaseVerificationAndDeployment/zeus_script_parity_checker.py
python releaseVerificationAndDeployment/check_wiki_assets.py
python releaseVerificationAndDeployment/wiki_style_checker.py
python releaseVerificationAndDeployment/documentation_contract_checker.py
python -m unittest discover -s releaseVerificationAndDeployment -p "test_*.py" -v
python releaseVerificationAndDeployment/performance_audit.py
git diff --check HEAD
```

After the source gates pass, use only the canonical launcher. It rebuilds the disposable mission
from the current source, disables BattlEye and defaults to 3840x2160:

```text
powershell -ExecutionPolicy Bypass -File .\releaseVerificationAndDeployment\launch_pr_review_audit.ps1 -Suite economy -Mode Manual
powershell -ExecutionPolicy Bypass -File .\releaseVerificationAndDeployment\launch_pr_review_audit.ps1 -Suite party -Mode Manual
powershell -ExecutionPolicy Bypass -File .\releaseVerificationAndDeployment\launch_pr_review_audit.ps1 -Suite all -Mode Automated
```

The Economy run requires an initial client, two-client dedicated case, JIP, respawn, team switch,
purge/re-enable, registered-object creation/deletion and an externally removed action. The party run
requires two and four seated clients plus a fifth JIP spectator. The final `all` run is accepted only
after the RPT proves the VR audit mission started, both Zeus-ready markers appear, every expected
case completes and no first-party SQF error is present.

## See also

- [Mission Diagnostics](Mission-Diagnostics)
- [Waldos Economy Systems](Waldos-Economy-Systems)
- [Waldos Mini Games](Waldos-Mini-Games)
- [Third-Party Scripts](Third-Party-Scripts-Headless-Client-And-Player-Markers)
- [Bohemia Interactive: remoteExec](https://community.bohemia.net/wiki/remoteExec)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
