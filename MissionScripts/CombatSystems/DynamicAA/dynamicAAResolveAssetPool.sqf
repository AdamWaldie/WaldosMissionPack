/*
 * Author: Waldo
 * Resolves one Dynamic AA asset pool from side defaults, an optional faction key and per-system overrides.
 *
 * Arguments:
 * 0: config <HASHMAP>
 * 1: side <SIDE>
 *
 * Return Value:
 * HashMap - radarClasses, staticSitePools, mobileClasses, fighterClasses and source
 *
 * Example:
 * private _pool = [_config, east] call Waldo_fnc_DynamicAAResolveAssetPool;
 */

params [
    ["_config", createHashMap, [createHashMap]],
    ["_side", east, [sideUnknown]]
];

private _sideKey = switch (_side) do {
    case west: {"WEST"};
    case independent: {"INDEPENDENT"};
    default {"EAST"};
};
private _defaultPool = createHashMapFromArray [
    ["radarClasses", ["Land_Radar_F"]],
    ["staticSitePools", [["B_Radar_System_01_F", "B_SAM_System_01_F", "B_AAA_System_01_F"]]],
    ["mobileClasses", [switch (_side) do {
        case west: {"B_APC_Tracked_01_AA_F"};
        case independent: {"I_LT_01_AA_F"};
        default {"O_APC_Tracked_02_AA_F"};
    }]],
    ["fighterClasses", [switch (_side) do {
        case west: {"B_Plane_Fighter_01_F"};
        case independent: {"I_Plane_Fighter_04_F"};
        default {"O_Plane_Fighter_02_F"};
    }]],
    ["source", _sideKey]
];

private _pool = createHashMap;
{_pool set [_x, _defaultPool get _x]} forEach keys _defaultPool;
private _sidePools = missionNamespace getVariable ["Waldo_DynamicAA_SideAssetPools", createHashMap];
private _selected = _sidePools getOrDefault [_sideKey, createHashMap];
if (count _selected > 0) then {
    {_pool set [_x, _selected get _x]} forEach keys _selected;
};

private _factionKey = _config getOrDefault ["faction", ""];
private _factionPools = missionNamespace getVariable ["Waldo_DynamicAA_FactionAssetPools", createHashMap];
if (_factionKey != "" && {_factionKey in (keys _factionPools)}) then {
    private _factionPool = _factionPools get _factionKey;
    {_pool set [_x, _factionPool get _x]} forEach keys _factionPool;
    _pool set ["source", _factionKey];
};

private _systemPool = _config getOrDefault ["assetPool", createHashMap];
if (count _systemPool > 0) then {
    {_pool set [_x, _systemPool get _x]} forEach keys _systemPool;
    _pool set ["source", format ["%1/system", _pool getOrDefault ["source", _sideKey]]];
};

private _validClasses = {
    params ["_classes"];
    _classes select {_x isEqualType "" && {_x != ""} && {isClass (configFile >> "CfgVehicles" >> _x)}}
};
private _radars = [(_pool getOrDefault ["radarClasses", []])] call _validClasses;
private _mobiles = [(_pool getOrDefault ["mobileClasses", []])] call _validClasses;
private _fighters = [(_pool getOrDefault ["fighterClasses", []])] call _validClasses;
private _staticPools = (_pool getOrDefault ["staticSitePools", []]) apply {[_x] call _validClasses};
_staticPools = _staticPools select {count _x > 0};

if (count _radars == 0) then {_radars = +(_defaultPool get "radarClasses")};
if (count _mobiles == 0) then {_mobiles = +(_defaultPool get "mobileClasses")};
if (count _fighters == 0) then {_fighters = +(_defaultPool get "fighterClasses")};
if (count _staticPools == 0) then {_staticPools = +(_defaultPool get "staticSitePools")};

_pool set ["radarClasses", _radars];
_pool set ["staticSitePools", _staticPools];
_pool set ["mobileClasses", _mobiles];
_pool set ["fighterClasses", _fighters];
_pool
