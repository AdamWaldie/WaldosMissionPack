/*
 * Author: Waldo
 * Select resource settings side.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp
 * 1: _sideKey <ANY> - side key
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, _sideKey] call Waldo_fnc_EcoResource_selectResourceSettingsSide;
 */

    params ["_disp", "_sideKey"];

    if (isNull _disp) exitWith {};

    private _upperKey = toUpper _sideKey;
    _disp setVariable ["WaldoEcoResource_SettingsSelectedSide", _upperKey];

    {
        private _button = _disp getVariable [_x select 0, controlNull];
        if (!isNull _button) then {
            if ((_x select 1) isEqualTo _upperKey) then {
                _button ctrlSetBackgroundColor [0.2, 0.6, 0.9, 0.85];
            } else {
                _button ctrlSetBackgroundColor [0, 0, 0, 0.6];
            };
            _button ctrlCommit 0;
        };
    } forEach [
        ["WaldoEcoResource_SettingsBLUFOR", "WEST"],
        ["WaldoEcoResource_SettingsOPFOR", "EAST"],
        ["WaldoEcoResource_SettingsINDFOR", "GUER"]
    ];

    [_disp] call Waldo_fnc_EcoResource_refreshResourceSettings;
