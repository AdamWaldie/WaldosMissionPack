/*
 * Author: WaldoTheWarfighter
 * Purpose: Give one interaction object ACE build and tear-down actions for the objects synced
 * to its nearest Game Logic. Build and tear-down use local ten-second progress bars.
 * Locality/authority: Eden Init calls this on server and interface clients. The server attaches
 * and hides synced objects and publishes initial status. Each interface installs ACE actions.
 * Completion callbacks publish status and request server-side visibility changes; this helper
 * has no separate server validation of the player or construction request.
 * Repeat/JIP: Eden Init runs for joining clients, which install their local actions. There is
 * no duplicate-action guard for repeat calls on one client or explicit runtime-object JIP replay.
 * Arguments:
 * 0: target <OBJECT> (required) - existing interaction object near the intended Game Logic.
 * 1: modern audio <BOOL> (default false) - true uses new construction audio; false uses old.
 * Return Value: No documented value from this setup call.
 * Current caller: mission-maker Eden interaction-object Init fields.
 * Example: [this, true] call Waldo_fnc_ConstructionObjects;
 * Result: the object gets ACE actions to reveal and hide its synchronized construction props.
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
    ["Construction Completed", _player, "CONSTRUCTION"] call Waldo_fnc_DynamicText;
};

Waldo_Construction_TearDown = {
    params ["_target","_player","_ConstructionAudioPath"];
    _constructionLogic = nearestObject [_target, "Logic"]; 
    _constructionParts = synchronizedObjects _constructionLogic;
    {[_x, true] remoteExec ["hideObjectGlobal", 2];} forEach _constructionParts;
    _target setVariable ['Waldo_Construction_Status', false, true]; 
    playSound3d [getMissionPath _ConstructionAudioPath, _target, false, getPosASL _target, 4, 1];
    ["Construction Torn Down", _player, "CONSTRUCTION"] call Waldo_fnc_DynamicText;
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
        }, {["Construction Not Built", _player, "CONSTRUCTION"] call Waldo_fnc_DynamicText;}, "Constructing..."] call ace_common_fnc_progressBar;
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
        }, {["Construction Still Standing", _player, "CONSTRUCTION"] call Waldo_fnc_DynamicText;}, "Tearing Down...."] call ace_common_fnc_progressBar;
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
