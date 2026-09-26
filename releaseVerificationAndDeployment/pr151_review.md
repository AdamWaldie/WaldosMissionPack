# PR 151 review and validation

PR 151 remains draft pending in-engine acceptance. The review began at `1f88659` against main
`7bf8506`, using an isolated worktree and preserving the original dirty checkout. Review commit
`030b211` corrected the initial defects. This follow-up implements the requested artillery and
convoy changes and addresses the source-level integration blockers. It also reviews the newer
remote `036942e` blocker fixes and reconciles their intent with the expanded implementation.

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
- **Convoy:** server registration replaces a server-pinned infinite controller. Owner-local workers
  follow a sampled leader route, damp spacing speed, slow turns and use bounded stuck recovery.
  Stop restores recorded formation, attack, forced speed and unloading. No FSM, teleport or repeated
  trail broadcast. Use `[convoyGroup, 0] call Waldo_fnc_SimpleAiConvoy` to stop; terminating the old
  spawn handle no longer stops the shared worker.
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
suite passed **321 tests**, including **21 Smart AI contract tests**. All ten static gates passed:
SQF (1,225 files), configuration, interaction UI, drawn UI, Zeus/script parity (81 modules), wiki
assets/style, documentation contracts, skill validation and performance regression. The performance
scanner reports 95 findings (10 high, 85 medium), with no new high recurring patterns. Wiki checks
initially caught a document encoding error; it was corrected and both checks then passed.
The audit builder ran before scanners. Git whitespace validation passed. These checks inspect source/tooling contracts, not AI mechanics.

## Remaining merge blockers: engine acceptance

No Arma session was launched in this follow-up. Source fixes do not establish correct live behaviour.
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
permission.” That permission request remains pending. Static work proceeds independently.

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
