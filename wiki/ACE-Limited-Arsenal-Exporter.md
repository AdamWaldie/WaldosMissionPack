# ACE Limited Arsenal Exporter

> **Use this page when:** you want a starting item list for a hand-curated ACE Arsenal.

The exporter reads the current loadouts of BLUFOR units and copies the distinct item class strings to your local clipboard. Use it while making the mission. It does not set up an arsenal or run automatically when players join.

## Quick setup in a test mission

1. Give BLUFOR units the loadouts you want to inspect. The shipped script reads `units blufor`, including non-playable BLUFOR units, so remove unwanted units before exporting.
2. Start the mission and open the debug console on your client.
3. Run the call below with **Local Execute**. Paste the copied array somewhere you can review it before adding it to a crate.

```sqf
[] execVM "MissionScripts\MissionMakerResourceScripts\ToolkitAceLimitedArsenal.sqf";
```

The script copies class strings, not magazine counts or a complete `CfgWeapons` policy. Review the list before using it as an arsenal allow-list.

## Script call and result

| Input | Type | Default | Effect |
| --- | --- | --- | --- |
| Arguments | None | None | The script collects `units blufor` on the machine running it. |
| Execution | `execVM` call | Manual | Runs locally and returns an Arma Script handle immediately. |
| Clipboard result | Array of class-name Strings | None before execution | The local clipboard receives the distinct strings found in those loadouts. |

To initialise a limited ACE Arsenal after checking the copied list, put a call like this in the crate's Eden Init field. Replace the sample names with the actual exported classes:

```sqf
[this, ["item1", "item2"]] call ace_arsenal_fnc_initBox;
```

This ACE call is separate from the exporter. The exporter's clipboard result is local and is not published to clients or replayed to joining players.

## If the exported list is wrong

Check which units belong to BLUFOR in the running mission. The script does not filter for playable slots. Run it again after correcting their loadouts, then review the new clipboard text before changing a live arsenal.

## See also

- [Starter Crates and Supply Crates](Logistics-System,-Starter-Crates-And-Quartermaster)
- [Mission-Maker Resource Scripts](Mission-Maker-Resource-Scripts)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
