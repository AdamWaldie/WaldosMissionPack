/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - spawnConfiguredBuilding
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_spawnConfiguredBuilding via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_pos", "_buildName", ["_sideKey", "NONE"], ["_dir", 0]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

        private _catalog = call Waldo_fnc_EcoBuild_getBuildCatalog;
        private _index = _catalog findIf {
            (toLower (_x param [0, ""])) isEqualTo (toLower _buildName)
        };
        if (_index < 0) exitWith {};

        private _entry = _catalog select _index;
        private _spawnClass = [_entry] call Waldo_fnc_EcoBuild_getBuildSpawnClass;

        private _building = createVehicle [_spawnClass, _pos, [], 0, "CAN_COLLIDE"];
        _building setVehiclePosition [_pos, [], 0, "CAN_COLLIDE"];
        _building setDir _dir;
        _building setVariable ["WaldoEcoBuild_IsConstructedBuilding", true, true];
        _building setVariable ["WaldoEcoBuild_BuildDefinitionName", _entry param [0, ""], true];
        _building setVariable ["WaldoEcoBuild_BuildOwnerSideKey", _sideKey, true];
        _building setVariable ["WaldoEcoBuild_BuildDescription", _entry param [1, ""], true];
        _building setVariable ["WaldoEcoBuild_BuildLastProduction", serverTime, false];
        _building setVariable ["WaldoEcoBuild_BuildLastUpkeep", serverTime, false];
        _building setVariable ["WaldoEcoBuild_ManualDisabled", false, true];
        _building setVariable ["WaldoEcoBuild_IsUpgrading", false, true];
        _building setVariable ["WaldoEcoBuild_UpgradeTargetName", "", true];
        _building setVariable ["WaldoEcoBuild_Operational", true, true];
        _building setVariable ["WaldoEcoBuild_DisabledReason", "", true];
        _building setVariable ["WaldoEcoBuild_MarkerDeleting", false, false];
        _building setVariable ["WaldoEcoBuild_DetectorAreaMarker", "", true];
        _building setVariable ["WaldoEcoBuild_DetectorContactMarkers", [], true];
        _building setVariable ["WaldoEcoBuild_LastDetectionScan", serverTime, false];

        _building addEventHandler ["Deleted", {
            params ["_entity"];
            [_entity] call Waldo_fnc_EcoBuild_cleanupDetectorVisuals;
        }];

        [[_building], true] call Waldo_fnc_EcoCore_registerCuratorEditableObjects;

        private _rows = call Waldo_fnc_EcoBuild_getSpawnedBuildings;
        _rows pushBackUnique _building;
        [_rows] call Waldo_fnc_EcoBuild_setSpawnedBuildings;

        [_building] call Waldo_fnc_EcoBuild_trackBuildingMarker;

        [_building, _entry] call Waldo_fnc_EcoBuild_attachBuildingActions;

