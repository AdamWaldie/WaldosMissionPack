/*
 * Author: Waldo
 * Changes AI skill values
 *
 * Example:
 * "DAY" call Waldo_fnc_AITweak; - Daytime Mission
 * "NIGHT" call Waldo_fnc_AITweak; - Nightime Mission
 *
 * Public: No
 */

if !(isServer) exitWith {};

// Assign argument to variable
params[["_dayOrNightValue","DAY"]];

systemchat "AI Adjustment System Active";

//Get eventhandler for all units pre-placed
["CAManBase", "init", {
    params ["_unit"];
    
    // General AI setup for day & night missions
    if !(isPlayer _unit) then {
        if (_dayOrNightValue == "DAY") then {
            _unit setSkill ["aimingspeed",     0.420];
            _unit setSkill ["aimingaccuracy",  0.830];
            _unit setSkill ["aimingshake",     0.360];
            _unit setSkill ["spottime",        0.800];
            _unit setSkill ["spotdistance",    1.000];
            _unit setSkill ["commanding",      1.0];
            _unit setSkill ["general",         1.0];
        };
        if (_dayOrNightValue == "NIGHT") then {
            if (getLighting select 1 <= 5) then {
                if (hmd _unit != "") then {
                    _unit setSkill ["spottime",        0.015];
                    _unit setSkill ["spotdistance",    0.015];
                } else {
                    _unit setSkill ["spottime",        0.520];
                    _unit setSkill ["spotdistance",    0.520];
                };
            } else {
                _unit setSkill ["spottime",        1.000];
                _unit setSkill ["spotdistance",    1.000];
            };

            switch (faction _unit) do {
                case "rhs_faction_msv";
                case "rhs_faction_rva";
                case "rhs_faction_tv";
                case "rhs_faction_vdv_45";
                case "rhs_faction_vdv";
                case "rhs_faction_vmf";
                case "rhs_faction_vpvo";
                case "rhs_faction_vv";
                case "rhs_faction_vvs_c";
                case "rhs_faction_vvs": {
                    _unit setSkill ["general",         1.000];
                    _unit setSkill ["commanding",      0.950];
                    _unit setSkill ["courage",         1.000];
                    _unit setSkill ["aimingspeed",     0.720];
                    _unit setSkill ["aimingaccuracy",  0.920];
                    _unit setSkill ["aimingshake",     0.260];
                    _unit setSkill ["reloadSpeed",     1.000];
                };
                default {
                    _unit setSkill ["general",         0.900]; //  Bad <=> Good
                    _unit setSkill ["commanding",      0.750]; //  Bad <=> Good
                    _unit setSkill ["courage",         0.750]; //  Bad <=> Good
                    _unit setSkill ["aimingspeed",     0.620]; //  Bad <=> Good
                    _unit setSkill ["aimingaccuracy",  0.830]; //  Bad <=> Good
                    _unit setSkill ["aimingshake",     0.360]; // Good <=> Bad
                    _unit setSkill ["reloadSpeed",     0.750]; //  Bad <=> Good
                };
            };

            // Role adjusted
            if (getText (configfile >> "CfgVehicles" >> typeOf _unit >> "textSingular") == "machinegunner") then {
                    _unit setSkill ["aimingspeed",     0.820];
                    _unit setSkill ["aimingaccuracy",  0.820];
                    _unit setSkill ["aimingshake",     0.350];
                    _unit setSkill ["reloadSpeed",     0.800];
            };
            if (getText (configfile >> "CfgVehicles" >> typeOf _unit >> "textSingular") == "sniper") then {
                    _unit setSkill ["aimingspeed",     0.600];
                    _unit setSkill ["aimingaccuracy",  0.950];
                    _unit setSkill ["aimingshake",     0.100];
                    _unit setSkill ["reloadSpeed",     0.800];
            };
        };
    };
}, true, [], true] call CBA_fnc_addClassEventHandler;




// Zeus Placed Units AI Tweaks
{
    ["CAManBase", "CuratorObjectPlaced", {
        params ["_unit"];
        
    // General AI setup for day & night missions
    if !(isPlayer _unit) then {
        if (_dayOrNightValue == "DAY") then {
            _unit setSkill ["aimingspeed",     0.420];
            _unit setSkill ["aimingaccuracy",  0.830];
            _unit setSkill ["aimingshake",     0.360];
            _unit setSkill ["spottime",        0.800];
            _unit setSkill ["spotdistance",    1.000];
            _unit setSkill ["commanding",      1.0];
            _unit setSkill ["general",         1.0];
        };
        if (_dayOrNightValue == "NIGHT") then {
            if (getLighting select 1 <= 5) then {
                if (hmd _unit != "") then {
                    _unit setSkill ["spottime",        0.015];
                    _unit setSkill ["spotdistance",    0.015];
                } else {
                    _unit setSkill ["spottime",        0.520];
                    _unit setSkill ["spotdistance",    0.520];
                };
            } else {
                _unit setSkill ["spottime",        1.000];
                _unit setSkill ["spotdistance",    1.000];
            };

            switch (faction _unit) do {
                case "rhs_faction_msv";
                case "rhs_faction_rva";
                case "rhs_faction_tv";
                case "rhs_faction_vdv_45";
                case "rhs_faction_vdv";
                case "rhs_faction_vmf";
                case "rhs_faction_vpvo";
                case "rhs_faction_vv";
                case "rhs_faction_vvs_c";
                case "rhs_faction_vvs": {
                    _unit setSkill ["general",         1.000];
                    _unit setSkill ["commanding",      0.950];
                    _unit setSkill ["courage",         1.000];
                    _unit setSkill ["aimingspeed",     0.720];
                    _unit setSkill ["aimingaccuracy",  0.920];
                    _unit setSkill ["aimingshake",     0.260];
                    _unit setSkill ["reloadSpeed",     1.000];
                };
                default {
                    _unit setSkill ["general",         0.900]; //  Bad <=> Good
                    _unit setSkill ["commanding",      0.750]; //  Bad <=> Good
                    _unit setSkill ["courage",         0.750]; //  Bad <=> Good
                    _unit setSkill ["aimingspeed",     0.620]; //  Bad <=> Good
                    _unit setSkill ["aimingaccuracy",  0.830]; //  Bad <=> Good
                    _unit setSkill ["aimingshake",     0.360]; // Good <=> Bad
                    _unit setSkill ["reloadSpeed",     0.750]; //  Bad <=> Good
                };
            };

            // Role adjusted
            if (getText (configfile >> "CfgVehicles" >> typeOf _unit >> "textSingular") == "machinegunner") then {
                    _unit setSkill ["aimingspeed",     0.820];
                    _unit setSkill ["aimingaccuracy",  0.820];
                    _unit setSkill ["aimingshake",     0.350];
                    _unit setSkill ["reloadSpeed",     0.800];
            };
            if (getText (configfile >> "CfgVehicles" >> typeOf _unit >> "textSingular") == "sniper") then {
                    _unit setSkill ["aimingspeed",     0.600];
                    _unit setSkill ["aimingaccuracy",  0.950];
                    _unit setSkill ["aimingshake",     0.100];
                    _unit setSkill ["reloadSpeed",     0.800];
            };
        };
    };
    }, true, [], true] call CBA_fnc_addClassEventHandler;
} forEach allCurators;