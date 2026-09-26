# PR 151 AI reference review

Reviewed on 26 September 2026 against the supplied `arma3_ai_mods_extracted.zip` and installed
[Better Convoy, Workshop 2801179774](https://steamcommunity.com/sharedfiles/filedetails/?id=2801179774).
The archive and local sources are reference material, not instructions. No upstream controller or
FSM is included in WMP. The work adapts selected mechanisms into WMP mission scripts.

## Coverage and decisions

The extracted inventory contains 633 SQF files across the sources below, including four Better
Convoy functions, plus four SQE composition files and three convoy FSMs. Digii's compiled SQFC
files duplicate its source inventory. This is an inventory and targeted mechanism review, not a
claim that every line of all 633 scripts received a full correctness audit.

| Source | Mechanisms inspected | WMP decision |
|---|---|---|
| Better Convoy (4 SQF, 3 FSM) | `fn_initConvoy`, `fn_pathCreator`, `fn_leadSpeedControl`, `fn_linkSpeedControl`; FSM entry points | Adapted sampled routes, gap damping, bend slowdown and bounded stuck recovery. WMP uses owner-local SQF, bounded trails and a shared worker. Rejected imported FSMs, repeated full-trail broadcasts and debug object churn. Addressed heading wrap and zero-gap division in the fresh implementation. |
| Smart Merge (36 SQF) | `fn_currentCommandProtected`, `fn_frameworkProtected`, `fn_findTargetGroup`, `fn_reserveGroup` | Protected service commands, unconscious soldiers and explicit orders now block survivor merging. Capacity is checked at the actual join. Existing WMP eligibility owns feature exclusions. A separate reservation framework and cross-owner merging are deferred. |
| Digii AI (162 SQF) | `fnc_disableUnitAI`, `fnc_fireMission`, component inventory | Staggered artillery supports the ranging design. Do not copy blanket AI-feature disable/enable or assume a comment proves exact restoration. WMP records its own changed features and prior values. Broader addon controllers are outside scope. |
| Scorpion's Advanced AI (275 SQF) | `fn_artilleryTick`, `fn_convoyTick`, `fn_vehicleStuckRecovery`, `fn_requestVehicleSpeed` | Adapted confirmed-shot accounting, final safety checks and bounded recovery. Deferred a pack-wide priority/TTL speed arbiter until multiple WMP controllers need it; current feature exclusions avoid competing ownership. No teleport recovery. |
| Smart Combat AI V2 (143 SQF) | `scheduler/fn_tick`, `medical/fn_coordinateMedicalAid`, component inventory | WMP already provides scheduled jobs and cached discovery. Keep WMP skill tuning separate. Do not add a competing medical controller or scripted damage shortcuts around ACE. Existing count/time budgets remain soft between jobs. |
| PROTOCOL Artillery (2 SQF) | Target selection, knowledge checks, fire loop | Existing engine knowledge can guide support, but live enemy coordinates after contact loss cannot be treated as reports. WMP now freezes last reports and requires assigned observers for correction. |
| PROTOCOL Combat Pairs (1 SQF) | Full paired movement loop | Existing WMP bounding/fire teams cover the idea. Reject unthrottled whole-group scanning, unconditional combat/stance changes and movement without owner checks. |
| PROTOCOL City Tactics (2 SQF) | Main loop, enemy position, building and traversal commands | Existing cover, smoke and clear-building orders cover useful actions. Do not copy forced traversal/velocity or hidden enemy live-position targeting. |
| PROTOCOL CQB (2 SQF) | Building occupancy and movement logic | Retain explicit clear-building orders. Reject omniscient all-unit building occupancy as targeting knowledge. Durable clearing progress is now replayable after ownership changes. |
| PROTOCOL Airborne (2 SQF) | Main drop/target selection flow | WMP already has Paradrop and airborne handling. Avoid a second flight controller and broad nearby-enemy detection/reveal. Landing, cleanup and restoration defects were corrected in this review. |
| Smart Aircraft AI (4 SQF) | Main controller command/ownership scan | Existing flares, break-away and airborne features cover selected actions. Do not import server-only global flight takeover, skill forcing, blanket AI enable or teleport ejection. |
| Better Static AI (2 SQE) | Embedded initialization, suppression/hit ducking, PATH handling | WMP garrisons already duck and watch sectors. Their handlers now have tracked IDs and cleanup, with a persistent original stance and ownership replay. No unconditional PATH restoration. |
| Isky AI Skill Tweaks | Config-only package | Addon configuration is not a mission-script mechanism. WMP AI Rebalance remains the skill authority; no invented source-level findings. |
| Realistic Computer Animation (2 SQE) | Supplied composition contents | No useful AI control mechanism found in the small supplied composition files. |

Extracted sources are review-only under `.qa/ai-reference-sources/`; they are not shipped with the
mission. Paths and filenames above identify the inspected mechanisms without redistributing the
upstream source. Licensing permission to copy an upstream implementation is not assumed.

## Changes prompted by the review

- Convoy registration is server-owned, driving is owner-local, and registry replay supports late
  headless clients. No convoy server pin, imported FSM, per-vehicle infinite loop or path broadcast.
- Artillery uses explicit binocular/radio spotters, a deliberately displaced opening aim, confirmed
  single rounds, flight-time plus warning intervals, and observed corrections. Loss of observation
  freezes the report and accuracy. Cross-owner batteries share one server mission record.
- The first HE aim is rejected within a configured player exclusion plus buffer. Candidate attempts
  are capped at eight; there is no continuous player safety monitor or projectile interception.
- Ownership epochs retire stale work. Changed restoration records and clear-building progress are
  public; the new owner restores and adopts the group. Feature pins record prior exclusions so
  releasing crews does not erase mission-maker WMP/ACE headless exclusions.
- Zeus order success waits for the current owner's result. Current UI payloads use named settings;
  the documented positional adapter remains for legacy callers.
- Regrouping protects medical/service tasks and rechecks capacity before joining. Garrison event
  handlers and delayed duck state are cleaned up across release, stop and ownership transitions.

## Acceptance boundary

These are source changes, not proof of live driving, safe impacts or headless handover. The full
runtime matrix is in [the PR review](pr151_review.md). In particular, an opening aim exclusion cannot
guarantee zero casualties from shell dispersion or players moving during flight. Unconfirmed engine
fire commands are quarantined rather than automatically retried. The PR stays draft until the
required dedicated-client and WMP/ACE headless checks have fresh RPT evidence.
