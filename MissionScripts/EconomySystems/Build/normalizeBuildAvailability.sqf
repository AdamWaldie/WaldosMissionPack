/*
 * Author: Waldo
 * Normalize build availability.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _rows <ARRAY> - rows (optional, default: ["ALL"])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_rows] call Waldo_fnc_EcoBuild_normalizeBuildAvailability;
 */

        params [["_rows", ["ALL"]]];

        private _result = [];
        private _source = _rows;
        if !(_source isEqualType []) then {
            _source = [_source];
        };

        {
            private _value = toUpper ([_x] call Waldo_fnc_EcoCore_trimString);
            if (_value isEqualTo "") then {continue;};
            if (_value in ["ALL", "EVERYONE"]) exitWith {
                _result = ["ALL"];
            };
            if (_value in ["WEST", "BLUFOR"]) then {
                _result pushBackUnique "WEST";
            };
            if (_value in ["EAST", "OPFOR"]) then {
                _result pushBackUnique "EAST";
            };
            if (_value in ["GUER", "INDEP", "INDEPENDENT"]) then {
                _result pushBackUnique "GUER";
            };
        } forEach _source;

        if ((count _result) <= 0) then {
            _result = ["ALL"];
        };

        _result

