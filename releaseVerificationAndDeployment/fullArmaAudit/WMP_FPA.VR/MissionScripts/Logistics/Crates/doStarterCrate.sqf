/*
Function with the purpose of simplifying the setup of starter crates.

Does the following:
- Adds linked ACE and vanilla interactions for saving the respawn loadout
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


// Loadout-save objects deliberately keep the visible vanilla action as a discoverability cue.
// The ACE and vanilla routes call the same guarded save function.
if (hasInterface) then {[_target] call Waldo_fnc_ZenAddLoadoutSaveAction;};


//Add full compliment of supplies (MEDICAL NOTWITHSTANDING)
[_target, 1,_crateSide, false, false] call Waldo_fnc_SupplyCratePopulate;

if (_arsenal == true) then {
    if (_unrestrictedArsenal == true) then {
        //Vanilla Arsenal & ACE Arsenal
        ["AmmoboxInit",[_target,true]] call BIS_fnc_arsenal;
        [_target, true] call ace_arsenal_fnc_initBox;
    } else {
        //Add Limited Ace Arsenal 
        [_target,_crateSide,false] call Waldo_fnc_CreateLimitedArsenal;
    };
};
