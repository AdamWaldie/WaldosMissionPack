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
   Every shipped comment links directly to the matching WMP wiki article; keep that URL when you
   copy or adapt the example.
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
| Loadout Save Point Example | Laptop with ACE and WMP-blue vanilla save actions, including ACRE radio state |
| Vehicle Recovery Workshop Example | Spaced workshop, recoverable vehicle and generic AUTO carrier |
| Helicopter and Ground Transport Services | AI-crewed named air/ground services with current LZ clearance and improved-landing defaults |
| Logistics Spawner Example | Immediately active standalone quartermaster access point |
| MHQ With Logistics Spawner | Deployable command post with synchronized parts |
| Virtual Vehicle Depot Spawner Example | Terminal and safely separated spawn point |
| AutoFortify Setup Example | Synced ACE Fortify catalogue |
| Mass AttachTo / Vehicle Mounted Weapon | Vehicle construction helpers |
| Halo and Static Line Paradrop Examples | Boarding and aircraft jump setup |
| Gunship Support Example | Crewed VTOL registered with `Waldo_fnc_GunshipRegister`, orbiting a movable marker with automatic service |
| Radio Jammer Example | Server-owned, movable jammer fixture |
| Hazardous Zone Example | Reliable fixed-area hazard with visible transition feedback and real danger |
| Hazard Emitter Moving Example | Contamination field that follows a vehicle, via `Waldo_fnc_HazardRegisterEmitter` directly |
| Dynamic AA Example | Anchor object generating a radar, static and mobile AA site around itself |
| Dynamic AO Example | Anchor object generating a randomized area of operations around itself |
| Explosive Wall Breaching Example | Explicit demolition-charge profile with a visibly testable centre gap |
| Emergency Dismount Vehicle Example | Simulation-safe upright vehicle that enables overturn/destroyed extraction |
| Tactical Display Example | Supported map-board access point |
| Bomb Defusal Example | Standard wire-cutting challenge with an explosive failure consequence |
| Interaction Examples Showcase | All ten field-equipment procedures side by side, cycling easy/standard/hard/expert |
| Construction Objects Example | ACE construction supply object with modern construction audio |
| Electronic Warfare Examples | EMP immunity and side-restricted signal tracking fixtures |
| Object Scaling Example | Supported Simple Object conversion and scale setup |
| Custom 3D Marker Example | Object-anchored, side-aware world marker with readable options |
| Economy Systems and Low/Medium/High | Runtime enablement and optional preset |
| Persistence Object Example | Crate registered with `Waldo_fnc_PersistenceRegisterObject`, no `isServer` wrapper needed |
| Teleport Script Example | Paired local addActions |

## Features intentionally without compositions

- **WMP HUD** is configured player-locally through `MissionConfig\interfaceConfig.sqf`; it has no world-object placement requirement, so a composition would be misleading. Use the full audit mission for live HUD testing.

Generated drop zones (`Waldo_fnc_ParadropCreateDropZone`) spawn and own their own aircraft/crew, unlike
the Gunship, Dynamic AA and Dynamic AO compositions above (which register/anchor around an object the
mission maker already placed) or the Halo/Static-Line Paradrop compositions (which fly an
already-placed, already-crewed aircraft) - a spawn-its-own-aircraft system is Zeus/script-only for the
same reason `Waldo_fnc_ParadropCreateDropZone` itself is not used by any composition: an Eden object
cannot represent "spawn this on demand" the way it represents "here is a real placed thing". Improved
helicopter landing is an automatic AI handler driven by ordinary landing waypoints. Accessibility,
treatment feedback and UI themes are player-interface features. Starting the Persistence system
itself (the `Waldo_Persistence_Enable` flag, its INIDBI2 dependency probe and the server database
scope) depends on a server extension and mission database policy that has no single placeable object
to represent it - but registering one *specific* world object once persistence is running is exactly
as composable as the systems above, see the Persistence Object Example composition. Rally points are
player-role state. Tree felling operates on terrain vegetation, which Eden compositions cannot own.
Those systems remain covered by beginner configuration, public calls, the full audit mission and
focused Zeus modules where appropriate.
