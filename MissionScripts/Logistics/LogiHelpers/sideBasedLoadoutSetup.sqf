/*
 * Author: Waldo
 * Joiner function called from initServer.sqf. Runs the mission.sqm scrape for every side
 * and stores the resulting equipment pools as broadcast globals (Logi_MissionSQMArray_*)
 * used by the starter crates, limited arsenals, supply boxes and Zeus boxes. Sets
 * Logi_MissionScanComplete once finished so consumers can waitUntil on it.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_SideBaseLoadoutSetup;
 */

// [ SQM side string, global variable suffix ]
{
    _x params ["_sideString", "_suffix"];
    private _pool = [_sideString] call Waldo_fnc_MissionSQMLookup;
    missionNamespace setVariable [format ["Logi_MissionSQMArray_%1", _suffix], _pool, true];
} forEach [["West", "West"], ["East", "East"], ["Independent", "Ind"], ["Civilian", "Civ"]];

// Signal that the mission.sqm sweep is complete.
missionNamespace setVariable ["Logi_MissionScanComplete", true, true];
