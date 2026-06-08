_Associated Files: MissionScripts\Logistics\LogiHelpers\massAttachItems.sqf_

This script attaches multiple objects to a second object.

Setting Up in Eden;
* Place the vehicle or object you want to attach to all other items.
* Place a Game Logic down as close as possible to the object. This can be found near the same menu as Modules.
* Place any objects you wish to attach.
* If you are using a vehicle as your primary object and any of your objects should be resting on the floor, then raise them about a foot, to allow for the drop of the vehicle's suspension once the game has been initialised.
* Select all the objects that will be attached, right-click and synchronise them to the Game Logic.
* In the init of the vehicle, paste the example below, and alter it to suit your needs.

Parameters:
* _targetObject - the variable name of the vehicle/object you wish to attach the synchronised objects to.

Example call:

In vehicle init:

`[variableNameOfObjectToAttachOthersTo] call Waldo_fnc_MassAttachRelative;`