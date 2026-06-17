/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - startAuthorityLoops
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_startAuthorityLoops via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        if (!isNil "WaldoEcoBuy_AuthorityLoopsStarted") exitWith {};

        private _shouldStart = [] call Waldo_fnc_EcoCore_canRunBackgroundAuthority;
        if (!_shouldStart) exitWith {};

        WaldoEcoBuy_AuthorityLoopsStarted = true;

        [] spawn {
            while {[] call Waldo_fnc_EcoCore_isModuleActive} do {
                uiSleep 5;
                call Waldo_fnc_EcoBuy_syncDropPoints;

                if (!isNil "Waldo_fnc_EcoBuy_ensurePurchaseTerminalActionLocal") then {
                    {
                        [_x] call Waldo_fnc_EcoBuy_ensurePurchaseTerminalActionLocal;
                    } forEach ((allMissionObjects "Land_Laptop_unfolded_F") select {
                        _x getVariable ["WaldoEcoBuy_IsPurchaseTerminal", false]
                    });
                };
            };
        };

