# Zeus Modules Features

The packs Zeus Modules require the mission maker to be utilising Zeus Enhanced.

These modules allow users to:
* Spawn a Logistics System Supply & Medical Crate to Zeus specification
* Set the mission to [ENDEX](https://github.com/AdamWaldie/WaldosMissionPack/wiki/ENDEX-Script-&-Custom-End-Screen)
* End the mission utilising the [Custom End](https://github.com/AdamWaldie/WaldosMissionPack/wiki/ENDEX-Script-&-Custom-End-Screen)

All Zeus modules provided by this pack can be found in Modules --> Waldos Mission Modules

![Image of the Zeus Modules and where they can be located](https://i.imgur.com/kdR1q9Z.png)

# Supply & Medical Crate Spawner

Zeus-spawned crates use the same class names as the standard [Logistics System](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Logistics-System,-Starter-Crates-And-Quartermaster), so changing the crates will carry over into zeus.

## Supply Crate Interace
![Zeus Interface of supply crate spawner](https://i.imgur.com/iuiulsL.jpg)

The supply crate interface allows the Zeus to select the size of resupply available in the crate, which side to draw players gear from, and whether to include equipment, weapons, attachments and items, launchers and launcer ammo, or just ammo.

## Medical Supply Crate Interface
![Zeus Interface of Medical Crate Spawner](https://i.imgur.com/7aZPysV.png)

The medical crate interface allows the Zeus to select the size of medical resupply available in the crate and whether to make the crate an ACE field hospital for improved medical proficiency for medical personnel in the surrounding area.

# Fortify Budget Module

This module requires the [Automatic Fortify Setup](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Automatic-ACE-Fortify-Setup), or ACE Fortify being active. It allows for the alteration of the fortify budget in zeus, without the need for manual scripting.

![Fortify Budget Module GUI](https://i.imgur.com/GYunnuf.jpg)

# ENDEX Module

The ENDEX module performs the following actions:
* Places all player weapons on Safe and prevents Players and player vehicles from firing.
* Makes all Hostile AI Passive
* Fully Heals all Players & Makes them invincible
* Creates a popup informing players that the mission is over and to congregate together for debriefing.
* If a player tries to fire their weapon or use grenades, it is deleted and a popup tells them to cease firing.

It does NOT end the mission.

An example of it in use can be seen below:
![Zeus Endex execution example](https://i.imgur.com/PBpewY8.png)

# Mission End

Similar to the vanilla mission end script, this mission will end the scenario.

However, this variation allows the zeus to end the mission utilising a custom end screen and debriefing message which can be customised in the description.ext. Check out the [ENDEX Script & Custom End Screen](https://github.com/AdamWaldie/WaldosMissionPack/wiki/ENDEX-Script-&-Custom-End-Screen) tutorial for more information.

Below is an example of the custom mission end screen:
![Mission End Screen Example](https://i.imgur.com/xmK9I1e.png)