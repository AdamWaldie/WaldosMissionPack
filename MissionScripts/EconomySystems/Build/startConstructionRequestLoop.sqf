/*
 * Author: Waldo
 * Start construction request loop.
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
 * [] call Waldo_fnc_EcoBuild_startConstructionRequestLoop;
 */

        if (!([] call Waldo_fnc_EcoCore_canRunBackgroundAuthority)) exitWith {};
        if (missionNamespace getVariable ["WaldoEcoBuild_StartConstructionRequestLoopStarted", false]) exitWith {};
        missionNamespace setVariable ["WaldoEcoBuild_StartConstructionRequestLoopStarted", true];

        [] spawn {
            while {[] call Waldo_fnc_EcoCore_isModuleActive} do {
                {
                    private _request = _x getVariable ["WaldoEcoBuild_StartConstructionRequest", []];
                    if (_request isEqualType [] && {(count _request) > 0}) then {
                        [_x, _request] call Waldo_fnc_EcoBuild_processStartConstructionRequest;
                    };
                } forEach ((allMissionObjects "Land_Research_HQ_F") select {
                    _x getVariable ["WaldoEcoResearch_IsResearchCenter", false]
                });

                {
                    private _request = _x getVariable ["WaldoEcoBuild_StartConstructionRequest", []];
                    if (_request isEqualType [] && {(count _request) > 0}) then {
                        [_x, _request] call Waldo_fnc_EcoBuild_processStartConstructionRequest;
                    };
                } forEach (vehicles select {
                    _x getVariable ["WaldoEcoBuild_IsConstructionVehicle", false]
                });

                uiSleep 0.25;
            };

            missionNamespace setVariable ["WaldoEcoBuild_StartConstructionRequestLoopStarted", false];
        };

