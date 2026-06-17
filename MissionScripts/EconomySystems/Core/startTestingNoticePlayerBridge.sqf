/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - startTestingNoticePlayerBridge
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_startTestingNoticePlayerBridge via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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
