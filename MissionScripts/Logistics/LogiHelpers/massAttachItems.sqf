/*
This script attaches multiple objects to a vehicle object.

parameters:
_targetObject - variable name of the vehicle/object you wish to attach the objects to.


Setting Up in Eden;
	- Place the vehicle or object that you want to attach all other items to.
	- Place a Game Logic down as close as possible to the object. This can be found near the same menu as Modules.
	- Place any objects you wish to attach.
	- If you are using a vehicle as your primary object and any of your objects should be resting on the floor, then raise them about a foot, to allow for the drop of the vehicle's suspension once the game has initialised.
	- Select all the objects that will be attached, right-click and synchronise them to the Game Logic.
	- In the init of the vehicle, paste the example below, and alter it to suit the needs you have.

Example call:

In vehicle init:

[variableNameOfObjectToAttachOthersTo] call Waldo_fnc_MassAttachRelative;

*/

params["_targetObject"];

// Finds all synced Objects. Hides the model and attaches the object to vehicle.
_syncLogic = nearestObject [_targetObject, "Logic"]; 
_AttachingLayerContents = synchronizedObjects _syncLogic;

// Attach Relative Position to MHQ vehicle & hide globally
{
	call{0 = [_x, _targetObject, true] call BIS_fnc_attachToRelative;};
} forEach _AttachingLayerContents;