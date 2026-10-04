/*
 * Author: WaldoTheWarfighter
 * Convert user-facing side names into supported build-availability keys.
 *
 * Locality / Authority: Pure helper; usable by the editor or authoritative catalog code.
 * Repeat/JIP: Deterministic, with no published state or side effects.
 * Current Callers: EcoBuild_isBuildAvailableForSide,
 * EcoBuild_loadBuildIntoPrompt and EcoBuild_normalizeBuildEntry.
 *
 * Arguments:
 * 0: _rows <ARRAY> - rows (optional, default: ["ALL"])
 *
 * Return Value:
 * ARRAY of STRING - canonical side keys or ["ALL"].
 * Result: Empty or unsupported selections fall back to ALL.
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

