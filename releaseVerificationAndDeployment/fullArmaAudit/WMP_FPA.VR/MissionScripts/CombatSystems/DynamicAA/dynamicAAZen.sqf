/*
 * Author: WaldoTheWarfighter
 * Opens the ZEN configuration dialog for a repeatable Dynamic AA system.
 *
 * Operational side and physical asset profile are deliberately independent. The dialog exposes
 * friendly display names and passes its validated configuration into the server-owned creation
 * workflow. It is currently called by Dynamic AA - Create in Zen_initModules.sqf.
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

private _resolveProfiles = {
        private _sideKey = "SELECTED SIDE";
        private _profileValues = [""];
        private _profileLabels = [format ["%1 default integrated air defence", _sideKey]];
        private _factionPools = missionNamespace getVariable ["Waldo_DynamicAA_FactionAssetPools", createHashMap];
        {
            private _key = _x;
            private _pool = _factionPools get _key;
            if (count _pool > 0) then {
                private _factionName = getText (configFile >> "CfgFactionClasses" >> _key >> "displayName");
                if (_factionName == "") then {_factionName = _key};
                _profileValues pushBack _key;
                _profileLabels pushBack format ["%1 profile", _factionName];
            };
        } forEach ((keys _factionPools) call BIS_fnc_sortAlphabetically);
    [_profileValues, _profileLabels]
};

private _initialProfiles = call _resolveProfiles;
private _defaultId = format ["AA_%1_%2", clientOwner, round (serverTime * 10)];
private _created = [
    "Create Dynamic AA System",
    [
        ["COMBO", ["Operational side", "Controls crew allegiance and hostile detection. It does not restrict the physical AA assets."], [[west, east, independent], ["BLUFOR", "OPFOR", "Independent"], 1]],
        ["COMBO", ["Asset profile", "Default uses the operational side pool; named profiles may contain assets from any faction."], [_initialProfiles select 0, _initialProfiles select 1, 0]],
        ["SLIDER", ["Detection radius", "Horizontal detection radius in metres."], [100, 10000, 2000, 0]],
        ["SLIDER", ["Minimum altitude", "Aircraft at or above this height can be detected."], [0, 1500, 50, 0]],
        ["SLIDER", ["Maximum altitude", "Aircraft above this height are ignored."], [50, 10000, 10000, 0]],
        ["SLIDER", ["Engagement radius", "Static/mobile defences activate only inside this range."], [100, 10000, 2000, 0]],
        ["SLIDER", ["Detection dwell", "Continuous detection seconds required before alert."], [0, 30, 0, 1]],
        ["SLIDER", ["Clear delay", "Seconds before a clear detection state is published."], [0, 60, 5, 1]],
        ["COMBO", ["Altitude mode", "AUTO uses ATL over land and ASL over water."], [["AUTO", "ATL", "ASL"], ["Automatic", "ATL", "ASL"], 0]],
        ["SLIDER", ["Static sites", "Each site contains a radar, missile launcher and gun."], [0, 8, 1, 0]],
        ["SLIDER", ["Mobile systems", "Faction-specific mobile AA vehicles."], [0, 8, 1, 0]],
        ["SLIDER", ["Scramble fighters", "Faction-specific fighters launched on first detection."], [0, 4, 0, 0]],
        ["CHECKBOX", ["Map markers", "Show the system area and status to all players."], true],
        ["CHECKBOX", ["Delete after radar loss", "Delete spawned assets when the central radar is destroyed."], false],
        ["CHECKBOX", ["Announce state", "Report detection and clear transitions in system chat."], true],
        ["CHECKBOX", ["Require Radar Shutdown Procedure", "Allow players to disable the system by completing a procedure on its central radar."], false],
        ["COMBO", ["Shutdown Procedure", "Circuit bypass is the semantic default; choose another procedure only when it better fits the scenario."], [["circuit", "wirecut", "commandinput", "radiotune"], ["Circuit bypass", "Control-wire isolation", "Command authentication", "Signal alignment"], 0]],
        ["COMBO", ["Procedure Difficulty", "Shared interaction difficulty profile."], [["easy", "standard", "hard", "expert"], ["Easy", "Standard", "Hard", "Expert"], 1]]
    ],
    {
        params ["_values", "_arguments"];
        _arguments params ["_modulePos", "_defaultId"];
        _values params ["_side", "_faction", "_radius", "_altitude", "_maximumAltitude", "_engagementRadius", "_dwell", "_clearDelay", "_altitudeMode", "_staticCount", "_mobileCount", "_fighterCount", "_markers", "_cleanup", "_announce", "_shutdownInteraction", "_shutdownChallenge", "_shutdownDifficulty"];
        [_modulePos, _defaultId, _radius, _altitude, _maximumAltitude, _engagementRadius, _dwell, _clearDelay, _side, _faction, _altitudeMode, round _staticCount, round _mobileCount, round _fighterCount, _markers, _cleanup, _announce, _shutdownInteraction, _shutdownChallenge, _shutdownDifficulty] spawn Waldo_fnc_DynamicAAZenPlacement;
    },
    {},
    [_modulePos, _defaultId]
] call zen_dialog_fnc_create;

_created;
