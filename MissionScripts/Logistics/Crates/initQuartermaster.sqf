/*//    INFO TEXT    //// ==========================================================================================

This is used to setup the logistics spawning system, via the "Quartermaster". The quartermaster is an object or NPC which acts as the spawner for these supply boxes & equipment.

Params:
_target - The quartermaster from which you can select these actions
_offsetDegrees - determines the bearing around the vehicle the spawner will be. Based on vehicle heading, not compass. E.g 0 = Front, 90 = Right, 180 = Rear, 270 = Left.
_offsetDistance - determines how far away from the vehicle the logistics spawner will be.

Exemplar:

[this] call Waldo_fnc_SetupQuarterMaster; 

//With custom direction,distance of spawner from object
[this,180,4] call Waldo_fnc_SetupQuarterMaster; 

*/


params["_target",["_offsetDegrees",90],["_offsetDistance",2]];
//Catch all for any not using ACE to prevent bad things
if !(isClass(configFile >> "CfgPatches" >> "ace_main")) exitwith {};

//Add a flag for usage of the actions, so that they can be disabled/enabled via MHQ, scripts or other means.
if (isServer || isDedicated) then {
    _target setVariable ["Waldo_LogisticsQM_CurrentStatus", true, true];
};

Waldo_QM_Medbox = {
    params ["_target", "_player","_offsetDegrees","_offsetDistance"];
    [_target, _player, "Medical",_offsetDegrees,_offsetDistance] call Waldo_fnc_LogisticsSpawner;
};
Waldo_QM_Ammobox = {
    params ["_target", "_player","_offsetDegrees","_offsetDistance"];
    [_target, _player, "Ammo",_offsetDegrees,_offsetDistance] call Waldo_fnc_LogisticsSpawner;
};
Waldo_QM_Fullbox = {
    params ["_target", "_player","_offsetDegrees","_offsetDistance"];
    [_target, _player, "Supply",_offsetDegrees,_offsetDistance] call Waldo_fnc_LogisticsSpawner;
};
Waldo_QM_Track = {
    params ["_target", "_player","_offsetDegrees","_offsetDistance"];
    [_target, _player, "Track",_offsetDegrees,_offsetDistance] call Waldo_fnc_LogisticsSpawner;
};
Waldo_QM_Wheel = {
    params ["_target", "_player","_offsetDegrees","_offsetDistance"];
    [_target, _player, "Wheel",_offsetDegrees,_offsetDistance] call Waldo_fnc_LogisticsSpawner;
};

Waldo_QM_InitMedBox = [
	"Waldo_QM_InitMedBox",
	"Retrieve Medical Box",
	"\a3\missions_f_oldman\data\img\holdactions\holdAction_box_ca.paa",
	{
		params ["_target","_player","_args"];
		_args params ["_ConstructionAudioPath","_offsetDegrees","_offsetDistance"];
		// Runs on Action Called
		[10, [_target, _player,_ConstructionAudioPath,_offsetDegrees,_offsetDistance], {
			_args call Waldo_QM_Medbox;
		}, {["Medical Box Left In Storage.", _player] call Waldo_fnc_DynamicText;}, "Rummaging Through The Stores."] call ace_common_fnc_progressBar;
	},
	{
		//[_target, _player, _actionParams] Condition
		(_target getVariable 'Waldo_LogisticsQM_CurrentStatus') && (_player distance _target) < 6 && speed _target < 1;
	},
	{},
	[_offsetDegrees,_offsetDistance],
	[],
	0,
	[false, false, false, false, false]
] call ace_interact_menu_fnc_createAction;

Waldo_QM_InitAmmoBox = [
	"Waldo_QM_InitAmmoBox",
	"Retrieve Ammo Box",
	"\a3\missions_f_oldman\data\img\holdactions\holdAction_box_ca.paa",
	{
		params ["_target","_player","_args"];
		_args params ["_ConstructionAudioPath","_offsetDegrees","_offsetDistance"];
		// Runs on Action Called
		[10, [_target, _player,_ConstructionAudioPath,_offsetDegrees,_offsetDistance], {
			_args call Waldo_QM_Ammobox;
		}, {["Ammo Box Left In Storage.", _player] call Waldo_fnc_DynamicText;}, "Rummaging Through The Stores."] call ace_common_fnc_progressBar;
	},
	{
		//[_target, _player, _actionParams] Condition
		(_target getVariable 'Waldo_LogisticsQM_CurrentStatus') && (_player distance _target) < 6 && speed _target < 1;
	},
	{},
	[_offsetDegrees,_offsetDistance],
	[],
	0,
	[false, false, false, false, false]
] call ace_interact_menu_fnc_createAction;

Waldo_QM_InitFullBox = [
	"Waldo_QM_InitFullBox",
	"Retrieve Supply Box",
	"\a3\missions_f_oldman\data\img\holdactions\holdAction_box_ca.paa",
	{
		params ["_target","_player","_args"];
		_args params ["_ConstructionAudioPath","_offsetDegrees","_offsetDistance"];
		// Runs on Action Called
		[10, [_target, _player,_ConstructionAudioPath,_offsetDegrees,_offsetDistance], {
			_args call Waldo_QM_Fullbox;
		}, {["Supply Box Left In Storage.", _player] call Waldo_fnc_DynamicText;}, "Rummaging Through The Stores."] call ace_common_fnc_progressBar;
	},
	{
		//[_target, _player, _actionParams] Condition
		(_target getVariable 'Waldo_LogisticsQM_CurrentStatus') && (_player distance _target) < 6 && speed _target < 1;
	},
	{},
	[_offsetDegrees,_offsetDistance],
	[],
	0,
	[false, false, false, false, false]
] call ace_interact_menu_fnc_createAction;

Waldo_QM_InitTrack = [
	"Waldo_QM_InitTrack",
	"Retrieve Spare Track",
	"\a3\missions_f_oldman\data\img\holdactions\holdAction_box_ca.paa",
	{
		params ["_target","_player","_args"];
		_args params ["_ConstructionAudioPath","_offsetDegrees","_offsetDistance"];
		// Runs on Action Called
		[10, [_target, _player,_ConstructionAudioPath,_offsetDegrees,_offsetDistance], {
			_args call Waldo_QM_Track;
		}, {["Spare Track Left In Storage.", _player] call Waldo_fnc_DynamicText;}, "Rummaging Through The Stores."] call ace_common_fnc_progressBar;
	},
	{
		//[_target, _player, _actionParams] Condition
		(_target getVariable 'Waldo_LogisticsQM_CurrentStatus') && (_player distance _target) < 6 && speed _target < 1;
	},
	{},
	[_offsetDegrees,_offsetDistance],
	[],
	0,
	[false, false, false, false, false]
] call ace_interact_menu_fnc_createAction;

Waldo_QM_InitWheel = [
	"Waldo_QM_InitWheel",
	"Retrieve Spare Wheel",
	"\a3\missions_f_oldman\data\img\holdactions\holdAction_box_ca.paa",
	{
		params ["_target","_player","_args"];
		_args params ["_ConstructionAudioPath","_offsetDegrees","_offsetDistance"];
		// Runs on Action Called
		[10, [_target, _player,_ConstructionAudioPath,_offsetDegrees,_offsetDistance], {
			_args call Waldo_QM_Wheel;
		}, {["Spare Track Left In Storage.", _player] call Waldo_fnc_DynamicText;}, "Rummaging Through The Stores."] call ace_common_fnc_progressBar;
	},
	{
		//[_target, _player, _actionParams] Condition
		(_target getVariable 'Waldo_LogisticsQM_CurrentStatus') && (_player distance _target) < 6 && speed _target < 1;
	},
	{},
	[_offsetDegrees,_offsetDistance],
	[],
	0,
	[false, false, false, false, false]
] call ace_interact_menu_fnc_createAction;


// Add action to Vehicle (ACE 3)

Waldo_QM_Category = [
	"Waldo_QM_Category" ,
	"Logistics Quartermaster",
	"\a3\missions_f_oldman\data\img\holdactions\holdAction_box_ca.paa",
	{true},
	{true}
] call ace_interact_menu_fnc_createAction;

Waldo_QM_DeployPlease = [
	"Waldo_QM_DeployPlease" ,
	"Deploy To Access",
	"\a3\missions_f_oldman\data\img\holdactions\holdAction_box_ca.paa",
	{true},
	{!(_target getVariable 'Waldo_LogisticsQM_CurrentStatus');}
] call ace_interact_menu_fnc_createAction;

[_target,
	0, 
	["ACE_MainActions"], 
	Waldo_QM_Category
] call ace_interact_menu_fnc_addActionToObject;

[_target,
	0, 
	["ACE_MainActions","Waldo_QM_Category"], 
	Waldo_QM_DeployPlease
] call ace_interact_menu_fnc_addActionToObject;

[_target,
	0, 
	["ACE_MainActions","Waldo_QM_Category"], 
	Waldo_QM_InitMedBox
] call ace_interact_menu_fnc_addActionToObject;

[_target,
	0, 
	["ACE_MainActions","Waldo_QM_Category"], 
	Waldo_QM_InitAmmoBox
] call ace_interact_menu_fnc_addActionToObject;

[_target,
	0, 
	["ACE_MainActions","Waldo_QM_Category"], 
	Waldo_QM_InitFullBox
] call ace_interact_menu_fnc_addActionToObject;

[_target,
	0, 
	["ACE_MainActions","Waldo_QM_Category"], 
	Waldo_QM_InitTrack
] call ace_interact_menu_fnc_addActionToObject;

[_target,
	0, 
	["ACE_MainActions","Waldo_QM_Category"], 
	Waldo_QM_InitWheel
] call ace_interact_menu_fnc_addActionToObject;