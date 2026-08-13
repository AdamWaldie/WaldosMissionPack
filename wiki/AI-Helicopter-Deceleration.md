# AI Helicopter Deceleration

> **Use this page when:** AI helicopters climb sharply while slowing down during ordinary cruise flight.

Arma AI can trade forward speed for an unwanted zoom-climb while braking. This optional helper
detects that specific trend—speed falling, altitude rising and the nose pitching up—and applies a
short downward world-space impulse on the machine that currently owns the aircraft. It does not
replace waypoints, set velocity, change AI features or prescribe a route.

The feature is disabled by default. Enable `Waldo_HelicopterDeceleration_Enable` in
`MissionConfig\aiConfig.sqf` only after testing the helicopters used by the mission. Helicopters are
supported by default; VTOL aircraft require the separate `IncludeVTOL` opt-in. Player-piloted,
remote-controlled and UAV aircraft are never changed.

## Priority and compatibility

[Improved AI Helicopter Landings](Improved-AI-Helicopter-Landings) always wins. As soon as a LAND,
UNLOAD, TRANSPORT UNLOAD, GET OUT, scripted landing, or WMP transport-destination order is active,
the cruise helper stands down—even before Improved Landing enters its final control range. If the
landing controller becomes active during the same frame, correction releases before another
impulse. The landing system remains solely responsible for approach, flare, go-around and touchdown.

This separation is deliberate. Cruise detection has no knowledge of landing slope, canopy,
touchdown commitment or go-around state, so using its force calculation inside an approach would
make the two controllers fight rather than improve the landing.

## Beginner setup

1. Open `MissionConfig\aiConfig.sqf`.
2. Change `Waldo_HelicopterDeceleration_Enable` from `false` to `true`.
3. Leave the advanced values unchanged for the first test.
4. Fly representative AI helicopter routes containing acceleration, turns, braking and a supported
   landing waypoint. Confirm the RPT has no repeated correction or terrain-guard warnings.

No init call or ZEN module is required. To exclude one unusual airframe, put this in its Eden init:

```sqf
this setVariable ["Waldo_HelicopterDeceleration_Exclude", true, true];
```

## Safety model

- correction runs only on the aircraft's current owner and follows locality migration;
- terrain clearance is checked beneath the aircraft and 100, 300 and 500 metres ahead;
- a mass-scaled acceleration cap and hard time limit bound every event;
- correction ends when climb settles, the nose drops, eligibility changes or terrain becomes unsafe;
- public aircraft variables expose active/last-result state for server diagnostics, not control;
- changing waypoints to a landing order immediately gives Improved Landing priority.

The helper cannot make a bad route safe or correct a damaged/unusual flight model. It is a narrow
fix for cruise braking behaviour, not a replacement autopilot.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
