/*
 * Author: Waldo
 * Start building manage request loop.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EcoBuild_startBuildingManageRequestLoop;
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

