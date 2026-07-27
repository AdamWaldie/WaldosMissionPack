/*
Function with the purpose to create an ace arsenal on the object, limited to the equipment retireved from the mission.sqm

parameters:
_target - the object variable name you want this to apply to
_crateSupplyside - the side that the crate will populate equipment from. Options: West,East,Independent,Civilian
_preExisting - user defined boolean for specifying whether an ace arsenal already exists on the object.

[_target,_crateSupplyside,_preExisting] spawn Waldo_fnc_CreateLimitedArsenal;

e.g.

[this, west, false] spawn Waldo_fnc_CreateLimitedArsenal;

*/
params["_target",["_crateSupplySide",west],["_preExisting",false]];

//Wait Until Init is completed & players ingame (Postinit hack)
waitUntil { missionNamespace getVariable ["WALDO_INIT_COMPLETE", false] };
//Double Security with ensuring mission.sqm sweep
waitUntil { missionNamespace getVariable ["Logi_MissionScanComplete", false] };

//Get the loadout pool for the requested side (defaults to west)
private _aceArsenalPool = [_crateSupplySide] call Waldo_fnc_GetSideLoadoutArray;

//Remove Empty Portions
{
    if ((_aceArsenalPool select _x) select 0 == "EMPTY") then {
        _aceArsenalPool deleteAt _x;
    };
} foreach _aceArsenalPool;

_aceArsenalPool = [_aceArsenalPool] call Waldo_fnc_UniqueLoadoutArray;

// if pre-existing Ace Arsenal (user specified) add items to it, else add entirely new arsenal
if (_preExisting == true) then {
    [_target, _aceArsenalPool] call ace_arsenal_fnc_addVirtualItems;
} else {
    [_target, _aceArsenalPool] call ace_arsenal_fnc_initBox;
};