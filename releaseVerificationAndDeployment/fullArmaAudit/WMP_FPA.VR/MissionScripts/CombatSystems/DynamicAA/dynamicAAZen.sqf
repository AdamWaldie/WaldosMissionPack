/*
 * Author: WaldoTheWarfighter
 * Opens a short staged ZEN workflow for a repeatable Dynamic AA system.
 *
 * Stage one contains only operational and detection settings. Stage two shows either one faction
 * profile selector or exact-selection guidance, never both. Shutdown procedure details are shown
 * in a third small dialog only when that interaction is enabled. Exact mode subsequently asks for
 * one class per requested asset slot, allowing mixed radars, weapons, vehicles and fighters.
 *
 * Arguments:
 * 0: modulePosition <ARRAY> - detection centre selected by module placement
 *
 * Return Value: Nothing.
 * Example: [_modulePos] call Waldo_fnc_DynamicAAZen;
 * Current caller: Dynamic AA - Create in Zen_initModules.sqf.
 */

params [["_modulePos", [], [[]]]];
if !(hasInterface) exitWith {};

private _sidePools = missionNamespace getVariable ["Waldo_DynamicAA_SideAssetPools", createHashMap];
private _factionPools = missionNamespace getVariable ["Waldo_DynamicAA_FactionAssetPools", createHashMap];
private _catalogue = createHashMapFromArray [
    ["profileValues", [""]], ["profileLabels", ["Operational-side default content"]],
    ["radarClasses", []], ["staticClasses", []], ["mobileClasses", []], ["fighterClasses", []]
];
{
    private _key = _x;
    private _name = getText (configFile >> "CfgFactionClasses" >> _key >> "displayName");
    if (_name == "") then {_name = _key};
    (_catalogue get "profileValues") pushBack _key;
    (_catalogue get "profileLabels") pushBack format ["%1  [%2]", _name, _key];
} forEach ((keys _factionPools) call BIS_fnc_sortAlphabetically);

private _collectPool = {
    params ["_pool"];
    {(_catalogue get "radarClasses") pushBackUnique _x} forEach (_pool getOrDefault ["radarClasses", []]);
    {{(_catalogue get "staticClasses") pushBackUnique _x} forEach _x} forEach (_pool getOrDefault ["staticSitePools", []]);
    {(_catalogue get "mobileClasses") pushBackUnique _x} forEach (_pool getOrDefault ["mobileClasses", []]);
    {(_catalogue get "fighterClasses") pushBackUnique _x} forEach (_pool getOrDefault ["fighterClasses", []]);
};
{[_sidePools get _x] call _collectPool} forEach keys _sidePools;
{[_factionPools get _x] call _collectPool} forEach keys _factionPools;
{
    _x params ["_classKey", "_labelKey"];
    private _classes = _catalogue get _classKey;
    private _labels = _classes apply {
        private _name = getText (configFile >> "CfgVehicles" >> _x >> "displayName");
        if (_name == "") then {_name = _x};
        format ["%1  [%2]", _name, _x]
    };
    _catalogue set [_labelKey, _labels];
} forEach [
    ["radarClasses", "radarLabels"],
    ["staticClasses", "staticLabels"],
    ["mobileClasses", "mobileLabels"],
    ["fighterClasses", "fighterLabels"]
];
if ((_catalogue get "radarClasses") isEqualTo []) exitWith {
    ["DYNAMIC AA", "No valid radar classes are configured.", "ERROR", "DYNAMIC_AA_CONFIG"] call Waldo_fnc_FeatureNotifyLocal;
};

private _defaultId = ["AA"] call Waldo_fnc_CreateRuntimeId;
[
    "Dynamic AA: System and Detection",
    [
        ["TOOLBOX:WIDE", ["Operational side", "Controls crew allegiance and hostile detection, not the equipment faction."], [1, 1, 3, ["BLUFOR", "OPFOR", "Independent"]]],
        ["TOOLBOX:WIDE", ["Equipment workflow", "Profile selects a reusable content pool. Exact chooses every requested asset independently."], [0, 1, 2, ["Faction profile", "Exact mixed assets"]]],
        ["SLIDER", ["Radar objects", "Number of radar buildings or units to place."], [1, 4, 1, 0]],
        ["SLIDER", ["Static AA positions", "Profile mode creates integrated sites; exact mode chooses one asset at each position."], [0, 8, 1, 0]],
        ["SLIDER", ["Mobile AA positions", "Number of mobile AA vehicles. Zero disables this response."], [0, 8, 1, 0]],
        ["SLIDER", ["Fighters per wave", "Number of individually selected or profile-pooled fighters. Zero disables scrambling."], [0, 4, 0, 0]],
        ["SLIDER", ["Detection radius (m)", "Horizontal range in metres."], [100, 10000, 2000, 0]],
        ["SLIDER", ["Minimum altitude (m)", "Aircraft below this height are ignored."], [0, 1500, 50, 0]],
        ["SLIDER", ["Maximum altitude (m)", "Aircraft above this height are ignored."], [50, 10000, 10000, 0]],
        ["SLIDER", ["Engagement radius (m)", "Defences activate only while an eligible aircraft is inside this range."], [100, 10000, 2000, 0]],
        ["SLIDER", ["Detection dwell (s)", "Continuous detection time required before activation."], [0, 30, 0, 1]],
        ["SLIDER", ["Clear delay (s)", "Time without a target before the system stands down."], [0, 60, 5, 1]],
        ["TOOLBOX:WIDE", ["Altitude reference", "Automatic uses ATL over land and ASL over water."], [0, 1, 3, ["Automatic", "ATL", "ASL"]]]
    ],
    {
        params ["_values", "_arguments"];
        _arguments params ["_modulePos", "_defaultId", "_catalogue"];
        _values params ["_sideIndex", "_modeIndex", "_radarCount", "_staticCount", "_mobileCount", "_fighterCount", "_radius", "_minimumAltitude", "_maximumAltitude", "_engagementRadius", "_dwell", "_clearDelay", "_altitudeIndex"];
        private _settings = createHashMapFromArray [
            ["side", [west, east, independent] param [_sideIndex, east]],
            ["assetSelectionMode", ["PROFILE", "EXACT"] param [_modeIndex, "PROFILE"]],
            ["radarCount", round _radarCount], ["staticCount", round _staticCount],
            ["mobileCount", round _mobileCount], ["fighterCount", round _fighterCount],
            ["radius", _radius], ["minimumAltitude", _minimumAltitude], ["maximumAltitude", _maximumAltitude],
            ["engagementRadius", _engagementRadius], ["detectionDwell", _dwell], ["clearDelay", _clearDelay],
            ["altitudeMode", ["AUTO", "ATL", "ASL"] param [_altitudeIndex, "AUTO"]]
        ];
        [_modulePos, _defaultId, _settings, _catalogue] spawn {
            params ["_modulePos", "_defaultId", "_settings", "_catalogue"];
            uiSleep 0;
            private _profileMode = (_settings get "assetSelectionMode") == "PROFILE";
            private _content = [];
            if (_profileMode) then {
                _content pushBack ["LIST", ["Faction/content profile", "Physical equipment profile; independent of operational side."], [_catalogue get "profileValues", _catalogue get "profileLabels", 0, 3]];
            };
            _content append [
                ["CHECKBOX", ["Map markers", "Show the system area and status."], true],
                ["CHECKBOX", ["Delete assets after radar loss", "Otherwise leave the disabled installation in place."], false],
                ["CHECKBOX", ["Announce detection state", "Use WMP notifications for detected and clear transitions."], true],
                ["CHECKBOX", ["Player radar shutdown objective", "Adds a procedure to the primary radar. Details are requested next only when enabled."], false]
            ];
            [
                ["Dynamic AA: Exact Asset Placement", "Dynamic AA: Profile and Behaviour"] select _profileMode,
                _content,
                {
                    params ["_values", "_arguments"];
                    _arguments params ["_modulePos", "_defaultId", "_settings", "_catalogue", "_profileMode"];
                    if (_profileMode) then {_settings set ["faction", _values deleteAt 0]};
                    _values params ["_markers", "_cleanup", "_announce", "_shutdown"];
                    _settings set ["createMarkers", _markers];
                    _settings set ["cleanupOnRadarLoss", _cleanup];
                    _settings set ["announce", _announce];
                    _settings set ["shutdownInteraction", _shutdown];
                    if (_shutdown) then {
                        [_modulePos, _defaultId, _settings, _catalogue] spawn {
                            params ["_modulePos", "_defaultId", "_settings", "_catalogue"];
                            uiSleep 0;
                            [
                                "Dynamic AA: Shutdown Objective",
                                [
                                    ["TOOLBOX:WIDE", ["Procedure", "Challenge players complete on the primary radar."], [0, 2, 2, ["Circuit bypass", "Control-wire isolation", "Command authentication", "Signal alignment"]]],
                                    ["TOOLBOX:WIDE", ["Difficulty", "Shared interaction difficulty profile."], [1, 1, 4, ["Easy", "Standard", "Hard", "Expert"]]]
                                ],
                                {
                                    params ["_values", "_arguments"];
                                    _arguments params ["_modulePos", "_defaultId", "_settings", "_catalogue"];
                                    _values params ["_challengeIndex", "_difficultyIndex"];
                                    _settings set ["shutdownChallenge", ["circuit", "wirecut", "commandinput", "radiotune"] param [_challengeIndex, "circuit"]];
                                    _settings set ["shutdownDifficulty", ["easy", "standard", "hard", "expert"] param [_difficultyIndex, "standard"]];
                                    [_modulePos, _defaultId, _settings, _catalogue] spawn Waldo_fnc_DynamicAAZenPlacement;
                                },
                                {},
                                [_modulePos, _defaultId, _settings, _catalogue]
                            ] call zen_dialog_fnc_create;
                        };
                    } else {
                        [_modulePos, _defaultId, _settings, _catalogue] spawn Waldo_fnc_DynamicAAZenPlacement;
                    };
                },
                {},
                [_modulePos, _defaultId, _settings, _catalogue, _profileMode]
            ] call zen_dialog_fnc_create;
        };
    },
    {},
    [_modulePos, _defaultId, _catalogue]
] call zen_dialog_fnc_create;
