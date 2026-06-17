/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - getBuildStorageRows
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_getBuildStorageRows via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_entry", []]];
        private _rows = _entry param [17, []];
        if (_rows isEqualType [] && {(count _rows) > 0} && {!((_rows select 0) isEqualType [])}) then {
            _rows = [_rows];
        };
        [_rows] call Waldo_fnc_EcoCore_normalizeNameValueRows

