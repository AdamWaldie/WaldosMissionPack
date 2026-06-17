/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - getBuildCountForSide
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_getBuildCountForSide via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_sideKey", "NONE"], ["_buildName", ""]];

        if (_sideKey isEqualTo "NONE" || {_buildName isEqualTo ""}) exitWith {0};

        private _entry = [_buildName] call Waldo_fnc_EcoBuild_getBuildDefinition;
        private _resolvedName = if ((count _entry) > 0) then {_entry param [0, _buildName]} else {_buildName};
        private _rows = call Waldo_fnc_EcoBuild_getSpawnedBuildings;
        private _activeJobs = call Waldo_fnc_EcoBuild_getActiveConstructionJobs;

        private _builtCount = {
            !isNull _x
            && {(_x getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"]) isEqualTo _sideKey}
            && {(_x getVariable ["WaldoEcoBuild_BuildDefinitionName", ""]) isEqualTo _resolvedName}
        } count _rows;

        private _activeCount = {
            ((_x param [1, ""]) isEqualTo _resolvedName)
            && {(_x param [2, "NONE"]) isEqualTo _sideKey}
        } count _activeJobs;

        _builtCount + _activeCount

