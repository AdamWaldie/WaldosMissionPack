/*
 * Author: Waldo
 * Start crate collect request loop.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EcoResource_startCrateCollectRequestLoop;
 */

    if (!([] call Waldo_fnc_EcoCore_canRunBackgroundAuthority)) exitWith {};
    if (missionNamespace getVariable ["WaldoEcoResource_CollectRequestLoopStarted", false]) exitWith {};
    missionNamespace setVariable ["WaldoEcoResource_CollectRequestLoopStarted", true];

    [] spawn {
        while {[] call Waldo_fnc_EcoCore_isModuleActive} do {
            {
                private _request = _x getVariable ["WaldoEcoResource_CollectRequest", []];
                if (_request isEqualType [] && {(count _request) > 0}) then {
                    [_x, _request] call Waldo_fnc_EcoResource_processCrateCollectRequest;
                };
            } forEach ((allMissionObjects "Land_PlasticCase_01_medium_F") select {
                _x getVariable ["WaldoEcoResource_IsResourceCrate", false]
            });

            uiSleep 0.25;
        };

        missionNamespace setVariable ["WaldoEcoResource_CollectRequestLoopStarted", false];
    };
