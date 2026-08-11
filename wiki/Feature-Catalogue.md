# Feature Catalogue

> **Use this page when:** you want a complete inventory of WMP systems, their default states, and their primary setup paths.

This is the complete top-level index of mission systems currently supplied by WaldosMissionPack. Follow the linked guide for setup, configuration, runtime controls and known engine boundaries.

## Recently integrated full systems

| Feature | What it provides | Primary setup and operation |
|---|---|---|
| [INIDBI2 Persistence](Persistence) | Optional player and registered-object persistence with a server-runtime dependency gate | `MissionConfig\persistenceConfig.sqf`; database authority in `initServer.sqf`; **Persistence - Control**, **Register Object**, and **Save Now** in ZEN |
| [Patient Treatment Feedback](Optional-Feature-Systems#patient-treatment-feedback) | Local ACE treatment start, completion and failure notifications using the pack notification UI | `MissionConfig\interfaceConfig.sqf` and scripted start/stop calls |
| [Hazardous Environments](Optional-Feature-Systems#hazardous-environments) | Repeatable contamination, toxic, temperature, vacuum/no-oxygen and callback-driven zones | `MissionConfig\environmentConfig.sqf`; scripted registration or ZEN create/remove modules |
| [Tree Felling](Optional-Feature-Systems#tree-felling) | Axe/hatchet-driven tree replacement, brush clearing, yields, protected areas and optional regrowth | Shared settings and scripted calls |
| [Emergency Dismount](Optional-Feature-Systems#emergency-dismount) | Local extraction from overturned or destroyed vehicles with configurable safety rules | `MissionConfig\interfaceConfig.sqf` or scripted start/stop calls; intentionally no ZEN module |
| [WMP HUD](WMP-HUD) | Friendly-only 3D identification with high-tech equipment eligibility and independent UID accessibility access | `MissionConfig\interfaceConfig.sqf`; WMP Interface self-interaction toggle; intentionally no ZEN module |
| [Colour-vision accessibility](UI-Visual-Themes#personal-colour-vision-profiles) | Personal semantic palettes retain state words, symbols, patterns and contrast under every era theme | Local persistent selector under ACE Self Interact > WMP Interface > Accessibility |
| [Explosive Wall Breaching](Optional-Feature-Systems#explosive-wall-breaching) | Server-validated class profiles, explosive strengths, replacement sections and reset support | `MissionConfig\environmentConfig.sqf` and scripted calls |
| [Object Scaling and Transforms](Optional-Feature-Systems#object-scaling) | Validated scaling, reset/copy/multiply, coordinate placement and tagged batches | Server limits in `MissionConfig\logisticsConfig.sqf`; scripted helpers or **Scale Object** in ZEN |
| [AI Rebalance](Waldos-AI-Tweak) | Named skill profiles, filters, variance, restoration and AI-locality migration handling | `MissionConfig\aiConfig.sqf`; **AI Rebalance - Control** in ZEN |
| [Improved AI Helicopter Landings](Improved-AI-Helicopter-Landings) | Exact-point vector approaches, flare, slope alignment, tree-canopy clearance, touchdown anchoring and bounded go-arounds for AI pilots | `MissionConfig\aiConfig.sqf`, per-aircraft profiles and event-driven locality handlers; intentionally no ZEN module |
| [UI Visual Themes](UI-Visual-Themes) | Visual-only DEFAULT, WW2, VIETNAM, SCIFI and PARCHMENT styling across WMP interface families | Global `Waldo_UI_Theme` in `MissionConfig\interfaceConfig.sqf`; live **UI QA - Set Visual Theme** selector |
| [Field Resupply](Optional-Feature-Extensions#field-resupply) | Finite hub stock, carrier allowances, deployed real-cargo crates and cargo-based salvage | `MissionConfig\logisticsConfig.sqf`; ZEN hub/carrier modules |
| [Tactical Display](Optional-Feature-Extensions#tactical-display) | Object-authenticated local tactical map with friendly and known-enemy filtering | `MissionConfig\interfaceConfig.sqf`; scripted or ZEN registration |
| [Dynamic Anti-Air](Dynamic-Anti-Air) | Named radar-controlled AA zones, altitude rules, dormant defences and fighter scrambling | Server side/faction pools in `MissionConfig\airOperationsConfig.sqf`; scripted creation or guided ZEN placement |
| [Dynamic AO Generation](Dynamic-AO-Generation) | Runtime faction discovery and complete randomized patrol, garrison, vehicle, air, civilian, minefield and roadblock areas | Server HashMap API or **Dynamic AO - Create/Remove** under WMP Combat Systems |
| [Airborne Gunship Support](Airborne-Gunship-Support) | Named gunship lifecycles, controller assignment, turret control, orbits and service cycles | `MissionConfig\airOperationsConfig.sqf`; server registration or focused ZEN operations |
| [Dynamic Paradrop Operations](Vehicle-Actions-&-Paradrop#dynamic-drop-zone-operations) | Player-focused server-owned drop routes with boarding, static-line/HALO actions, aligned repeat circuits, optional AI jumpers, markers and teardown | Pools and thresholds in `MissionConfig\airOperationsConfig.sqf`; scripted APIs or ZEN modules |
| [Vehicle Recovery](Vehicle-Recovery-And-Squad-Rallies#vehicle-recovery) | Damage-gated packaging, recovery carriers and keyed workshops that restore vehicle configuration | Scripted object registration or three focused ZEN registration modules |
| [Helicopter and Ground Transport](Transport-Services) | Reusable server-reserved AI transport pools with named management, physical pickup, destination, disembark and RTB lifecycles | Register AI-crewed vehicles by script or the focused WMP Logistics ZEN modules |
| [Squad Rally Points](Vehicle-Recovery-And-Squad-Rallies#squad-rally-points) | Temporary group-owned respawn positions with hostile, terrain, membership, expiry and cooldown rules | `MissionConfig\missionSystemsConfig.sqf`; squad-leader actions or runtime ZEN control |

Runtime configuration is server-authoritative. Current settings are published for connected and JIP players, while keyed JIP initialisers install or remove the required local behavior. AI and breaching remain all-machine systems because their engine locality can move between server, player clients and headless clients.

## Supporting integration changes

| Area | Current behavior | User impact |
|---|---|---|
| Runtime state and JIP | The server publishes ordered feature-setting bundles; players and headless clients request the current snapshot before installing locality-sensitive behavior | Mid-mission ZEN changes remain authoritative for current players and later joins |
| Global UI styling | One validated visual resolver supplies fonts, panels and semantic colours without forking feature logic | Mission era styling changes without changing authority, mechanics, geometry or controls |
| WMP notification UI | Treatment feedback, gunship, Dynamic AA, tree felling, field resupply, vehicle recovery, rally, persistence, emergency dismount and manual respawn-loadout saving use owned notification channels; breaching feedback is an explicit opt-in | Feature feedback no longer competes for Arma's shared hint display |
| Loadout scraping | `Waldo_fnc_MissionSQMLookup` recursively walks every Eden `Entities` collection and includes both `isPlayer` and `isPlayable` objects | Playable characters inside organiser folders and arbitrarily nested folders contribute to arsenals, starter crates and supply crates |
| Economy request handling | Authority requests share one scheduler and runtime objects use explicit registries | Correctness and cleanup improve without changing economy balance |
| UI and lifecycle cleanup | SafeStart, ENDEX, mini-games and optional systems remove only controls, protections and handlers they own | Repeated activation, reset, death and debriefing do not leave stale feature state |
| Verification | The checked-in full-pack audit mirrors release scripts and includes twenty repeatable physical stations for the recently integrated systems, including nested-folder playable loadout scraping and Dynamic AO generation; CI also checks SQF, configuration, drawn UI, ZEN parity, wiki assets, performance guardrails and regression contracts | New systems can be exercised in one hosted or dedicated test session and remain part of the release gate |

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

The current ACRE2 framework uses a single `MissionConfig\acreConfig.sqf`, label-only named side presets, deterministic side/group/player/role plans, independent same-type radio occurrences and ears, frequency-radio support, verified JIP-safe CEOI/Babel, and ACRE-filtered respawn/persistence loadouts. Extra radios and alternate PTT remain player-owned. Obsolete `_Legacy` ACRE setup functions have been removed so there is one supported lifecycle.
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
