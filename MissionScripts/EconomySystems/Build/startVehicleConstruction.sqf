/*
 * Author: Waldo
 * Start vehicle construction.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _vehicle <OBJECT> - vehicle (optional, default: objNull)
 * 1: _caller <OBJECT> - caller (optional, default: objNull)
 * 2: _buildName <STRING> - build name (optional, default: "")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_vehicle, _caller, _buildName] call Waldo_fnc_EcoBuild_startVehicleConstruction;
 */

        params [
            ["_vehicle", objNull],
            ["_caller", objNull],
            ["_buildName", ""]
        ];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (isNull _vehicle || isNull _caller) exitWith {};
        if !(_vehicle getVariable ["WaldoEcoBuild_IsConstructionVehicle", false]) exitWith {};
        if !(alive _vehicle) exitWith {};
        if (isNil "Waldo_fnc_EcoResource_getSideKeyFromSide") exitWith {};
        if (!(isNil "Waldo_fnc_EcoCommand_hasCommandAuthority") && {!([_caller] call Waldo_fnc_EcoCommand_hasCommandAuthority)}) exitWith {};

        private _sideKey = [side group _caller] call Waldo_fnc_EcoResource_getSideKeyFromSide;
        if !(_sideKey in ["WEST", "EAST", "GUER"]) exitWith {};

        private _entry = [_buildName] call Waldo_fnc_EcoBuild_getBuildDefinition;
        if ((count _entry) <= 0) exitWith {};
        if ([_entry, call Waldo_fnc_EcoBuild_getBuildCatalog] call Waldo_fnc_EcoBuild_hasBuildEntryError) exitWith {};
        if !([_entry, _sideKey] call Waldo_fnc_EcoBuild_isBuildAvailableForSide) exitWith {};
        if !([_entry, _sideKey] call Waldo_fnc_EcoBuild_areBuildRequirementsMetForSide) exitWith {};
        if ([_entry, _sideKey] call Waldo_fnc_EcoBuild_isBuildLimitReachedForSide) exitWith {};
        if !([_entry, _sideKey] call Waldo_fnc_EcoBuild_canAffordBuildForSide) exitWith {};

        {
            [_sideKey, _x param [0, ""], -(_x param [1, 0]), _buildName] call Waldo_fnc_EcoResource_addSideResourceAmount;
        } forEach (_entry param [2, []]);

        private _jobId = format [
            "%1_%2_%3",
            _buildName,
            _sideKey,
            floor ((serverTime * 1000) + (random 100000))
        ];
        [_jobId, _buildName, _sideKey] call Waldo_fnc_EcoBuild_registerConstructionJob;

        private _pos = getPosATL _vehicle;
        private _dir = getDir _vehicle;
        deleteVehicle _vehicle;

        private _siteItems = [_pos, _dir, _sideKey, _buildName] call Waldo_fnc_EcoBuild_spawnConstructionSite;
        private _runtimeRows = call Waldo_fnc_EcoBuild_getConstructionJobRuntime;
        _runtimeRows pushBack [
            _jobId,
            _siteItems,
            _pos,
            _dir,
            _buildName,
            _sideKey,
            1 max (_entry param [4, 60]),
            0,
            0,
            serverTime
        ];
        [_runtimeRows] call Waldo_fnc_EcoBuild_setConstructionJobRuntime;

