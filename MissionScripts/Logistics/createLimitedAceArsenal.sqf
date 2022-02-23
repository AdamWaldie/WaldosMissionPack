/*
Function with the purpose to create an ace arsenal on the object, limited to the equipment retireved from the mission.sqm (read initServer.sqf & missionFileLookup.sqf for details)

parameters:
_target - the object variable name you want this to apply to
_preExisting - user defined boolean for specifying whether an ace arsenal already exists on the object.

[_target,_preExisting] spawn Waldo_fnc_CreateLimitedArsenal;

e.g.

[this, false] spawn Waldo_fnc_CreateLimitedArsenal;

*/
params["_target",["_preExisting",false]];

//Wait Until Init is completed & players ingame (Postinit hack)
waitUntil { missionNamespace getVariable ["WALDO_INIT_COMPLETE", false] };

_aceArsenalPool = missionNamespace getVariable "Logi_MissionSQMArray";

_aceArsenalPool = str _aceArsenalPool splitString "[]," joinString ",";
_aceArsenalPool = parseSimpleArray ("[" + _aceArsenalPool + "]");
_aceArsenalPool = _aceArsenalPool arrayIntersect _aceArsenalPool select {_x isEqualType "" && {_x != ""}};
diag_log _aceArsenalPool;

// if pre-existing Ace Arsenal (user specified) add items to it, else add entirely new arsenal
if (_preExisting == true) then {
    [_target, _aceArsenalPool] call ace_arsenal_fnc_addVirtualItems;
} else {
    [_target, _aceArsenalPool] call ace_arsenal_fnc_initBox;
};