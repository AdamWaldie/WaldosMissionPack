/*
 * Author: Waldo
 * Changes AI skill values
 *
 * Example:
 * "DAY" call Waldo_fnc_AITweak; - Daytime Mission
 * "NIGHT" call Waldo_fnc_AITweak; - Nightime Mission
 *
 * 
 *  This script alters the base AI subskills to improve responsiveness while allowing for a reasonably balanced PvE environment. When used in conjunction with Lambs.danger, this script allows for the AI to trigger more Ai behaviours than the default, which results in a more responsive and dangerous AI, while remaining balanced.
 *  There are two modes available: DAY and NIGHT.
 *
 *   Both can be selected via the init.sqf to change which is active, comment out the undesired setting and uncomment the desired setting.
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
                //RHS
                case "rhs_faction_msv";
                case "rhs_faction_rva";
                case "rhs_faction_tv";
                case "rhs_faction_vdv_45";
                case "rhs_faction_vdv";
                case "rhs_faction_vmf";
                case "rhs_faction_vpvo";
                case "rhs_faction_vv";
                case "rhs_faction_vvs_c";
                //WW2
                case "LIB_US_101AB"; 
                case "LIB_US_82AB"; 
                case "NORTH_FIN"; 
                case "NORTH_NOR"; 
                case "EAW_ROC";
                case "EAW_ROC_Early"; 
                case "EAW_ROC_Ger";
                case "EAW_ROC_Southern"; 
                case "EAW_ROC_West";
                case "EAW_ROC_Winter"; 
                case "LIB_UK_AB_w";
                case "LIB_UK_ARMY_w";
                case "LIB_US_ARMY_w"; 
                case "IND_F";
                case "JMSSA_britain_fact"; 
                case "CSA38_GB";
                case "JMSSA_britain_des_fact"; 
                case "JMSSA_britain_sicily_fact"; 
                case "JMSSA_britain_BEF_fact"; 
                case "CSA38_CSA38"; 
                case "CSA38_CSOB"; 
                case "LIB_FFI";
                case "LIB_GUER";
                case "sab_nl_faction_green"; 
                case "CSA38_PL"; 
                case "CSA38_SLOV"; 
                case "CSA38_spol"; 
                case "LIB_UK_AB"; 
                case "LIB_UK_ARMY"; 
                case "LIB_UK_DR"; 
                case "LIB_US_ARMY"; 
                case "LIB_NAC";
                case "EAW_IRA";
                case "NORTH_SOV"; 
                case "LIB_RKKA"; 
                case "EAW_IJA";
                case "LIB_WEHRMACHT_w"; 
                case "CSA38_GERM";
                case "JMSSA_italy_fact"; 
                case "SG_STURM"; 
                case "SG_STURMPANZER"; 
                case "LIB_WEHRMACHT";
                //3CB
                case "UK3CB_ADA_O";
                //OPTRE
                case "OPTRE_Ins";
                case "dev_flood";
                case "MEU_Covenant";
                case "OPTRE_FC_Covenant";
                case "LM_OPCAN_FRI";
                case "LM_OPCAN_FRI_DES";
                case "LM_OPCAN_FRI_WDL";
                case "LM_OPCAN_URA";
                case "OPTRE_Ins";
                //Base (No Edit)
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
                    //RHS
                    case "rhs_faction_msv";
                    case "rhs_faction_rva";
                    case "rhs_faction_tv";
                    case "rhs_faction_vdv_45";
                    case "rhs_faction_vdv";
                    case "rhs_faction_vmf";
                    case "rhs_faction_vpvo";
                    case "rhs_faction_vv";
                    case "rhs_faction_vvs_c";
                    //WW2
                    case "LIB_US_101AB"; 
                    case "LIB_US_82AB"; 
                    case "NORTH_FIN"; 
                    case "NORTH_NOR"; 
                    case "EAW_ROC";
                    case "EAW_ROC_Early"; 
                    case "EAW_ROC_Ger";
                    case "EAW_ROC_Southern"; 
                    case "EAW_ROC_West";
                    case "EAW_ROC_Winter"; 
                    case "LIB_UK_AB_w";
                    case "LIB_UK_ARMY_w";
                    case "LIB_US_ARMY_w"; 
                    case "IND_F";
                    case "JMSSA_britain_fact"; 
                    case "CSA38_GB";
                    case "JMSSA_britain_des_fact"; 
                    case "JMSSA_britain_sicily_fact"; 
                    case "JMSSA_britain_BEF_fact"; 
                    case "CSA38_CSA38"; 
                    case "CSA38_CSOB"; 
                    case "LIB_FFI";
                    case "LIB_GUER";
                    case "sab_nl_faction_green"; 
                    case "CSA38_PL"; 
                    case "CSA38_SLOV"; 
                    case "CSA38_spol"; 
                    case "LIB_UK_AB"; 
                    case "LIB_UK_ARMY"; 
                    case "LIB_UK_DR"; 
                    case "LIB_US_ARMY"; 
                    case "LIB_NAC";
                    case "EAW_IRA";
                    case "NORTH_SOV"; 
                    case "LIB_RKKA"; 
                    case "EAW_IJA";
                    case "LIB_WEHRMACHT_w"; 
                    case "CSA38_GERM";
                    case "JMSSA_italy_fact"; 
                    case "SG_STURM"; 
                    case "SG_STURMPANZER"; 
                    case "LIB_WEHRMACHT";
                    //3CB
                    case "UK3CB_ADA_O";
                    //OPTRE
                    case "OPTRE_Ins";
                    case "dev_flood";
                    case "MEU_Covenant";
                    case "OPTRE_FC_Covenant";
                    case "LM_OPCAN_FRI";
                    case "LM_OPCAN_FRI_DES";
                    case "LM_OPCAN_FRI_WDL";
                    case "LM_OPCAN_URA";
                    case "OPTRE_Ins";
                    //Base (No Edit)
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
