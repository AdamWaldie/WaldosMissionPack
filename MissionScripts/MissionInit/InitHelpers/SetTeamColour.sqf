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

private _getTeamName = "";
if !(roleDescription player == "") then {
    _getTeamName = roleDescription player;
} else {
    _getTeamName = getText (configFile >> "CfgVehicles" >> typeOf player >> "displayName");
};
_getTeamName = _getTeamName splitString " ";
_getTeamName = _getTeamName select 0;
_getTeamName = toUpper _getTeamName;

//Due to the large scope of potential name conventions for clans, heres a collossal catch all.
switch (_getTeamName) do {
    case "ALPHA": {
        [player, "RED"] call ace_interaction_fnc_joinTeam;
        (player) setVariable ["Waldo_PlayerInit_Team", 'RED'];
    };
	case "RED": {
        [player, "RED"] call ace_interaction_fnc_joinTeam;
        (player) setVariable ["Waldo_PlayerInit_Team", 'RED'];
    };
    case "BRAVO": {
        [player, "BLUE"] call ace_interaction_fnc_joinTeam;
        (player) setVariable ["Waldo_PlayerInit_Team", 'BLUE'];
    };
	case "BLUE": {
        [player, "BLUE"] call ace_interaction_fnc_joinTeam;
        (player) setVariable ["Waldo_PlayerInit_Team", 'BLUE'];
    };
    case "CHARLIE": {
        [player, "GREEN"] call ace_interaction_fnc_joinTeam;
        (player) setVariable ["Waldo_PlayerInit_Team", 'GREEN'];
    };
	case "GREEN": {
        [player, "GREEN"] call ace_interaction_fnc_joinTeam;
        (player) setVariable ["Waldo_PlayerInit_Team", 'GREEN'];
    };
	case "MEDIC": {
        [player, "GREEN"] call ace_interaction_fnc_joinTeam;
        (player) setVariable ["Waldo_PlayerInit_Team", 'GREEN'];
    };
    case "DELTA": {
        [player, "YELLOW"] call ace_interaction_fnc_joinTeam;
        (player) setVariable ["Waldo_PlayerInit_Team", 'YELLOW'];
    };
	case "YELLOW": {
        [player, "YELLOW"] call ace_interaction_fnc_joinTeam;
        (player) setVariable ["Waldo_PlayerInit_Team", 'YELLOW'];
    };
    default {
        _getTeamName = 'WHITE';
        (player) setVariable ["Waldo_PlayerInit_Team", 'WHITE'];
    };
};

private _return = _getTeamName;

//Debug Logging
systemChat [format ["%1 was assigned as team %2.", player, _getTeamName], "SetTeamColor"];

_return;