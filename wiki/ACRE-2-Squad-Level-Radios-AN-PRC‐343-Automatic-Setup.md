# ACRE2 PRC-343 Assignment

> **Use this page when:** you need repeatable PRC-343 block/channel allocation by side and group.

PRC-343 assignments are compiled on the server from `MissionConfig\acreConfig.sqf` and broadcast in the versioned ACRE plan. The key is side plus normalised group ID, so identical callsigns on opposing sides cannot overwrite one another.

An explicit assignment uses `[block, channel]` and reserves its slot before automatic allocation:

```sqf
["VIKING-1-1", ["PLT1"], [1, 1]]
```

Both values must be between 1 and 16. Invalid or colliding explicit assignments are rejected; WMP never silently relocates them. For groups without an override, two numeric callsign components become block/channel, a single numeric component becomes the channel within the callsign prefix's deterministic block, and a callsign without numbers receives the first free channel in that block.

Acceptance boundaries include B1C16, B2C1, B12C1 and B16C16. The client converts the pair to ACRE's flat 1–256 channel only at the point it applies a unique PRC-343 radio ID. The CEOI continues to show the clearer block/channel form.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
