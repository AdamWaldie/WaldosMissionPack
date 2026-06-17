/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - getPresetComboSelection
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_getPresetComboSelection via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_combo", controlNull]];

    if (isNull _combo) exitWith {""};
    private _index = lbCurSel _combo;
    if (_index < 0) exitWith {""};
    _combo lbData _index
