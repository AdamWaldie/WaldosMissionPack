# Vehicle Actions and Paradrop

> **Use this page when:** you need vehicle interactions, static-line or HALO jumps, and their equipment simulation settings.

The shipped Minimal and Full Eden paradrop compositions use passenger Blackfish aircraft with their
normal four-person editor crew: pilot, copilot and two crew chiefs. WMP does not create replacement
crew for an aircraft that already exists in Eden. This preserves the side and group chosen by the
mission maker and avoids duplicate or empty-side AI in multiplayer. Runtime crew creation is
reserved for an aircraft genuinely spawned by the Zeus module or script API.

_Associated Files:_
- _MissionScripts\VehicleActionsSetup_
- _MissionScripts\Paradrop_

WMP adds jump and side-door exit actions to supported vehicle classes at mission start. The automatic list covers the RHS, CUP and vanilla classes below. See [ACE Cargo and Object Handling](ACE-Cargo-And-Object-Handling) for ACE storage and handling settings.

## Beginner setup: choose one path

| If you want... | Start with... | Coding required |
|---|---|---|
| A ready-made working example | Eden composition **[WMP] Halo And Static Line Blackfish Drop Examples** | None; move/rotate its `dz1` and `dz2` markers. |
| Your own placed and crewed aircraft | `Waldo_fnc_ParadropQuickFlightSetup` | One line in the aircraft Init field. |
| Zeus to create and manage the whole operation in play | **Paradrop - Create Drop Zone** | None. |
| Generated AI jumpers, lifecycle and scripted control | `Waldo_fnc_ParadropCreateDropZone` | Advanced SQF/HashMap setup. |

For the shortest custom setup:

1. Place and crew a transport aircraft in Eden.
2. Place an Eden marker at the drop zone, name it `dz1`, and rotate it to the desired approach
   direction.
3. Put this in the aircraft's Init field:

```sqf
[this, "dz1"] call Waldo_fnc_ParadropQuickFlightSetup;
```

4. Preview the mission. The aircraft waits for its pilot and WMP startup, consumes the setup marker,
   creates the route/operation markers, and installs player jump interactions.

Start with the shipped 300 m / 300 km/h Static-Line or 1,200 m / 250 km/h HALO defaults. Change one
thing at a time only after the default route works with your chosen airframe.

---

## Auto-Detected Vehicles

The following vehicles receive actions automatically when the mission loads (and when Zeus spawns them during the mission):

### Exit Side Selection (Left / Right dismount)
| Base Class | Vehicles |
|---|---|
| `Heli_Transport_01_base_F` | Vanilla CH-47 Chinook family |
| `rhs_uh1h_base` | RHS UH-1H |
| `RHS_UH1_Base` | RHS UH-1Y/N |
| `RHS_Mi24_base` | RHS Mi-24 family |

### Static Line Jump
| Base Class | Notes |
|---|---|
| `RHS_Mi24_base` | Also gets exit actions |
| `RHS_Mi8_base` | RHS Mi-8 family |
| `Heli_Transport_02_base_F` | Vanilla Merlin/Puma family |
| `RHS_C130J_Base` | Also gets HALO (see below) |
| `B_T_VTOL_01_infantry_F` | Vanilla V-44 VTOL: also gets HALO |

### HALO Jump
| Base Class |
|---|
| `RHS_C130J_Base` |
| `B_T_VTOL_01_infantry_F` |

### Automatic Medical Vehicle Flag (ACE3)
| Base Class / Variant | Effect |
|---|---|
| RHS UH-60 MEV variants | `ace_medical_isMedicalVehicle = true` |
| RHS M1230a1 variants | `ace_medical_isMedicalVehicle = true` |
| RHS Stryker MEV | `ace_medical_isMedicalVehicle = true` |

For jump or exit actions on an unlisted vehicle, use **Manual Vehicle Setup** below.

---

## Jump Availability Conditions

Jump actions only appear (and can only be triggered) when **all** conditions are met:

| Condition | Static Line | HALO |
|---|---|---|
| Player is in cargo (not driver/gunner) | ✓ | ✓ |
| Aircraft door or ramp is open | ✓ | ✓ |
| Altitude ≥ minimum | ✓ | ✓ |
| Altitude ≤ maximum | ✓ | N/A |
| Speed ≤ maximum | ✓ | N/A |

Supported door/ramp animations: `ramp_bottom`, `door_2_1/2`, `jumpdoor_1/2`, `back_ramp_switch`, `back_ramp_half_switch`, `RearDoors`, `Door_1_source`, `ramp_anim`.

---

## How Jumping Works

### Static Line Jump
1. Player triggers the hold action → ejected from the aircraft at the door
2. A parachute vehicle (the configured `WALDO_STATIC_STATICCHUTE` class) is spawned and the player is placed in it immediately
3. Equipment simulation runs (see below)
4. Player descends under a fixed-wing chute: not steerable in vanilla, steerable with RHS `rhs_d6_Parachute`

### HALO Jump
1. Player triggers the hold action → ejected from the aircraft
2. **Equipment simulation** runs first
3. **Parachute backpack system** activates: the player's exact backpack loadout is saved and the backpack is replaced with a parachute (`WALDO_PARA_HALOCHUTE`)
4. Player freefalls; a hold action "Ditch Chute And Put On Backpack" appears near the ground
5. Landing automatically restores the original backpack, including exact magazine ammunition, weapons, nested containers and item counts. The hold action remains as a manual fallback. Repeated jump setup cannot overwrite an unrestored original backpack.

---

## Equipment Simulation

_Associated File: MissionScripts\Paradrop\paraEquipmentSim.sqf_

Simulates realistic item loss during a jump. Runs automatically on every jump. Two modes exist: **basic** (default) and **advanced**.

### What Can Be Lost

| Item Slot | Chance | Basic Mode | Advanced Mode |
|---|---|---|---|
| NVG/HMD | ~50% (random > 4 on 1–10 scale) | Unassigned (stays in inventory) | Permanently deleted |
| Soft headgear (bandanas, berets, boonie hats, caps, etc.) | ~60% (random > 3) | Unassigned | Deleted |
| Non-tactical glasses (aviators, spectacles, sport glasses) | ~70% (random > 2) | Unassigned | Deleted |

**Basic mode** (default): Items are unequipped and fall to the inventory: the player is notified "You almost lost [item] during your jump, it is in your inventory."

**Advanced mode**: Items are permanently deleted: the player is notified "You lost [item] during your jump."

Helmets and ballistic goggles are **not** in the loss lists and are always safe.

### Enabling Advanced Mode

Advanced mode is not exposed as a parameter in the standard jump flow. To enable it, you would call the function directly with `true` as the second argument:

```sqf
[player, true] call Waldo_fnc_paraEquipmentSim;
```

---

## Jump Settings Check

_Associated File: MissionScripts\Paradrop\checkForJumpSettings.sqf_

Adds a "Check Jump Settings" option under **ACE Self-Actions → Para Interactions** on any jump-capable aircraft. When activated, it displays the available jump type(s) and their requirements via an on-screen CBA notification:

- Static Line: max safe speed, altitude window
- HALO: minimum altitude

This is added automatically alongside jump actions. No setup required.

---

## Reliable Quick Flight Setup

_Associated Files: `MissionScripts\Paradrop\paradropQuickFlightSetup.sqf`,
`MissionScripts\Paradrop\paradropBuildFlightRoute.sqf`_

For an Eden-placed plane with its own crew, this call creates an AI-flown paradrop route. It uses no
ZEN registration or generated jumpers.

1. Place a marker at the drop zone and name it in Eden. This example uses `"dz1"`.
2. Put this in the aircraft's Init field:

```sqf
[this, "dz1"] call Waldo_fnc_ParadropQuickFlightSetup;
```

The arguments are `[aircraft, target, direction, altitude, maxSpeed, options]`. `target` accepts a
marker name, position or object. Use the marker name from step 1 for the simplest setup. With a
marker target, the default `direction` value of `-1` uses that marker's Eden **Direction**. Rotate
the marker to change the approach heading. With a position or object target, WMP calculates the
heading from the aircraft. The call waits up to 180 seconds for a pilot while mission startup
finishes. You may put a separate `Waldo_fnc_MoveInCargoPlane` call on another composition object;
the two Init fields can run in either order.

When `target` is a marker, the script immediately reads its position and Eden **Direction**, creates
the WMP-owned point/corridor markers, then deletes the original setup marker. Dedicated clients can
load their mission.sqm marker copy after that server deletion, so WMP also publishes a persistent
client-local hide watcher for the consumed marker. The drop-zone area and standby/green/red lines are
therefore visible in the pre-mission briefing map without the red Eden setup marker overlaid. Route
setup later reuses that exact geometry rather than creating another overlaid set.

If the plane never flies toward its target, check that the marker exists and its name matches the
`target` string exactly. WMP reports a missing marker through `systemChat` and the RPT.

The **[WMP] Halo And Static Line Blackfish Drop Examples** composition includes both configured
aircraft and their `"dz1"` and `"dz2"` target markers. Find it under Eden **Compositions >
Waldos Mission Pack Compositions - Air Operations**. Move the markers to the drop zones you want.

The aircraft's own existing waypoints are cleared before the generated route is added. This matters:
a leftover Eden waypoint competing with a scripted route for the AI's attention is the most common
reason a hand-set-up paradrop plane behaves unpredictably (wandering off the jump run, ignoring
altitude/speed, or never turning back for another pass). If you want to keep your own waypoints,
don't call this function: set the aircraft up manually instead (see below). If the pilot's Eden
group has other units besides this aircraft's crew (a squad leader who's also the pilot, a
multi-crew group with members elsewhere), the crew is automatically moved into a dedicated fresh
group first, so those other units keep their own waypoints untouched.

WMP passes the requested static-line and HALO limits through
`Waldo_fnc_ParadropNormalizeJumpEnvelope` before installing the jump action. It uses the route's
clamped altitude and speed, which keeps the action's live checks within the aircraft's flight
profile. `Waldo_fnc_ParadropCreateDropZone` uses the same route values.

The optional `options` HashMap accepts these keys:

| Key | What it changes |
|---|---|
| `staticJumpEnabled`, `haloJumpEnabled`, `staticMinimumAltitude`, `staticMaximumAltitude`, `staticMaximumSpeed`, `staticChuteClass`, `haloMinimumAltitude`, `haloBackpackClass` | Sets which jumps are offered and their limits. Omitted values come from `MissionConfig\airOperationsConfig.sqf`; WMP then normalizes them to the route. |
| `lifecycle` | `LOOP` (default), `RETAIN` or `DESPAWN`. This quick-flight call never deletes the aircraft. `DESPAWN` changes the route waypoints and can trigger marker cleanup. |
| `circuitDirection` | `LEFT` (default) or `RIGHT`. |
| `approachDistance`, `runLength`, `exitDistance` | Sets the route geometry. |
| `name` | Sets the marker label; default `"Drop Zone"`. |
| `aircraftInvincible` | Off by default. Protects against normal engine damage and reapplies after locality changes. Scripted `setDamage` and `setHit` can still damage the aircraft. |
| `createMarkers` | On by default. Creates hidden AREA, STANDBY, GREEN and RED route markers, plus a visible POINT marker for a named Eden target. Set `false` to omit them. |
| `keepMarkersOnCleanup` | Off by default. Set `true` to keep static markers after aircraft loss or a `DESPAWN` run reaches its exit. It does not change the aircraft or crew. |

See the function header for the full option list and a one-shot HALO example.

`createMarkers` also adds an aircraft marker that tracks the plane's position and heading while it
flies. Only players on the aircraft's side can see it. WMP removes this live marker when the
aircraft is gone, even if `keepMarkersOnCleanup` keeps the static route markers.

This quick setup and the Dynamic Drop-Zone system below both use
`Waldo_fnc_ParadropBuildFlightRoute`. Use Dynamic Drop-Zone when you need generated AI jumpers,
Zeus create/remove controls or default map markers.

### Helicopters and planes use different AI speed modes

This distinction is internal and deliberate:

- Helicopter route waypoints use Arma AI's `FULL` speed mode so Huron/Mohawk-class pilots actually
  pursue the requested cruise speed. The explicit `limitSpeed` value remains the hard ceiling.
- Fixed-wing and VTOL plane routes retain `LIMITED`, where the established launch velocity and
  cruise orders already behave correctly.
- A newly spawned helicopter receives time to establish rotor lift before cruise orders are applied;
  it is not injected immediately into full forward velocity while the rotor is still spooling up.

Mission makers set the numeric route ceiling, not `FULL`/`LIMITED` themselves. Applying the
helicopter workaround to planes, removing the helicopter lift delay, or confusing `limitSpeed`
(km/h) with `forceSpeed` (m/s) can produce overspeed, slow flight, or an apparent dive. The current
dedicated audit tests two helicopter classes at roughly 300 m and verifies they remain alive,
airborne, moving and inside the expected speed band.

---

## Dynamic Drop-Zone Operations

ZEN provides **Paradrop - Create Drop Zone**, **Paradrop - Embark Players** and **Paradrop - Remove
Operation** modules. The create dialog deliberately separates operational side from physical
airframe: side controls the single AI pilot and any explicitly requested AI jumpers, while the
airframe may come from any faction.

The aircraft flies a CARELESS/BLUE route at a forced terrain-relative height and capped speed. It
uses exact run-in waypoints through standby, green, centre, red and departure gates. The default
aircraft contains one AI pilot and **zero AI cargo**, leaving its cargo seats for players. Optional
AI jumpers and forced player sequencing remain available, with a configurable interval and static
line or HALO method.

Post-pass behavior is explicit: **Loop and repeat** flies a wide left- or right-hand circuit through
a point behind the original spawn before beginning the next aligned run; **Single pass - retain**
loiters beyond the exit; **Single pass - despawn** deletes the aircraft, its crew and the operation
(a lost aircraft is cleaned up the same way). The map markers created for the operation are **removed
automatically** along with this cleanup, since a marker for a drop zone that's no longer active is
just stale: check **Keep markers when the operation ends automatically** in the create dialog
(`keepMarkersOnCleanup`, off by default) to leave them on the map instead. Explicitly using
**Paradrop - Remove Operation** always removes the markers regardless of that setting. As with the
quick-setup flight above, the operation also carries a live-updating aircraft marker that tracks the
plane's real position/heading every frame while it flies; that one is always removed with the
operation regardless of `keepMarkersOnCleanup`.

The Zeus create dialog offers **Static-Line**, **HALO**, or **Static-Line and HALO**, plus requested
route altitude and speed. Its initial values come from `MissionConfig\airOperationsConfig.sqf`: the
shipped Static-Line profile is the same 300 m / 300 km/h profile used by the working full Eden
composition, while the shipped HALO profile is 1,200 m / 250 km/h. The client explains the limits,
and the server independently hard-gates the request against `WALDO_STATIC_MINALTITUDE`,
`WALDO_STATIC_MAXALTITUDE`, `WALDO_STATIC_MAXSPEED`, and `WALDO_PARA_HALOALTITUDE`. **Both** raises
the route to the HALO floor and expands the generated Static-Line ceiling around that accepted
route, so both selected actions remain mechanically possible. An incompatible request is adjusted
to the nearest valid value; it is never allowed to create an operation whose selected action cannot
be used. Zeus-created operations do not impose a ramp/door prerequisite because their AI
aircraft do not provide the passenger a dependable door control; scripted and Eden setups retain
the documented `requireOpenDoor` option. Actions are installed for current
clients and JIP clients through a network-ID resolver, so a newly spawned aircraft is not silently
received as `objNull` before replication finishes.

**Invincible drop aircraft** is available in the ZEN create dialog and is off by default. It is the
same `aircraftInvincible` setting used by both script APIs. The protection is locality-aware and is
removed again if an operation is removed while its aircraft is retained.

Scripted setups remain fully customizable through `Waldo_fnc_ParadropCreateDropZone`. The server
normalizes those custom envelopes against the requested route, but mission makers using the script
API are responsible for testing their chosen flight behaviour and airframe.

**Paradrop - Embark Players** and **Paradrop - Remove Operation** list both registry-backed Dynamic
Drop Zone operations and aircraft set up with `Waldo_fnc_ParadropQuickFlightSetup` (a mission
maker's own placed-and-crewed Eden aircraft). Entries are labelled **[DYNAMIC]** or **[EDEN]**.
Removing an Eden/quick-flight operation follows the same rules as removing a dynamic operation: its
operation markers, live marker and registration are cleared, and **Delete aircraft** removes its
aircraft and AI crew unless players are aboard. Turning the checkbox off retains the aircraft but
removes its WMP jump interactions. It uses the player directly underneath the placed module first,
then the curator selection:

- with a player selected, choose that player or all active players in that player's group and move them directly into free cargo seats;
- with no player target, choose a physical boarding object and label, then create it at the module with a blue **Board Paradrop Aircraft** addAction.

The default object is a flagpole carrying a blue flag. The standard selector also offers info stands, a map board, laptop, camping table and portable light. Created points have simulation disabled, remain editable/movable in Zeus and retain their boarding action after repositioning. Extend `Waldo_Paradrop_BoardingPointClasses` in `init.sqf` for mission-specific objects.

Only players are transferred, pilot/turret seats are never claimed, and full or stale aircraft are
reported through WMP notifications.

The **Create map markers** option is on by default and visibly draws the overall rectangular drop
zone, small amber standby line, green jump line, red stop line and a named point marker, matching
the pre-placed quick-flight example. Turn the option off when none of those route markers should be
shown. Arma itself makes these global markers available to JIP
clients. **Paradrop - Remove Operation** always cleans the operation markers and can delete either a
dynamic or pre-placed aircraft when enabled and no players are aboard. Automatic cleanup
on a despawn pass or aircraft loss removes generated markers too unless
`keepMarkersOnCleanup` was enabled at creation.

Jump actions and optional aircraft damage protection use one JIP replay attached directly to the
aircraft object. Arma removes that replay automatically when the aircraft is deleted. Explicitly
removing an operation also removes the replay before retaining or deleting the aircraft, so later
JIP clients never retry setup for an obsolete aircraft netId.

Mission makers can extend the friendly-name dropdowns before startup:

```sqf
Waldo_Paradrop_AircraftClasses pushBackUnique "My_Transport_Aircraft";
Waldo_Paradrop_StaticChuteClasses pushBackUnique "My_Static_Line_Chute";
Waldo_Paradrop_HaloBackpackClasses pushBackUnique "My_Steerable_Parachute_Backpack";
Waldo_Paradrop_BoardingPointClasses pushBackUnique "My_Boarding_Point_Object";
```

The equivalent server-side API is:

```sqf
private _drop = createHashMapFromArray [
    ["id", "DZ_ALPHA"], ["name", "DZ ALPHA"], ["centre", getMarkerPos "dz_alpha"],
    ["side", west], ["aircraftClass", "B_T_VTOL_01_infantry_F"],
    ["direction", 90], ["altitude", 300], ["maximumSpeed", 300],
    ["lifecycle", "LOOP"], ["circuitDirection", "LEFT"],
    ["staticJumpEnabled", true], ["staticMinimumAltitude", 180],
    ["staticMaximumAltitude", 350], ["staticMaximumSpeed", 310],
    ["staticChuteClass", "NonSteerable_Parachute_F"],
    ["haloJumpEnabled", false], ["haloBackpackClass", "B_Parachute"],
    ["jumperCount", 0], ["autoDropPlayers", false], ["createMarkers", true],
    ["keepMarkersOnCleanup", false], ["aircraftInvincible", false]
];
[_drop] call Waldo_fnc_ParadropCreateDropZone;
```

Use `Waldo_fnc_ParadropEmbark` to transfer players or create a boarding point, and
`Waldo_fnc_ParadropRemoveDropZone` with the stable operation ID for scripted cleanup.

## Configuring Jump Parameters

Jump thresholds are set in `MissionConfig\airOperationsConfig.sqf` and apply to **all** aircraft: both auto-detected and manually set up:

Edit the existing rows in that file; do not copy runtime `missionNamespace setVariable` commands
into `init.sqf` or `initServer.sqf`:

```sqf
// Inside the existing "server" array
["WALDO_STATIC_MINALTITUDE", 180, true],
["WALDO_STATIC_MAXALTITUDE", 350, true],
["WALDO_STATIC_MAXSPEED", 310, true],
["WALDO_STATIC_STATICCHUTE", "NonSteerable_Parachute_F", true],
["Waldo_Paradrop_DefaultStaticRouteAltitude", 300, true],
["Waldo_Paradrop_DefaultStaticRouteSpeed", 300, true],
["WALDO_PARA_HALOALTITUDE", 1000, true],
["WALDO_PARA_HALOCHUTE", "B_Parachute", true],
["Waldo_Paradrop_DefaultHaloRouteAltitude", 1200, true],
["Waldo_Paradrop_DefaultHaloRouteSpeed", 250, true]
```

`Waldo_Paradrop_DefaultAircraftInvincible` is in the file's `shared` array and defaults to `false`.
The final Boolean on each server row is the config loader's publish flag; beginners should retain it.
Keep the Static-Line route speed at or below its maximum release speed, and keep the HALO route
altitude at or above its minimum. WMP validates/normalizes requests, but compatible values are easier
for players and AI to understand.

For a steerable static chute with RHS, use `"rhs_d6_Parachute"` instead.

---

## Manual Vehicle Setup

For any vehicle not auto-detected, paste one of the following into its **init field** in Eden:

```sqf
// Apply both HALO and static line (reads server feature defaults automatically)
[this] call Waldo_fnc_VehicleJumpSetup;

// Apply only HALO
[this, 1000, "B_Parachute"] call Waldo_fnc_AddHaloJump;

// Apply only static line
[this, 180, 350, 310, "rhs_d6_Parachute"] call Waldo_fnc_AddStaticJump;

// Apply exit side selection
[this] call Waldo_fnc_AddExitActions;
```

`Waldo_fnc_VehicleJumpSetup` is a convenience wrapper that applies both jump types using whichever parameters are set in `MissionConfig\airOperationsConfig.sqf`.

## Beginner troubleshooting

| Symptom | Check first |
|---|---|
| Aircraft never starts its route | The target marker exists, its name exactly matches the Init-field string, and the aircraft has a living pilot. WMP waits up to 180 seconds for startup/pilot readiness and then logs the exact failure. |
| Jump action never appears | You are in a cargo seat, the required door/ramp is open for Eden/script setups, and live altitude/speed are inside the configured envelope. Use **ACE Self-Actions → Para Interactions → Check Jump Settings**. |
| Helicopter falls or dives just after spawning | Confirm the current WMP route builder is being used and no mission/mod script injects velocity or `forceSpeed` during rotor startup. WMP deliberately delays helicopter cruise orders. |
| Helicopter cruises far too slowly | Do not override generated waypoints to `LIMITED`; WMP uses `FULL` for helicopters while retaining `limitSpeed` as the ceiling. |
| Plane behaves differently after copying helicopter settings | Restore the generated fixed-wing `LIMITED` waypoints. The helicopter speed-mode workaround is not intended for planes. |
| Aircraft overspeeds | Speeds exposed to mission makers are km/h. Do not pass the same raw number to an extra `forceSpeed` call, which expects m/s. |
| Aircraft loops or circles near a gate | Remove competing Eden waypoints and test the default route geometry before shortening approach/run distances. Quick setup clears its aircraft group's existing waypoints intentionally. |
| JIP player has no jump action | Confirm the aircraft still exists and the operation was not removed. Current operations replay setup by aircraft net ID; stale replay is removed with the aircraft/operation. |
| Old map markers remain | Use **Paradrop - Remove Operation**. Automatic cleanup retains static markers only when `keepMarkersOnCleanup` was explicitly enabled. |

---

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
