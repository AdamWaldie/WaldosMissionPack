# Mission-Maker Resource Scripts

> **Use this page when:** you need to find one of WMP's optional mission-making and debug scripts.

These four files serve different jobs. None is a player-facing WMP system, and none starts automatically. Pick the guide for the tool you need. Do not place all four in mission startup simply because they share a folder.

## Quick setup: choose one tool

| Tool | Use it for | Runs on |
| --- | --- | --- |
| [ACE Limited Arsenal Exporter](ACE-Limited-Arsenal-Exporter) | Copying class strings from BLUFOR loadouts for a curated arsenal | A mission maker's local debug session |
| [Vehicle Damage Monitor](Vehicle-Damage-Monitor) | Watching hit-point damage on the vehicle under your cursor | A mission maker's local debug session |
| [Example Unhiding Script](Example-Unhiding-Script) | Adapting a group-reveal pattern for a server trigger | The server after you edit the group names |
| [Mod Config Patch Logger](Mod-Config-Patch-Logger) | Finding a loaded addon's `CfgPatches` class | A mission maker's local debug session |

## Script calls and common behaviour

| Input | Type | Default | Result |
| --- | --- | --- | --- |
| Call arguments | None | None | Each file reads its own local context or edited group names. |
| `execVM` result | Arma Script handle | Manual call only | The handle means the script started, not that its work succeeded. |
| Feature toggle | None | Off until called | These are optional aids, not automatic services. |

Follow the linked guide for the exact call, output and limitations of each file. A debug-console script runs on the machine that executes it. The group-reveal template needs a server-owned trigger because it changes shared objects.

## If a tool does not work

First check that you used the guide for the specific file. The exporter reads BLUFOR units, and the damage monitor reads your cursor target. The reveal template needs your group variables. The patch logger writes to the current machine's `.rpt`.

## See also

- [Feature Index](Feature-Tutorials)
- [Mission Diagnostics](Mission-Diagnostics)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
