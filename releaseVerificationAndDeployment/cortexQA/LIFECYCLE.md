# Cortex lifecycle review

Status: source review in progress; this is not whole-system live acceptance. Trigger, completion and migration contracts must be tested together. Sources below are relative to MissionScripts/AiScripting/Cortex unless stated otherwise.

## Existing group flow

| State/action | Trigger and start conditions | End and next action | Current ownership behaviour |
|---|---|---|---|
| CALM | Eligible local group discovered; master/contact gates open | Real recent knowledge enters CONTACT; usable report can enter INVESTIGATE | Locality resets local state and rediscovery reassesses |
| INVESTIGATE | Valid area report and corresponding hearing/report/investigation gates | Direct contact interrupts; expiry or live investigation-gate closure immediately restores calm | Temporary movement is cleared during adoption; investigation is not resumed verbatim |
| CONTACT | Recent enemy knowledge; current eligible living leader | Morale may retreat/surrender; lost contact enters SECURITY or restores calm only after the current bounded flank, advance or coordinated movement has ended | Enemy knowledge and local state are reacquired |
| Flank / advance | CONTACT, positive enabled profile preference and actor/distance/cooldown requirements in start function; one weighted choice sets the preferred order and the other viable tactic is an immediate fallback | Physical bound arrival exchanges roles or advances index; COMPLETE, CLOSE, LOSSES, STALLED, TIME_LIMIT, ABORT and RELEASE are distinct endings | Checkpoint restores disabled capabilities and movers; current migration cancels the manoeuvre rather than resuming the bound |
| SECURITY | No recent visible contact beyond configured loss interval | New contact interrupts; security delay selects search actors or enters REGROUP; live post-contact gate closure restores calm | Reassessed after adoption |
| SEARCH | Security interval completed, suitable riflemen and remembered position | Arrival, no actors, contact, search expiry or live post-contact gate closure returns actors; CONTACT, REGROUP or CALM follows | Phase, target, original deadline and search actors are public. The new owner rebuilds unfinished physical movement, chooses a living replacement after casualties and never extends the deadline |
| Coordinated assault handover | A responder has rallied, accepted the server role and completed its screened final approach; coordinated participation is positive | The prepared bounded drill launches without another random rejection, assaults to the objective and clears through; it does not stop at the flank | Tokened role and original lease remain authoritative; migration revalidates the role before rebuilding movement |
| REGROUP | Search/retreat ends | Physical radius measures COHESIVE; deadline records INCOMPLETE; both release to CALM. New contact interrupts | Holders/settings are restored, but full consolidation progress is not replayed |
| RETREAT | Morale result, or a mobile damaged vehicle; usable enemy position and dry retreat candidate | Ends active drill first; temporary waypoint drives withdrawal. At least 30 m physical travel is required. A vanished waypoint or 15 s without net travel replans at a different angle, up to four times; 120 s records INCOMPLETE and enters REGROUP. Eligible on-foot survivors may surrender; mounted actors continue withdrawal | Movement type, origin, target, deadline and replan progress are public. A new owner restores old controls, then resumes the same bounded infantry or vehicle route without replaying smoke or countermeasures |
| SURRENDER | Morale outcome, gate and eligible local on-foot actor | Releases explicit and automatic orders, then hands captivity to ACE | Captivity is separate from normal manoeuvre state; transfer and release variants still require acceptance |
| Explicit defend / garrison / clear | Valid owner-routed operator request and valid positions/building | Own release functions; Zeus takeover releases holding orders; rejected replacement should preserve prior order | Public assignments replay on adoption; clear resumes its public order through discovery |
| Reinforcement / coordinated support | Server reservation and owner acknowledgement | Lease expiry, revocation, feature closure or requester completion clears owned movement/settings | Server lease remains authoritative; owner accepts current token; full tactical continuation requires QA |

Sources: cortexGroupTick.sqf, cortexFlankStart.sqf, cortexAdvanceStart.sqf, cortexFlankStep.sqf, cortexFlankEnd.sqf, cortexRetreat.sqf, cortexSurrender.sqf, cortexOrderLocal.sqf, cortexSupportMaintain.sqf, cortexDiscover.sqf, cortexLocality.sqf, cortexCheckpoint.sqf.

## Handover invariants to prove

1. Validate the new action before invalidating a valid old order.
2. Invalidate old jobs/callback tokens before they can affect the replacement.
3. Release only settings, destinations, reservations and event handlers owned by the outgoing action.
4. Publish enough intent for the new owner to continue or explicitly report cancellation. Never report a resumed action when it was only rediscovered.
5. Apply the incoming order only after outgoing cleanup; delayed cleanup must not issue follow/stop/target commands over it.
6. Distinguish physical completion, cancellation, failure and time expiry in results and Zeus feedback.
7. Restore squad cohesion without overriding a newer Zeus order, explicit holding order, captivity, medical state or vehicle role.
8. Preserve authored feature exclusions and AI capabilities; do not enable capabilities that Cortex did not disable.

Group-phase changes now use one owner-local atomic path which updates `phase` and `phaseStart` together
and publishes a bounded 32-entry `[serverTime, from, to, reason, owner]` history. Diagnostics flag any
current phase which disagrees with the newest published transition. The contact lifecycle audit requires
the real `CONTACT -> SECURITY -> SEARCH -> REGROUP -> CALM` physical sequence and the matching public
ledger; the ledger is evidence of ordering and never substitutes for movement, firing or arrival.

## Confirmed gaps and changes

- Automatic drill migration remains restore-and-reassess. Investigation, search and withdrawal now have explicit continuation policies; WMP and ACE transfer/disconnect tests must prove them physically.
- RestoreCalm previously cleared checkpoint data before a pending drill had necessarily restored disabled capabilities. It now ends the drill synchronously before clearing temporary waypoints/checkpoints. Static regression added; live transition/migration acceptance pending.
- Retreat now records actual travel and bounded replans in `Waldo_Cortex_Withdrawal`; a vanished waypoint below 30 m cannot count as withdrawal. The 120-second escape remains an explicit `INCOMPLETE` result. Live blockage, casualty and network acceptance remains pending.
- Post-contact ownership now waits for an active local drill, reinforcement approach or coordinated assault to finish or abort. Smoke, terrain or a temporary sighting gap cannot silently switch the group to SECURITY during that bounded action.
- Zeus cleanup preserves a replacement autonomous-attack setting as well as replacement movement, behaviour, speed and ROE. Static ownership regression is present; live operator acceptance remains pending.
- Contact can invoke fire control, stance, anti-armour and movement systems during the same tick. Fire control and stance exclude drill actors; anti-armour movement needs an explicit ownership review. Do not assume all concurrent actions respect the same actor reservation.
- Zeus marking publishes a hold token; owner cleanup occurs on a subsequent tick. Real curator event delivery, new-order arrival and no stale command resurrection must be observed for every action phase.
- SafeStart/ENDEX postpone scheduler jobs; that alone does not establish that already-issued engine movement has stopped. Pause semantics need explicit acceptance.
- Investigation and post-contact switches are now live permissions. Closing either gate during its active phase uses the ordinary restoration path immediately, instead of allowing search movement and changed settings to survive until a timeout. Static cleanup coverage is present; live UI switching remains pending.
- Reinforcement, Contact and Coordinated Assault gate closures reject the exact accepted support token to the server before local role and movement cleanup. This prevents a stopped responder retaining a dead role or consuming a support slot until lease expiry. Token, snapshot and sender validation make repeated or racing cleanup harmless; live cross-owner closure remains pending.
- A calm remount now survives group-locality migration as semantic passenger/vehicle intent. Adoption first retires old-owner commands, then restores only living, local, still-unassigned passengers against the original deadline. Zeus and a newer vehicle assignment win; repeated migration cannot extend the attempt. Cross-owner boarding remains pending live acceptance.
- Locality adoption now rechecks the current Investigation, report/hearing, Post-contact, Vehicles and Remount gates before it rebuilds any semantic movement intent. A closed gate clears the durable transition instead of issuing a stale move for one scheduler interval. Static ordering coverage is present; physical migration with live setting changes remains pending.
- Counter-battery acquisition now rejects its delayed callback directly when the live feature switch closes. Shoot-and-scoot publishes SUPPORT or COUNTER purpose with its durable token, and every delayed/locality-resumed relocation rechecks that feature and its own scoot switch before acquiring movement. Static ordering coverage is present; owner migration during the firing-to-relocation handover remains pending.

## Remaining inventory

Complete individual lifecycle rows and transition tests for artillery/spotters/counter-battery, convoy/cargo/armed crews/recovery, airborne insertion, aircraft flares/break-away/deceleration/landing, grenade evasion/throws, cover/stance/fire control/anti-armour, ammunition sharing, remounting, survivor merging, lighting/profile refresh and UI/settings replay. Keep coverage.json cases and existing visual fixtures; this review is additive.

Required test dimensions: natural trigger, refused start, actual work, successful physical finish, timeout, blocked actor, casualty, gate closure, repeated start, replacement, Zeus intervention, WMP HC, ACE HC, disconnect, JIP and another module controlling the same actor. Each transition checks outgoing cleanup AND the incoming physical outcome.

## Stuck and separated actors

Required: bounded individual recovery, sufficient covering strength, continued movement by the viable element, straggler rejoin, and explicit fallback when too few actors remain. No teleport or false arrival. First saved layer reissues the unchanged destination at most twice, eight seconds apart, without resetting physical progress or overriding disabled PATH/MOVE. The subsequent recovery layer is described below; the physical blockage matrix remains unaccepted. Do not treat retries as full contingency support.

Anti-armour now excludes current drill movers and refuses relocation from explicit holding/clearing assignments or disabled PATH/MOVE, while allowing safe stationary fire. Live interaction tests remain pending.

## Additive combat handover fixtures

FLANK-ZEUS and ADVANCE-ZEUS require 8 m physical movement before invoking the production Zeus marker. They check capability restoration, stale-job rejection and physical replacement travel. The original all-members-within-15-metre and 20-metre drift checks remain, alongside formation-aware checks requiring leader arrival, each soldier reaching its engine-assigned formation position, and stability for 15 seconds. Opponents are removed at replacement to isolate command ownership.

Runtime 133856 passed replacement formation arrival for both cases and formation stability for Flank; the original fixed-radius findings remain recorded. These are direct-handler server cases, not proof of real curator event delivery, ongoing-fire handover or headless migration. FLANK-ZEUS-CONSOLIDATE additionally waits for the normal clear-through/consolidation transition and requires 8 metres of support-element travel before replacement. That new case is staged in runtime 142945 but has not yet completed.

Remaining live operator checks must use actual Zeus orders during approach, grenade hold, clear-through and consolidation. Confirm the curator event reaches the owner, old restrictions are restored, replacement movement physically occurs, and no old job resumes. Repeat on WMP and ACE headless ownership and during owner disconnect. A direct function call cannot substitute for these UI and network checks.

## Observable manoeuvre acceptance

These are intended outcomes, not claims that current live tests pass.

| Action | Observable work | Successful end |
|---|---|---|
| Advance | One element moves while another covers; roles exchange at bounds. Both elements retain useful frontage and may engage. | Whole squad advances through the intended bounds; separated actors are accounted for. |
| Flank | Base engages while manoeuvre element moves laterally then approaches from an offset; broad threat-facing frontage. | Manoeuvre element physically occupies the flank; assault or consolidation follows explicitly. |
| Assault | Covering fire, short approach and safe grenade use where appropriate; close and clear. | Physical occupation/clearance followed by consolidation, not merely last-waypoint acceptance. |
| Building clear | Use a usable entrance, traverse assigned internal positions and engage. Retry another accessible approach when blocked. | Required positions reached; inaccessible rooms/buildings remain explicitly unresolved. |
| Garrison | Occupy usable internal positions and observe/fire through useful sectors. | Assigned occupants are physically inside at correct elevations. |
| Defend | Spread over a frontage, select usable cover and maintain observation/firing opportunities. | Occupy and hold positions; explicit replacement or withdrawal releases them. |
| Withdraw | Move away from the threat with supporting fire and smoke where useful; stronger squads use covering elements. | Physical separation and regroup, with retained actors/weapons as applicable. |
| Contact reaction | Orient to known danger, engage/use cover and select a compatible manoeuvre. | A deliberate follow-on action or post-contact transition; no competing movement loops. |
| Investigate/search | Approach reported area using bounded knowledge; supported search actors rejoin. | Area search ends distinctly by arrival, contact, expiry or cancellation. |
| Regroup | Actors close on the squad and resume its mission; stragglers stay accounted for. | Physical cohesion, or explicit incomplete recovery. |
| Surrender | Stop fighting, release old manoeuvres and enter supported captivity. | Stable captive/disarmed state without stale combat work restarting. |
| Convoy | Column following, occupants retained during travel, push-through while mobile; pinned cargo dismount with crew retained. | Intended stop/arrival with correct seat-role handling and useful Zeus feedback. |
| Zeus replacement | Old action releases restrictions, then actors obey the replacement. | Physical replacement-order execution with no old-order resurrection. |

Multi-squad variants require assigned supporting/manoeuvring squads, coordinated progress and a shared consolidation plan. They are not proved by a single-squad pass. QA cards must distinguish these intended manoeuvres from the narrower scenario currently being exercised.

Coordinated assault approach assignment now evaluates bounded left/right candidates from each helper's durable rally area. It rejects routes that enter the requester's firing corridor, keeps squad approach points at least 35 metres apart and samples three fixed points on each candidate route for terrain or solid-geometry screening. The bounded score favours a screened approach without adding per-tick or per-unit scans. This removes the previous dispatch-order alternation that could make a helper cross the base of fire. Physical live acceptance remains outstanding.

Recovery follow-up: saved controller now tracks stragglers, continues only with at least two actors and 60 percent of the original element, bounds rejoin attempts and reports PARTIAL when separation remains. Rejoining requires usable PATH/MOVE and occurs between movement stages, avoiding mid-bound insertion into obsolete slots. Controlled PATH-inhibition fixtures were added; physical geometry blockage, separated leaders, multiple blocked actors, migration and explicit fallback notifications remain pending.

Movement ROE candidate: RED movers use YELLOW during each bound to retain firing without independent pursuit. At halt, release or ownership adoption, restore the original value only if the current value still matches the Cortex-applied override. Other authored modes and later external changes are preserved. Live acceptance remains pending.


### Assault continuation and consolidation (saved candidate, live acceptance pending)

Advance and Flank may enter assault after their final hold when enabled and the existing morale, range and aggression checks allow it. They approach the fixed reported objective, optionally throw a carried frag after arrival, wait for confirmed deployment and projectile clearance, then cross 20 metres beyond the objective. The direction remains fixed while crossing. An unresolved queued frag ends explicitly after thirty seconds rather than allowing the rush.

After a flank clears through, its on-foot covering element moves forward to a line 12 metres beyond the objective while the assault element holds. Actual arrival and a ten-second hold precede completion. Advance has already brought both elements through. All stages remain part of the same owner-local drill: Zeus takeover, feature disable, eligibility loss and ownership migration use its existing cleanup. Stragglers cannot produce full completion. The physical-consolidation case measures the entire squad and support movement; implementation alone does not pass it.
