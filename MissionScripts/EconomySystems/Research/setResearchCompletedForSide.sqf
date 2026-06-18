/*
 * Author: Waldo
 * Set research completed for side.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _sideKey <ANY> - side key
 * 1: _researchName <ANY> - research name
 * 2: _completed <BOOL> - completed (optional, default: true)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_sideKey, _researchName, _completed] call Waldo_fnc_EcoResearch_setResearchCompletedForSide;
 */

        params ["_sideKey", "_researchName", ["_completed", true]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

        private _rows = [_sideKey] call Waldo_fnc_EcoResearch_getSideResearched;
        private _name = [_researchName] call Waldo_fnc_EcoCore_trimString;
        if (_name isEqualTo "") exitWith {};

        private _index = _rows findIf {(toLower _x) isEqualTo (toLower _name)};
        if (_completed) then {
            if (_index < 0) then {
                _rows pushBack _name;
            };
        } else {
            if (_index >= 0) then {
                _rows deleteAt _index;
            };
        };

        [_sideKey, _rows] call Waldo_fnc_EcoResearch_setSideResearched;

