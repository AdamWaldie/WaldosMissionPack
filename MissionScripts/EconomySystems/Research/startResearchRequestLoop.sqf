/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - startResearchRequestLoop
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_startResearchRequestLoop via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        if (missionNamespace getVariable ["WaldoEcoResearch_StartResearchRequestLoopStarted", false]) exitWith {};
        missionNamespace setVariable ["WaldoEcoResearch_StartResearchRequestLoopStarted", true];

        [] spawn {
            while {[] call Waldo_fnc_EcoCore_isModuleActive} do {
                {
                    private _request = _x getVariable ["WaldoEcoResearch_StartResearchRequest", []];
                    if (_request isEqualType [] && {(count _request) > 0}) then {
                        [_x, _request] call Waldo_fnc_EcoResearch_processStartResearchRequest;
                    };
                } forEach allPlayers;

                {
                    private _request = _x getVariable ["WaldoEcoResearch_StartResearchRequest", []];
                    if (_request isEqualType [] && {(count _request) > 0}) then {
                        [_x, _request] call Waldo_fnc_EcoResearch_processStartResearchRequest;
                    };
                } forEach ((allMissionObjects "Land_Research_HQ_F") select {
                    _x getVariable ["WaldoEcoResearch_IsResearchCenter", false]
                });

                uiSleep 0.25;
            };

            missionNamespace setVariable ["WaldoEcoResearch_StartResearchRequestLoopStarted", false];
        };

