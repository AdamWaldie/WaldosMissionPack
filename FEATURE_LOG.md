# WMP Feature Log

This file contains only agreed work which has not yet been implemented. Completed features and
accepted fixes belong in the feature catalogue, their specific wiki page and release notes.

## Target: 4.8.4

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
