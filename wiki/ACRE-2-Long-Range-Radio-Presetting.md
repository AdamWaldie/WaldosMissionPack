# ACRE2 Communications Configuration

> **Use this page when:** you need deterministic carried-radio assignments, independent duplicate radios, named displays, CEOI or optional Babel support.

Associated files: `MissionConfig\acreConfig.sqf` and `MissionScripts\MissionInit\ACRE2\acre2*.sqf`
(vehicle radio racks specifically: `acre2RackSetup.sqf`, `acre2RackApply.sqf`).

All mission authoring lives in `MissionConfig\acreConfig.sqf`. WMP validates it before play, the
server sends the complete side/group setup to joining players, and each player's own computer
configures only the radios that player carries after ACRE is ready. Do not add ACRE waits or radio
setup calls to multiplayer `init.sqf`.

## Smallest working example: one group, one net

Before the full nets/families/overrides model below, here is the minimum that gets one squad
talking to each other on their own channel — everything else on this page is depth for when a
mission needs more than this. Inside the `"sides"` row for `WEST` in `MissionConfig\acreConfig.sqf`
(keep the shipped official ACRE preset name):

```sqf
[
    "WEST", "default3",
    [ // NETS: [key, label, family, value]
        ["PLT1", "PLATOON 1", "PRC_LR", 2]
    ],
    [ // GROUPS: [editor groupId, assignment rows]
        ["ALPHA-1-1", [                          // must match the Eden group's groupId
            ["ACRE_PRC343", "ALL", [1, 1], "LEFT"],   // short-range squad radio, block 1 channel 1
            ["ACRE_PRC152", "ALL", "PLT1", "RIGHT"]   // long-range radio tuned to the PLT1 net
        ]]
    ]
]
```

Every carried PRC-343 in that group starts on block 1/channel 1, and every carried PRC-152 starts on
the `PLT1` net. Read on for multiple nets, duplicate radios needing different tunings, per-player
overrides and named displays.

## Settings to edit

- `enabled`: master switch for the replacement lifecycle.
- `prc343PresetPolicy`: `FULL_RANGE` keeps 16 blocks but gives no side isolation; `SIDE_ISOLATED` uses ACRE's combat-side presets and five blocks.
- `namedDisplays`: labels supported PRC-148/152/117F channels without changing frequencies.
- `sides`: official side preset, nets and editor-group rows.
- `radioOverrides`: exceptional per-player assignment changes.
- `babel`: language definitions and assignments; shipped examples remain disabled.

Leave `strict` and `additionalRadioProfiles` alone unless extending or diagnosing the framework. WMP deliberately leaves PTT, speaker mode and other unsaved controls under player control. It does not poll, periodically reapply, or retune radios on group changes.

## What is a net?

A **net** is one named radio conversation, such as Platoon, Company or Air-to-Ground. It has exactly
one tuning value. A net is `[key, label, family, value]`:

```sqf
[
    "PLT1",      // 0: short internal name used by group rows.
    "PLATOON 1", // 1: name shown on supported displays and in the CEOI.
    "PRC_LR",    // 2: compatible radio family: PRC-148, PRC-152 and PRC-117F.
    2             // 3: the one value for this net: channel 2.
]
```

The result is straightforward: a compatible PRC-148, PRC-152 or PRC-117F assigned to `PLT1` starts
on channel 2. A BF-888S cannot use `PLT1`, even though it also has a channel 2, because it belongs to
a different frequency family and would not join the same conversation.

A shared net key is meaningful only when its tunings are interoperable. The official PRC-148/152/117F presets use matching frequencies at matching channel numbers. BF-888S and SEM52SL occupy different bands and therefore use separate local nets. PRC-77 and SEM70 can share an explicit common frequency. There is no global net count or smallest-radio capacity limit.

### Radio compatibility and special nets

Do not assume that the same channel number means two different radio families can communicate.
WMP resolves every net against the **base radio class** and ignores incompatible net rows.

| Radio | WMP target | Capacity or range | Safe authoring rule |
|---|---|---|---|
| PRC-343 | `[block, channel]` | 16 channels per block; 16 blocks under `FULL_RANGE`, 5 under `SIDE_ISOLATED` | Uses the same assignment row as every other radio; `[]` requests callsign inference. |
| PRC-148 | Channel number | Channels 1-32 | May share a named net with PRC-152/117F when official side-preset channel numbers match. |
| PRC-152 | Channel number | Channels 1-100 | May share numbered-channel PLT/AIR/CAS nets with PRC-148/117F. |
| PRC-117F | Channel number | Channels 1-100 | May share numbered-channel PLT/AIR/CAS nets with PRC-148/152. |
| BF-888S | Channel number | Channels 1-16 | Different band: use a BF-888S-specific net such as `BF_HANDHELD`. |
| SEM52SL | Channel number | Channels 1-12 | Different band: use a SEM52SL-specific net such as `SEM_HANDHELD`. |
| PRC-77 | Explicit MHz | 30-75.95 MHz, 50 kHz steps | Use a frequency net. It can share with SEM70 only at a value valid for both, such as 51.000 MHz. |
| SEM70 | Explicit MHz | 30-79.975 MHz, 25 kHz steps | Use a frequency net; never substitute an ordinary channel number. |
| Unknown radio | Unmanaged | Unknown | WMP preserves it. Register a tested carried-radio profile rather than guessing. |
| Vehicle radio rack | Unmanaged by this carried-radio scan | See "Vehicle radio racks" below | Configured separately, per-vehicle, via `Waldo_fnc_ACRE2RackSetup` - not part of this file. |

The shipped families are `PRC_LR`, `BF888`, `SEM52`, `LEGACY_VHF` and the separate PRC-343 block
system. A net remains valid when at least one radio in that family supports its value. Validation
then checks each actual group/player assignment against the selected radio. This permits, for
example, a higher PRC-152/117F channel while clearly rejecting that same net on a PRC-148 whose
32-channel capacity is too small. A shared legacy frequency must fit both PRC-77 and SEM70
range/step rules when both radios are assigned to it.

## Groups, duplicate radios and ears

A group is `[editor group ID, assignment rows]`. Every radio uses
`[radio class, "ALL" or occurrence number, target, ear]`:

```sqf
[
    "VIKING-2-3", // 0: groupId set for this squad in Eden Editor.
    [               // 1: [class, ALL/occurrence, net or direct value, ear].
        ["ACRE_PRC343", 1, [2, 3], "LEFT"],
        ["ACRE_PRC343", 2, [2, 4], "RIGHT"],
        ["ACRE_PRC148", "ALL", "PLT1", "RIGHT"],
        ["ACRE_PRC152", 1, "PLT1", "RIGHT"],
        ["ACRE_PRC152", 2, "AIRGND", "LEFT"],
        ["ACRE_PRC117F", "ALL", "PLT1", "BOTH"]
    ]
]
```

`ALL` is the readable choice when every carried radio of that class is identical. When duplicates
differ, number every intended occurrence (`1`, `2`, and so on). Do not combine `ALL` and numbered
rows for one class; validation rejects that ambiguity. Missing numbered occurrences are simply skipped.

`LEFT`, `RIGHT` and `BOTH`/`CENTER` are independent per occurrence. A PRC-343 assignment target of
`[]` requests deterministic callsign allocation. Two valid numeric callsign components are interpreted
as block/channel; otherwise WMP hashes the callsign and probes collisions deterministically.

## Side-scoped player overrides

Overrides are `[side, selector, mode, assignments]`. `MERGE` accepts readable `ALL` rows and retains
the rest of the group plan. When duplicate radios differ, use `REPLACE` with the complete numbered list.

```sqf
["WEST", ["ROLE", "JTAC"], "MERGE", [
    ["ACRE_PRC152", "ALL", "AIRGND", "RIGHT"]
]]
```

Selectors are `UID`, Eden `VARIABLE`, or `ROLE` text before an optional `@` suffix. Side scoping prevents a WEST override from accidentally validating against an EAST net.

## Named displays and upstream safeguards

WMP changes only `label` on PRC-148, `description` on PRC-152 and `name` on PRC-117F. It uses existing ACRE presets, never calls `copyPreset`, never writes TX/RX frequency fields for naming, and verifies the label plus unchanged frequencies after each write. The same deterministic label registration runs on server, hosted clients and JIP clients before normal radio application.

ACRE has [open issue history around copied or locally divergent presets](https://github.com/IDI-Systems/acre2/issues/1056). These safeguards avoid the known high-risk paths, but physical display verification remains part of multiplayer acceptance because a static test cannot prove ACRE/TeamSpeak runtime state.

## Join, respawn and persistence

On initial join, WMP waits for ACRE and applies the mission's starting setup once. That starting
setup is then saved as the player's first respawn condition. It is not continually enforced.

Saved loadouts always pass through `acre_api_fnc_filterUnitLoadout`. Never save or restore an `_ID_n` radio classname: [duplicate unique IDs are a documented cause of respawn failures](https://github.com/IDI-Systems/acre2/issues/1163). Radio state is stored separately by base class and same-type occurrence. When a player uses Save Loadout, their current supported channels, ears, volume, audio source and selected radio become their new respawn condition. INIDBI2 radio persistence carries the same saved state across sessions. The mission plan is used only for initial setup or when no usable saved snapshot exists.

Persistence and initial assignment use an explicit handshake rather than racing. A server result of
`FOUND` restores the saved radios and suppresses baseline retuning for that loadout generation.
`NONE` applies the mission baseline and captures it as the first safe save. `FAILED` or a 30-second
timeout allows the baseline and the rest of WMP to continue, but disables persistence writes for
that client session so an unread record cannot be overwritten. Mission makers do not disable ACRE
assignment after a first campaign session; the lifecycle selects persistence or baseline itself.

WMP applies numbered-channel radios and the PRC-343 directly to each resolved unique radio ID, then
reads the channel back before the initial respawn snapshot may be saved. For a PRC-343, the authored
`[block, channel]` is converted to ACRE's absolute 1-256 channel only at that API boundary. This
prevents ACRE's asynchronous bulk setup from leaving Block 1/Channel 1 in the first saved snapshot.
An `"ALL"` assignment is matched as the literal selector, so it also applies correctly to every
carried PRC-117F/148/152 occurrence instead of being preserved as unmanaged.

ACRE's `setupRadios` frequency path is asynchronous and exposes no public frequency read-back. WMP validates the request and records it as pending/unverified; the audit requires checking the physical PRC-77/SEM70 interface. It refuses frequency setup when same-type rack/external radios make ACRE's occurrence order ambiguous.

## Vehicle radio racks

> New to rack radios? [ACRE2 Vehicle Radio Rack Setup](ACRE2-Vehicle-Radio-Rack-Setup) is a
> beginner-focused walkthrough covering the same feature; this section is the full technical
> reference.

Vehicle-mounted rack radios (AN/VRC-64, AN/VRC-103, AN/VRC-110, AN/VRC-111, SEM90, or any
mission-added rack) are a separate, vehicle-scoped surface, deliberately outside
`acreConfig.sqf`'s per-player carried-radio scan (which preserves rack radios untouched - see the
table above). One object-init call on the vehicle configures every rack it has:

```sqf
// Simplest - apply a named ACRE2 preset to every rack on this vehicle. ACRE2 applies that preset's
// channels to each rack radio automatically as it mounts:
[this, ["preset", "vrc110_default"]] call Waldo_fnc_ACRE2RackSetup;

// Explicit per-rack control - rack 0 (0-based, in acre_api_fnc_getVehicleRacks order) gets channel
// 5; rack 1 gets Block 2/Channel 3 after mounting a PRC-117F into it:
[this, ["assignments", [
    [0, 5],
    [1, [2, 3], "ACRE_PRC117F"]
]]] call Waldo_fnc_ACRE2RackSetup;
```

`assignments` rows are `[rackIndex or "ALL", setting, mountRadioClass]`:

- `setting` is a channel number, `[block, channel]` for PRC-343-style radios, or a decimal MHz
  frequency - the same shapes used for carried radios above. `-1` (the default) applies no
  channel/frequency, useful when a row only needs to mount or remove a radio.
- `mountRadioClass` (optional) is a base radio classname (e.g. `"ACRE_PRC117F"`) to mount into that
  rack, or the sentinel `"REMOVE_RACK"`.

### Which vehicles have racks by default

No mods required for the common case. ACRE2 attaches racks by class inheritance, so essentially
every vanilla Arma 3 helicopter, plane, tank, wheeled APC, armed boat and MRAP-family vehicle already
has one or two racks the moment ACRE2 loads - confirmed directly against ACRE2's own
`addons/sys_rack/CfgVehicles.hpp`:

| Vehicle base class | Racks | Default contents |
|---|---|---|
| `Helicopter_Base_F`, `Plane_Base_F`, `Tank_F`, `Wheeled_APC_F`, `Boat_Armed_01_base_F`, `VTOL_01_unarmed_base_F` | 1-2 | A PRC-117F, **already mounted, not removable** (see below) |
| `MRAP_01/02/03_base_F` (Hunter/Strider/Ifrit-family) | 2 | Rack 1: empty AN/VRC-110, **removable**. Rack 2: a PRC-117F, already mounted, not removable |

Call `Waldo_fnc_ACRE2RackSetup` on any of these immediately to retune the pre-mounted PRC-117F's
channel - that is the common case and needs nothing extra. `acre_api_fnc_getVehicleRacks` returns
`[]` for a vehicle with no rack class in its inheritance chain (most cars, most static weapons); use
`acre_api_fnc_addRackToVehicle` (or a mod that already does) to give one a rack first.

`WMP_Compositions/[WMP]ACRE2_Vehicle_Radio_Rack_Example_Minimal` places a Hunter with the shortest
working call - a single named preset applied to every rack. `_Full` shows the same vehicle with
explicit per-rack `assignments` (mounting a replacement radio into the removable AN/VRC-110 and
retuning the fixed PRC-117F), matching the two examples below.

### Replacing or removing a rack's radio

A mission maker can give a vehicle a different radio loadout at any point in the mission, not just
at spawn - call `Waldo_fnc_ACRE2RackSetup` again with a different `assignments` config. **This only
does anything on a rack ACRE2 itself has flagged removable.** Checked directly against ACRE2's
config: of every vanilla rack in the table above, that is **only** the MRAP family's empty AN/VRC-110
`Rack_1` - every PRC-117F ACRE2 pre-mounts elsewhere (helicopters, planes, tanks, wheeled APCs, boats,
and the MRAPs' own `Rack_2`) has no `isRadioRemovable` property set at all, and ACRE2's own internal
check (`GET_STATE_RACK(...,"isRadioRemovable")`, defaulting to `false` when unset) means that radio
is fixed hardware by ACRE2's own design, not a WMP restriction. A mission-added rack
(`acre_api_fnc_addRackToVehicle`) can set `isRadioRemovable = true` itself for full replace/remove
behaviour anywhere.

```sqf
// On an MRAP-family vehicle - mount a PRC-152 into the empty, removable AN/VRC-110 rack (index
// depends on acre_api_fnc_getVehicleRacks order for that specific vehicle; 0 in the vanilla config):
[myMrap, ["assignments", [
    [0, 12, "ACRE_PRC152"]
]]] call Waldo_fnc_ACRE2RackSetup;
```

- A `mountRadioClass` that differs from what a rack currently holds **replaces** it - ACRE2's own
  mount call overwrites the previous occupant directly; there is no separate unmount step. This is
  refused (with an RPT diagnostic, that rack left untouched) when ACRE2's own
  `acre_api_fnc_isRackRadioRemovable` check reports the current occupant is not removable - as it
  will for essentially every vanilla vehicle's pre-mounted PRC-117F, per the table above.
- `"REMOVE_RACK"` rips the entire physical rack - hardware and radio - off the vehicle via
  `acre_api_fnc_removeRackFromVehicle`, gated by the same removability check, with the same
  practical result: it works on the MRAP's empty `Rack_1`, and is refused everywhere else on a
  vanilla vehicle. No public ACRE2 API to unmount only the radio and leave an empty rack in place was
  found; removal always takes the rack with it. If a mission specifically needs an intentionally-empty
  slot, place a spare unconfigured rack for that purpose rather than relying on
  "remove-then-later-remount."
- Calling `Waldo_fnc_ACRE2RackSetup` again with the **same** config as last time is a no-op (nothing
  is re-applied) unless a third `force` argument is passed - this is what keeps an Eden object init
  field, which runs on every connected machine, from repeating the same work once per client at
  mission start while still allowing a genuinely different later call through.

### How it works, and what is unverified

Rack initialisation and radio-ID issuance are genuinely asynchronous in ACRE2 and require a
connected player - ACRE2 delegates the actual mount/initialise work to a player's machine internally
rather than completing it synchronously on the server. `Waldo_fnc_ACRE2RackSetup` self-forwards to
the server like `Waldo_fnc_Jammer` (safe with no `isServer` wrapper in an Eden init field), then
waits with a bounded timeout - 30 seconds for the vehicle's racks to report initialised
(`acre_api_fnc_areVehicleRacksInitialized`), then 20 seconds per rack for its mounted radio to
receive a real unique ID rather than sit as a bare, un-initialised base classname
(`acre_api_fnc_getMountedRackRadio` returns the base class until ACRE2 finishes issuing the ID).
Both timeouts assume at least one player is connected; an empty dedicated server cannot complete
rack setup, the same operational constraint ACRE2 itself has.

CHANNEL and BLOCK_CHANNEL-mode rack radios are applied and read back synchronously, exactly like
carried radios of the same class. **FREQUENCY-mode rack radios (PRC-77/SEM70-family) are the one
path that has not been proven against a live engine**: no public per-radio frequency-write API
exists, so this reuses the same batched, ordinal `acre_api_fnc_setupRadios` call carried radios use
- but computes that specific radio's occurrence directly from its own already-known unique ID's
position in the broad current-radio list, rather than the ambiguous "which physical radio is this"
problem the carried-radio path guards against when several same-class radios of unknown identity are
visible at once. Treat FREQUENCY-mode rack radios as the priority item to verify manually before
relying on them.

Diagnostics: `runDiagnostics.sqf`'s `acre-vehicle-racks` row reports how many vehicles have had rack
setup requested, how many are still pending (mid-wait or timed out without producing an ID), and how
many reported a problem - check `[WMP ACRE RACK]` RPT entries for detail on any specific vehicle.

## Diagnostics and testing

The CEOI is generated from the compiled plan and lists each named net once, the current group's
PRC-343 assignment, and live channel highlights where ACRE provides read-back. Diagnostics report
unknown families, incompatible group assignments, channel-capacity failures, invalid frequency
ranges/steps, missing radio occurrences, ACRE readiness and conflicting Eden radio attributes.
Frequency entries remain request-based rather than falsely described as read-back verified.

The full audit mission distributes every supported carried radio among playable squad members, with at least one same-class partner. Its ACRE station tests duplicate radios, independent ears, named non-channel-1 assignments, PRC-77/SEM70 requests, filtered loadout respawn, Babel and preserved extra radios. The obsolete argument-based ACRE setup functions have been removed; `acreConfig.sqf` is the only supported setup path.

## Group callsign fallback

ACRE assignments match the group's live `groupId`, not merely the text shown in an Eden unit slot.
WMP therefore checks the group leader's role description on the server before compiling the radio
plan. If it contains an explicit suffix such as:

```text
Squad Leader@VIKING 2-3
```

WMP globally sets that group's callsign to `VIKING 2-3` and verifies the read-back. This covers the
case where CBA's Eden callsign attribute did not survive mission startup. It is only a fallback:
groups without `@Callsign` are left unchanged, and duplicate or empty suffixes are rejected and
written to the RPT. Put the suffix on the **group leader**, and keep it identical to the group key in
`MissionConfig\acreConfig.sqf`.

The role text before `@` is deliberately irrelevant. `Alpha Rifleman` does nothing;
`Alpha Team Leader@Viking` assigns `Viking`; and `Alpha Team Leader@Viking-1-1` assigns
`Viking-1-1`. This lets team-colour/role naming and group callsigns coexist without WMP mistaking a
role such as `Alpha Rifleman` for a radio callsign.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
