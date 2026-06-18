/*
 * Author: Waldo
 * Start authority loops.
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
 * [] call Waldo_fnc_EcoResource_startAuthorityLoops;
 */

    if (!isNil "WaldoEcoResource_AuthorityLoopsStarted") exitWith {};

    private _shouldStart = [] call Waldo_fnc_EcoCore_canRunBackgroundAuthority;
    if (!_shouldStart) exitWith {};

    WaldoEcoResource_AuthorityLoopsStarted = true;

    [] spawn {
        while {[] call Waldo_fnc_EcoCore_isModuleActive} do {
            uiSleep 5;
            call Waldo_fnc_EcoResource_generateZoneResources;
        };
    };

    [] spawn {
        while {[] call Waldo_fnc_EcoCore_isModuleActive} do {
            uiSleep 5;
            call Waldo_fnc_EcoCommand_pruneGroundCommandUIDs;
        };
    };
