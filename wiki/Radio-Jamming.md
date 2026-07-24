_Associated Files: `init.sqf`, `MissionScripts\MissionInit\Jamming\jammingInit.sqf`, `jammerCreate.sqf`, `jammerToggle.sqf`, `jammerRemove.sqf`, `jammingFactor.sqf`, `jammingAcreSignal.sqf`, `jammingTfarLoop.sqf`, `jammerInteraction.sqf`, `jammerScan.sqf`, `jammerMapDraw.sqf`, `jammingHud.sqf`, `MissionScripts\ZenModules\Zen_jammerPlaceModule.sqf`, `Zen_jammerToggleModule.sqf`, `Zen_jammerRemoveModule.sqf`, `Waldo_fnc_Jammer`, `Waldo_fnc_JammerToggle`, `Waldo_fnc_JammerRemove`_

# Radio Jamming (ACRE2 / TFAR)

Localised radio jamming lets you deny communications in an area. Drop a **jammer** — any object with a radius — and radios inside its field stop working, fading back in through a soft edge as you leave. It works with **both ACRE2 and TFAR**, so you don't have to care which radio mod your unit runs.

Use it for EW objectives ("destroy the jammer to restore comms"), no-comms insertions, roleplay around a signals site, or just to make an area go dark on cue.

## What it does

* **ACRE2** — inside a jammer field, the signal between radios is dragged down toward the noise floor: transmissions get garbled and then drop out entirely. You can restrict a jammer to specific frequency **bands** so, say, only VHF is jammed.
* **TFAR** — inside a jammer field, a player's receive and transmit ranges are throttled toward zero and, at full strength, the radio is disabled outright. TFAR jamming is **broadband** (there is no per-band option).
* **Both** — jamming is strongest inside the **radius**, then falls off over the **falloff** distance to nothing. You can jam **everyone** or only **chosen sides**, aim it as a **cone**, and make it **pulse**.

The feature is **on by default** but does nothing until you actually place a jammer, so leaving it enabled costs you nothing.

> **ACRE2 requirement:** your ACRE2 **signal model** must be **LOS Multipath** (the default) or **Arcade**. ACRE2 does not expose the hook this uses under *LOS Simple*, so jamming will silently do nothing on that model.

## "Is it jamming or just an Arma bug?" — the feedback is deliberately loud

Arma's radio mods drop comms for all kinds of buggy reasons, so a silent jammer would just look like another glitch. This system makes jamming **unmistakable**:

* A **persistent, blinking HUD banner** appears while you are jammed — drawn on the main display so other scripts' hints can't paint over it. It shows a live **strength %**, a bar, and the line *"Comms loss here is intentional — not a game bug."*
* A loud **entry message** in system chat when you're first jammed, and a **periodic reminder** every few seconds while it lasts.
* A green **"COMMS RESTORED"** banner and chat line the moment you leave the field.
* Players can actively confirm it with the **Scan for Radio Jammers** ACE self-action (see EW Toolkit below).

If you ever want it quieter, set `Waldo_Jamming_Notify` to `false` — but for most missions the loud feedback is the point.

## The quickest setup (Eden init field)

Place any object (an antenna, a vehicle, a generator), then in its **init field**:

```sqf
[this] call Waldo_fnc_Jammer;
```

That's a 300 m jammer that jams everyone on every band. Done.

Want more control? The full form is:

```sqf
[this, 500, "EAST"] call Waldo_fnc_Jammer;                                    // 500 m, jams OPFOR only
[this, 800, "ALL", [[30, 88]], 50, 1, true, true] call Waldo_fnc_Jammer;      // VHF-only, with a map marker
[this, 800, "ALL", "ALL", 50, 1, true, true, [90, 60]] call Waldo_fnc_Jammer; // a 60-deg cone facing 090
[this, 600, "ALL", "ALL", 50, 1, true, false, [], [4, 2]] call Waldo_fnc_Jammer; // pulses 4s on / 2s off
```

## `Waldo_fnc_Jammer` parameters

| # | Parameter | Type | Default | Purpose |
|---|---|---|---|---|
| 0 | object | Object | — | The emitter the jammer sits on (its position is the jam centre). |
| 1 | radius | Number | `300` | Full-strength jamming radius, in metres. |
| 2 | affectedSides | String / Array | `"ALL"` | `"ALL"`, a side, or an array. Accepts `"WEST"`/`"BLUFOR"`, `"EAST"`/`"OPFOR"`, `"IND"`/`"INDFOR"`, `"CIV"`/`"CIVILIAN"`, or actual sides. Only listed sides are jammed. |
| 3 | bands | String / Array | `"ALL"` | `"ALL"`, or an array of `[minMHz, maxMHz]` ranges to jam only those bands. **ACRE2 only** — ignored by TFAR. |
| 4 | falloff | Number | `50` | Extra metres of linear falloff beyond the radius. `0` = a hard edge. |
| 5 | strength | Number | `1` | Jamming strength at full effect, `0`–`1` (`1` = total blackout). |
| 6 | active | Bool | `true` | Start switched on. |
| 7 | createMarker | Bool | `false` | Place a red "Radio Jammer" map marker on it. |
| 8 | sector | Array | `[]` | `[]` = omnidirectional, or `[bearing, arc]` for a directional cone facing `bearing` degrees, `arc` degrees wide. |
| 9 | duty | Array | `[]` | `[]` = constant, or `[onSec, offSec]` to pulse the jammer on and off. |
| 10 | jamUAV | Bool | `false` | Also jam UAVs/drones in the field (see below). |

`Waldo_fnc_Jammer` returns a numeric **jammer id** you can keep to toggle or remove it later. Calling it again on the same object updates that jammer in place (it never stacks).

## UAV / drone jamming (counter-UAS)

Set the **jamUAV** flag (param 10, or the "Also Jam UAVs / Drones" checkbox in the Zeus module) and the field becomes counter-drone as well as anti-radio:

* **Autonomous drones** inside the field have their AI frozen — they stop flying/driving and hunting, and can be slipped past.
* **Player-controlled drones** get a **degrading video feed** as the operator flies into the field, and at near-total jamming the **datalink is cut** and the terminal disconnects.

```sqf
// A 400 m counter-UAS bubble that jams radios AND drones for everyone:
[this, 400, "ALL", "ALL", 50, 1, true, true, [], [], true] call Waldo_fnc_Jammer;
```

Just like the radio HUD, UAV jamming is **loud on purpose** — the operator sees a persistent blinking **"UAV LINK JAMMED — not a game bug"** banner and a clear "datalink lost" message, so a frozen or disconnected drone is never written off as one of Arma's UAV glitches. Because it is just a flag on a jammer, the same Toggle/Disable ACE actions, Zeus toggle/remove modules and RDF scan apply to it.

## The jamming model (global toggles in `init.sqf`)

These let you tune how realistic/gamey the jamming feels. All are on by default.

| Flag | Default | Effect |
|---|---|---|
| `Waldo_Jamming_LOS` | `true` | **Terrain line-of-sight** — a hill or ridge between the jammer and a radio blocks the field. Put a jammer on high ground for reach; tuck behind terrain to hide from it. |
| `Waldo_Jamming_BurnThrough` | `true` | **Power burn-through** — higher-power radios (e.g. a PRC-117F) resist jamming, shrinking the effective radius, while handhelds die fast. |
| `Waldo_Jamming_BurnThroughRef` | `500` | Reference radio power in mW — a radio at this power is fully affected; more powerful radios burn through. |
| `Waldo_Jamming_Curve` | `"LINEAR"` | Falloff shape at the edge: `"LINEAR"` or `"INVSQ"` (inverse-square feel — sharper near the centre). |
| `Waldo_Jamming_Destructible` | `true` | Destroying a jammer's object **removes the jammer automatically** — blow the tower, comms come back, no trigger needed. |
| `Waldo_Jamming_GmOverlay` | `true` | **Curators** see a floating marker (and facing line for cones) over every jammer. Ordinary players never see it. |
| `Waldo_Jamming_ScanRange` | `3000` | Detection range (m) of the handheld RDF scan action. |

## EW toolkit (for players, no Zeus needed)

Every jammer and every player gets ACE actions so an EW team can play the cat-and-mouse in the field:

| Action | Where | Who | What it does |
|---|---|---|---|
| **Toggle Radio Jammer** | on the jammer object | anyone | Switches that jammer on/off. |
| **Disable Radio Jammer** | on the jammer object | engineers | Destroys the emitter (which, with destructible jammers on, removes it). |
| **Scan for Radio Jammers** | self-interaction (ACE) | anyone | Reports the **bearing**, coarse **range** and **signal strength** to the nearest active jammer. Take bearings from two spots to triangulate the source. |

## Turning jammers on/off and removing them from script

Both take either the jammer **object** or its **id**. They are server-authoritative — safe to call from a trigger, a client or a script.

```sqf
[myTower, false] call Waldo_fnc_JammerToggle;   // switch off (omit the bool to just flip it)
[myTower]        call Waldo_fnc_JammerRemove;    // remove the jammer, keep the object
[myTower, true]  call Waldo_fnc_JammerRemove;    // remove the jammer AND delete the object
```

A classic EW objective is now automatic — because jammers are destructible by default, you don't even need a trigger:

```sqf
// In the jammer tower's init - blow it up in-game and comms come back on their own:
[this, 600, "WEST"] call Waldo_fnc_Jammer;
```

## Zeus usage

Three modules live under **Modules → Waldos Mission Modules** (Zeus Enhanced required):

| Module | Action |
|---|---|
| **Radio Jammer - Place** | Opens a dialog — radius, falloff, strength, affected side, **cone arc + bearing** (arc 360 = omni), **pulsing**, **also jam UAVs** and map marker — then spawns an emitter and switches the jammer on. |
| **Radio Jammer - Toggle Nearest** | Flips the nearest jammer on/off. |
| **Radio Jammer - Remove Nearest** | Removes the nearest jammer and deletes its object. |

The placed emitter is added to the curator, so you can drag or delete it like any Zeus object, and (with the GM overlay on) you'll see it floating-marked in the world.

## Global options (`init.sqf`)

```sqf
Waldo_Jamming_Enable = true;                                        // false = feature off entirely
missionNamespace setVariable ["Waldo_Jamming_Notify", true, true];  // on-screen jamming HUD + chat feedback
// plus the model toggles in the table above
```

## How it works (for the curious)

The jammer list is owned and broadcast by the server, so late-joining players inherit every jammer automatically. Each player runs the engine for whichever radio mod they have — an ACRE2 custom signal function and/or a TFAR loop — reading that live list through a shared calculator (`Waldo_fnc_JammingFactor`) that applies the whole model (duty cycle, sides, band, cone, terrain LOS, burn-through, falloff). A link is jammed when **either** end of it (the radio receiving *or* the radio transmitting) is inside an active field that affects your side and matches the band. That means both "your radio is in the jammed zone" and "the person calling you is standing in a jammer" degrade the call.

## See also

* [ACRE 2 Long Range Radio](https://github.com/AdamWaldie/WaldosMissionPack/wiki/ACRE-2-Long-Range-Radio-Presetting) — radio channel setup
* [Mission Diagnostics](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Mission-Diagnostics) — warns if jamming is enabled with no radio mod loaded
* [Waldos Mission Pack Zeus Modules](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mission-Pack-Zeus-Modules)
* [Mission Configuration Reference](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Mission-Configuration-Reference)
