/*
Function with the purpose of simplifying the setup of starter crates.

Does the following:
- Adds addaction to allow for the saving of loadout
- Adds limited Ace Arsenal (Mission.sqm bound)
- Adds full supplies (Both Medical & Standard) (Mission.sqm bound)


parameters:
_target - the object variable name you want this to apply to
_arsenal - boolean as tto whether you want an ACE/Vanilla arsenal or not


To call

[_target,_arsenal] spawn Waldo_fnc_DoStarterCrate;

e.g.

[this,true] spawn Waldo_fnc_DoStarterCrate; //from unit init as example


*/
params["_target","_arsenal"];

//Wait Until Init is completed & players ingame (Postinit hack)
waitUntil { missionNamespace getVariable ["WALDO_INIT_COMPLETE", false] };
//Double Security with ensuring mission.sqm sweep
waitUntil { missionNamespace getVariable ["Logi_MissionScanComplete", false] };


//identifier Addaction 
_target addAction ["<t color='#035afc'>Starter Crate</t>",{}];

//loadout saving Addaction here
_target addAction ["<t color='#00FF00'>Save Respawn Loadout</t>", Waldo_fnc_SaveLoadout];

//Add full compliment of supplies (MEDICAL NOTWITHSTANDING)
[_target, 1, true] call Waldo_fnc_SupplyCratePopulate;

if (_arsenal == true) then {
    //Add Limited Ace Arsenal 
    [_target,false] call Waldo_fnc_CreateLimitedArsenal;
};