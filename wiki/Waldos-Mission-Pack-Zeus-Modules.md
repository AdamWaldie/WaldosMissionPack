# Waldos Mission Pack Zeus Modules

> **Use this page when:** you need to find, configure, or understand WMP's Zeus Enhanced modules.

## Requirements and location

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

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
