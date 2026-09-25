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

### What you should edit

| Setting | Type | Default | What it controls |
|---|---|---:|---|
| `Waldo_HelicopterDeceleration_Enable` | Boolean | `false` | Master switch. Enable only after testing the mission's airframes. |
| `Waldo_HelicopterDeceleration_IncludeVTOL` | Boolean | `false` | Include VTOL aircraft; leave off unless their flight-mode transitions have been tested. |
| `Waldo_HelicopterDeceleration_MinimumSpeed` | Number (km/h) | `80` | Ignore slower aircraft. |
| `Waldo_HelicopterDeceleration_MinimumAltitude` | Number (metres AGL) | `25` | Never correct below this height. |
| `Waldo_HelicopterDeceleration_MinimumSpeedLoss` | Number (km/h per sample) | `4` | Braking threshold. |
| `Waldo_HelicopterDeceleration_MinimumAltitudeGain` | Number (metres per sample) | `0.5` | Unwanted climb threshold. |
| `Waldo_HelicopterDeceleration_MinimumNoseUp` | Number (vector direction Z) | `0.02` | Minimum nose-up attitude; zero is level. |
| `Waldo_HelicopterDeceleration_TerrainClearance` | Number (metres) | `25` | Required clearance over terrain ahead. |
| `Waldo_HelicopterDeceleration_MaximumCorrectionAcceleration` | Number (m/s²) | `2.5` | Downward acceleration cap. |
| `Waldo_HelicopterDeceleration_MaximumClimbRate` | Number (m/s) | `0.5` | Stop correcting when the climb falls to this rate. |
| `Waldo_HelicopterDeceleration_SampleInterval` | Number (seconds) | `0.5` | Cadence of the owner-local detection check. |
| `Waldo_HelicopterDeceleration_ControlInterval` | Number (seconds) | `0.02` | Cadence while a correction is active. |
| `Waldo_HelicopterDeceleration_MaximumCorrectionSeconds` | Number (seconds) | `4` | Hard duration limit for one correction. |
| `Waldo_HelicopterDeceleration_Debug` | Boolean | `false` | Log acquire/release reasons and owner IDs during diagnosis. |

The numeric rows are advanced safety thresholds. Leave them at their shipped values until a
repeatable test identifies a specific airframe problem. This feature has no mission-maker function
call: it starts from the flag, evaluates eligible AI aircraft on their current owner, and follows
locality changes. It does not replay a past correction to joining players.

## What success looks like

- The helicopter follows its existing waypoint route normally.
- Braking no longer produces a large unwanted climb.
- A landing waypoint still uses Improved Landing without interference.
- Low-altitude, player-piloted, remote-controlled and UAV aircraft are unchanged.
- Moving or deleting a landing waypoint releases landing control normally; the deceleration helper
  does not invent a replacement waypoint.

There is intentionally no composition: the feature reacts to ordinary AI helicopter flight and has
no object or station to place. Check it with a crewed AI helicopter on a representative route.

## Safety model

- correction runs only on the aircraft's current owner and follows locality migration;
- terrain clearance is checked beneath the aircraft and 100, 300 and 500 metres ahead;
- a mass-scaled acceleration cap and hard time limit bound every event;
- correction ends when climb settles, the nose drops, eligibility changes or terrain becomes unsafe;
- public aircraft variables expose active/last-result state for server diagnostics, not control;
- changing waypoints to a landing order immediately gives Improved Landing priority.

The helper cannot make a bad route safe or correct a damaged/unusual flight model. It is a narrow
fix for cruise braking behaviour, not a replacement autopilot.

## See also

- [Improved AI Helicopter Landings](Improved-AI-Helicopter-Landings)
- [Transport Services](Transport-Services)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
