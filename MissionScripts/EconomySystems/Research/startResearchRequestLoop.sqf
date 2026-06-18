/*
 * Author: Waldo
 * Start research request loop.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EcoResearch_startResearchRequestLoop;
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

