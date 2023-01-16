/*

Defence Construction Script

This function allows you to fake the construction of defences/objects/scenery from a single object via Ace Interaction

Setting Up in Eden;
	- Place the object or object that you want to have the respawn deployable from, and provide it a variable name
	- Place a Game Logic down as close as possible to the object. This can be found near the same menu as Modules.
	- Place any objects you wish to appear when the object is interactd with..
	- If you are using a object as your primary object and any of your deployable objects should be resting on the floor, then raise them about a foot, to allow for the drop of the object's suspension once the game has initialised.
	- Select all the objects that will be deployable, right-click and synchronise them to the Game Logic.
	- In the init of the object, paste the example below, and alter it to suit the needs you have.

Parameters:
_target - Vehicle or Object to use as the interactable to build synced objects from
_UseModernConsturctionAudio - boolean (true/false) | Options: True = Modern construction Noises, False = Old Wooden Sounding Construction Noises.

Call:

[_target,_UseModernConsturctionAudio] call Waldo_fnc_ConstructionObjects;

e.g.

[this,true] call Waldo_fnc_ConstructionObjects; - use modern audio


*/

params["_target",["_useModernConsturctionAudio",false]];

//Catch all for any not using ACE to prevent bad things
if !(isClass(configFile >> "CfgPatches" >> "ace_main")) exitwith {};

//Select Desired Audio For Pack/Unpack
_ConstructionAudioPath = "MissionScripts\Logistics\MHQ\Audio\Audio_Deploy_New.ogg";
if (_useModernConsturctionAudio == false) then {
	_ConstructionAudioPath = "MissionScripts\Logistics\MHQ\Audio\Audio_Deploy_Old.ogg"
};

// Finds all synced Objects. Hides the model and attaches the object to object.
_constructionLogic = nearestObject [_target, "Logic"]; 
_constructionParts = synchronizedObjects _constructionLogic;


if (isServer || isDedicated) then {
	_target setVariable ['Waldo_Construction_Status', false, true];
	[_constructionLogic, _target] call BIS_fnc_attachToRelative;
	{
		[_x, _target] call BIS_fnc_attachToRelative;
		[_x, true] remoteExec ["hideObjectGlobal", 2];
	} forEach _constructionParts;
};

Waldo_Construction_Deploy = {
	params ["_target", "_player","_ConstructionAudioPath"];
	_constructionLogic = nearestObject [_target, "Logic"]; 
	_constructionParts = synchronizedObjects _constructionLogic;
	{[_x, false] remoteExec ["hideObjectGlobal", 2];} forEach _constructionParts;
	_target setVariable ['Waldo_Construction_Status', true, true];
	playSound3d [getMissionPath _ConstructionAudioPath, _target, false, getPosASL _target, 4, 1];
	["Construction Completed", _player] call Waldo_fnc_DynamicText;
};

Waldo_Construction_TearDown = {
	params ["_target","_player","_ConstructionAudioPath"];
	_constructionLogic = nearestObject [_target, "Logic"]; 
	_constructionParts = synchronizedObjects _constructionLogic;
	{[_x, true] remoteExec ["hideObjectGlobal", 2];} forEach _constructionParts;
	_target setVariable ['Waldo_Construction_Status', false, true];	
	playSound3d [getMissionPath _ConstructionAudioPath, _target, false, getPosASL _target, 4, 1];
	["Construction Torn Down", _player] call Waldo_fnc_DynamicText;
};


//Action Start for adding RP
Waldo_Construction_InitDeploy = [
	"Waldo_Construction_InitDeploy",
	"Perform Construction Work",
	"\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_unloadVehicle_ca.paa",
	{
		// Runs on Action Called
		[10, [_target, _player,_ConstructionAudioPath], {
			_args call Waldo_Construction_Deploy;
		}, {["Construction Not Built", _player] call Waldo_fnc_DynamicText;}, "Constructing..."] call ace_common_fnc_progressBar;
	},
	{
		//[_target, _player, _actionParams] Condition
		!(_target getVariable 'Waldo_Construction_Status') && (_player distance _target) < 6;
	},
	{},
	[_ConstructionAudioPath],
	[],
	0,
	[false, false, false, false, false]
] call ace_interact_menu_fnc_createAction;

// Action for removing RP
Waldo_Construction_InitTeardown = [
	"Waldo_Construction_InitTeardown",
	"Tear Down Construction",
	"\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_loadVehicle_ca.paa",
	{
		// Runs on Action Called
		[10, [_target, _player,_ConstructionAudioPath], {
			_args call Waldo_Construction_TearDown;
		}, {["Construction Still Standing", _player] call Waldo_fnc_DynamicText;}, "Tearing Down...."] call ace_common_fnc_progressBar;
	},
	{
		//[_target, _player, _actionParams] Condition
		(_target getVariable 'Waldo_Construction_Status') && (_player distance _target) < 6;
	},
	{},
	[_ConstructionAudioPath],
	[],
	0,
	[false, false, false, false, false]
] call ace_interact_menu_fnc_createAction;

Waldo_Construction_Category = ["Waldo_Construction_Category" ,"Construction", "\a3\ui_f_oldman\data\IGUI\Cfg\holdactions\repair_ca.paa", {true}, {true}] call ace_interact_menu_fnc_createAction;

// Add action to Vehicle (ACE 3)
[_target,
	0, 
	["ACE_MainActions"], 
	Waldo_Construction_Category
] call ace_interact_menu_fnc_addActionToObject;

[_target,
	0, 
	["ACE_MainActions","Waldo_Construction_Category"], 
	Waldo_Construction_InitDeploy
] call ace_interact_menu_fnc_addActionToObject;

[_target,
	0, 
	["ACE_MainActions","Waldo_Construction_Category"], 
	Waldo_Construction_InitTeardown
] call ace_interact_menu_fnc_addActionToObject;