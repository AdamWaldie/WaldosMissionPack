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
3. **Parachute backpack system** activates — player's backpack is replaced with a parachute (`WALDO_PARA_HALOCHUTE`), original backpack contents are saved
4. Player freefalls; a hold action "Ditch Chute And Put On Backpack" appears once on the ground (altitude < 2 m)
5. Activating the hold action (5-second hold) restores the original backpack and contents, removes the forced-walk restriction

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

## Configuring Jump Parameters

Jump thresholds are set in `initServer.sqf` and apply to **all** aircraft — both auto-detected and manually set up:

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
// Apply both HALO and static line (reads thresholds from initServer.sqf automatically)
[this] call Waldo_fnc_VehicleJumpSetup;

// Apply only HALO
[this, 1000, "B_Parachute"] call Waldo_fnc_AddHaloJump;

// Apply only static line
[this, 180, 350, 310, "rhs_d6_Parachute"] call Waldo_fnc_AddStaticJump;

// Apply exit side selection
[this] call Waldo_fnc_AddExitActions;
```

`Waldo_fnc_VehicleJumpSetup` is a convenience wrapper that applies both jump types using whichever parameters are set in `initServer.sqf`.

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
