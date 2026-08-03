# ACRE2 Communications Configuration

> **Use this page when:** you need deterministic carried-radio assignments, independent duplicate radios, named displays, CEOI or side-isolated ACRE2 presets.

Associated files: `MissionConfig\acreConfig.sqf` and `MissionScripts\MissionInit\ACRE2\acre2*.sqf`.

All active authoring lives in `MissionConfig\acreConfig.sqf`. Pre-init validates configuration, registers Babel and changes only supported preset label fields. `initServer.sqf` publishes one versioned side/group plan for JIP. `initPlayerLocal.sqf` waits with a deadline and configures only the local player's carried radios. Do not add ACRE waits or mutable radio defaults to multiplayer `init.sqf`.

Set root `enabled` to `false` to disable the replacement lifecycle completely. `strict = true` rejects explicit PRC-343 collisions; with strict mode off those collisions are retained but reported as warnings. `prc343PresetPolicy = "FULL_RANGE"` preserves all sixteen PRC-343 blocks for every side without changing the side presets used by the other radios. `SIDE_ISOLATED` opts into ACRE's five-block combat-side PRC-343 presets when cross-side frequency separation is worth the reduced capacity. `retuneOnGroupChange` is deliberately false by default. A CBA group-change event rebuilds the CEOI, but radios are retuned only when that switch is enabled.

## Nets, groups and explicit radios

Each side entry is `[side, existing ACRE preset, nets, groups]`. Side aliases `BLUFOR`, `OPFOR`, `INDEPENDENT` and `CIVILIAN` are accepted, but the compiled plan uses `WEST`, `EAST`, `GUER` and `CIV`. Presets remain `default3`, `default2`, `default4` and `default` respectively.

```sqf
["WEST", "default3", [
    ["PLT1", "PLATOON 1", []],
    ["AIRGND", "AIR-GND", []]
], [
    ["VIKING-1-1", ["PLT1", "AIRGND"], [1, 1], [
        ["ACRE_PRC343", 1, [1, 1], "LEFT"],
        ["ACRE_PRC343", 2, [1, 2], "RIGHT"],
        ["ACRE_PRC152", 1, "PLT1", "RIGHT"],
        ["ACRE_PRC152", 2, "AIRGND", "LEFT"]
    ]]
]]
```

A group is `[normalised group ID, fallback net keys, fallback PRC-343 assignment, explicit radio assignments]`. Each explicit radio assignment is:

```text
[base radio class, same-type occurrence, target, ear]
```

- Occurrence is one-based: `1` is the first radio of that base class, `2` the second.
- A numbered-channel target may be a logical net key or direct channel.
- A PRC-343 target is `[block, channel]`. Channel and block are both 1–16 under the default `FULL_RANGE` policy. `SIDE_ISOLATED` reduces WEST/EAST/GUER to blocks 1–5. Validation follows the policy and rejects values ACRE would otherwise silently clamp.
- A manual-frequency target may be a logical net with a class-specific override or a direct MHz value/`[MHz, kHz]` pair.
- Ear is `LEFT`, `RIGHT`, `BOTH` or `CENTER`. `BOTH` is converted to ACRE's API value `CENTER`.

Only explicitly listed occurrences are managed. Additional identical, captured or unsupported radios remain untouched. When the explicit list is empty, the simple fallback manages one PRC-343 and assigns successive supported carried radios to the group's ordered net list. Radios beyond those available net slots remain untouched and are shown as preserved in diagnostics.

WMP does not set or restore alternate PTT assignments. It also does not force volume, speaker mode, current radio or audio source during ordinary mission-plan application. Those remain player preferences.

## Player and role overrides

`radioOverrides` can replace the current group's explicit list for one player. First match wins:

```sqf
["radioOverrides", [
    [["UID", "7656119..."], [["ACRE_PRC152", 1, "COY", "RIGHT"]]],
    [["VARIABLE", "jtac_1"], [["ACRE_PRC152", 1, "AIRGND", "RIGHT"]]],
    [["ROLE", "JTAC"], [["ACRE_PRC152", 1, "AIRGND", "RIGHT"]]]
]]
```

`ROLE` compares the unit's role-description text before an optional `@` suffix. Overrides affect radio assignment only; Babel retains its separate UID/editor-variable overrides.

## Radio profiles

A profile is `[base class, mode, default ear sequence, maximum channel, frequency range]`. The ear sequence is used by simple fallback allocation; explicit assignments can override it per occurrence. Numbered-channel profiles use an empty frequency range. Manual-frequency profiles use `[minimum MHz, maximum MHz, step kHz, ACRE pair divisor]`, allowing validation to reject values the physical radio cannot tune. The divisor accounts for ACRE's model-specific pair encoding: PRC-77 uses 100 while SEM70 uses 1000. Mission makers may supply a clear decimal MHz value; WMP converts it to the correct pair.

- PRC-343: `BLOCK_CHANNEL`.
- PRC-148: `CHANNEL`, 32 preset channels.
- PRC-152 and PRC-117F: `CHANNEL`, 100 preset channels each.
- BF-888S: `CHANNEL`, 16 preset channels.
- SEM52SL: `CHANNEL`, 13 preset channels.
- PRC-77 and SEM70: `FREQUENCY`, applied through ACRE's public `acre_api_fnc_setupRadios` when available.
- Unknown or third-party carried radios: untouched until a tested profile is registered.
- Vehicle racks and externally shared radios: intentionally filtered out even though ACRE's broad current-radio API can expose them. Rack ownership and initialization are server/vehicle scoped.

Frequency assignments for repeated same-type radios must be contiguous from occurrence one because ACRE's public setup API addresses repeated radios in order. PRC-77 values tune from 30 to 75.95 MHz in 50 kHz steps; SEM70 values tune from 30 to 79.975 MHz in 25 kHz steps. Each logical net may carry separate PRC-77 and SEM70 overrides while still sharing one net key with numbered radios. The shipped WEST example includes both override types.

ACRE's frequency setup API is asynchronous and has no public frequency getter. WMP can validate the requested value, occurrence order and accepted setup call, but cannot immediately prove the final dial frequency through the public API. It records only frequencies it requested for persistence and the audit requires a physical-radio check. The API also sees racks and external radios; WMP refuses a frequency write when an accessible same-type non-carried radio would make occurrence ambiguous. If the installed ACRE version lacks the API, WMP leaves those radios unchanged and reports the failure rather than attempting private data writes.

## Named displays

WMP modifies only official display-name fields in existing side presets: `label` for PRC-148, `description` for PRC-152 and `name` for PRC-117F. It never copies presets or rewrites TX/RX frequencies. Names are upper-case, restricted to safe display characters and capped at 12 characters. Every write is read back and TX/RX values are compared before and after.

Named labels belong to a preset channel, not a physical radio. Different physical radios on different channels display their respective channel labels; a name cannot be unique per physical radio independently of its preset channel.

## Diagnostics and testing

The CEOI contains both the authoritative plan and the most recent verified local application: radio class/occurrence, resolved setting, ear, missing assignments and preserved radios. API failures are logged and manual/QA applications can show a WMP warning card.

`MissionConfig\acreConfig.sqf` contains a commented, copyable assignment library for every shipped
profile: duplicate PRC-343 block/channel rows, PRC-148/152/117F/BF-888S/SEM52SL net rows,
PRC-77/SEM70 net and direct-frequency rows, a complete group row, and UID/variable/role overrides.

The full audit mission gives every playable squad member at least one same-class radio partner.
Commander and Medic share duplicate PRC-343/152 sets plus PRC-148s; Anti-Tank and Engineer share
PRC-117F, BF-888S, SEM52SL, PRC-77 and SEM70; Marksman bridges those pairs with a PRC-343 and
PRC-117F. The assigned channels are deliberately not channel 1. The ACRE2 station can display this
pair matrix, verify independent channels/ears, inspect the ordered unique-radio list and perform a
persisted-state round trip. The previous implementation remains available only through explicit
`_Legacy` functions.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
