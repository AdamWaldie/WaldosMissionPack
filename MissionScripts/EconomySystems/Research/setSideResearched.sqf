/*
 * Author: Waldo
 * Set side researched.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _sideKey <ANY> - side key
 * 1: _rows <ARRAY> - rows (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_sideKey, _rows] call Waldo_fnc_EcoResearch_setSideResearched;
 */

        params ["_sideKey", ["_rows", []]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

        private _varName = [_sideKey] call Waldo_fnc_EcoResearch_getResearchStateVar;
        if (_varName isEqualTo "") exitWith {};

        private _clean = [];
        {
            private _name = [_x] call Waldo_fnc_EcoCore_trimString;
            if (_name isEqualTo "") then {continue;};
            if ((_clean findIf {(toLower _x) isEqualTo (toLower _name)}) >= 0) then {continue;};
            _clean pushBack _name;
        } forEach _rows;

        missionNamespace setVariable [_varName, _clean, true];

