# ACRE2 PRC-343 Assignment

> **Use this page when:** you need repeatable PRC-343 block/channel allocation by side and group.

PRC-343 assignments come from `MissionConfig\acreConfig.sqf`. The server sends the completed setup
to players, while each player's own computer configures the radio they carry. Side and group ID are
both used, so identical callsigns on opposing sides do not overwrite one another.

The group's simple fallback uses `[block, channel]` and reserves its slot before automatic allocation:

```sqf
[
    "VIKING-1-1", // 0: exact Eden groupId for the squad.
    ["PLT1"],      // 1: preferred named nets for other supported radios.
    [1, 1],        // 2: first PRC-343 starts on block 1, channel 1.
    []             // 3: no additional per-radio assignments.
]
```

Replace `[1, 1]` with `[]` if WMP should choose the PRC-343 block/channel automatically from the
groupId.

To manage more than one PRC-343 independently, use same-type occurrence assignments:

```sqf
[
    "VIKING-1-1", ["PLT1"], [], [
        ["ACRE_PRC343", 1, [1, 1], "LEFT"],  // first PRC-343 -> B1/C1 -> left ear.
        ["ACRE_PRC343", 2, [1, 2], "RIGHT"]  // second PRC-343 -> B1/C2 -> right ear.
    ]
]
```

Only listed occurrences are changed. A third or captured PRC-343 remains untouched. Ear accepts `LEFT`, `RIGHT`, `BOTH` or `CENTER`; `BOTH` becomes ACRE `CENTER`.

Both values must be between 1 and 16. Invalid assignments are rejected. With strict validation enabled, collisions are rejected; with strict mode disabled, they are retained and clearly reported. For groups without an override, two numeric callsign components become block/channel, a single numeric component becomes the channel within the callsign prefix's deterministic block, and a callsign without numbers receives the first free channel in that block.

The client converts the pair to ACRE's flat channel only when it applies a unique PRC-343 radio ID. The default `prc343PresetPolicy = "FULL_RANGE"` deliberately assigns the PRC-343 `default` preset on every side, exposing B1–B16 while leaving long-range radios on their normal side presets. Set the policy to `SIDE_ISOLATED` only when side-separated PRC-343 frequencies are required; WEST `default3`, EAST `default2`, and Independent `default4` then expose B1–B5. The CEOI continues to show the clearer block/channel form, and WMP rejects out-of-range blocks before ACRE can silently clamp them.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
