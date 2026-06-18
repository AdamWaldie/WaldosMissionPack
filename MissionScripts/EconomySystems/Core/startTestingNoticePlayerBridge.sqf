/*
 * Author: Waldo
 * Start testing notice player bridge.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_startTestingNoticePlayerBridge;
 */

    if (missionNamespace getVariable ["WaldoEcoCore_TestingNoticePlayerBridgeStarted", false]) exitWith {};
    missionNamespace setVariable ["WaldoEcoCore_TestingNoticePlayerBridgeStarted", true];

    [] spawn {
        while {[] call Waldo_fnc_EcoCore_isModuleActive} do {
            {
                if (isNull _x) then {continue;};
                [
                    _x,
                    "WaldoEcoCore_TestingNoticeActionAddedLocalV2",
                    call Waldo_fnc_EcoCore_getTestingNoticeActionArgs
                ] call Waldo_fnc_EcoCore_publishPubZeusObjectAction;
            } forEach allPlayers;

            uiSleep 1;
        };

        missionNamespace setVariable ["WaldoEcoCore_TestingNoticePlayerBridgeStarted", false];
    };
