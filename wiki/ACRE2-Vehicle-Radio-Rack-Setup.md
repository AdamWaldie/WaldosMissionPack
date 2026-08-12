# ACRE2 Vehicle Radio Rack Setup

> **Use this page when:** you have a vehicle (Hunter, helicopter, tank, boat, plane, APC...) and you
> want its built-in ACRE2 rack radio tuned to a channel, or you want to swap what radio is mounted in
> it. Start here if you have never touched rack radios before — for the full technical reference see
> the "Vehicle radio racks" section of
> [ACRE2 Communications Configuration](ACRE-2-Long-Range-Radio-Presetting#vehicle-radio-racks).

Associated files: `MissionScripts\MissionInit\ACRE2\acre2RackSetup.sqf`,
`MissionScripts\MissionInit\ACRE2\acre2RackApply.sqf`.

## What this actually is

A **rack radio** is the radio built into a vehicle — the thing crew talk on through their headset
without carrying a handheld. It is completely separate from the personal radios your squad carries
(those are configured in `MissionConfig\acreConfig.sqf`, a different page). Rack radios are
configured **per vehicle**, with **one line in that vehicle's Eden init field**.

You do not need to place, buy or spawn anything extra, and you do not need any mod besides ACRE2
itself. Most vanilla Arma 3 vehicles already have one or two racks the moment ACRE2 loads.

## Quickest working setup

1. Place a vehicle in Eden Editor (a Hunter/Strider/Ifrit, a helicopter, a tank, an APC, an armed
   boat — see the table below for the full list).
2. Double-click it, open its **Init** field, and paste:
   ```sqf
   [this, ["preset", "vrc110_default"]] call Waldo_fnc_ACRE2RackSetup;
   ```
3. Done. Save, preview the mission with a player connected (rack setup needs a real connected player
   — see "Why nothing happens on an empty test server" below), get in the vehicle, and its rack
   radio(s) will be tuned automatically as ACRE2 finishes mounting them.

That's it — most mission makers never need anything beyond this one line. Everything past this
point is for when you want more control.

`vrc110_default` is one of ACRE2's own built-in preset names, not a WMP invention — it is the same
kind of preset you already pick for personal radios in the ACRE2 in-game radio settings. Any ACRE2
preset name works here.

## "Which vehicle can I even use this on?"

No mods required for the common case — ACRE2 gives most vanilla vehicle classes a rack the moment it
loads:

| If your vehicle is a... | It already has... |
|---|---|
| Helicopter, plane, tank, wheeled APC, armed boat, VTOL | A PRC-117F, already mounted and **fixed** (cannot be swapped or removed — see below) |
| Hunter / Strider / Ifrit (MRAP family) | Two racks: an **empty AN/VRC-110 you can freely re-equip**, plus a fixed PRC-117F |

Anything not on that list (most cars, most static weapons) has no rack at all — `Waldo_fnc_ACRE2RackSetup`
silently does nothing on those, it will not error.

If you only want to retune the channel of whatever is already mounted (the common case for
helicopters, planes, tanks, APCs and boats), the one-line preset call above already does that — read
no further.

## Want more control? Explicit per-rack assignment

Instead of a preset, hand it an `assignments` list — one row per rack you want to touch:

```sqf
[this, ["assignments", [
    [0, 5],                           // rack 0: just set channel 5
    [1, [2, 3], "ACRE_PRC117F"]       // rack 1: mount a PRC-117F, then set it to Block 2 / Channel 3
]]] call Waldo_fnc_ACRE2RackSetup;
```

Each row is `[rackIndex, channelOrFrequency, mountRadioClass (optional)]`:

- **`rackIndex`** — `0` is the vehicle's first rack, `1` its second, and so on, or the word `"ALL"`
  to apply the same row to every rack on the vehicle. Order matches whatever ACRE2 itself reports for
  that vehicle — if you are not sure which index is which on a specific vehicle, start with `"ALL"`
  or just experiment.
- **`channelOrFrequency`** — a plain channel number, `[block, channel]` (same idea as a squad
  PRC-343), or a decimal MHz frequency for a PRC-77/SEM70-style radio. Use `-1` (or leave the row as
  just `[rackIndex]`) if you only want to mount/remove a radio and not touch its channel.
- **`mountRadioClass`** (optional) — a radio classname like `"ACRE_PRC152"` to swap into that rack,
  or the special word `"REMOVE_RACK"` to rip the rack out entirely. Leave it out to keep whatever is
  already mounted.

## Swapping or removing what's mounted

This only works on a rack ACRE2 itself allows you to change. In practice, on stock Arma 3 vehicles,
that means **only the Hunter/Strider/Ifrit's empty AN/VRC-110 rack** — every vanilla PRC-117F other
vehicles come with is fixed hardware by ACRE2's own design, not a WMP limit. Trying to swap or remove
one of those is safely refused (nothing breaks — check the RPT for a `[WMP ACRE RACK]` line if you
want to confirm it was refused and why).

```sqf
// On a Hunter-family vehicle: put a PRC-152 in the empty, swappable rack (index 0 on the vanilla config):
[this, ["assignments", [[0, 12, "ACRE_PRC152"]]]] call Waldo_fnc_ACRE2RackSetup;
```

## Changing a vehicle's radios later in the mission

Call `Waldo_fnc_ACRE2RackSetup` again at any time — from a trigger, a script, whatever — with a
different config, and it re-applies. Calling it again with the **exact same** config it already has
does nothing (this is intentional — it is what makes it safe for the one-liner above to sit in an
init field that every connected player's machine technically runs).

## Why nothing happens on an empty test server

ACRE2 needs an actual connected player to finish setting a vehicle's racks up — this is an ACRE2
engine behaviour, not a WMP choice. If you preview/host with nobody connected, or the vehicle sits
empty, the radio simply will not finish initialising and nothing will be tuned. Get a player in (or
near) the vehicle and it will complete within a few seconds.

## Try it yourself

Two ready-made compositions in `WMP_Compositions/` demonstrate this on a placed, crewed Hunter:

- **`[WMP] ACRE2 Vehicle Radio Rack Example (Minimal)`** — the one-line preset call above.
- **`[WMP] ACRE2 Vehicle Radio Rack Example (Full)`** — explicit per-rack control: swaps the empty
  rack to a PRC-152 on channel 5, and retunes the fixed PRC-117F.

Drop either into Eden and read its in-editor comment for a walkthrough.

## Something not working?

- **Nothing is tuned at all:** make sure ACRE2 itself is loaded, and that a player is actually
  connected (see above).
- **A swap or "REMOVE_RACK" is being ignored:** that rack is fixed hardware on this vehicle (true for
  every vanilla PRC-117F rack) — see "Swapping or removing what's mounted" above.
- **Still stuck:** check the RPT log for lines starting `[WMP ACRE RACK]` — they name the exact
  vehicle and rack and explain what happened. Mission Diagnostics also reports a rack-setup summary
  under its `acre-vehicle-racks` row — see [Mission Diagnostics](Mission-Diagnostics).

## See also

- [ACRE2 Communications Configuration](ACRE-2-Long-Range-Radio-Presetting) — personal/carried radio
  setup, and the full technical reference for rack radios (asynchronous timing, FREQUENCY-mode
  caveats, diagnostics detail).
- [AN/PRC-343 Automatic Setup](ACRE-2-Squad-Level-Radios-AN-PRC%E2%80%90343-Automatic-Setup)
- [Mission Diagnostics](Mission-Diagnostics)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
