/*
 * Author: Waldo
 * Set side active research.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _sideKey <ANY> - side key
 * 1: _row <ARRAY> - row (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_sideKey, _row] call Waldo_fnc_EcoResearch_setSideActiveResearch;
 */

        params ["_sideKey", ["_row", []]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

        private _varName = [_sideKey] call Waldo_fnc_EcoResearch_getResearchActiveVar;
        if (_varName isEqualTo "") exitWith {};

        missionNamespace setVariable [_varName, _row, true];

