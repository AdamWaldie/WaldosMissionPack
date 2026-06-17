/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - isResearchExclusiveBlocked
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_isResearchExclusiveBlocked via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_sideKey", "_entry"];

        private _blocked = false;
        {
            if ([_sideKey, _x] call Waldo_fnc_EcoResearch_isResearchCompletedForSide) exitWith {
                _blocked = true;
            };
        } forEach (_entry param [8, []]);

        _blocked

