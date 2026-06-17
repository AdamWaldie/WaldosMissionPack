/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - startAuthorityLoops
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_startAuthorityLoops via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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
