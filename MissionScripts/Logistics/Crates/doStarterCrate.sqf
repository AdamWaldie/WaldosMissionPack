/*
Function with the purpose of simplifying the setup of starter crates.

Does the following:
- Adds addaction to allow for the saving of loadout
- Adds limited Ace Arsenal (Mission.sqm bound)
- Adds full supplies (Both Medical & Standard) (Mission.sqm bound)


parameters:
_target - the object variable name you want this to apply to
_arsenal - boolean as tto whether you want an ACE/Vanilla arsenal or not
_crateSide - the side that the crate will populate equipment from. Options: West,East,Independent,Civilian
_unrestrictedArsenal - boolean as to whether you want the arsenal to be unrestricted or not.


To call

[_target,_arsenal,_crateSide,_unrestrictedArsenal] spawn Waldo_fnc_DoStarterCrate;

e.g.

[this,true,west,false] spawn Waldo_fnc_DoStarterCrate; //from unit init as example


*/
params["_target","_arsenal",["_crateSide",west],["_unrestrictedArsenal",false]];

//Wait Until Init is completed & players ingame (Postinit hack)
waitUntil { missionNamespace getVariable ["WALDO_INIT_COMPLETE", false] };
//Double Security with ensuring mission.sqm sweep
waitUntil { missionNamespace getVariable ["Logi_MissionScanComplete", false] };


//identifier Addaction 
_target addAction ["<t color='#035afc'>Starter Crate</t>",{}];

//loadout saving Addaction here
_target addAction ["<t color='#00FF00'>Save Respawn Loadout</t>", Waldo_fnc_SaveLoadout];


//Add full compliment of supplies (MEDICAL NOTWITHSTANDING)
[_target, 1,_crateSide, true] call Waldo_fnc_SupplyCratePopulate;

if (_arsenal == true) then {
    if (_unrestrictedArsenal == true) then {
        //Vanilla Arsenal & ACE Arsenal
        ["AmmoboxInit",[this,true]] call BIS_fnc_arsenal;
        [_target, true] call ace_arsenal_fnc_initBox;
    } else {
        //Add Limited Ace Arsenal 
        [_target,_crateSide,false] call Waldo_fnc_CreateLimitedArsenal;
    };
};

Waldo_StarterCrate_SaveAction = [
	"Waldo_StarterCrate_SaveAction",
	"Save Respawn Loadout",
	"\a3\missions_f_oldman\data\img\holdactions\holdAction_box_ca.paa",
	{
		[] call Waldo_fnc_SaveLoadout
	},
	{
		//[_target, _player, _actionParams] Condition
		(_player distance _target) < 6 && speed _target < 1;
	},
	{},
	[],
	[],
	0,
	[false, false, false, false, false]
] call ace_interact_menu_fnc_createAction;


// Add action to Vehicle
[_target,
	0, 
	["ACE_MainActions"], 
	Waldo_StarterCrate_SaveAction
] call ace_interact_menu_fnc_addActionToObject;