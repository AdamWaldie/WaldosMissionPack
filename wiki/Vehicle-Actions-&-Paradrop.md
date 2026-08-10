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

This system provides three categories of vehicle-specific actions that are applied automatically at mission start: **paradrop/HALO jumping**, **side-door exit selection**, and **ACE cargo attributes**. Auto-detection covers the most common RHS, CUP and Vanilla assets — no setup required for those vehicles.

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
| `B_T_VTOL_01_infantry_F` | Vanilla V-44 VTOL — also gets HALO |

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

### ACE Cargo Attributes
| Base Class | Cargo Space | Notes |
|---|---|---|
| `MRAP_01_base_F` | 4 items | Vanilla Hunter/Strider/Ifrit family |

For any vehicle not in the above list, apply actions manually — see **Manual Setup** below.

---

## Jump Availability Conditions

Jump actions only appear (and can only be triggered) when **all** conditions are met:

| Condition | Static Line | HALO |
|---|---|---|
| Player is in cargo (not driver/gunner) | ✓ | ✓ |
| Aircraft door or ramp is open | ✓ | ✓ |
| Altitude ≥ minimum | ✓ | ✓ |
| Altitude ≤ maximum | ✓ | — |
| Speed ≤ maximum | ✓ | — |

Supported door/ramp animations: `ramp_bottom`, `door_2_1/2`, `jumpdoor_1/2`, `back_ramp_switch`, `back_ramp_half_switch`, `RearDoors`, `Door_1_source`, `ramp_anim`.

---

## How Jumping Works

### Static Line Jump
1. Player triggers the hold action → ejected from the aircraft at the door
2. A parachute vehicle (the configured `WALDO_STATIC_STATICCHUTE` class) is spawned and the player is placed in it immediately
3. Equipment simulation runs (see below)
4. Player descends under a fixed-wing chute — not steerable in vanilla, steerable with RHS `rhs_d6_Parachute`

### HALO Jump
1. Player triggers the hold action → ejected from the aircraft
2. **Equipment simulation** runs first
3. **Parachute backpack system** activates — the player's exact backpack loadout is saved and the backpack is replaced with a parachute (`WALDO_PARA_HALOCHUTE`)
4. Player freefalls; a hold action "Ditch Chute And Put On Backpack" appears near the ground
5. Landing automatically restores the original backpack, including exact magazine ammunition, weapons, nested containers and item counts. The hold action remains as a manual fallback. Repeated jump setup cannot overwrite an unrestored original backpack.

---

## Equipment Simulation

_Associated File: MissionScripts\Paradrop\paraEquipmentSim.sqf_

Simulates realistic item loss during a jump. Runs automatically on every jump. Two modes exist — **basic** (default) and **advanced**.

### What Can Be Lost

| Item Slot | Chance | Basic Mode | Advanced Mode |
|---|---|---|---|
| NVG/HMD | ~50% (random > 4 on 1–10 scale) | Unassigned (stays in inventory) | Permanently deleted |
| Soft headgear (bandanas, berets, boonie hats, caps, etc.) | ~60% (random > 3) | Unassigned | Deleted |
| Non-tactical glasses (aviators, spectacles, sport glasses) | ~70% (random > 2) | Unassigned | Deleted |

**Basic mode** (default): Items are unequipped and fall to the inventory — the player is notified "You almost lost [item] during your jump, it is in your inventory."

**Advanced mode**: Items are permanently deleted — the player is notified "You lost [item] during your jump."

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

For a plane you've already placed and crewed yourself in Eden, two steps give it a reliable
AI-flown paradrop route — no ZEN, no registry, no generated jumpers:

1. Place a marker anywhere on the map and name it (Eden Editor toolbar → Markers) — this is the
   drop zone the plane will fly toward. Any name works; `"dz1"` is just the example below.
2. In the aircraft's init field:

```sqf
[this, "dz1"] call Waldo_fnc_ParadropQuickFlightSetup;
```

That's it — no marker math, no waypoints to place by hand. Arguments:
`[aircraft, target, direction, altitude, maxSpeed, options]`. `target` accepts a marker name (the
beginner-friendly option — reference whatever you named the marker in step 1), a raw position, or
an object; `direction` (`-1` by default), when `target` is a marker, uses **that marker's own Eden
"Direction" rotation** — rotate the marker in Eden to set the approach heading, no coordinate math
needed. For a raw position or object target it falls back to computing a heading from the aircraft's
position toward the target. It waits (up to 180 seconds - a heavy multi-feature mission can
legitimately still be finishing init.sqf, and this is a one-time setup cost) for a pilot to exist
before doing anything, so it's safe to place alongside a separate `Waldo_fnc_MoveInCargoPlane` call
on another object in the same composition — both init fields can run in any order.

When `target` is a marker, the script immediately reads its position and Eden **Direction**, creates
the WMP-owned point/corridor markers, then deletes the original setup marker. Dedicated clients can
load their mission.sqm marker copy after that server deletion, so WMP also publishes a persistent
client-local hide watcher for the consumed marker. The drop-zone area and standby/green/red lines are
therefore visible in the pre-mission briefing map without the red Eden setup marker overlaid. Route
setup later reuses that exact geometry rather than creating another overlaid set.

**If the plane never takes off toward its target**, the most common cause is step 1 — the marker
was never placed, or its name doesn't exactly match the `target` string. This case reports itself
in-game via `systemChat` ("`<aircraft> has no flight target: place a map marker named <name>...`"), not
just the RPT log, specifically so this beginner mistake is easy to spot and fix.

The **"[WMP] Halo And Static Line Blackfish Drop Examples"** composition (Eden Editor →
Compositions → Waldos Mission Pack Compositions - Air Operations) demonstrates this end to end: it
already includes both aircraft wired up as above *and* their `"dz1"`/`"dz2"` target markers, so
dropping it into a mission and hitting play works immediately with no extra setup — drag the two
markers to wherever you actually want each drop zone to be.

The aircraft's own existing waypoints are cleared before the generated route is added. This matters:
a leftover Eden waypoint competing with a scripted route for the AI's attention is the most common
reason a hand-set-up paradrop plane behaves unpredictably (wandering off the jump run, ignoring
altitude/speed, or never turning back for another pass). If you want to keep your own waypoints,
don't call this function — set the aircraft up manually instead (see below). If the pilot's Eden
group has other units besides this aircraft's crew (a squad leader who's also the pilot, a
multi-crew group with members elsewhere), the crew is automatically moved into a dedicated fresh
group first, so those other units keep their own waypoints untouched.

Whatever static-line/HALO envelope you request (or the mission's configured defaults) is passed
through `Waldo_fnc_ParadropNormalizeJumpEnvelope` before the jump action is installed, using the same
clamped altitude/speed the route was actually built with — not your raw input — so it stays
reachable no matter what altitude/speed you pass in. This is the fix for a jump action that never
becomes available at all: the hold-action's live condition checks the aircraft's altitude and speed
against that envelope every frame, and a route altitude/speed set independently of the envelope is
exactly how the two end up unable to ever agree. `Waldo_fnc_ParadropCreateDropZone` normalizes off
the same route-returned basis, so both entry points behave identically here.

`options` is a HashMap for anything beyond the defaults — jump envelope overrides (falls back to the
mission's `MissionConfig\airOperationsConfig.sqf` values, then normalized as above), `lifecycle`
(`LOOP` default / `RETAIN` / `DESPAWN` — this function never deletes the aircraft under any
lifecycle; `DESPAWN` only changes which waypoints get added and is one of the two automatic
marker-cleanup triggers below), `circuitDirection` (`LEFT` default / `RIGHT`),
`approachDistance`/`runLength`/`exitDistance`, `name` (marker label, default `"Drop Zone"`),
`aircraftInvincible` (**off by default** — protects the aircraft from normal engine damage for the
life of the operation and reapplies protection if ownership moves between the server, a headless
client or a player client; scripted `setDamage`/`setHit` calls can still damage it),
`createMarkers` (**on by default** — AREA/STANDBY/GREEN/RED/POINT markers in the same layout as
`Waldo_fnc_ParadropCreateDropZone`, so you get a visible working drop zone immediately; pass `false`
for a map-clutter-free operation), and `keepMarkersOnCleanup` (**off by default** — the static markers
are removed automatically once the aircraft is destroyed/deleted, or once a `DESPAWN` run reaches its
exit point, since a marker for a drop zone that's no longer active is just stale; set `true` to leave
them on the map instead — this never affects the aircraft or crew either way). See the script's own
header for the complete list and a HALO one-shot example.

`createMarkers` also adds a **live-updating aircraft marker** — the same mechanism Airborne Gunship
Support uses for its own aircraft — that tracks the plane's real position/heading every frame while
it's flying, visible only to a friendly side. This is what actually "replaces" a pre-placed target
marker with a working drop zone once the aircraft takes off, rather than leaving only a fixed icon on
the map with no sense of where the plane currently is. It's always removed once the aircraft is gone,
regardless of `keepMarkersOnCleanup` (that option only ever affects the static
AREA/STANDBY/GREEN/RED/POINT markers).

This shares its actual flight-route logic (`Waldo_fnc_ParadropBuildFlightRoute`) with the fuller
Dynamic Drop-Zone system below — the same proven standby/green/red/exit route and the same
altitude/speed handling, so both paths fly identically once airborne. Use the Dynamic Drop-Zone
system instead when you want a managed, repeatable operation with generated AI jumpers, a Zeus
create/remove workflow, or map symbology by default.

---

## Dynamic Drop-Zone Operations

ZEN provides **Paradrop - Create Drop Zone**, **Paradrop - Preview Deployment Direction**,
**Paradrop - Embark Players** and **Paradrop - Remove Operation** modules. The create dialog
deliberately separates operational side from physical airframe: side controls the single AI pilot
and any explicitly requested AI jumpers, while the airframe may come from any faction.

### Previewing the deployment direction

The create dialog's **Run direction** slider is otherwise a blind 0-359 number with no feedback
about which way the line actually falls across the terrain. Place **Paradrop - Preview Deployment
Direction** at the intended drop-zone centre first to see it before committing:

1. The module immediately draws the real standby/green/red/exit line in 3D at your last-used heading
   (0° the first time).
2. **Q/E** rotates the line live in 5° steps — watch it sweep across the terrain in real time.
3. **Enter** confirms and opens the normal **Create Dynamic Paradrop** dialog with that heading
   already loaded into the Run direction slider (still adjustable there if you want to fine-tune the
   number directly). **Escape** cancels without opening anything.

The preview is entirely local to your own Zeus client — nothing is created or changed on the server
until you actually confirm the create dialog, which keeps its normal validation and clamping. This
is a convenience step, not a replacement: placing **Paradrop - Create Drop Zone** directly still
opens straight to the dialog with the slider defaulted to 0°, exactly as before.

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
just stale — check **Keep markers when the operation ends automatically** in the create dialog
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
reported through WMP notifications. The ongoing audit station also exposes **BOARD ME INTO QA
PARADROP** and **CREATE QA BOARDING POINT** controls.

The **Create map markers** option is on by default and visibly draws the overall rectangular drop
zone, small amber standby line, green jump line, red stop line and a named point marker, matching
the pre-placed quick-flight example. Turn the option off when none of those route markers should be
shown. Arma itself makes these global markers available to JIP
clients. **Paradrop - Remove Operation** always cleans the operation markers and can delete either a
dynamic or pre-placed aircraft when enabled and no players are aboard. Automatic cleanup
on a despawn pass or aircraft loss removes generated markers too unless
`keepMarkersOnCleanup` was enabled at creation.

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

Jump thresholds are set in `MissionConfig\airOperationsConfig.sqf` and apply to **all** aircraft — both auto-detected and manually set up:

```sqf
// Static Line
missionNamespace setVariable ["WALDO_STATIC_MINALTITUDE", 180, true];  // metres AGL
missionNamespace setVariable ["WALDO_STATIC_MAXALTITUDE", 350, true];  // metres AGL
missionNamespace setVariable ["WALDO_STATIC_MAXSPEED",    310, true];  // km/h
missionNamespace setVariable ["WALDO_STATIC_STATICCHUTE", "NonSteerable_Parachute_F", true]; // chute class (vanilla default)
missionNamespace setVariable ["Waldo_Paradrop_DefaultStaticRouteAltitude", 300, true]; // metres AGL
missionNamespace setVariable ["Waldo_Paradrop_DefaultStaticRouteSpeed", 300, true];    // km/h

// HALO
missionNamespace setVariable ["WALDO_PARA_HALOALTITUDE", 1000, true];  // metres AGL minimum
missionNamespace setVariable ["WALDO_PARA_HALOCHUTE",    "B_Parachute", true];        // chute class
missionNamespace setVariable ["Waldo_Paradrop_DefaultHaloRouteAltitude", 1200, true];  // metres AGL
missionNamespace setVariable ["Waldo_Paradrop_DefaultHaloRouteSpeed", 250, true];      // km/h
missionNamespace setVariable ["Waldo_Paradrop_DefaultAircraftInvincible", false, true]; // normal damage protection default
```

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

---

## Set Cargo Attributes

_Associated File: MissionScripts\VehicleActionsSetup\SetCargoAttributes.sqf_

Manually configure the ACE cargo space, cargo size, drag and carry settings for any object.

### Parameters

| # | Type | Default | Description |
|---|---|---|---|
| 0 | OBJECT | — | Vehicle or object |
| 1 | NUMBER | — | Cargo space (use `nil` to leave unchanged) |
| 2 | NUMBER | — | Cargo size (use `nil` to leave unchanged) |
| 3 | BOOL | true | Draggable |
| 4 | BOOL | true | Carryable |

### Examples

```sqf
[myTruck, 30, -1] call Waldo_fnc_SetCargoAttributes;         // 30 cargo space
[myCrate, -1, 2, true, false] call Waldo_fnc_SetCargoAttributes; // size 2, draggable only
[myCrate, nil, nil, true, false] call Waldo_fnc_SetCargoAttributes; // only set drag/carry
```

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
