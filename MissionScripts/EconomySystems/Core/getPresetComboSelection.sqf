/*
 * Author: Waldo
 * Get preset combo selection.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _combo <ANY> - combo (optional, default: controlNull)
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_combo] call Waldo_fnc_EcoCore_getPresetComboSelection;
 */

    params [["_combo", controlNull]];

    if (isNull _combo) exitWith {""};
    private _index = lbCurSel _combo;
    if (_index < 0) exitWith {""};
    _combo lbData _index
