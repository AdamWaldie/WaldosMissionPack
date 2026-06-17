/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - startBuildingManageRequestLoop
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_startBuildingManageRequestLoop via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        if (!([] call Waldo_fnc_EcoCore_canRunBackgroundAuthority)) exitWith {};
        if (missionNamespace getVariable ["WaldoEcoBuild_BuildingManageRequestLoopStarted", false]) exitWith {};
        missionNamespace setVariable ["WaldoEcoBuild_BuildingManageRequestLoopStarted", true];

        [] spawn {
            while {[] call Waldo_fnc_EcoCore_isModuleActive} do {
                {
                    private _request = _x getVariable ["WaldoEcoBuild_BuildingManageRequest", []];
                    if (_request isEqualType [] && {(count _request) > 0}) then {
                        [_x, _request] call Waldo_fnc_EcoBuild_processBuildingManageRequest;
                    };
                } forEach (call Waldo_fnc_EcoBuild_getSpawnedBuildings);

                uiSleep 0.25;
            };

            missionNamespace setVariable ["WaldoEcoBuild_BuildingManageRequestLoopStarted", false];
        };

