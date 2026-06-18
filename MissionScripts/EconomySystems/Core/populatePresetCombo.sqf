/*
 * Author: Waldo
 * Populate preset combo.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _combo <ANY> - combo (optional, default: controlNull)
 * 1: _choices <ARRAY> - choices (optional, default: [])
 * 2: _selectedKey <STRING> - selected key (optional, default: "")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_combo, _choices, _selectedKey] call Waldo_fnc_EcoCore_populatePresetCombo;
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
