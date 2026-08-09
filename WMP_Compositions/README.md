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
| Vehicle Recovery Workshop Example (Minimal) | Smallest working workshop/vehicle/carrier registration - required args only |
| Vehicle Recovery Workshop Example (Full) | Spaced workshop, recoverable vehicle and generic AUTO carrier with every option shown |
| Helicopter and Ground Transport Services (Minimal) | Smallest working AI-crewed service registration - required args only |
| Helicopter and Ground Transport Services (Full) | AI-crewed named air/ground services with current LZ clearance and improved-landing defaults, every option shown |
| Logistics Spawner Example (Minimal) | Smallest working standalone quartermaster access point |
| Logistics Spawner Example (Full) | Immediately active standalone quartermaster access point with every option shown |
| MHQ With Logistics Spawner (Minimal) | Single truck, smallest working deployable command post |
| MHQ With Logistics Spawner (Full) | Deployable command post with synchronized parts and every option shown |
| Virtual Vehicle Depot Spawner Example (Minimal) | Smallest working terminal and spawn point registration |
| Virtual Vehicle Depot Spawner Example (Full) | Terminal and safely separated spawn point with every option shown |
| AutoFortify Setup Example | Synced ACE Fortify catalogue |
| Mass AttachTo / Vehicle Mounted Weapon | Vehicle construction helpers |
| Halo and Static Line Paradrop Examples (Minimal) | Smallest working self-crewed aircraft flying a static-line route |
| Halo and Static Line Paradrop Examples (Full) | Boarding and aircraft jump setup for two aircraft, every option shown |
| Gunship Support Example (Minimal) | Smallest working registration for a crewed VTOL |
| Gunship Support Example (Full) | Crewed VTOL registered with `Waldo_fnc_GunshipRegister`, orbiting a movable marker with automatic service, every option shown |
| Radio Jammer Example (Minimal) | Smallest working jammer fixture |
| Radio Jammer Example (Full) | Server-owned, movable jammer fixture with every option shown |
| Hazardous Zone Example (Minimal) | Smallest working fixed-area hazard registration |
| Hazardous Zone Example (Full) | Reliable fixed-area hazard with visible transition feedback and real danger, every option shown |
| Radiation Hazard With Audio (Minimal) | Smallest working call - no profile overrides |
| Radiation Hazard With Audio (Full) | MODERATE_RADIATION preset with label/notification overrides shown explicitly |
| Hazard Emitter Moving Example (Minimal) | Smallest working moving contamination field |
| Hazard Emitter Moving Example (Full) | Contamination field that follows a vehicle, via `Waldo_fnc_HazardRegisterEmitter` directly, every option shown |
| Dynamic AA Example (Minimal) | Smallest working anchor object - id and centre only |
| Dynamic AA Example (Full) | Anchor object generating a radar, static and mobile AA site around itself, every option shown |
| Dynamic AO Example (Minimal) | Smallest working anchor object - id, centre and faction (faction has no default) |
| Dynamic AO Example (Full) | Anchor object generating a randomized area of operations around itself, every option shown |
| Explosive Wall Breaching Example (Minimal) | Smallest working profile - an empty HashMap uses every default |
| Explosive Wall Breaching Example (Full) | Explicit demolition-charge profile with a visibly testable centre gap, every key shown |
| Emergency Dismount Vehicle Example | Simulation-safe upright vehicle that enables overturn/destroyed extraction |
| Tactical Display Example (Minimal) | Smallest working access point registration |
| Tactical Display Example (Full) | Supported map-board access point with every option shown |
| Bomb Defusal Example (Minimal) | Smallest working wire-cutting challenge |
| Bomb Defusal Example (Full) | Standard wire-cutting challenge with an explosive failure consequence, every option shown |
| Interaction Examples Showcase | All ten field-equipment procedures side by side, cycling easy/standard/hard/expert |
| Minesweeper Interaction Example | Passing/failing marks a real `Waldo_fnc_CreateObjective` task SUCCEEDED/FAILED |
| Keypad Interaction Example | Passing unlocks a nearby locked vehicle; failing leaves it locked |
| Lockpick Interaction Example | Passing populates a nearby empty crate with `Waldo_fnc_SupplyCratePopulate`; failing leaves it empty |
| Circuit Interaction Example | Failing fires a real `Waldo_fnc_EMP` burst on the surrounding area; passing is safe |
| Repair Interaction Example | Passing repairs and restarts a nearby heavily damaged vehicle; failing leaves it disabled |
| RadioTune Interaction Example | Passing calls `Waldo_fnc_JammerToggle` to switch off a nearby live radio jammer |
| Pressure Interaction Example | Failing applies real damage to the acting player; passing is safe |
| Sequence Interaction Example | Passing sends a `Waldo_fnc_NotificationBroadcast` card to a whole side |
| CommandInput Interaction Example | Passing plants a `Waldo_fnc_Tracker` signal tracker on a nearby vehicle |
| Construction Objects Example | ACE construction supply object with modern construction audio |
| Electronic Warfare Examples | EMP immunity and side-restricted signal tracking fixtures |
| Object Scaling Example | Supported Simple Object conversion and scale setup |
| Custom 3D Marker Example (Minimal) | Smallest working object-anchored marker |
| Custom 3D Marker Example (Full) | Object-anchored, side-aware world marker with readable options, every option shown |
| Notification Trigger | Server-only 25 m Eden trigger that sends one editable WMP notification without firing at mission load |
| Economy Systems and Low/Medium/High | Runtime enablement and optional preset |
| Persistence Object Example (Minimal) | Smallest working call - key and object only, every field saved by default |
| Persistence Object Example (Full) | Crate registered with `Waldo_fnc_PersistenceRegisterObject`, no `isServer` wrapper needed, options shown |
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
