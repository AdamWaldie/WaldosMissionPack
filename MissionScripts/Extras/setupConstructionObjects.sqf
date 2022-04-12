/*
Defence Construction Script

"Build" defences from an object based on layer contents

This is the Server Setup script.

Parameters for Waldo_fnc_ServerSetupMHQ:
_buildingObject - Variable name of the vehicle being used as the interaction point 
_layerName - the name of the eden editor layer which houses the objects which make up the Mobile Headquarters additional objects. THIS SHOULD NOT INCLUDE THE VEHICLE ITSELF! Quotation Marks required ("").

Call:

[_buildingObject,_layerName] call Waldo_fnc_SetupConstructionObjects;

e.g.

[logiCrate,"constructionobjectlayer"] call Waldo_fnc_SetupConstructionObjects;


*/

params["_buildingObject","_layerName"];

/Get contents of layer defined by player
private _layerContents = getMissionLayerEntities _layerName;
//Select only obects from the [[Objects],[marker]] original return
_layerContents = _layerContents select 0;

// Hide all layer contents globally
{
	[_x, true] remoteExec ["hideObjectGlobal", 2];
} forEach _layerContents;

//Set global variable for use
_buildingObject setVariable ['Waldo_Construction_Layer', _layerContents, true];
//Prevent race conditions with flag.
_buildingObject setVariable ['Waldo_Construction_ServerInit', true, true];