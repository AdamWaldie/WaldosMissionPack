# PR 151 review and validation

Review baseline: PR head `1f88659d1553d2dfab2f664bf9a2fd75295971ce`, compared with current remote main `7bf85065fdab2050d874fbbf504c4b99c7885761` on 26 September 2026. The review used an isolated checkout. The original working directory and its audit changes were preserved.

The PR should remain a draft. The fixes below address confirmed source defects, but the headless-handover and feature-release contracts still need work. No Arma runtime result is claimed.

## Corrections made

- Corrected the Zeus waypoint-edit event payload and added waypoint selection/attribute coverage. Bohemia documents edited/placed events as curator, group and index; deleted/selected events carry a waypoint array.
- Applied the shared eligibility gate to garrison, defence and clear-building orders before side effects. Group-level feature markers now receive the same checks as unit and vehicle markers.
- Made repeated garrison/defence placement replace old assignments and invalidate older arrival jobs. Garrison release restores PATH only when this pass disabled it.
- Rechecked eligibility in running drills, coordinated assaults and delayed contact delivery. Live LAMBS mode changes now affect already managed groups, and the LAMBS restoration marker survives transfer between owners.
- Revalidated artillery role, feature switch, eligibility and friendly/civilian proximity at the actual dispersed aim point immediately before firing. Mounted occupants are included. Delayed counter-battery missions retain their responding side; delayed relocation also respects Zeus control.
- Made blocked backblast stop the current firing request after ordering the gunner to reposition. A later step must check clearance again.
- Cancelled pending startup on stop, cleared abandoned airborne work, removed tracked aircraft handlers and gated delayed flare bursts. Parachute exits restore the prior damage setting on the current unit owner.
- Required actual landing before assigning the post-drop ground attack. Waypoint completion now compares indices with currentWaypoint because completed waypoints remain in the engine list.
- Corrected the scheduler documentation: its budget is checked between jobs. A running job can exceed it, and queue traversal remains proportional to queue size.

## Merge blockers found by the review

1. **P1: transient restoration does not survive ownership changes.** `aiPassGroupTick.sqf` clears the managed flag on locality loss, and `aiPassFlankStep.sqf` retires immediately. The old machine retains the group state and drill restoration records. A new owner cannot reliably restore behaviour, stance, speed and disabled AI features from that data. Returning to a previous owner can reuse stale state. This needs an explicit ownership-transfer cleanup/replay contract, including an abrupt headless disconnect.
2. **P1: clear-building orders have no durable replay.** `aiPassClearBuilding.sqf` stores its flag and job locally. Discovery replays garrison and defence only. A transfer drops the clearing job; a return can encounter a stale clear flag. The generation check prevents replacement jobs fighting locally but does not solve transfer.
3. **P1: feature-crew release clears exclusions without provenance.** `aiPassReleaseFeatureCrew.sqf` clears WMP and ACE headless exclusions on groups and soldiers. It cannot distinguish a feature's own pin from a mission-maker exclusion that existed first. Release must restore recorded prior values or preserve exclusions it does not own.

The AI Orders feedback also reports successful dispatch as acceptance for remote groups. An owner can subsequently reject the order. Add an authoritative owner result before presenting a success notification.

## Resolution of the blockers

Each fix below has static regression coverage in `test_smart_ai_pass.py`. None has been run in the
engine.

1. **Transient restoration.**
   - `Waldo_fnc_AIPassPublishRestore` publishes one broadcast record, `Waldo_AIPass_Restore`:
     changed behaviour (with the "had contact" flag), changed speed, drill-disabled AI features and
     pass-set stances.
   - It is called at the end of each group step and flank step, and by `FlankEnd`, `RestoreCalm`
     and `ReleaseGroup`. It sends only when the content changes and clears the record once nothing
     is left to undo.
   - Discovery calls `Waldo_fnc_AIPassAdoptRestore` on a local group that has a record and no local
     state. It restores what the record names, clears "WMP AI PASS" waypoints and calls non-posted
     soldiers back to the leader, before garrison or defence re-apply.
   - The old owner drops its local state, published-record cache and clear-building flag when the
     group is no longer local. The drop happens in both the group tick and discovery, so a return
     starts clean.
   - An abrupt headless-client disconnect is covered the same way: the server adopts the record.
2. **Clear-building replay.**
   - The WMP clear publishes `Waldo_AIPass_ClearOrder` = [building, deadline, behaviour to restore],
     with the deadline on `serverTime` in multiplayer.
   - Discovery on the new owner resumes it with the `resume` option. The resume uses the original
     behaviour and the remaining time.
   - An expired or ineligible resume drops the order and restores behaviour.
   - Finishing, Zeus waypoints and ineligibility clear the published order. Stop keeps it for
     restart, like garrison and defence.
3. **Exclusion provenance.**
   - `Waldo_fnc_HeadlessPinCrew` records the prior values of `Waldo_ServerOwnedFeature`,
     `Waldo_Headless_ExcludeGroup` and `acex_headless_blacklist` on each group, and of
     `acex_headless_blacklist` on each soldier. The record is `Waldo_HeadlessPin_Prior`, written by
     the first pin only.
   - `Waldo_fnc_AIPassReleaseFeatureCrew` restores exactly those values and no longer writes `false`
     or touches soldiers' `Waldo_ServerOwnedFeature`.
   - A group without a pin record keeps whatever it has.
4. **AI Orders feedback.**
   - Garrison, defend, release, clear and airborne orders for a group owned by another machine are
     sent to that owner as `Waldo_fnc_AIPassOrderLocal`. The owner runs the order function locally
     and notifies the curator of its real result.
   - The server runs every other order itself through the same function.
   - If the group changes owner again before the order arrives, the order is refused and the
     curator is asked to place the module again.

## Verification

The full repository suite passed: **310 tests**, including **11 new static Smart AI regression tests**. These inspect source contracts and do not execute SQF.

All ten static gates passed: SQF, configuration, interaction UI, drawn UI, Zeus/script parity, wiki assets, wiki style, documentation contracts, skill validation and performance regression. The performance scanner reports 95 existing findings, including 10 high findings; it reports no new high-severity recurring patterns. The audit builder ran before the scanners. Git whitespace validation passed.

The initial test run lacked PyYAML. Installing it into the isolated checkout resolved the dependency errors. The regression tests also reject the original PR source; several absence checks surface as lookup errors on that version.

## Engine acceptance still required

After the blockers are fixed, use `launch_pr_review_audit.ps1` with its default 3840x2160 resolution and `-noBattlEye`. Verify mission entry and fresh RPT initialization markers. Exercise Zeus edits during drills and delayed fire; repeat, replace and release orders; stop/restart during an airborne drop; change battery roles and move friendly occupied vehicles into the aim area; test SafeStart/ENDEX; and transfer groups server to HC, back to server and through an HC disconnect. Repeat with LAMBS SPLIT and WMP modes, and with Paradrop, Transport Services, Gunship, Dynamic AA, Convoy and dialogue exclusions present.

Agent-driven Arma launch requires permission under AGENTS.md because it writes a mission into the installed game directory and opens the application. No game process was launched during this review.

Engine event reference: https://community.bistudio.com/wiki/Arma_3:_Event_Handlers#CuratorWaypointEdited
