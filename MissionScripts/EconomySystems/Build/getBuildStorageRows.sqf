/*
 * Author: WaldoTheWarfighter
 * Normalizes a build definition's resource-storage bonus rows.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _entry <ARRAY> - entry (optional, default: [])
 *
 * Return Value:
 * <ARRAY> normalized [resource, capacity] rows.
 *
 * Example:
 * [_entry] call Waldo_fnc_EcoBuild_getBuildStorageRows;
 * Locality/Authority: Any machine; transforms catalog data only.
 * Repeat/JIP Behaviour: Deterministic for the same entry; no JIP effect.
 * Current Callers: Building effect and resource-capacity calculations.
 * Result: A single legacy row is wrapped before normalizing all names and values.
 */

        params [["_entry", []]];
        private _rows = _entry param [17, []];
        if (_rows isEqualType [] && {(count _rows) > 0} && {!((_rows select 0) isEqualType [])}) then {
            _rows = [_rows];
        };
        [_rows] call Waldo_fnc_EcoCore_normalizeNameValueRows

