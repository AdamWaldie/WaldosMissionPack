/*
 * Author: Waldo
 * Get build storage rows.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _entry <ARRAY> - entry (optional, default: [])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_entry] call Waldo_fnc_EcoBuild_getBuildStorageRows;
 */

        params [["_entry", []]];
        private _rows = _entry param [17, []];
        if (_rows isEqualType [] && {(count _rows) > 0} && {!((_rows select 0) isEqualType [])}) then {
            _rows = [_rows];
        };
        [_rows] call Waldo_fnc_EcoCore_normalizeNameValueRows

