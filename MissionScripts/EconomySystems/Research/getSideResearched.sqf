/*
 * Author: Waldo
 * Get side researched.
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
 * [_sideKey] call Waldo_fnc_EcoResearch_getSideResearched;
 */

        params ["_sideKey"];

        private _varName = [_sideKey] call Waldo_fnc_EcoResearch_getResearchStateVar;
        if (_varName isEqualTo "") exitWith {[]};
        +(missionNamespace getVariable [_varName, []])

