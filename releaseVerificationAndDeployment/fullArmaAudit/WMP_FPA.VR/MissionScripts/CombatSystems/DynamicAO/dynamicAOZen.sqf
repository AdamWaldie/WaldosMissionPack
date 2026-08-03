/*
 * Author: WaldoTheWarfighter
 * Opens one user-friendly ZEN dialog that creates a complete Dynamic AO at the module position.
 *
 * Faction and allegiance are one friendly-name selector, eliminating raw class entry and invalid
 * side/faction combinations without staged dialogs. All bounded runtime options map directly to
 * Waldo_fnc_DynamicAOCreate; generated units use the active WMP AI profile, while vehicle and air
 * percentages are ratios and need not total 100.
 * Current caller: Dynamic AO - Create in Zen_initModules.sqf.
 *
 * Arguments:
 * 0: module position <ARRAY>
 *
 * Return Value:
 * Boolean - true when the dialog was opened
 *
 * Example:
 * [_modulePos] call Waldo_fnc_DynamicAOZen;
 */
params [["_modulePos", [], [[]]]];
if !(hasInterface) exitWith {false};
private _factions = [[west, east, independent, civilian]] call Waldo_fnc_DynamicAOGetFactions;
if (count _factions == 0) exitWith {
    ["DYNAMIC AO", "No usable combat factions are present in the running modset.", "ERROR", "DYNAMIC_AO", 7]
        call Waldo_fnc_FeatureNotifyLocal;
    false
};
private _factionValues = _factions apply {_x select 1};
private _factionLabels = _factions apply {_x select 2};
private _civilianFactions = [[civilian]] call Waldo_fnc_DynamicAOGetFactions;
private _civilianValues = [""];
private _civilianLabels = ["None - do not populate civilians"];
{_civilianValues pushBack (_x select 1); _civilianLabels pushBack (_x select 2)} forEach _civilianFactions;
private _defaultName = ["AO"] call Waldo_fnc_CreateRuntimeId;

[
    "Create Dynamic Area of Operations",
    [
        ["EDIT", ["AO name", "Stable script/cleanup identifier. Unsupported characters are removed."], [_defaultName]],
        ["COMBO", ["Enemy faction and side", "Live faction scan. The side shown in brackets owns every spawned enemy group."], [_factionValues, _factionLabels, 0]],
        ["SLIDER", ["AO radius", "Generation and ground-patrol radius in metres."], [100, 2000, 500, 0]],
        ["SLIDER", ["Infantry patrol groups", "Each patrol contains four to eight faction infantry."], [0, 12, 3, 0]],
        ["SLIDER", ["Building garrison groups", "Two to four units per usable building; silently capped by available buildings."], [0, 30, 3, 0]],
        ["SLIDER", ["Manned static turrets", "Random faction static weapons, including supported HMG, GMG, AA, AT and mortar assets."], [0, 20, 0, 0]],
        ["SLIDER", ["Vehicle patrols", "Total ground vehicles selected from the three ratios below."], [0, 10, 0, 0]],
        ["SLIDER", ["Vehicle ratio - cars", "Relative weight; values are normalized automatically."], [0, 100, 34, 0]],
        ["SLIDER", ["Vehicle ratio - APCs", "Relative weight; empty asset buckets fall through automatically."], [0, 100, 33, 0]],
        ["SLIDER", ["Vehicle ratio - tanks", "Relative weight; all-zero available weights become equal."], [0, 100, 33, 0]],
        ["SLIDER", ["Air patrols", "Total aircraft selected from the four ratios below."], [0, 8, 0, 0]],
        ["SLIDER", ["Air ratio - helicopters", "Relative rotary-wing weight."], [0, 100, 25, 0]],
        ["SLIDER", ["Air ratio - jets", "Fixed-wing assets at or above 600 km/h."], [0, 100, 25, 0]],
        ["SLIDER", ["Air ratio - drones", "Any rotary or fixed-wing asset with isUav enabled."], [0, 100, 25, 0]],
        ["SLIDER", ["Air ratio - planes", "Fixed-wing assets below 600 km/h."], [0, 100, 25, 0]],
        ["SLIDER", ["Helicopter patrol range", "Maximum rotary-wing route radius in metres."], [200, 3000, 1000, 0]],
        ["SLIDER", ["Plane patrol range", "Maximum fixed-wing route radius in metres."], [200, 4000, 2000, 0]],
        ["CHECKBOX", ["Simple pathing", "Use two movement points plus cycle instead of the standard four-point randomized routes."], false],
        ["COMBO", ["Civilian faction", "Live civilian-faction scan; choose None for a combat-only AO."], [_civilianValues, _civilianLabels, 0]],
        ["SLIDER", ["Wandering civilians", "Individual civilian patrols; requires a civilian faction."], [0, 50, 0, 0]],
        ["SLIDER", ["Building civilians", "Individual civilians placed in usable buildings."], [0, 50, 0, 0]],
        ["SLIDER", ["Parked civilian cars", "Empty civilian cars placed in safe open positions."], [0, 30, 0, 0]],
        ["SLIDER", ["Outer-ring minefields", "Each field has its own Zeus cleanup anchor."], [0, 15, 0, 0]],
        ["CHECKBOX", ["Show minefield markers", "Show a red border around each generated mine cluster."], false],
        ["SLIDER", ["Manned roadblocks", "Checkpoints require roads inside the AO and may legitimately spawn fewer."], [0, 12, 0, 0]],
        ["CHECKBOX", ["Show AO marker", "Global side-coloured AO border and named centre marker."], true]
    ],
    {
        params ["_values", "_arguments"];
        _arguments params ["_modulePosition", "_factions"];
        _values params [
            "_name", "_faction", "_radius", "_patrols", "_garrisons", "_statics",
            "_vehicles", "_car", "_apc", "_tank", "_air", "_heli", "_jet", "_drone", "_plane",
            "_heliRange", "_planeRange", "_simple", "_civilianFaction", "_civPatrol", "_civGarrison",
            "_civCars", "_mines", "_mineMarkers", "_roadblocks", "_showMarker"
        ];
        private _row = _factions select ((_factions findIf {(_x select 1) == _faction}) max 0);
        private _id = [_name, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] call BIS_fnc_filterString;
        if (_id == "") then {_id = ["AO"] call Waldo_fnc_CreateRuntimeId};
        private _config = createHashMapFromArray [
            ["id", _id], ["center", _modulePosition], ["side", _row select 0], ["faction", _faction],
            ["radius", _radius], ["patrolGroups", round _patrols],
            ["garrisonGroups", round _garrisons], ["staticTurrets", round _statics],
            ["vehiclePatrols", round _vehicles], ["vehicleMix", [_car, _apc, _tank]],
            ["airPatrols", round _air], ["airMix", [_heli, _jet, _drone, _plane]],
            ["heliPatrolRange", _heliRange], ["planePatrolRange", _planeRange], ["simplePathing", _simple],
            ["civilianFaction", _civilianFaction], ["civilianPatrols", round _civPatrol],
            ["civilianGarrisons", round _civGarrison], ["civilianCars", round _civCars],
            ["minefields", round _mines], ["showMineMarkers", _mineMarkers],
            ["roadblocks", round _roadblocks], ["showMarker", _showMarker]
        ];
        [_config, player] remoteExecCall ["Waldo_fnc_DynamicAOCreate", 2];
    },
    {},
    [_modulePos, _factions]
] call zen_dialog_fnc_create;
true
