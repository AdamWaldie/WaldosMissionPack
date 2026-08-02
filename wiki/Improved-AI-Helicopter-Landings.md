# Improved AI Helicopter Landings

> **Use this page when:** AI helicopters need reliable exact-point landings, slope handling, canopy clearance and a controlled go-around.

The improved landing system applies only to AI-piloted helicopters. It recognises LAND, UNLOAD, TRANSPORT UNLOAD and GET OUT waypoints, including scripted landing waypoints whose waypoint script identifies a landing task. Arma represents Eden's Land waypoint as a `SCRIPTED` waypoint using `A3\functions_f\waypoints\fn_wpLand.sqf`; a literal engine waypoint type named `LAND` is invalid and is not used. It never modifies a player pilot's helicopter. A waypoint must be more than 50 metres from the helicopter when acquired; this deliberately avoids taking control of the frequently self-completing landing waypoint used during take-off.

During final approach, the owning machine applies a bounded terrain-following velocity and orientation solution. Horizontal speed reduces into a flare, upward and downward rates are capped, and the aircraft blends toward the landing surface normal near touchdown. Touchdown requires the aircraft to be inside the configured radius, at no more than 1 metre ATL and moving at no more than 2 m/s horizontally or 1.5 m/s vertically; this accommodates helicopter model contact offsets without accepting a fly-by. Nearby tree canopies raise the approach/hover height. If the helicopter reaches the final area far too high or genuinely overshoots after entering the final 80 metres, it opens distance and turns back for at most the configured number of go-arounds.

## Locality and lifecycle

The feature uses the same event-driven ownership model as WMP AI skill tuning:

- a CBA helicopter class-init handler catches editor, Zeus and scripted aircraft;
- a per-helicopter `Local` event adopts it after server, headless-client or client ownership migration;
- an active-control marker travels with the aircraft so a new owner restores inherited AI state before resuming or abandoning the approach;
- only the machine currently owning the helicopter applies flight vectors;
- player pilots and remotely controlled AI immediately cancel scripted control;
- loss of locality, deletion or editing of the active waypoint, engine/fuel/damage failure, sling loading, exclusion or live disable restores the AI movement and FSM state immediately. Automatic engine completion of an otherwise unchanged waypoint is tolerated only inside the final commit distance.

No server assumes permanent ownership, and no scan of every world object is required. Each locally owned AI helicopter has a small waypoint tracker because Arma provides no waypoint-changed event suitable for this controller; that tracker ends as soon as the aircraft dies or leaves the machine's locality.

## Configuration

The feature is enabled by default. Set `Waldo_ImprovedHelicopterLanding_Enable = false` before its guarded default in `init.sqf` to disable it.

Important global settings include:

| Setting | Default | Purpose |
|---|---:|---|
| `Waldo_ImprovedHelicopterLanding_MinimumActivationDistance` | `50` | Hard minimum range before takeover |
| `Waldo_ImprovedHelicopterLanding_TriggerDistance` | `500` | Base distance at which a valid approach may start |
| `Waldo_ImprovedHelicopterLanding_TransitAltitude` | `30` | Minimum terrain-relative approach height |
| `Waldo_ImprovedHelicopterLanding_GlideSlopeRatio` | `4` | Descent distance multiplier |
| `Waldo_ImprovedHelicopterLanding_TreeScanRadius` | `25` | Landing-zone canopy scan radius |
| `Waldo_ImprovedHelicopterLanding_TreeSafetyBuffer` | `5` | Clearance above the highest detected canopy |
| `Waldo_ImprovedHelicopterLanding_GoAroundHeight` | `150` | Excessive relative height near the landing point |
| `Waldo_ImprovedHelicopterLanding_MaximumGoArounds` | `1` | Bounded repeated approaches; `0` disables them |
| `Waldo_ImprovedHelicopterLanding_MaximumClimbRate` | `8` | Maximum scripted upward velocity in metres/second |
| `Waldo_ImprovedHelicopterLanding_MaximumDescentRate` | `10` | Maximum scripted downward velocity in metres/second |
| `Waldo_ImprovedHelicopterLanding_FinalCommitDistance` | `75` | Inside this range, premature vanilla LAND-waypoint completion no longer cancels the scripted flare and touchdown |

Set `Waldo_ImprovedHelicopterLanding_Exclude = true` on a helicopter to opt it out. For class-, role- or mission-specific tuning, store a HashMap in `Waldo_ImprovedHelicopterLanding_Profile`; keys use the global suffix without the `Waldo_ImprovedHelicopterLanding_` prefix.

```sqf
this setVariable ["Waldo_ImprovedHelicopterLanding_Profile", createHashMapFromArray [
    ["TransitAltitude", 45],
    ["MaximumClimbRate", 5],
    ["MaximumGoArounds", 2]
]];
```

**AI - Helicopter Landing Control** exposes the common live settings as bounded, plain-language ZEN controls. Curator changes are server-validated, sent to connected locality owners in one ordered payload and included in the normal JIP snapshot.

## Engine boundaries

The controller cannot make an obstructed landing point safe. Tree detection changes the flight profile; it does not remove vegetation. Rotor geometry, very steep terrain, damaged flight models and modded helicopters with unusual simulation can still prevent touchdown. Test critical airframes and landing zones, and use a normal MOVE waypoint near—but not immediately beside—the helicopter before a take-off-to-landing route.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
