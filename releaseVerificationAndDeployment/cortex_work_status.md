# Cortex work and acceptance status

Updated 4 October 2026. PR 151 remains draft. Batched Arma testing uses the canonical 3840x2160 resolution. Core LAMBS compatibility passed both standalone and installed-mod arms. The 50-squad infantry and 50-group mixed native-versus-Cortex matrices passed the agreed frame-time budgets in their recorded runs; repeated hardware and ACE HC runs remain.

## 4 October: HBQ driving and naval-assault source assessments

The locally installed HBQ Advanced Driving AI 1.0.0 PBO was unpacked and inspected. WMP adopts its
route-memory and anticipatory-speed principles conservatively. A convoy performs one bounded road
walk every three seconds to anticipate curves, junctions and grades; followers reuse the predecessor
trail already held by the spacing controller. Speed increases are damped while safety and braking
remain immediate. The controller does not add a worker per vehicle. An enabled convoy also stores the identity of its final MOVE
waypoint and may re-select that exact waypoint only when the engine completes it more than 75 metres
early, its type and position are unchanged, and Zeus has not suspended the controller. It never
creates a replacement route, teleports, repairs, unflips, pushes or suppresses collision damage.
Those exclusions preserve player roadblocks and ambushes. While WMP owns a convoy it captures and
temporarily applies HBQ's public pause and crew-return variables; final release restores exact value
and variable presence. HBQ remains untouched for non-WMP vehicles. Static acceptance is implemented;
an HBQ-loaded dedicated/HC/Zeus route-loss run remains queued.

The locally installed PROTOCOL AI NAVY SEAL PBO was also unpacked. Its useful concepts are shoreline
sampling, finite boat approach, separate support and assault roles, cover-biased movement and casualty
redistribution. Its implementation is not suitable as a shared compatibility owner: one file launches
two overlapping global group scans, takes control based only on enemy proximity, repeatedly forces
exits and individual moves, and does not arbitrate Zeus, locality, authored orders or cleanup. No source
is copied. WMP now supplies a separately gated naval landing through the existing Cortex group job: a
crew compares a bounded set of dry shore/shallow-water candidates, takes one finite native MOVE lease,
stops for dismount and restores its authored route; passenger groups unload only their own cargo and
continue through one dry-ground egress. Combined crew/cargo groups never receive a land waypoint.
Casualties reduce the landing element without creating a readiness wait. Zeus, expiry, locality and
feature cleanup restore exact boat speed and only token-matched WMP state. When PROTOCOL is loaded,
WMP yields naval ownership completely. Static acceptance is implemented; dependency-loaded,
multi-owner and varied-coast physical arms remain queued.

## 4 October: VCOM, WebKnight, IMS and civilian ownership

Local Workshop source was inspected for WebKnight Zombies, WebKnight Droids, the WBK Units LAMBS
compatibility patch and Simple Civilian Behaviour. The official VCOM source was also inspected. IMS2
was not present in the local Workshop library; the locally available earlier IMS generation and known
IMS2 runtime markers informed a conservative active-actor gate, but IMS2 live compatibility is not
accepted yet.

Cortex now excludes WebKnight custom actors and active IMS melee actors without excluding ordinary
infantry merely because either addon is loaded. The WBK LAMBS patch remains authoritative because
Cortex refuses those actors before acquiring any movement lease. VCOM receives a finite movement
lease that preserves and restores its exact `Vcm_Disable` baseline; active VCOM support or medic
movement refuses the Cortex request. VCOM formation, flank, rescue and skill controls are untouched.

An additive WMP civilian reaction supplies event-driven `FiredNear`/`Hit` flight only when Simple
Civilian Behaviour is absent. It has no poller or FSM, yields to Zeus, and exposes enable, radius,
distance and cooldown controls. WMP Diagnostics reports loaded integrations, finite leases, external
actor ownership and active civilian reactions. The coverage registry now maps 63 cases, 180 settings
and 151 production AI sources. The new civilian and naval physical audits are saved but unexecuted; all
dependency-loaded, HC, JIP and real event-delivery variants remain open.

## 1 October: LAMBS ownership and compatibility

The four supplied Workshop packages now have explicit, separate treatment. LAMBS_Danger and its
Waypoints component are behavioural integrations; LAMBS_Turrets, LAMBS_Suppression and LAMBS_RPG
are detected as config layers and remain active in every Cortex mode. In the default shared mode,
Danger retains ordinary contact tactics. A responder accepting a Cortex reinforcement rally or
coordinated assault takes a finite public movement lease, temporarily pauses LAMBS group manoeuvres,
and restores the exact prior group setting on completion, rejection, expiry, ownership migration,
Zeus takeover or Cortex shutdown. This removes simultaneous movement orders without disabling the
requester's LAMBS-controlled base of fire. Cortex-only mode now also records and restores a mission
maker's pre-existing disabled state across live mode changes.

LAMBS_Danger's GPLv2 license adds a condition forbidding modified or derivative versions on Steam
Workshop, so no upstream FSM source is copied into WMP. Shared mode uses the installed mod's engine
FSM and public APIs at runtime. Static validation passed 268 focused Cortex/modularity tests, all 1,265
SQF files, all 113 wiki pages, all 85 Zeus modules, eight performance-audit tests and `git diff --check`.
The regression scan found no new high-severity recurring pattern. Runtime `20261001-110329` passed
the standalone fallback with zero findings. Runtime `20261001-111118`, using the installed LAMBS
suite and two real WMP HCs, passed active-tactic/forced-move/waypoint refusals, clean lease and exact
false/true restoration, live HC adoption/renewal/release and Zeus replacement movement with zero
findings and zero SQF errors. ACE HC, disconnect, JIP and wider terrain/mod combinations remain.

## 1 October: distributed 100-group contact benchmark

The earlier 100-group result covered server-owned patrol only. Runtime `20261001-111812` executed the
first distributed 100x6 OFF/ON/ON/OFF contact matrix across the server and two WMP HCs. It failed
closed: the user observed 14 FPS falling to 8 FPS, no arm achieved the required workload, and the
Cortex arms accumulated 5.7-13.0 seconds of overdue work while disabled arms reported zero. Native
arms moved 63/68 groups and fired 40/44; Cortex arms moved 61/53 and fired 48/35. This is not a
performance-budget pass.

The source review found a concrete scheduler ceiling: a 0.25-second handler guaranteed only one
heavy job per wake after the soft budget was exceeded, limiting an owner to four heavy steps per
second. Due work now gets one budgeted opportunity per frame while the cached deadline keeps idle
frames constant-time. The revised benchmark retains 100 six-soldier groups but uses 25 controlled
contact groups and 75 ordinary movement groups, and adds rendered-client frame sampling. Without
LAMBS it compares vanilla against Cortex; with the installed suite it compares LAMBS alone against
Cortex plus LAMBS SPLIT. Fresh 4K runs are required for the agreed 5% median / 10% p95 budget.

Runtime `20261001-114026` completed that controlled-contact matrix. Scheduler lateness improved to
0-2.235 seconds, but server frame time remained above budget: native arms measured 23/30 ms
median/p95 and Cortex arms measured 31/44 and 34/46 ms. HC differences were smaller. The workload
gate correctly withheld a comparison, but review found two audit defects: routes started before the
warm-up baseline, and shots were counted only from leaders. The saved fixture now captures every
soldier's start before owner-local activation and records a group's first real FiredMan event on the
group owner. No budget pass is claimed pending a rebuilt matrix.

Runtime `20261001-115539` confirmed that the corrected fixture performs real work: 99 of 100
groups moved, 18 of 25 contact groups fired and the first observed response took 29.552 seconds.
One headless client then crashed inside the Arma allocator during the first arm, transferring its 33
groups back to the server and invalidating the comparison. The saved matrix now paces initial
ownership transfers, requires both expected headless clients before and after each arm, and refuses
to publish partial OFF/ON/ON/OFF results.

Runtime `20261001-120528` then completed all four arms with both HCs still connected, but HC2's
simulation had stopped advancing after the first simultaneous path-request burst. Its result was
absent and its 33 groups explain the repeated 65-67 movement count. The audit now staggers those
owner-local requests across frames, publishes an owner heartbeat, identifies connected-but-frozen
owners and cancels later arms once an owner stops responding. No comparison is claimed from this run.

The primary budget target is now 50 groups. The infantry matrix uses 50 six-soldier squads, while
the additive mixed matrix uses 30 infantry squads, ten ground vehicles, six helicopters and four
jets. Both retain matched OFF/ON/ON/OFF arms, real physical work, actual-fire gates, two HC owners,
rendered-client sampling and the agreed 5% median / 10% p95 limit. The 100-group result remains a
local-host saturation finding rather than the acceptance workload.

Runtime `20261001-122634` completed the first 50-squad matrix without an owner stall. Every arm moved
47-50 groups, all 13 contact groups fired, response began within 4.337-5.559 seconds and every sampler
returned. Server median/p95 measured 31/37 and 31/36 ms natively versus 27/39 and 28/38 ms with
Cortex; both HCs remained 21/24 ms. The run was not comparable because one to three transferred
soldiers died in three arms, including the closing native arm. Invulnerability is now reapplied on
the actual owner after locality transfer; no budget pass is claimed from the invalid matrix.

Runtime `20261001-123818` completed a valid 50-squad infantry OFF/ON/ON/OFF matrix. Every arm moved
47-50 groups, all 13 contacts fired, all owners remained responsive and all server, HC and rendered
client median/p95 gates passed. Server native baselines were 30/36 and 31/37 ms versus Cortex 29/38
and 28/38 ms. The HCs remained 21/24-25 ms and the client remained within budget.

Runtime `20261001-131706` completed a valid additive mixed matrix with 30 infantry squads, ten ground
vehicles, six helicopters and four jets. The production flight-locality policy kept aircraft on the
server, giving every arm the same 24/13/13 active ownership. Native arms moved 50/49 groups and Cortex
arms 49/48; all ten contacts fired and responded within 3.352-4.387 seconds. Server median/p95 was
21/24 ms natively and 21/25 ms with Cortex; HC and rendered-client gates also passed. Server and client
both completed with zero Cortex findings and no SQF errors. Observer death, stationary jet spawning,
transient group migration refusal, stale remote groups and an unrelated conversation-author audit
error cascade were corrected before this accepted run.

## 1 October: contact initiative without authored movement

Bounding advance no longer requires an unfinished ordinary waypoint. An eligible steady squad with no active waypoint can use enemy knowledge seen within the previous ten seconds as a finite objective, run the existing successive covered bounds, and transition through the existing assault/consolidation flow. Cortex does not add a persistent waypoint for this case. An active HOLD, GUARD, SENTRY or other non-movement waypoint remains authoritative and refuses the automatic advance. This closes a source-level idle path for editor-placed or newly stationary squads without adding a poller, global scan or per-unit scheduler. Physical aggression, route quality, Zeus interruption and performance remain queued for the rebuilt audit.

| Requested work | Implementation | Recorded evidence / work remaining |
|---|---|---|
| Cortex name in functions | 99 Cortex function exports and Cortex source directory; old aliases and settings retained for existing missions | Static alias checks passed; live audit uses the new functions |
| One custom control/tuning UI | Eight purpose pages, contextual help, retained drafts, Apply/Cancel, authoritative revision checking | Pages, draft retention, Cancel, server Apply and cleanup passed; physical input and layout matrix remain |
| Cortex ZEN category and purpose modules | AI/combat controls grouped under Cortex, explicit target selection and refusal messages | Exact selected-object workflows still need live acceptance |
| Infantry orders | Defend, garrison, clear and release paths preserve prior valid work when a new request fails | Earlier passes checked acceptance and assignments only, not physical execution. Physical defence arrival/hold and defence movement on both HCs passed in runtime-20260926-132854. Garrison arrival/hold still FAILED with the simulation-enabled mission-placed house in runtime-20260926-135217: soldiers stopped outside, 3.76 m and 15.05 m from their slots. The excluded engine comparison also failed. That completed run recorded 32 checks and no SQF errors. A separately labelled open-door diagnostic is in progress; the failure is retained |
| Identifiable artillery spotters | Explicit assignment to existing binocular-equipped units; radio inventory not required | Assignment passed; observation loss and communication changes still need live cases |
| Warning and finite artillery fire | Opening aim exclusion, deliberate offset, corrected finite bursts, relocation reset and cooldown | Real finite mortar fire passed; multi-burst ranging, moving targets and safety rejection still need live coverage |
| Counter-battery without mandatory radar | Firing-event acquisition; radar shortens delay | Real normal/radar acquisition and finite replies passed in runtime-20260926-124153 |
| Mixed convoy movement | Bounded immediate-predecessor trails, tracked native movement, wheeled pathing, size-aware spacing | Predecessor column and right-angle turn passed in runtime-20260926-132003; that run was interrupted before destination/contact completion |
| Convoy destination cargo unloading | Arrival halt with cargo-only unloading | Lead stalled-order recovery fixed the earlier failures. Arrival/unload and passenger move-clear passed in runtime-20260926-131507; retest after latest trail changes remains |
| Convoy armed crew and contact | Mounted engagement under existing rules; push through, halt and unload if pinned | Manual halt retains crew; moving/pinned contact and actual gunner engagement need live cases |
| Headless support | Owner-local commands, acknowledgements, ordered settings, migration cleanup | Both WMP transfers and owner-local orders passed; ACE-initiated transfer, abrupt disconnect and JIP remain |
| Feature gating and AI-mod compatibility | Separate feature gates, group exclusions, pause, Zeus priority and LAMBS mode handling | Static gates passed; live switching/cleanup and the compatibility matrix remain |
| Source review-derived improvements | Capability checks, shared passenger safety, cross-owner support/reporting, cover checks and optional infantry avoidance | Implemented paths need expanded combat/locality acceptance |
| Further source-review proposals | Mechanized overwatch, casualty assignment and prisoner recovery | Not implemented or accepted; assessment remains separate from shipped features |
| Understandable QA | In-game phase card, expected behaviour, individual results and report generator | Reports preserve failures and missing completion; additional live cases are listed above |
| Defaults and documentation | Complete AI configuration defaults reference and review record | Refresh wiki and PR body with final behaviour and evidence before publication |

Tests: releaseVerificationAndDeployment/test_cortex_operations.py, test_cortex_report.py, test_ai_modularity.py and test_smart_ai_pass.py. The dedicated engine suite is releaseVerificationAndDeployment/cortexQA. Its README lists case IDs, commands and limitations. Runtime reports live in .qa/pr-review-audit/runtime-*/cortex-results.md.

Passing static checks establishes regression coverage. Acceptance of each engine behaviour requires its own completed live case. A focused convoy run does not cover infantry or artillery. Its convoy migration case covers WMP transfer, not ACE-initiated transfer.

## 26 September: additive suite and threat-facing bounds

The full suite retains infantry, WMP owner transfers, convoy travel and contact, artillery, counterbattery and client UI cases. Combat and mechanics scenarios are appended. Focused convoy runs now also include moving and pinned contact; they previously omitted those scenarios. Focused runs cannot establish full-suite acceptance.

Flank and advance slots now face the known threat instead of the travel direction. WEDGE uses rear stagger; other formations use a line. Cover adjustments are limited to two metres from each slot. The client overlay measures actual frontage and depth and shows a threat axis and actual movement trails. This is an implementation change awaiting live acceptance, not a claim that formations or assault now work.

The preceding combat run, runtime-20260926-141749, recorded 29 checks and four failures with no SQF errors: flank and advance completion failed, along with flank assault entry and arrival. The fresh full run is runtime-20260926-142845. Its staged source also includes temporary suppression of leader-issued attack assignments during a drill, with restoration on cleanup and ownership recovery.

Regression evidence for this revision: 391 repository tests passed; 107 Cortex and QA SQF files checked without syntax findings. The full live run remains in progress.

The full run again failed garrison arrival, hold, the excluded engine comparison and the open-door comparisons. Both WMP headless clients did pass physical defence movement. A garrison recovery bug is fixed in the working tree: stalled MOVE commands no longer prevent the bounded no-progress retry. This correction and the four independent building-entry comparisons were added after the running mission was staged and are not yet live-verified.

## Subsequent fixes awaiting the next rebuild

The latest flank trace confirms that arrived soldiers resumed formation movement toward the leader while others were still approaching. Bounds now hold each arrival with owner-local PATH control until the next bound, restoring only features Cortex changed. The default 25-second timeout now measures lack of progress; the absolute limit is 100 seconds. Timeout still fails the drill. Threat-facing formations and cover limits remain in place.

Mixed convoys now use a size-aware spacing tolerance, bounded catch-up acceleration and longer tracked look-ahead. Wheeled path refreshes no longer repeatedly issue a stop. The new visual overlay shows actual speed and predecessor gap, and a sustained-speed assertion supplements the initial movement check.

Passenger travel orders now replay on each owner and are cancelled before unloading. QA carries four passengers in two independent cargo squads and transfers one cargo squad to a different HC from the vehicle crew. These changes remain unverified in the running mission; the next full build must test them.


## 27 September: completed expanded run and convoy comparison

The completed runtime-20260926-152525 recorded 166 checks: 142 passed and 24
failed, with three error lines from one convoy dismount-facing expression.
Convoy travel/contact/arrival and WMP owner transfer passed that scenario, but the
user subsequently observed repeated stops and startup loops. Its broad speed
threshold did not establish smooth movement. Garrison, clearing, flank completion,
morale/surrender, hearing investigation, airborne ownership/drop, remount and
withdrawal smoke remain unresolved. Advancement, regrouping, consolidation, Zeus
movement, stance, grenade evasion and several support cases passed recorded
physical checks; this is not universal acceptance.

The new convoy matrix compares all-wheeled, all-tracked and mixed fixtures, with
long straight-route sampling, actual speed/stopped fractions and explicit startup
and restart checks. The previous native-follow controller is retained as a test
comparison. The interrupted runtime-20260927-020011 preserves 31 checks and zero
SQF errors, with movement failures; no completion is claimed. The replacement
runtime-20260927-021127 includes comparison runs at 50 m and current-controller
runs at 15/30/50/75 m. Its results are pending.

Source corrections: navigation paths are no longer truncated to enforce spacing
already enforced by the speed controller; native following replaces projected
behind-predecessor recovery targets; same-owner resumes preserve trails and
cursor progress; stretched mobile convoys slow rather than abruptly stopping.
Default separation is 30 m in script and Zeus. These are hypotheses under live
comparison, not a completed convoy fix.

Cortex master and grenade evasion now default on in config and UI defaults.
Individual switches and external-controller exclusions remain. Infantry fire
control and anti-armour handlers now respect group and unit hold-fire modes.
A new actual-firing test covers hold-fire and weapons-free transitions, pending
live execution. Helicopter flight pinning no longer excludes separate passenger
squads from Cortex; operating crew remain excluded. In-flight WMP migration is
still intentionally refused by its flight-locality policy, and the audit now
reports that precondition separately rather than expecting a forbidden transfer.

Latest regression run before the new fire-control audit: 399 tests passed;
1256 production SQF files, 113 wiki pages and 85 Zeus modules passed their static
checks. New QA SQF files require their explicit syntax scan as well. No full AI
acceptance is claimed and source changes have not been pushed.

## Convoy column and halt feedback follow-up

The 021127 matrix has recorded speed, startup and restart failures. Screenshots also show lateral formation spread, which its original assertions did not measure. The next build adds a physical single-file assertion (maximum straight-route lateral deviation and predecessor ordering), continuous owner-local COLUMN enforcement, and one shared-UI notification to assigned Zeus owners per accepted halt transition, including group, grid and reason. Duplicate halt requests return before notification. These changes require in-engine verification.

Registry synchronization was also clearing navigation before ConvoyTick could preserve it. Same-owner snapshots with the same vehicle list now retain navigation through release; locality changes still discard local state. Recovery from individual obstructions, roadblock preservation and bounded recovery attempts remain outstanding, not implemented acceptance claims.

The 023448 audit entered VR with its client and two headless clients. Its first baseline single-file failure measures displacement from the ideal route, including the leader, and can reject a correctly aligned column shifted sideways. The source assertion is corrected to compare followers with predecessors on the straight leg; retain that earlier result as a measurement defect, not a movement fix. This correction requires rebuilding.

Calm remount now retains public passenger intent for 60 seconds, retries actual boarding on the current owner, and cancels on contact, conflicting orders or disabled features. Targeted checks pass; live acceptance and migration variants remain pending.

The hearing travel fixture previously began inside the generated investigation waypoint completion radius (after the 30 m stand-off). The listener/source placement now requires physical approach while retaining an actual nearby gunshot as the stimulus. The original failed evidence remains; the corrected fixture is not yet live-tested. Withdrawal smoke now logs actual turret weapon simulations, magazines and every Fired event to distinguish launcher discovery from firing failure.

## Root-cause convoy comparison

The 024723 focused run still reproduced lateral spread while the engine formation value was COLUMN. Chaining versus group-leader fallback was insufficient; do not call the wedge resolved. Runtime 025120 compares the native baseline at 30 m with one change per fixture: direct lead doMove, forceSpeed, and omission of lead setConvoySeparation. Existing full and focused matrices remain available. The comparison is pending.

Bounded retry exhaustion now requests STALLED through the current-owner/revision-validated server halt API, with the affected registered vehicle. STALLED keeps cargo aboard and reports the affected vehicle/grid to assigned Zeus players. This provides a persistent failure state, not automatic obstacle clearance or accepted individual roadblock recovery.

Trail acquisition has a deterministic gap dependency: the initial predecessor point is outside the 18 m capture radius at 30/50 m gaps, and a lateral formation offset can keep every recorded point outside that radius. Source now accepts a recorded point ahead in a forward cone within 150 m when near-trail acquisition fails, preserving cursor direction and rejecting behind-vehicle points. Initial setup no longer restores pre-convoy driving orders, and lead startup resumes native following rather than inserting a personal destination. These changes still require the rebuilt physical column matrix. Driver-versus-vehicle follow and force-speed-only controls did not reproduce the wedge; direct lead movement did increase stops.


### 27 September: physical column results and missing QA

Runtime `runtime-20260927-030530` completed 79 checks with no SQF error lines and five failed assertions. Wheeled 30/50 and tracked 30 held measured single file; tracked 50 failed lateral offset, speed and restart count; mixed 30 failed resume progress and mixed 50 failed speed. The forward-trail acquisition change is an improvement, not full convoy acceptance.

Added runnable CORE gate cases (five refusal/stationary checks paired with reopened physical defence arrival), vehicle AT standoff, actual projectile gunnery priority/hold fire, and a focused convoy occupant suite. Existing suites remain in the `all` runner. New catalogue diary and scope label distinguish a focused run from complete coverage. CORE/gunnery cases have not yet been executed. Many catalogue entries still lack runnable coverage; the register explicitly retains that gap.

User confirmed unintended operating-crew and same/separate-group cargo exits. Found seat-maintenance only covered passengers and checked vehicle assignment without the occupied seat assignment. Extended owner-local repair to all occupied roles, retaining operating crew on halt; no teleport, forced re-entry or lock-in is introduced. Requires physical acceptance. Seat test records GetOutMan for all actors and actual seat occupancy before/after an intentional cargo-unload halt.

Found convoy-matrix cleanup only deleted current `crew vehicle`, leaving departed fixture actors behind. It now deletes its original roster, includes an operating-crew retention assertion, and labels/logs case ownership and exits. Unselected infantry fixtures no longer spawn; completed infantry/convoy fixtures clean up before following cases. Broad background deletion was rejected by automatic approval review and was not applied; unrelated full-pack stations remain intact.


### Occupant retention follow-up

Runtime `runtime-20260927-032658`: all eight SEATS checks passed, including actual travel, zero observed exits, same-group and separate-group cargo retention, commanded cargo-only unloading, operating crew retention and cleanup. All ten CORE gate checks passed. The overall run remains FAIL (38 checks, two gunnery/standoff findings, zero SQF errors). The gunnery fixture was outside the tactical processing range and attempted to tune a non-runtime configuration key; the corrected source requires another run. These results do not establish complete AI acceptance.

The seat suite now adds an explicit WMP migration to two different headless owners, samples every actor's physical seat during continued travel, and performs the deliberate cargo-only halt while ownership remains split. The fixture-only server pin is released before requesting migration. ACE automatic transfer and HC disconnect remain separate, unverified variants. This expanded case is pending live results.

Runtime `runtime-20260927-034106` passed all 12 focused SEATS checks: server travel/retention, two-HC adoption, physical continued travel with no sampled dismount, cargo-only unload across owners, crew retention and full roster cleanup. Server completed with zero findings. HC1 owned operating crew plus same-group passengers; HC2 owned the separate passenger squad. ACE automatic transfers and disconnect/contact variants remain unverified. All 406 unit tests, 1256 production SQF files, 113 wiki pages and 85 Zeus parity checks pass; these do not resolve the outstanding convoy movement or other AI acceptance failures.

The corrected gunnery encounter explicitly faces enemies toward the APC and waits for real engine AT detection (no reveal). Runtime 035952 passed natural detection, actual AT-directed fire and hold-fire, but standoff failed despite 84.7 m movement because the distance baseline was sampled after activation and the phase-card delay. The baseline now precedes activation; the unchanged +60 m distance requirement is being rerun. Added independent pedestrian avoidance QA (unexecuted), without replacing any convoy tests.

Runtime 040456: corrected gunnery server suite completed with zero findings. Actual AT fire, hold-fire, natural detection, disabled stationary control and +60 m physical threat separation with crew retention passed. Diagnostics confirmed eligible=true, zeusHeld=false, CONTACT and an actual MOVE destination. The combined report remains INCOMPLETE because the run was stopped before client UI completion; do not describe it as full audit acceptance. Cover is the next live case.

Source update after the paused live campaign: the on-demand WMP Diagnostics report now exposes durable Cortex ownership for remount, INVESTIGATE/SEARCH transitions, coordinated support and delayed artillery relocation. Expired deadlines, assignment conflicts, closed gates and token disagreement report ERROR instead of appearing as an idle managed group. This adds no recurring poller and remains limited to 20 rows per controller category. Static validation is required; live acceptance remains pending and Arma was not opened for this update.

Stop/restart source audit: stopping Cortex now invalidates every public artillery shoot-and-scoot token plus attack-run flare phase/cooldown state. Already sleeping CBA callbacks cannot regain authority after a quick restart. The world-vehicle scan runs only during the administrative stop path, preserving the 100-group runtime budget. Static validation is required; no game launch was used.

Cover runtime 040903 recorded arrival but failed its solid-wall check. The fixture ray incorrectly mixed a sea-level start with terrain-relative actors. Corrected AGL-to-ASL conversion; runtime 041148 passed all four COVER checks, with physically separate positions and a fixture wall between the threat ray and each soldier. Server zero findings. This does not cover all terrain or owner variants.

Landing configuration authority rejection now exits at function scope; payload length/types/finite numbers are checked before clamping or mutation. Runtime 041916 passed three malformed-input rejections, state preservation, real touchdown/hold, and cancellation with physical redirected flight and released controller. Server zero findings. Unauthorized remote requests still need a dedicated negative runtime case. Native UI inspection found the vehicles page readable at the current resolution; no general layout acceptance claimed.

Avoidance runtime 041548 failed sustained stop/hold; no injury and subsequent travel passed. The fixture allowed native movement during the phase-card delay before registering the controller. Source now starts the controller first, retains the approach case, adds a close occupied-corridor case and logs minimum separation plus corridor stop requests. Retest pending. 406 regression tests, 1256 SQF files, 113 wiki pages and 85 Zeus modules pass static gates.


Avoidance runtime 042448 completed 23 checks, one failure and zero SQF errors. Close-corridor stop/hold, physical pedestrian clearance and resume passed; the approach stop/hold failed and remains recorded. The approach observation now begins immediately after controller registration, with the instruction delay before the route is issued.

Convoy path handover now selects recorded-path driving by actual AI steering capability rather than excluding every tracked class. Normal formation movement is stopped once when path control is acquired; refreshed paths do not repeat that stop. Native recovery/release clears acquisition state. This is pending physical acceptance in runtime 043245 (wheeled, tracked and mixed columns at 30/50 m). Regression gates: 406 tests, 1256 SQF files, 113 wiki pages and 85 Zeus modules passed. Gunnery visual telemetry now distinguishes its completed natural-detection prerequisite from target assignment and shows measured travel and separation gained against the unchanged requirements; this display change requires the next rebuilt gunnery run.


Runtime 043245 exposed a second convoy issue while testing the handover: the trailing vehicle kept about 30 km/h despite a recorded forced limit below 10 km/h and compressed to about 5 m. Source now sends the calculated metres-per-second speed in each recorded path point and refreshes braking even inside the gap band. Added a separate physical spacing assertion (at least 80 percent of post-start samples inside the size-aware tolerance band), retaining all prior column/speed/restart tests. These latest speed/spacing changes are NOT in runtime 043245; they need a fresh build after that run completes. Current source passes 406 regression tests and production plus changed-QA SQF syntax validation. No complete convoy acceptance is claimed.


Runtime 043245 finished both server and client: FAIL, 91 checks, eight server findings, zero SQF error lines. Failures: tracked-30 operating crew, tracked-50 alignment/halt/turnaround/operating crew, mixed-30 halt/turnaround, mixed-50 operating crew. Exit events identify gunner/commander GET OUT after halt; authoritative cargo and full seat diagnostics are added to the next run to distinguish classification from native assignment changes. Primary driver/gunner/commander roles are now excluded from passenger classification even if the engine person-turret flag is set; true cargo and FFV turret passengers remain eligible. This protection is pending live acceptance.

Added runContact.sqf and contact focus, retained in all: independent wall-occlusion prerequisite, no hidden acquisition, enemy physically walking around the screen, natural sighting and live contact phase. No reveal or injected knowledge. This is implemented but unexecuted; coverage remains partial. Full regression had one obsolete text-contract error after the stricter seat guard; corrected contract and all 35 Cortex contract tests pass, with other full-suite tests passing. SQF, wiki and Zeus parity gates pass. Rebuilt convoycolumn run launched with the path speed field, spacing assertion, seat-role protection and halt diagnostics; results pending.


Runtime 044808 is still running. Its wheeled-30 case passed column and continuous speed but failed the new measured spacing requirement: in-band samples [42,0]/60, rear gap 39.3 to 97.7 m. Source now adds measured follower-speed catch-up pacing to the lead outside contact (5 km/h floor, no added hard-stop), and proportional follower correction toward requested spacing. These changes are NOT in the live runtime and need a fresh acceptance run after completion. Cortex contract tests (35) and production SQF syntax (1256 files) pass; physical acceptance is not claimed.

The existing runConvoySeats sequence now repeats with a tracked APC escort after its unchanged wheeled escort case, including same/separate cargo, two-HC migration, physical travel, cargo-only halt and original-roster cleanup. New IDs use TRACKED-SEATS; new variant remains unexecuted. This closes a fixture coverage gap, not an acceptance gap by itself.


Runtime 044808 confirmed the APC exit root cause: fullCrew reports primary gunner and commander rows with personTurret=true. The earlier broad flag-only passenger predicate therefore selected operating crew. With role-qualified classification, tracked-30 halt, resume, no-turnaround and all operating-crew retention passed; the halt cargo array is empty. Spacing still failed, so this is narrow evidence only. The same flag-only condition also excluded those primary gunners from convoy mounted-fire responses; source now gates by passenger classification instead. Airborne turret-passenger selection now explicitly excludes primary roles too. These follow-on fixes require live retests; the running mission predates them.


Runtime 044808 finished both sides: FAIL, 97 checks, nine findings, zero SQF error lines. All six operating-crew retention checks passed with role-qualified classification. Remaining findings include six spacing cases, wheeled-30 startup loop, mixed-30 halt and turnaround. The new catch-up pacing is source-only until its rebuilt run.

Found retreat smoke searched only owner-local artillery. It now passes an optional SUPPORT/SMOKE requester group to the existing server artillery API; HC sender ownership, requester eligibility, communications, same-side selection and both feature gates are validated. HE spotter rules remain unchanged. Queued smoke tracks the requester gates. Added runArtillerySmoke.sqf with actual two-shell smoke and near-ground target delivery measurements, disabled-parent/child refusal and no-fire checks; natural withdrawal triggers, missing-ammo and HC combinations remain pending. Rebuilt artillerysmoke audit launched; results pending. Latest complete regression: 406 passed; SQF 1256, wiki 113 and Zeus parity 85 passed before the documentation-only update.


Runtime 050329 completed FAIL: 20 checks, four smoke findings, zero SQF errors. Diagnostic runtime 050957 confirms the mortar contains eight smoke rounds and getArtilleryAmmo includes that magazine, but the selector rejects it. Combined profile logging exceeded the engine line limit; source now logs each profile separately. No speculative effectsSmoke classifier added: live HE and flare profiles share that field. Standoff screenshot threat -1 represented no assigned gunner target, not proof of no detection; updated observer already separates natural detection, physical travel and separation.


Runtime 051610 identifies the smoke root cause: Smoke_82mm_AMOS_White is shotDeploy, usage flags 0, zero direct/indirect damage, submunition SmokeShellArty. Source now classifies bounded smoke payload chains (maximum four levels), rejecting damaging carriers and mixed/unrecognised payloads. Added smoke-only inventory HE rejection assertion without removing previous cases. Production SQF 1256 and all 406 repository tests pass. Actual firing/delivery and the new inventory assertion still require the rebuilt audit; current live run predates the fix.


Runtime 052234 completed FAIL: 21 checks, two delivery/fire findings, zero SQF errors. Smoke classification and smoke-only HE rejection passed; no rounds fired and the mission quarantined. Fixture had BLUE Never Fire mode. Source now tests disabled feature gates with YELLOW, adds an independent BLUE rejection case, then explicitly opens fire. Artillery request, mission-step and owner-shot paths now respect BLUE without reserving an impossible new mission. Smoke delivery observation follows the real SubmunitionCreated payload instead of assuming the carrier reaches ground. Full 406 tests and SQF/QA syntax pass. Rebuilt runtime 052844 is running; physical outcome remains pending.


Runtime 052844 server smoke assertions all passed: two actual Smoke_82mm_AMOS_White rounds at 05:30:01/04, real SmokeShellArty payloads at [1782.32,1489.76,-0.094] and [1787.67,1494.22,-0.094], both near [1800,1500,0]. No extra shots over the follow-up interval; smoke-only inventory refused HE. Parent/child gates and BLUE rejection passed. This proves the server-owned scripted request path only, not natural withdrawal or HC combinations. Awaiting client completion before archiving/restarting.


Smoke runtime 052844 completed PASS, 22 checks, zero SQF errors, both server/client completed. Added source-only empty-inventory, no-projectile and completed-lock-release cases afterwards. Convoy runtime 053239 is still running. Wheeled-30 passed single file/speed/progress/halt/crew but failed spacing/restarts; wheeled-50 also failed lateral alignment. Telemetry shows rear truck still in native MOVE at 29 km/h while middle truck is path-controlled STOP, rear gap 6.49 m despite 7 km/h forced limit. Source now relinquishes native formation for steering-capable followers immediately on setup/resume and waits for the first usable predecessor trail, instead of falling back to doFollow before trail acquisition. No physical pass claimed for this change. All 406 regression tests pass; fresh convoy build required after current run completes.


Added runScheduler.sqf (scheduler focus and all) with twelve independent 80 m physical squad movements through the real minimum-budget scheduler, measured first-run latency, arrival and terminal-job retirement. Unexecuted; distance tiers/FPS/HC remain outstanding. Current convoy run 053239 also reproduces tracked halt failures. Source crew maintenance no longer reissues orderGetIn to unchanged mounted occupants every five seconds; it repairs/new-assigns only and issues HALT after seat maintenance. Added failed-halt speed/command/destination/locality evidence. This is an unverified correction, not a live halt pass. Regression 406 passed.


Convoy runtime 053239 completed FAIL: 97 checks, 15 findings, zero SQF errors, both server/client complete. All six crew-retention checks passed; all six spacing checks failed, with wheeled/mixed-30 restart findings and tracked halt/turnaround findings. Rebuilding the identical matrix with immediate steering handover and non-redundant mounted seat orders. Thresholds unchanged.


Runtime 054758 wheeled-30 passed the full case: spacing [58,60]/60, maximum lateral 4.17 m, average speeds 29.30/29.66/29.90 km/h, zero restarts/stops, halt, forward resume/no turnaround, retained crew and cleanup. Remaining matrix still running, not broad acceptance. Added runProfiles.sqf for resolver precedence/alias/fallback/aggression/skill invariants (explicitly configuration-only, unexecuted), plus >= probability rejection so a random zero cannot start a zero-chance flank/advance/coordinated assault. Regression 406 passed.


Runtime 054758 wheeled-50 spacing also passed [60,60]/60, with no restarts. Tracked halt still fails: rear vehicle speed 29.84/30.12 km/h while forcedSpeed=0 and driver command STOP. Source explicitly clears setDriveOnPath on HALT before applying the stop; engine verification pending. Added runCoordinated.sqf natural contact/two-team rally/disabled hold/opposite-side physical assault, no lease injection. New coordinated suite is unexecuted. Regression 406 passed before the small explicit-path-clear addition.

## 30 September: movement ownership and combat preservation

The latest source-only checkpoints replace competing movement commands with explicit group and actor ownership. Support, flank, advance, assault, regroup and grenade evasion now preserve unrelated owners instead of clearing one another. Zeus replacement orders revoke the affected Cortex movement, and a responder whose requester leaves contact releases its support reservation without erasing a different manoeuvre.

Combat is preserved across those transitions. Regroup no longer clears targets or forces every soldier to reform on a fixed timer. Flank recovery retains known targets while stragglers rejoin. Coordinated covering soldiers can temporarily leave a path-disabled hold to evade a live grenade, and the support controller respects that actor reservation. Single- and multi-squad routes use a wider sampled fire corridor and retain the selected side of a supporting squad's fire axis.

The final assault now treats grenades as optional support rather than a phase gate. A failed, unavailable or cancelled throw cannot freeze the movement sequence. Completed flank and advance actions can proceed through approach, assault, clear-through and consolidation while covering elements continue to engage.

These changes are covered by source contracts, the SQF validator, wiki checks and Zeus/script parity checks. They have not been run in a newly built Arma audit under the current no-launch instruction, so no new physical movement, combat-effectiveness or performance pass is claimed here.

Convoy wedge analysis found that the path owner still used centre-to-centre distance for speed control. A follower displaced sideways by the requested spacing could therefore be considered correctly spaced and retain a stable V even while `COLUMN` remained the reported group formation. Aligned vehicle pairs now control against forward separation, keep a bounded 5 km/h alignment speed while physically clear, and retain the existing Euclidean control on turns. Lead pacing uses the same aligned-pair measurement. The source contract and convoy documentation cover this rule; physical confirmation remains queued because Arma launches are paused.

The broader inert-AI review found a separate movement-lifecycle fault. Flank and advance jobs used a fixed five-minute movement lease, while the drill itself lived in another scheduler job. An expired lease or a lost/starved callback could leave the drill present, block replacement tactics and retain owned PATH/behaviour restrictions. Drills now publish a heartbeat, standalone drills renew a 90-second movement lease each step, and GroupTick ends a controller silent for 30 seconds through the common restoration path. Coordinated bounds use the same heartbeat while retaining their server lease. SafeStart/ENDEX refresh a 60-second resumption grace. On-demand WMP diagnostics expose heartbeat age, threshold, movement lease and grace. Source contracts and static validation cover this recovery; an Arma retest is queued under the current no-launch instruction.

The state-gate audit also found start-only behaviour in two runtime switches. Disabling Investigation during an ordinary investigation, or Post-contact during SECURITY/SEARCH, previously left the old movement alive until arrival or timeout. Active INVESTIGATE, SECURITY, SEARCH and REGROUP phases now recheck their owning gate and immediately use common CALM cleanup, including search-team return and owned waypoint/settings restoration. Static regression covers the transition; UI and physical acceptance are queued while game launches are paused.

Coordinated support had a related distributed-state leak: local gate closure could stop movement without rejecting the accepted server token, leaving a dead responder in the support job until lease expiry. Contact, Reinforcement and Coordinated Assault closure now reject the exact lease snapshot before clearing local token, role and owned movement state. The server revalidates sender, token and snapshot. Static regression covers both closure branches; cross-owner physical acceptance remains queued.

Pending calm remount also lost its public intent during group-owner adoption because migration cleanup deliberately disables boarding. Adoption now captures the original passenger/vehicle/deadline record, retires old-owner commands, then republishes only living local passengers that remain unassigned or assigned to the same vehicle. Zeus and replacement assignments win, and the deadline is never renewed. Static regression covers the handover; physical HC boarding remains queued.

Adoption previously relied on the following GroupTick to notice a newly closed Investigation, report/hearing, Post-contact, Vehicles or Remount gate. That allowed the new owner to issue one stale search or boarding intent first. Locality recovery now rechecks the applicable gates before any semantic movement is rebuilt and clears a refused transition immediately. Static ordering coverage passes; live migration while toggling settings remains queued.

Delayed artillery work now carries and enforces its owner. Counter-battery acquisition rejects a delayed callback immediately when its live switch closes. Shoot-and-scoot publishes SUPPORT or COUNTER purpose with its durable token, and both ordinary retries and locality resumption recheck the matching artillery feature plus shoot-and-scoot setting before issuing movement. Static contracts pass; migration during the firing-to-relocation transition remains queued.

## 1 October: tactical initiative and coordinated tempo

Contact no longer makes independent random decisions which can reject both flank and advance. One weighted profile choice establishes the preferred style, then the alternate enabled tactic is attempted immediately when the preferred route or actor gate cannot start. Militia and line profiles favour direct bounds; veteran and elite profiles increasingly favour flank routes. Positive profile weights select style rather than adding a second idle outcome.

Prepared coordinated attacks no longer wait for physical assembly. An acknowledged responder with communications and a safe shared-contact route enters directly from its live position; distinct rally areas remain a fallback while dispatch is pending. Once one safe approach is dispatched, route-rejected reservations are released so those squads resume autonomous combat. During the attack, a responder below four combat-effective dismounts is retired immediately instead of leaving the coordinator alive until lease expiry. Failed bounds yield for eight seconds, and the server watchdog follows the configured owner-side bound timeout rather than always waiting 180 seconds.

These are bounded group-level checks in the existing two-second coordinator, with no per-unit worker or recurring global scan. Source contracts cover direct accepted-contact dispatch, release paths, exact lease validation, casualty retirement and watchdogs. Physical tempo, engagement effectiveness, owner migration and the 50-group mixed frame-time budget still require the next rebuilt audit.

## 1 October: installed LAMBS ownership audit

The four supplied Workshop packages were inspected from their locally installed PBOs, including the shipped LAMBS_Danger 2.6.2.1 SQF and FSM source. The earlier group switch alone was insufficient: it blocks a new LAMBS group decision, but an already queued callback can still begin a flank or assault and later restore formation, speed and attack settings over Cortex movement.

LAMBS publishes `lambs_danger_isExecutingTactic` before scheduling those delayed callbacks. Shared ownership now refuses a fresh Cortex movement lease while that marker is active, while any unit carries LAMBS forced movement, or while an explicit LAMBS Waypoint `task*` owns the group. Cortex does not clear or rewrite upstream state; it leaves that responder under LAMBS and permits another group to be selected. Diagnostics show LAMBS-owned groups and accumulated busy-lease refusals. Scoped lease cleanup was also added to calm, retreat, gate-close and orphan-token paths so a same-tick state transition cannot leave LAMBS disabled until the next discovery pass.

The installed Turrets, Suppression and RPG PBOs confirm they are configuration companions; Cortex does not disable them. No LAMBS code is copied into WMP. Static validation covers the ownership contract. A rebuilt multiplayer run with LAMBS loaded, queued and active tactics, locality migration and Zeus replacement remains queued under the no-launch instruction.

## 1 October: paired LAMBS compatibility audit

The canonical full-pack launcher now supports `-CortexFocus lambs` and an explicit `-IncludeLambs` arm that loads the installed Danger, Turrets, Suppression and RPG packages on every audit process. Omitting the switch runs the same Cortex fallback fixture without LAMBS.

The standalone arm requires every soldier to physically move to and hold an assigned defence position. The loaded arm additionally refuses queued/running LAMBS tactics, forced movement and LAMBS waypoint tasks; checks false and true baseline restoration; transfers the public lease to a real headless-client owner for renewal and release; returns the group to the server; then interrupts a live Cortex lease with Zeus and requires every soldier to execute the ordinary replacement waypoint without route resurrection. `Waldo_AIPass_LambsMode` now has its own 57th coverage case.

The first rebuilt standalone attempt at `runtime-20261001-105254` is invalid evidence: the audit's
arrival predicate omitted parentheses around `findIf`, producing repeated SQF type errors before an
outcome could be observed. The predicate and every matching comparison in the fixture are corrected,
covered by a regression assertion and queued for an immediate clean rerun.

Static validation passed 268 focused Cortex tests, all 1,265 SQF files, all 113 wiki pages, all 85 Zeus/script parity checks, the executable 57-case/165-setting coverage audit, and `git diff --check`. Arma remained closed; both paired live arms are queued and neither is claimed accepted.

## 1 October: LAMBS-first building backend

Installed LAMBS Waypoints is now the preferred backend for public Cortex garrison and clear-building
orders in both Danger ownership modes. Cortex calls only the installed public task functions. It
retains the spawned CQB handle, pre-task group/unit state, task-created waypoints and a public semantic
intent so stop, replacement orders, Zeus takeover and locality migration can retire or reconstruct the
task without copying LAMBS implementation or leaving a stale controller behind. The independent
Cortex building controller remains the automatic fallback when LAMBS is absent and can be selected
per call with `useLambs=false`.

The building audit now treats these as two distinct paths. The installed arm requires physical
garrison arrival and hold, at least two CQB participants, multiple real room visits and physical
execution of a replacement order after release. The additive native arm still covers multiple house
models, 2/6/12-person clears, casualty replacement and locked-door behavior. Static validation passes;
the rebuilt live building audit is pending and no new CQB acceptance is claimed yet.

## 1 October: dedicated lighting and equipment audit

Lighting no longer relies only on direct skill-number checks inside the profile fixture. A dedicated `lighting` focus dynamically discovers NVG-capable and ordinary HMD classes from `CfgWeapons`, so modded equipment is assessed by declared vision capability rather than classname. It verifies darkness clamping, partial NVG recovery, an ordinary-HMD control and preservation of the original skill snapshot across real WMP headless-client adoption.

The same fixture performs a physical night comparison. The observer starts with its weapon light forced off and must neither acquire nor fire. After the light is physically on, the forward target must be acquired and receive actual fire while an equally distant rear target remains outside the beam. Spotting skill must remain unchanged: flashlights illuminate through the engine and do not grant omnidirectional Cortex awareness.

Static validation passed 268 focused Cortex tests, all 1,265 SQF files, all 113 wiki pages, all 85 Zeus/script parity checks, the exact coverage report and `git diff --check`. Arma remained closed; the new physical detection, firing and HC cases are queued and unaccepted.

## 3 October: aircraft continuity and real missile defence

The completed `runtime-20261003-182908` air batch recorded 16 server findings and zero client
findings. Its helicopter lateral case fired five real rounds but remained in `INGRESS`, repeatedly
slowed and circled close to its start. The fixed-wing standoff case fired four rounds but never
completed egress. The exact Zeus waypoint was retained, yet the helicopter travelled only about
55 metres toward a replacement more than 680 metres away. These are controller failures, not
accepted attack patterns. The earlier missile fixture also never produced a real launcher shot or
incoming-missile event, so its defensive outcome is invalid evidence.

Source now uses one group-level native movement command per ingress, attack and egress leg. Useful
progress means closing the active leg; local circles cannot reset the progress clock, and Cortex no
longer replans a pattern while it is running. Completion reselects the unchanged authored waypoint.
Zeus handover similarly leaves the authenticated curator waypoint as the sole movement authority
instead of layering an individual pilot command over it. The audit hard-fails more than five seconds
of low-speed flight or a long circular path with little net displacement.

The missile comparison now starts both native and Cortex helicopters in forward crossing flight and
requires a real launcher firing event, real `IncomingMissile`, real countermeasure expenditure,
physical departure from the projected uncorrected path and survival. The launcher is at tactical
range rather than the former 400-metre point-blank position. Cortex applies two bounded defensive
break impulses while preserving forward energy. The landing and deceleration helpers yield during
that finite defensive lease so independent WMP flight controllers cannot cancel one another.

Static validation passes all 642 repository tests and all 1,276 SQF files. The rebuilt focused air
batch remains required; none of the new physical behavior is claimed accepted yet.

## 4 October: uneven terrain and finite fixed-wing delivery

The flat VR range could not show whether infantry avenues, vehicle routes or defensive positions
remain usable on real ground. The additive `terrain` focus now refuses VR, searches bounded dry
sectors for at least seven metres of relief and measurable roughness, and exercises the production
avenue selector for infantry and vehicles. It requires physical movement and terrain-aware defence
occupation. The shared selector now reuses its bounded 20-metre fire-lane samples for water,
steepness, cumulative relief and road scoring; the former three interior terrain checks could miss
a narrow ridge, ditch or water strip on a long leg. No extra loop or background worker was added.
Aircraft planning now retains the uncapped lift requirement as diagnostics and refuses a Cortex run
when that requirement exceeds the bounded platform correction. Native control remains untouched in
that case; the planner no longer returns a route it has already measured below safe clearance and
waits for the emergency proximity abort after committing the aircraft.
This is queued for the next batched non-VR launch and is not yet live acceptance.

The completed `runtime-20261004-083928` air batch recorded 35 server findings. Every fixed-wing
surface profile reached ATTACK but released no weapon. The guided case exposed a loaded, aligned,
terrain-clear firing solution before the engine rejected `fireAtTarget` for the pilot-operated fixed
weapon; the moving air-to-air intercept did release a real missile. The production controller now
retains the same range, angle, alignment, terrain and ballistic gates but asks the actual pilot to
release a fixed surface weapon. Independently aimed turrets keep their native request path, and a
real `Fired` event remains the only proof of release.

A fixed-wing pass also measures signed progress along its immutable delivery axis. Once it has
crossed 350 metres beyond the target without releasing, it records `DELIVERY_MISSED` and proceeds to
egress instead of circling the attack endpoint. The audit treats the weapon result as failed while
separately requiring a finite, non-circular egress. Static validation passes all 247 focused Cortex
tests and all 1,279 SQF files. Physical release, impact, safe terrain clearance and handover remain
queued for the next rebuilt batch.
