# ACRE2 Communications Configuration

> **Use this page when:** you need deterministic carried-radio assignments, independent duplicate radios, named displays, CEOI or optional Babel support.

Associated files: `MissionConfig\acreConfig.sqf` and `MissionScripts\MissionInit\ACRE2\acre2*.sqf`.

All mission authoring lives in `MissionConfig\acreConfig.sqf`. WMP validates it at pre-init, the server broadcasts one versioned side/group plan for JIP, and each interface client configures only its local carried radios after ACRE is ready. Do not add ACRE waits or authoritative defaults to multiplayer `init.sqf`.

## Settings to edit

- `enabled`: master switch for the replacement lifecycle.
- `prc343PresetPolicy`: `FULL_RANGE` keeps 16 blocks but gives no side isolation; `SIDE_ISOLATED` uses ACRE's combat-side presets and five blocks.
- `namedDisplays`: labels supported PRC-148/152/117F channels without changing frequencies.
- `sides`: official side preset, nets and editor-group rows.
- `radioOverrides`: exceptional per-player assignment changes.
- `babel`: language definitions and assignments; shipped examples remain disabled.

Leave `version`, `strict` and `additionalRadioProfiles` alone unless extending or diagnosing the framework. WMP deliberately leaves PTT, volume, speaker mode and current-radio preference under player control. It does not poll, periodically reapply, or retune radios on group changes.

## Nets describe real radio tunings

A net is `[key, label, tunings]`. Each tuning is `[base radio class, target]`:

```sqf
["PLT1", "PLATOON 1", [
    ["ACRE_PRC148", 2],
    ["ACRE_PRC152", 2],
    ["ACRE_PRC117F", 2]
]],
["BF_LOCAL", "LOCAL BF", [["ACRE_BF888S", 4]]],
["SEM_LOCAL", "LOCAL SEM", [["ACRE_SEM52SL", 4]]],
["LEGACY", "LEGACY", [["ACRE_PRC77", 34.000], ["ACRE_SEM70", 34.000]]]
```

A shared net key is meaningful only when its tunings are interoperable. The official PRC-148/152/117F presets use matching frequencies at matching channel numbers. BF-888S and SEM52SL occupy different bands and therefore use separate local nets. PRC-77 and SEM70 can share an explicit common frequency. There is no global net count or smallest-radio capacity limit.

Built-in limits are PRC-148 32 channels, PRC-152/117F 100, BF-888S 16 and SEM52SL 12 ordinary channels. PRC-77 tunes 30–75.95 MHz in 50 kHz steps; SEM70 tunes 30–79.975 MHz in 25 kHz steps. Unknown radios and vehicle racks are preserved.

## Groups, duplicate radios and ears

A group is `[editor group ID, ordered fallback nets, PRC-343 assignment, explicit templates]`:

```sqf
["VIKING-1-1", ["PLT1", "AIRGND"], [], [
    ["ACRE_PRC343", 1, [5, 16], "LEFT"],
    ["ACRE_PRC343", 2, [6, 3], "RIGHT"],
    ["ACRE_PRC152", 1, "PLT1", "RIGHT"],
    ["ACRE_PRC152", 2, "AIRGND", "LEFT"],
    ["ACRE_PRC117F", 1, "AIRGND", "BOTH"]
]]
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

One debounced helper owns initial join, JIP, respawn and player-object replacement. A later event cancels an earlier waiter. It waits with a deadline for ACRE, the complete server plan and any persistence restore, then applies the plan, Babel and CEOI once.

Saved loadouts always pass through `acre_api_fnc_filterUnitLoadout`. Never save or restore an `_ID_n` radio classname: [duplicate unique IDs are a documented cause of respawn failures](https://github.com/IDI-Systems/acre2/issues/1163). Radio state is stored separately by base class and same-type occurrence. Normal respawn applies the current mission plan; enabled persistence restores saved state first and suppresses baseline retuning for that loadout generation.

ACRE's `setupRadios` frequency path is asynchronous and exposes no public frequency read-back. WMP validates the request and records it as pending/unverified; the audit requires checking the physical PRC-77/SEM70 interface. It refuses frequency setup when same-type rack/external radios make ACRE's occurrence order ambiguous.

## Diagnostics and testing

The CEOI is generated from the compiled plan and lists every net's radio-specific tuning, the current group's PRC-343 assignment, applied occurrences/ears, failures and preserved radios. Frequency entries are explicitly request-based rather than falsely described as read-back verified.

The full audit mission distributes every supported carried radio among playable squad members, with at least one same-class partner. Its ACRE station tests duplicate radios, independent ears, named non-channel-1 assignments, PRC-77/SEM70 requests, filtered loadout respawn, Babel and preserved extra radios. Legacy functions remain manual emergency fallbacks only.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
