/*
 * Author: Waldo
 * Start authority loops.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EcoBuy_startAuthorityLoops;
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

