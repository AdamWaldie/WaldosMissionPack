# Waldos Mission Pack Zeus Modules

> **Use this page when:** you need to find, configure, or understand WMP's Zeus Enhanced modules.

## Requirements and location

These modules allow users to:
* Spawn a Logistics System Supply & Medical Crate to Zeus specification
* Set the mission to [ENDEX](ENDEX-Script-&-Custom-End-Screen)
* End the mission utilising the [Custom End](ENDEX-Script-&-Custom-End-Screen)
* Create and remove named [Dynamic Anti-Air](Dynamic-Anti-Air) systems
* Scale the nearest object through a validated server request
* Configure persistence, hazardous environments, emergency dismount and AI rebalance while the mission is running
* Register field-resupply hubs/carriers and tactical-display terminals
* Register, assign and operate airborne gunship support
* Register vehicle-recovery workshops, recoverable vehicles and recovery carriers
* Configure temporary squad rally respawns during play

WMP's Zeus modules require Zeus Enhanced. Find them under **Modules → Waldos Mission Modules**.

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

* **Radio Jammer - Place** — opens a dialog to set the jamming **radius**, **falloff**, **strength**, the **side** it jams, a directional **cone arc + bearing** (arc 360 = omnidirectional), whether it **pulses**, and whether to drop a **map marker**, then spawns an emitter at the module position and switches it on. The emitter is added to the curator so it can be dragged or deleted like any Zeus object.
* **Radio Jammer - Toggle Nearest** — flips the nearest jammer on or off (no dialog).
* **Radio Jammer - Remove Nearest** — removes the nearest jammer and deletes its emitter.

The Place dialog also offers a directional **cone**, **pulsing**, and an **also jam UAVs / drones** option (counter-UAS). See the [Radio Jamming](Radio-Jamming) page for the full scripting API and the ACRE2 signal-model requirement.

## EMP & Signal Tracker Modules

Two more electronic-warfare modules (full detail on the [EW: EMP & Signal Trackers](Electronic-Warfare-EMP-And-Signal-Trackers) page):

* **EMP Detonation** — a dialog for **radius** and **duration**, then detonates an electromagnetic pulse at the module position: infantry in range lose NVGs and TFAR radio use, vehicles have their engines cut, and players get a white-out flash and clear message. Units/vehicles marked with `Waldo_fnc_EMPImmune` are spared.
* **Plant Signal Tracker** — tags the nearest unit or vehicle so a chosen side follows it live on the map (hidden from the tracked side).

## Dynamic Anti-Air Modules

**Dynamic AA - Create** opens the system settings and then guides Zeus through radar, static-site and mobile-system placement on the map. **Dynamic AA - Remove Nearest** selects the active system nearest to the placed module and can either delete its assets or leave them disabled. See the [Dynamic Anti-Air guide](Dynamic-Anti-Air) for every option.

## Scale Object Module

Place **Scale Object** directly on the intended target and choose the multiplier. The server enforces the mission's configured minimum and maximum scale. Live curator use deliberately does not replace the selected object with a simple object; mission makers can still request that conversion through the scripted API during pre-planned setup.

## Optional Feature Runtime Modules

These modules are repeat-safe and send configuration through a server-authoritative curator request. Live setting bundles are applied on clients before their matching initializer runs. Joining players and headless clients request an ordered server snapshot before locality-sensitive features activate, while keyed JIP entries replay or clear the required initializer. Where a module offers **Copy setup script**, the copied call can be moved into mission setup for repeatable pre-planned use.

## Persistence

**Persistence - Control** enables or disables persistence and configures player/object save intervals and the supported data categories. Enabling still requires a compatible INIDBI2 server runtime; placing the module does not silently bypass the dependency gate.

**Persistence - Register Object** selects the nearest object within 25 metres and registers its cargo, damage, fuel, ammunition/pylons and/or transform under a stable key.

**Persistence - Save Now** can immediately request saves from connected players, registered objects, or both without disabling the system.

## Hazardous Environments

**Hazard - Create** creates a named circular hazard at the module position. Zeus can set its semantic type, player-facing label, range, exposure/recovery rates, damage threshold, protection rules and protective equipment. It can also copy a setup call for later mission authoring.

**Hazard - Remove Nearest** removes the registered hazard whose centre is nearest to the placed module.

## Emergency Dismount

**Emergency Dismount - Control** changes overturn and destroyed-vehicle triggers, velocity preservation, temporary protection, clear-position search, clearance checks, exit method and optional consciousness recovery.

## AI Rebalance

**AI Rebalance - Control** enables or disables the supported AI profile at runtime and selects day/night mode plus the Legacy, Public, Standard or Veteran balance profile. Legacy remains the compatibility default.

## Field Resupply

**Field Resupply - Register Hub** turns the object directly under the module into a side-restricted refill hub with finite or unlimited stock. If no object is under it, the server creates an empty `Logi_SupplyBoxClass` crate at the module position and registers that instead. **Field Resupply - Assign Carrier** gives the nearest infantry unit a current and maximum deployable-crate allowance. All creation, refill, deploy, take and salvage operations are validated by the server.

## Tactical Display

**Tactical Display - Register** turns the nearest object into a range-limited terminal. Players with proximity and line of sight can open its tactical map; it shows friendlies and only enemies already known to their group.

## Airborne Gunship Support

**Gunship - Register or Spawn** registers the nearest aircraft or creates a validated aircraft class at the module position. **Gunship - Assign Controller** assigns the nearest player to a named system. **Gunship - Set Orbit** sends the selected aircraft to the module position. **Gunship - Operational Control** returns it to its combat orbit, sends it through its service cycle, releases its operator or removes the system. See the [Airborne Gunship Support guide](Airborne-Gunship-Support).

## Vehicle Recovery

**Vehicle Recovery - Register Workshop** assigns a key, delivery radius, nearby completion-notification radius, serviced side and optional delivery-area/exact-position map markers to the nearest object. Its exported call includes the same choices. **Register Vehicle** sets the matching key, damage and destroyed-vehicle policy, engineer restriction, transport package, cargo preservation and restored fuel. **Register Carrier** adds validated package loading and unloading to the nearest vehicle. See [Vehicle Recovery and Squad Rally Points](Vehicle-Recovery-And-Squad-Rallies).

## Squad Rally Points

**Respawn - Squad Rally Control** enables or disables squad-leader rally actions and adjusts object class, duration, cooldown, enemy exclusion, group size, placement, slope and the optional direct-regroup ability. Disabling it also removes active rallies. See [Vehicle Recovery and Squad Rally Points](Vehicle-Recovery-And-Squad-Rallies).

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
