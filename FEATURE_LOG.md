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
