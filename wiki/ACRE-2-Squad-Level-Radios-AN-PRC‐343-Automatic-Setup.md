# ACRE2 PRC-343 Assignment

> **Use this page when:** you need repeatable PRC-343 block/channel allocation by side and group.

PRC-343 assignments come from `MissionConfig\acreConfig.sqf`. The server sends the completed setup
to players, while each player's own computer configures the radio they carry. Side and group ID are
both used, so identical callsigns on opposing sides do not overwrite one another.

Every carried radio uses `[class, "ALL" or occurrence number, target, ear]`. For one PRC-343:

```sqf
[
    "VIKING 2-3", // 0: Eden groupId for the squad.
    [              // 1: radio assignment rows.
        ["ACRE_PRC343", "ALL", [2, 3], "LEFT"] // every carried 343 uses B2/C3 in the left ear.
    ]
]
```

Replace `[2, 3]` with `[]` if WMP should infer Block 2/Channel 3 from `VIKING 2-3`.

To manage more than one PRC-343 independently, use same-type occurrence assignments:

```sqf
[
    "VIKING 2-3", [
        ["ACRE_PRC343", 1, [2, 3], "LEFT"],  // first PRC-343 -> B2/C3 -> left ear.
        ["ACRE_PRC343", 2, [2, 4], "RIGHT"]  // second PRC-343 -> B2/C4 -> right ear.
    ]
]
```

Use `ALL` only when every PRC-343 has identical settings. If they differ, number each intended
radio as `1`, `2`, and so on. Mixing `ALL` and numbered rows for the same class is rejected because
it is ambiguous to a beginner. Unlisted occurrences remain untouched. Ear accepts `LEFT`, `RIGHT`,
`BOTH` or `CENTER`; `BOTH` becomes ACRE `CENTER`.

Both values must be between 1 and 16. Invalid assignments are rejected. With strict validation enabled, collisions are rejected; with strict mode disabled, they are retained and clearly reported. For a PRC-343 row whose target is `[]`, two numeric callsign components become block/channel, a single numeric component becomes the channel within the callsign prefix's deterministic block, and a callsign without numbers receives a deterministic free slot.

The client converts the pair to ACRE's flat channel only when it applies a unique PRC-343 radio ID. The default `prc343PresetPolicy = "FULL_RANGE"` deliberately assigns the PRC-343 `default` preset on every side, exposing B1–B16 while leaving long-range radios on their normal side presets. Set the policy to `SIDE_ISOLATED` only when side-separated PRC-343 frequencies are required; WEST `default3`, EAST `default2`, and Independent `default4` then expose B1–B5. The CEOI continues to show the clearer block/channel form, and WMP rejects out-of-range blocks before ACRE can silently clamp them.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
