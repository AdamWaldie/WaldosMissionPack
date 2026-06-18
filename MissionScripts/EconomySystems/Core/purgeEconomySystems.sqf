/*
 * Author: Waldo
 * Purge economy systems.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_purgeEconomySystems;
 */

    if !(canSuspend) exitWith {
        [] spawn {
            [] call Waldo_fnc_EcoCore_purgeEconomySystems;
        };
        true
    };

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {false};

    missionNamespace setVariable ["WaldoEcoCore_ModulePurgeInProgress", true, true];
    missionNamespace setVariable ["WaldoEcoCore_ModuleActive", false, true];
    missionNamespace setVariable ["WaldoEcoCore_ModulePurgedForJIP", true, true];
    missionNamespace setVariable ["WaldoEcoCore_CommitmentModeEnabled", false, true];
    missionNamespace setVariable ["WaldoEcoCore_TestingNoticeEnabled", false, true];
    missionNamespace setVariable ["WaldoEcoCore_TestingNoticeToken", 0, true];

    [] call Waldo_fnc_EcoCore_broadcastUnifiedClientCleanup;

    [
        [true, true, true, true],
        [true, true, true, true]
    ] call Waldo_fnc_EcoCore_executeUnifiedPurge;

    [] call Waldo_fnc_EcoCore_purgeResearchRuntimeValues;
    [] call Waldo_fnc_EcoCore_purgeResourceZones;
    [] call Waldo_fnc_EcoCore_deleteAllTrackedMarkers;
    missionNamespace setVariable ["WaldoEcoResource_ResourceMarkersVisible", true, true];

    private _deadline = time + 3;
    waitUntil {
        uiSleep 0.1;
        private _remaining = call Waldo_fnc_EcoResource_getActiveResourceMarkers;
        if ((count _remaining) > 0) then {
            {
                deleteMarker _x;
            } forEach _remaining;
            missionNamespace setVariable ["WaldoEcoResource_ActiveResourceMarkers", [], true];
        };
        ((count (call Waldo_fnc_EcoResource_getActiveResourceMarkers)) <= 0) || {time >= _deadline}
    };

    [] call Waldo_fnc_EcoCore_broadcastUnifiedClientCleanup;

    WaldoEcoResource_AuthorityLoopsStarted = nil;
    WaldoEcoResource_ZeusHookStarted = nil;
    WaldoEcoResearch_SystemInitialized = nil;
    WaldoEcoResearch_ProgressLoopStarted = nil;
    WaldoEcoResearch_ZeusHookStarted = nil;
    WaldoEcoBuild_SystemInitialized = nil;
    WaldoEcoBuild_ProductionLoopStarted = nil;
    WaldoEcoBuild_ZeusHookStarted = nil;
    WaldoEcoBuy_AuthorityLoopsStarted = nil;
    WaldoEcoBuy_ZeusHookStarted = nil;
    WaldoEcoCore_SaveZeusHookStarted = nil;

    missionNamespace setVariable ["WaldoEcoResource_BootstrapInitialized", false];
    missionNamespace setVariable ["WaldoEcoResource_SystemInitialized", false];
    missionNamespace setVariable ["WaldoEcoResearch_SystemInitialized", false];
    missionNamespace setVariable ["WaldoEcoBuild_SystemInitialized", false];
    missionNamespace setVariable ["WaldoEcoBuy_SystemInitialized", false];
    missionNamespace setVariable ["WaldoEcoCore_ModulePurgeInProgress", false, true];
