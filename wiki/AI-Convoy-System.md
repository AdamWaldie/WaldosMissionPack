# AI Convoy System

> **Use this page when:** you need to create, tune or stop an AI land-vehicle convoy.

_Associated Files: `MissionScripts/AiScripting/simpleAiConvoy.sqf`, `convoySync.sqf`, `convoyTick.sqf`, `convoyReleaseLocal.sqf`_

The convoy follows its lead vehicle's route with sampled path points, spacing-based speed control
and slower turns. It uses mission SQF and CBA; no addon or imported FSM is required. Registration
belongs to the server, while driving commands run on the current AI owner.

## Setup

Use a simulation-enabled group with 2–20 AI-driven land vehicles, then give the leader normal
waypoints. Static weapons, player crews and vehicles controlled by another WMP feature are rejected.
Call on the server; an authorised Zeus module or current headless owner can also request changes.

```sqf
[convoyGroup] call Waldo_fnc_SimpleAiConvoy; // 30 km/h, 15 m, push through
[convoyGroup, 25, 25, false] call Waldo_fnc_SimpleAiConvoy;
[convoyGroup, 0] call Waldo_fnc_SimpleAiConvoy; // stop and restore
```

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| Group | GROUP | required | The AI vehicle group. |
| Speed | NUMBER | 30 | Maximum km/h, clamped to 5–120. Zero or less stops the controller. |
| Separation | NUMBER | 15 | Target metres between vehicles, clamped to 10–100. |
| Push through | BOOL | true | Suppress group attack/unloading while travelling; otherwise release control during combat. |

Calling again updates the existing convoy. The function returns registration success, not a
long-running script handle. Existing `spawn` calls can dispatch registration, but terminating that
handle no longer stops the convoy. Replace old termination blocks with `[convoyGroup, 0] call
Waldo_fnc_SimpleAiConvoy` on the server. Multiple groups use the same API independently.

## Zeus controls

Place **WMP AI & Combat > Convoy - Create Moving Group** on an existing crewed AI land vehicle.
Choose configure or stop, speed, spacing and push-through from labelled controls. A missing or
invalid selection is rejected; the module never guesses a nearby vehicle. Feedback confirms
registration; the owner applies driving settings on its next worker step.

## Movement and recovery

Followers use the lead vehicle's sampled route instead of continually cutting straight across bends.
The leader slows for large gaps and turns. Follower speed uses gap and relative-speed correction,
including zero-gap and heading-wrap cases. A follower stalled for 20 seconds falls back to normal
formation following, with a ten-second path retry delay. Recovery does not teleport vehicles.

The controller preserves leader waypoints. It records formation, attack permission, forced speed
and combat unloading before changing them, then restores those values on stop. It releases driving
control for SafeStart/ENDEX, Zeus intervention and player crews. With push-through disabled, it also
releases during combat. A destroyed lead vehicle can be replaced by a surviving registered driver.

## Headless clients and performance

Convoys are not pinned to the server. An ordered registry replays to server/headless owners,
including late joiners. Ownership changes discard local driving state; the new owner reconstructs
the trail from the leader and uses formation following until useful samples exist. Prior restoration
values are public. Both WMP and ACE headless migration paths still require live acceptance testing.

One CBA worker per AI-owning machine considers one convoy every 0.25 seconds. Each convoy updates
at most once per second, so many convoys receive less frequent updates. Each holds at most 128 route
samples, sends at most ten path points per follower, and refreshes a follower path no more often than
every three seconds. Route samples stay local; registration changes send registry snapshots.

## Limitations and checks

This implementation has static regression coverage, but has not passed in-engine acceptance.
Test bends, junctions, mixed vehicle sizes, blocked roads, lead loss, repeated configuration/stop,
Zeus intervention, player entry and transfer between server and headless clients before live use.
Migration reconstructs the trail; it does not preserve the complete previous route history.
Engine driving and road geometry can still prevent progress. Push-through changes AI orders, not
vehicle invulnerability or the engine's ability to navigate a blocked route.

## See also

- [Headless Client Support](Headless-Client-Support)
- [Smart AI Pass](Smart-AI-Pass)
- [WMP Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
