/*
 * Author: Waldo
 * Start placed construction.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _pos <ARRAY> - pos (optional, default: [0, 0, 0])
 * 1: _dir <SCALAR> - dir (optional, default: 0)
 * 2: _caller <OBJECT> - caller (optional, default: objNull)
 * 3: _buildName <STRING> - build name (optional, default: "")
 * 4: _source <OBJECT> - source (optional, default: objNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_pos, _dir, _caller, _buildName, _source] call Waldo_fnc_EcoBuild_startPlacedConstruction;
 */

        params [
            ["_pos", [0, 0, 0]],
            ["_dir", 0],
            ["_caller", objNull],
            ["_buildName", ""],
            ["_source", objNull]
        ];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (isNull _caller) exitWith {};
        if (isNil "Waldo_fnc_EcoResource_getSideKeyFromSide") exitWith {};
        if (!(isNil "Waldo_fnc_EcoCommand_hasCommandAuthority") && {!([_caller] call Waldo_fnc_EcoCommand_hasCommandAuthority)}) exitWith {};

        private _sideKey = [side group _caller] call Waldo_fnc_EcoResource_getSideKeyFromSide;
        if !(_sideKey in ["WEST", "EAST", "GUER"]) exitWith {};

        private _entry = [_buildName] call Waldo_fnc_EcoBuild_getBuildDefinition;
        if ((count _entry) <= 0) exitWith {};
        if ([_entry, call Waldo_fnc_EcoBuild_getBuildCatalog] call Waldo_fnc_EcoBuild_hasBuildEntryError) exitWith {};
        if !([_entry, _sideKey] call Waldo_fnc_EcoBuild_isBuildAvailableForSide) exitWith {};
        if !([_entry, _sideKey] call Waldo_fnc_EcoBuild_areBuildRequirementsMetForSide) exitWith {
            [_caller, format ["%1: requirements not met.", _buildName]] call Waldo_fnc_EcoCore_notifyActor;
        };
        if ([_entry, _sideKey] call Waldo_fnc_EcoBuild_isBuildLimitReachedForSide) exitWith {
            [_caller, format ["%1: build limit reached.", _buildName]] call Waldo_fnc_EcoCore_notifyActor;
        };
        if !([_entry, _sideKey] call Waldo_fnc_EcoBuild_canAffordBuildForSide) exitWith {
            [_caller, format ["%1: not enough resources.", _buildName]] call Waldo_fnc_EcoCore_notifyActor;
        };

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

        if (!isNull _source && {_source getVariable ["WaldoEcoBuild_IsConstructionVehicle", false]}) then {
            deleteVehicle _source;
        };

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

