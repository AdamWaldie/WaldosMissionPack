# WMP Feature Log

This file contains only agreed work which has not yet been implemented. Completed features and
accepted fixes belong in the feature catalogue, their specific wiki page and release notes.

## Target: 4.8.4

### Smart AI Pass - in-engine verification

**Status:** Planned

Every Smart AI Pass behaviour is implemented but has not run in the engine. Run the full audit mission
with CBA, ACE, ZEN and ACRE2 (and once more with LAMBS Danger and Waypoints) and confirm:

- contact, flank drills, street crossing, post-contact search and regroup on a dedicated server and
  after an ACE Headless / WMP Headless handover;
- inserted "WMP AI PASS" waypoints resume patrol waypoints afterwards;
- `ProjectileCreated` is raised where AI are local before grenade evasion is recommended;
- AI pilots' own flare use, before aircraft flares are recommended;
- artillery, counter-battery and airborne drops end to end;
- zero SQF errors in server, client and headless-client RPTs.

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
