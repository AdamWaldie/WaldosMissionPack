# PR 152 integration review

The submitted changes address dedicated-server logistics registration, physical cargo, deleted-state replay on join, transport menu visibility and themed buttons. Source review found additional faults in cargo recovery and feature coexistence. The corrections are included in this branch. In-engine acceptance remains pending.

## ACE vehicle service roles

ZEN **WMP Logistics > ACE Vehicle Services - Configure** now uses the same `Waldo_fnc_VehicleServicesConfigure` API available in Eden Init. Ammunition supply, fuel supply, repair and medical status are independent roles. Omitted script keys and Keep current dialog choices preserve the selected vehicle's other services. Explicit refill controls replace stock only when requested. The API accepts live land vehicles, aircraft and boats and preserves inventory, simulation and movement.

Server-side validation covers named payload types, stock ranges, required ACE components and supported rearm modes. Active fuel nozzles block disable/refill operations. A per-vehicle queue waits for ACE settings and drains requests in order outside the remote-call context. ACE owns action replay and gameplay. Re-enabling ammunition supply replays deduplicated action setup for clients that joined while the role was disabled. WMP's automatic medical setup respects existing explicit true/false choices.

The live `qa_transfer_vehicle` HEMTT has all four roles, 1500 ammunition points and 2000 litres of service fuel. This prepares a real test vehicle and does not count as a live pass. The new ACE Vehicle Services wiki guide contains setup examples, keys, limits and the required dedicated-server checks.

## Corrections

The cargo acknowledgement worker now starts through CBA's next-frame queue. Its calls to the server-only unmount API therefore leave the original remote request context. The cargo owner publishes the applied revision after setting the approved pose. A provisional attachment alone is not accepted as acknowledgement. A mount revision prevents an older worker from recovering a later mount of the same object.

Rejected cargo uses the existing owner-placement acknowledgement before its saved mass returns. If the ground search fails, the attachment keeps its near-zero mass and the player is told to recover it with ACE Carry. Failed mount acknowledgement no longer falls back to restoring physics inside the vehicle. Pickup copies saved mass to ACE locally before a fast ground drop can beat the server response. Starter crates remain excluded, and both server registration and the Zeus eligibility handler reject people.

Jammer interaction replay has a dedicated named JIP entry bound through the shared networking helpers. Removing a jammer no longer clears another feature's object-keyed replay. The delayed Zeus retry checks that the jammer remains registered. Existing Disable Jammer and optional inactive-field Activate Jammer controls are retained.

Prompt fitting saves each button's layout-constrained font height before shrinking its text for the initial theme. Later theme changes can restore that baseline.

## Validation

The full Python suite passes: 320 tests. SQF validation passes for 1,145 files; configuration validation passes for 15 files. Wiki structure passes for 108 pages, Zeus/script parity passes for 77 modules, and documentation contracts pass for 13 files. The performance audit reports 95 existing findings, including 10 high-severity findings, with no new high-severity recurring patterns. These are static checks, including source-contract assertions, and do not establish Arma runtime behaviour.

ACE 3.21.2 source was checked directly for startCarryLocal and dropObject_carry. It confirms the saved-mass variable and the global mass-restoration event. The engine's object-keyed JIP slot is shared, so independent features need named entries. Init replay suppression remains a startup-phase heuristic: it also suppresses custom local client calls made before that phase ends. Custom server setup belongs in initServer.sqf; later client calls retain forwarding.

## Dedicated-server acceptance

Use launch_pr_review_audit.ps1 with Suite all, Mode Manual, -noBattlEye and the default 3840x2160 resolution. Rebuild from this checkout. Enter the playable mission slot, confirm VR mission initialization in fresh client/server RPTs, and use a second client for JIP checks. An opened lobby is insufficient.

- Issue every Quartermaster role, deploy Field Resupply, buy an Economy crate, spawn a resource crate, and exercise ZEN crate, loadout-save and runtime setup. Confirm exact classes, carryability, cargo size and server registration.
- Run ZEN Base Services, Supply Transfers and Physical Cargo on supported objects. Inspect server applied=true records. Verify people, vehicles, static weapons and starter crates retain their intended restrictions.
- Mount and recover heavy crates, wheels, tracks and fuel stores on actual simulation-enabled vehicles. Test repeated pickup, immediate ground drop, remount, moving-vehicle rejection, blocked ground, cargo-owner migration, ACE internal loading, vehicle destruction and deletion. Check mass restoration and seat locks.
- Remove an Eden marker, tracker and jammer; complete an objective and consume a one-shot notification. Join again and verify that removed state stays absent. Keep the jammer object and also give it another WMP feature; that feature must remain available after jammer removal. Remove a newly placed jammer before the delayed retry.
- Verify transport menus with no fleet, then register and remove each transport type. Check the documented vanilla fallback separately.
- Open Conversation Author under WW2, NAVAL, SCIFI and PARCHMENT. Switch back to a narrow-font theme and inspect button sizes. Capture real windows across 4:3, 16:10, 16:9 and ultrawide layouts, following the interaction QA instructions where applicable.

Do not merge on static results alone. No Arma launch or live physics, JIP, locality or visual test has been performed for this review.
