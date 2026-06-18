/*
 * Author: Waldo
 * Normalize research entry.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _entry <ARRAY> - entry (optional, default: [])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_entry] call Waldo_fnc_EcoResearch_normalizeResearchEntry;
 */

        params [["_entry", []]];

        private _name = [(_entry param [0, ""])] call Waldo_fnc_EcoCore_trimString;
        if (_name isEqualTo "") exitWith {[]};

        private _desc = [(_entry param [1, ""])] call Waldo_fnc_EcoCore_trimString;
        private _costs = [(_entry param [2, []])] call Waldo_fnc_EcoCore_normalizeNameValueRows;
        private _requirements = [(_entry param [3, []])] call Waldo_fnc_EcoCore_normalizeNameList;
        private _timeSeconds = 1 max (floor (_entry param [4, 60]));
        private _icon = [_entry param [5, call Waldo_fnc_EcoResource_getDefaultResourceIcon]] call Waldo_fnc_EcoCore_trimString;
        private _color = [(_entry param [6, call Waldo_fnc_EcoResource_getDefaultResourceColor])] call Waldo_fnc_EcoResource_normalizeResourceColor;
        private _researched = _entry param [7, false];
        private _exclusiveWith = [(_entry param [8, []])] call Waldo_fnc_EcoResearch_normalizeResearchExclusives;
        if !(_researched isEqualType true) then {
            _researched = false;
        };

        [_name, _desc, _costs, _requirements, _timeSeconds, _icon, _color, _researched, _exclusiveWith]

