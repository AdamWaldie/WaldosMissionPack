/*
 * Author: WaldoTheWarfighter
 * Converts the economy state authored through Construction Zeus modules into public setup calls.
 *
 * Arguments:
 * 0: include build definitions <BOOL>, default true.
 * 1: include placed construction sources and completed buildings <BOOL>, default true.
 *
 * Return Value:
 * ARRAY of STRING - ordered SQF statements.
 * Locality/Authority: Read-only curator export; generated calls belong in authoritative setup.
 * Repeat/JIP Behaviour: Repeated export reads current published state without changing it.
 * Current Callers: Economy unified setup-script exporter.
 * Example: [true, true] call Waldo_fnc_EcoBuild_buildSetupCalls;
 * Result: Returns catalog and placed-object setup statements in order.
 */
params [
    ["_includeDefinitions", true, [false]],
    ["_includePlacements", true, [false]]
];

private _lines = ["// CONSTRUCTION MODULE SETUP"];

if (_includeDefinitions) then {
    _lines pushBack "// Construction: Define Build Catalogue";
    _lines pushBack (str [call Waldo_fnc_EcoBuild_getBuildCatalog] + " call Waldo_fnc_EcoBuild_setBuildCatalog;");
};

if (_includePlacements) then {
    _lines pushBack "";
    _lines pushBack "// Construction: Place Build Sources";
    {
        _lines pushBack (str [getPosATL _x, typeOf _x] + " call Waldo_fnc_EcoBuild_spawnConstructionVehicle;");
    } forEach (vehicles select {
        _x getVariable ["WaldoEcoBuild_IsConstructionVehicle", false]
    });

    _lines pushBack "";
    _lines pushBack "// Construction: Place Completed Buildings";
    {
        if (!isNull _x && {alive _x}) then {
            private _buildName = _x getVariable ["WaldoEcoBuild_BuildDefinitionName", ""];
            if (_buildName != "") then {
                private _arguments = [
                    getPosATL _x,
                    _buildName,
                    _x getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"],
                    getDir _x
                ];
                _lines pushBack (str _arguments + " call Waldo_fnc_EcoBuild_spawnConfiguredBuilding;");
            };
        };
    } forEach (call Waldo_fnc_EcoBuild_getSpawnedBuildings);
};

_lines
