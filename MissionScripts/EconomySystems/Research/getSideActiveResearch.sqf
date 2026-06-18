/*
 * Author: Waldo
 * Get side active research.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _sideKey <ANY> - side key
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_sideKey] call Waldo_fnc_EcoResearch_getSideActiveResearch;
 */

        params ["_sideKey"];

        private _varName = [_sideKey] call Waldo_fnc_EcoResearch_getResearchActiveVar;
        if (_varName isEqualTo "") exitWith {[]};
        +(missionNamespace getVariable [_varName, []])

