/*

Defence Construction Script

"Build" defences from an object based on layer contents

This is the activation/deactivation script.

Setting Up in Eden;
	- Place the object or object that you want to have the respawn deployable from, and provide it a variable name
	- Place a Game Logic down as close as possible to the object. This can be found near the same menu as Modules.
	- Place any objects you wish to appear when the object is interactd with..
	- If you are using a object as your primary object and any of your deployable objects should be resting on the floor, then raise them about a foot, to allow for the drop of the object's suspension once the game has initialised.
	- Select all the objects that will be deployable, right-click and synchronise them to the Game Logic.
	- In the init of the object, paste the example below, and alter it to suit the needs you have.

Parameters:
_buildingObject - Vehicle or Object to use as the interactable to build synced objects from
_UseModernConsturctionAudio - boolean (true/false) | Options: True = Modern construction Noises, False = Old Wooden Sounding Construction Noises.

Call:

[_buildingObject,_UseModernConsturctionAudio] call Waldo_fnc_ConstructionObjects;

e.g.

[this,true] call Waldo_fnc_ConstructionObjects; - use modern audio


*/

params["_buildingObject",["_useModernConsturctionAudio",false]];

//Catch all for any not using ACE to prevent bad things
	if !(isClass(configFile >> "CfgPatches" >> "ace_main")) exitwith {};

	//Select Desired Audio For Pack/Unpack
	private _ConstructionAudioPath = "MissionScripts\Logistics\MHQ\Audio\Audio_Deploy_New.ogg";
	if (_useModernConsturctionAudio == false) then {
		_ConstructionAudioPath = "MissionScripts\Logistics\MHQ\Audio\Audio_Deploy_Old.ogg"
	};
	
	// Finds all synced Objects. Hides the model and attaches the object to object.
	_constructionLogic = nearestObject [_buildingObject, "Logic"]; 
	_constructionParts = synchronizedObjects _constructionLogic;
	

	if (isServer || isDedicated) then {
		_buildingObject setVariable ['Waldo_Construction_Status', false, true];
		[_constructionLogic, _buildingObject] call BIS_fnc_attachToRelative;
		{
			[_x, _buildingObject] call BIS_fnc_attachToRelative;
			[_x, true] remoteExec ["hideObjectGlobal", 2];
		} forEach _constructionParts;
	};

	waldo_CONSTRUCTION_Deploy = {
		params ["_buildingobject", "_player","_ConstructionAudioPath"];
		["Construction Completed", _player] call Waldo_fnc_DynamicText;
		_constructionLogic = nearestObject [_buildingObject, "Logic"]; 
		_constructionParts = synchronizedObjects _constructionLogic;
		{[_x, false] remoteExec ["hideObjectGlobal", 2];} forEach _constructionParts;
		playSound3d [getMissionPath _ConstructionAudioPath, _buildingobject, false, getPosASL _buildingobject, 4, 1];
		_buildingobject setVariable ['Waldo_Construction_Status', true, true];
	};

	waldo_CONSTRUCTION_TearDown = {
		params ["_buildingobject","_player","_ConstructionAudioPath"];
		_constructionLogic = nearestObject [_buildingObject, "Logic"]; 
		_constructionParts = synchronizedObjects _constructionLogic;
		{[_x, true] remoteExec ["hideObjectGlobal", 2];} forEach _constructionParts;
		playSound3d [getMissionPath _ConstructionAudioPath, _buildingobject, false, getPosASL _buildingobject, 4, 1];
		_buildingobject setVariable ['Waldo_Construction_Status', false, true];	
		["Construction Torn Down", _player] call Waldo_fnc_DynamicText;
	};
	
	
	//Action Start for adding RP
	waldo_Construction_InitBuild = [
		"waldo_Construction_InitBuild",
		"Perform Construction Work",
		"\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_unloadVehicle_ca.paa",
		{
			// Runs on Action Called
			
			[10, [_buildingobject, _player,_ConstructionAudioPath], {
				_args call waldo_CONSTRUCTION_Deploy;
			}, {["Construction Not Built", _player] call Waldo_fnc_DynamicText;}, "Constructing..."] call ace_common_fnc_progressBar;
		},
		{
			//[_buildingobject, _player, _actionParams] Condition
			!(_buildingObject getVariable 'Waldo_Construction_Status') && (_player distance _buildingobject) < 6;
		},
		{},
		[],
		[],
		0,
		[false, false, false, false, false]
	] call ace_interact_menu_fnc_createAction;

	// Action for removing RP
	waldo_Construction_InitTeardown = [
		"waldo_Construction_InitTeardown",
		"Tear Down Construction",
		"\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_loadVehicle_ca.paa",
		{
			// Runs on Action Called
			
			[10, [_buildingobject, _player,_ConstructionAudioPath], {
				_args call waldo_CONSTRUCTION_TearDown;
			}, {[_duration, "Construction Still Standing", _player] call Waldo_fnc_DynamicText;}, "Tearing Down...."] call ace_common_fnc_progressBar;
		},
		{
			//[_buildingobject, _player, _actionParams] Condition
			(_buildingObject getVariable 'Waldo_Construction_Status') && (_player distance _buildingobject) < 6;
		},
		{},
		[],
		[],
		0,
		[false, false, false, false, false]
	] call ace_interact_menu_fnc_createAction;
	
	// Add action to Vehicle (ACE 3)
	[_buildingobject,
		0, 
		["ACE_MainActions"], 
		waldo_Construction_InitBuild
	] call ace_interact_menu_fnc_addActionToObject;

	[_buildingobject,
		0, 
		["ACE_MainActions"], 
		waldo_Construction_InitTeardown
	] call ace_interact_menu_fnc_addActionToObject;