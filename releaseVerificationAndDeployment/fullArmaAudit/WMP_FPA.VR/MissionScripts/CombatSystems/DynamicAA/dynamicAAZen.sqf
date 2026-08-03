/*
 * Author: WaldoTheWarfighter
 * Opens the user-facing ZEN configuration dialog for a repeatable Dynamic AA system.
 *
 * Operational side controls allegiance and hostile detection only. Asset profile selects physical
 * content independently, while Exact asset selection lets Zeus choose one radar, static AA, mobile
 * AA and fighter class from every configured profile. Counts of zero disable that response type.
 * All selectors use display names plus classnames so modded assets remain understandable.
 *
 * Arguments:
 * 0: modulePosition <ARRAY> - detection centre selected by module placement
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_modulePos] call Waldo_fnc_DynamicAAZen;
 *
 * Current caller: Dynamic AA - Create in Zen_initModules.sqf.
 */

params [["_modulePos", [], [[]]]];
if !(hasInterface) exitWith {};

private _sidePools = missionNamespace getVariable ["Waldo_DynamicAA_SideAssetPools", createHashMap];
private _factionPools = missionNamespace getVariable ["Waldo_DynamicAA_FactionAssetPools", createHashMap];

private _profileValues = [""];
private _profileLabels = ["Operational-side default content"];
{
    private _key = _x;
    private _factionName = getText (configFile >> "CfgFactionClasses" >> _key >> "displayName");
    if (_factionName == "") then {_factionName = _key};
    _profileValues pushBack _key;
    _profileLabels pushBack format ["%1  [%2]", _factionName, _key];
} forEach ((keys _factionPools) call BIS_fnc_sortAlphabetically);

private _radarClasses = [];
private _staticClasses = [];
private _mobileClasses = [];
private _fighterClasses = [];
private _collectPool = {
    params ["_pool"];
    {_radarClasses pushBackUnique _x} forEach (_pool getOrDefault ["radarClasses", []]);
    {{_staticClasses pushBackUnique _x} forEach _x} forEach (_pool getOrDefault ["staticSitePools", []]);
    {_mobileClasses pushBackUnique _x} forEach (_pool getOrDefault ["mobileClasses", []]);
    {_fighterClasses pushBackUnique _x} forEach (_pool getOrDefault ["fighterClasses", []]);
};
{[_sidePools get _x] call _collectPool} forEach keys _sidePools;
{[_factionPools get _x] call _collectPool} forEach keys _factionPools;

private _makeLabels = {
    params ["_classes"];
    _classes apply {
        private _name = getText (configFile >> "CfgVehicles" >> _x >> "displayName");
        if (_name == "") then {_name = _x};
        format ["%1  [%2]", _name, _x]
    }
};
private _radarLabels = [_radarClasses] call _makeLabels;
private _staticLabels = [_staticClasses] call _makeLabels;
private _mobileLabels = [_mobileClasses] call _makeLabels;
private _fighterLabels = [_fighterClasses] call _makeLabels;
if (_radarClasses isEqualTo []) exitWith {
    ["DYNAMIC AA", "No valid radar classes are configured.", "ERROR", "DYNAMIC_AA_CONFIG"] call Waldo_fnc_FeatureNotifyLocal;
};

private _defaultId = ["AA"] call Waldo_fnc_CreateRuntimeId;
[
    "Create Dynamic AA System",
    [
        ["TOOLBOX:WIDE", ["Operational side", "Crew allegiance and which aircraft are hostile. This does not choose the physical equipment."], [1, 1, 3, ["BLUFOR", "OPFOR", "Independent"]]],
        ["TOOLBOX:WIDE", ["Asset selection", "Profile chooses a configured faction/content pool. Exact lets you choose every equipment type below."], [0, 1, 2, ["Faction/content profile", "Exact equipment"]]],
        ["LIST", ["Faction/content profile", "Independent of operational side. Used only in profile mode; blank uses that side's default content."], [_profileValues, _profileLabels, 0, 4]],
        ["LIST", ["Exact radar", "Used only in exact mode. Buildings need no crew; radar vehicles and static weapons receive crew of the operational side."], [_radarClasses, _radarLabels, 0, 4]],
        ["LIST", ["Exact static AA", "Used only in exact mode. One selected weapon is created at every static position."], [_staticClasses, _staticLabels, 0, 4]],
        ["LIST", ["Exact mobile AA", "Used only in exact mode. One selected vehicle is created at every mobile position."], [_mobileClasses, _mobileLabels, 0, 4]],
        ["LIST", ["Exact fighter", "Used only in exact mode. The selected aircraft is used for every scrambled fighter."], [_fighterClasses, _fighterLabels, 0, 4]],
        ["SLIDER", ["Radar units", "Number of independent radar objects to place. The system remains online while the required radar count survives."], [1, 4, 1, 0]],
        ["SLIDER", ["Static AA units/sites", "Exact mode creates this many individual selected weapons. Profile mode creates this many configured integrated sites."], [0, 8, 1, 0]],
        ["SLIDER", ["Mobile AA units", "Number of mobile AA vehicles to place. Zero disables this response."], [0, 8, 1, 0]],
        ["SLIDER", ["Scramble fighters", "Number of fighters in a response wave. Zero disables fighter response."], [0, 4, 0, 0]],
        ["SLIDER", ["Detection radius", "Horizontal detection radius in metres."], [100, 10000, 2000, 0]],
        ["SLIDER", ["Minimum altitude", "Aircraft at or above this height can be detected."], [0, 1500, 50, 0]],
        ["SLIDER", ["Maximum altitude", "Aircraft above this height are ignored."], [50, 10000, 10000, 0]],
        ["SLIDER", ["Engagement radius", "Static/mobile defences activate only inside this range."], [100, 10000, 2000, 0]],
        ["SLIDER", ["Detection dwell", "Continuous detection seconds required before alert."], [0, 30, 0, 1]],
        ["SLIDER", ["Clear delay", "Seconds before a clear detection state is published."], [0, 60, 5, 1]],
        ["TOOLBOX:WIDE", ["Altitude mode", "AUTO uses ATL over land and ASL over water."], [0, 1, 3, ["Automatic", "ATL", "ASL"]]],
        ["CHECKBOX", ["Map markers", "Show the system area and status to all players."], true],
        ["CHECKBOX", ["Delete after radar loss", "Delete spawned assets when insufficient radars remain operational."], false],
        ["CHECKBOX", ["Announce state", "Report detection and clear transitions through WMP notifications."], true],
        ["CHECKBOX", ["Require Radar Shutdown Procedure", "Allow players to disable the system by completing a procedure on its primary radar."], false],
        ["TOOLBOX:WIDE", ["Shutdown Procedure", "Choose the interaction challenge used on the primary radar."], [0, 2, 2, ["Circuit bypass", "Control-wire isolation", "Command authentication", "Signal alignment"]]],
        ["TOOLBOX:WIDE", ["Procedure Difficulty", "Shared interaction difficulty profile."], [1, 1, 4, ["Easy", "Standard", "Hard", "Expert"]]]
    ],
    {
        params ["_values", "_arguments"];
        _arguments params ["_modulePos", "_defaultId"];
        _values params ["_sideIndex", "_assetModeIndex", "_faction", "_radarClass", "_staticClass", "_mobileClass", "_fighterClass", "_radarCount", "_staticCount", "_mobileCount", "_fighterCount", "_radius", "_altitude", "_maximumAltitude", "_engagementRadius", "_dwell", "_clearDelay", "_altitudeModeIndex", "_markers", "_cleanup", "_announce", "_shutdownInteraction", "_shutdownChallengeIndex", "_shutdownDifficultyIndex"];
        private _side = [west, east, independent] param [_sideIndex, east];
        private _assetMode = ["PROFILE", "EXACT"] param [_assetModeIndex, "PROFILE"];
        private _altitudeMode = ["AUTO", "ATL", "ASL"] param [_altitudeModeIndex, "AUTO"];
        private _shutdownChallenge = ["circuit", "wirecut", "commandinput", "radiotune"] param [_shutdownChallengeIndex, "circuit"];
        private _shutdownDifficulty = ["easy", "standard", "hard", "expert"] param [_shutdownDifficultyIndex, "standard"];
        [_modulePos, _defaultId, _radius, _altitude, _maximumAltitude, _engagementRadius, _dwell, _clearDelay, _side, _faction, _assetMode, _radarClass, _staticClass, _mobileClass, _fighterClass, _altitudeMode, round _radarCount, round _staticCount, round _mobileCount, round _fighterCount, _markers, _cleanup, _announce, _shutdownInteraction, _shutdownChallenge, _shutdownDifficulty] spawn Waldo_fnc_DynamicAAZenPlacement;
    },
    {},
    [_modulePos, _defaultId]
] call zen_dialog_fnc_create;
