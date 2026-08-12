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
3. Done. Save, preview the mission with a player connected (rack setup needs a real connected player
   near the vehicle within about 30 seconds — see "Why nothing happens on an empty test server"
   below), get in the vehicle, and its rack radio(s) will be tuned to channel 5 automatically as
   ACRE2 finishes mounting them.

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

## Why nothing happens on an empty test server (or a big mission)

ACRE2 needs an actual connected player **already close to the vehicle** to finish setting its racks
up — this is an ACRE2 engine behaviour, not a WMP choice. If you preview/host with nobody connected,
or the vehicle sits empty, the radio simply will not finish initialising and nothing will be tuned.

This also matters on a real mission: the vehicle's init field runs the instant the mission starts,
but the setup call only waits about **30 seconds** for a player to be near enough for ACRE2 to
actually do the work. On a large mission where players spend more than 30 seconds walking from their
spawn to the vehicle, that first attempt will time out (you'll see
`racks-not-initialised (no connected player, or ACRE2 setup failed within 30s)` in the RPT log) even
though nothing is actually wrong. This is expected, not a bug — get a player in (or near) the vehicle
and simply call `Waldo_fnc_ACRE2RackSetup` again (same line, e.g. from a trigger once a player is
confirmed near the vehicle, or just re-run it manually) and it will complete within a few seconds.

## How it works, and what is unverified

Rack initialisation and radio-ID issuance are genuinely asynchronous in ACRE2 and require a
connected player — ACRE2 delegates the actual mount/initialise work to a player's machine internally
rather than completing it synchronously on the server. `Waldo_fnc_ACRE2RackSetup` self-forwards to
the server like `Waldo_fnc_Jammer` (safe with no `isServer` wrapper in an Eden init field), then
waits with a bounded timeout — 30 seconds for the vehicle's racks to report initialised
(`acre_api_fnc_areVehicleRacksInitialized`), then 20 seconds per rack for its mounted radio to
receive a real unique ID rather than sit as a bare, un-initialised base classname
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

- **Nothing is tuned at all, and the RPT shows `racks-not-initialised`:** a player wasn't close
  enough to the vehicle within ~30 seconds of mission start — see "Why nothing happens on an empty
  test server (or a big mission)" above. Get a player to the vehicle and call
  `Waldo_fnc_ACRE2RackSetup` again.
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
