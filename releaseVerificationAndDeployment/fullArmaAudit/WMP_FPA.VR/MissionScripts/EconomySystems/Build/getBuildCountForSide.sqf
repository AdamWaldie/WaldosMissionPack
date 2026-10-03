/*
 * Author: WaldoTheWarfighter
 * Counts completed and active construction jobs of one definition for a side.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (optional, default: "NONE")
 * 1: _buildName <STRING> - build name (optional, default: "")
 *
 * Return Value:
 * <NUMBER> completed plus in-progress count.
 *
 * Example:
 * [_sideKey, _buildName] call Waldo_fnc_EcoBuild_getBuildCountForSide;
 * Locality/Authority: Any machine; reads published building/job registries.
 * Repeat/JIP Behaviour: Repeat-safe read; JIP sees current registries.
 * Current Callers: Construction build-limit checks and status display.
 * Result: The count includes ongoing jobs so limits cannot be bypassed by queueing.
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

