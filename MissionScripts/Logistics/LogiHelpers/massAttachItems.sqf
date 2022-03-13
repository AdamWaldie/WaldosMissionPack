/*
This script attaches multiple objects from a given layer to a vehicle object.

parameters:
_targetObject - variable name of the vehicle/object you wish to attach the turret to.
_nameOfLayerContainingObjects - name of the layer which contains the objects you would like to attach to the target object. In quotations ("").

Example call:

In vehicle init:

[variableNameOfObjectToAttachOthersTo,"nameOfLayerContainingObjects"] call Waldo_fnc_MassAttachRelative;

*/

params["_targetObject","_nameOfLayerContainingObjects"];

//Get contents of layer defined by player
private _AttachingLayerContents = getMissionLayerEntities _nameOfLayerContainingObjects;
//Select only obects from the [[Objects],[marker]] original return
_AttachingLayerContents = _AttachingLayerContents select 0;

// Attach Relative Position to MHQ vehicle & hide globally
{
	call{0 = [_x, _targetObject, true] call BIS_fnc_attachToRelative;};
} forEach _AttachingLayerContents;