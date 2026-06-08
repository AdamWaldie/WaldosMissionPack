_Associated Files: MissionScripts\Logistics\\VirtualVehicleDepot_

This script initiates a virtual vehicle depot spawner. It could be more pretty, but it does provide a large degree of functionality.

# Features

The VVD (Vitual Vehicle Depot) can perform the following actions:
* Spawn Vehicles
* Add/Remove damage to specific parts of the vehicle
* Change Weapons or Pylon setup where mod config allows
* Alter vehicles cosmetics
* Add/remove AI from each crew slot

# Setup

Parameters:
* _depotSpawnerObject - The item to add the spawner addactions onto
* _depotSpawnPoint - This should be a helipad, but a flat object on top of which the vehicle will be spawned
* _types - what should be allowed to be selected from this specific spawner, multiple can be given - Potential arguments: ["Auto","All","Car", "Tank", "Helicopter", "Plane", "Ship", "StaticWeapon"] "Auto" will look at the ground beneath it and select a type based on that.
* _sidesToAllowUseOfSpawner - Sides allowed to use the spawner - Potential Arguments: ["BLUFOR","OPFOR","INDEP", "CIV", "ALL"]
* _enforcePlayerSideToAccess - enforce that players must match the side of the spawner to get the vehicles
* _limitToSideVehicles - limit vehicles able to be spawned (but not viewed) to that matching the player side (Finicky and 50/50 working) Recommend leaving as false.
* _removeUavs - remove UAVs from the spawner (80/20 as to whether it works depending on mod config)
* _range - range from which you can view the interactions on the spawner
* _script - script to apply directly to the spawned vehicle, bypassing the garage.

Example Calls:

`[this, Circle_Helipad, ["All"], ["ALL"], false, false, false, 10, ""] call Waldo_fnc_VVDInit;` - Fully unrestricted vehicle spawner. See the below image for an example setup. The laptop is the interactable object, and Circle_Helipad refers to the parachute target. This example is available to you as part of the compositions provided in the pack. 

![Example of mission pack setup](https://i.imgur.com/0DkSWJl.png)
