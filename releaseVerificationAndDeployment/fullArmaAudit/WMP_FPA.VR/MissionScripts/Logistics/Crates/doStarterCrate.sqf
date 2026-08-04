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
// Public editor call: every machine may execute an object's init field, but the server owns all
// global inventory mutations and publishes the client-local actions for hosted, dedicated and JIP.
if (!isServer) exitWith {};

//Wait Until Init is completed & players ingame (Postinit hack)
waitUntil { missionNamespace getVariable ["WALDO_INIT_COMPLETE", false] };
//Double Security with ensuring mission.sqm sweep
waitUntil { missionNamespace getVariable ["Logi_MissionScanComplete", false] };


// Preserve the original blue identifier and install the functional save interaction on every
// current interface. The keyed replay gives later joiners the same local actions.
if (hasInterface) then {[_target] call Waldo_fnc_StarterCrateSetupLocal};
[_target] remoteExecCall ["Waldo_fnc_StarterCrateSetupLocal", -2, format ["Waldo_StarterCrate_%1", netId _target]];


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
