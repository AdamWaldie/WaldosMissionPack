//Post-Init Setup of saved Loadout (Measure taken to help prevent Naked/unarmed People)

["CAManBase", "InitPost", {
    params ["_unit"];
    if (!local _unit) exitWith {
        if (_unit == player) then {
            //DO FUCK ALL BECAUSE UNIT IS NON-LOCAL (DEBUG Measure for applying loadouts via script)
        };
    };
    if (_unit == player) then {
        [_unit, [missionNamespace, "Player_Inventory"]] call BIS_fnc_saveInventory;
        _unit addAction [
        "Flip Vehicle", 
        "MissionScripts\Logistics\flipAction.sqf", 
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
        "MissionScripts\Logistics\flipAction.sqf", 
        [], 
        0, 
        false, 
        true, 
        "", 
        "_this == (vehicle _target) && {(count nearestObjects [_target, ['landVehicle'], 5]) > 0 && {(vectorUp cursorTarget) select 2 < 0}}"
    ];
    };
}] call CBA_fnc_addClassEventHandler;

/*
=====================RESPAWN WITH LOADOUT ON DEATH====================================

UNCOMMENT THE BELOW IF YOU WANT PEOPLE TO RESPAWN WITH WHAT THEY DIED WITH!


*/

/*
["CAManBase", "Killed", {
    params ["_unit"];
    if (_unit == player) then {
        [_unit, [missionNamespace, "Player_Inventory"]] call BIS_fnc_saveInventory;
    };
}] call CBA_fnc_addClassEventHandler;


*/