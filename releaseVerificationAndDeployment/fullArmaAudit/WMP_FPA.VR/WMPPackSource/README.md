# WaldosMissionPack
A package of mission scripts for mission makers designed to be highly flexible, automated and as easy as possible for any mission makers to interact with.

## License

WaldosMissionPack is released under the [MIT License](LICENSE). Assets retain any notices required
by adjacent licence files.

![alt text](https://github.com/AdamWaldie/WaldosMissionPack/blob/main/Pictures/loading.jpg?raw=true)

**If you find this mission pack inside a mission, please do not utilise it. Mission Makers like to customise the pack. Download the Missionpack Folder (WMP_Version_Number_Here.zip) from github: https://github.com/AdamWaldie/WaldosMissionPack/releases/latest**

# Background Information
- This project was created originally for the mission makers of the Rooster Teeth Gaming Discord, with the intent to provide them with the easiest possible method 
to utilise critical systems of arma 3. Now, it is in continued use by at least forty known units, from all corners of the milsimsphere.
- Basic mission setup can be achieved easily through editing the supplied description.ext, and various Init files while the more interesting features can be set up by following the indepth documentation in each file.
- All features are functionalised, and simply require a function call as directed in the files themselves to work.
- All functions follow the follwing Syntax "Waldo_fnc_FunctionName", you may find a full list of these in WaldosFunctions.sqf.

# Pack Features
- Loadout saving and respawn system
- Lifecycle-safe ACRE2 radio, duplicate-radio/ear assignment, named-channel, CEOI, Babel and respawn/persistence handling configured from `MissionConfig\acreConfig.sqf`
- Locality-separated feature defaults in `MissionConfig` while init files retain authority, activation and JIP lifecycle
- Localised Radio Jamming for ACRE2 & TFAR - drop a jammer object (or place one live from Zeus) to deny comms in an area. Terrain line-of-sight, radio-power burn-through, directional cones, pulsing, per-side and (ACRE2) per-band control; optional UAV/drone jamming (freeze autonomous drones, cut controlling players' datalinks); destructible jammers for "blow the tower" objectives, ACE toggle/disable actions and a handheld RDF scanner for EW teams, plus a deliberately loud on-screen jamming HUD so it's never mistaken for a game bug.
- Electronic Warfare toolkit - a one-shot EMP burst (kills NVGs, vehicle engines and TFAR radios in a radius, with an immunity tag) and C-Track style signal trackers (tag a unit/vehicle and a chosen side follows it live on the map). Both scriptable and available as Zeus modules.
- Custom loadout & logistics system which scrapes the kits of all playable characters to fulfil base logistical needs - such as starter crates and supply crates. (Disable scenario Binarization, and edit loadouts via ACE Arsenal to ensure 100% satisfaction)
- Vehicle Ambush/Camo scripts.
- Vehicle unflipping actions
- Configurable AI convoy system with mission-maker and Zeus workflows.
- Teleportation Script
- Endex & Safestart Scripts - Safestart is available but inactive by default and can be enabled by Zeus; ENDEX includes an automatic After-Action Report (duration, KIA/WIA, vehicle losses, friendly fire, objectives, top fraggers).
- Script-driven Tasks/Objectives helpers - JIP-safe BIS task wrappers with automatic map markers that also feed the After-Action Report.
- Mission Diagnostics - a read-only server and client health report with run IDs, machine roles, feature areas, explicit loaded/disabled/unavailable states, and structured RPT output.
- Performance regression audit - a CI-enforced static review of recurring SQF schedulers, world searches, UI redraws and network publication, with reviewed exceptions and documented in-engine verification limits.
- Custom Zeus Enhanced modules for in-game access to the logistics system, ENDEX & Safestart scripts.
- Checked Zeus/script parity for all 42 core and 19 Economy modules. Direct modules use the public API; authoring adapters translate Zeus selections into the same public calls. Shared mutations use curator-authenticated server bridges where required, while interface-only export/preview tools stay local. The checked-in parity manifest prevents missing controls and invented API links from silently shipping.
- Server-owned custom 3D world markers with object/position anchors, JIP support, side and distance filtering, accessible icon-plus-text labels, and one shared renderer.
- Safe-zone-aware WMP notification cards with accessible states, mission-authored channel placement, optional permitted local overrides, FIFO sequencing, bounded non-overlapping stacks, duplicate coalescing and an ACE/vanilla emergency UI cleanup action.
- Optional feature systems - dependency-gated persistence, ACE patient treatment feedback, hazardous environments and moving emitters, tree felling and brush clearing, emergency dismount, a friendly-identification accessibility aid, profile-driven explosive wall breaching, server-validated transforms, finite field resupply and authenticated tactical displays. All default off, expose repeat-safe configuration and cleanup APIs, and use focused Zeus Enhanced modules where runtime operation is useful.
- Dynamic Anti-Air - multiple named radar-controlled air-defence zones, available through script or guided Zeus placement, with configurable side/faction asset pools, altitude rules, dynamic static/mobile responses and fighter scrambling.
- Airborne Gunship Support - multiple named existing or spawned gunships with side/faction pools, assigned player controllers, validated turret profiles, configurable combat orbits, automatic RTB/service cycles, friendly markers and focused Zeus operation.
- AI rebalance profiles - preserves existing behavior by default while offering PUBLIC, STANDARD and VETERAN baselines plus faction and role overrides for new missions.
- Waldos Economy Systems - a Zeus Resource / Research / Build / Buy economy suite with Ground Command, run live from the Zeus Enhanced module menu (ZEN required for the in-Zeus menu). Its Zeus builder exports readable setup calls for `MissionConfig\economyConfig.sqf`, including placed economy fixtures; the existing portable catalogue string remains available for transfer and import.
- Waldos Mini Games - twelve seated multiplayer party games (Battleship, Who's Who, Shotgun Roulette, Blackjack, Texas Hold'em, Five-Card Draw, Liar's Dice, Chess, Checkers, Connect Four, RPS, UNO) plus ten diegetic field-equipment procedures. Players inspect distinct EOD controllers, diagnostic tablets, access terminals, lock cylinders, breaker cabinets, maintenance hatches, radios, hydraulic manifolds, secure consoles, and tactical command uplinks. Procedures use procedural Arma controls as their complete primary presentation, with colourblind-safe redundant cues, integrated operating instructions, curated easy/standard/hard/expert difficulty profiles, immersive mission-specific profiles, optional low-opacity material textures, one-line Eden setup, exclusive server-owned attempts, persistent `IDLE`/`RUNNING`/`SUCCESS`/`FAILURE` state usable in ACE or vanilla conditions, authoritative callbacks/CBA events, and an optional party-table equipment picker.
- Optional ACE corpse traps - consume any compatible vanilla or modded throwable to rig a body; opening its inventory releases the stored projectile.
- HALO & Static Line Jump Scripts with equipment & weapon loss simulation.
- [WIP] Virtual Vehicle Deployment Garage
- Bundled (optional, off by default) third-party scripts - Werthles' Headless Client kit and aeroson's dynamic player markers - wired through a single clean entry point.
- Extensively documented files to learn how it works, and make use of this pack!
- Mission Pack Compositions to hasten the learning and mission building process
- Auto-generated cover/loading screen - the title and version are rendered programmatically from description.ext and kept in sync on every push and release.
- Claude Mission Config Skill - a separate downloadable release item that teaches an AI assistant (Claude or ChatGPT) how to configure every feature in this pack for your mission, with per-feature reference docs and clear guidance on what it can safely edit for you versus what still needs doing by hand in Eden Editor.


# QuickStart Guide
You can always find the most recent quickstart guide at this URL: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Quickstart-Guide

# Release Validation
The canonical feature test is the hosted **WMP FULL PACK PR AUDIT** VR mission. Its builder stages
the exact release allowlist and runs the pack's real `description.ext`, `init.sqf`,
`initServer.sqf` and `initPlayerLocal.sqf` around a proven, unbinarized five-slot scenario. Launch
it with `releaseVerificationAndDeployment/launch_pr_review_audit.ps1`. It requires CBA, ACE, ZEN
and ACRE2, disables BattlEye, defaults to 3840×2160, and keeps mutating automation off by default. The
workflow and evidence rules are documented under `releaseVerificationAndDeployment/fullArmaAudit/`.

# Other Information
- All files are provided with description on their utilisation and purpose.
- initPlayerLocal.sqf utilises CBA eventhandlers to provide respawn loadout saving/loading. You can choose whether to respawn with starting equipment, or what they died with in that file.
- Its recommended that you download Visual Studio Code & Its SQF plugins. Itll make any script reading in Arma 3 easier on you! 
    - Visual Studio Code: https://code.visualstudio.com/
    - SQF Language Extension: https://marketplace.visualstudio.com/items?itemName=vlad333000.sqf
    - SQF Debugger Extension: https://marketplace.visualstudio.com/items?itemName=billw2011.sqf-debugger

# Tutorials
I maintain a wiki on github, which is updated alongside the files to provide mission makers with easy access to knowledge regarding the pack.

The Wikis home can be found here:
https://github.com/AdamWaldie/WaldosMissionPack/wiki

Feature Tutorials can be found here:
https://github.com/AdamWaldie/WaldosMissionPack/wiki/Feature-Tutorials

Zeus Module Tutorials can be found here:
https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mission-Pack-Zeus-Modules

# Required Addons
- CBA_A3
- ACE 3 (Field Headquarters, Construction System, Quartermaster Logistics Spawner)

# Supported Addons
- ACRE 2 (optional; configure or disable it in `MissionConfig\acreConfig.sqf`)
- TFAR (inherent support through Eden configuration)
- Zeus Enhanced & Compat
- LAMBS Series of mods (Tutorial Mission Requires this, the pack can work without it)
- All unit mods compatable

<p align="center"><a href="https://www.buymeacoffee.com/thewaldo123" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png" alt="Buy Me A Coffee" style="height: 41px !important;width: 174px !important;box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;-webkit-box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;" ></a></p>

<p align="center">This pack is presently maintained solely by Waldo.</p>

