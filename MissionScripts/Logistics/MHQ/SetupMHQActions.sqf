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

This is the MHQ activation/deactivation script.

Parameters:
_MHQ - Vehicle or Object to use as the Mobile headquarters
_editorObjectsLayer - Name of the Eden editor layer which houses the additional objects which make up the deployed MHQ. Should be in quoatation marks (e.g. "edenLayerName")
_side - Side you want the respawn positon to work for | Options: west,east,independent,civillian
_UseModernConsturctionAudio - boolean (true/false) | Options: True = Modern construction Noises, False = Old Wooden Sounding Construction Noises.
_logisticsSystemImplementation - boolean (true/false) | Options: True = Utilise Logistics System spawner, False = Do Not utilise logistics system spawner.

In order to use the logistics system, you must set _logisticsSystemImplementation = true in the parameters AND ensure that there is a base game helipad ("Land_HelipadEmpty_F") in the layer which contains the deployable objects.

*/
params["_MHQ","_editorObjectsLayer",["_side",west],["_useModernConsturctionAudio",true],["_logisticsSystemImplementation",false]];

//Get contents of layer defined by player
private _layerInfo = getMissionLayerEntities _editorObjectsLayer;
//Select only obects from the [[Objects],[marker]] original return
private _layerContents = _layerInfo select 0;

//Select Desired Audio For Pack/Unpack
private _MHQAudioPath = "MissionScripts\Logistics\MHQ\Audio\Audio_Deploy_New.ogg";
if (_useModernConsturctionAudio == false) then {
	_MHQAudioPath = "MissionScripts\Logistics\MHQ\Audio\Audio_Deploy_Old.ogg"
};

[
	_MHQ,											
	"Deploy Mobile Headquarters",										
	"\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_loadVehicle_ca.paa",	// Idle icon shown on screen
	"\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_loadVehicle_ca.paa",	// Progress icon shown on screen
	"!(missionNamespace getVariable 'Waldo_MHQ_Status') && _this distance _target < 5",						// Condition for the action to be shown
	"_caller distance _target < 5 && {speed _target < 1}",						// Condition for the action to progress						
	{},//Codestart													
	{
		params ["_target", "_caller", "_actionId", "_arguments"];
		_arguments params["_MHQ","_layerContents","_MHQAudioPath","_side","_logisticsSystemImplementation"];
		_randPart = selectRandom _layerContents;
		[_randPart, false] remoteExec ["hideObjectGlobal", 0];
	},		//codeprogress											
	{
		params ["_target", "_caller", "_actionId", "_arguments", "_progress", "_maxProgress"];
		_arguments params["_MHQ","_layerContents","_MHQAudioPath","_side","_logisticsSystemImplementation"];
		{[_x, false] remoteExec ["hideObjectGlobal", 0];} forEach _layerContents;
		_MHQ engineOn false;
		_RandomObjectSelection = selectRandom _layerContents;
		MHQRespawn = [_side, _RandomObjectSelection, "Mobile Headquarters"] call BIS_fnc_addRespawnPosition;
		missionNamespace setVariable ['Waldo_MHQ_Status', true, true];
		{
			_x action ["Eject", vehicle _x];
		} forEach crew _MHQ;
		[_MHQ, "LOCKED"] remoteExec ["setVehicleLock", 0];
		//["TaskSucceeded",["","Forward Respawn Position Available"]] call BIS_fnc_showNotification;
		playSound3d [getMissionPath _MHQAudioPath, _MHQ];
		if (_logisticsSystemImplementation == true) then {
			private _arrayIndexOfHelipad = -1;
			_arrayIndexOfHelipad = _layerContents findif {typeof _X == "Land_HelipadEmpty_F"};
			if (_arrayIndexOfHelipad != -1) then {
				private _spawnerObject =  _layerContents select _arrayIndexOfHelipad;
				private _MHQAddactions = [_MHQ,_spawnerObject] call Waldo_fnc_SetupQuarterMaster;
				missionNamespace setVariable ['Waldo_MHQ_QuarterMasterActions', _MHQAddactions, true];
				diag_log "MHQ Logistics Plugin Enabled: Helipad Found";
			} else {
				diag_log "MHQ Logistics Plugin Enabled: Helipad Not Found";
				hint "To use logistics spawner with this module, you must include exactly one 'Land_HelipadEmpty_F'";
			};
		};
	},				// Code executed on completion
	{
		params ["_target", "_caller", "_actionId", "_arguments"];
		_arguments params["_MHQ","_layerContents","_MHQAudioPath","_side","_logisticsSystemImplementation"];
		{[_x, true] remoteExec ["hideObjectGlobal", 0];} forEach _layerContents;
		_MHQ allowDamage false;
	},													//on failure
	[_MHQ,_layerContents,_MHQAudioPath,_side,_logisticsSystemImplementation],													// Arguments passed to script
	12,													// Action duration [s]
	0,													// Priority
	false,												// Remove on completion
	false												// Show in unconscious state
] call BIS_fnc_holdActionAdd;	// MP compatible implementation

[
	_MHQ,
	"Pack up Mobile Headquarters",											
	"\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_loadVehicle_ca.paa",	// Idle icon shown on screen
	"\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_loadVehicle_ca.paa",	// Progress icon shown on screen
	"missionNamespace getVariable 'Waldo_MHQ_Status' && _this distance _target < 5",						// Condition for the action to be shown
	"_caller distance _target < 5 && {speed _target < 1}",						// Condition for the action to progress								
	{
		params ["_target", "_caller", "_actionId", "_arguments"];
		_arguments params["_MHQ","_layerContents","_MHQAudioPath","_side","_logisticsSystemImplementation"];
		_MHQ engineOn false;
	},													// Code executed when action starts
	{
		params ["_target", "_caller", "_actionId", "_arguments"];
		_arguments params["_MHQ","_layerContents","_MHQAudioPath","_side","_logisticsSystemImplementation"];
		_randPart = selectRandom _layerContents;
		[_randPart, true] remoteExec ["hideObjectGlobal", 0];
	},													// Code executed on tick
	{
		params ["_target", "_caller", "_actionId", "_arguments", "_progress", "_maxProgress"];
		_arguments params["_MHQ","_layerContents","_MHQAudioPath","_side","_logisticsSystemImplementation"];
		{[_x, true] remoteExec ["hideObjectGlobal", 0];} forEach _layerContents;
		_MHQ engineOn false;
		MHQRespawn call BIS_fnc_removeRespawnPosition;
		[_MHQ, "UNLOCKED"] remoteExec ["setVehicleLock", 0];
		missionNamespace setVariable ['Waldo_MHQ_Status', false, true];
		//["TaskCanceled",["","Command Respawn Unavailable"]] call BIS_fnc_showNotification;
		playSound3d [getMissionPath _MHQAudioPath, _MHQ];
		if (_logisticsSystemImplementation == true) then{
			private _addActArray = missionNamespace getVariable "Waldo_MHQ_QuarterMasterActions";
			{
				_MHQ removeAction _x;
			} forEach _addActArray;
		};
	},				// Code executed on completion
	{
		params ["_target", "_caller", "_actionId", "_arguments"];
		_arguments params["_MHQ","_layerContents","_MHQAudioPath","_side","_logisticsSystemImplementation"];
		{[_x, false] remoteExec ["hideObjectGlobal", 0];} forEach _layerContents;
		_MHQ allowDamage true;
	},													// Code on failure
	[_MHQ,_layerContents,_MHQAudioPath,_side,_logisticsSystemImplementation],													// Arguments passed to the script
	12,													// Action duration
	0,													// Priority
	false,												// Remove on completion
	false												// Show in unconscious state
] call BIS_fnc_holdActionAdd;	// MP compatible implementation


diag_log "MHQ Actions Added";