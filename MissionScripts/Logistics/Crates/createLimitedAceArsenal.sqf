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
/*
_aceArsenalPool = missionNamespace getVariable "Logi_MissionSQMArray_West";
*/

//Capitalise so I dont go mad with variations
//_crateSupplySide = toUpper _crateSupplySide;

//default setup
private _aceArsenalPool = missionNamespace getVariable "Logi_MissionSQMArray_West";
//get all loadout data by default
if (_crateSupplySide == EAST) then {
    _aceArsenalPool = missionNamespace getVariable "Logi_MissionSQMArray_East";
};
if (_crateSupplySide == INDEPENDENT) then {
    _aceArsenalPool = missionNamespace getVariable "Logi_MissionSQMArray_Ind";
};
if (_crateSupplySide == CIVILIAN) then {
    _aceArsenalPool = missionNamespace getVariable "Logi_MissionSQMArray_Civ";
};

//Remove Empty Portions
{
    if ((_aceArsenalPool select _x) select 0 == "EMPTY") then {
        _aceArsenalPool deleteAt _x;
    };
} foreach _aceArsenalPool;

_aceArsenalPool = str _aceArsenalPool splitString "[]," joinString ",";
_aceArsenalPool = parseSimpleArray ("[" + _aceArsenalPool + "]");
_aceArsenalPool = _aceArsenalPool arrayIntersect _aceArsenalPool select {_x isEqualType "" && {_x != ""}};

// if pre-existing Ace Arsenal (user specified) add items to it, else add entirely new arsenal
if (_preExisting == true) then {
    [_target, _aceArsenalPool] call ace_arsenal_fnc_addVirtualItems;
} else {
    [_target, _aceArsenalPool] call ace_arsenal_fnc_initBox;
};