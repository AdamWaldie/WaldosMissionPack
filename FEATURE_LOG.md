# WMP Feature Log

This file contains only agreed work which has not yet been implemented. Completed features and
accepted fixes belong in the feature catalogue, their specific wiki page and release notes.

## Target: 4.8.4

### Smart AI Pass - remaining behaviours

**Status:** Planned

The Smart AI Pass framework (scheduler, eligibility gate, AI Control wiring) and survivor regroup
are implemented. Each remaining behaviour gets its own `Waldo_AIPass_<Behaviour>_Enable` switch in
`MissionConfig\aiConfig.sqf`, runs through the pass scheduler, and uses `Waldo_fnc_AIPassIsEligible`.

Required direction, in build order:

- airborne reinforcement: a "detected by" trigger requests a Dynamic Paradrop drop;
- hold and garrison posture, with a Dynamic AO option; opt-in only, never on by default;
- clear-building order from Zeus or script, with position reservations and timeouts;
- artillery fire support on known enemy positions only, counter-battery from `ArtilleryShellFired`,
  and gating by radio jamming;
- gunship flares for registered WMP aircraft, only if in-engine testing shows AI pilots do not
  already release them;
- a full contact pass: group state ladder with hysteresis, post-contact security/search/regroup,
  multi-bound bounding and base-plus-manoeuvre flanking, street crossing, building assault, grenade
  evasion, fire distribution and morale;
- when LAMBS is loaded, split ownership per behaviour;
- verify in engine before enabling the dependent behaviours:
  - whether a leader ordering himself to move freezes his squad;
  - whether a group `move` order stops patrol waypoints from resuming;
  - `ProjectileCreated` locality;
  - `fireAtTarget` with flare launchers;
  - whether `disableAI "FSM"` affects LAMBS;
  - the locality of group `EnemyDetected`/`KnowsAboutChanged` events.

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
