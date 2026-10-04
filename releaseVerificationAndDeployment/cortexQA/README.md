# Cortex acceptance suite

Run from the PR worktree with the checked launcher:

```powershell
./releaseVerificationAndDeployment/launch_pr_review_audit.ps1 -HeadlessClients 2 -CortexAudit
```

This is a disposable, state-mutating audit. It creates its own remote infantry, house, mixed convoy and mortar, restores the tunable settings it changed, and removes its fixtures. It runs real production functions. The client follows after the server and uses the actual custom UI controls and Apply/Cancel handlers. It leaves Cortex Control open for visual review. It does not simulate keyboard or pointer use.

During the run, a test card states what to watch and shows the latest recorded results. Open Zeus and choose **Inspect current test in Zeus** to move the camera to the fixtures. Ownership transfers can take several seconds; **Transferring** is a pending state. A persistent mismatch or failed adoption requires investigation. The briefing diary retains the server results and client summary.

The scripts emit `WMP CORTEX QA|case|PASS/FAIL|detail`, followed by separate server and client completion summaries. A missing completion marker is an incomplete run, never a pass. Inspect all four RPT files for SQF errors as well as case results.

| Cases | Assertions |
| --- | --- |
| ORD-01 through ORD-06 | Disabled-state explanation, defence, empty garrison preserving a prior order, physical defence arrival and hold, three-dimensional building arrival and hold, immediate hand-back cleanup, return to automatic eligibility |
| HC-01 through HC-04 | Two registered owners, real WMP migration and adoption, acknowledged owner-local orders and physical defence arrival on each HC, return to server |
| CNV-00 through CNV-10 | Cargo starts and stays aboard; every mixed-convoy vehicle moves after controller startup; manual halt unloads cargo and passengers move clear; resume adopts script-seated cargo, transfers the convoy to an HC, reaches the final waypoint and unloads; operating crew remain aboard; release removes the controller |
| ART-01 through ART-04 | Explicit spotter assignment, real fire request, actual Fired events, finite round count |
| CB-NORMAL and CB-RADAR | Real enemy mortar emission, measured acquisition delay, two real response rounds and no additional rounds; radar registration and removal |
| UI-01 through UI-06 | Custom display, all eight pages, pending values across tabs, Cancel, authoritative Apply, reservation cleanup |

Additional live coverage is required for: ACE's own transfer workflow; HC disconnect while an order or fire mission is pending; joining client replay; pinned/mobile convoy ambushes; spotter loss and target-location reset; exact selected-object ZEN placement; mouse/keyboard operation, aspect ratios, all themes and manual visual review. Record these separately until executable cases cover them.

Added cases require a fresh completed run. An earlier pass does not cover a subsequently expanded suite. Results belong to the timestamped `.qa/pr-review-audit/runtime-*` run and exact staged source.

Cortex audit launches bypass role selection and automatically enter the disposable mission. This applies only to `-CortexAudit`; normal audit launches retain their lobby workflow.

To isolate convoy faults, add `-CortexFocus convoy`; this includes convoy transfer but excludes infantry and artillery. Use `-CortexFocus infantry` for physical defence/garrison execution and infantry orders on both HCs. Order-accepted checks alone do not establish behavioural success. Generate a readable case-by-case result with `python releaseVerificationAndDeployment/report_cortex_audit.py <runtime-directory>`. Missing completion markers produce INCOMPLETE when no failure has been recorded; any failed assertion or SQF error produces FAIL. The separate Run complete field still remains no until both server and client finish, even when a failure is already known. Each case includes its recorded measurements as well as the RPT location.

Passenger exits are logged with the active convoy phase. Any exit during TRAVEL fails the retention case. The manual-stop card explicitly announces the deliberate unload so it cannot be confused with an unexpected travel dismount.

## Reusable scenario template

Keep this checked-in suite as the starting point for Cortex behaviour acceptance. Build a fresh disposable mission for each source revision; keep timestamped reports from failed runs as well as successful runs.

Each scenario should follow this sequence:

1. Create or select a correctly configured fixture. Verify actual simulation, placement, ownership, crew, building positions and required feature switches before testing behaviour.
2. Show a phase card stating what the operator should see. Publish destinations and distances for movement cases; show the live feature switches that govern the case.
3. Issue the real public function or module request. Record acceptance separately from execution.
4. Observe the physical outcome for every expected actor. Reject missing/dead actors, unvisited positions, wrong floors, premature dismounts and stalled movement. A timeout is a failure or incomplete result, never arrival.
5. Check sustained behaviour, cancellation, replacement and cleanup. Repeat the applicable cases after ownership transfer.
6. Restore the original settings and clearly label that restoration. Save server and client completion, individual case results, diagnostics and SQF errors in the report.

For movement faults, retain an independent engine-command comparison with Cortex excluded, and verify that comparison's own fixture and ownership. A faulty control case cannot establish an engine limitation. Do not teleport actors into their expected destinations or directly set completion flags to obtain a pass.

The current infantry setup includes two assigned soldiers, visible destination markers, remaining distances, command/destination diagnostics, and a separate excluded comparison soldier. The comparison house is mission-placed with simulation explicitly enabled. The builder regression test checks that generated setting. Keep collision geometry intact; do not use a decorative/simple object as a pathfinding fixture.

Extend the existing purpose cases instead of replacing the suite whenever a fault appears. A new check needs a fresh live result; static regression passes alone do not certify it. Current unresolved behaviour and evidence are recorded in `../cortex_work_status.md` and `../cortex_logic_review.md`.

The infantry suite retains the original garrison result before an explicitly labelled open-door diagnostic. That comparison opens the fixture doors, reissues movement, and records separate outcomes for Cortex and an excluded, server-pinned soldier. A diagnostic success does not turn the original failed garrison case into a pass.

## Full AI coverage

`COVERAGE.md` specifies 63 behaviour cases, with an exact mapping of every declared AI setting and production AI source in `coverage.json`. A mapped setting means the test is specified, not executed. The regression check rejects new settings or production sources without a case.

Use `-CortexFocus combat` for real contact, flank/assault and waypoint advance. These fixtures must be inside the configured tactical distance from the actual player; Zeus camera position does not satisfy that gate. The test records this prerequisite, movement, actual firing, real drill ending and disable cleanup. The first combat run at the distant infantry range did not satisfy the distance prerequisite and is not valid acceptance evidence.

## Additive runs

The default `-CortexFocus all` retains infantry, both headless clients, convoy travel and ambushes, artillery, counterbattery, combat movement, mechanics and client UI checks. Focused runs are diagnostic subsets, never substitutes for full acceptance. The convoy subset includes moving contact and pinned contact as well as travel and unloading.

LAMBS compatibility uses a paired audit against the same saved fixture. Run `-CortexAudit -CortexFocus lambs` without optional LAMBS mods to prove Cortex's standalone physical movement, then repeat with `-IncludeLambs -HeadlessClients 2` to load the installed Danger, Turrets, Suppression and RPG suite. The loaded arm verifies that Cortex refuses groups already owned by a queued/running LAMBS tactic, forced move or LAMBS waypoint task; clean finite leases restore the prior LAMBS group state; a real HC owner adopts, renews and releases the lease; and a Zeus replacement order physically takes control without route resurrection. Both arms are required before compatibility is accepted.

Use `-CortexAudit -CortexFocus lighting -HeadlessClients 2` for the dedicated visibility audit. It discovers NVG-capable and ordinary HMD classes from configuration instead of matching mod class names, transfers the observer to an HC to verify owner-local reapplication, and performs an actual dark engagement with a flashlight. The forward target must be acquired and fired upon after physical illumination while an equally distant rear target remains outside the beam. The observer's global spotting skill must not rise when the light turns on. This is additive to the profile skill checks and remains unaccepted until the fresh mission completes it.

Use `-CortexFocus mechanics` for ammunition sharing, casualty regroup and actual skill changes. These new cases require live validation. Existing failed building cases remain in the full run; the open-door comparison records a separate result.

`-CortexFocus terrain -AuditTerrain Altis` now includes an additive damage-enabled equal-force battle after the isolated ground-route checks and before the air corridor. Two six-soldier squads per side receive ordinary opposing objectives across the dynamically selected uneven sector. The battle records real fire from both sides, casualties, physical progress by several groups and production flank/advance transitions. It does not assign Cortex roles, protect actors or accept an elapsed timer as success. This is the first live-terrain combat arm; headless ownership, Zeus interruption, other terrains and repeated reliability remain required.

The combined-operation case also keeps its repeatable VR baseline but no longer assumes fixed flat coordinates on real worlds. It rotates the whole three-axis infantry, tracked-support and defended-objective layout onto a bounded dry sector only after sampling every ground approach for usable slope and at least 15 m relief. The audit records the chosen world, bearing, relief and roughness; failure to find evaluative ground fails the prerequisite rather than falling back to a convenient flat patch.

The building comparison appends four independent physical-entry cases: two house models, each using direct movement and a building-attached waypoint. It does not replace the original garrison or open-door checks. The comparison units are excluded from Cortex and pinned to the server; neither their position nor arrival result is forced.

Combat halts also measure the actual element frontage and depth relative to the enemy. A minimum spread and a depth limit catch collapsed or enemy-facing files. This is a rough formation check; the visual overlay remains necessary to assess cover and facing.

Mixed-convoy QA includes a longer straight approach before the existing corner. A separate 20-second travel sample requires every vehicle to average at least 7.5 km/h with a 25 km/h request, catching crawling that the initial ten-metre movement check misses. Vehicle overlays show actual speed and predecessor distance against the size-aware spacing band; cyan trails show the route driven.

### Added physical scenarios awaiting fresh acceptance

The default `all` run preserves the earlier cases and adds:

- `runMechanics.sqf`: post-contact consolidation and subsequent Zeus-directed travel, measured from every member's position.
- `runReactions.sqf`: cover stance, a real grenade projectile, casualty-driven retreat and surrender with ground weapon inventory.
- `runSupport.sqf`: real gunshot hearing, report-led investigation, reinforcement travel and cancellation.
- `runAirborne.sqf`: an explicit passenger drop across owners, observed parachutes, actual landing, retained backpacks and operating crew.
- `runBuildingComparison.sqf`: direct movement, building waypoints and forced replanning on both models; additional production garrison and clearing with independently recorded room visits. Earlier building failures remain recorded.

These are runnable procedures, not accepted results. `coverage.json` marks their coverage as partial because all ownership, disable, cancellation and boundary variants have not yet been exercised. A failed diagnostic remains a failure in the run report.


Convoy comparison (`-CortexFocus convoymatrix`) is additive to the existing cargo,
corner, contact, arrival and ownership suite. It compares the previous native-follow
controller at 50 m with the current controller at 30/50/75 m, for wheeled, tracked
and mixed vehicles. A 1 km straight keeps the sampling interval away from arrival
braking. Acceptance records actual mean speed, stopped samples, restarts, physical
travel, and a deliberate halt/resume without turning around. Results from the
previous controller are comparison evidence, not acceptance of Cortex.

### Focused convoy column regression

Use `-CortexAudit -CortexFocus convoycolumn` with the full-pack launcher to run wheeled, tracked and mixed convoys at 30 m and 50 m. The complete matrix remains available through `convoymatrix`. The focused run checks physical predecessor lateral offset and order on the straight leg, speed continuity, startup and deliberate halt/resume. It does not establish corner, roadblock or ambush acceptance.

## Additional focused cases

`-CortexFocus gates` tests master, group, unit, external-control and side exclusions with refused/stationary controls followed by real defence movement. `-CortexFocus gunnery` tests actual turret projectiles, AT priority, hold fire and physical standoff. Both are also included in `all`; they do not replace any existing suite. These new cases still need live acceptance.

The observer card names the selected scope. The diary entry **Cortex: full QA inventory** lists every feature case and its implementation status from coverage.json. A procedure-only entry is missing executable coverage, not a passed test.


`-CortexFocus convoyseats` isolates operating crew, same-group passengers and a separate mounted squad. It measures real travel and exits, then deliberately unloads cargo while retaining crew. With two connected HCs it transfers the convoy and separate cargo squad to different owners before the halt. Use `-HeadlessClients 2`; missing owners fail the ownership prerequisite rather than silently skipping it. The split-owner travel/unload case passed in runtime-20260927-034106. This does not cover ACE automatic transfers, disconnects or all combat conditions.

`-CortexFocus landing` exercises physical helicopter landing and waypoint cancellation; `-CortexFocus cover` checks physical defence arrival and intervening cover geometry. Both are additive members of `all` and remain unverified. `extensions` runs seats, gates and gunnery sequentially. No focused run is a complete AI acceptance run.


The following additive focuses are staged in the launcher and `all`, but have not yet completed live acceptance:

- `scheduler`: twelve queued jobs must each start and physically move their own soldier; a queued flag is insufficient.
- `profiles`: configuration precedence, probability boundaries and unchanged unit skill. This is a configuration test, not evidence of tactical movement.
- `coordinated`: natural contact must draw two supporting squads through a rally and into separate assault approaches while the base element remains behind.
- `lifecycle`: retain the server case and repeat on each of two WMP headless owners. Disable Cortex during physical defence movement, check owner-cleared assignments, return to server for an ordinary waypoint, re-enable without resurrecting the old order, then return to the selected owner for a fresh defence order. This does not test ACE-managed transfer or HC disconnect.

Gunnery fixtures assert that both threat soldiers initially face the APC and require natural AT detection. The standoff overlay separately reports detection, vehicle travel and gained threat separation. The normal-play card instructs the operator to open Zeus before using the inspection button. Detection has its own procedure card so it cannot appear to be a stalled preparation or firing stage.

`-CortexFocus aircraft` adds a real AA launcher and airborne helicopter: natural acquisition, an actual missile, countermeasure projectiles, physical evasive departure, clearance and crew retention. It is unexecuted and partial. Native-AI comparison, disabled/low-altitude boundaries, empty ammunition and locality variants are still required before attributing all observed defence to Cortex.

`-CortexFocus convoytracked` runs the unchanged tracked 30 m and 50 m cases from the column matrix for faster fault isolation. It preserves all their movement, spacing and halt/resume assertions; the full wheeled/mixed matrix remains required. Halt diagnostics include each operating crew member's current command and destination, including the effective commander.

`-CortexFocus deceleration` runs two fresh helicopter flights with braking correction disabled, then enabled. Both must reach 120 km/h naturally before a slower approach order. The observer records speed loss, peak altitude gain, minimum clearance, travel and crew retention; labels show live altitude and peak climb. The comparison requires an actual baseline climb and a reduction with correction enabled. Missing stimulus is a failed fixture, not success. This suite is unexecuted; repeated flights, terrain, landing-priority and owner-transfer variants remain outstanding.

The deceleration fixture also requires no more than 10 m of climb during enabled braking from its approximately 120 m flight layer. This is the audit's operational target for a modest flare on clear, level terrain. Relative improvement alone cannot pass the feature; previous runs with roughly 61 m of climb do not satisfy this added check. It supplements the existing comparison rather than replacing it.

Aircraft defence now includes separate native and Cortex flights. Both must receive a real missile;
the enabled flight must show at least 5 m more departure from its event-time trajectory over two
seconds. Flare counts are observed in both flights, but a flare alone does not establish Cortex
causation because the native pilot can also deploy one. The fixture supplies the managed-aircraft
eligibility marker; creation through the actual gunship service remains a separate integration test.

The coordinated-assault focus retains its server case and then repeats with the responder squads on separate WMP headless clients. Actual unit and group owners are checked before contact. After support disable and cleanup, the HC groups return to the server for ordinary waypoint handover commands; this does not claim to test Zeus waypoint delivery to an HC. Every helper must physically advance and subsequently travel under the new orders.

## Performance pilot

Use `-CortexAudit -CortexFocus performance` for the server patrol OFF/ON/ON/OFF comparison: 50 groups of six soldiers in each arm. Acceptance limits are 5% added median and 10% added p95 frame time; missing movement, unmanaged groups or overdue jobs fail independently. This matched flat fixture isolates scheduler cost and is not evidence for HC, terrain, combat or mixed-force behaviour. See [the performance plan](PERFORMANCE.md) for the full acceptance matrix. Earlier 100-group results remain recorded as historical saturation evidence and are not repeated by the routine full audit.

Use `-CortexFocus performancecontact -HeadlessClients 2` for the primary 50-squad infantry comparison. Use `-CortexFocus performancemixed -HeadlessClients 2` for the separate 50-group combined-force comparison: 30 infantry squads, ten ground vehicles, six helicopters and four jets. Both run OFF/ON/ON/OFF, require physical work and actual fire, sample the server, both HCs and the rendered client, and apply the 5% median / 10% p95 budget only when every arm is comparable.

The lifecycle focus also includes refused HC-to-HC transfer cases. Once a squad is on an HC, the fixture temporarily excludes it from migration, requests the other HC, and requires both the original actual ownership and exactly one matching WMP ownership record to remain. Existing disable, physical movement and restart checks follow. These refusal cases passed in the completed 2026-09-27 lifecycle runs; they do not establish ACE-managed transfer coverage.

### Zeus interruption coverage

The lifecycle focus retains the existing disable/restart cases and adds held-defence takeover on the server and two WMP headless owners. It invokes the production takeover marker without a waypoint-change flag, requires assignment cleanup, returns HC groups to the server, and measures arrival at a new ordinary waypoint. Runtime `20260927-093717` completed 50 checks with zero findings and zero SQF errors. The preceding run had an HC2 replacement-arrival failure; retain that evidence as an intermittent issue.

An additional server case interrupts defence after at least 10 m of actual travel and before arrival. It issues the replacement waypoint immediately, before waiting for cleanup, then measures arrival and 15 seconds without the cancelled order resuming. Runtime `20260927-094454` completed 53 checks with zero findings and zero SQF errors, including all three new mid-movement checks. Neither case establishes real curator UI event delivery, interruption of every action, or replacement movement while still owned by an HC.

Cover-stance reactions now include later explicit standing orders during feature disable and Zeus takeover. Each case first requires a real Cortex crouch/prone pose, then checks physical standing and 12 seconds without restoration of the old stance. These added cases have not yet been run in-engine.

Use `-CortexFocus reactions` for a focused repeat of the existing cover-stance, grenade and morale cases, including the new stance interruption checks. These cases remain in both `mechanics` and `all`; the focused entry does not replace them.

The completed reactions run `20260927-095424` recorded 29 checks, two failures and no SQF errors. Both later-stance preservation cases and grenade movement passed. Retreat and surrender failed; the fresh run adds visible morale/state/travel and end-state diagnostics. It also includes real firing and target-hit cases for open ground versus low cover, and the corrected clearance-based stance selection. Those additions remain pending live acceptance.

Runtime `20260927-101028` completed 34 checks with two failures and zero SQF errors. It confirmed real retreat smoke deployment, but both casualty outcomes ended with an active Zeus hold and cleared state. Plain-selection takeover was removed for the next build; earlier no-hold withdrawal failures remain open. Leadership diagnostics now record actual leader identity/aliveness, active waypoint and survivor movement destination every two seconds during the casualty cases.


## Breadth-first acceptance pass

Establish a usable baseline across all 58 cases in `coverage.json` before further tuning individual manoeuvres. Preserve existing tests and failures. A baseline requires a visible physical outcome, feature-off behaviour, safe cancellation and repeat cleanup; full ownership and integration acceptance remains a separate required pass.

The launcher also accepts independent `-CortexFocus support`, `airborne`, `vehicles` and `fire` runs. These execute the existing support, parachute, vehicle-reaction and fire-control procedures separately. They remain included in `mechanics` and `all`; no coverage is removed. Each run retains server/client completion reporting and the visual guide.

Rotate through sensing/sharing/support; infantry orders/cover/buildings; fire/ammunition/reactions; vehicle/convoy; artillery; aviation; profiles/lighting; then multi-squad, Zeus, ownership and scale. Fix a blocking functional defect in each family before returning for tuning. Procedure-only road crossing and multi-squad cases need executable physical tests. Never turn missing coverage or a stalled action into a pass to advance the rotation.

Use `-CortexFocus buildings` to run the existing two-model engine comparisons and production garrison/clear cases independently. This uses the same procedure retained in `infantry` and `all`; it does not replace the original first-model garrison case or establish that its entry failure is fixed.

For a focused combat regression, add `-CortexCombatCase ADVANCE-BLOCKED` to `-CortexAudit -CortexFocus combat`. The launcher validates case names and rejects the selector for other focuses. Omit the selector to retain all 18 combat cases. The RPT records the selected scope; a single-case result is not full combat acceptance.

## Coordinated approach geometry comparison

Use `-CortexFocus coordinatedbounds` for the retained long-screen scenario. Use `-CortexFocus coordinatedclean` for an additive comparison: short view screens surround the initial helper positions rather than crossing the later assault corridor. All original movement and handover criteria remain; comparison case IDs start with `CLEAN-`. The full suite includes both layouts. This tests whether removed fixture geometry contributes to the long lateral detours; it does not establish that the production movement controller is correct.


### Coordinated movement evidence boundary

The coordinated, coordinatedbounds and coordinatedclean scenarios are controller diagnostics. Their actors are invulnerable, the opponent cannot fire, and the range has no natural terrain. The 35 m bounds, 60 m travel and 50 m objective proximity checks expose command, handover and path faults; passing them does not establish useful tactics or successful combat. Retain these cases when adding engagement coverage.

Combat acceptance remains outstanding. It requires live opposing squads, natural detection, return fire and suppression, casualties, traversable terrain with distinct covered and exposed approaches, and an objective that can be contested and secured. Evaluate objective distance reduced and ground held, not accumulated travel. Record covering fire against the threat while another element advances, exposure along the actual route, casualties, cohesion and the transition into assault, clearance and consolidation. A withdrawal must gain separation and establish a viable position. A blocked or separated soldier must not freeze the viable element. Zeus replacement orders must remain authoritative throughout.

Distances should follow the scenario terrain, weapon reach and actual observation conditions. Use multiple engagement ranges and squad counts; increasing the size of the empty range alone is not a combat test. Include server and headless ownership, owner transfer, and the agreed 50-group primary frame-time budget. Prior 100-group runs remain historical stress evidence. These are acceptance requirements, not claims of implemented or passing cases.


The pending rally-separation change reserves distinct 45 m squad rally areas, with candidate centres 110 m apart and no fallback to a shared point. The existing physical-rally check now uses each durable lease destination and adds a distinct-area check. This bounded geometric layout is an interim anti-crowding fix, not cover/concealment route selection; terrain suitability and in-engine acceptance remain outstanding. Coordinated fire-team and final handoffs also no longer add fixed pause timers on top of the covering squad and scheduler handoff. Single-squad pauses and grenade clearance waits remain unchanged.


### Road crossing

The additive `crossing` focus executes `runCrossing.sqf`. It searches once within 2 km of the observer for an engine-recognised, non-bridge road, then requires natural contact, the production advance crossing stage, a real smoke projectile and every soldier physically beyond the far edge. Route flags alone cannot pass. The current VR launcher cannot supply real roads: it records a failed terrain prerequisite rather than substituting decorative geometry. A road-terrain mission and disabled-during-action, Zeus and owner variants remain required.

## Complete feature run

`-CortexFocus features -HeadlessClients 2` includes every server suite selected by `all`, followed by the client UI checks. This includes defence/garrison, convoy movement/contact/crew/cargo, artillery/counter-battery, aircraft, support, reactions, fire control, inventory, profiles/lighting, scheduler/performance, single-squad manoeuvres/transitions and multi-squad comparisons. Long coordinated comparisons run last in both full focuses. Individual focuses remain available; no existing case is removed.

Runtime 20260929-155242 predates this expanded dispatch and does NOT run the complete selection. It only runs the earlier non-coordinated batch. A freshly rebuilt mission is required for complete selection. Executing every suite still does not establish every required ownership, interruption or boundary variant: the coverage register remains partial.

`-CortexFocus artillery` independently runs the finite lethal burst, warning and counter-battery cases. Its explicitly assigned spotter is created and removed by that fixture; it no longer depends on a private unit from the infantry block.

Ammo sharing additionally checks disable-after-transfer and a second scheduler-driven transfer after re-enable, including donor funding and total-round conservation. These additions require the next rebuilt mission; runtime 20260929-155242 predates them.
