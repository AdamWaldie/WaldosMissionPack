/*

Defence Construction Script

"Build" defences from an object based on layer contents

This is the activation/deactivation script.

Parameters:
_buildingObject - Vehicle or Object to use as the Mobile headquarters
_UseModernConsturctionAudio - boolean (true/false) | Options: True = Modern construction Noises, False = Old Wooden Sounding Construction Noises.

Call:

[_buildingObject,_UseModernConsturctionAudio] call Waldo_fnc_AddConstructionActions;

e.g.

[logiCrate,true] call Waldo_fnc_AddConstructionActions;


*/

params["_buildingObject",["_useModernConsturctionAudio",false]];

//Get contents of layer defined by player
waitUntil { _buildingObject getVariable ["Waldo_Construction_ServerInit", false] };

//Select only obects from the [[Objects],[marker]] original return
private _layerContents = _buildingObject getVariable "Waldo_Construction_Layer";
//private _layerContents = _layerInfo select 0;

//Select Desired Audio For Pack/Unpack
private _buildingObjectAudioPath = "MissionScripts\Logistics\MHQ\Audio\Audio_Deploy_New.ogg";
if (_useModernConsturctionAudio == false) then {
	_buildingObjectAudioPath = "MissionScripts\Logistics\MHQ\Audio\Audio_Deploy_Old.ogg"
};

[
	_buildingObject,											
	"Build Field Defences",										
	"\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_loadVehicle_ca.paa",	// Idle icon shown on screen
	"\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_loadVehicle_ca.paa",	// Progress icon shown on screen
	"!(_target getVariable 'Waldo_buildingObject_Status') && _this distance _target < 5",						// Condition for the action to be shown
	"_caller distance _target < 5 && {speed _target < 1}",						// Condition for the action to progress						
	{},//Codestart													
	{
		params ["_target", "_caller", "_actionId", "_arguments"];
		_arguments params["_buildingObject","_layerContents","_buildingObjectAudioPath"];
		_randPart = selectRandom _layerContents;
		[_randPart, false] remoteExec ["hideObjectGlobal", 2];
	},		//codeprogress											
	{
		params ["_target", "_caller", "_actionId", "_arguments", "_progress", "_maxProgress"];
		_arguments params["_buildingObject","_layerContents","_buildingObjectAudioPath"];
		{[_x, false] remoteExec ["hideObjectGlobal", 2];} forEach _layerContents;
		_buildingObject setVariable ['Waldo_buildingObject_Status', true, true];
		playSound3d [getMissionPath _buildingObjectAudioPath, _buildingObject, false, getPosASL _buildingObject, 4, 1];
	},				// Code executed on completion
	{
		params ["_target", "_caller", "_actionId", "_arguments"];
		_arguments params["_buildingObject","_layerContents","_buildingObjectAudioPath"];
		{[_x, true] remoteExec ["hideObjectGlobal", 2];} forEach _layerContents;
	},													//on failure
	[_buildingObject,_layerContents,_buildingObjectAudioPath],													// Arguments passed to script
	30,													// Action duration [s]
	0,													// Priority
	false,												// Remove on completion
	false												// Show in unconscious state
] call BIS_fnc_holdActionAdd;	// MP compatible implementation

[
	_buildingObject,
	"Tear Down Defences",											
	"\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_loadVehicle_ca.paa",	// Idle icon shown on screen
	"\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_loadVehicle_ca.paa",	// Progress icon shown on screen
	"(_target getVariable 'Waldo_buildingObject_Status') && _this distance _target < 5",						// Condition for the action to be shown
	"_caller distance _target < 5 && {speed _target < 1}",						// Condition for the action to progress								
	{
		params ["_target", "_caller", "_actionId", "_arguments"];
		_arguments params["_buildingObject","_layerContents","_buildingObjectAudioPath"];
	},													// Code executed when action starts
	{
		params ["_target", "_caller", "_actionId", "_arguments"];
		_arguments params["_buildingObject","_layerContents","_buildingObjectAudioPath"];
		_randPart = selectRandom _layerContents;
		[_randPart, true] remoteExec ["hideObjectGlobal", 2];
	},													// Code executed on tick
	{
		params ["_target", "_caller", "_actionId", "_arguments", "_progress", "_maxProgress"];
		_arguments params["_buildingObject","_layerContents","_buildingObjectAudioPath"];
		{[_x, true] remoteExec ["hideObjectGlobal", 2];} forEach _layerContents;
        playSound3d [getMissionPath _buildingObjectAudioPath, _buildingObject, false, getPosASL _buildingObject, 4, 1];
        _buildingObject setVariable ['Waldo_buildingObject_Status', false, true];
	},				// Code executed on completion
	{
		params ["_target", "_caller", "_actionId", "_arguments"];
		_arguments params["_buildingObject","_layerContents","_buildingObjectAudioPath"];
		{[_x, false] remoteExec ["hideObjectGlobal", 2];} forEach _layerContents;
	},													// Code on failure
	[_buildingObject,_layerContents,_buildingObjectAudioPath],													// Arguments passed to the script
	30,													// Action duration
	0,													// Priority
	false,												// Remove on completion
	false												// Show in unconscious state
] call BIS_fnc_holdActionAdd;	// MP compatible implementation


diag_log "Construction Actions Added";