//Post-Init Setup of saved Loadout (Measure taken to help prevent Naked People)
["CAManBase", "InitPost", {
    params ["_unit"];
    if (!local _unit) exitWith {
        if (_unit == player) then {
            //DO FUCK ALL BECAUSE UNIT IS NON-LOCAL DEBUG ONLY
        };
    };
    if (_unit == player) then {
        [_unit, [missionNamespace, "Player_Inventory"]] call BIS_fnc_saveInventory;
        _unit addAction [
        "Flip Vehicle", 
        "MissionScripts\flipAction.sqf", 
        [], 
        0, 
        false, 
        true, 
        "", 
        "_this == (vehicle _target) && {(count nearestObjects [_target, ['landVehicle'], 5]) > 0 && {(vectorUp cursorTarget) select 2 < 0}}"
    ];
    };
}] call CBA_fnc_addClassEventHandler;


//Respawn Reapplication Of Loadout Segment
["CAManBase", "Respawn", {
    params ["_unit"];
    if (_unit == player) then {
        [_unit, [missionNamespace, "Player_Inventory"]] call BIS_fnc_loadInventory;
        _unit addAction [
        "Flip Vehicle", 
        "MissionScripts\flipAction.sqf", 
        [], 
        0, 
        false, 
        true, 
        "", 
        "_this == (vehicle _target) && {(count nearestObjects [_target, ['landVehicle'], 5]) > 0 && {(vectorUp cursorTarget) select 2 < 0}}"
    ];
    };
}] call CBA_fnc_addClassEventHandler;

//UNCOMMENT THE BELOW IF YOU WANT PEOPLE TO RESPAWN WITH WHAT THEY DIED WITH!
//Save Loadout on Death
/*
["CAManBase", "Killed", {
    params ["_unit"];
    if (_unit == player) then {
        [_unit, [missionNamespace, "Player_Inventory"]] call BIS_fnc_saveInventory;
    };
}] call CBA_fnc_addClassEventHandler;*/

//=====================DO NOT UN-COMMENT BELOW THESE LINES====================================

//Ensure loadout is applied via local execution (Safety Net) - Not implemented in this build due to no issues so far
/*
["CAManBase", "Local", {
    params ["_unit"];
    if (_unit == player && {local _unit}) then {
        [_unit, [missionNamespace, "Player_Inventory"]] call BIS_fnc_loadInventory;
    };
}] call CBA_fnc_addClassEventHandler;*/

//Arsenal Eventhandler - DO NOT ENABLE. Next version will have Arsenal interaction saving
/*
_id = ["ace_arsenal_displayClosed", {

_LoadoutSaveArsenal = execvm "MissionScripts\saveRespawnLoadout.sqf";

}] call CBA_fnc_addEventHandler;*/

// Loadout Save/Load handling

