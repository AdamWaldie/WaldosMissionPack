/*
Mobile Headquarters Script

A script which allows for the creation of a command post, acting as a respawn position, and logistics quartermaster if desired.

This allows a number of objects, as defined in a Eden Editor layer, to be attached to a vehicle, and "deployed"/"undeployed" on request when in a desired location.

When setup in initServer.sqf:
- Objects defined in the named layer are attached relative to their position to the target vehicle.
- Those same objects are then hidden globally.

When deployed the following occurs:
- Objects defined in the named layer are set as visible.
- A respawn position is enabled around the vehicle in quesiton.
- (Optional) A logistics quartermaster from the logistics module is added to the vehicle.
- (choice of one) Deployment sounds are played (old style wood & modern day construction noises)

When Un-deployed the following occurs:
- Objects defined in the named layer are set as invisible.
- The Mobile HQ Respawn position is disabled.
- (Optional) The Logistics Quartermaster is removed.
- (choice of one) Un-Deployment sounds are played (old style wood & modern day construction noises)

This is the Server Setup script.

Parameters for Waldo_fnc_ServerSetupMHQ:
_MHQVariableName - Variable name of the vehicle being used as the mHQ 
_layerName - the name of the eden editor layer which houses the objects which make up the Mobile Headquarters additional objects. THIS SHOULD NOT INCLUDE THE VEHICLE ITSELF! Quotation Marks required ("").

e.g.

From initServer.sqf:

[variableNameofMHQ,"layerName"] call Waldo_fnc_ServerSetupMHQ;

*/

params["_MHQVariableName","_layerName"];

_MHQVariableName setVariable ['Waldo_MHQ_Status', false, true];

//Get contents of layer defined by player
private _layerContents = getMissionLayerEntities _layerName;
//Select only obects from the [[Objects],[marker]] original return
_layerContents = _layerContents select 0;

// Attach Relative Position to MHQ vehicle & hide globally
{
	call{0 = [_x, _MHQVariableName] call BIS_fnc_attachToRelative;};
    [_x, true] remoteExec ["hideObjectGlobal", 2];
} forEach _layerContents;

//Set global variable for use
_MHQVariableName setVariable ['Waldo_MHQ_Layer', _layerContents, true];
//Prevent race conditions with flag.
_MHQVariableName setVariable ['Waldo_MHQ_ServerInit', true, true];
diag_log "MHQ ServerSetup Complete";