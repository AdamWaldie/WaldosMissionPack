/*
 * Author: WaldoTheWarfighter
 * Assigns the local player an ACE team colour from their Eden role description or unit display name.
 * A useful role format is `[team] [role]@[callsign]`, such as `Alpha Rifleman@Viking-1`.
 * Locality/authority: client-local ACE team assignment; no server-owned group or registry change.
 * Repeat/JIP: joining players run this from init.sqf; a repeat call re-evaluates the current role.
 * Arguments: none. The function reads the local player.
 * Return Value: No useful value.
 * Current caller: init.sqf; mission makers may call it again after changing a player's role.
 * Example: call Waldo_fnc_SetTeamColour;
 * Result: a player whose role begins `Alpha` receives the red ACE team colour.
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
