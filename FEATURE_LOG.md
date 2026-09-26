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
- artillery, counter-battery and artillery smoke end to end;
- airborne insertion from an AI helicopter and an AI plane: climb, drop distance, one jumper at a
  time clear of the airframe, parachute opens, backpack kept, SAD after landing; an unload waypoint
  lands instead; the AI Orders "parachute out now" order;
- landed Paradrop AI jumpers and the dismounted crew of a written-off transport are taken over;
- AI Tuning module: opens on the live values, a change reaches a headless client (and a headless
  client that joins afterwards), and aggression, cohesion and reaction speed visibly change squads;
- artillery roles: a support-only gun ignores enemy artillery, a counter-battery-only gun ignores
  squads' calls, and no counter-battery lands near friendlies;
- airborne passengers in FFV seats jump too; a helicopter with an unload waypoint still ahead lands;
- final assault, bounding advance, investigation, defence line reserve and coordinated assault;
- Zeus priority on a dedicated server: selection, waypoints, target designation, remote control and
  ZEN AI actions each release the squad, and AI Orders exclude/return work;
- aircraft break-away on each airframe before recommending it;
- grenades (flank smoke, retreat smoke, assault frag) leave towards the target after the thrower is
  turned, and no chemlight or ACE flashbang is thrown as smoke;
- `IncomingMissile` fires on the aircraft owner's machine and `ArtilleryShellFired` reaches the
  machine that owns the answering battery (counter-battery across server and headless client);
- AI with vanilla, TFAR and ACRE2 radios pass the radio check (contact reports, reinforcement,
  artillery), and a radio-less soldier does not;
- flanking elements engage on the final approach and assault, and cover spots face away from the
  enemy rather than all being accepted;
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

## PR 151 review follow-up (2026-09-26)

Smart AI source corrections and outstanding runtime acceptance are recorded in [the PR 151 review](releaseVerificationAndDeployment/pr151_review.md) and [source review](releaseVerificationAndDeployment/pr151_ai_source_review.md). The PR remains draft. Add live coverage for opening ranging exclusion, explicit spotter loss/recovery and jamming, cross-owner shot accounting, ownership restoration, clear-building replay, pin provenance, owner-confirmed Zeus results, and convoy route/recovery/stop behaviour under WMP and ACE headless migration. Static results do not satisfy these checks.
