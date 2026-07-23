_Associated Files: `init.sqf`, `MissionScripts\MissionInit\Jamming\jammingInit.sqf`, `jammerCreate.sqf`, `jammerToggle.sqf`, `jammerRemove.sqf`, `jammingFactor.sqf`, `jammingAcreSignal.sqf`, `jammingTfarLoop.sqf`, `MissionScripts\ZenModules\Zen_jammerPlaceModule.sqf`, `Zen_jammerToggleModule.sqf`, `Zen_jammerRemoveModule.sqf`, `Waldo_fnc_Jammer`, `Waldo_fnc_JammerToggle`, `Waldo_fnc_JammerRemove`_

# Radio Jamming (ACRE2 / TFAR)

Localised radio jamming lets you deny communications in an area. Drop a **jammer** — any object with a radius — and radios inside its field stop working, fading back in through a soft edge as you leave. It works with **both ACRE2 and TFAR**, so you don't have to care which radio mod your unit runs.

Use it for EW objectives ("destroy the jammer to restore comms"), no-comms insertions, roleplay around a signals site, or just to make an area go dark on cue.

## What it does

* **ACRE2** — inside a jammer field, the signal between radios is dragged down toward the noise floor: transmissions get garbled and then drop out entirely. You can restrict a jammer to specific frequency **bands** so, say, only VHF is jammed.
* **TFAR** — inside a jammer field, a player's receive and transmit ranges are throttled toward zero and, at full strength, the radio is disabled outright. TFAR jamming is **broadband** (there is no per-band option).
* **Both** — jamming is strongest inside the **radius**, then falls off linearly over the **falloff** distance to nothing. You can jam **everyone** or only **chosen sides**. Players get an on-screen "RADIO JAMMED" prompt when they enter a field (toggleable).

The feature is **on by default** but does nothing until you actually place a jammer, so leaving it enabled costs you nothing.

> **ACRE2 requirement:** your ACRE2 **signal model** must be **LOS Multipath** (the default) or **Arcade**. ACRE2 does not expose the hook this uses under *LOS Simple*, so jamming will silently do nothing on that model.

## The quickest setup (Eden init field)

Place any object (an antenna, a vehicle, a generator), then in its **init field**:

```sqf
[this] call Waldo_fnc_Jammer;
```

That's a 300 m jammer that jams everyone on every band. Done.

Want more control? The full form is:

```sqf
[this, 500, "EAST"] call Waldo_fnc_Jammer;                         // 500 m, jams OPFOR only
[this, 800, "ALL", [[30, 88]], 50, 1, true, true] call Waldo_fnc_Jammer;  // VHF-only, 800 m + 50 m falloff, with a map marker
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

`Waldo_fnc_Jammer` returns a numeric **jammer id** you can keep to toggle or remove it later. Calling it again on the same object updates that jammer in place (it never stacks).

## Turning jammers on/off and removing them

Both take either the jammer **object** or its **id**. They are server-authoritative — safe to call from a trigger, a client or a script.

```sqf
[myTower, false] call Waldo_fnc_JammerToggle;   // switch off (omit the bool to just flip it)
[myTower, true]  call Waldo_fnc_JammerToggle;    // switch back on

[myTower]        call Waldo_fnc_JammerRemove;    // remove the jammer, keep the object
[myTower, true]  call Waldo_fnc_JammerRemove;    // remove the jammer AND delete the object
```

A classic EW objective — blow the tower, comms come back:

```sqf
// In the jammer tower's init:
[this, 600, "WEST"] call Waldo_fnc_Jammer;

// In a trigger that fires when the tower is destroyed:
[jammerTower] call Waldo_fnc_JammerRemove;
```

## Zeus usage

Three modules live under **Modules → Waldos Mission Modules** (Zeus Enhanced required):

| Module | Action |
|---|---|
| **Radio Jammer - Place** | Opens a dialog (radius, falloff, strength, affected side, map marker), then spawns an emitter and switches the jammer on. |
| **Radio Jammer - Toggle Nearest** | Flips the nearest jammer on/off. |
| **Radio Jammer - Remove Nearest** | Removes the nearest jammer and deletes its object. |

The placed emitter is added to the curator, so you can drag or delete it like any Zeus object.

## Global options (`init.sqf`)

```sqf
Waldo_Jamming_Enable = true;                                        // false = feature off entirely
missionNamespace setVariable ["Waldo_Jamming_Notify", true, true];  // on-screen "RADIO JAMMED" prompt
```

## How it works (for the curious)

The jammer list is owned and broadcast by the server, so late-joining players inherit every jammer automatically. Each player runs the engine for whichever radio mod they have — an ACRE2 custom signal function and/or a TFAR loop — reading that live list. A link is jammed when **either** end of it (the radio receiving *or* the radio transmitting) is inside an active field that affects your side and matches the band. That means both "your radio is in the jammed zone" and "the person calling you is standing in a jammer" degrade the call.

## See also

* [ACRE 2 Long Range Radio](https://github.com/AdamWaldie/WaldosMissionPack/wiki/ACRE-2-Long-Range-Radio-Presetting) — radio channel setup
* [Mission Diagnostics](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Mission-Diagnostics) — warns if jamming is enabled with no radio mod loaded
* [Waldos Mission Pack Zeus Modules](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mission-Pack-Zeus-Modules)
* [Mission Configuration Reference](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Mission-Configuration-Reference)
