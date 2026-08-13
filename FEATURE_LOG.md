# WMP Feature Log

This file records agreed work which is either still planned or implemented but awaiting a stated
acceptance test. Read each **Status** line: **Planned** means it is not implemented;
**Implemented, pending acceptance** means the code and documentation exist but the listed live Arma
test must still pass. Fully accepted work is removed from this file and documented in the feature
catalogue and its feature-specific wiki page.

## Target: 4.8.3

### Paradrop deployment-direction preview

**Status:** Planned

Upgrade the Paradrop Zeus workflow so the curator can preview the intended deployment direction on
the map before confirming placement.

Required direction:

- show the proposed approach direction, standby line, green/jump line, red/end line and complete
  drop-zone area before creation;
- let the curator rotate or revise the direction before confirmation;
- use the confirmed direction for markers, aircraft approach, drop path and repeat circuit;
- cancel without leaving markers, handlers or a partly registered operation;
- keep preview UI local to the curator and final creation server-authoritative;
- document and test the workflow in the Paradrop audit station and Zeus/script parity checks.

### AI helicopter deceleration without zoom-climbing

**Status:** Planned; viable, but it must complement rather than duplicate improved landing

Add an optional owner-local flight stabiliser for AI-piloted helicopters and VTOLs which are
decelerating in normal flight. Its purpose is to suppress Arma's excessive upward climb while the AI
slows down; it is not another landing controller.

Required direction:

- detect the narrow state of a local, living, engine-on AI aircraft which is slowing, pitching up
  and gaining height above a safe terrain-clearance floor;
- apply only a bounded vertical correction and release immediately when the aircraft descends,
  levels out, finishes decelerating, loses locality or enters an unsafe terrain envelope;
- never run while WMP Improved Helicopter Landing is active, during its go-around, touchdown or
  ground-hold phases, or while a player/remote controller is flying;
- support helicopters by default and make VTOL support separately configurable;
- install and remove owner-local handlers on locality changes, including server and HC ownership,
  without a global every-frame scan of all aircraft;
- expose an enable switch, conservative advanced tuning, per-aircraft opt-out and diagnostics;
- test normal waypoints, grouped flight, transport cruise, landing acquisition, go-arounds, terrain
  ahead, HC transfer and manual/Zeus remote control before enabling it by default.

### Headless-client compatibility rework

**Status:** Implemented, pending live headless-client acceptance testing

Native headless-client support is implemented under `MissionScripts\Headless\`. When ACE Headless is
loaded it remains the sole automatic group distributor; WMP observes completed transfers and
reapplies owner-local AI behaviour. Without ACE Headless, WMP can distribute eligible groups itself.
Server-owned feature registries and control entities remain on the server. Registration retries,
authenticated transfer acknowledgement, disconnect recovery and diagnostics are implemented.

Acceptance still required:

- test ordinary AI, Dynamic AO, transports and improved helicopter landing with no HC, one HC,
  multiple HCs, HC disconnect/reconnect and JIP players;
- confirm Dynamic AA, gunship and paradrop authority/control entities remain server-owned;
- confirm Zeus can still raise and move ordinary objects and WMP never migrates curator helpers;
- confirm transferred groups receive the configured AI profile and stay responsive after transfer
  and after an HC disconnect.

### Field Resupply real-cargo crates

**Status:** Implemented, pending in-engine ACE Cargo/Gear and salvage acceptance testing

Deployed crates now use `Waldo_fnc_SupplyCratePopulate`, contain real side-scoped cargo, expose
ordinary ACE Cargo/Gear access and use actual remaining contents to decide whether salvage is
allowed. The obsolete charge and brokered `TAKE` model has been removed while finite hub stock and
carrier crate capacity remain independent controls. ZEN, notifications, diagnostics, configuration,
wiki coverage and the audit station have been updated.

Acceptance still required:

- confirm a deployed crate opens through ACE Cargo/Gear and contains the intended side-scoped cargo;
- remove some cargo and confirm salvage is rejected, then empty the crate and confirm salvage returns
  one portable crate to the correct carrier without duplicating inventory;
- repeat deploy, use and salvage on a dedicated server and with a JIP player.

### Boat transport services

**Status:** Implemented, pending in-engine acceptance testing against real boat classes and coastal terrain

Boat services are implemented as their own typed pool with Eden/script and ZEN registration,
specific/all-available requests, occupant controls, open-water validation, spacing, markers,
notifications, diagnostics, configuration and wiki coverage. They reuse the transport lifecycle but
do not use road or helicopter landing rules.

Acceptance still required:

- verify pickup, destination, occupant RTB and bulk request flows with small and large vanilla boats;
- verify shoreline rejection, open-water adjustment, safe multi-boat spacing and stuck recovery;
- repeat on hosted and dedicated multiplayer, including JIP and a boat whose AI group moves to an HC.
