/*
Author: Waldo
This function assigns members of the team automatically to teams before mission start based on their role description.

For best outcome the role description format of [Team] [Role Name]@[Callsign] Should be followed.

Arguments:
N/A

Returns:
Nothing

Example:
call Waldo_fnc_SetTeamColour;

*/

private _roleDesc = "";

if !(roleDescription player == "") then {
    _roleDesc = roleDescription player;
} else {
    _roleDesc = getText (configFile >> "CfgVehicles" >> typeOf player >> "displayName");
};
_roleDesc = toUpper _roleDesc;

// Using a switch statement to match the condition and assign the team color - this is first match so order is imperative
switch (true) do {
    case ((_roleDesc find "ASSISTANT SQUAD LEADER") > -1 || (_roleDesc find "ASL") > -1): {
        [player, "RED"] call ace_interaction_fnc_joinTeam;
    };
    case ((_roleDesc find "SQUAD LEADER") > -1 || (_roleDesc find "SL") > -1): {
        [player, "YELLOW"] call ace_interaction_fnc_joinTeam;
    };
    case ((_roleDesc find "MEDIC") > -1): {
        [player, "GREEN"] call ace_interaction_fnc_joinTeam;
    };
    case ((_roleDesc find "ALPHA") > -1 || (_roleDesc find "RED") > -1): {
        [player, "RED"] call ace_interaction_fnc_joinTeam;
    };
    case ((_roleDesc find "BRAVO") > -1 || (_roleDesc find "BLUE") > -1): {
        [player, "BLUE"] call ace_interaction_fnc_joinTeam;
    };
    case ((_roleDesc find "CHARLIE") > -1 || (_roleDesc find "GREEN") > -1): {
        [player, "GREEN"] call ace_interaction_fnc_joinTeam;
    };
    case ((_roleDesc find "DELTA") > -1 || (_roleDesc find "YELLOW") > -1): {
        [player, "YELLOW"] call ace_interaction_fnc_joinTeam;
    };
    default {
        [player, "WHITE"] call ace_interaction_fnc_joinTeam;
    };
};