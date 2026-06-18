/*
 * Author: Waldo
 * Normalize resource name.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _name <STRING> - name (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_name] call Waldo_fnc_EcoResource_normalizeResourceName;
 */

    params [["_name", ""]];

    private _safeName = if (_name isEqualType "") then {_name} else {str _name};
    if (_safeName isEqualTo "") exitWith {""};
    _safeName
