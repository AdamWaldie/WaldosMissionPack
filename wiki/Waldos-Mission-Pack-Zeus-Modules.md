# Waldos Mission Pack Zeus Modules

> **Use this page when:** you need to find, configure, or understand WMP's Zeus Enhanced modules.

## Requirements and location

All WMP ZEN dialogs run on the curator's machine, but shared changes are validated and executed on
the server. A successful dedicated-server use produces a completion notification for the curator;
silence is not considered success. Long-lived missions use punctuation-safe runtime IDs, so
gunship, Dynamic AA/AO, hazard and paradrop creation do not begin failing after the server has been
up for many hours. Economy placement/configuration, Fortify, EMP and tracker requests use the same
curator-authenticated server rule as the larger runtime systems.

These modules allow users to:
* Spawn a Logistics System Supply & Medical Crate to Zeus specification
* Turn a crewed AI land-vehicle group into a managed [AI Convoy](AI-Convoy-System)
* Set the mission to [ENDEX](ENDEX-Script-&-Custom-End-Screen)
* End the mission utilising the [Custom End](ENDEX-Script-&-Custom-End-Screen)
* Create and remove named [Dynamic Anti-Air](Dynamic-Anti-Air) systems
* Generate and clean up complete randomized [Dynamic AOs](Dynamic-AO-Generation)
* Create and remove routed [Dynamic Paradrop](Vehicle-Actions-&-Paradrop#dynamic-drop-zone-operations) operations
* Scale the nearest object through a validated server request
* Configure persistence, hazardous environments and AI rebalance while the mission is running
* Register field-resupply hubs/carriers and tactical-display terminals
* Register, assign and operate airborne gunship support
* Register vehicle-recovery workshops, recoverable vehicles and recovery carriers
* Configure temporary squad rally respawns during play
* Enable, time or lift SafeStart protection during play, even though it starts inactive by default
* Send a [WMP notification card](Custom-UI-Notifications) to everyone, one side, a named group, or selected players

WMP's Zeus modules require Zeus Enhanced. To keep the palette usable, they are grouped by purpose under **WMP Mission Flow**, **WMP Logistics**, **WMP Transport**, **WMP AI & Combat**, **WMP Electronic Warfare**, **WMP Environment**, **WMP Air Operations**, **WMP Mission Tools**, and **WMP Interface & QA**. Economy modules are grouped under **WMP Economy Systems**. Headless-client controls use their own **WMP Headless Client** category and appear only when `Waldo_Headless_Enable` is true.

Use them to:

- spawn Logistics System supply and medical crates;
- configure mission systems through guided interfaces;
- apply [ENDEX](ENDEX-Script-&-Custom-End-Screen) protection;
- finish the mission with a configured WMP end screen.

![Image of the Zeus Modules and where they can be located](https://i.imgur.com/kdR1q9Z.png)

## Supply & Medical Crate Spawner

Zeus-spawned crates use the same class names and generated contents as the standard [Logistics System](Logistics-System,-Starter-Crates-And-Quartermaster). Changes to the mission's logistics configuration therefore carry over to Zeus-created crates.

## Supply crate interface
![Zeus Interface of supply crate spawner](https://i.imgur.com/iuiulsL.jpg)

The interface lets Zeus select the resupply size, the side whose playable loadouts supply the contents, and whether to include equipment, weapons, attachments, items, launchers and launcher ammunition, or ammunition only.

## Medical supply crate interface
![Zeus Interface of Medical Crate Spawner](https://i.imgur.com/7aZPysV.png)

The medical-crate interface selects the resupply size and whether the crate becomes an ACE field hospital for nearby medical personnel.

## Fortify Budget Module

This module requires the [Automatic Fortify Setup](Automatic-ACE-Fortify-Setup), or ACE Fortify being active. It allows for the alteration of the fortify budget in zeus, without the need for manual scripting.

![Fortify Budget Module GUI](https://i.imgur.com/GYunnuf.jpg)

## AI Convoy Module

Under **WMP AI & Combat**, **Convoy - Create Moving Group** turns the nearest crewed AI land-vehicle group within 150 m of the module into a managed convoy. Place the module on or near the lead vehicle. The dialog sets max speed, target separation and whether the convoy pushes through contact (keeps moving and only returns fire on the move) instead of stopping to engage. It calls the same [AI Convoy System](AI-Convoy-System) behaviour (`Waldo_fnc_SimpleAiConvoy`) available to scripts, dispatched to whichever machine currently owns the selected group. See [AI Convoy System](AI-Convoy-System) for the full parameter reference and the manual-stop script pattern.

## ENDEX Module

The ENDEX module performs the following actions:
* Places all player weapons on Safe and prevents Players and player vehicles from firing.
* Makes all Hostile AI Passive
* Fully Heals all Players & Makes them invincible
* Creates a popup informing players that the mission is over and to congregate together for debriefing.
* If a player tries to fire their weapon or use grenades, it is deleted and a popup tells them to cease firing.

It does NOT end the mission.

## SafeStart Modules

SafeStart is loaded but **inactive by default**, so a normal mission begins live. Under **WMP Mission
Flow**, Zeus can use **SafeStart: Enable Protection** to freeze firing and damage immediately,
**SafeStart: Start Go-Live Timer** to enable protection and begin a seconds-based countdown, or
**SafeStart: Go Live Now** to lift protection and cancel a timer. These modules call the same
server-authoritative API as scripts, publish the current state for JIP players and remain available
for the whole mission. See [Safestart](Safestart) for confinement and mission-start overrides.

An example of it in use can be seen below:
![Zeus Endex execution example](https://i.imgur.com/PBpewY8.png)

## Mission End

Similar to the vanilla mission end script, this mission will end the scenario.

However, this variation allows the zeus to end the mission utilising a custom end screen and debriefing message which can be customised in the description.ext. Check out the [ENDEX Script & Custom End Screen](ENDEX-Script-&-Custom-End-Screen) tutorial for more information.

Below is an example of the custom mission end screen:
![Mission End Screen Example](https://i.imgur.com/xmK9I1e.png)

## Mission Flow: Send Notification

Under **WMP Mission Flow**, sends a [WMP notification card](Custom-UI-Notifications) to a chosen audience instead of a single local player: title/message text, a type selector, duration, placement, a **Send to all players** checkbox, and a single ZEN-native **OWNERS** recipient picker (its own Sides/Groups/Players tabs, live multi-select, no typed callsign) for everything short of "everyone." Picked sides/groups/players are resolved into one deduplicated unit list before sending, so a player covered by more than one selection is never notified twice. Routed through a curator-authenticated server bridge before calling the same `Waldo_fnc_NotificationBroadcast` script API. See the [Custom UI Notifications](Custom-UI-Notifications) page for the full audience rules and the matching script call.

## Radio Jammer Modules

Three modules drive the [Radio Jamming](Radio-Jamming) system live in-game (works with ACRE2 and TFAR):

* **Radio Jammer - Place** — opens one scrollable dialog to set the jamming **radius**, **falloff**, **strength**, the **side** it jams, a directional **cone arc + bearing**, pulsing, markers, emitter source, optional reactivation, optional hostile field-disable procedure, public/engineer access, and whether success disables or destroys it. Fixed choices use always-visible buttons and the emitter uses an inline list, avoiding drop-downs being painted underneath later controls at some UI scales. Players always use **Disable Jammer** to turn an active field off; optional **Activate Jammer** restores an inactive/disabled field and resets its procedure. On empty ground it spawns the exact selected class, simulation-enables it and assigns it to the requesting curator. When placed directly on any existing mission or mod object, it can use that object without altering its simulation state. Its live field and interactions remain attached after movement.
* **Radio Jammer - Toggle Nearest** — flips the nearest jammer on or off (no dialog).
* **Radio Jammer - Remove Nearest** — removes the nearest jammer and deletes its emitter.

The Place dialog also offers a directional **cone**, **pulsing**, and an **also jam UAVs / drones** option (counter-UAS). See the [Radio Jamming](Radio-Jamming) page for the full scripting API and the ACRE2 signal-model requirement.

## EMP & Signal Tracker Modules

Two more electronic-warfare modules (full detail on the [EW: EMP & Signal Trackers](Electronic-Warfare-EMP-And-Signal-Trackers) page):

* **EMP Detonation** — a dialog for **radius** and **duration**, then detonates an electromagnetic pulse at the module position: infantry in range lose NVGs and TFAR radio use, vehicles have their engines cut, and players get a white-out flash and clear message. Units/vehicles marked with `Waldo_fnc_EMPImmune` are spared.
* **Plant Signal Tracker** — must be placed directly on an object or unit, then tags that exact target so a chosen side follows it live on the map. Empty-ground placement is rejected; it never guesses from nearby entities.

## Dynamic Anti-Air Modules

**Dynamic AA - Create** accepts a human-readable system/marker name while retaining a separate safe internal runtime ID. It separates common detection settings from one relevant equipment page, so profile and exact-selection controls are never shown together. Exact mode retains the original readable radar, static, mobile and fighter lists with a quantity for each. **Add another mixed equipment set** repeats that same page only when additional classes are wanted, allowing exact mixed quantities without per-unit dialogs. Operational side and physical equipment remain independent. Map-marker visibility and the default-on display of range/floor/ceiling values are separate switches. Generated installations reserve class-aware physical footprints and reject placement if enough clear positions cannot be found. The optional radar shutdown objective can use any shared WMP interaction procedure. **Dynamic AA - Remove Nearest** identifies the nearest system by its custom name and can either delete its assets or leave them disabled. See the [Dynamic Anti-Air guide](Dynamic-Anti-Air) for every option.

## Dynamic AO Modules

Under **WMP AI & Combat**, **Dynamic AO - Create** uses one live friendly-name faction/side selector and exposes independent patrol, garrison, static, weighted vehicle/air, civilian, minefield, roadblock, pathing and marker controls. The entered AO name is retained as the centre-marker and removal-list name while a safe internal ID is generated separately. Patrol routes preserve Arma's waypoint-zero state and explicitly activate their first movement waypoint on dedicated authority. **Dynamic AO - Remove** lists active AOs and preselects the nearest one. Deleting the hidden AO centre anchor invokes the same complete cleanup; minefield anchors remove only their own field. See [Dynamic AO Generation](Dynamic-AO-Generation).

## Scale Object Module

Place **Scale Object** directly on the intended target and choose the multiplier. The server enforces the mission's configured minimum and maximum scale. Live curator use deliberately does not replace the selected object with a simple object; mission makers can still request that conversion through the scripted API during pre-planned setup.

## Optional Feature Runtime Modules

These modules are repeat-safe and send configuration through a server-authoritative curator request. Live setting bundles are applied on clients before their matching initializer runs. Joining players and headless clients request an ordered server snapshot before locality-sensitive features activate, while keyed JIP entries replay or clear the required initializer. Where a module offers **Copy setup script**, the copied call can be moved into mission setup for repeatable pre-planned use.

## Persistence

**Persistence - Control** enables or disables persistence and configures player/object save intervals and the supported data categories. Enabling still requires a compatible INIDBI2 server runtime; placing the module does not silently bypass the dependency gate.

**Persistence - Register Object** selects the nearest object within 25 metres and registers its cargo, damage, fuel, ammunition/pylons and/or transform under an automatically generated stable runtime key.

**Persistence - Save Now** can immediately request saves from connected players, registered objects, or both without disabling the system.

## Hazardous Environments

These modules appear only when `Waldo_Hazard_Enable` is `true` in `MissionConfig\environmentConfig.sqf`. A disabled hazard runtime therefore does not leave unusable controls in Zeus.

**Hazard - Create** first selects a mission-configured hazard preset, then exposes plain-language RP name/messages, intensity, range, exposure, recovery, damage, fatal threshold and protection controls. Detector-aware presets are labelled in the first selector. Zeus can keep their mission-maker detector rules or deliberately make hazard information visible to everyone, independently from physical protection/damage. The dialog also controls the continuous exposure panel and can copy a setup call for later mission authoring.

**Hazard - Remove Nearest** removes the registered hazard whose centre is nearest to the placed module.

## AI Rebalance

**AI Rebalance - Control** enables or disables the supported AI profile at runtime, selects daylight or NVG-aware low-light conditions, and offers **Existing Mission Balance**, **WMP Militia**, **WMP Line**, **WMP Veteran** and **WMP Elite**. The WMP prefix distinguishes these encounter profiles from Arma's own difficulty presets; Existing Mission Balance remains the compatibility option rather than a fifth tuned tier.

## Field Resupply

**Field Resupply - Register Hub** turns the object directly under the module into a side-restricted refill hub with finite or unlimited stock. If no object is under it, the server creates an empty `Logi_SupplyBoxClass` crate at the module position and registers that instead. **Field Resupply - Assign Carrier** gives the nearest infantry unit a current and maximum deployable-crate allowance. **Field Resupply - Grant Crates** is placed directly on an assigned infantry carrier, or within 25 metres of one, and grants 1–10 additional crates. Zeus may either respect the existing maximum or explicitly increase capacity enough to fit the complete grant. Only the receiving player is notified, after the fake loading/title presentation has ended. With ACE loaded, the assigned player receives carrier controls under ACE Self Actions; a backpack is required and deployment is available only on foot. Assignment, grants, refill, deploy and salvage operations are validated by the server; taking supplies from a deployed crate is ordinary ACE Cargo/Gear interaction against its real populated cargo, not a separate WMP action.

## Loadout Save Point

**Respawn: Create Loadout Save Point** is under **WMP Logistics**. Place it on an existing object to add the save-loadout interaction, or place it on empty ground to create the configured station crate first. It is intentionally grouped with supply, starter-loadout and re-equipment tools rather than mission-flow controls.

## Tactical Display

**Tactical Display - Register** turns the nearest object into a range-limited terminal. Players with proximity and line of sight can open its tactical map; it shows friendlies and only enemies already known to their group. An optional simplified authentication section exposes enable, procedure and difficulty; command authentication is preselected as the semantic default.

## Airborne Gunship Support

**Gunship - Register or Spawn** selects operational side independently from any configured compatible airframe, or registers the nearest existing aircraft. **Gunship - Assign Controller** assigns the nearest player to a named system. **Gunship - Set Orbit** sends the selected aircraft to the module position. **Gunship - Operational Control** returns it to its combat orbit, sends it through its timed service cycle, releases its operator or removes the system. During RTB/service the assigned player receives status/progress only; tasking and weapon controls return when service completes. See the [Airborne Gunship Support guide](Airborne-Gunship-Support).

## Dynamic Paradrop

**Paradrop - Create Drop Zone** independently selects operational side and a validated transport airframe, then configures the named exact route, forced altitude/speed, approach/drop/exit lengths, repeating or single-pass lifecycle, circuit direction, static-line and HALO player actions, parachute classes, optional automatic drop, optional AI cargo (zero by default), cadence and map symbology. The server normalizes each enabled jump altitude/speed envelope around the route, so custom values cannot suppress every action. **Paradrop - Embark Players** detects a player directly under the module or in the curator selection and offers that player/group; with no player target it creates a reusable, curator-movable blue-action boarding object. **Paradrop - Remove Operation** lists both WMP-spawned dynamic operations and pre-placed Eden/quick-flight operations, applying the same marker cleanup, optional aircraft deletion and player-aboard safety rule to both. See [Vehicle Actions & Paradrop](Vehicle-Actions-&-Paradrop#dynamic-drop-zone-operations).

## Vehicle Recovery

**Vehicle Recovery - Register Workshop** assigns a key, delivery radius, nearby completion-notification radius, serviced side and optional delivery-area/exact-position map markers to the nearest object. Its exported call includes the same choices. **Register Vehicle** sets the matching key, damage and destroyed-vehicle policy, engineer restriction, recovery-object class, cargo preservation and restored fuel. It may be placed directly on an already-destroyed wreck: dead crew proxies retained by Arma do not count as occupants, while any living occupant still blocks packaging. Its friendly recovery-object dropdown is built from the mission-extensible `Waldo_Recovery_PackageClasses` pool. It can optionally replace immediate packaging with a simplified preparation procedure configured by enable, procedure and difficulty; repair is preselected. **Register Carrier** supports any nearby vehicle. Automatic handling uses its real configured vehicle cargo bay when a package fits and virtualizes otherwise; Virtual Manifest removes that engine dependency entirely, while Physical Cargo Bay deliberately enforces it. Loading range and a combined 1–10 package capacity are configurable. See [Vehicle Recovery and Squad Rally Points](Vehicle-Recovery-And-Squad-Rallies).

## Custom 3D Marker and Field Equipment

**Create Custom 3D Marker** is a safe front end to the scripted marker API. Choose a plain-language icon, accessible colour, side audience, height, range and size. Place it on an object to follow that object, or on empty ground for a fixed marker. With **Place above object** off and extra height zero, the shared script/Zeus renderer locks the marker to the object's model origin; it does not add bounding height or terrain elevation. WMP validates the curated choices on the server; Zeus never needs a texture path or config classname.

**Remove Custom 3D Marker** lists all active WMP world markers with the nearest one preselected. Place it on an anchor object to sort that object's markers first, or place it near a fixed marker. The curator-authenticated server removes the selected current registry ID only; anchor objects and ordinary Eden/Zeus map markers are never deleted. The matching script API accepts an exact marker ID, an anchor object, or a position and search radius.

**Add WMP Field Equipment Interaction** must be placed directly on the intended object; that exact object receives the action. It offers every built-in named procedure, difficulty and a short action label. Success and failure each have an independent preset for the selected object: no action, record completion (success only), show/enable, hide/disable, unlock, lock, destroy or delete. Each result also has an always-visible optional code field. That code runs authoritatively on the server after its preset and receives `_target` (the selected object), `_actor` (the player), `_success` and `_result`, allowing a curator to affect another named mission object or start a wider script. **EOD bomb defusal** adds the same live defusal wrapper used by scripts and may independently detonate on failure. Repeat/retry controls are explicit.

## Headless Client

When `Waldo_Headless_Enable` is true, the separate **WMP Headless Client** category provides debug overlay, forced rebalance and manual handoff controls. The overlay labels each AI group with its live owner and unit count: server, named HC, unexpected owner or a red registry mismatch. The confirmation also reports connected HCs, managed groups and mismatches. See [Headless Client Support](Headless-Client-Support).

## AI Helicopter Landing

[Improved AI Helicopter Landings](Improved-AI-Helicopter-Landings) intentionally has no ZEN module — it is a per-aircraft profile applied through `MissionConfig\aiConfig.sqf` and event-driven locality handlers, not a placeable or runtime-toggled system.

## Transport Services

**Transport Service - Register** must be placed on an existing living AI-crewed helicopter, land vehicle or boat. It registers the selected type into its independent pool and exposes plain-language service name, access, marker, boarding, destination, helicopter altitude, base servicing and opt-in emergency-reset options. **Transport Service - Return to Base** cancels the current task for a selected registered service and orders a physical RTB. See [Helicopter, Ground and Boat Transport Services](Transport-Services).

## UI Theme QA

**UI QA - Set Visual Theme** selects Default/Modern, Second World War, Vietnam/Cold War, Science Fiction or Parchment/Fantasy styling. It changes presentation globally and can show the requesting curator a three-card semantic/stacking preview. See [UI Visual Themes](UI-Visual-Themes).

## Squad Rally Points

**Respawn - Squad Rally Control** enables or disables squad-leader rally actions and adjusts object class, duration, cooldown, enemy exclusion, group size, placement, slope and the optional direct-regroup ability. Disabling it also removes active rallies. See [Vehicle Recovery and Squad Rally Points](Vehicle-Recovery-And-Squad-Rallies).

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
