# ACRE2 Communications Configuration

> **Use this page when:** you need deterministic carried-radio assignments, independent duplicate radios, named displays, CEOI or optional Babel support.

Associated files: `MissionConfig\acreConfig.sqf` and `MissionScripts\MissionInit\ACRE2\acre2*.sqf`.

All mission authoring lives in `MissionConfig\acreConfig.sqf`. WMP validates it before play, the
server sends the complete side/group setup to joining players, and each player's own computer
configures only the radios that player carries after ACRE is ready. Do not add ACRE waits or radio
setup calls to multiplayer `init.sqf`.

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
| PRC-343 | `[block, channel]` | 16 channels per block; 16 blocks under `FULL_RANGE`, 5 under `SIDE_ISOLATED` | Use the group's PRC-343 field or an explicit PRC-343 assignment. It does not consume LR named-net rows. |
| PRC-148 | Channel number | Channels 1-32 | May share a named net with PRC-152/117F when official side-preset channel numbers match. |
| PRC-152 | Channel number | Channels 1-100 | May share numbered-channel PLT/AIR/CAS nets with PRC-148/117F. |
| PRC-117F | Channel number | Channels 1-100 | May share numbered-channel PLT/AIR/CAS nets with PRC-148/152. |
| BF-888S | Channel number | Channels 1-16 | Different band: use a BF-888S-specific net such as `BF_LOCAL`. |
| SEM52SL | Channel number | Channels 1-12 | Different band: use a SEM52SL-specific net such as `SEM_LOCAL`. |
| PRC-77 | Explicit MHz | 30-75.95 MHz, 50 kHz steps | Use a frequency net. It can share with SEM70 only at a value valid for both, such as 34.000 MHz. |
| SEM70 | Explicit MHz | 30-79.975 MHz, 25 kHz steps | Use a frequency net; never substitute an ordinary channel number. |
| Unknown radio or vehicle rack | Unmanaged | Unknown | WMP preserves it. Register a tested carried-radio profile rather than guessing. |

The shipped families are `PRC_LR`, `BF888`, `SEM52`, `LEGACY_VHF` and the separate PRC-343 block
system. A net remains valid when at least one radio in that family supports its value. Validation
then checks each actual group/player assignment against the selected radio. This permits, for
example, a higher PRC-152/117F channel while clearly rejecting that same net on a PRC-148 whose
32-channel capacity is too small. A legacy frequency that does
not fit both PRC-77 and SEM70 range/step rules.

## Groups, duplicate radios and ears

A group is `[editor group ID, PRC-343 assignment, radio defaults, occurrence overrides]`:

```sqf
[
    "VIKING-2-3", // 0: groupId set for this squad in Eden Editor.
    [2, 3],         // 1: explicit PRC-343 Block 2, Channel 3. Use [] for automatic inference.
    [               // 2: defaults apply to every carried occurrence of each listed class.
        ["ACRE_PRC148", "PLT1", "RIGHT"],
        ["ACRE_PRC152", "PLT1", "RIGHT"],
        ["ACRE_PRC117F", "PLT1", "CENTER"]
    ],
    [               // 3: overrides change one same-type occurrence.
        ["ACRE_PRC152", 2, "AIRGND", "LEFT"] // only the second PRC-152 differs.
    ]
]
```

The example gives every carried PRC-152 PLT1/right-ear as its baseline, then changes only the second
PRC-152 to AIRGND/left-ear. Overrides are one-based within that base class and are skipped when that
occurrence is absent. A radio class with neither a default nor an occurrence override remains
untouched; there is no hidden priority or “next compatible net” behaviour.

`LEFT`, `RIGHT` and `BOTH`/`CENTER` are independent per occurrence. An empty PRC-343 field requests deterministic callsign allocation. Two valid numeric callsign components are interpreted as block/channel; otherwise WMP hashes the callsign and probes collisions deterministically. Explicit slots always win and invalid explicit values are rejected rather than clamped.

## Side-scoped player overrides

Overrides are `[side, selector, mode, assignments]`. `MERGE` replaces matching `[class, occurrence]`
identities while retaining group defaults and other overrides. `REPLACE` discards both group defaults
and occurrence overrides before applying its list.

```sqf
["WEST", ["ROLE", "JTAC"], "MERGE", [
    ["ACRE_PRC152", 1, "AIRGND", "RIGHT"]
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

ACRE's `setupRadios` frequency path is asynchronous and exposes no public frequency read-back. WMP validates the request and records it as pending/unverified; the audit requires checking the physical PRC-77/SEM70 interface. It refuses frequency setup when same-type rack/external radios make ACRE's occurrence order ambiguous.

## Diagnostics and testing

The CEOI is generated from the compiled plan and lists each named net once, the current group's
PRC-343 assignment, and live channel highlights where ACRE provides read-back. Diagnostics report
unknown families, incompatible group assignments, channel-capacity failures, invalid frequency
ranges/steps, missing radio occurrences, ACRE readiness and conflicting Eden radio attributes.
Frequency entries remain request-based rather than falsely described as read-back verified.

The full audit mission distributes every supported carried radio among playable squad members, with at least one same-class partner. Its ACRE station tests duplicate radios, independent ears, named non-channel-1 assignments, PRC-77/SEM70 requests, filtered loadout respawn, Babel and preserved extra radios. Legacy functions remain manual emergency fallbacks only.

## Group callsign fallback

ACRE assignments match the group's live `groupId`, not merely the text shown in an Eden unit slot.
WMP therefore checks the group leader's role description on the server before compiling the radio
plan. If it contains an explicit suffix such as:

```text
Squad Leader@VIKING-1-1
```

WMP globally sets that group's callsign to `VIKING-1-1` and verifies the read-back. This covers the
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
