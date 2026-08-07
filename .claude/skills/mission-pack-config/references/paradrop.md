# Paradrop — now "Dynamic Paradrop Operations"

Two layers exist, and it's important to know which the user means:

1. **Automatic per-vehicle jump actions** — most "Plane"-class assets
   auto-detect and get static-line/HALO actions with no per-vehicle config.
   Unchanged in spirit from before, just reconfigured (below).
2. **Dynamic Drop Zone Operations (new)** — a server-owned, ZEN- or
   script-created drop route: an AI-piloted aircraft flies a run-in circuit
   (standby/green/centre/red/departure gates) at a forced height/speed,
   with boarding, configurable static-line/HALO player actions, optional AI
   jumpers, markers and teardown. This is the "call-driven" system per
   `wiki/Feature-Setup-and-Activation.md` — config supplies pools/envelopes,
   a call/ZEN module creates each drop zone instance.

## Config (`MissionConfig\airOperationsConfig.sqf`)

Jump envelope/thresholds are now `server` entries in this file (loaded by
`initServer.sqf`, JIP-published) — do not paste `setVariable` calls into
`initServer.sqf` yourself:

```sqf
["WALDO_STATIC_MINALTITUDE", 180, true],           // metres AGL minimum
["WALDO_STATIC_MAXALTITUDE", 350, true],           // metres AGL maximum
["WALDO_STATIC_MAXSPEED", 310, true],              // km/h maximum
["WALDO_STATIC_STATICCHUTE", "rhs_d6_Parachute", true], // static-line chute class
["WALDO_PARA_HALOALTITUDE", 1000, true],           // metres AGL minimum for HALO
["WALDO_PARA_HALOCHUTE", "B_Parachute", true]      // HALO backpack class
```

Shared content pools (loaded on every machine from `init.sqf`, feed both the
automatic per-vehicle jump actions and the dynamic drop-zone selectors):

```sqf
["Waldo_Paradrop_AircraftClasses", [ /* transport aircraft offered by scripts/ZEN */ ]],
["Waldo_Paradrop_StaticChuteClasses", ["NonSteerable_Parachute_F"]],
["Waldo_Paradrop_HaloBackpackClasses", ["B_Parachute", "O_Parachute", "I_Parachute"]],
["Waldo_Paradrop_BoardingPointClasses", [ /* movable objects offered as labelled boarding points */ ]]
```

- Static-line jumps only activate within the altitude/speed window above —
  if a user reports "no jump option," check the aircraft's actual altitude
  and speed against these thresholds first.
- `WALDO_STATIC_STATICCHUTE` / `WALDO_PARA_HALOCHUTE` are parachute
  classnames — swap for a mod's chute (e.g. an RHS one) if the mission uses
  one instead of vanilla. For non-RHS missions, use
  `"NonSteerable_Parachute_F"` (vanilla, fixed-wing).

## Custom / non-auto-detecting aircraft

If a vehicle doesn't get the jump action automatically, add to its **Eden
Editor init field** (a script call, not a `mission.sqm` edit — safe to hand
over as a paste-in snippet):

```sqf
[this] call Waldo_fnc_VehicleJumpSetup;
// or apply only one type:
[this, 1000, "B_Parachute"] call Waldo_fnc_AddHaloJump;
[this, 180, 350, 310, "rhs_d6_Parachute"] call Waldo_fnc_AddStaticJump;
```

`Waldo_fnc_VehicleJumpSetup` reads the current `airOperationsConfig.sqf`
values automatically. **It only adds the jump action — it does not fly the
plane anywhere.** For that, see the next two sections.

## Reliable AI flight — quick setup (`Waldo_fnc_ParadropQuickFlightSetup`)

The simple alternative to the full Dynamic Drop Zone system below, for an
aircraft the mission maker already placed and crewed in Eden. Two steps:
place a named marker as the drop zone, then one call in the object's init
field:

```sqf
[this, "dz1"] call Waldo_fnc_ParadropQuickFlightSetup;
// [aircraft, target(marker name/position/object), direction(-1=auto), altitude, maxSpeed, options]
```

- `target` as a marker name is the beginner-friendly option: place a
  marker anywhere in Eden, name it, reference that name here — no
  coordinate math. If the marker was never placed or the name doesn't
  match exactly, this is reported in-game via `systemChat`, not just the
  RPT log — the #1 beginner mistake with this function.
- Builds a reliable standby → green → red → exit AI route (looping by
  default) using the exact same route logic as the Dynamic Drop Zone system
  (`Waldo_fnc_ParadropBuildFlightRoute`) — both stay in sync, fixes to one
  benefit the other.
- **Clears the aircraft's existing waypoints first.** A leftover Eden
  waypoint fighting the generated route is the #1 reason a hand-set-up
  paradrop plane misbehaves — don't call this on an aircraft whose manual
  waypoints the mission maker wants to keep. If the pilot's group has other
  units besides this aircraft's crew (e.g. a squad leader who's also the
  pilot), the crew is automatically moved into a dedicated fresh group first
  so those other units never lose their own waypoints.
- Waits (bounded, 180s - generous since this is a one-time setup cost and a
  heavy multi-feature mission can legitimately still be finishing init.sqf)
  for a pilot to exist, so it's safe even if a separate init-field call
  (e.g. `Waldo_fnc_MoveInCargoPlane` on another object) assigns the crew —
  order between the two doesn't matter.
- Requested (or configured-default) jump envelope values are clamped by
  `Waldo_fnc_ParadropNormalizeJumpEnvelope` around the route's actual
  altitude/speed before the jump action is installed — the fix for a jump
  action that never becomes available because the route and the envelope
  were set independently and can't both be satisfied at once.
  `Waldo_fnc_ParadropCreateDropZone` normalizes the same way.
- `options` HashMap: jump envelope overrides (default from
  `airOperationsConfig.sqf`'s `WALDO_STATIC_*`/`WALDO_PARA_*`, then
  normalized as above), `lifecycle` (`LOOP` default/`RETAIN`/`DESPAWN`),
  `circuitDirection` (`LEFT` default/`RIGHT`),
  `approachDistance`/`runLength`/`exitDistance`, `name` (marker label,
  default `"Drop Zone"`), `createMarkers` (**on by default** — the same
  AREA/STANDBY/GREEN/RED/POINT markers as the Dynamic Drop Zone system, so
  the mission maker sees a working drop zone immediately; pass `false` for
  a clutter-free operation), `keepMarkersOnCleanup` (**off by default** —
  the markers are removed automatically once the aircraft is
  destroyed/deleted, or once a `DESPAWN` lifecycle run reaches its exit
  point, since a marker for a drop zone that's no longer active is just
  stale). Full list in the script header.
- Set `keepMarkersOnCleanup: true` to opt out and leave the markers on the
  map instead — this still does **not** delete the aircraft or its crew
  either way, since this entry point never created or owned them in the
  first place (unlike `Waldo_fnc_ParadropCreateDropZone`, whose `DESPAWN`
  does delete the aircraft it spawned).
- No registry, no generated jumpers by default — use the Dynamic Drop Zone
  system instead for a managed, repeatable operation with those features.

## Dynamic Drop Zone Operations (new system)

### Scripted (`initServer.sqf`, server call-driven)

```sqf
private _drop = createHashMapFromArray [
    ["id", "DZ_ALPHA"], ["name", "DZ ALPHA"], ["centre", getMarkerPos "dz_alpha"],
    ["side", west], ["aircraftClass", "B_T_VTOL_01_infantry_F"],
    ["direction", 90], ["altitude", 250], ["maximumSpeed", 220],
    ["lifecycle", "LOOP"], ["circuitDirection", "LEFT"],
    ["staticJumpEnabled", true], ["staticMinimumAltitude", 180],
    ["staticMaximumAltitude", 350], ["staticMaximumSpeed", 310],
    ["staticChuteClass", "NonSteerable_Parachute_F"],
    ["haloJumpEnabled", false], ["haloBackpackClass", "B_Parachute"],
    ["jumperCount", 0], ["autoDropPlayers", false], ["createMarkers", true],
    ["keepMarkersOnCleanup", false]
];
[_drop] call Waldo_fnc_ParadropCreateDropZone;
```

`lifecycle`: `"LOOP"` (repeat wide circuit and re-run), `"RETAIN"`
(loiter after one pass), or `"DESPAWN"` (delete the aircraft/crew after
one pass — this system spawned and owns them, unlike `Waldo_fnc_
ParadropQuickFlightSetup`, see above; a lost aircraft is cleaned up the
same way). Markers are deleted alongside that automatic teardown by
default too, since a marker for a drop zone that's no longer active is
just stale — set `keepMarkersOnCleanup: true` at creation to leave them
on the map instead. An explicit `Waldo_fnc_ParadropRemoveDropZone` call
always removes them regardless.
The route validates itself against the requested jump envelopes — static
speed stays at least 60 km/h above the capped route speed, altitude stays
inside every enabled jump window with margin to absorb normal AI autopilot
wander, and an unsupported door-animation requirement disables itself
automatically rather than silently breaking.
`requireOpenDoor` defaults `true` here too (aligned with the quick-setup
entry point above) — safe because it self-disables for any airframe
without a recognised door/ramp animation.

```sqf
[dzId, playerOrGroup] call Waldo_fnc_ParadropEmbark;         // move players into the aircraft
["DZ_ALPHA"] call Waldo_fnc_ParadropRemoveDropZone;          // teardown
```

### Zeus ("Waldos Mission Modules" / WMP Combat Systems)

**Paradrop - Create Drop Zone**, **Paradrop - Embark Players**, **Paradrop -
Remove Operation**. The create dialog separates operational side (AI pilot +
any requested AI jumpers) from physical airframe (any faction's aircraft
class). Default aircraft: one AI pilot, **zero AI cargo** — cargo seats are
left for players. Embark uses the player standing under the module first,
then curator selection; falls back to a physical boarding object (default a
flagpole) with a blue **Board Paradrop Aircraft** addAction if no player
target is given.

Mission makers can extend the friendly-name dropdowns before startup:

```sqf
Waldo_Paradrop_AircraftClasses pushBackUnique "My_Transport_Aircraft";
Waldo_Paradrop_StaticChuteClasses pushBackUnique "My_Static_Line_Chute";
Waldo_Paradrop_HaloBackpackClasses pushBackUnique "My_Steerable_Parachute_Backpack";
Waldo_Paradrop_BoardingPointClasses pushBackUnique "My_Boarding_Point_Object";
```

## Equipment simulation and jump settings check

Unchanged: `Waldo_fnc_paraEquipmentSim` runs automatically on every jump
(basic mode unequips/loses NVGs, soft headgear and non-tactical glasses;
`[player, true] call Waldo_fnc_paraEquipmentSim;` for advanced/permanent-loss
mode — not exposed as a standard param, a direct call). "Check Jump
Settings" ACE self-action reports the aircraft's current jump
type/requirements — added automatically, no setup needed.
