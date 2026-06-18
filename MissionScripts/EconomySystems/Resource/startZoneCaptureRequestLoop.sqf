/*
 * Author: Waldo
 * Start zone capture request loop.
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
 * [] call Waldo_fnc_EcoResource_startZoneCaptureRequestLoop;
 */

    if (!([] call Waldo_fnc_EcoCore_canRunBackgroundAuthority)) exitWith {};
    if (missionNamespace getVariable ["WaldoEcoResource_ZoneCaptureRequestLoopStarted", false]) exitWith {};
    missionNamespace setVariable ["WaldoEcoResource_ZoneCaptureRequestLoopStarted", true];

    [] spawn {
        while {[] call Waldo_fnc_EcoCore_isModuleActive} do {
            {
                private _request = _x getVariable ["WaldoEcoResource_ZoneCaptureRequest", []];
                if (_request isEqualType [] && {(count _request) > 0}) then {
                    [_x, _request] call Waldo_fnc_EcoResource_processZoneCaptureRequest;
                };
            } forEach allPlayers;

            {
                private _anchor = _x param [10, objNull];
                if (!isNull _anchor) then {
                    private _request = _anchor getVariable ["WaldoEcoResource_ZoneCaptureRequest", []];
                    if (_request isEqualType [] && {(count _request) > 0}) then {
                        [_anchor, _request] call Waldo_fnc_EcoResource_processZoneCaptureRequest;
                    };
                };
            } forEach (call Waldo_fnc_EcoResource_getResourceZones);

            uiSleep 0.25;
        };

        missionNamespace setVariable ["WaldoEcoResource_ZoneCaptureRequestLoopStarted", false];
    };
