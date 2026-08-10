<!--
Draft GitHub Release body for v4.8.2. Copy the section below the divider into the
GitHub "Releases" editor when the v4.8.2 tag is cut (after description.ext's
onLoadName is bumped and Pictures/loading.jpg has regenerated on main).
This file is a staging draft, not a shipped/packaged part of the mission pack.
-->

---

# Waldos Mission Pack v4.8.2

![alt text](https://github.com/AdamWaldie/WaldosMissionPack/blob/main/Pictures/loading.jpg?raw=true)

Waldos Mission Pack v4.8.2 is a stability and hardening release. v4.8.1 shipped a lot of new ground — the ACRE2 rewrite and eleven new systems — and this release is the full-pack audit pass that follows it up: every known issue called out in v4.8.1 is fixed, paradrop finally gets a flight route mission makers can trust, and Transport Services, Dynamic AA, Dynamic AO and Hazardous Environments have all been through a dedicated-server/listen-host locality audit to close races that only showed up under real multiplayer conditions.

## What's Changed

### Every v4.8.1 known issue is resolved

- **Hazards Module** — fixed the registration race against `init.sqf`'s SHARED config (a hazard zone placed via a composition's init field could silently register nothing), a stuck zone left behind when a moving emitter's anchor object was deleted, a grace-clock pruning loop that mutated a HashMap while iterating it, and decoupled the status panel's visibility from exposure decay so it stops flickering. The panel now aggregates instead of listing every zone by name, and Hazardous Environments' enable/zone/start state ships as one ordered server snapshot so JIP clients evaluate it correctly instead of racing multiple separate broadcasts.
- **Vehicle Recovery crash** — root-caused: `getVariable`'s no-default form silently dropped `nil` custom-variable entries out of an array literal, corrupting the packaged `[name, value]` pairs on practically any vehicle that had never been registered as a transport service. Fixed at the source and hardened on both restore paths (Recovery and Persistence) so a malformed entry is skipped, not a crash.
- **HALO/HAHO paradrop positioning** — the real fix: a new shared `Waldo_fnc_ParadropBuildFlightRoute` (standby → green → red → exit) now backs both the one-line `Waldo_fnc_ParadropQuickFlightSetup` for a mission maker's own placed plane and the existing ZEN Dynamic Drop Zone system, clearing conflicting Eden waypoints automatically and normalizing the jump envelope against the same clamped altitude/speed the route actually flies — no more jump actions gated on thresholds the plane's own route could never satisfy.
- **Claude Mission Config Skill upload** — fixed the over-length/malformed frontmatter description that failed claude.ai's uploader silently, added `claude_skill_validator.py` to CI so this class of bug fails a PR instead of failing at upload time, and shipped the actual zip shape claude.ai's "Upload skill" dialog needs (skill folder at the zip root, not the mission-project `.claude/skills/...` prefix). Also fixed a Windows-only bug where zip arcnames used backslashes, collapsing every folder in the archive.
- **Field hospital indicator** — the floating, badly-offset "FIELD HOSPITAL" 3D marker is gone. Field Hospital crates now get a proper ACE Interact ("Field Hospital Info") plus linked vanilla `addAction`, reporting the crate's ACE medical treatment bonus on demand instead of cluttering the sky.
- **Air LZ search radius** — Transport Services' default landing search radius is now 500m (clearance scale 1.5), not the old 75m.
- **Transport mid-landing move / no cancel** — fixed the actual dispatch and landing races underneath this (see Transport Services below), and Set Destination can now be issued again after a transport is already en route, the same way Move Pickup Point already worked — a genuine cancel-and-redirect instead of being stuck once dispatched.

### Paradrop reliability

- Added `Waldo_fnc_ParadropBuildFlightRoute` and `Waldo_fnc_ParadropNormalizeJumpEnvelope`, the reusable route/envelope logic now shared by quick setup and Dynamic Drop Zones (see above).
- Widened jump-envelope buffers to absorb AI autopilot wander, fixed LOOP restarts flying to map origin (0,0) instead of standby, fixed marker leaks, and fixed drop-zone marker overlap/decluttering.
- A missing or misnamed drop-zone marker now reports a clear in-game error instead of failing silently.
- Added a live-updating aircraft marker for drop zones (mirroring the gunship marker), and `Waldo_fnc_ParadropQuickFlightSetup` now honors the target marker's rotation and swaps it for a real DZ marker.
- Paradrop example compositions are wired to the reliable quick setup and ship their own drop-zone markers out of the box.

### Transport Services hardening

- Fixed a real dispatch race: a directly-targeted `remoteExecCall` and its companion broadcast `setVariable` have no ordering guarantee, so a brand-new dispatch could arrive and look "stale" and get silently dropped, leaving the aircraft with no waypoint. Now retries briefly before giving up.
- Fixed a matching landing-side race in the improved-landing/transport handoff that could leave the AI refusing to land.
- Occupant transport controls (Set Destination, RTB, stuck-route recovery) now live in the vehicle's own ACE self-interaction tree, not the external interaction — occupants previously could see status only and couldn't reach these actions from inside their own aircraft.
- Automatic RTB now correctly checks every crew/turret/FFV/cargo seat via `fullCrew`, requires the transport to be grounded/slow and human-empty first, and `destinationDwell` can no longer authorize departure with a player still aboard.
- Ground transport now falls back off-road when a stalled route is obstructed; helicopters no longer idle their engine mid-wait during pickup/boarding/destination dwell; combat-ineffective transports are written off and their crew locked in.
- Fixed the improved helicopter landing controller hovering forever in confined LZs.

### Dynamic AA hardening

- Fixed the actual placement-rejection bug: added `Waldo_DynamicAA_MaxSlopeDegrees` so a steep-terrain candidate is rejected the same way a tree or building is, instead of over-rejecting placement on genuinely open terrain.
- Fixed the live radar-loss crash where an `exitWith` escaped the radar-filter assignment and left a "destroyed" zone still able to engage; radar loss is now synchronous and authoritative.
- Detection and engagement are now enforced as five independent gates (hostile crewed aircraft, horizontal detection radius, ATL/ASL altitude floor/ceiling, horizontal engagement radius, live radar authority), with `AUTOCOMBAT` disabled alongside `AUTOTARGET` so crews can't independently engage anything outside their assigned list.
- Fixed dedicated-server crew/group side verification and AI-group locality ownership so ZEN-created AA no longer inherits the curator client's remote-execution identity.
- Added a human-readable system/marker name independent of the internal registry ID, and separated map markers from a default-on "Show range and altitude limits" toggle.

### Dynamic AO

- Restored real patrol movement (was placeholder waypoints) without breaking Arma's waypoint-zero state.
- Fixed the shipped `Dynamic AO Example Minimal` composition, which silently did nothing because its init call omitted the one required `faction` key.
- Defaults AO map markers off for Zeus-created AOs and tracks every spawned unit/vehicle/group/anchor consistently for dedicated-server curator visibility.

### Gunship Support

- Added `Waldo_fnc_GunshipAssignControllerOnStart` — a real handler for assigning a FAC/JTAC from a placed unit's own init field, waiting (bounded) for the aircraft's own registration to finish first.
- Fixed a bug where an Eden-placed aircraft that already had a pilot skipped turret crewing entirely, leaving gunner seats empty; turret discovery now uses `allTurrets`.
- Status (including "no controller assigned") is now visible to any friendly player, not hidden entirely without a controller; the orbit marker no longer draws a second circle over the mission maker's own marker.
- Added a `Gunship Support Example` composition demonstrating controller assignment.

### UI, notifications and themes

- Added the **PARCHMENT** (fantasy/olden-times) UI visual theme and a **MINIMAL** notification theme (semi-transparent, low-profile cards).
- Fixed the HIGH_CONTRAST accessibility profile on light-background themes, and fixed accessibility settings overriding theme stylistics.
- Redesigned the ZEN "Mission Flow: Send Notification" recipient picker as one native OWNERS picker (Sides/Groups/Players tabs, live multi-select) instead of a typed callsign field, and fixed a real in-game parse error in that module.
- MHQ deploy/teardown notifications now go to the acting player only, not the whole side.
- Added `Waldo_fnc_SendNotification`, a beginner-friendly scripted notification API with validated recipient/state/placement/duration inputs.

### Eden compositions

- Added `Gunship Support Example`, `Dynamic AA Example` and `Dynamic AO Example` compositions.
- Split the remaining compositions into Minimal/Full variant pairs, added per-procedure interaction-outcome compositions, and added a Persistence Object Example composition.
- Fixed composition unit sides showing Empty/Unknown and opened the transport driver seat to players.

### Mission Diagnostics

- Added a dedicated Paradrop diagnostics section (HALO altitude threshold validity, auto-detected jump-capable aircraft counts, Dynamic Drop Zone registry/JIP parity) and Field Hospital coverage.
- Diagnostic findings can now carry a short plain-language remediation hint alongside the existing detail text.

### Documentation

- Began a beginner-focused pass across the wiki's optional-feature pages (quick-setup steps and parameter tables for Persistence, patient treatment feedback, Hazardous Environments, Emergency Dismount, Object Scaling, Field Resupply and Tactical Display).
- Documented `Waldo_fnc_PersistenceRegisterObject`'s full calling contract, transport RTB safety settings, and synced the Claude Mission Config Skill's reference files with everything above.

### Dedicated-server / listen-host locality audit

A full-pack audit branch closed out a batch of related dedicated-server and locality defects across the systems above: Dynamic AA and Dynamic AO group/crew locality ownership, hazardous-environment JIP snapshot ordering, and the gunship/field-resupply/ZEN-toggle listen-host targeting bugs where state changes could be applied against the wrong machine.

## Upgrade Notes

- **Field Resupply is now enabled by default** (`Waldo_FieldResupply_Enable = true` in `MissionConfig\logisticsConfig.sqf`) — set it to `false` if your mission doesn't use it.
- **Transport occupant controls moved.** Set Destination, RTB and stuck-route recovery now live in the vehicle's own ACE self-interaction tree, not the external interaction menu — update any custom documentation/training material accordingly.
- **Economy Zeus category renamed** from `Waldos Economy Systems` to `WMP Economy Systems` in the Zeus module list.
- **`WALDO_STATIC_STATICCHUTE` now defaults to vanilla** `NonSteerable_Parachute_F` instead of the RHS-dependent `rhs_d6_Parachute` — missions running RHS should set this explicitly in `MissionConfig\airOperationsConfig.sqf` if they were relying on the old default.
- If you hand-wired paradrop aircraft with your own Eden waypoints, switch to `Waldo_fnc_ParadropQuickFlightSetup` — it now clears existing waypoints on the aircraft's group before flying its own route, so leftover Eden waypoints will be removed on first use.

## Known Issues

- ACRE2 vehicle/object radio rack presetting and a Paradrop deployment-direction preview are tracked for a future release; neither is in this one.

**Full Changelog**: https://github.com/AdamWaldie/WaldosMissionPack/compare/v4.8.1...v4.8.2
