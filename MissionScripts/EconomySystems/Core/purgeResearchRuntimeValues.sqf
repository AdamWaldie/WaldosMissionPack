/*
 * Author: Waldo
 * Purge research runtime values.
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
 * [] call Waldo_fnc_EcoCore_purgeResearchRuntimeValues;
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
