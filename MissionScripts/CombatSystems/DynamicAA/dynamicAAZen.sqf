/*
 * Author: WaldoTheWarfighter
 * Opens the user-facing ZEN configuration workflow for a repeatable Dynamic AA system.
 *
 * Common detection settings are separated from equipment so profile and exact controls never
 * appear together. Profile mode uses one faction list and response counts. Exact mode retains the
 * original four readable asset lists; each confirmed batch records one class and quantity per
 * category. Optional additional batches allow mixed classes without repetitive per-unit dialogs.
 *
 * The faction profile list always includes every mission-maker-authored Waldo_DynamicAA_
 * FactionAssetPools entry (exact AA hardware), plus every other faction Waldo_fnc_
 * ResolveFactionCatalog finds live in the running modset - auto-detected entries have no specific
 * AA hardware of their own, so Waldo_fnc_DynamicAAResolveAssetPool falls back to the chosen side's
 * default AA pool for them while still using the faction's own identity/label.
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
// Every other faction actually present in the running modset (vanilla or third-party), so a
// mission maker never has to hand-author Waldo_DynamicAA_FactionAssetPools just to see it in the
// list. It gets the side's default AA hardware unless/until they add their own pool entry for it.
private _seenFactions = createHashMap;
{_seenFactions set [_x, true]} forEach keys _factionPools;
{
    _x params ["_discoveredSide", "_discoveredFaction", "_discoveredLabel"];
    if !(_seenFactions getOrDefault [_discoveredFaction, false]) then {
        _seenFactions set [_discoveredFaction, true];
        (_catalogue get "profileValues") pushBack _discoveredFaction;
        (_catalogue get "profileLabels") pushBack format ["%1 (auto-detected - side-default AA hardware unless configured)", _discoveredLabel];
    };
} forEach ([[west, east, independent]] call Waldo_fnc_ResolveFactionCatalog);
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
    ["radarClasses", "radarLabels"], ["staticClasses", "staticLabels"],
    ["mobileClasses", "mobileLabels"], ["fighterClasses", "fighterLabels"]
];
if ((_catalogue get "radarClasses") isEqualTo []) exitWith {
    ["DYNAMIC AA", "No valid radar classes are configured.", "ERROR", "DYNAMIC_AA_CONFIG"] call Waldo_fnc_FeatureNotifyLocal;
};

private _defaultId = ["AA"] call Waldo_fnc_CreateRuntimeId;
private _shutdownOptions = ["circuit"] call Waldo_fnc_MiniGameInteractionOptions;
[
    "Dynamic AA: Detection and Behaviour",
    [
        ["EDIT", ["System and marker name", "Human-readable name shown on map markers and in Zeus removal. It does not control the internal runtime ID."], ["Dynamic AA"]],
        ["TOOLBOX:WIDE", ["Operational side", "Controls crew allegiance and hostile detection, not physical equipment."], [1, 1, 3, ["BLUFOR", "OPFOR", "Independent"]]],
        ["TOOLBOX:WIDE", ["Equipment selection", "Choose one reusable faction profile or manually select mixed equipment."], [0, 1, 2, ["Faction profile", "Exact mixed equipment"]]],
        ["SLIDER", ["Detection radius (m)", "Horizontal detection range."], [100, 10000, 2000, 0]],
        ["SLIDER", ["Minimum altitude (m)", "Aircraft below this height are ignored."], [0, 1500, 60, 0]],
        ["SLIDER", ["Maximum altitude (m)", "Aircraft above this height are ignored."], [50, 10000, 10000, 0]],
        ["SLIDER", ["Engagement radius (m)", "Defences activate only inside this range."], [100, 10000, 2000, 0]],
        ["SLIDER", ["Detection dwell (s)", "Continuous detection time before activation."], [0, 30, 0, 1]],
        ["SLIDER", ["Clear delay (s)", "Time without a target before stand-down."], [0, 60, 5, 1]],
        ["TOOLBOX:WIDE", ["Altitude reference", "Automatic uses ATL over land and ASL over water."], [0, 1, 3, ["Automatic", "ATL", "ASL"]]],
        ["CHECKBOX", ["Map markers", "Show the system area and state."], true],
        ["CHECKBOX", ["Show range and altitude limits", "When map markers are enabled, show detection range, floor and ceiling on the marker label."], true],
        ["CHECKBOX", ["Delete assets after radar loss", "Otherwise leave the disabled installation in place."], false],
        ["CHECKBOX", ["Announce detection state", "Use WMP notifications for detected and clear transitions."], true],
        ["CHECKBOX", ["Player radar shutdown objective", "Adds the selected procedure to the primary radar."], false],
        ["COMBO", ["Shutdown procedure", "Choose any shared interaction procedure. Used only when the shutdown objective is enabled."], _shutdownOptions],
        ["TOOLBOX:WIDE", ["Procedure difficulty", "Used only when the shutdown objective is enabled."], [1, 1, 4, ["Easy", "Standard", "Hard", "Expert"]]]
    ],
    {
        params ["_values", "_arguments"];
        _arguments params ["_modulePos", "_defaultId", "_catalogue"];
        _values params ["_displayNameRaw", "_sideIndex", "_modeIndex", "_radius", "_minimumAltitude", "_maximumAltitude", "_engagementRadius", "_dwell", "_clearDelay", "_altitudeIndex", "_markers", "_showMarkerDetails", "_cleanup", "_announce", "_shutdown", "_challengeId", "_difficultyIndex"];
        private _displayName = [_displayNameRaw, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 _-()[]"] call BIS_fnc_filterString;
        if (_displayName == "") then {_displayName = "Dynamic AA"};
        _displayName = _displayName select [0, 64];
        private _settings = createHashMapFromArray [
            ["displayName", _displayName],
            ["side", [west, east, independent] param [_sideIndex, east]],
            ["assetSelectionMode", ["PROFILE", "EXACT"] param [_modeIndex, "PROFILE"]],
            ["radius", _radius], ["minimumAltitude", _minimumAltitude], ["maximumAltitude", _maximumAltitude],
            ["engagementRadius", _engagementRadius], ["detectionDwell", _dwell], ["clearDelay", _clearDelay],
            ["altitudeMode", ["AUTO", "ATL", "ASL"] param [_altitudeIndex, "AUTO"]],
            ["createMarkers", _markers], ["showMarkerDetails", _showMarkerDetails],
            ["cleanupOnRadarLoss", _cleanup], ["announce", _announce],
            ["shutdownInteraction", _shutdown],
            ["shutdownChallenge", _challengeId],
            ["shutdownDifficulty", ["easy", "standard", "hard", "expert"] param [_difficultyIndex, "standard"]]
        ];
        if ((_settings get "assetSelectionMode") == "PROFILE") then {
            [_modulePos, _defaultId, _settings, _catalogue] spawn {
                params ["_modulePos", "_defaultId", "_settings", "_catalogue"];
                uiSleep 0;
                [
                    "Dynamic AA: Faction Profile",
                    [
                        ["LIST", ["Faction/content profile", "Physical equipment profile; independent of operational side."], [_catalogue get "profileValues", _catalogue get "profileLabels", 0, 4]],
                        ["SLIDER", ["Radar objects", "Radar buildings or units to place."], [1, 4, 1, 0]],
                        ["SLIDER", ["Static AA sites", "Configured integrated sites; zero disables them."], [0, 8, 1, 0]],
                        ["SLIDER", ["Mobile AA systems", "Mobile vehicles; zero disables them."], [0, 8, 1, 0]],
                        ["SLIDER", ["Fighters per wave", "Scrambled aircraft; zero disables them."], [0, 4, 0, 0]]
                    ],
                    {
                        params ["_values", "_arguments"];
                        _arguments params ["_modulePos", "_defaultId", "_settings", "_catalogue"];
                        _values params ["_faction", "_radars", "_statics", "_mobiles", "_fighters"];
                        _settings set ["faction", _faction];
                        _settings set ["radarCount", round _radars];
                        _settings set ["staticCount", round _statics];
                        _settings set ["mobileCount", round _mobiles];
                        _settings set ["fighterCount", round _fighters];
                        [_modulePos, _defaultId, _settings, _catalogue] spawn Waldo_fnc_DynamicAAZenPlacement;
                    },
                    {},
                    [_modulePos, _defaultId, _settings, _catalogue]
                ] call zen_dialog_fnc_create;
            };
        } else {
            private _openExactBatch = {
                params ["_modulePos", "_defaultId", "_settings", "_catalogue", "_batches", "_self"];
                uiSleep 0;
                private _batchNumber = count _batches + 1;
                private _radarDefault = [0, 1] select (_batchNumber == 1);
                [
                    format ["Dynamic AA: Exact Equipment Set %1", _batchNumber],
                    [
                        ["LIST", ["Radar class", "Original readable class selector. Set quantity to zero when this set adds no radar."], [_catalogue get "radarClasses", _catalogue get "radarLabels", 0, 3]],
                        ["SLIDER", ["Radar quantity", "Quantity of the selected radar class in this set."], [0, 4, _radarDefault, 0]],
                        ["LIST", ["Static AA class", "One exact static weapon class."], [_catalogue get "staticClasses", _catalogue get "staticLabels", 0, 3]],
                        ["SLIDER", ["Static AA quantity", "Quantity of the selected static class in this set."], [0, 8, 1, 0]],
                        ["LIST", ["Mobile AA class", "One exact mobile-AA vehicle class."], [_catalogue get "mobileClasses", _catalogue get "mobileLabels", 0, 3]],
                        ["SLIDER", ["Mobile AA quantity", "Quantity of the selected mobile class in this set."], [0, 8, 1, 0]],
                        ["LIST", ["Fighter class", "One exact fighter class."], [_catalogue get "fighterClasses", _catalogue get "fighterLabels", 0, 3]],
                        ["SLIDER", ["Fighter quantity", "Quantity of the selected class in each scramble wave."], [0, 4, 0, 0]],
                        ["CHECKBOX", ["Add another mixed equipment set", "Open this same selector again to add different classes and exact quantities."], false]
                    ],
                    {
                        params ["_values", "_arguments"];
                        _arguments params ["_modulePos", "_defaultId", "_settings", "_catalogue", "_batches", "_self"];
                        _values params ["_radarClass", "_radarCount", "_staticClass", "_staticCount", "_mobileClass", "_mobileCount", "_fighterClass", "_fighterCount", "_addAnother"];
                        _batches pushBack [_radarClass, round _radarCount, _staticClass, round _staticCount, _mobileClass, round _mobileCount, _fighterClass, round _fighterCount];
                        if (_addAnother) then {
                            [_modulePos, _defaultId, _settings, _catalogue, _batches, _self] spawn _self;
                        } else {
                            private _radars = [];
                            private _statics = [];
                            private _mobiles = [];
                            private _fighters = [];
                            {
                                _x params ["_rc", "_rn", "_sc", "_sn", "_mc", "_mn", "_fc", "_fn"];
                                for "_i" from 1 to _rn do {_radars pushBack _rc};
                                for "_i" from 1 to _sn do {_statics pushBack _sc};
                                for "_i" from 1 to _mn do {_mobiles pushBack _mc};
                                for "_i" from 1 to _fn do {_fighters pushBack _fc};
                            } forEach _batches;
                            if (_radars isEqualTo []) exitWith {
                                ["DYNAMIC AA", "Exact equipment requires at least one radar.", "ERROR", "DYNAMIC_AA_CONFIG"] call Waldo_fnc_FeatureNotifyLocal;
                            };
                            _settings set ["radarAssignments", _radars];
                            _settings set ["staticAssignments", _statics];
                            _settings set ["mobileAssignments", _mobiles];
                            _settings set ["fighterAssignments", _fighters];
                            _settings set ["radarCount", count _radars];
                            _settings set ["staticCount", count _statics];
                            _settings set ["mobileCount", count _mobiles];
                            _settings set ["fighterCount", count _fighters];
                            [_modulePos, _defaultId, _settings, _catalogue] spawn Waldo_fnc_DynamicAAZenPlacement;
                        };
                    },
                    {},
                    [_modulePos, _defaultId, _settings, _catalogue, _batches, _self]
                ] call zen_dialog_fnc_create;
            };
            [_modulePos, _defaultId, _settings, _catalogue, [], _openExactBatch] spawn _openExactBatch;
        };
    },
    {},
    [_modulePos, _defaultId, _catalogue]
] call zen_dialog_fnc_create;
