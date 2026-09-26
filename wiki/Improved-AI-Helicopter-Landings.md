# Improved AI Helicopter Landings

> **Use this page when:** AI helicopters need reliable exact-point landings, slope handling, canopy clearance and a controlled go-around.

Vanilla AI helicopters often land poorly on their own: overshooting the marked point, bouncing on a slope, or clipping a tree canopy on the way down. This system takes over final approach for an AI-piloted helicopter given a landing-type waypoint, and lands it precisely at the intended point instead.

## Start with a landing waypoint

Place an AI-piloted helicopter and give it a MOVE waypoint followed by an Eden Land, UNLOAD, TRANSPORT UNLOAD or GET OUT waypoint. Preview the route with an open landing area. The feature is on by default and needs no object Init call or ZEN module. Adjust `MissionConfig/aiConfig.sqf` only when the default flight profile does not suit your aircraft or landing zone.

The improved landing system applies only to AI-piloted helicopters. It recognises LAND, UNLOAD, TRANSPORT UNLOAD and GET OUT waypoints, including scripted landing waypoints whose waypoint script identifies a landing task. Arma represents Eden's Land waypoint as a `SCRIPTED` waypoint using `A3\functions_f\waypoints\fn_wpLand.sqf`; a literal engine waypoint type named `LAND` is invalid and is not used. It never modifies a player pilot's helicopter. A waypoint must be more than 50 metres from the helicopter when acquired; this deliberately avoids taking control of the frequently self-completing landing waypoint used during take-off.

During final approach, the owning machine applies a bounded terrain-following velocity and orientation solution. On short legs, vanilla AI retains departure control until the helicopter has reached the configured minimum approach speed or entered the real descent envelope; the scripted controller therefore cannot turn a low-speed lift-off into the pace for the entire trip. Horizontal speed then reduces into a flare, upward and downward rates are capped, and the aircraft blends toward the landing surface normal near touchdown. Touchdown requires the aircraft to be inside the configured radius, at no more than 1 metre ATL and moving at no more than 2 m/s horizontally or 1.5 m/s vertically; this accommodates helicopter model contact offsets without accepting a fly-by. Nearby tree canopies raise the approach/hover height. If the helicopter reaches the final area far too high or genuinely overshoots after entering the final 80 metres, it opens distance and turns back for at most the configured number of go-arounds.

After touchdown, the owning machine keeps AI movement and pilot FSM control constrained and applies a light ground anchor. This prevents vanilla completion of a final LAND waypoint from making the helicopter immediately take off again. A configurable touchdown settling time delays only genuine onward movement. Moving, deleting, retyping or replacing the landing waypoint releases the anchor immediately; so do locality migration, player/Zeus pilot takeover, system disablement and loss of a usable AI pilot. If the landing waypoint completes with no onward order, the helicopter remains grounded.

## Locality and lifecycle

The feature uses the same event-driven ownership model as WMP AI skill tuning:

- a CBA helicopter class-init handler catches editor, Zeus and scripted aircraft;
- a per-helicopter `Local` event adopts it after server, headless-client or client ownership migration;
- an active-control marker travels with the aircraft so a new owner restores inherited AI state before resuming or abandoning the approach;
- only the machine currently owning the helicopter applies flight vectors;
- player pilots and remotely controlled AI immediately cancel scripted control;
- loss of locality, deletion or editing of the active waypoint, engine/fuel/damage failure, sling loading, exclusion or live disable restores the AI movement and FSM state immediately. Automatic engine completion of an otherwise unchanged waypoint is tolerated only inside the final commit distance.

No server assumes permanent ownership, and no scan of every world object is required. Each locally owned AI helicopter has a small waypoint tracker because Arma provides no waypoint-changed event suitable for this controller; that tracker ends as soon as the aircraft dies or leaves the machine's locality.

Improved Landing has unconditional priority over the optional [AI Helicopter Deceleration](AI-Helicopter-Deceleration) helper. A supported landing order reserves the aircraft before approach takeover, and an active landing controller forces any cruise correction to release before its next impulse.

## Configuration

The feature is on by default. To disable it, change the `Waldo_ImprovedHelicopterLanding_Enable` row to `false` in `MissionConfig/aiConfig.sqf`. Keep the shipped init files; they load the setting and install the locality-aware controller.

These are the current rows in `MissionConfig/aiConfig.sqf`. Start with the first setup above; the timing and velocity settings are for tuning a tested airframe.

| Setting (`Waldo_ImprovedHelicopterLanding_` prefix) | Type | Shipped default | Purpose |
|---|---:|---:|---|
| `Enable` | Boolean | `true` | Watch eligible AI landing waypoints. |
| `MinimumActivationDistance` | Number, metres | `50` | Waypoint must begin at least this far away. |
| `TriggerDistance` | Number, metres | `500` | Distance at which a valid approach may start. |
| `TriggerSpeedFactor` | Number, multiplier | `4.2` | Scales the speed-based approach trigger. |
| `MinimumApproachSpeed` | Number, km/h | `55` | Minimum speed for takeover outside the close descent envelope. |
| `TransitAltitude` | Number, metres above terrain | `30` | Clear-terrain approach height. |
| `GlideSlopeRatio` | Number, horizontal-to-vertical ratio | `4` | Descent distance multiplier. |
| `TreeScanRadius` | Number, metres | `25` | Canopy search radius around touchdown. |
| `TreeSafetyBuffer` | Number, metres | `5` | Extra clearance above detected canopy. |
| `MaximumTreeHoverHeight` | Number, metres | `40` | Ceiling for canopy correction. |
| `GoAroundTriggerDistance` | Number, metres | `200` | Assess excessive height inside this range. |
| `GoAroundHeight` | Number, metres above terrain | `150` | Climb target during a go-around. |
| `GoAroundExitDistance` | Number, metres | `250` | Distance flown clear before re-approach. |
| `GoAroundSpeed` | Number, km/h | `70` | Commanded go-around speed. |
| `MaximumGoArounds` | Number, whole attempts | `1` | Maximum retries for one landing; `0` disables them. |
| `MaximumClimbRate` | Number, metres/second | `8` | Upward velocity cap. |
| `MaximumDescentRate` | Number, metres/second | `10` | Downward velocity cap. |
| `TouchdownRadius` | Number, metres | `5` | Accepted horizontal position error. |
| `FinalCommitDistance` | Number, metres | `75` | Inside this range, early vanilla waypoint completion does not cancel the flare. |
| `ControlInterval` | Number, seconds | `0.05` | Owner-local control update interval; performance-sensitive. |
| `TouchdownHoldSeconds` | Number, seconds | `20` | Grounded settling period before onward movement. |

Set `Waldo_ImprovedHelicopterLanding_Exclude = true` on a helicopter to opt it out. For class-, role- or mission-specific tuning, store a HashMap in `Waldo_ImprovedHelicopterLanding_Profile`; keys use the global suffix without the `Waldo_ImprovedHelicopterLanding_` prefix.

```sqf
this setVariable ["Waldo_ImprovedHelicopterLanding_Profile", createHashMapFromArray [
    ["TransitAltitude", 45],
    ["MaximumClimbRate", 5],
    ["MaximumGoArounds", 2]
]];
```

The feature has no ZEN module. Change mission defaults in `MissionConfig/aiConfig.sqf`, use a per-aircraft `Waldo_ImprovedHelicopterLanding_Profile` override, or call `Waldo_fnc_ImprovedHelicopterLandingConfigureServer` from an authorised mission script for a live global change.

The live server call takes **one Array** at position 0. It requires all 11 values in this exact order; a partial array returns `false`. Call it on the server to read its Boolean acceptance result. A client request is forwarded and immediately returns `false`, so that return is not proof the server rejected it.

| Array index | Type | Meaning |
| --- | --- | --- |
| 0 | Boolean | Enable landing control. |
| 1 | Number, metres | Minimum activation distance, clamped to 50–500. |
| 2 | Number, metres | Transit altitude, clamped to 15–150. |
| 3 | Number, ratio | Glide-slope ratio, clamped to 2–10. |
| 4 | Number, metres | Tree scan radius, clamped to 0–75. |
| 5 | Number, metres | Tree safety buffer, clamped to 0–25. |
| 6 | Number, metres | Go-around height, clamped to 50–500. |
| 7 | Number, metres/second | Maximum climb rate, clamped to 1–20. |
| 8 | Number, metres/second | Maximum descent rate, clamped to 1–25. |
| 9 | Number, whole attempts | Maximum go-arounds, rounded and clamped to 0–3. |
| 10 | Number, seconds | Touchdown hold, clamped to 0–60. |

For example, `[[true, 50, 30, 4, 25, 5, 150, 8, 10, 1, 20]] call Waldo_fnc_ImprovedHelicopterLandingConfigureServer;` republishes the shipped core profile. The runtime call does not change the other global settings in the table. Ordinary waypoint setup never needs this call. Its current callers are mission scripts that intentionally change the live global profile.

## Engine boundaries

The controller cannot make an obstructed landing point safe. Tree detection changes the flight profile; it does not remove vegetation. Rotor geometry, very steep terrain, damaged flight models and modded helicopters with unusual simulation can still prevent touchdown. Test critical airframes and landing zones, and use a normal MOVE waypoint near—but not immediately beside—the helicopter before a take-off-to-landing route.

## See also

- [AI Helicopter Deceleration](AI-Helicopter-Deceleration)
- [Feature Configuration Files](Feature-Configuration-Files)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
