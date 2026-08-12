# ACRE2 Vehicle Radio Rack Setup

> **Use this page when:** you have a vehicle (Hunter, helicopter, tank, boat, plane, APC...) and you
> want its built-in ACRE2 rack radio tuned to a channel, or you want to swap what radio is mounted in
> it. This is the complete reference for vehicle rack radios, from the smallest working call through
> the underlying ACRE2 mechanics. Personal/carried squad radios are a separate surface, configured in
> [ACRE2 Communications Configuration](ACRE-2-Long-Range-Radio-Presetting).

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
   [this, ["assignments", [["ALL", 5]]]] call Waldo_fnc_ACRE2RackSetup;
   ```
3. Done. Save, preview the mission with a player connected (rack setup needs a real connected
   player somewhere on the server — see "Why nothing happens on an empty test server" below), get in
   the vehicle, and its rack radio(s) will be tuned to channel 5 automatically as ACRE2 finishes
   mounting them.

That's it — most mission makers never need anything beyond this one line. Everything past this
point is for when you want more control.

> **A note on ACRE2 "presets":** `Waldo_fnc_ACRE2RackSetup` also accepts a `["preset", "name"]`
> config that hands a preset name straight to ACRE2's own `acre_api_fnc_setVehicleRacksPreset`. A
> preset name is a name ACRE2 defines for an actual **radio model** (e.g. a PRC-152 or PRC-117F
> preset) — a rack designation like AN/VRC-110 names the vehicle's **mounting hardware**, not a
> radio, and is never itself a valid preset name. WMP does not ship or guarantee any preset name
> works in your install; use `assignments` (explicit channel numbers, as above) unless you have
> already confirmed a specific preset name in your own ACRE2 setup.

## "Which vehicle can I even use this on?"

No mods required for the common case — ACRE2 attaches racks by class inheritance, so most vanilla
Arma 3 vehicle classes already have a rack the moment it loads — confirmed directly against ACRE2's
own `addons/sys_rack/CfgVehicles.hpp`:

| Vehicle base class | Racks | It already has... |
|---|---|---|
| `Helicopter_Base_F`, `Plane_Base_F`, `Tank_F`, `Wheeled_APC_F`, `Boat_Armed_01_base_F`, `VTOL_01_unarmed_base_F` | 1-2 | A PRC-117F, already mounted and **fixed** (cannot be swapped or removed — see below) |
| `MRAP_01/02/03_base_F` (Hunter/Strider/Ifrit-family) | 2 | Rack 0: an **empty AN/VRC-110 you can freely re-equip**. Rack 1: a fixed PRC-117F |

Anything not on that list (most cars, most static weapons) has no rack at all —
`acre_api_fnc_getVehicleRacks` returns `[]` for it, and `Waldo_fnc_ACRE2RackSetup` silently does
nothing there — it will not error. Use `acre_api_fnc_addRackToVehicle` (or a mod that already does)
to give such a vehicle a rack first.

If you only want to retune the channel of whatever is already mounted (the common case for
helicopters, planes, tanks, APCs and boats), the one-line call above already does that — read no
further.

## Want more control? Explicit per-rack assignment

Instead of a preset, hand it an `assignments` list — one row per rack you want to touch:

```sqf
[this, ["assignments", [
    [0, 5],                        // rack 0: just set channel 5
    [1, 44, "ACRE_PRC117F"]        // rack 1: mount a PRC-117F, then set it to channel 44
]]] call Waldo_fnc_ACRE2RackSetup;
```

Each row is `[rackIndex, channelOrFrequency, mountRadioClass (optional)]`:

- **`rackIndex`** — `0` is the vehicle's first rack, `1` its second, and so on, or the word `"ALL"`
  to apply the same row to every rack on the vehicle. Order matches whatever ACRE2 itself reports for
  that vehicle — if you are not sure which index is which on a specific vehicle, start with `"ALL"`
  or just experiment.
- **`channelOrFrequency`** — a plain channel number for most radios (PRC-148/152/117F), `[block,
  channel]` **only** for a PRC-343 (it has no plain channel number, only block+channel), or a decimal
  MHz frequency for a PRC-77/SEM70-style radio. Do not use `[block, channel]` for a PRC-148/152/117F —
  those radios only have a plain channel number, no block concept. Use `-1` (or leave the row as just
  `[rackIndex]`) if you only want to mount/remove a radio and not touch its channel.
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

ACRE2 needs an actual connected player **somewhere on the server** to finish setting a vehicle's
racks up — this is an ACRE2 engine behaviour, not a WMP choice; ACRE2 delegates that work to a
connected player's own machine (any connected player, not specifically one near or inside the
vehicle). `Waldo_fnc_ACRE2RackSetup` triggers ACRE2's own rack initialisation itself as soon as a
player exists (it does not wait around hoping ACRE2 gets to it on its own), so on a normal hosted
mission setup completes within a few seconds of a player being connected, regardless of where that
player currently is on the map.

The one genuine gap this can't paper over: a **dedicated server that auto-starts its mission before
anyone has joined** fires this vehicle's Eden init field with zero players connected — nothing ACRE2
does can initialise a rack with nobody there to do the work. WMP handles this by waiting, separately
and much more patiently (up to **5 minutes**), for a player to actually be connected before it even
attempts anything with ACRE2; only once a player exists does the short 30-second ACRE2 wait start. If
you still see `no-player-connected (nobody joined the server within 300s of this call)` in the RPT, no
player joined that server within 5 minutes of the mission starting — call
`Waldo_fnc_ACRE2RackSetup` again once someone has. If instead you see
`racks-not-initialised (no connected player, or ACRE2 setup failed within 30s)`, a player was
connected but ACRE2 itself failed to finish within 30 seconds — this is the case worth reporting if it
recurs, since it means ACRE2's own initialisation did not complete even with the explicit trigger.

## How it works, and what is unverified

Rack initialisation and radio-ID issuance are genuinely asynchronous in ACRE2 and require a
connected player — ACRE2 delegates the actual mount/initialise work to a player's machine internally
rather than completing it synchronously on the server. `Waldo_fnc_ACRE2RackSetup` self-forwards to
the server like `Waldo_fnc_Jammer` (safe with no `isServer` wrapper in an Eden init field), which then
runs two separate, differently-bounded waits rather than one shared timeout:

1. **Up to 5 minutes** for any player to be connected to the server at all — a dedicated server can
   fire this vehicle's Eden init field before its lobby has filled, which is a mission-hosting
   condition outside WMP's or ACRE2's control.
2. Once a player exists, it calls `acre_api_fnc_initVehicleRacks` on the vehicle itself — per ACRE2's
   own source, that function must be executed explicitly and is not triggered automatically on
   vehicle creation or by player proximity; it delegates the actual work to whichever connected
   player ACRE2 selects, not necessarily one near the vehicle. Calling it directly, rather than
   passively waiting for ACRE2 to trigger it on its own, is what makes the following **30-second**
   wait for `acre_api_fnc_areVehicleRacksInitialized` to report true normally resolve within a few
   seconds regardless of where players currently are on the map.

Then 20 seconds per rack for its mounted radio to receive a real unique ID rather than sit as a bare,
un-initialised base classname
(`acre_api_fnc_getMountedRackRadio` returns the base class until ACRE2 finishes issuing the ID).

CHANNEL-mode rack radios (PRC-148/152/117F) are applied and read back synchronously, exactly like
carried radios of the same class — this is the tested, verified path. **FREQUENCY-mode rack radios
(PRC-77/SEM70-family) are the one path that has not been proven against a live engine**: no public
per-radio frequency-write API exists, so this reuses the same batched, ordinal
`acre_api_fnc_setupRadios` call carried radios use, computing that specific radio's occurrence from
its own already-known unique ID's position in the broad current-radio list. Treat FREQUENCY-mode rack
radios as the priority item to verify manually before relying on them.

**Why some racks refuse a swap or `"REMOVE_RACK"`:** both are gated by ACRE2's own
`acre_api_fnc_isRackRadioRemovable` check, which is `false` unless `isRadioRemovable = 1` was set
where that rack was configured. Checked directly against ACRE2's vanilla vehicle config, that is
**only** the MRAP family's empty AN/VRC-110 rack — every PRC-117F ACRE2 pre-mounts elsewhere has no
`isRadioRemovable` property set at all, so it is fixed hardware by ACRE2's own design, not a WMP
restriction. A mission-added rack (`acre_api_fnc_addRackToVehicle`) can set that flag itself for full
replace/remove behaviour anywhere. No public ACRE2 API to unmount only the radio and leave an empty
rack in place was found — `"REMOVE_RACK"` always takes the physical rack with it.

Diagnostics: `runDiagnostics.sqf`'s `acre-vehicle-racks` row reports how many vehicles have had rack
setup requested, how many are still pending (mid-wait or timed out without producing an ID), and how
many reported a problem — check `[WMP ACRE RACK]` RPT entries for detail on any specific vehicle.

## Try it yourself

Two ready-made compositions in `WMP_Compositions/` demonstrate this on a placed, crewed Hunter:

- **`[WMP] ACRE2 Vehicle Radio Rack Example (Minimal)`** — the one-line `"ALL"` call above.
- **`[WMP] ACRE2 Vehicle Radio Rack Example (Full)`** — explicit per-rack control: swaps the empty
  rack to a PRC-152 on channel 5, and retunes the fixed PRC-117F.

Drop either into Eden and read its in-editor comment for a walkthrough.

## Something not working?

- **Nothing is tuned at all, and the RPT shows `no-player-connected`:** nobody joined the server
  within 5 minutes of the call — see "Why nothing happens on an empty test server" above. Call
  `Waldo_fnc_ACRE2RackSetup` again once a player is connected.
- **Nothing is tuned at all, and the RPT shows `racks-not-initialised`:** a player was connected but
  ACRE2 itself failed to finish initialising within 30 seconds — this is worth reporting if it
  recurs, since it means ACRE2's own initialisation did not complete even with the explicit trigger.
- **A swap or "REMOVE_RACK" is being ignored:** that rack is fixed hardware on this vehicle (true for
  every vanilla PRC-117F rack) — see "Swapping or removing what's mounted" above.
- **Still stuck:** check the RPT log for lines starting `[WMP ACRE RACK]` — they name the exact
  vehicle and rack and explain what happened. Mission Diagnostics also reports a rack-setup summary
  under its `acre-vehicle-racks` row — see [Mission Diagnostics](Mission-Diagnostics).

## See also

- [ACRE2 Communications Configuration](ACRE-2-Long-Range-Radio-Presetting) — personal/carried squad
  radio setup (a separate surface from vehicle racks).
- [AN/PRC-343 Automatic Setup](ACRE-2-Squad-Level-Radios-AN-PRC%E2%80%90343-Automatic-Setup)
- [Mission Diagnostics](Mission-Diagnostics)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
