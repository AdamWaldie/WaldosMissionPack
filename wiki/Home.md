# Waldos Mission Pack Wiki

> **Use this page when:** you are choosing where to begin or looking for the main WMP feature areas.

![Waldos Mission Pack](https://github.com/AdamWaldie/WaldosMissionPack/blob/main/Pictures/loading.jpg?raw=true)

Waldos Mission Pack is an Arma 3 mission scripting framework for mission makers who want reliable logistics, mission flow, radio, Zeus, economy, interaction, and quality-of-life systems without rebuilding them for every operation. CBA and ACE are required; supported integrations include ACRE2, TFAR, Zeus Enhanced, and LAMBS.

## Start here

| What you want to do | Open this page |
|---|---|
| Install WMP in a mission | [Quickstart Guide](Quickstart-Guide) |
| Find a feature | [Feature Index](Feature-Tutorials) |
| Drop in a ready-made example instead of scripting from scratch | [Eden Compositions](Eden-Compositions) |
| Configure mission entry files | [Mission Configuration Reference](Mission-Configuration-Reference) |
| Set up or activate a feature | [Feature Setup and Activation](Feature-Setup-and-Activation) |
| Find a feature setting | [Feature Configuration Files](Feature-Configuration-Files) |
| Place or configure Zeus modules | [WMP Zeus Modules](Waldos-Mission-Pack-Zeus-Modules) |
| Translate Zeus setup into script | [Zeus and Script API Parity](Zeus-And-Script-API-Parity) |
| Diagnose a setup or runtime problem | [Mission Diagnostics](Mission-Diagnostics) |
| Have an AI assistant configure a feature for you | [Claude Mission Config Skill](Claude-Mission-Config-Skill) |
| Write or review WMP documentation | [Coding and Documentation Standards](Coding-Standards) |

## Main feature areas

### Mission flow and player UI

- [Safestart](Safestart) — preparation protection, countdown, go-live, and reset behavior.
- [ENDEX and After-Action Report](ENDEX-Script-&-Custom-End-Screen) — combat protection, AAR, and mission-end presentation.
- [Custom UI Notifications](Custom-UI-Notifications) — safe-zone-aware semantic notification cards.
- [Tasks and Objectives](Tasks-And-Objectives) — server-authoritative, JIP-safe mission objectives.
- [Custom 3D World Markers](Custom-3D-World-Markers) — JIP-safe labels and icons over objects or positions.

### Logistics and deployment

- [Logistics, Starter Crates, and Quartermaster](Logistics-System,-Starter-Crates-And-Quartermaster)
- [Loadout Saving and Respawn](Loadout-Saving-and-Respawn)
- [Mobile Command Post](Mobile-Command-Post-With-Integrated-Logistics-System)
- [Virtual Vehicle Depot](Virtual-Vehicle-Depot)
- [Vehicle Actions and Paradrop](Vehicle-Actions-&-Paradrop)
- [Transport Services](Transport-Services) — reusable AI helicopter/ground pickup and delivery
- [Vehicle Recovery and Squad Rally Points](Vehicle-Recovery-And-Squad-Rallies)

### Economy and base building

- [Economy Systems](Waldos-Economy-Systems) — Resource, Research, Build, Buy, and Ground Command.
- [Economy Setup and Configuration](Waldos-Economy-Systems-Setup-And-Configuration) — presets, scripted setup, and Zeus-to-script export.
- [Automatic ACE Fortify Setup](Automatic-ACE-Fortify-Setup)
- [Construction Objects](Construction-Objects)

### Electronic warfare and radio

- [Radio Jamming](Radio-Jamming) — ACRE2/TFAR interference, UAV effects, and Zeus controls.
- [EMP and Signal Trackers](Electronic-Warfare-EMP-And-Signal-Trackers)
- [ACRE2 Radio Setup](ACRE-2-Long-Range-Radio-Presetting)
- [ACRE2 Babel](ACRE2-Babel-Configuration)

### Games and field equipment

- [Waldos Mini Games](Waldos-Mini-Games) — the table-game and field-equipment hub.
- [Table Games](Waldos-Mini-Games-Table-Games) — twelve seated multiplayer games.
- [Interaction Procedures](Waldos-Mini-Games-Interaction-Challenges) — ten accessible equipment procedures.
- [Bomb Defusal](Bomb-Defusal) — pair any procedure with an authoritative explosive consequence.

### Optional and advanced systems

- [Complete Feature Catalogue](Feature-Catalogue) — the full pack inventory and default states.
- [Persistence](Persistence) — database-backed player state and registered-object save/restore via INIDBI2.
- [Optional Feature Systems](Optional-Feature-Systems) — treatment feedback, obituary and confirmed-death reporting, hazards, tree felling, emergency dismount, WMP HUD, breaching, and object transforms.
- [Optional Feature Extensions](Optional-Feature-Extensions) — field resupply, tactical displays, advanced controls, and engine boundaries.
- [Dynamic Anti-Air](Dynamic-Anti-Air) — reusable radar-controlled air-defence zones for scripts and Zeus.
- [Dynamic AO Generation](Dynamic-AO-Generation) — server-owned randomized areas of operations created during play.
- [Airborne Gunship Support](Airborne-Gunship-Support) — controller-operated gunships with configurable orbits and service cycles.
- [Performance and Optimisation Audit](Performance-And-Optimisation-Audit) — CI guardrails and runtime verification guidance.

### AI and mission-maker tools

- [Waldo's AI Tuning](Waldos-AI-Tweak)
- [AI Convoy System](AI-Convoy-System)
- [Mission-Maker Resource Scripts](Mission-Maker-Resource-Scripts)
- [Coding and Documentation Standards](Coding-Standards)

## Requirements

| Type | Add-ons |
|---|---|
| Required | CBA_A3, ACE 3 |
| Supported | ACRE2, TFAR, Zeus Enhanced and compatibility add-ons, LAMBS series |

Features that depend on an optional add-on remain dormant when that integration is not loaded unless their page states otherwise.

## Project aim

WMP is intended to be approachable enough for a new mission maker and transparent enough for an experienced author to inspect, adapt, and extend. Public setup calls, configuration, locality, diagnostics, and known limitations are documented so a mission does not depend on unexplained editor state.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
