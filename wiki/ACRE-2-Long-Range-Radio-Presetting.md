# ACRE2 Communications Configuration

> **Use this page when:** you need deterministic carried-radio assignments, independent duplicate radios, named displays, CEOI or optional Babel support.

Associated files: `MissionConfig\acreConfig.sqf` and `MissionScripts\MissionInit\ACRE2\acre2*.sqf`.
Vehicle-mounted rack radios are a separate surface with their own page:
[ACRE2 Vehicle Radio Racks](ACRE2-Vehicle-Radio-Rack-Setup).

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
| Vehicle radio rack | Unmanaged by the player-carried scan | See [ACRE2 Vehicle Radio Racks](ACRE2-Vehicle-Radio-Rack-Setup) | Uses `rackProfiles` in this same file and reuses these named side/net definitions, but is applied per vehicle with `Waldo_fnc_ACRE2RackSetup`. |

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

## Shared side channel sets (cooperative missions)

**What this is for:** joint nets above bridges one specific channel across chosen sides. Sometimes
that's not enough - a co-op mission where WEST and GUER are both player-controlled coalition partners
who should just fully talk to each other, on every channel, all the time. Give one of them the same
preset as the other and point its `nets` at the other's by name:

```sqf
// MissionConfig\acreConfig.sqf
["GUER", "default3", "INHERIT:WEST", [ // GUER uses WEST's preset AND WEST's exact channel list
    ["ALLY-1-1", [["ACRE_PRC152", "ALL", "PLT1", "RIGHT"]]] // GUER's own groups, same as normal
]],
```

Now every channel WEST has - PLT1, COY, AIRGND, whichever nets you've defined - GUER has too, the
same real frequency and the same channel label, automatically. Add a channel to WEST later and GUER
gets it too without touching GUER's row again. Groups (which squad uses which channel) stay separate
per side, since your WEST and GUER units are still different Eden groups - only the channel list
itself is shared.

Point directly at whichever side holds the real channel list. Don't chain sides (GUER inheriting from
EAST who inherits from WEST) - inherit straight from the side that actually defines the channels;
chaining, self-reference, an unknown side, or inheriting from a side using a different preset are all
rejected with a clear reason at mission start.

## Joint radio nets

**What this is for:** every side normally has its own separate channels - a WEST platoon net and an
EAST platoon net are different frequencies, so the two sides can never accidentally hear each other.
Sometimes you *want* that on purpose for one specific channel - a combined command net, a WEST JTAC
talking straight to an EAST liaison, allied WEST+GUER forces coordinating an attack - without opening
up anything else between them. `jointNets` punches exactly one such hole. `[]` by default, meaning no
bridging exists until you add a row.

```sqf
// MissionConfig\acreConfig.sqf
["jointNets", [
    ["JOINT_CMD", "PRC_LR", 45.500, [["WEST", 13], ["EAST", 6], ["GUER", 6]]]
    // [netId (diagnostics-only), radio family, shared frequency, [[side, channel], ...]]
]],
```

Read that row as: **45.500 MHz** is the one shared frequency. On **WEST**'s own radios, **channel
13** gets programmed to it. On **EAST**'s, **channel 6**. On **GUER**'s, also **channel 6**. So a
WEST player switches to channel 13, an EAST player switches to channel 6 - different numbers, same
real frequency underneath - and those two can now talk, while every other channel on their radios
stays exactly as isolated from each other as before. The channel numbers don't need to match across
sides because a channel number only means anything on that side's own radio preset; pick whichever
free channel each side has available.

Only `PRC_LR`, `BF888` and `SEM52` radio families can be used this way - PRC-343 and PRC-77/SEM70
work differently under the hood and aren't supported here yet. Using an unsupported family, an
unknown side, an out-of-range channel, or a channel that collides with a real net you've already
assigned on that side is always rejected with a clear reason at mission start, rather than silently
letting a real operational net get rerouted onto the bridge.

**Known v1 limitation:** a joint net is not yet referenceable by name from a group's assignment rows
the way an ordinary named net is (`["ACRE_PRC152", "ALL", "PLT1", "RIGHT"]`-style rows cannot yet say
`"JOINT_CMD"`) - note the channel number you placed it at and assign that number directly in the
relevant side's own group rows. There is also no in-mission Zeus toggle for a joint net yet; it is
mission-start configuration only. Both are clean, separately-scoped future work.

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

## See also

- [ACRE2 Vehicle Radio Racks](ACRE2-Vehicle-Radio-Rack-Setup) — vehicle-mounted rack radios (a
  separate surface from the carried-radio plan on this page).
- [AN/PRC-343 Automatic Setup](ACRE-2-Squad-Level-Radios-AN-PRC%E2%80%90343-Automatic-Setup)
- [Automated CEOI](ACRE2-Automated-CEOI-Document)
- [Babel Configuration](ACRE2-Babel-Configuration)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
