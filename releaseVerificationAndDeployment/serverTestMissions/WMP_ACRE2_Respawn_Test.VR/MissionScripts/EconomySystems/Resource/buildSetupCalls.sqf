/*
 * Author: WaldoTheWarfighter
 * Converts the economy state authored through Resource Zeus modules into public setup calls.
 *
 * Arguments:
 * 0: include definitions and side settings
 * 1: include placed zones and crates
 *
 * Return Value:
 * ARRAY of STRING - ordered SQF statements.
 */
params [
    ["_includeDefinitions", true, [false]],
    ["_includePlacements", true, [false]]
];

private _lines = ["// RESOURCE MODULE SETUP"];

if (_includeDefinitions) then {
    _lines pushBack "// Resource: Define Resource Types";
    {
        _lines pushBack (str _x + " call Waldo_fnc_EcoResource_addResourceType;");
    } forEach (call Waldo_fnc_EcoResource_getResourceCatalog);

    _lines pushBack "";
    _lines pushBack "// Resource: Set Side Balances";
    {
        _x params ["_sideKey", "_rows"];
        {
            _lines pushBack (str [_sideKey, _x param [0, "Resource"], _x param [1, 0], "Mission Setup"] + " call Waldo_fnc_EcoResource_setSideResourceAmount;");
        } forEach _rows;
    } forEach (call Waldo_fnc_EcoResource_getAllSideResourceRows);

    _lines pushBack "";
    _lines pushBack "// Resource: Map Visibility";
    _lines pushBack (str [missionNamespace getVariable ["WaldoEcoResource_ResourceMarkersVisible", true], "Mission Setup"] + " call Waldo_fnc_EcoResource_setResourceMarkerVisibility;");
};

if (_includePlacements) then {
    _lines pushBack "";
    _lines pushBack "// Resource: Place Production Zones";
    {
        private _arguments = [
            _x param [2, [0, 0, 0]],
            _x param [1, "Resource Zone"],
            _x param [3, 20],
            _x param [4, []],
            _x param [5, "NONE"],
            _x param [7, 30]
        ];
        _lines pushBack (str _arguments + " call Waldo_fnc_EcoResource_createResourceZone;");
    } forEach (call Waldo_fnc_EcoResource_getResourceZones);

    _lines pushBack "";
    _lines pushBack "// Resource: Place Collectible Crates";
    {
        if (!isNull _x && {alive _x} && {!(_x getVariable ["WaldoEcoResource_Collected", false])}) then {
            _lines pushBack (str [getPosATL _x, _x getVariable ["WaldoEcoResource_ResourceRows", []]] + " call Waldo_fnc_EcoResource_spawnResourceCrate;");
        };
    } forEach ((allMissionObjects "Land_PlasticCase_01_medium_F") select {
        _x getVariable ["WaldoEcoResource_IsResourceCrate", false]
    });
};

_lines
