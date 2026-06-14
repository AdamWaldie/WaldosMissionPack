/*
 * Author: Waldo
 * Returns the scraped mission.sqm loadout array for a given side.
 * Centralises the side -> Logi_MissionSQMArray_* lookup that the supply crate and
 * limited arsenal systems both need, so the side mapping lives in one place.
 *
 * Arguments:
 * 0: Side <SIDE> (Optional, default: west) - west / east / independent / civilian
 *
 * Return Value:
 * Loadout array <ARRAY> - the matching Logi_MissionSQMArray_* (empty array if unset)
 *
 * Example:
 * private _loadoutArray = [east] call Waldo_fnc_GetSideLoadoutArray;
 */

params [["_side", west]];

private _suffix = switch (_side) do {
    case east: { "East" };
    case independent: { "Ind" };
    case civilian: { "Civ" };
    default { "West" };
};

missionNamespace getVariable [format ["Logi_MissionSQMArray_%1", _suffix], []]
