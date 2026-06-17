/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - populateResourceConfigList
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_populateResourceConfigList via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_disp"];

    if (isNull _disp) exitWith {};

    private _list = _disp getVariable ["WaldoEcoResource_ConfigList", controlNull];
    if (isNull _list) exitWith {};

    lbClear _list;

    {
        private _name = _x param [0, "Resource"];
        private _idx = _list lbAdd _name;
        _list lbSetData [_idx, _name];

        private _icon = _x param [2, ""];
        if (_icon isNotEqualTo "") then {
            _list lbSetPicture [_idx, _icon];
        };

        private _color = [_x param [1, "#FFFFFF"]] call Waldo_fnc_EcoResource_normalizeResourceColor;
        private _rgba = [_color] call Waldo_fnc_EcoResource_colorHexToRGBA;
        _list lbSetColor [_idx, _rgba];
    } forEach (call Waldo_fnc_EcoResource_getResourceCatalog);

    private _selected = _disp getVariable ["WaldoEcoResource_ConfigSelectedIndex", -1];
    if (_selected >= lbSize _list) then {
        _selected = (lbSize _list) - 1;
    };

    if (_selected >= 0) then {
        _list lbSetCurSel _selected;
    } else {
        if ((lbSize _list) > 0) then {
            _list lbSetCurSel 0;
        };
    };
