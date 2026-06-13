_Associated Files: MissionScripts\Logistics\MHQ\MHQSetup.sqf_

A script which allows for the creation of a command post, acting as a respawn position, you may choose to combine this with the logistics quartermaster script if so desired.

This can be both a stationary object, or a vehicle.

This allows a number of objects, as selected via the syncing of a named gamelogic to be attached to a vehicle, and "deployed"/"undeployed" on request when in a desired location.

### Setting Up in Eden:
* Place the vehicle or object that you want to have the respawn deployable from, and provide it a variable name. This will be known as the MHQ/CP in this tutorial.
* Place a Game Logic down as close as possible to the MHQ/CP. This can be found near the same menu as Modules.
* Place any objects you wish to appear when the respawn is deployed. Leave some room approx 3m to the left of the primary object to allow space for players to respawn.
* If you are using a vehicle as your primary object and any of your deployable objects should be resting on the floor, then raise them about a foot, to allow for the drop of the vehicle's suspension once the game has initialised.
* Select all the objects that will be deployable, right-click and synchronise them to the Game Logic.
* In the init of the MHQ/CP, paste the following: [this] call Waldo_fnc_MHQSetup;
* If you desire to utilise the modern construction audio, please use the example noting that below.
* That's it.
* (Optional) The file contains an array of all the potential names for the Command Posts, add some if you want or set it to just a smaller amount; just remember it's an array of strings within the selectRandom square brackets (If you don't know what any of that means, dont touch it!)

### Features:
* Allows any Vehicle or Object to be a deployable respawn. Vehicle will be attached to the vehicle during movement while object respawns are static.
* Creates a randomised Command Post name and marker on the map.
* Changes the respawn side depending on who deployed it.
* Allows for the optional deployment of logistics supplies if enabled and the [logistics System](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Logistics-System,-Starter-Crates-And-Quartermaster) is active.

Parameters:
* _target - Vehicle or Object to use as the Mobile headquarters
* _logistics - boolean as to whether to enable the logistics system on the MHQ
* _constructionAudio - boolean (true/false) | Options: True = Modern construction Noises, False = Old Wooden Sounding Construction Noises.
if _logistics is utilised:
* _logisticsDirection - determines the bearing around the vehicle the spawner will be. Based on vehicle heading, not compass. E.g 0 = Front, 90 = Right, 180 = Rear, 270 = Left.
* _logisticsDistance - determines how far away from the vehicle the logistics spawner will be.

Example:

Default:
`[this] call Waldo_fnc_MHQSetup; `

Modern construction audio:
`[this,true] call Waldo_fnc_MHQSetup;`

Logistics system with spawner 4m to the rear of the vehicle:
`[this,true,true,180,4] call Waldo_fnc_MHQSetup;`

Below is an example of a properly setup MHQ, the Halftrack is the interaction object:
![MHQ example](https://i.imgur.com/Rz9KwXL.png)

### Changing the Boxes The Quartermaster Spawns

**You can edit class of crate spawned for both medical and supply boxes in the initServer.sqf:**
![Picture displaying the appropriate place in Initserver.sqf to change the boxes](https://i.imgur.com/0CdEY8U.png)

**Logi_SupplyBoxClass** is the class of box which will spawn when ammo or resupply boxes are spawned.

**Logi_MedicalBoxClass** is the class of box which will spawn when a medical box is spawned.