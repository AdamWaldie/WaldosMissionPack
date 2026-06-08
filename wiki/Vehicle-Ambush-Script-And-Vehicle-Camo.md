_Associated Files: MissionScripts\Logistics\VehicleCamoScript\vehicleCamo.sqf_

A script which allows for the creation of "camo" objects to assist in hiding a vehicle in ambush. The script also accounts for limited dismounted movement around the vehicle in concealment (civ).

If the Player:
* Is spotted
* Fires the vehicles weapons
* Moves more than 40 meters from the vehicle
* Takes damage (Player or vehicle)

The player is returned to their side (potential game-restricted delay of up to 30 seconds) however the camo objects will remain until the vehicle moves, or the camo is removed by the indicated ace action.

Designed for vehicles.

### Setting Up in Eden;
* Place the vehicle or object that you want to have the respawn deployable from, and provide it a variable name
* Place a Game Logic down as close as possible to the vehicle. This can be found near the same menu as Modules.
* Place any objects you wish to appear when the camo is deployed.
* If you are using a vehicle as your primary object and any of your deployable objects should be resting on the floor, then raise them about a foot, to allow for the drop of the vehicle's suspension once the game has initialised.
* Select all the objects that will be deployable, right-click and synchronise them to the Game Logic.
* In the init of the vehicle, paste the example below, and alter it to suit the needs you have.

### Parameters:
* _target - Vehicle or Object to deploy camo from.

Example:

`[this] call Waldo_fnc_VehicleCamoSetup;`

Below is an example of a setup camo system in the eden editor. The Nazi Tank is the interaction object:
![Camo script example in the editor](https://i.imgur.com/dlyoKsk.png)
