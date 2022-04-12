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
_helipadSpawnPoint - Name of the invisible helipad you wish to use as the respawn position & logistics spawning position.
_side - Side you want the respawn positon to work for | Options: west,east,independent,civillian
_UseModernConsturctionAudio - boolean (true/false) | Options: True = Modern construction Noises, False = Old Wooden Sounding Construction Noises.
_logisticsSystemImplementation - boolean (true/false) | Options: True = Utilise Logistics System spawner, False = Do Not utilise logistics system spawner.

In order to use the logistics system, you must set _logisticsSystemImplementation = true in the parameters AND ensure that there is a base game helipad ("Land_HelipadEmpty_F") in the layer which contains the deployable objects.
You must give the helipad a variable name, and use that variable name in the _helipadSpawnPoint parameter. You should also give the MHQ itself a variable name and use it as the _MHQ parameter.

*/
params["_MHQ","_helipadSpawnPoint",["_side",west],["_useModernConsturctionAudio",false],["_logisticsSystemImplementation",false]];

//Get contents of layer defined by player
waitUntil { _MHQ getVariable ["Waldo_MHQ_ServerInit", false] };

//Select only obects from the [[Objects],[marker]] original return
private _layerContents = _MHQ getVariable "Waldo_MHQ_Layer";
//private _layerContents = _layerInfo select 0;
diag_log str _layerContents;

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
	"!(_target getVariable 'Waldo_MHQ_Status') && _this distance _target < 5",						// Condition for the action to be shown
	"_caller distance _target < 5 && {speed _target < 1}",						// Condition for the action to progress						
	{},//Codestart													
	{
		params ["_target", "_caller", "_actionId", "_arguments"];
		_arguments params["_MHQ","_layerContents","_helipadSpawnPoint","_MHQAudioPath","_side","_logisticsSystemImplementation"];
		_randPart = selectRandom _layerContents;
		[_randPart, false] remoteExec ["hideObjectGlobal", 2];
	},		//codeprogress											
	{
		params ["_target", "_caller", "_actionId", "_arguments", "_progress", "_maxProgress"];
		_arguments params["_MHQ","_layerContents","_helipadSpawnPoint","_MHQAudioPath","_side","_logisticsSystemImplementation"];
		{[_x, false] remoteExec ["hideObjectGlobal", 2];} forEach _layerContents;
		_MHQ engineOn false;
		if(isNull _helipadSpawnPoint) then {
			["Please Supply A Named Helipad In the MHQ layer"] remoteExec ["Hint",0];
			diag_log "MHQ Helipad Not Designated Or Found";
		};
		//Get unique markern name for respawn selection
		private _gridPos = mapGridPosition getPos _MHQ;
		private _markerText = format["Mobile HQ at %1",_gridPos];
		_respawnMarker = createMarker [_markerText, _MHQ, 1];
		//Add respawn
		MHQRespawn = [_side, _helipadSpawnPoint, _respawnMarker] call BIS_fnc_addRespawnPosition;
		diag_log MHQRespawn;
		//Set complete state on object
		_MHQ setVariable ['Waldo_MHQ_Status', true, true];
		{
			_x action ["Eject", vehicle _x];
		} forEach crew _MHQ;
		[_MHQ, "LOCKED"] remoteExec ["setVehicleLock", 0];
		playSound3d [getMissionPath _MHQAudioPath, _MHQ, false, getPosASL _MHQ, 4, 1];
		if (_logisticsSystemImplementation == true) then {
			[_MHQ,_helipadSpawnPoint,_side,"",true] remoteExec ["Waldo_fnc_SetupQuarterMaster",0,true];
			diag_log "MHQ Logistics Plugin Enabled";
		} else {
			diag_log "MHQ Logistics Plugin Disabled";
		};
	},				// Code executed on completion
	{
		params ["_target", "_caller", "_actionId", "_arguments"];
		_arguments params["_MHQ","_layerContents","_helipadSpawnPoint","_MHQAudioPath","_side","_logisticsSystemImplementation"];
		{[_x, true] remoteExec ["hideObjectGlobal", 2];} forEach _layerContents;
		_MHQ allowDamage false;
	},													//on failure
	[_MHQ,_layerContents,_helipadSpawnPoint,_MHQAudioPath,_side,_logisticsSystemImplementation],													// Arguments passed to script
	10,													// Action duration [s]
	0,													// Priority
	false,												// Remove on completion
	false												// Show in unconscious state
] call BIS_fnc_holdActionAdd;	// MP compatible implementation

[
	_MHQ,
	"Pack up Mobile Headquarters",											
	"\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_loadVehicle_ca.paa",	// Idle icon shown on screen
	"\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_loadVehicle_ca.paa",	// Progress icon shown on screen
	"(_target getVariable 'Waldo_MHQ_Status') && _this distance _target < 5",						// Condition for the action to be shown
	"_caller distance _target < 5 && {speed _target < 1}",						// Condition for the action to progress								
	{
		params ["_target", "_caller", "_actionId", "_arguments"];
		_arguments params["_MHQ","_layerContents","_helipadSpawnPoint","_MHQAudioPath","_side","_logisticsSystemImplementation"];
		_MHQ engineOn false;
	},													// Code executed when action starts
	{
		params ["_target", "_caller", "_actionId", "_arguments"];
		_arguments params["_MHQ","_layerContents","_helipadSpawnPoint","_MHQAudioPath","_side","_logisticsSystemImplementation"];
		_randPart = selectRandom _layerContents;
		[_randPart, true] remoteExec ["hideObjectGlobal", 2];
	},													// Code executed on tick
	{
		params ["_target", "_caller", "_actionId", "_arguments", "_progress", "_maxProgress"];
		_arguments params["_MHQ","_layerContents","_helipadSpawnPoint","_MHQAudioPath","_side","_logisticsSystemImplementation"];
		{[_x, true] remoteExec ["hideObjectGlobal", 2];} forEach _layerContents;
		_MHQ engineOn false;
		MHQRespawn call BIS_fnc_removeRespawnPosition;
		deleteMarker "Mobile HQ";
		[_MHQ, "UNLOCKED"] remoteExec ["setVehicleLock", 0];
		_MHQ setVariable ['Waldo_MHQ_Status', false, true];
		playSound3d [getMissionPath _MHQAudioPath, _MHQ, false, getPosASL _MHQ, 4, 1];
		if (_logisticsSystemImplementation == true) then {
			private _addActArray = _MHQ getVariable "Waldo_MHQ_QuarterMasterActions";
			diag_log _addActArray;
			{
				[_MHQ,_x] remoteExec ["removeAction",0,true];
			} forEach _addActArray;
		};
	},				// Code executed on completion
	{
		params ["_target", "_caller", "_actionId", "_arguments"];
		_arguments params["_MHQ","_layerContents","_helipadSpawnPoint","_MHQAudioPath","_side","_logisticsSystemImplementation"];
		{[_x, false] remoteExec ["hideObjectGlobal", 2];} forEach _layerContents;
		_MHQ allowDamage true;
	},													// Code on failure
	[_MHQ,_layerContents,_helipadSpawnPoint,_MHQAudioPath,_side,_logisticsSystemImplementation],													// Arguments passed to the script
	10,													// Action duration
	0,													// Priority
	false,												// Remove on completion
	false												// Show in unconscious state
] call BIS_fnc_holdActionAdd;	// MP compatible implementation


diag_log "MHQ Actions Added";