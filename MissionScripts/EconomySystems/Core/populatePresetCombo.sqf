/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - populatePresetCombo
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_populatePresetCombo via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [
        ["_combo", controlNull],
        ["_choices", []],
        ["_selectedKey", ""]
    ];

    if (isNull _combo) exitWith {};

    lbClear _combo;
    private _selectedIndex = 0;

    {
        private _key = _x param [0, ""];
        private _label = _x param [1, _key];
        private _index = _combo lbAdd _label;
        _combo lbSetData [_index, _key];
        if ((toUpper _key) isEqualTo (toUpper _selectedKey)) then {
            _selectedIndex = _index;
        };
    } forEach _choices;

    _combo lbSetCurSel _selectedIndex;
