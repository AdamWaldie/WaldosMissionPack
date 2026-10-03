# PR 151 review and validation

PR 151 remains draft pending in-engine acceptance. The review began at `1f88659` against main
`7bf8506`, using an isolated worktree and preserving the original dirty checkout. Review commit
`030b211` corrected the initial defects. This follow-up implements the requested artillery and
convoy changes and addresses the source-level integration blockers. It also reviews the newer
remote `036942e` blocker fixes and reconciles their intent with the expanded implementation.

## Current acceptance status

The implementation is named Cortex throughout its function API and source directory. Ninety-nine `Waldo_fnc_Cortex...` functions replace the previous public names; legacy aliases retain existing mission calls. Configuration and state keys remain compatible.

Cortex Control now combines feature switches and tuning in one window. Each page explains its purpose, requirements and setup. The window distinguishes saved state from pending changes. Purpose modules require an explicit eligible target, preserve an existing order when a new order cannot run, and report refusal reasons. Hand-back releases posted orders immediately. Server revision checks reject stale settings submissions.

The dedicated audit `runtime-20260926-123545` completed its server and client suites with zero findings. It exercised infantry orders, adoption and acknowledged orders on both headless clients, server return, movement of all three convoy vehicles after controller startup, cargo unloading with crew retention, and a finite two-round artillery burst. The client exercised all eight pages, draft retention, Cancel, authoritative Apply and reservation cleanup. All 383 repository tests and ten static gates passed. These results do not establish mouse usability, every layout or the complete combat matrix.

The ownership overlay now reads expected and observed owners from one snapshot and marks pending transfers separately. This addresses the transient mismatch display seen during the audit; a completed transfer still needs its owner acknowledgement.

The expanded audit runtime-20260926-124153 passed real counter-battery acquisition and finite response checks both with and without radar. It failed CNV-08 destination halt and CNV-09 destination unloading. The focused runtime-20260926-124827 reproduced those failures with all three vehicles stopped short. Convoy recovery changes are undergoing a fresh focused run; neither failed run is accepted. The repository suite now has 387 passing tests, including four audit-report tests. Other engine coverage still required: ACE-initiated handoff, disconnect during pending work, joining client replay, moving and pinned ambushes, spotter loss and target relocation, exact ZEN target/settings handling, themes, aspect ratios and physical input. Mechanized overwatch, casualty assignment and prisoner recovery remain proposals, not implemented features.

The sections below retain the implementation record. Earlier test counts describe earlier revisions.

## Changes and intent

- **Artillery warning:** opening HE uses a deliberate 300 m offset plus report error. At most eight
  candidates are checked against one living-player snapshot; each needs the configured 200 m
  exclusion plus 100 m buffer. Failure cancels the mission. This is an aim safeguard, not a promise
  that dispersion or later movement cannot hurt players.
- **Finite bursts:** support defaults to three bursts of three rounds; counter-battery to three
  bursts of four. Smoke uses one burst. Rounds share one aim point, with a 2 s minimum requested
  spacing subject to gun reload. After the last round, estimated flight time plus a 20 s warning
  pause precedes correction. The mission ends at its burst cap and then enters cooldown.
- **Observed corrections:** only explicitly assigned existing soldiers with binoculars request
  support. Inventory radios are not required; WMP jamming still blocks transmission. Zeus lists
  assigned names and no extra units spawn. A fresh observed report reduces offset to 55%, with
  a 40 m floor. Lost observation or blocked communications freezes support position and accuracy.
- **Counter-battery:** firing events capture positions; no spotter or radar is required. Acquisition
  defaults to 60 s, reduced to 20 s under registered radar coverage. Bursts walk closer to the last
  captured position. A reported move of at least 150 m resets opening offset and safety checks,
  without adding bursts. No live transform tracking or continuous player/projectile monitoring.
- **Cross-owner artillery:** the server holds the mission and shot count, asks the spotter owner for
  a report and sends one firing command to the gun owner. Actual engine firing events confirm
  expenditure. Unknown outcomes are quarantined without retry; explicit owner rejection ends the
  mission. Every shot rechecks role, switches, pause, eligibility, ammunition/range and nearby
  friendlies/civilians, including crew. No claim is made that an issued engine command is cancellable.
- **Headless restoration:** ownership epochs invalidate old jobs. Changed restoration checkpoints
  retain behaviour, speed, drill-disabled features and movement information; pass-set stance markers
  are public. New owners restore interrupted transient work, then adopt eligible groups. This covers
  the intended WMP and ACE headless paths without pinning all AI to the server.
- **Clearing replay:** public orders retain the building, completed position indices, shared-server
  deadline and original behaviour. New owners rebuild local assignments with time remaining.
  Replacement orders, release and stop clear work. Expired resumes do not issue new movement.
- **Feature pin provenance:** first-pin records preserve pre-existing WMP/ACE exclusions for crew,
  groups and generated paradrop units. Release restores recorded values and preserves unknown pins.
- **Zeus results:** named payloads are validated on the server and run on the current owner. Success
  follows the owner's result; missing responses are reported as uncertain. Required building and
  spotter targets are explicit. Legacy positional AI_ORDER input retains a documented adapter. Battery roles change on the server; JIP init calls cannot overwrite them.
- **Convoy:** server registration coordinates owner-local travel, arrival and held contact. Wheeled
  paths and native tracked destinations follow a bounded leader trail with size/speed-aware spacing.
  Stop holds vehicles and dismounts cargo. Explicit release restores original settings. Mounted
  weapons retain their crew and respond under existing ROE. No FSM, teleport or repeated trail
  broadcast. Terminating an old spawn handle does not stop the shared worker.
- **Protected tasks and cleanup:** survivor regroup avoids unconscious soldiers, service commands
  and posted orders, and rechecks host capacity immediately before joining. Garrison handler IDs,
  duck callbacks and original stance have explicit release/ownership cleanup.

Earlier corrections remain: correct Zeus waypoint event payloads; shared eligibility checks;
repeat-order generations; live LAMBS mode restoration; delayed drill gates; blocked-backblast
repositioning without a same-step shot; stop/start cancellation; airborne damage restoration on the
current owner; actual landing before ground orders; and correct pending waypoint index checks.

## Concurrent PR integration

Remote commit `036942e` independently addressed the same four blockers. Its useful shared-clock
clear-order deadline is retained, as are the Paradrop/Transport exclusion explanations. Its separate
publish/adopt helpers are superseded by the scheduler checkpoint and Local-event epoch contract;
keeping both would restore twice and publish competing records. Its pin record is superseded by
the shared first-pin helper, which also covers generated jumpers. Its positional owner notification
worker is superseded by the named server-dispatch/result contract. Both histories remain in the PR.
Stop explicitly cancels clearing; it does not silently replay a stopped clear order on restart.

## Performance limits

The AI scheduler has a default soft 1 ms budget checked between jobs, not a hard pre-emption limit.
Queue traversal still scales with queue size. Discovery supplies gun and spotter caches. The legacy counter
observation helper handles at most four cached spotters per job. Opening HE checks at most eight aims per opening burst;
there is no continuous player/projectile safety monitor. Restoration broadcasts occur on change.

Convoys share one worker per AI-owning machine, considering one convoy each 0.25 s. A convoy steps
at most once per second, holds at most 128 route samples and sends at most ten path points per
follower no more often than every three seconds. Registration permits 2–20 vehicles. Larger convoy
counts reduce update frequency. On migration, formation following bridges reconstruction of the
local trail; complete route history is not broadcast.

## Implementation boundaries

WMP remains a mission-script pack. AI behaviour uses existing engine knowledge, WMP skill tuning,
ACE medical handling and the established feature ownership rules. Convoy paths stay local and
bounded; artillery uses explicit observations and confirmed rounds. Flight controllers retain their
existing ownership requirements.

## Verification

The integrated branch includes main `b7ca3fe` and remote PR commit `036942e`. The full repository
suite passed **330 tests**, including **30 Smart AI contract tests**. All ten static gates passed:
SQF (1,227 files), configuration, interaction UI, drawn UI, Zeus/script parity (81 modules), wiki
assets/style, documentation contracts, skill validation and performance regression. The performance
scanner reports 95 findings (10 high, 85 medium), with no new high recurring patterns. Wiki checks
initially caught a document encoding error; it was corrected and both checks then passed.
The audit builder ran before scanners. Git whitespace validation passed. These checks inspect source/tooling contracts, not AI mechanics.

## Remaining merge blockers: engine acceptance

At this earlier review stage, no Arma session had been launched. The current acceptance status above supersedes that historical boundary.
Use `launch_pr_review_audit.ps1`, default 3840x2160 and `-noBattlEye`, and require actual VR mission
entry plus fresh RPT initialization evidence. Exercise:

1. Explicit spotter assignment/removal, binocular loss, absent inventory radios, jamming, occlusion and death. Move the
   target after observation loss and verify the aim does not follow or tighten without a report.
2. Opening aim rejection near players, no safe candidate, friendly occupied vehicles near later
   aims, role/switch changes, ammunition exhaustion and gun deletion. Measure warning intervals
   against actual impacts. No duplicate fire after owner change or an uncertain command.
3. Server-to-HC, HC-to-server, HC-to-HC and abrupt disconnect during flanks, clearing and artillery.
   Repeat with WMP headless and ACE headless, late joining owners, both LAMBS modes, and stopped AI.
4. Garrison/defence/clear replacement, release and stop/restart; Zeus waypoint edits; real owner
   rejection and response timeout. Verify pre-existing mission-maker exclusions survive crew release.
5. Convoy bends/junctions, mixed sizes, obstruction, leader loss, reconfiguration, stop, player entry,
   Zeus interruption and locality migration. Verify restored speed/unloading/formation and cleanup.
6. Existing Paradrop, Transport Services, Gunship, Dynamic AA, dialogue and Dynamic AO interactions,
   SafeStart/ENDEX, airborne cancellation and damage restoration.

Agent-driven launch permission is required by AGENTS.md: “Agent-driven launches write a disposable
mission into the installed Arma directory and open a desktop application, so obtain the required
permission.” The user subsequently authorized launch, restart of the audit processes and automatic mission entry for Cortex audits.

## Dedicated Zeus AI controls

WMP AI Control contains AI Control, AI Tuning, AI Orders, Artillery - Set Up Spotter,
Artillery - Set Battery Role, Artillery - Set Up Radar and Convoy - Create Moving Group.
Dynamic AO and Dynamic AA stay in WMP AI & Combat. Artillery setup moves out of the tactical order
selector into exact-target helpers. Battery setup supports empty guns; radar setup provides side
selection and repeat-safe removal through the script API's optional third boolean argument.
All helper changes use the authenticated server route, retain public JIP state and add no loops.
Feature switches and equipment are not changed implicitly. Dialog selection, server logs, resulting
state and JIP/HC behaviour remain subject to the existing live acceptance gate.

The dedicated-category changes passed the full 320-test suite before the burst changes and all ten static gates. The palette contains 81 registered modules overall. No new high recurring performance patterns were reported. Live ZEN rendering and execution remain unverified.

## Convoy arrival, contact and mixed vehicles

The existing speed, separation and push-through controls now cover mixed tracked/wheeled convoys.
Arrival and explicit stop enter a persistent hold and dismount captured cargo through each soldier's
owner. Drivers, commanders and weapon-turret crews stay aboard; passenger firing seats are cargo.
Mounted crew can engage known recent threats under existing ROE while the column moves. Push-through
halts after 15 seconds pinned in contact; disabling it halts on contact. Explicit configuration
resumes, while an optional fifth API boolean releases/restores the controller. Cargo is not auto-boarded.

Tracked/unsupported steering uses native destinations along the leader trail. Wheeled followers retain
bounded paths. Cached vehicle dimensions set minimum gaps; the slowest declared speed limits the
column. The leader waits for stretched spacing outside contact. The registry transports restoration
and cargo state together; a five-second changed checkpoint preserves contact progress across HCs.

Live tests must cover mixed orderings, mounted ROE, pinned/mobile contact, final-route arrival, cargo
seat changes, unconscious passengers, separate cargo owners, explicit resume/release and stale owner
requests. These additions have no live acceptance result.

## Contact-drill follow-up

Contact now requires recent danger, suppression or a hostile vehicle hit; sighting alone does not
halt the convoy. Mounted crews prefer known active threats under their existing ROE. The existing
push-through and 15-second pinned rules remain in force.

Ambush passengers receive one bounded initial cover/dispersal order. Searches are limited to two
passengers per convoy/owner/five-second step, with a server-issued 45-second expiry. Public destinations
support HC transfer; Smart AI yields while the order is active. Resume/release/operator intervention
cleans it up. Arrival/manual stops only unload. Completed unloading is recorded so intentional reboarding
does not trigger repeated get-out orders. Hit handlers are tracked and broadcasts are throttled.

The implementation does not choose vehicle exit doors, guarantee protected cover, plan road bypasses
or coordinate an assault. Contact classification, cover selection and migration remain unverified in engine.

## Modular AI integration

The follow-up adds live ammunition capability checks, shared passenger safety, effective-ally morale
checks, bounded cover validation and actual artillery ammunition checks. Contact reports now carry
expiring positions across owners. Reinforcement and coordinated assault use server reservations with
owner acknowledgements and matching-state checks. Optional nearby-gunfire investigation and convoy
infantry avoidance default off. Existing vehicle and convoy behaviours have independent child switches.

Per-group exclusions can disable automatic behaviours, and an external-control flag yields automatic
Smart AI and convoy commands. Separate convoy cargo and turret groups retain their own exclusions.
Settings use the existing named tuning contract and HC/JIP replay. No addon config classes, FSM
replacement, medical override or projectile steering is included.

Required live cases: simultaneous requests competing for one helper; delayed or reordered reservation
and acknowledgement messages; ownership transfer before and after acceptance; disable during travel,
assault and cover movement; independent cargo-group exclusions; empty, AA and dual-purpose launchers;
wet ground and bridges; suppressed gunfire; narrow cover; and crowded mixed-vehicle convoys. Check WMP
and ACE headless migration separately. Static validation does not establish these engine behaviours.

### Current-main integration

Merged main `d5e26d2` into the PR branch, retaining its logistics, ACE vehicle-services and JIP fixes.
Resolved convoy conflicts in favour of the current-owner controller and exact-target Zeus workflow;
combined the paradrop headers and retained typed Dynamic AO documentation. The combined palette has
82 modules. The merged branch passed 369 repository tests, including 43 Smart AI/modularity contracts.
At this merge checkpoint, engine acceptance and Control/Tuning consolidation were outstanding. The current status above records the subsequent work.

All ten static gates passed after the merge: 1,251 SQF files, 82 Zeus modules, wiki/configuration
contracts, UI checks and performance regression. The performance scan remains at 95 findings
(10 high, 85 medium), with no new high-severity recurring patterns. The audit fixture was rebuilt
before scanners. No in-engine validation had been performed at that checkpoint.

### Runtime startup repair and revised controls

The palette now combines AI Control and Tuning on eight purpose pages and splits infantry, airborne and group handover orders into focused modules (85 modules total). Complete ordered settings revisions precede local worker changes. Legacy positional controls share server validation. Disabling grenade evasion removes its projectile handler.

The first dedicated audit with two headless clients exposed invalid `bitAnd` expressions in launcher capability and artillery ammunition selection, an executable override appended after the AI configuration return value, and player-loadout startup running on HCs. The configuration failure prevented the shared-ready flag and therefore the authoritative settings handshake. Repairs use numeric bit tests, keep the override in the shared data table, guard player startup with `hasInterface`, and report nil configuration returns without cascading an undefined-variable error. The validator now rejects `bitAnd`.

The repaired source passed 372 regression tests. Live acceptance is being repeated against a rebuilt disposable mission; the original run is a failed test, not acceptance evidence.

### Cortex custom control interface

Replaced the settings-page dialog chain with Cortex Control: one modal window, purpose navigation, scrollable settings with inline help, pending edits across tabs, Apply changed values, and Cancel. It uses the existing named server validation and settings broadcasts; script identifiers stay compatible. ZEN now groups the shorter purpose-module names under WMP Cortex. The interface adds no per-frame or polling worker. Live visual and interaction acceptance remains outstanding.

### Master shutdown cancels explicit orders

The physical lifecycle audit reproduced a stale-order bug: soldiers obeyed an ordinary waypoint while
Cortex was disabled, then travelled 64.154 m back toward their previous defence assignment after restart.
Master shutdown now invokes the existing owner-local defence, garrison and clear-building releases.
This clears public assignments and restores Cortex-owned restrictions before rediscovery can replay them.
Completed merges and surrenders remain unchanged.

Fresh runtime `20260927-073245` passed all five server-owned defence lifecycle checks, including physical
ordinary movement while disabled, no stale-order return after restart (maximum marker distance 8.885 m),
and physical arrival under a fresh defence order. Garrison shutdown, HC migration, JIP and explicit Zeus
handover variants remain unaccepted. The original failed runtime `20260927-072844` is retained.
Static regression: 412 tests passed, 1,257 SQF files with zero errors, 113 wiki pages and 85 Zeus modules.

The additive lifecycle run `20260927-073840` repeated the original server case and added both WMP
headless owners. Each owner executed real defence movement, cleared assignments on master shutdown,
and accepted a fresh defence order after restart. Ordinary waypoint movement was checked after
returning each squad to the server while disabled. Neither squad resurrected the old order. This
covers WMP migration for this defence sequence; ACE-managed transfer, HC disconnect and JIP remain
separate acceptance work.

### Aircraft defence physical comparison

Added a native-AI comparison alongside the existing enabled aircraft test. Both flights receive a
real AA missile following natural acquisition. Runtime `20260927-074821` measured 0.217 m native
versus 34.076 m Cortex departure from the event-time trajectory over two seconds; both retained crew
and ground clearance. Native AI also released flares (five recorded events versus three enabled),
so this proves the scoped evasive movement response, not the Cortex origin of the flare releases.
The fixture sets the managed-aircraft eligibility marker; actual gunship-service creation, low-altitude
refusal, ammunition exhaustion, owner changes and cancellation remain acceptance work.

### Scheduler physical workload

Runtime `20260927-075211` executed the pending twelve-squad scheduler fixture at the minimum 0.2 ms
soft budget. All jobs began 0.167 seconds after submission, all soldiers physically covered the 80 m
route and arrived within 0.95 m, and every job completed exactly once. The fixture uses cheap movement
jobs: this verifies the server queue path but does not establish heavy-load performance, budget
saturation, distant update tiers, FPS throttling or HC workload behaviour.

### Coordinated assault live evidence — 27 September

Runtime `20260927-081101` completed 21 checks with two failures and no SQF errors. Physical screening kept both helpers available; both rallied and then advanced around the obstacle on opposite sides. Not every soldier reached the 50 m objective radius, so coordinated assault remains unaccepted. Earlier fixture failures remain recorded. The next run reports individual travel, remaining distance, command and support lease state; side geometry is measured independently without relaxing arrival. Cross-owner, cancellation and route restoration still require live validation.

Active reinforcement and coordinated-assault assignments now reject new independent flank/advance drills. The guards run before movement or attack-state mutation. This closes a source-confirmed competing-controller path; a combined-features live test is still required.

Runtime `20260927-081755` confirms both valid assault leases and opposite-side movement, but two soldiers remained 63–66 m from the objective at the deadline. The finite assault destination now uses MOVE with a 10 m completion radius instead of an open-ended SAD waypoint with 20 m radius. Normal combat reactions remain enabled. This change requires a fresh live retest; the failed result is retained.

The coordinated QA template now adds disable/release checks followed by at least 50 m of actual travel under new ordinary orders for every helper. Opposite-side validation also requires every helper to have advanced at least 60 m, preventing the initial rally layout alone from passing it. These added cases await a rebuilt live run.

Runtime `20260927-082342` contradicts acceptance of the finite approach change: one squad arrived at 26–30 m, the other remained 71–127 m away with active MOVE commands and valid assault leases. Arrival remains failed. Cancellation and physical handover checks are added for the next run, without removing any earlier checks.

Source review found that contact entry imposed COMBAT on active coordinated responders. It now leaves their behaviour to native combat reactions while the finite assault order is active; AUTOCOMBAT is not disabled. This targets forced whole-squad combat bounding during the approach and remains a candidate fix pending live verification.

Runtime `20260927-082929` passed support assignment and temporary-waypoint cleanup after disable, but failed physical travel under fresh ordinary orders. Assault arrival and opposite-side geometry also failed. The test now demonstrates why cleanup flags alone are insufficient; the forced-COMBAT candidate will be checked against the same unchanged physical thresholds.

Runtime `20260927-083701` passed coordinated arrival and opposite-side movement after removing forced COMBAT (all six travelled 166–182 m and reached within 50 m). Disable cleanup passed, but subsequent ordinary-order travel still failed. The server case remains; a separate-HC responder case using WMP migration is now added. Fresh ordinary orders are issued after return to server, so HC Zeus delivery is not claimed.

Performance acceptance now explicitly targets at least 100 six-unit groups against matched Cortex-off workloads, including dedicated-server and WMP/ACE HC variants. The user confirmed the 5% median / 10% p95 overhead budget, with no stalled AI jobs. The current twelve single-unit scheduler test is explicitly insufficient; the scale matrix remains unimplemented and unverified. See `cortexQA/PERFORMANCE.md`.
