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

WMP's Zeus modules require Zeus Enhanced. To keep the palette usable, they are grouped under **WMP Mission Flow**, **WMP Logistics**, **WMP Combat Systems**, **WMP Air Operations**, **WMP Mission Tools**, and **WMP Interface & QA**. Economy modules remain under **Waldos Economy Systems**.

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

## ENDEX Module

The ENDEX module performs the following actions:
* Places all player weapons on Safe and prevents Players and player vehicles from firing.
* Makes all Hostile AI Passive
* Fully Heals all Players & Makes them invincible
* Creates a popup informing players that the mission is over and to congregate together for debriefing.
* If a player tries to fire their weapon or use grenades, it is deleted and a popup tells them to cease firing.

It does NOT end the mission.

An example of it in use can be seen below:
![Zeus Endex execution example](https://i.imgur.com/PBpewY8.png)

## Mission End

Similar to the vanilla mission end script, this mission will end the scenario.

However, this variation allows the zeus to end the mission utilising a custom end screen and debriefing message which can be customised in the description.ext. Check out the [ENDEX Script & Custom End Screen](ENDEX-Script-&-Custom-End-Screen) tutorial for more information.

Below is an example of the custom mission end screen:
![Mission End Screen Example](https://i.imgur.com/xmK9I1e.png)

## Radio Jammer Modules

Three modules drive the [Radio Jamming](Radio-Jamming) system live in-game (works with ACRE2 and TFAR):

* **Radio Jammer - Place** — opens a dialog to set the jamming **radius**, **falloff**, **strength**, the **side** it jams, a directional **cone arc + bearing**, pulsing, markers, emitter source, optional reactivation, optional hostile field-disable procedure, public/engineer access, and whether success disables or destroys it. Players always use **Disable Jammer** to turn an active field off; optional **Activate Jammer** restores an inactive/disabled field and resets its procedure. On empty ground it spawns the exact selected class, simulation-enables it and assigns it to the requesting curator. When placed directly on any existing mission or mod object, it can use that object without altering its simulation state. Its live field and interactions remain attached after movement.
* **Radio Jammer - Toggle Nearest** — flips the nearest jammer on or off (no dialog).
* **Radio Jammer - Remove Nearest** — removes the nearest jammer and deletes its emitter.

The Place dialog also offers a directional **cone**, **pulsing**, and an **also jam UAVs / drones** option (counter-UAS). See the [Radio Jamming](Radio-Jamming) page for the full scripting API and the ACRE2 signal-model requirement.

## EMP & Signal Tracker Modules

Two more electronic-warfare modules (full detail on the [EW: EMP & Signal Trackers](Electronic-Warfare-EMP-And-Signal-Trackers) page):

* **EMP Detonation** — a dialog for **radius** and **duration**, then detonates an electromagnetic pulse at the module position: infantry in range lose NVGs and TFAR radio use, vehicles have their engines cut, and players get a white-out flash and clear message. Units/vehicles marked with `Waldo_fnc_EMPImmune` are spared.
* **Plant Signal Tracker** — must be placed directly on an object or unit, then tags that exact target so a chosen side follows it live on the map. Empty-ground placement is rejected; it never guesses from nearby entities.

## Dynamic Anti-Air Modules

**Dynamic AA - Create** keeps operational side and physical asset profile independent in one dialog. Operational side controls allegiance and targeting; the profile may intentionally draw radar, static, mobile or fighter classes configured under another faction. Internal registry IDs and raw pool keys remain behind friendly display names. **Dynamic AA - Remove Nearest** selects the active system nearest to the placed module and can either delete its assets or leave them disabled. See the [Dynamic Anti-Air guide](Dynamic-Anti-Air) for every option.

## Dynamic AO Modules

Under **WMP Combat Systems**, **Dynamic AO - Create** uses one live friendly-name faction/side selector and exposes independent patrol, garrison, static, weighted vehicle/air, civilian, minefield, roadblock, pathing and marker controls. No raw faction classname, asset classname or internal registry id is required. **Dynamic AO - Remove** lists active AOs and preselects the nearest one. Deleting the hidden AO centre anchor invokes the same complete cleanup; minefield anchors remove only their own field. See [Dynamic AO Generation](Dynamic-AO-Generation).

## Scale Object Module

Place **Scale Object** directly on the intended target and choose the multiplier. The server enforces the mission's configured minimum and maximum scale. Live curator use deliberately does not replace the selected object with a simple object; mission makers can still request that conversion through the scripted API during pre-planned setup.

## Optional Feature Runtime Modules

These modules are repeat-safe and send configuration through a server-authoritative curator request. Live setting bundles are applied on clients before their matching initializer runs. Joining players and headless clients request an ordered server snapshot before locality-sensitive features activate, while keyed JIP entries replay or clear the required initializer. Where a module offers **Copy setup script**, the copied call can be moved into mission setup for repeatable pre-planned use.

## Persistence

**Persistence - Control** enables or disables persistence and configures player/object save intervals and the supported data categories. Enabling still requires a compatible INIDBI2 server runtime; placing the module does not silently bypass the dependency gate.

**Persistence - Register Object** selects the nearest object within 25 metres and registers its cargo, damage, fuel, ammunition/pylons and/or transform under an automatically generated stable runtime key.

**Persistence - Save Now** can immediately request saves from connected players, registered objects, or both without disabling the system.

## Hazardous Environments

**Hazard - Create** first selects a mission-configured hazard preset, then exposes plain-language RP name/messages, intensity, range, exposure, recovery, damage, fatal threshold and protection controls. The preset supplies semantic type and any configured protective equipment. It can also copy a setup call for later mission authoring.

**Hazard - Remove Nearest** removes the registered hazard whose centre is nearest to the placed module.

## AI Rebalance

**AI Rebalance - Control** enables or disables the supported AI profile at runtime, selects daylight or NVG-aware low-light conditions, and offers **Existing Mission Balance**, **WMP Militia**, **WMP Line**, **WMP Veteran** and **WMP Elite**. The WMP prefix distinguishes these encounter profiles from Arma's own difficulty presets; Existing Mission Balance remains the compatibility option rather than a fifth tuned tier.

## Field Resupply

**Field Resupply - Register Hub** turns the object directly under the module into a side-restricted refill hub with finite or unlimited stock. If no object is under it, the server creates an empty `Logi_SupplyBoxClass` crate at the module position and registers that instead. **Field Resupply - Assign Carrier** gives the nearest infantry unit a current and maximum deployable-crate allowance. **Field Resupply - Grant Crates** is placed directly on an assigned infantry carrier, or within 25 metres of one, and grants 1–10 additional crates. Zeus may either respect the existing maximum or explicitly increase capacity enough to fit the complete grant. Only the receiving player is notified, after the fake loading/title presentation has ended. With ACE loaded, the assigned player receives carrier controls under ACE Self Actions; a backpack is required and deployment is available only on foot. All assignment, grants, refill, deploy, take and salvage operations are validated by the server.

## Loadout Save Point

**Respawn: Create Loadout Save Point** is under **WMP Logistics**. Place it on an existing object to add the save-loadout interaction, or place it on empty ground to create the configured station crate first. It is intentionally grouped with supply, starter-loadout and re-equipment tools rather than mission-flow controls.

## Tactical Display

**Tactical Display - Register** turns the nearest object into a range-limited terminal. Players with proximity and line of sight can open its tactical map; it shows friendlies and only enemies already known to their group. An optional simplified authentication section exposes enable, procedure and difficulty; command authentication is preselected as the semantic default.

## Airborne Gunship Support

**Gunship - Register or Spawn** selects operational side independently from any configured compatible airframe, or registers the nearest existing aircraft. **Gunship - Assign Controller** assigns the nearest player to a named system. **Gunship - Set Orbit** sends the selected aircraft to the module position. **Gunship - Operational Control** returns it to its combat orbit, sends it through its timed service cycle, releases its operator or removes the system. During RTB/service the assigned player receives status/progress only; tasking and weapon controls return when service completes. See the [Airborne Gunship Support guide](Airborne-Gunship-Support).

## Dynamic Paradrop

**Paradrop - Create Drop Zone** independently selects operational side and a validated transport airframe, then configures the named exact route, forced altitude/speed, approach/drop/exit lengths, repeating or single-pass lifecycle, circuit direction, static-line and HALO player actions, parachute classes, optional automatic drop, optional AI cargo (zero by default), cadence and map symbology. The server normalizes each enabled jump altitude/speed envelope around the route, so custom values cannot suppress every action. **Paradrop - Embark Players** detects a player directly under the module or in the curator selection and offers that player/group; with no player target it creates a reusable, curator-movable blue-action boarding object. **Paradrop - Remove Operation** selects a named live operation and removes its aircraft, boarding points and markers without deleting troops that have already jumped. See [Vehicle Actions & Paradrop](Vehicle-Actions-&-Paradrop#dynamic-drop-zone-operations).

## Vehicle Recovery

**Vehicle Recovery - Register Workshop** assigns a key, delivery radius, nearby completion-notification radius, serviced side and optional delivery-area/exact-position map markers to the nearest object. Its exported call includes the same choices. **Register Vehicle** sets the matching key, damage and destroyed-vehicle policy, engineer restriction, recovery-object class, cargo preservation and restored fuel. Its friendly recovery-object dropdown is built from the mission-extensible `Waldo_Recovery_PackageClasses` pool. It can optionally replace immediate packaging with a simplified preparation procedure configured by enable, procedure and difficulty; repair is preselected. **Register Carrier** supports any nearby vehicle. Automatic handling uses its real configured vehicle cargo bay when a package fits and virtualizes otherwise; Virtual Manifest removes that engine dependency entirely, while Physical Cargo Bay deliberately enforces it. Loading range and a combined 1–10 package capacity are configurable. See [Vehicle Recovery and Squad Rally Points](Vehicle-Recovery-And-Squad-Rallies).

## AI Helicopter Landing

## UI Theme QA

**UI QA - Set Visual Theme** selects Default/Modern, Second World War, Vietnam/Cold War or Science Fiction styling. It changes presentation globally and can show the requesting curator a three-card semantic/stacking preview. See [UI Visual Themes](UI-Visual-Themes).

## Squad Rally Points

**Respawn - Squad Rally Control** enables or disables squad-leader rally actions and adjusts object class, duration, cooldown, enemy exclusion, group size, placement, slope and the optional direct-regroup ability. Disabling it also removes active rallies. See [Vehicle Recovery and Squad Rally Points](Vehicle-Recovery-And-Squad-Rallies).

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
