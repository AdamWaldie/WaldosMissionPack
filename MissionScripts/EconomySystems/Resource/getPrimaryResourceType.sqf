/*
 * Author: Waldo
 * Get primary resource type.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _rows <ARRAY> - rows (optional, default: [])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_rows] call Waldo_fnc_EcoResource_getPrimaryResourceType;
 */

    params [["_rows", []]];
    if ((count _rows) <= 0) exitWith {"Resource"};
    (_rows select 0) param [0, "Resource"]
