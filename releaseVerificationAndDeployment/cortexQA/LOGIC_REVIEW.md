# Cortex logic review

## Incapacitated leader succession (2026-09-30)

Leader-dependent tactics previously selected a successor only after the current leader died. An ACE-unconscious or engine-incapacitated leader therefore remained the source for knowledge, position and movement decisions, allowing withdrawal, reinforcement and manoeuvre to wait indefinitely. The group tick now promotes the highest-ranking local combat-effective member whenever the current leader cannot act, and rechecks the replacement before running leader-dependent logic. This is statically covered and awaits the next permitted in-engine casualty run.

This is an open defect and acceptance register, not a completion certificate.

## Tactical movement ownership

Source review after runtime `20260930-182028` found that the contact tick selected a local flank or
advance before asking whether an acknowledged reinforcement package should become a coordinated
assault. The requester could therefore own a local drill while also acting as the coordinated base of
fire, producing crossed routes, role churn and return-to-formation movement.

Coordinated assault now has first refusal over movement. An acknowledged or dispatched coordination
keeps the requester in its base-of-fire role through a finite pending lease; local flank and advance
remain available only when no coordinated package forms. Flank and advance are also selected
sequentially, so one contact tick has one movement owner. Fire control, stance, anti-armour, smoke,
ammo sharing and casualty replacement remain layered behaviours and do not become movement owners.

The prior requester-side `allGroups` scan has also been removed from the contact cadence. The server
support job publishes only the at-most-six responders already reserved for that requester, and clears
the index with the reservation. This prevents coordinated selection from growing quadratically at the
50-group primary performance target. Static acceptance is 151 focused Cortex tests and 1,262 validated SQF
files. A rebuilt live run remains required and is deliberately deferred while game launches are paused.

## Confirmed casualty defect

Runtime `runtime-20260927-101803` records a dead group leader throughout the retreat observation, a living survivor following a nearby FORMATION PLANNED destination, and an active retreat waypoint farther away. No Zeus hold was active. The server failed physical retreat and surrender.

`cortexKnowledge.sqf` returns no enemies for a dead leader. Thus casualty succession affects both movement and threat-dependent decisions. The group tick now selects a conscious living local successor by rank only when the current leader is dead or absent, after eligibility and locality checks. Existing living leaders are preserved. Server reactions and server/HC lifecycle runs now demonstrate physical recovery; other tactical phases and ACE ownership transitions remain open.

The reactions suite adds a living-successor assertion without removing physical withdrawal, smoke-projectile, disarm or weapon-on-ground checks.

## Required cross-feature checks

| Invariant | Required evidence | Status |
| --- | --- | --- |
| Casualty succession | Leader killed during contact, retreat, flank, assault and holding orders; replacement acts on server and HC | Server retreat and moving succession on server/HC1/HC2 passed; flank, assault and holding casualty variants open |
| Medical incapacity | Unconscious leaders and members do not execute tactics; recovery preserves intended leadership | Open |
| Cancellation | Zeus waypoint/edit/remote control cancels current movement and delayed effects; plain selection leaves them running | Selection handlers removed; real event validation open |
| Locality | Active action migrates once, old owner stops, new owner resumes; disconnect and ACE HC covered | Partial lifecycle evidence only |
| Movement ownership | No competing formation, tactical, convoy, boarding or recovery controller | Open; convoy and assault failures remain |
| Completion | Actual arrival, firing, dismount, boarding or surrender proves outcome | Physical tests exist; full feature mapping open |
| Restoration | Feature disable, cancellation, deletion and completion restore only settings still owned by Cortex | Partial stance evidence; remaining states open |
| Delayed effects | Recheck eligibility, ownership, target and action generation before applying | Grenade checks improved; full callback audit open |
| Knowledge | Decisions use living observers and genuine knowledge, never omniscient test inputs | Dead-leader dependency confirmed; wider review open |
| Isolation | Each fixture cleans up actors, handlers and settings; no concurrent case contamination | Open |
| Performance | 100+ groups, combat and idle, server and HC; median <=5%, p95 <=10% overhead | Patrol pilot only; broader acceptance open |

## Client audit issue

The same runtime reached UI authoritative apply and logged restoration at 10:24:31, but had not reported reservation cleanup or client completion by 10:26:21. The process remained alive. This is incomplete evidence, not a successful client run or permission to treat an observation timeout as termination.

## Queued grenade medical state

The throw helper previously checked alive/local/on-foot but not unconsciousness or captivity. It now uses the shared combat-effective predicate both before turning/queuing and immediately before firing. This prevents an incapacitated or surrendered actor from executing a queued throw. Static callback regression covers the guard; a live medical-state transition case remains pending.

## Delayed grenade regroup

The six-second evasion callback previously issued doFollow after checking only life, locality and group eligibility. It now rejects changed groups, boarding, medical/captivity state, changed Zeus tokens, replaced destinations and newer drills. An additive second-projectile scenario replaces movement during evasion and requires physical arrival. The corrected live replacement-movement case passed in runtime-20260927-105148; medical and ownership transition variants remain open.

Client completion follow-up: direct desktop inspection showed the finished client phase and zero client findings before the authorized restart. The RPT-based report still lacks the client completion marker and remains incomplete; retain both observations rather than changing the report to pass.

## Fresh leadership acceptance evidence

Runtime `runtime-20260927-103703` completed server and client, 39 checks, two findings and no SQF error lines. Living-successor checks passed in both casualty scenarios. Physical retreat passed at [1414.32,1068.08,0.00143909]; the survivor retained the rifle and deployed real smoke. Surrender disarm/capture and weapon-on-ground passed. Knowledge was non-empty after succession. This supports the casualty fix in the server fixture, not all HC or tactical phases.

Both queued smoke cancellation cases passed with zero throws and unchanged inventory. Replacement movement after evasion failed (31.87 m remaining). The surrender broken-state observer failed after state cleanup; it now retains a read-only reference to the original state map. Both original findings remain in the report and require rerun.

Runtime `runtime-20260927-104354` completed all 39 checks with one finding and no SQF errors. Physical retreat and surrender passed again; the retained-state morale assertion passed (lowest 0.16). Evasion replacement diagnostics showed the runner at [1428.54,1099.62] against [1430,1100] at the first post-briefing sample. The briefing had delayed observation by eight seconds. The next fixture briefs before the stimulus, observes immediately and uses 60 m travel; it no longer requires an unsupported permanent hold after an individual doMove. The original failed report is retained.

Runtime `runtime-20260927-105148`: completed reactions audit PASS, 39 checks, zero SQF errors, zero server/client findings. Corrected 60 m replacement movement passed at 3.8771 m remaining. Physical retreat, retained rifle, real smoke, surrender/disarm, both queued cancellation cases and broken-state observation passed. This is server fixture evidence only. The subsequent lifecycle suite adds real moving-leader casualties on server and both WMP HC owners, maintaining ownership through successor arrival; these additions are not yet accepted.

## Owner-local casualty continuation

Runtime `runtime-20260927-105913` completed with 64 checks, zero findings and zero SQF error lines, including client completion. Fresh moving groups lost their leader on the server (owner 2), HC1 (owner 4) and HC2 (owner 5). Each selected a living successor and physically reached the destination without changing owner. Existing disable/restart and Zeus replacement cases remained in the suite. This proves these WMP HC cases, not ACE transfer or disconnect recovery.

## Surrender handover ordering

Surrender now rechecks eligibility, the feature gate and a local combat-effective on-foot candidate before mutation. It releases explicit Cortex holding orders and automatic movement/stance state before surrendering through ACE, so later cleanup cannot overwrite captive posture. Repeated calls exclude surrendered actors. Additive reaction checks require ten seconds of disarmed captivity at the surrender location and no duplicate dropped-weapon holder on repeat. These changes are undergoing live validation in runtime-20260927-111216; static gates passed (429 repository tests, 1257 SQF files, 85 module parity checks and 113 wiki pages).

## Replaced drill job identity

Flank and advance jobs previously carried only a group reference. Cancellation removes the drill state, but an already queued old job can run after a replacement drill starts and then operate on that replacement. Both start paths now allocate a machine-local serial token, store it in the drill and pass it to the job. The step rejects absent or mismatched tokens before any cleanup or movement. Owner epochs still independently protect locality changes. The combat suite submits a stale token against a real active drill and checks rejection without changing its stage, index or destinations; all existing physical completion checks remain. Live acceptance is pending.

Runtime `runtime-20260927-111216` completed reactions acceptance: 41 checks, zero findings, zero SQF error lines and both server/client completion. Physical retreat, smoke, surrender, sustained captivity and repeat-without-duplicate-holder passed. The subsequent stale-drill token change passed 430 repository tests and all required static gates; it is not part of that live result.

## Final approach and timing evidence

Runtime `runtime-20260927-111912` passed six physical flank bounds and threat-facing frontage, then failed with controller STALLED at the FINAL point before the QA deadline. At least one soldier changed from MOVE to ATTACK with its engine destination short of the assigned spot. Final and assault approaches now use the same movement ownership as ordinary bounds, restoring fire at their halt while the base covers; close clearing retains engagement. This change is not in the running audit.

Progress tracking now recognises 0.5 m net improvement rather than 2 m. The no-progress timeout remains bounded. Absolute bound duration reports TIME_LIMIT separately from STALLED; terminal diagnostics include each soldier's remaining distance, time since net progress, command and engine destination. QA observation expiry is separately reported and never asserted as an engine stall. Neither expiry counts as completion.

The user requires multi-squad flanking, advance and combat plus all transitions. The coordinated fixture now has a six-man base and two six-man responders, measuring actual base and responder fire after the independent rally stage. Mixed owners, blocked/casualty responders, Zeus interruption of one team, friendly-fire separation and complete bound/hold/frag/clear/regroup transitions remain required; this expansion is unexecuted.

## Required bounding overwatch

The current advance chooses one rifle element and moves it through up to three bounds, leaving the base element behind. Its completion is not evidence of alternating bounding overwatch. The requested final behaviour includes successive and alternating bounds, within-squad and multi-squad mover/cover roles, physical arrival before role exchange, actual supporting fire, and cancellation/casualty/blocked-team contingencies. Preserve the existing single-element regression while adding these behaviours and acceptance cases; do not relabel the existing advance as complete coverage.

Runtime `runtime-20260927-111912` completed: 42 checks, three flank findings, no SQF error lines and both completion markers. Ordinary advance completion and close-contact advance stop passed, including physical movement, frontage, actual firing and cleanup. All three stale-token rejection checks passed. Flank final arrival, assault entry and assault arrival failed. These results do not establish alternating bounds or multi-squad cohesion.


## Successive overwatch and moving engagement implementation

Advance now divides eligible on-foot soldiers into a rifle element and a second leader/support element. The first moves while the second holds, then roles exchange at physical arrival; both use separate lateral slots at the same bound before advancing to the next. Cleanup and ownership checkpoints retain all participants. Fire control excludes only current movers from automatic target reassignment, permitting the stationary element to support. QA labels the active roles and independently measures cover position, shots during cover, and both elements taking turns. This is successive overwatch only; alternating leapfrog and multi-squad coordination are still open.

The user explicitly requires engaging while moving. Therefore the interim BLUE/disabled-TARGET approach is superseded in saved source: movers retain firing permission and TARGET, suspend automatic retargeting, receive only a genuinely known contact and then their movement destination. A new FiredMan check requires an actual projectile event while a current mover travels above 1 km/h during MOVE. Neither an assigned target nor firing only at a halt passes. These changes are not in runtime-20260927-113050 and require rebuilt live acceptance.

Stationary detection now uses a separate physical-movement clock, so a detour that increases target distance is not called STALLED. Net approach remains recorded; prolonged moving routes still report TIME_LIMIT rather than success. Both clocks appear in terminal diagnostics. The original index regression was updated for the expanded record and focused checks passed.

Runtime 113050's ordinary advance did not start after delayed natural contact. The fixture had allowed native waypoint travel during acquisition, which could consume its distance prerequisites; this is a setup risk, not yet a proven sole cause. The next fixture holds PATH only during natural acquisition, restores it before exercising the production advance, and logs leader position, current waypoint, remaining distance and real knowledge. Original failures remain recorded.

- Lighting follow-up: AUTO is now the guarded default and runtime fallback. NVG capability is checked from configuration instead of accepting every HMD. One bounded owner worker checks ten previously profiled units per second; changed state reapplies from the baseline. Stop removes the worker. Added measured lighting-layer checks to the profile fixture; actual night detection, active-goggle state, flashlight beams and owner/performance variants remain unaccepted. No flashlight skill bonus has been introduced.
- Combat runtime 20260927-113050 completed both sides with four ordinary-advance failures (never started). Flank and close advance passed. This run used the interim approach code, not the saved successive-overwatch/moving-fire changes.

Lighting/profile runtime 20260927-115212 completed server and client: 28 checks passed, no SQF errors. Measured spotDistance day 0.70, unaided dark 0.175, NVG dark 0.525, restored day 0.70; repeated apply did not compound. This does not prove actual detection, flashlight behaviour, or the later worker-only refresh check.

Runtime 20260927-115537 confirms moving-fire regression: all three flank movers replaced MOVE with ATTACK, selected nearby destinations and remained stationary over 25 seconds. First bound failed and zero moving shots were recorded. Saved follow-up removes explicit doTarget contact from movement issuance, retains threat-facing doWatch and firing permission. This is unverified; no timeout extension or lowered acceptance threshold was used.

Combat runtime 20260927-115537 server finished with 15 findings. Ordinary advance now starts with the acquisition fixture fixed, but fails first-bound completion. Cover holds and actual covering fire pass; close advance records moving shots yet still stalls. This proves that firing and travel can overlap for some actors, not that the manoeuvre works. The next build removes the explicit mover target assignment and samples cover throughout every bound.

Operator confirmed a Zeus command during runtime-20260927-120333 flank. The actual ending is RELEASE, controllerFailure empty, at 12:05:25. Treat completion/moving-fire/assault findings as interrupted-case evidence, not an uninterrupted regression. The run confirms release but does not measure arrival at the operator destination. Original logs retained with an operator-interruption note.

The 120333 ordinary-advance fixture reports empty engine knowledge at 350 m when contact times out. Added a 250 m ordinary advance while preserving the 350 m setup as ADVANCE-DISTANT; 150 m ADVANCE-CLOSE and FLANK remain. No reveal or artificial knowledge is introduced. The new cases and queued-grenade drill-replacement variant require rebuilding.

Close advance in 120333 completed both elements at the first bound and recorded actual moving shots, but the next role exchange stalled with ATTACK commands. Saved correction explicitly clears assigned targeting with doWatch objNull before watching the threat direction and issuing the next bound. The prior doTarget objNull alone was not sufficient cancellation. Full target/weapon capabilities remain unchanged; fresh live comparison required.


Movement follow-up: runtime 20260927-121353 again records ATTACK takeover and stationary actors during flank and successive advance. The next experiment suspends TARGET pursuit only during owned movement, leaving AUTOTARGET, WEAPONAIM, FIREWEAPON and combat mode unchanged. The existing restoration list restores only capabilities Cortex disabled. This supersedes the earlier assumption that keeping TARGET enabled was necessary for firing. Physical arrival and actual moving-shot acceptance remain unchanged; this experiment is not yet live-validated.

Runtime 20260927-121353 completed server/client: 67 checks, 16 server findings, zero client findings and zero SQF errors. Flank and ordinary advance stalled; close advance failed proximity completion; distant contact failed acquisition. Saved TARGET-pursuit experiment passes 432 repository tests, 1257 SQF validation, 85 module parity and 113 wiki checks. Physical retest remains required.


Lifecycle audit: see LIFECYCLE.md for source-backed triggers/start/end/migration paths and open transition gaps. RestoreCalm now synchronously ends an active drill before clearing restoration checkpoints; 50 focused contracts pass, live transition acceptance pending. This change is not in runtime-20260927-122858.

Runtime 20260927-122858 completed: 67 checks, 22 server findings, zero client findings and zero SQF errors. TARGET-pursuit suppression did not solve stationary ATTACK takeover and is reverted; no acceptance claim. Subsequent saved changes: synchronous calm cleanup, anti-armour movement ownership guards, two bounded destination retries. These require physical transition/recovery QA. Persistent straggler continuation remains open.

Movement isolation: added FLANK-NATIVE-FIRE as an additive comparison with only Cortex fire control disabled. Normal engine firing and the same movement/shot/arrival acceptance remain. Expanded ten-second actor telemetry includes behaviour, unit combat mode, group attack permission, TARGET/AUTOTARGET and assigned target. This distinguishes the test configurations; it does not yet establish causality. Unexecuted.

Added FLANK-YELLOW as a separate comparison retaining Cortex fire control but using group YELLOW instead of RED. It retains normal weapon use and all existing outcome checks. Production combat-mode behaviour is unchanged until live evidence resolves the difference.

Recovery ownership review: fire control now excludes START-stage actors and rejoining stragglers even while the main element pauses; anti-armour also excludes rejoining actors. Fire control rechecks locality, eligibility, feature gate and combat effectiveness. These are saved changes, not part of runtime-20260927-124426. That run's flank Zeus handover passed physical prerequisite, cleanup and stale-job rejection, but failed all-member arrival (furthest 22.5 m). Added formation/leader-distance/command diagnostics for the next run; existing threshold and failed evidence retained.

Recovery QA correction: continuation origins are sampled when the straggler is first separated, not at initial blockage. Movement before the stall can no longer pass the continuation assertion. Owner adoption clears recovery diagnostics to MIGRATED rather than falsely claiming the new owner resumed recovery. Neither change constitutes physical migration/recovery acceptance.

Runtime 20260927-124426 server completed with 27 findings. Both Zeus handovers passed actual interruption prerequisite, cleanup and retired-job rejection; both failed the 15 m all-member arrival and 20 m drift thresholds, with leaders near 2 m and furthest followers near 22-23 m. Formation geometry remains to be measured; raw failures retained. Next build runs native-fire and YELLOW comparisons first, preserving all existing cases. Current saved regression: 438 tests, 1257 SQF files, 85 module parity and 113 wiki checks pass.

Runtime 20260927-130332 interim observation: FLANK-NATIVE-FIRE reached assault, recorded moving shots and physical progress, but exceeded its 240-second observation window at MOVE index 6. One actor remained under ATTACK about 20 m short at bound 4; the viable element continued after separation. This contradicts a complete scheduler freeze and does not establish manoeuvre completion or straggler recovery. Full run remains live.

Comparison correction: added FLANK-YELLOW-NATIVE-FIRE without removing any case. The four configurations now independently vary group RED/YELLOW and Cortex fire control enabled/disabled. Previously comparing native-fire RED against Cortex-fire YELLOW changed two variables. All four keep the same physical acceptance checks; production rules of engagement are unchanged. The added case is not present in the currently running staged mission and remains unexecuted.

Recovery review: the continuation quorum previously recalculated 60 percent from an already reduced element, permitting cumulative separation to erode the required strength. It now uses the original selected element (or original bounding team). Rejoin destinations now use surviving peers in the actor's own team; the previous whole-drill centroid could lie between separated covering and moving teams. Leader position is the fallback if that team has no viable peers. Neither correction teleports actors, bypasses movement inhibitions or establishes live recovery acceptance. Saved after runtime-20260927-130332 was staged.

Runtime 20260927-130332 YELLOW comparison: physical movement, frontage, actual moving fire, assault entry and assault position passed. The 240-second observation expired at MOVE index 7 without a controller ending. This is unaccepted completion, not evidence of stationary failure. Added a separate 120-second late-completion diagnostic after all original assertions; deadline failures remain recorded and cannot be converted to passes. No deadline was extended. This diagnostic is unexecuted in the current staged mission.

Bound ROE correction saved after the 130332 comparison: only RED movers temporarily use YELLOW, retaining fire-at-will while preventing independent pursuit from superseding the bound. Other authored modes remain unchanged. Restoration rows now carry [unit, original, applied] and restore only if the applied value is still current; legacy two-field rows retain BLUE as their historical applied value. Halt, end and locality adoption share that ownership check. QA now checks actual post-release combat modes against the pre-drill modes. This is a production candidate, not live acceptance; the current run still contains the older mode handling. Rejoining stragglers and real Zeus/mod ROE changes still need physical acceptance.

User screenshot matched 130332 ADVANCE TIME_LIMIT at 13:19:39: bound duration 101 seconds; one active mover remained 16.9 m short under ATTACK. Moving-fire pass was real ([0,0,0,0,1,1]), but the result payload omitted shot rows and the guide defaulted to zero. Saved display corrections retain final shot counts, clear obsolete generic bound labels, distinguish deadline-exceeded from ended, and label terminal recovery actors SEPARATED AT END rather than REJOINING. These display changes do not repair or waive the movement failure; in-game render retest required.

Added FLANK-ZEUS-ROE: requires a physically moving drill and an actual owned mode-override row, changes that mover to BLUE as an external hold-fire stimulus, invokes the existing Zeus handover function and retains physical replacement-arrival/no-resurrection checks. Final combat-mode comparison expects the newer BLUE value for that actor and original modes for others. This is a scripted function-path test, not proof of curator UI event delivery. Unexecuted; all earlier handover cases retained.

Acceptance correction: both-elements-bounded previously checked role-start observations and could pass with the second team stranded. It now requires sampled physical arrival within 3 m of every assigned mover position for both teams during a halt. The former observation remains as the separately named both-elements-started check. Existing failed runtime evidence is unchanged; corrected assertion awaits a fresh build. Also found Advance_MinContactSeconds tuning is rejected as unknown; this setting transport mismatch remains under review.

Advance timing transport fix: Advance_MinContactSeconds was declared/read with default 30 but missing from CortexTuningSpec, so runtime requests were rejected and owner snapshots omitted it. Added the shared slider (0-300 seconds, default 30) and a QA assertion that requested 5 seconds is actually applied. No bypass of other eligibility/contact checks. Live snapshot/HC transport and UI rendering remain to be verified in a rebuilt mission.

Fire-control QA had a second settings mismatch: MaxShootersPerTarget=1 was requested but absent from the tuning specification, leaving the default 2. Added shared runtime validation/snapshot entry (1-12, default 2) and an actual-value assertion before the fixture. Earlier fire-control results do not prove the requested one-shooter configuration. Fresh live validation required.

130332 FLANK-ZEUS geometry: leader 1.975 m from waypoint; followers 7.18-21.205 m from leader in WEDGE. All expected destinations were DoNotPlan or DoNotPlanFormation and near actual positions. This supports native formation placement rather than old drill resumption for this case. Added independent formation-arrival acceptance requiring leader within 3 m, every actor >=35 m actual travel, <=3 m from its engine destination, <=30 m from leader, plus <=3 m physical drift for 15 seconds with no resurrected drill. Prior fixed-radius assertions and their failed evidence are retained. New checks unexecuted.
Runtime 20260927-133856 launched with saved movement-mode, recovery, tuning and QA changes. Client and both HC initialization confirmed. First native-fire case reached its second bound with all three movers; this is interim evidence only, not completion. Previous runtime 130332 completed 148 checks with 41 server findings, zero client findings and zero SQF error lines; report retained.

133856 first comparison failed: FLANK-NATIVE-FIRE stopped at bound 2, one YELLOW mover 16.28 m short under ATTACK; moving-fire failed. Per-unit RED-to-YELLOW alone is not a validated solution. Group-YELLOW comparison remains running. Recovery QA now requires proximity to surviving members of the original moving element, not any squad member; earlier broad peer-based rejoin passes do not establish this stricter outcome.
Added diagnostic-only FLANK-AWARE and ADVANCE-AWARE cases after real contact/start: disable autonomous combat switching and set individual AWARE behaviour on fixture actors. Existing physical movement, moving-fire, frontage and completion assertions remain. This isolates native danger behaviour; it is not a production policy or an accepted fix. Both cases are saved after 133856 staging and remain unexecuted.


### Advance and flank assault transition correction (27 September)

Source review confirmed that HOLD excluded Advance from assault and CLEAR stopped at the enemy position. The saved controller now permits both manoeuvres to enter the existing gated assault branch, snapshots its reported objective and heading, and places CLEAR 20 metres beyond it. This also prevents frontage reversing when actors cross the objective. Turning assault off during this sequence aborts through the normal cleanup path. Water approach/crossing destinations are rejected. Close contact no longer cancels the manoeuvre solely because assault range has been reached while assault is enabled.

The combat QA retains the assault-position check as an observed proximity check during the assault, rather than demanding actors remain there after clearing through. An additive physical-clear-through check requires living movers to arrive at their assigned clearing spots and cross at least 10 metres beyond the objective; Advance must do this with both elements. These edits passed 59 focused static regression tests and SQF syntax checks, but are not in the running 133856 mission and have no live acceptance yet.

Still outstanding: deliberate consolidation of the covering and assault elements, grenade timing at the assault position, explicit close-contact transition instead of completing a longer planned flank, terrain/path viability beyond the water check, and complete multi-squad chaining. The existing aggression roll and morale/range gates remain; this change does not make every advance automatically assault.


### Assault grenade sequencing (27 September, saved candidate)

The frag request moved from final-flank HOLD to physical ASSAULT arrival (after both advance elements arrive). A queued throw now enters GRENADE, retains position holds, and requires a matching actual FiredMan projectile, at least eight seconds elapsed, and projectile deletion before allowing CLEAR. An unconfirmed throw or projectile still present at thirty seconds ends as GRENADE_UNRESOLVED. This does not claim that arbitrary modded explosive secondary effects have ended. The throw helper installs one temporary local handler, removes it on matching fire, and expires it after ten seconds if no matching fire occurs. Existing next-frame eligibility, locality, Zeus, token, ammunition and friendly-distance checks remain. There is no new per-unit polling loop.

Focused contracts now total 60 passing tests. Live throw/hold/crossing, interruption during GRENADE, and handler cleanup still require acceptance; the current mission does not contain this candidate.


### Additive live grenade acceptance case

FLANK-GRENADE now gives the fixture carried grenades and observes the normal behaviour path. Independent QA FiredMan records capture real projectiles and deployment times. Acceptance requires actual deployment, no more than three metres of drift during the grenade hold, and physical clear-through without a live grenade or less than eight seconds since firing. The visual card explains this stage. No controller flag or queued throw substitutes for deployment. This case is saved but unexecuted.

ADVANCE-CLOSE now explicitly disables assault, preserving its existing close-contact stop test under the new assault transition policy. All previous combat cases remain. The active 133856 audit processes were verified live while the server was running the earlier FLANK case; no restart was performed.


### Grenade cancellation and ownership checks

The next-frame frag callback now rechecks the assault gate for drill-owned throws, closing the gap between a live disable and the next scheduler step. Cortex locality cleanup retires the local temporary FiredMan listener on loss and gain, before the old drill state is discarded. The new owner does not resume the grenade stage. Fired projectile records are retained; cleanup never deletes a live explosive. Actual migration/disable-during-throw acceptance is still pending.


### 133856 live comparison evidence (still running)

The four audit processes were verified live. FLANK-YELLOW-NATIVE-FIRE completed at 13:47:56, after the 13:46:41 observation deadline; moving-fire counts included 2 and 4. FLANK-YELLOW completed at 13:52:46, after its 13:52:37 deadline; moving-fire counts included 6, 13 and 22. Their original deadline failures remain recorded. These demonstrate late completion in this run, not universal acceptance.

FLANK-NATIVE-FIRE stalled at bound 2 with a remaining mover executing ATTACK 16.28 metres from its assigned spot. Ordinary FLANK stalled at assault bound 6 with an ATTACK mover 25.69 metres away. Both had group RED with the candidate individual YELLOW override. Whole-group combat mode therefore remains a useful controlled comparison; the per-unit change alone has not resolved takeover.

ADVANCE ended PARTIAL at 14:02:28. Both elements physically reached the first two bounds and moving fire occurred, but unresolved separation prevented COMPLETE. This is not a passed advance. A saved additive ADVANCE-YELLOW comparison now uses the same enemy range and fixtures as ordinary ADVANCE to test whether the group-mode result extends to successive bounds. It has not run yet.


### Consolidation acceptance gap

The current end path holds the flank element at the ground won and leaves the covering element behind. GroupTick only releases holders when the leader is already within 30 metres; it does not order that leader/cover element forward. An additive physical-consolidation assertion now requires the living squad within 35 metres of the reported assault objective and leader, and the original covering element to have moved at least 30 metres from its support position. This check is deliberately not satisfied by COMPLETE or holder flags. The controller still needs a genuine consolidation stage; the new assertion is saved and not yet run.


### Saved flank consolidation candidate

After clear-through and its hold, a flank now recruits its surviving local on-foot covering members into the same drill and moves them to a line 12 metres beyond the fixed assault objective. The assault element holds and covers. This reuses the existing MOVE arrival/retry/straggler handling and token/eligibility/Zeus cancellation checks; no additional scheduler loop is created. Checkpoint restoration includes the newly recruited movers. Advance already moves both original elements across the objective and does not add this extra support move. Consolidation arrival has a ten-second hold, and unresolved recovery still prevents COMPLETE.

This is a saved implementation candidate, not live acceptance. Its physical-consolidation QA was added before implementation. Focused regression now passes 66 tests and the controller passes SQF syntax validation. Multi-squad consolidation, live takeover/migration in this new stage, and the continuing group-mode movement failures remain outstanding.


### Late-result display and physical cohesion

The separate late-completion diagnostic now also measures physical squad/support consolidation if assault was observed. Original deadline failures remain unchanged. The final visual result updates from the actual latest controller ending rather than showing the empty result captured before the extended observation. Late completion remains a separate outcome, not a retroactive pass of the original manoeuvre deadline. This observer change still needs a fresh live run.


### Full static gate after consolidation edits

451 repository tests passed. The production SQF validator checked 1,257 files with zero errors; Zeus/script parity checked 85 modules, wiki structure checked 113 pages, and git diff whitespace checks passed. Unit/audit generation completed before the scanners ran. Runtime 133856 still had all four expected processes and was executing ADVANCE-ZEUS at 14:12:14; neither completion marker was present. It was preserved. These static results do not establish live acceptance of the newer assault, grenade or consolidation stages.


### Grenade integration with fire control

Fire control and anti-armour selection now exclude the pending grenade thrower during GRENADE. Without this, the newly added Advance grenade hold allowed either pass to issue competing target orders to that actor. Other stationary soldiers retain their covering-fire roles. The exclusion uses the existing group pass and adds no handler or loop. This integration guard is statically checked but not yet validated during live throwing.


### Combat-mode fixture prerequisite and handover evidence

In runtime 133856, FLANK-ZEUS passed physical replacement formation arrival at 14:11:50 and fifteen-second stability at 14:12:05. ADVANCE-ZEUS passed formation arrival at 14:15:58. This does not waive the retained earlier fixed-radius findings.

Several restoration checks failed while displaying all actual modes as RED. The old fixture captured unitCombatMode immediately after setting the group mode and did not print expected values. A delayed engine application is a hypothesis, not a confirmed root cause. The saved fixture now waits up to five seconds for the requested group and individual modes, records that prerequisite separately, and prints both expected and actual unit values on restoration. Existing recorded failures are retained; no production restoration policy was weakened.


### Assault approach spacing correction

The assault approach is now 20 metres short of the fixed objective. Its previous 12-metre centre matched the grenade helper's friendly exclusion radius exactly, so the three-metre arrival tolerance and two-metre cover adjustment could put an assaulter inside that radius. The 20-metre approach leaves margin for those adjustments. Actual friendly/civilian checks and grenade range checks remain authoritative; the larger offset does not guarantee a safe throw or require throwing when blocked. Live acceptance remains pending.


### Visual stage labels

Combat overlays now label current destinations and movers as Assault approach, Clear through or Support consolidation, with an explicit grenade-clearance hold label. Actual trails, distances and route points remain. The saved display still needs rendered review in the fresh mission. Runtime 133856 was verified live at 14:20:34 with FLANK-BLOCKED progressing through bound 2; it was not restarted.


### Carrier selection at assault arrival

ASSAULT arrival already occurs after both Advance elements reach the point. Its grenade selection now checks fit local assault members in turn, stopping at the first safely queued carried frag, rather than selecting one random member and abandoning the attempt if that inventory is empty. This includes the first Advance element, which was previously excluded because only the second/current movers were considered. The existing helper still validates inventory, range and friendlies, and only one throw is queued. Mixed-inventory live acceptance is still pending.


### 133856 blocked-flank result and recovery diagnostics

At 14:23:01 FLANK-BLOCKED passed tracked-straggler, continued-with-blocked-actor, preserved-movement-inhibition, movement and moving-fire checks, but failed physical rejoin. It eventually ended PARTIAL at 14:23:35. Main-element continuation is demonstrated for this fixture; full recovery is not. The next saved combat run logs recovery attempt counts, next-attempt delay, position, command, expected destination, combat mode and movement capabilities on the existing ten-second diagnostic interval, to distinguish exhausted retries from competing engine orders without adding production polling.

The repository suite passed 457 tests before this diagnostic-only edit. The current live run has reached ADVANCE-BLOCKED and has not yet reported completion.


### Rebuilt run 142945

Runtime 133856 completed with 214 checks, 58 server findings, zero client findings and zero SQF error lines. All four processes were verified against their exact runtime command lines before stopping. The checked-in launcher rebuilt and launched runtime 142945: server 56828, headless clients 17132 and 56296, client 6672. Client pack initialization and Zeus readiness were recorded at 14:30:41-42, with headless pack initialization at 14:30:33. The first combat case started at 14:30:58. Its new fixture-combat-mode prerequisite confirmed group-requested RED and all six actual RED modes at 14:30:45. New assault, grenade and consolidation behaviour remains unaccepted until physical outcomes complete.


### 142945 recovery telemetry: competing orders after retry exhaustion

At 14:33:55-14:34:37, FLANK-NATIVE-FIRE recovery actor 2:675 reported six exhausted attempts, RED combat mode, enabled PATH and MOVE, and currentCommand ATTACK. It first stood at [1147.47,1248.12], later moved with expected destinations as far as [1488.08,917.17] and [1473.59,934.452], while the main element paused near [1154,1323]. This is evidence of conflicting engine attack destinations after the bounded recovery attempts, not merely insufficient observation time or disabled locomotion. Whole-group YELLOW comparison remains the next relevant control; do not resolve this by relaxing rejoin acceptance or extending time alone. This case is still running and its final outcome is not inferred here.


### 142945 first case ended; restoration prerequisite evidence

FLANK-NATIVE-FIRE ended STALLED during late observation at 14:35:23. Original and late physical-consolidation checks failed. At 14:35:51 combat-mode-restored passed, with all six expected RED values matching all six actual RED values after the new fixture prerequisite. This supports the fixture snapshot-timing explanation for earlier restoration failures in this scenario; it does not prove all interruption or external-mode variants. The next whole-group YELLOW/native-fire comparison started at 14:36. All four audit processes were verified live; no restart or acceptance waiver was performed.


## Breadth pass and live comparison, 27 September

Runtime 20260927-142945 remains live. At 15:09:28, ADVANCE-YELLOW completed with physical movement and moving-fire checks passing (shot counts 8,6,4,3,1,0). Standard ADVANCE previously ended STALLED at bound 1: one mover remained 41.83 m short for 25.23 seconds while another was moving. These are different outcomes; do not label all advance behaviour nonfunctional or accept all variants from the YELLOW result.

Saved after this launch: independent support/airborne/vehicles/fire focuses; hearing and report sight blockers; reinforcement accepted-owner assignment and cleanup checks; mixed-round ammunition conservation and measured donor removal; post-landing movement and repeat drop refusal; dismount prerequisite for remount; covered-area firing; real fire-control target hits and labels; artillery resupply/repeat delivery; post-defence aircraft flight; post-contact replacement-destination retention. Road-crossing and withdrawal smoke try available carriers until one throw is queued. None of these later changes are in the running mission.

All 460 repository tests and the SQF, parity and wiki gates passed for the breadth batch before the final withdrawal carrier edit; that edit passed syntax and 73 operation tests. Full live acceptance, real-road crossing, multi-squad variants and compatibility/performance scope remain open.


ADVANCE-YELLOW full-case review: completion, both elements starting/bounding, covering fire, moving fire, disabled cleanup and combat-mode restoration passed. Initial contact observation exceeded its 60-second window (15:05:21 failure, automatic drill started 15:05:35). Frontage failed at element 0 bounds 1 and 2, with measured depths 42.90 m and 41.41 m. Therefore this is a completed but rough manoeuvre, not a clean case. The contact timing issue and actual formation depth must be investigated separately; neither raw failure is waived.

Lighting QA now includes automatic owner-worker refresh after NVG removal and re-equipping, with live measured skill labels. These additive checks deliberately do not call the apply function after equipment changes. Syntax validated and repository regression suite passed; in-engine execution pending a fresh mission build. This remains skill-layer evidence, not target-detection acceptance.

Zeus replacement QA corrected from a shared destination radius to physical formation arrival: leader within 3 m, every living member travels at least 35 m and reaches its own expected destination within 3 m, remaining within 30 m of the leader. The 15-second hold samples displacement, survival and drill resurrection throughout. Historical failed assertions remain in their original RPTs with evidence-backed test-problem assessments; this change requires a fresh live run.

Damaged-armour QA now measures a disabled baseline on the same mobile damaged APC, requires natural opponent detection, samples movement and crew retention for 15 seconds, and verifies no smoke before enabling withdrawal. Enabled acceptance still requires actual smoke and retreat distance. Saved change is syntax-checked; live execution pending.

Recovery transition correction: FlankStep previously restored all mover ROE/AUTOTARGET overrides when the viable element finished its bound, including actors still in recovery. Runtime 142945 showed recovering actors reverting to RED while attempting rejoin. Cleanup now retains still-owned recovery overrides across bounds; rejoined actors use normal restoration, and FlankEnd retains final cancellation/migration cleanup. A newer unit ROE is not overwritten. Syntax and 82 focused regressions pass; physical recovery retest pending. This does not establish that group-level attack takeover is solved.

Separate passenger-group correction: generic vehicle reactions previously collected only vehicles whose effective commander belonged to the reacting group, preventing separate cargo squads from dismount/remount handling. Vehicle collection now includes mounted members, while withdrawal and gunnery remain restricted to the effective commander's group. Cargo operations retain same-group and local-unit PassengerReady checks, and feature-owned convoy exclusions remain unchanged. The vehicle QA retains the original same-group case and adds a separate-group variant with natural passenger contact and physical dismount/remount. Live validation pending.

Passenger fixture sightlines: separate cargo may face rearward, so the test now provides front and rear visible opponents, requires natural knowledge in both crew and passenger groups, and shows the group layout in labels. Both opponents are removed before remount. The passenger group's own remount record is logged. Full regression suite passed after these changes; live execution still pending.

Vehicle acceptance additionally requires original passenger and crew group membership after actual dismount/remount. Separate squads cannot pass by being merged into the driver's group. Syntax and focused regression checks passed; live case pending.


Mechanics live run 20260927-155107: ammunition transferred a real seven-round magazine with total rounds conserved. Post-contact physical consolidation, cohesion, replacement-order arrival and ten-second destination retention passed. Survivor regroup failed both physical approach and membership: survivors remained near [1200,1095], about 95 m from the host after 140 seconds; the controller logged a stall at 99.47 m. This is a functional failure in this fixture, not merely an arrival tolerance issue. Root cause remains unresolved. Additive ten-second QA samples now record living leader, command, expected destination, PATH state, speed and closest host distance without modifying behaviour or accepting flags as movement. These samples require a fresh build.

Regroup takeover correction: the ineligible MOVE path issued doFollow after Zeus or another controller took priority, potentially replacing the new unit movement order. It now retires without an order. Added a fresh, independent casualty-triggered regroup interruption fixture: real job prerequisite, physical eastward replacement travel, original group retention and ten-second no-merge return. It uses the production Zeus ownership handler, not real curator mouse input. This does not resolve the earlier unobserved cause of regroup stalling, and live validation is pending.

Runtime 155107 breadth findings: airborne passengers died about seven seconds after the accepted drop, neither parachute was observed, and post-landing movement could not execute. Cause unresolved; added audit-only board/exit/death events, chute configuration and one-second motion samples. Vehicle shared-group passengers were already outside with dismount disabled; the old enabled assertion incorrectly passed on that existing state. Enabled dismount and dependent remount now require passengers actually aboard at enable time. The original disabled failure remains; native dismount versus another controller remains to be isolated. No source fix is claimed for either behaviour.

Completed mechanics runtime 20260927-155107: 111 checks, 16 server findings, zero client findings and zero SQF errors, both completion markers present. Assessment sidecar preserves raw failures and flags the enabled dismount false-positive. Vehicle withdrawal physically passed and retained crew but smoke failed; the immediate fixture weapon snapshot was empty, so countermeasure initialization/equipment must be checked before attribution. Separate passengers failed natural-contact prerequisite and did not exit. Fresh airborne runtime 20260927-161928 launched after verified shutdown of only the four completed audit processes. Full 460 regressions, 1257-file SQF validation, 85-module parity, 113-page wiki structure and whitespace checks passed before launch.

Airborne root cause isolated by runtime 161928: audit pre-init explicitly configured WALDO_STATIC_STATICCHUTE=B_Parachute. This is a backpack CfgVehicles class, so the old existence-only validation accepted it. Live samples show both passengers remained on foot in freefall and died; no chute boarding event occurred. Corrected the audit pre-init to NonSteerable_Parachute_F and Cortex now requires ParachuteBase inheritance before exit, falling back otherwise. Added a separate B_Parachute override run with FALLBACK-prefixed checks, preserving the ordinary case and restoring configuration afterwards. Both saved corrections require fresh live validation.

Moving airborne fixture now requires actual speed >=50 km/h, travel >=100 m, and continued flight on a 4 km pilot-controlled route. Runtime 163830 met 106.758 km/h and 101.961 m before insertion, but its DROP job still retired after the first jumper with epoch unchanged and no Zeus hold. Inspection found helicopter installation lacked a ParachuteBase exclusion, potentially marking the jumper as a pinned helicopter pilot and invalidating the whole squad. Added exclusion before any handler/pin and an additive live chute-controller conflict check. Saved fix requires fresh validation; no claim that motion alone fixes insertion.

Runtime 164803: both passengers deployed and landed alive in both moving normal/fallback flights; chute controller-conflict checks passed. Post-landing movement printed PASS despite undefined _forEachIndex within findIf. This is a test failure, not valid physical acceptance. Replaced with an indexed forEach aggregate and per-unit travel/remaining measurements. Overall run must fail on SQF errors despite zero assertion findings. Fresh passenger enabled cases preserve original disabled cases and require controller records plus actual exits.

Runtime 165401: real seven-round ammo transfer passed again. Regroup physically approached and merged at 16:56:26 after leader succession; closest distances about 17 m. This run does not explain the older stall or establish repeat reliability. Added a separate two-squad withdrawal baseline to runReactions: natural contact, real casualties, per-survivor away travel, actual smoke, group/weapon retention and intra-squad spacing. Coordinated alternating overwatch/shared-rally acceptance remains absent; the added case is unexecuted.

Code-level ownership race: an EntityKilled regroup job or explicit airborne order may be queued before initial discovery. Discovery calls CortexLocality, changes owner epoch and clears reservations, invalidating the new job. Both start paths now adopt locally before reserving/queuing, with an ordering regression. Live link to the failed REGROUP-Zeus prerequisite is not yet proven; diagnostic values added to that assertion. 463 repository tests passed. Runtime 165401 still runs the prior source; it passed post-contact consolidation and Zeus replacement arrival/hold again.

### Grenade cancellation fixture ownership (2026-09-27)
Runtime runtime-20260927-165401 reproduced ASSAULT-DISABLED cancellation failure: one real throw, inventory 3 to 2. The fixture previously injected its drill token before the presentation delay, allowing discovery to replace that state. The saved fixture now adopts the local group and establishes the assault generation immediately before queueing, within the same unscheduled block as cancellation. It records and requires the queue-time token. This corrects the test precondition; it does not establish live cancellation success. Focused operations regressions: 74 passed. Existing runtime remains untouched; corrected fixture requires a fresh staged run.


### Sound investigation measurement (2026-09-27)
The live mechanics run again failed sound approach, without recording travel details. The assertion measured distance to the hidden shooter rather than the quantized sound report. Production requests a point 30 m short of the report with a 25 m completion radius; the former less-than-40 m shooter check can reject that intended stopping region. The saved test now requires at least 15 m actual travel and 15 m closure toward the recorded area, within the 55 m outer stopping region, and displays travel, range and phase. Full initial report, start/final positions and best range are logged. This is a measurement correction, not evidence that the previous failure was solely a test problem; fresh execution remains required.


### Per-burst artillery warning smoke (2026-09-27)
User-requested warning: the shared server fire sequence now creates four SmokeShellRed objects in a 25 m ring around the reported target and waits ten seconds before the first shot of each burst. WARNED retains the selected ranging aim; FIRING skips additional warnings. Applies to lethal support and counter-battery bursts; smoke-only fire missions bypass the warning. Normal eligibility and owner-local shot safety rechecks remain active after the delay. Smoke cleanup runs after sixty seconds independently of mission cancellation. No per-unit scanning is added. Focused regressions pass; physical smoke visibility, shot timing, per-burst counts, cancellation and HC migration still require live acceptance.


### Fallback landing route geometry (2026-09-27)
Runtime 165401 fallback post-landing movement failed with travel 70.2 m / 27.3 m and destination distances 0.2 m / 7.3 m. Both soldiers reached the arrival area, but the destination was only 70 m north of the leader; dispersed landing made the second route too short to require 30 m travel before arrival. The saved fixture puts the destination 70 m north of the northernmost landing position and asserts at least 65 m initial distance for every passenger. Physical movement and arrival thresholds are unchanged. Preserve the raw FAIL as a test-geometry problem; corrected execution is pending.

### Zeus cancellation with pending remount but no local state (2026-09-27)
Pending boarding is a public group variable; behaviour state is owner-local. Ineligibility cleanup and ReleaseGroup previously both required a non-empty local map. A pending remount with an empty map could therefore survive takeover. Both guards now also accept pending remount intent, allowing RestoreCalm with remount disabled to cancel boarding and clear the public record. This closes the state-shape gap; physical Zeus interception and HC migration acceptance remain pending.

### Warning observer and master-stop remount cleanup (2026-09-27)
Artillery audit 172726 created its warning phase and fired at 17:28:59 after the 17:28:43 warning. The EntityCreated observer recorded zero smoke objects; saved QA now observes ProjectileCreated, matching ammunition handling. No physical warning acceptance is claimed. Master Stop also now releases groups with pending public remount intent even if both local state and managed flag are absent, extending the Zeus cleanup correction to disabling Cortex.

## Multi-squad contact transition (27 September)

Live runtime 175212 exposed independent flank movement: one team split over 200 m while another barely travelled. These are failures, not accepted coordination. That run used per-squad drills. Shared alternating squad roles have since been implemented, but their physical movement acceptance remains failing.

Source review found that first contact cleared a responder rally and physical rally readiness was evaluated only in CALM. Saved changes preserve the reserved move and measure arrival in SupportMaintain in every phase. Empty assault dispatch no longer consumes the engagement; requester completion waits for responder assault acknowledgement. Added a separate contact-during-rally live variant, preserving screened and HC variants. These saved changes need a rebuilt live run.

### Combined bounds: live movement conflict remains unresolved

The 20260927-181516 run physically rallied both responding squads, but subsequently recorded repeated SUPPORT_BOUND stalls. Several movers reported ATTACK with LEADER PLANNED destinations instead of their assigned bound positions. This establishes failed movement, not its precise cause: it does not yet distinguish engine combat planning, a retained fire order, or an external controller. Additional failure-only diagnostics now record attack permission, behaviour, combat mode, target, movement/targeting features, group owner and support role. They run only when a bound fails, without another polling loop. Do not treat accepted roles, firing checks, or the 466 passing static tests as tactical acceptance. The new aggression default of 1.2 is tuning, not a fix for this conflict.

The next candidate also suspends TARGET pursuit only on active movers, retaining WEAPONAIM and FIREWEAPON. The existing disabled-feature records restore it at a halt, cancellation or owner migration; separated recovery actors retain it until recovery ends. This is a candidate fix, not a live pass. The original prohibition on disabling TARGET in the static check incorrectly conflated pursuit with weapon firing; the check now protects the actual weapon capabilities and requires restoration tracking.

### Per-element combat movement ownership (27 September, next candidate)

Runtime 183219 still reports stationary ATTACK actors while group attack is disabled, assignedTarget is null and PATH/MOVE are enabled. Pursuit suspension alone did not resolve the problem. The next candidate temporarily disables AUTOCOMBAT on active movers and changes COMBAT movers to per-unit AWARE, preserving their weapons and the covering element. It records prior behaviour, restores only its owned value at halt/end, and includes restoration in locality checkpoints. Recovery actors retain their owned movement state until recovery ends. This uses existing bound transitions, not another per-unit polling loop. The live coordinated audit additionally verifies restoration of TARGET, AUTOTARGET, AUTOCOMBAT and PATH. Static acceptance: 467 tests, 1259 SQF files, 113 wiki pages and 85 Zeus modules pass. Physical movement and fire acceptance remain pending a rebuilt mission.

### Reported objective covering fire

Source review found a separate integration gap: responders can hold a valid coordinated COVER role while their personal enemy list remains empty. FireControl returned before considering the report, and GroupTick only called it in CONTACT. Saved changes permit suppression of the existing reported position for matching, unexpired coordinated leases and call it on the existing group tick outside CONTACT. They do not reveal an enemy object or assign an unseen target. Existing feature gates, ammo limits, suppressor caps, cooldowns and friendly line-of-fire checks remain. This change is not staged in runtime 185004 and still needs live acceptance.

### Completed-bound ownership leak

GroupTick retained actors in its holders list after a replacement drill began. When their leader came within 30 m, its reunion pass could issue doFollow over that drill. It now transfers active drill members out of the previous holding list before reunion. This is a source-confirmed competing-order path; its contribution to live ATTACK stalls is not yet proven. Failure diagnostics now distinguish assignedTarget from getAttackTarget, since an empty assigned target does not prove that an engine attack task is absent. Runtime 185004 still stalled with AWARE and automatic targeting/combat disabled, so those overrides alone are insufficient.

### Attack-to-movement handoff candidate (27 September)

The 190743 live run confirms `getAttackTarget` still names the hostile on stalled movers, although `assignedTarget` is null, group attack is disabled, and PATH/MOVE are enabled. Target selection gates alone do not clear this existing command. The next candidate briefly disengages only an actor with an active attack target, returns it to leader command, and immediately restores its moving combat mode before the bound order. No group-wide ceasefire, sustained BLUE movement, teleport, or relaxed arrival criterion is introduced. This remains unverified in engine until the rebuilt run completes.

Live follow-up: runtime 192529 completed 32 checks with four findings and zero SQF errors. ADVANCE-AWARE physically completed multiple team bounds but ended PARTIAL with a separated actor. Contact timing, frontage, complete arrival and firing while moving failed. The momentary per-unit disengagement is not an accepted fix; normal-combat comparison follows. Runtime 190743 completed 35 checks with five findings and zero SQF errors, preserving the coordinated movement and replacement-order failures.

Normal combat comparison 193231 completed 33 checks, four findings, zero SQF errors. Covering fire and shots during movement passed. Contact deadline, frontage, clear-through and complete outcome failed; ending GRENADE_UNRESOLVED, with the leader separated. A separate source defect was corrected: explicit cancellation by the queued throw callback now records the drill token; GRENADE may continue without a throw only for that matching cancellation. Unconfirmed attempted throws and live projectile expiry still retain the existing safety stop. This change awaits a rebuilt live run. The procedure card now changes from contact to movement when the drill starts.

### 2026-09-27 original-waypoint return

Runtime 194843 completed with seven findings. Both teams physically completed bounds 0–2 with covering fire. During bound 3, actor 2:709 changed its expected destination to the original group waypoint [1200,1500,0], reached it, then returned too late. Stationary-only recovery did not catch this moving diversion. The candidate now detects return to the unchanged original waypoint and uses the existing two retries, eight seconds apart, without changing waypoints or relaxing arrival. Zeus eligibility is checked first. Live acceptance remains pending; this does not establish that every competing engine order is resolved.

### 2026-09-27 advance through objective: passing server run

Runtime 200043 completed the focused ADVANCE-GRENADE server procedure with zero findings. Both three-person elements physically reached all bounds, one real fragmentation grenade fired, the live-frag crossing gate passed, both elements cleared through the objective, and fire while moving was observed. The controller ended COMPLETE with no separated actors. One bounded movement retry occurred. This is one successful server-owned run, not proof of HC migration, repeated reliability, or multi-squad acceptance. All 472 repository regression tests, 1259 SQF files, 113 wiki pages and 85 Zeus parity entries passed static gates. Runtime 195847 was deliberately interrupted to remove a newly found callback-scope error before acceptance.

### Tactical tempo and shared objective candidates

Final advance, clear and consolidation holds now use the existing bound pause (default four seconds); standalone flank final holds use twice that value. Normal bounds already used the pause. Grenade clearance is unchanged. Coordinated FlankStep now takes its enemy position from the validated matching support role, rather than an older local contact position in a still-CALM responder. These changes were saved during runtime 200752 and are not present in that running mission; both need rebuilt live validation.

The next coordinated run also logs role, controller stage, expected destination and physical position every fifteen seconds inside the QA harness only. An additive unopposed handover follows the existing threatened ordinary/Zeus handovers: it removes the fixture enemy but does not reset actor position, AI features, behaviour or combat mode. Earlier failures remain recorded; the comparison is diagnostic, not a substitute for threatened handover acceptance.

Runtime 200752 completed 36 checks with four findings and zero SQF errors. Inter-squad role exchange, physical covering fire, intra-squad cover and opposite-side approach passed. Viable arrival was 6/6 and 4/6; the all-actor arrival requirement still failed. Natural rally sight and threatened ordinary/Zeus handover failed. Feature and attack-setting restoration passed, but several actors remained in native ATTACK during replacement orders. This build predates the tempo/objective and diagnostic changes; its results remain separate.

### Backtracking during coordinated bounds

User observed repeated back-and-forth movement in runtime 202509. Removed the experimental momentary BLUE/doFollow handoff: issuing native formation follow before the individual bound was not proven to clear attack state and introduced a competing movement order. Also prevented completed-bound holders from receiving ordinary near-leader regroup orders while the squad-level assault still owns them. Hold records remain available for cleanup; active-drill filtering remains. These are candidates pending a rebuilt run, not a claim that all backtracking is fixed.

### Failed coordinated bound returning to leader (27 September)

Source review confirmed that STALLED/TIME_LIMIT called FlankEnd, which issued doFollow to every actor before the coordinator retried. The candidate now preserves gained ground for a still-valid coordinated lease, transfers PATH ownership to supportHeld, and releases those holds only for a new MOVE sequence or reservation cleanup. The original failed outcome remains published. Zeus/ineligibility and release do not enter this holding path. Static gates: 475 repository tests and 105 Cortex SQF files pass; live acceptance pending rebuild. This addresses failure cleanup, not yet the separate native ATTACK command overriding moving actors.

### Required avenues-of-approach routing (source candidate; not accepted yet)

The user requires terrain-aware routing for flank, advance, assault, withdrawal and coordinated movement. Saved source now gives flank, advance, initial and obstruction-replanned infantry withdrawal, and coordinated helper approaches one shared group-level selector. It considers no more than eight caller-supplied candidates and three geometry samples per leg, rejects water and supporting-fire corridors, preserves the starting side of a support axis, and scores terrain/solid ballistic screening separately from weaker visual concealment. Longer legs add at most twelve arithmetic safety samples without adding geometry rays. The chosen legs are reused by the existing bound planner; there is no per-unit or per-tick search. A confirmed withdrawal obstruction excludes the failed destination before selecting another avenue. Final clear-through remains deliberately direct across the fixed objective; its approach into that close phase still needs physical acceptance.

Preserve existing tests and add comparative covered/exposed approach fixtures, vegetation concealment versus solid cover, terrain dead ground, constrained crossings, blocked avenues, objective change, Zeus takeover, and HC migration. Measure actual actor trails, exposure along travel and arrival; planned points alone cannot pass. Maintain squad frontage at firing positions while allowing a narrower approach through terrain. Replan only on objective change or confirmed obstruction. Vegetation concealment must not be reported as ballistic cover. Include routing cost in the approved 50-group budget of at most 5% added median frame time and 10% added p95 frame time versus Cortex off. The saved source is a candidate, not live acceptance.

### Approach geometry diagnostic, 29 September

Live runtime 142009 still shows long lateral journeys under MOVE before any failed-bound cleanup. The x coordinates near 1400/1600 match the ends of the original concrete screen at y=1470. This is a correlation, not proof of retained engine path geometry. Added coordinatedclean with short initial helper view screens away from the later approach corridor; preserved coordinatedbounds and all original acceptance checks. CLEAN- prefixes keep results separate. The saved cleanup fix alone has not resolved all movement failures.


### Movement and engagement review, 29 September

Runtime 145259 retains native ATTACK commands on stationary moving-element actors despite PATH/MOVE being enabled and bounded doMove retries. The same-frame group BLUE/reset experiment did not reliably clear those commands; observed per-unit modes also changed after the reset. Removed that experiment from saved source. No claim of corrected handoff is made. Runtime 143341 completed with 38 checks, five behavioural findings and 75 SQF error lines; a findIf callback incorrectly used _forEachIndex in the unopposed handover diagnostic. That callback is now an indexed forEach. Its earlier result remains invalid evidence.

Saved movement code retains automatic target acquisition and weapon use. Only Cortex-owned matching cover stances are released when movement starts. Stationary drill members may use cover stance selection; movers, recovery actors and pending grenade throwers retain their own operation. Coordinated handoffs no longer add fixed pauses. Separate rally reservations remain geometric candidates, not terrain-aware routes.

Additive coordinated checks measure moving-element shots at the FiredMan event (speed at discharge, excluding Throw/Put), and the longest interval of no physical squad movement while a MOVE destination remains outstanding. The latter is an empty-range diagnostic, not a universal combat deadline. Existing arrival, all-actor and viable-element progress, covering fire, backtracking and handover checks remain. New measurements are not present in runtime 145259 and need a fresh build.

Saved regression gates: 480 repository tests passed, 1259 mission SQF files validated, 113 wiki pages and 64 image references validated, and 85 Zeus modules passed parity. Physical movement acceptance remains unresolved. Grenade evasion still excludes drill actors and requires deliberate preemption/resume work; removing that guard without restoring movement ownership would introduce another competing order.


### Coverage wiring and tracked STOP release, 29 September

The completed runtime 145259 recorded 39 checks, seven failed checks and no SQF errors. Both threatened handovers and the unopposed comparison failed. All prior results remain. A separate source review found supportHeld cleanup enabled PATH but did not retire Cortex's doStop. Saved cleanup now resumes only tracked local followers whose command remains STOP when coordination ends; a new bound or a newer individual command is not replaced. This does not claim to clear persistent ATTACK state. Runtime 153709 has entered the rebuilt VR mission with two HCs to retest the candidate.

All 55 manifest cases now have explicit executable_sources. check_cortex_coverage.py checks declared settings, file existence, launcher staging and server dispatch. Its optional --require-accepted gate fails while any feature remains incomplete. This is structural coverage only. Road crossing now has runCrossing.sqf with engine-road, natural-contact, real smoke and physical far-side checks. VR cannot supply the road prerequisite; the real-terrain run and remaining thirteen variant categories are still required. All existing feature cases remain partial.

Regression gates passed: 483 tests, 1259 production SQF files, 29 QA SQF files, 113 wiki pages, 64 image links and 85 Zeus modules. Handover actor labels now identify ORDINARY ORDER, ZEUS ORDER or UNOPPOSED ORDER rather than preserving stale RALLY labels. Trails and failed assertions remain intact.

### Fire-at-will movement ownership, 30 September

Runtime 20260930-182028 completed with 45 server findings, three client UI findings and no acceptance claim. The coordinated case repeatedly left movers under native ATTACK while Cortex owned an unfinished MOVE; physical advance, moving fire, idle, backtracking and threatened handovers failed. The unopposed handover later moved, which distinguishes permanent path loss from combat-order conflict. The earlier controlled comparison remains decisive: ADVANCE-YELLOW physically completed with moving fire while the matching RED advance stalled. Arma defines RED as fire-at-will plus independent engagement and YELLOW as fire-at-will while retaining formation.

Saved correction gives a RED group a finite, owned YELLOW lease for the whole manoeuvre, one scheduler step before its first bound. It never uses BLUE and therefore does not silence the base of fire. The covering fire-team and supporting squad retain target acquisition and explicit suppression; only current movers keep their existing bounded pursuit-feature leases. The original group mode is restored only while the live value still matches Cortex's applied YELLOW, and the lease is included in locality checkpoints. A later Zeus, waypoint or script ROE change ends the manoeuvre as ROE_CHANGED and survives cleanup. The coordinated audit now separately requires live MOVE-stage samples to remain YELLOW and retains actual fire, movement, ATTACK-override, idle, backtracking and handover checks. Static acceptance: 149 Cortex tests and 1262 SQF files pass. Fresh in-engine acceptance is required.

# Withdrawal movement ownership

- Retreat smoke and the retreat route are independent layers. Smoke may execute even when the
  engine has replaced the route, so smoke is never evidence of physical withdrawal.
- A group in RED grants the engine independent pursuit authority. Cortex now leases RED to YELLOW
  for the withdrawal: weapons remain fire-at-will while the finite retreat waypoint retains movement
  ownership. Cleanup restores RED only if the group still has the applied YELLOW value; Zeus or
  another controller changing ROE wins immediately.
- The lease is part of the public restoration checkpoint so a headless-client locality change cannot
  strand the squad in Cortex's temporary mode.

The CONTACT transition previously treated release of a garrison or defence order as the whole
retreat, and performed no action at all for a building-clear order. Those branches now release the
previous movement owner and then call the common physical retreat transition. Surrender remains the
higher-priority terminal reaction.

# Vehicle movement ownership

Vehicle withdrawal and anti-tank standoff both use the same temporary group-waypoint mechanism as
investigation, support and retreat. Previously a damaged vehicle could receive a withdrawal and then
replace it with standoff in the same evaluation; coordinated or local infantry movement could replace
that waypoint on the next scheduler tick. Vehicle tactics now report movement ownership, persist it
while their physical waypoint is unfinished, give withdrawal priority over standoff and block other
Cortex movement acquisition. Gunnery and the other contact layers continue normally.

The ownership check is deliberately not an early return from vehicle handling: it blocks only a new
destination. Target selection, firing, onboard reports and passenger handling still run during the
move.

The lease is now a shared group-movement contract rather than a vehicle-only flag. Mobile artillery
uses it for shoot-and-scoot. A battery waits in bounded five-second steps if a manoeuvre or explicit
order already owns movement, then acquires the lease when free. Contact entry and investigation
observe the lease even if vehicle tactics are disabled. The authenticated request token and deadline
are public so a new group owner can resume a pending relocation after locality migration.

Locality adoption restores and clears the old owner's transient state before it resumes an
authenticated pending relocation. Support-reservation cleanup also checks the shared lease before
deleting a route, so an expired rally cannot erase a newer vehicle or artillery movement.

Remnant regroup now records every soldier it stops for the merge. Completion, timeout, feature
disablement, locality invalidation, and Zeus takeover release only Cortex-owned combat-labelled
holds. Newer direct movement, boarding, action, and scripted unit commands remain authoritative.

Cover stance selection now enforces its documented stationary-only contract. A soldier already
moving for a bound, regroup, backblast clearance, or engine route keeps an engine-selected stance;
Cortex samples cover only after speed falls below 1 km/h.

Infantry withdrawal now releases the explicit `supportHeld` actors from both PATH locks and
`doStop` before it issues the retreat route. The route acquires the shared movement lease as
`INFANTRY_WITHDRAW`, preventing stale support cleanup or another tactic from replacing it.

Garrison and defence replacement-order release now distinguishes Cortex-owned `doStop` holds from
newer direct commands. Combat-labelled owned holds rejoin the leader so a fresh group waypoint can
move them; direct movement, boarding, actions, and scripts remain untouched.

Blocked anti-armour backblast now creates one ten-second actor movement reservation. The relocation
is not reissued every group tick, a newer destination cancels it, and coordinated bounds omit that
single actor until the reservation expires. The rest of the squad remains free to move and engage.

# Tactical initiative selection

Source review found three independent random vetoes in the active contact path. A squad could reject
flank and then reject advance despite satisfying both physical prerequisites. More seriously, a
requester could rally and reserve support squads, then reject the assembled coordinated assault and
wait 120 seconds. These outcomes presented as intermittent inactivity and wasted completed support
work rather than useful tactical variation.

`cortexTacticalStart.sqf` now treats positive flank and advance profile values as relative preference
weights. One bounded draw chooses the first viability check; if that manoeuvre cannot start, the
other positive enabled option is attempted immediately. The start functions retain their actor,
range, route, lease, morale and cooldown gates, but no longer add independent random rejection.
Prepared coordinated assaults launch deterministically when participation is positive. Zero remains
an explicit exclusion. The selector adds no scheduler, persistent loop or per-unit scan.

This is source and static-regression evidence only. It requires a fresh audit build and repeated live
contact cases before it can establish improved tempo or combat effectiveness.

The shipped profiles previously assigned identical flank and advance values within every profile.
After converting those values from independent permission rolls to preferences, that would have made
every profile choose the same 50/50 style. Defaults now progress from direct-bound preference for
MILITIA and LINE to increasing flank preference for VETERAN and ELITE. This changes first choice,
never the immediate fallback or the physical viability gates.
