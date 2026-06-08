_Associated Files: MissionScripts\Logistics\Construction\ConstructionObjects.sqf_

This function allows you to fake the construction of defences/objects/scenery from a single object via Ace Interaction.

Objects must be pre-placed in the editor around the item you wish to build from, but the interactable object does not need to be stationary.

Construction objects can be transported in ACE cargo and retain its abilities.

### Setting Up in Eden;
* Place the object or object that you want to have the respawn deployable from, and provide it a variable name
* Place a Game Logic down as close as possible to the object. This can be found near the same menu as Modules.
* Place any objects you wish to appear when the object is interacted with..
* If you are using an object as your primary object and any of your deployable objects should be resting on the floor, then raise them about a foot, to allow for the drop of the object's suspension once the game has initialised.
* Select all the objects that will be deployable, right-click and synchronise them to the Game Logic.
* In the object's init, paste the example below, and alter it to suit your needs.

### Parameters:
* _target - Vehicle or Object to use as the interactable to build synced objects from
* _UseModernConsturctionAudio - boolean (true/false) | Options: True = Modern construction Noises, False = Old Wooden Sounding Construction Noises.

Call:

`[_target,_UseModernConsturctionAudio] call Waldo_fnc_ConstructionObjects;`

e.g.

`[this,true] call Waldo_fnc_ConstructionObjects; - use modern audio`

Below is an example of the construction script correctly setup. The ammo box is the object the player interacts with:
![Picture of the construction script in the editor](https://i.imgur.com/gYf9HQq.png)