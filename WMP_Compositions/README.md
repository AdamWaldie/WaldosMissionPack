# WMP Eden composition catalogue

These compositions are beginner-facing Eden examples for features that benefit from reusable,
pre-placed objects. They require the matching version of WaldosMissionPack inside the mission.
Composition init fields deliberately call the public WMP functions; they do not contain private
copies of feature logic.

## Categories

| Eden category | What belongs there |
|---|---|
| Foundation | Side starter layouts, respawn and curator setup |
| Logistics | Crates, field resupply, recovery, MHQ, vehicle depot and construction helpers |
| Air Operations | Pre-planned aircraft and boarding examples |
| Combat Systems | Physical combat/EW fixtures such as a radio jammer |
| Interface | Physical access points such as the Tactical Display board |
| Mission Systems | Whole-mission opt-in systems such as Economy |
| Mission Tools | Small editor utilities such as paired teleport points |

## How to customise safely

1. Place the composition in Eden and keep its objects separated as supplied.
2. Read the nearby Eden comment before changing an init field.
3. Change only the clearly named side, range, stock, key, class or toggle arguments.
4. Call WMP's documented public setup function directly. Its implementation owns server authority,
   client-local setup and JIP replay; mission makers should not add an `isServer` wrapper unless the
   specific function documentation explicitly requires one.
5. Do not move player-local action setup into `initServer.sqf`; WMP registration functions publish
   the correct client/JIP setup themselves.
6. Copy the full matching version of `MissionScripts`, `MissionConfig`, `description.ext` and init
   files into the mission. A composition is not a standalone mod.

## Current catalogue

| Composition | Purpose |
|---|---|
| Basic Setup West/East/Independent/Civilian | Side-specific respawn and starter logistics |
| Basic Mobile Respawn Vehicle | Minimal mobile respawn example |
| Basic Player Controlled Zeus | Player/curator foundation |
| Starter, Supply and Medical Crate Collections | Side and contents variants with server-owned population |
| Field Resupply Hub Example | Refill hub; assign infantry carriers by script or Zeus |
| Vehicle Recovery Workshop Example | Spaced workshop, recoverable vehicle and generic AUTO carrier |
| Logistics Spawner Example | Quartermaster access point |
| MHQ With Logistics Spawner | Deployable command post with synchronized parts |
| Virtual Vehicle Depot Spawner Example | Terminal and safely separated spawn point |
| AutoFortify Setup Example | Synced ACE Fortify catalogue |
| Mass AttachTo / Vehicle Mounted Weapon | Vehicle construction helpers |
| Halo and Static Line Paradrop Examples | Boarding and aircraft jump setup |
| Radio Jammer Example | Server-owned, movable jammer fixture |
| Hazardous Emitter Example | Dangerous moving-object hazard with visible transition feedback |
| Tactical Display Example | Supported map-board access point |
| Economy Systems and Low/Medium/High | Runtime enablement and optional preset |
| Teleport Script Example | Paired local addActions |

## Features intentionally without compositions

Dynamic AO and Dynamic AA are server-authoritative generated systems; Zeus or scripted creation is
clearer and safer than shipping pre-spawned clusters. Improved helicopter landing is an automatic AI
handler driven by waypoints. Accessibility, treatment feedback and UI themes are player-interface
features. Persistence depends on server extensions and mission policy. Rally points are player-role
state. Object scaling is target-specific and may convert decorative objects to simple objects. Those
features remain documented through MissionConfig, public calls, the full audit mission and focused
Zeus modules where appropriate.
