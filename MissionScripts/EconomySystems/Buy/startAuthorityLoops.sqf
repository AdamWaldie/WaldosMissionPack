/*
 * Author: WaldoTheWarfighter
 * Starts the Purchasing subsystem's authority-side maintenance loops once.
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
 * Locality/Authority: Economy authority only; clients consume published purchase state.
 * Repeat/JIP Behaviour: Startup guard prevents duplicate loops; public state supports JIP.
 * Current Callers: Economy initialization.
 * Result: Purchase housekeeping continues while Economy is active.
 */

        if (!isNil "WaldoEcoBuy_AuthorityLoopsStarted") exitWith {};

        private _shouldStart = [] call Waldo_fnc_EcoCore_canRunBackgroundAuthority;
        if (!_shouldStart) exitWith {};

        WaldoEcoBuy_AuthorityLoopsStarted = true;

        [] spawn {
            while {[] call Waldo_fnc_EcoCore_isModuleActive} do {
                uiSleep 5;
                call Waldo_fnc_EcoBuy_syncDropPoints;
            };
        };

