/*
 * Author: Waldo
 * Start zeus menu hook.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Runs the single shared client-side loop that detects the Zeus curator display opening
 * and, on each open transition, spawns every injector registered via
 * Waldo_fnc_EcoCore_registerZeusMenuInjector. This replaces the previous design where
 * each subsystem (Resource / Research / Build / Buy / Core-Save) ran its own identical
 * Zeus-open polling loop - collapsing up to five per-client mission-long loops into one.
 * Idempotent: the loop starts at most once per client.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_startZeusMenuHook;
 */

    if (!hasInterface) exitWith {};
    if (!isNil "WaldoEcoCore_ZeusMenuHookStarted") exitWith {};
    WaldoEcoCore_ZeusMenuHookStarted = true;

    [] spawn {
        private _wasOpen = false;

        while {[] call Waldo_fnc_EcoCore_isModuleActive} do {
            private _disp = call Waldo_fnc_EcoCore_getZeusDisplay;
            private _isOpen = !isNull _disp;

            if (_isOpen && !_wasOpen) then {
                _wasOpen = true;

                // Each injector re-fetches the display, settles, and guards against
                // double-injection via its own <system>_MenuInjected display variable,
                // so spawning them per open transition mirrors the old per-loop behaviour.
                {
                    [] spawn _x;
                } forEach (missionNamespace getVariable ["WaldoEcoCore_ZeusMenuInjectors", []]);
            };

            if (!_isOpen && _wasOpen) then {
                _wasOpen = false;
            };

            uiSleep 0.5; // poll back-off (perf): detect Zeus open within 0.5s
        };

        WaldoEcoCore_ZeusMenuHookStarted = nil;
    };
