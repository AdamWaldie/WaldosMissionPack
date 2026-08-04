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

A **net** is simply a named radio conversation, such as Platoon, Company or Air-to-Ground. The net
tells WMP which channel each supported radio must use to join that conversation.

A net is `[key, label, tunings]`. Each tuning is `[base radio class, target]`:

```sqf
[
    "PLT1",      // 0: short internal name used elsewhere in this config.
    "PLATOON 1", // 1: name players see on supported radio displays and in the CEOI.
    [             // 2: channel used by each radio type.
        ["ACRE_PRC148", 2], // PRC-148 uses channel 2 for PLATOON 1.
        ["ACRE_PRC152", 2], // PRC-152 uses channel 2 for PLATOON 1.
        ["ACRE_PRC117F", 2] // PRC-117F uses channel 2 for PLATOON 1.
    ]
]
```

The result is straightforward: a player assigned to `PLT1` who carries any listed radio starts on
that radio's channel 2. A radio not listed in this net cannot use this net and is left for the next
compatible net or left unchanged.

A shared net key is meaningful only when its tunings are interoperable. The official PRC-148/152/117F presets use matching frequencies at matching channel numbers. BF-888S and SEM52SL occupy different bands and therefore use separate local nets. PRC-77 and SEM70 can share an explicit common frequency. There is no global net count or smallest-radio capacity limit.

Built-in limits are PRC-148 32 channels, PRC-152/117F 100, BF-888S 16 and SEM52SL 12 ordinary channels. PRC-77 tunes 30–75.95 MHz in 50 kHz steps; SEM70 tunes 30–79.975 MHz in 25 kHz steps. Unknown radios and vehicle racks are preserved.

## Groups, duplicate radios and ears

A group is `[editor group ID, ordered fallback nets, PRC-343 assignment, explicit templates]`:

```sqf
[
    "VIKING-1-1",      // 0: exact groupId set for this squad in Eden Editor.
    ["PLT1", "AIRGND"], // 1: preferred nets, checked from left to right.
    [],                 // 2: empty means automatically assign the first PRC-343 from the groupId.
    [                   // 3: optional exact assignments for individual carried radios.
        ["ACRE_PRC343", 1, [5, 16], "LEFT"], // first PRC-343 -> block 5/channel 16 -> left ear.
        ["ACRE_PRC343", 2, [6, 3], "RIGHT"], // second PRC-343 -> block 6/channel 3 -> right ear.
        ["ACRE_PRC152", 1, "PLT1", "RIGHT"], // first PRC-152 -> PLT1 -> right ear.
        ["ACRE_PRC152", 2, "AIRGND", "LEFT"] // second PRC-152 -> AIRGND -> left ear.
    ]
]
```

The occurrence is one-based within that base class. Templates apply only when the occurrence exists, so one squad row can cover different role loadouts without reporting missing radios. An empty explicit list assigns each supported carried radio to the first compatible group net; repeated radios take successive compatible nets. Unmatched and captured radios remain untouched.

`LEFT`, `RIGHT` and `BOTH`/`CENTER` are independent per occurrence. An empty PRC-343 field requests deterministic callsign allocation. Two valid numeric callsign components are interpreted as block/channel; otherwise WMP hashes the callsign and probes collisions deterministically. Explicit slots always win and invalid explicit values are rejected rather than clamped.

## Side-scoped player overrides

Overrides are `[side, selector, mode, assignments]`. `MERGE` replaces matching `[class, occurrence]` identities and retains other group rows. `REPLACE` starts with an empty list.

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

The CEOI is generated from the compiled plan and lists every net's radio-specific tuning, the current group's PRC-343 assignment, applied occurrences/ears, failures and preserved radios. Frequency entries are explicitly request-based rather than falsely described as read-back verified.

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
