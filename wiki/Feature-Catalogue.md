# Feature Catalogue

> **Use this page when:** you want a complete inventory of WMP systems, their default states, and their primary setup paths.

This is the complete top-level index of mission systems currently supplied by WaldosMissionPack. Follow the linked guide for setup, configuration, runtime controls and known engine boundaries.

## Recently integrated full systems

| Feature | What it provides | Primary setup and operation |
|---|---|---|
| [INIDBI2 Persistence](Optional-Feature-Systems#persistence) | Optional player and registered-object persistence with a server-runtime dependency gate | Shared settings in `init.sqf`; database authority in `initServer.sqf`; **Persistence - Control**, **Register Object**, and **Save Now** in ZEN |
| [Patient Treatment Feedback](Optional-Feature-Systems#patient-treatment-feedback) | Local ACE treatment start, completion and failure notifications using the pack notification UI | Player settings in `initPlayerLocal.sqf`; **Treatment Feedback - Control** in ZEN |
| [Hazardous Environments](Optional-Feature-Systems#hazardous-environments) | Repeatable contamination, toxic, temperature, vacuum/no-oxygen and callback-driven zones | Shared presets in `init.sqf`; scripted registration or ZEN create/remove modules |
| [Tree Felling](Optional-Feature-Systems#tree-felling) | Axe/hatchet-driven tree replacement, brush clearing, yields, protected areas and optional regrowth | Shared settings in `init.sqf`; **Tree Felling - Control** in ZEN |
| [Emergency Dismount](Optional-Feature-Systems#emergency-dismount) | Local extraction from overturned or destroyed vehicles with configurable safety rules | Player settings in `initPlayerLocal.sqf`; **Emergency Dismount - Control** in ZEN |
| [Accessibility PID](Optional-Feature-Systems#friendly-identification-accessibility-aid) | Allowlisted, friendly-only identification icons and names with LOS and visibility controls | Eligibility and presentation in `initPlayerLocal.sqf`; **Accessibility PID - Control** in ZEN |
| [Explosive Wall Breaching](Optional-Feature-Systems#explosive-wall-breaching) | Server-validated class profiles, explosive strengths, replacement sections and reset support | Shared profiles in `init.sqf`; scripted calls or **Breaching - Configure Class** in ZEN |
| [Object Scaling and Transforms](Optional-Feature-Systems#object-scaling) | Validated scaling, reset/copy/multiply, coordinate placement and tagged batches | Server limits in `initServer.sqf`; scripted helpers or **Scale Object** in ZEN |
| [AI Rebalance](Waldos-AI-Tweak) | Named skill profiles, filters, variance, restoration and AI-locality migration handling | Shared settings in `init.sqf`; **AI Rebalance - Control** in ZEN |
| [Field Resupply](Optional-Feature-Extensions#field-resupply) | Finite hub stock, carrier allowances, deployed ammunition crates and salvage | Shared settings in `init.sqf`; ZEN hub/carrier modules |
| [Tactical Display](Optional-Feature-Extensions#tactical-display) | Object-authenticated local tactical map with friendly and known-enemy filtering | Player display settings in `initPlayerLocal.sqf`; scripted or ZEN registration |
| [Dynamic Anti-Air](Dynamic-Anti-Air) | Named radar-controlled AA zones, altitude rules, dormant defences and fighter scrambling | Server side/faction pools in `initServer.sqf`; scripted creation or guided ZEN placement |
| [Airborne Gunship Support](Airborne-Gunship-Support) | Named gunship lifecycles, controller assignment, turret control, orbits and service cycles | Shared defaults in `init.sqf`; server registration or focused ZEN operations |
| [Vehicle Recovery](Vehicle-Recovery-And-Squad-Rallies#vehicle-recovery) | Damage-gated packaging, recovery carriers and keyed workshops that restore vehicle configuration | Scripted object registration or three focused ZEN registration modules |
| [Squad Rally Points](Vehicle-Recovery-And-Squad-Rallies#squad-rally-points) | Temporary group-owned respawn positions with hostile, terrain, membership, expiry and cooldown rules | Shared settings in `init.sqf`; squad-leader actions or runtime ZEN control |

Runtime configuration is server-authoritative. Current settings are published for connected and JIP players, while keyed JIP initialisers install or remove the required local behavior. AI and breaching remain all-machine systems because their engine locality can move between server, player clients and headless clients.

## Mission flow and player experience

- [Mission Intro Text](Mission-Intro-Or-Title-Text)
- [Mission UI Text Overlays](Mission-UI-Text-Overlays)
- [ENDEX and After-Action Report](ENDEX-Script-&-Custom-End-Screen)
- [Safestart](Safestart)
- [Tasks and Objectives](Tasks-And-Objectives)
- [Team Colour Setup](Team-Colour-Setup)
- [Radio Reports, Checklists and Support Calls](Radio-Reports,-Checklists,-Support-Calls-And-Documentation)

## Logistics, deployment and vehicles

- [Logistics, Starter Crates and Quartermaster](Logistics-System,-Starter-Crates-And-Quartermaster)
- [Loadout Saving and Respawn](Loadout-Saving-and-Respawn)
- [Mobile Command Post](Mobile-Command-Post-With-Integrated-Logistics-System)
- [Vehicle Actions and Paradrop](Vehicle-Actions-&-Paradrop)
- [Vehicle Ambush and Camo](Vehicle-Ambush-Script-And-Vehicle-Camo)
- [Teleportation and Move Into Cargo](Teleportation-&-Move-Into-Cargo-Interactions)
- [Virtual Vehicle Depot](Virtual-Vehicle-Depot)
- [Weapon Mounting](Weapon-Mounting-With-Custom-Name)

## Economy, construction and games

- [Waldos Economy Systems](Waldos-Economy-Systems)
- [Construction Objects](Construction-Objects)
- [Automatic ACE Fortify Setup](Automatic-ACE-Fortify-Setup)
- [Simple Mass Attach Items](Simple-Mass-Attach-Items)
- [Waldos Mini Games](Waldos-Mini-Games)
- [Table Games](Waldos-Mini-Games-Table-Games)
- [Interaction Challenges](Waldos-Mini-Games-Interaction-Challenges)

## AI, radio and mission-maker tools

- [AI Convoy System](AI-Convoy-System)
- [Map Location Tools](Map-Location-Tools)
- [Optional Headless Client and Player Markers](Third-Party-Scripts-Headless-Client-And-Player-Markers)
- [ACRE 2 Long-Range Presetting](ACRE-2-Long-Range-Radio-Presetting)
- [ACRE 2 Short-Range Presetting](ACRE-2-Squad-Level-Radios-AN-PRC%E2%80%90343-Automatic-Setup)
- [ACRE 2 Automated CEOI](ACRE2-Automated-CEOI-Document)
- [ACRE 2 Babel Configuration](ACRE2-Babel-Configuration)
- [Mission Diagnostics](Mission-Diagnostics)
- [Mission Maker Resource Scripts](Mission-Maker-Resource-Scripts)
- [Unit Insignias](Unit-Insignias)
- [Cover and Loading Screen Generation](Cover-Loading-Screen-Generation)

## Configuration and runtime operation

- [Quickstart Guide](Quickstart-Guide)
- [Mission Configuration Reference](Mission-Configuration-Reference)
- [Waldos Mission Pack Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)
- [Optional Feature Systems](Optional-Feature-Systems)
- [Optional Feature Extensions and Engine Boundaries](Optional-Feature-Extensions)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
