/*
 * Author: Waldo
 * Opens the ZEN configuration dialog for a repeatable Dynamic AA system.
 *
 * Arguments:
 * 0: modulePosition <ARRAY> - detection centre selected by module placement
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_modulePos] call Waldo_fnc_DynamicAAZen;
 */

params [["_modulePos", [], [[]]]];
if !(hasInterface) exitWith {};

private _defaultId = format ["AA_%1_%2", clientOwner, round (serverTime * 10)];
[
    "Create Dynamic AA System",
    [
        ["EDIT", ["System ID", "Unique letters, numbers, underscores or hyphens."], [_defaultId]],
        ["SLIDER", ["Detection radius", "Horizontal detection radius in metres."], [100, 10000, 2000, 0]],
        ["SLIDER", ["Minimum altitude", "Aircraft at or above this height can be detected."], [0, 1500, 50, 0]],
        ["SLIDER", ["Maximum altitude", "Aircraft above this height are ignored."], [50, 10000, 10000, 0]],
        ["SLIDER", ["Engagement radius", "Static/mobile defences activate only inside this range."], [100, 10000, 2000, 0]],
        ["SLIDER", ["Detection dwell", "Continuous detection seconds required before alert."], [0, 30, 0, 1]],
        ["SLIDER", ["Clear delay", "Seconds before a clear detection state is published."], [0, 60, 5, 1]],
        ["COMBO", ["AA side", "Side owning all spawned responses and selecting the default asset pool."], [[west, east, independent], ["BLUFOR", "OPFOR", "Independent"], 1]],
        ["EDIT", ["Asset faction/pool key", "Optional key from Waldo_DynamicAA_FactionAssetPools; blank uses the selected side pool."], [""]],
        ["COMBO", ["Altitude mode", "AUTO uses ATL over land and ASL over water."], [["AUTO", "ATL", "ASL"], ["Automatic", "ATL", "ASL"], 0]],
        ["SLIDER", ["Static sites", "Each site contains a radar, missile launcher and gun."], [0, 8, 1, 0]],
        ["SLIDER", ["Mobile systems", "Faction-specific mobile AA vehicles."], [0, 8, 1, 0]],
        ["SLIDER", ["Scramble fighters", "Faction-specific fighters launched on first detection."], [0, 4, 0, 0]],
        ["CHECKBOX", ["Map markers", "Show the system area and status to all players."], true],
        ["CHECKBOX", ["Delete after radar loss", "Delete spawned assets when the central radar is destroyed."], false],
        ["CHECKBOX", ["Announce state", "Report detection and clear transitions in system chat."], true]
    ],
    {
        params ["_values", "_modulePos"];
        _values params ["_id", "_radius", "_altitude", "_maximumAltitude", "_engagementRadius", "_dwell", "_clearDelay", "_side", "_faction", "_altitudeMode", "_staticCount", "_mobileCount", "_fighterCount", "_markers", "_cleanup", "_announce"];
        [_modulePos, _id, _radius, _altitude, _maximumAltitude, _engagementRadius, _dwell, _clearDelay, _side, _faction, _altitudeMode, round _staticCount, round _mobileCount, round _fighterCount, _markers, _cleanup, _announce] spawn Waldo_fnc_DynamicAAZenPlacement;
    },
    {},
    _modulePos
] call zen_dialog_fnc_create;
