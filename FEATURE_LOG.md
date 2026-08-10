# WMP Feature Log

This file records agreed future work which is not part of the current release. An entry being listed
here means it is planned for investigation and implementation; it does not mean the feature is
already available. Completed work should move into the relevant release notes and be removed from
this list.

## Target: 4.8.3

### ACRE2 radio racks and object radios

**Status:** Planned

Add a mission-maker setup method for radios mounted in vehicle racks or attached to world objects.
It should provide the same dependable initial presetting intent as player-carried radios, while
respecting ACRE2's separate rack ownership and mounted-radio lifecycle.

Required direction:

- support a clear object-init call for Eden-placed vehicles and objects;
- allow each installed rack radio to receive its own channel or frequency assignment;
- support named channels where the physical radio supports them;
- avoid changing player-carried radio state or continuously retuning a rack during play;
- work in hosted and dedicated multiplayer, including JIP and vehicle-locality changes;
- diagnose missing ACRE2, unsupported radio classes, invalid channels/frequencies and racks which
  have not yet produced their unique radio IDs;
- provide beginner-friendly inline documentation, examples and wiki coverage.

### Paradrop deployment-direction preview

**Status:** Planned

Upgrade the Paradrop Zeus workflow so the curator can preview the intended deployment direction on
the map before confirming placement. This should make the standby, green and red lines predictable
before the drop zone and aircraft route are created.

Required direction:

- show the proposed approach/deployment direction during placement rather than only after creation;
- clearly distinguish the standby line, jump/green line, red/end line and overall drop-zone area;
- allow the curator to rotate or revise the direction before confirmation;
- use the final previewed direction for markers, aircraft approach, drop path and any repeat circuit;
- cancel cleanly without leaving markers, handlers or partially registered operations;
- remain usable on dedicated servers, with preview UI local to the curator and creation authoritative
  on the server;
- document the workflow and cover it in the Paradrop audit station and Zeus/script parity checks.

### Headless-client compatibility rework

**Status:** Planned

Replace the old optional headless-client integration with a WMP-aware ownership and locality layer.
The rework must treat group transfer as a normal runtime state change: server-authoritative feature
state remains on the server, while AI, waypoint and vehicle commands execute wherever the affected
group or object is currently local.

Required direction:

- support one or more headless clients without requiring feature-specific mission-maker workarounds;
- migrate eligible AI groups deliberately and exclude player groups, curator helpers, temporary
  interaction actors and other WMP-owned control entities;
- reapply locality-sensitive AI, waypoint, vehicle, air-operations and transport handlers after a
  group changes owner, without duplicating event handlers or state machines;
- preserve server registries, public/JIP snapshots and cleanup ownership while the HC owns the live
  AI operation;
- recover cleanly if a headless client disconnects, including reassignment of groups and restoration
  of any owner-local behaviour;
- expose diagnostics for connected HCs, assigned groups, excluded groups, failed transfers,
  ownership mismatches and orphaned operations;
- test Dynamic AO, Dynamic AA, transports, gunships, paradrops and improved helicopter landing with
  no HC, one HC, multiple HCs, HC disconnect/reconnect and JIP players;
- replace the legacy third-party activation path only after the new implementation has passed hosted
  and dedicated-server acceptance, with beginner-friendly configuration and wiki documentation.

### Field Resupply: replace charge-based deployed crates with real crate contents

**Status:** Planned

Redesign deployed Field Resupply crates so they behave like a normal populated supply crate
(ACE Cargo/Gear access to real inventory) instead of the current limited-`TAKE`-count abstraction.
Today `Waldo_fnc_FieldResupplyServerHandle`'s `DEPLOY` derives a fixed set of logical magazine rows
from the deploying carrier's own inventory (`_getMagazineRows`, filtered by
`Waldo_FieldResupply_AllowedMagazines`/`BlockedMagazines`/`MinimumMagazineRounds`, sized by
`Waldo_FieldResupply_UseCapacityBasedAmounts`/`MagazinesPerType`/`CapacityAmounts`) and stores it as
`Waldo_FieldResupply_CargoRows` against a fixed `Waldo_FieldResupply_ChargesPerCrate`; the crate keeps
empty physical cargo on purpose so `TAKE` (`Waldo_fnc_FieldResupplyReceiveAmmo`) stays the only way to
draw from it and `SALVAGE` decides recoverability by comparing `Waldo_FieldResupply_Charges` against
`Waldo_FieldResupply_InitialCharges`. Replace that with real crate cargo populated the same way a
standard supply crate is (`Waldo_fnc_SupplyCratePopulate`, scoped to the hub's serviced side), so a
deployed crate can simply be deployed, opened, taken from and salvaged like any other logistics crate.

Required direction:

- populate a deployed crate's actual weapon/magazine/item cargo (via `Waldo_fnc_SupplyCratePopulate`
  or an equivalent field-resupply-scoped populate path) instead of building
  `Waldo_FieldResupply_CargoRows` from the carrier's own magazines;
- drop the per-crate charge count entirely — `TAKE` becomes normal ACE Cargo/Gear interaction against
  real inventory rather than a server-brokered logical grant gated on remaining charges;
- redefine `SALVAGE` recoverability from actual remaining cargo (e.g. cargo emptiness/weight) instead
  of the charges-vs-initial-charges comparison, since there is no charge counter left to compare;
- decide the fate of the now-obsolete config surface
  (`Waldo_FieldResupply_ChargesPerCrate`/`AllowedMagazines`/`BlockedMagazines`/
  `MinimumMagazineRounds`/`UseCapacityBasedAmounts`/`MagazinesPerType`/`CapacityAmounts`) —
  remove or fold into whatever options the reused populate path exposes (size scalar, side,
  weapons/attachments/launchers toggles, matching `Waldo_fnc_SupplyCratePopulate`'s own parameters);
- keep hub stock (`Waldo_FieldResupply_Stock`) and carrier portable-crate capacity
  (`Waldo_FieldResupply_MaxCrates`/`Crates`) exactly as they are — those govern how many crates a hub
  can issue and a carrier can carry, and are unrelated to this change;
- keep the existing ACE dragging/carrying setup on deployed crates, and confirm ACE Cargo/Gear
  interaction works correctly against the populated contents without the old `TAKE` action installed
  alongside it;
- update the Field Resupply ZEN modules, notifications, diagnostics coverage, wiki page section and
  the audit mission's Field Resupply station to match the new deploy/take/salvage behaviour.

### Boat transport services

**Status:** Planned

Extend WMP Transport Services with waterborne transports, using the same player-facing request,
destination and return-to-base language as the existing ground and air services without pretending
that road or helicopter routing rules apply to boats.

Required direction:

- register Eden-placed and Zeus-selected boats as named transport services, with automatically
  generated internal IDs and independently configurable operational side;
- provide specific-boat and all-available-water-transport requests through the existing Transport
  self-interaction structure;
- provide destination and return-to-base actions to occupants of the exact boat, with ACE actions
  preferred and documented vanilla fallbacks when ACE is unavailable;
- choose reachable water pickup/destination points, reject landlocked requests clearly and account
  for shoreline access without beaching or repeatedly colliding with the coast;
- reserve safe arrival spacing when several boats are requested together and prevent services from
  spawning, stopping or returning inside one another;
- preserve server-authoritative service state while executing movement commands wherever the boat
  and its AI crew are local, including dedicated-server, JIP and later headless-client handling;
- cover stuck, destroyed, abandoned, full-capacity and no-valid-water-route states, plus clean
  cancellation, reassignment and removal;
- integrate map markers, WMP notification targeting, diagnostics, compositions, the full audit
  mission and beginner-friendly configuration/wiki examples.
