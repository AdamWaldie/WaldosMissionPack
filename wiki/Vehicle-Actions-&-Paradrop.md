# Vehicle Actions and Paradrop

> **Use this page when:** you need vehicle interactions, static-line or HALO jumps, and their equipment simulation settings.

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

For a plane you've already placed and crewed yourself in Eden, one call in its init field gives it a
reliable AI-flown paradrop route — no ZEN, no registry, no generated jumpers:

```sqf
[this, "dz1"] call Waldo_fnc_ParadropQuickFlightSetup;
```

Arguments: `[aircraft, target, direction, altitude, maxSpeed, options]`. `target` accepts a marker
name, a position, or an object; `direction` (`-1` by default) is computed automatically from the
aircraft's position toward the target if you don't set one. It waits (up to 30 seconds) for a pilot
to exist before doing anything, so it's safe to place alongside a separate `Waldo_fnc_MoveInCargoPlane`
call on another object in the same composition — both init fields can run in any order.

The aircraft's own existing waypoints are cleared before the generated route is added. This matters:
a leftover Eden waypoint competing with a scripted route for the AI's attention is the most common
reason a hand-set-up paradrop plane behaves unpredictably (wandering off the jump run, ignoring
altitude/speed, or never turning back for another pass). If you want to keep your own waypoints,
don't call this function — set the aircraft up manually instead (see below).

`options` is a HashMap for anything beyond the defaults — jump envelope overrides (falls back to the
mission's `MissionConfig\airOperationsConfig.sqf` values), `lifecycle` (`LOOP` default / `RETAIN` /
`DESPAWN`), `circuitDirection` (`LEFT` default / `RIGHT`), `approachDistance`/`runLength`/
`exitDistance`, and `createMarkers` (off by default — this entry point is deliberately map-clutter-free
unless you ask for the standby/green/red lines). See the script's own header for the complete list
and a HALO one-shot example.

This shares its actual flight-route logic (`Waldo_fnc_ParadropBuildFlightRoute`) with the fuller
Dynamic Drop-Zone system below — the same proven standby/green/red/exit route and the same
altitude/speed handling, so both paths fly identically once airborne. Use the Dynamic Drop-Zone
system instead when you want a managed, repeatable operation with generated AI jumpers, a Zeus
create/remove workflow, or map symbology by default.

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
loiters beyond the exit; **Single pass - despawn** cleans the aircraft and operation. Speed input is
in km/h and is converted to the engine's metres-per-second `forceSpeed` unit.

The create dialog independently enables and configures static-line and HALO player actions. Static
line selects a parachute vehicle plus minimum/maximum altitude and maximum speed. HALO selects a
steerable parachute backpack and minimum altitude. The optional door requirement can be disabled
for airframes whose ramp animations are not among the supported names. Both action sets are
installed for current clients and JIP clients. The authoritative creation API normalizes enabled
jump envelopes against the requested route: the route altitude remains inside each enabled
altitude window, static-line maximum speed stays at least 40 km/h above capped route speed, and an
unsupported door-animation requirement is disabled. Automatic sequencing also switches to the
enabled alternative or turns itself off instead of silently selecting a disabled jump method.

**Paradrop - Embark Players** uses the player directly underneath the placed module first, then the
curator selection:

- with a player selected, choose that player or all active players in that player's group and move them directly into free cargo seats;
- with no player target, choose a physical boarding object and label, then create it at the module with a blue **Board Paradrop Aircraft** addAction.

The default object is a flagpole carrying a blue flag. The standard selector also offers info stands, a map board, laptop, camping table and portable light. Created points have simulation disabled, remain editable/movable in Zeus and retain their boarding action after repositioning. Extend `Waldo_Paradrop_BoardingPointClasses` in `init.sqf` for mission-specific objects.

Only players are transferred, pilot/turret seats are never claimed, and full or stale aircraft are
reported through WMP notifications. The ongoing audit station also exposes **BOARD ME INTO QA
PARADROP** and **CREATE QA BOARDING POINT** controls.

Optional global map symbology includes the overall rectangular drop zone, small standby/green/red
line rectangles and a named point marker. Arma itself makes these global markers available to JIP
clients. The removal module cleans the markers and can delete the operation aircraft.

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
    ["direction", 90], ["altitude", 250], ["maximumSpeed", 220],
    ["lifecycle", "LOOP"], ["circuitDirection", "LEFT"],
    ["staticJumpEnabled", true], ["staticMinimumAltitude", 180],
    ["staticMaximumAltitude", 350], ["staticMaximumSpeed", 310],
    ["staticChuteClass", "NonSteerable_Parachute_F"],
    ["haloJumpEnabled", false], ["haloBackpackClass", "B_Parachute"],
    ["jumperCount", 0], ["autoDropPlayers", false], ["createMarkers", true]
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
missionNamespace setVariable ["WALDO_STATIC_STATICCHUTE", "rhs_d6_Parachute", true]; // chute class

// HALO
missionNamespace setVariable ["WALDO_PARA_HALOALTITUDE", 1000, true];  // metres AGL minimum
missionNamespace setVariable ["WALDO_PARA_HALOCHUTE",    "B_Parachute", true];        // chute class
```

For a non-RHS static chute (if you don't have RHS), use `"NonSteerable_Parachute_F"` (vanilla, fixed-wing).

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
