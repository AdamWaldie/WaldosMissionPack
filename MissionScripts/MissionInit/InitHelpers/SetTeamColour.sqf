/*
Author: Waldo
This function assigns members of the team automatically to teams before mission start based on their role description.

For best outcome the role description format of [Team] [Role Name]@[Callsign] Should be followed.

E.g. Alpha Rifleman, Blue Rifleman, ASL, SL@Viking-1

Arguments:
N/A

Returns:
Nothing

Example:
call Waldo_fnc_SetTeamColour;

*/

// Use role description, and if no description, use class display name
private _roleDesc = if !(roleDescription player == "") then {
    roleDescription player
} else {
    getText (configFile >> "CfgVehicles" >> typeOf player >> "displayName");
};
_roleDesc = toUpper _roleDesc;

private _teamMapping = [
    ["SQUAD LEADER", "YELLOW"],
    ["SL", "YELLOW"],
    ["PLATOON SERGEANT", "YELLOW"],
    ["PSG", "YELLOW"],
    ["PLATOON LEADER", "YELLOW"],
    ["PL", "YELLOW"],
    ["COMPANY COMMANDER", "YELLOW"],
    ["CC", "YELLOW"],
    ["COMMANDING OFFICER", "YELLOW"],
    ["CO", "YELLOW"],
    ["LT", "YELLOW"],
    ["LIEUTENANT", "YELLOW"],
    ["MAJOR", "YELLOW"],
    ["CAPTAIN", "YELLOW"],
    ["COLONEL", "YELLOW"],
    ["1ST SERGEANT", "YELLOW"],
    ["1SG", "YELLOW"],
    ["ASSISTANT SQUAD LEADER", "RED"],
    ["ASL", "RED"],
    ["MEDIC", "GREEN"],
    ["ALPHA", "RED"],
    ["RED", "RED"],
    ["BRAVO", "BLUE"],
    ["BLUE", "BLUE"],
    ["CHARLIE", "GREEN"],
    ["GREEN", "GREEN"],
    ["DELTA", "YELLOW"],
    ["YELLOW", "YELLOW"]
];

private _assignedTeam = ""; // Default to blank (no team)

//Search for match
{
    if (_roleDesc find (_x select 0) > -1) exitWith {
        _assignedTeam = _x select 1;
    };
} forEach _teamMapping;

// Assign the team only if a match was found
if (_assignedTeam != "") then {
    [player, _assignedTeam] call ace_interaction_fnc_joinTeam;
};
