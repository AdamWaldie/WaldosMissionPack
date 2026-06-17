/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - purgeResearchRuntimeValues
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_purgeResearchRuntimeValues via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    {
        private _doneVar = [_x] call Waldo_fnc_EcoResearch_getResearchStateVar;
        if (_doneVar isNotEqualTo "") then {
            missionNamespace setVariable [_doneVar, [], true];
        };

        private _activeVar = [_x] call Waldo_fnc_EcoResearch_getResearchActiveVar;
        if (_activeVar isNotEqualTo "") then {
            missionNamespace setVariable [_activeVar, [], true];
        };
    } forEach ["WEST", "EAST", "GUER", "CIV"];
