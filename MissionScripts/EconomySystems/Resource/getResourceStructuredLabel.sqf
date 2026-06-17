/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getResourceStructuredLabel
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getResourceStructuredLabel via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_resourceType", ["_includeIcon", false], ["_amount", -1], ["_capacity", -2]];

    private _def = [_resourceType] call Waldo_fnc_EcoResource_getResourceDefinition;
    private _name = if ((count _def) > 0) then {_def param [0, _resourceType]} else {_resourceType};
    private _color = if ((count _def) > 1) then {_def param [1, "#FFFFFF"]} else {"#FFFFFF"};
    private _icon = if ((count _def) > 2) then {_def param [2, ""]} else {""};
    if (_includeIcon) then {
        _icon = [_icon] call Waldo_fnc_EcoResource_getRenderableResourceIcon;
    };

    private _text = if (_amount >= 0) then {
        if (_capacity >= 0) then {
            format ["%1: %2 / %3", _name, _amount, _capacity]
        } else {
            format ["%1: %2", _name, _amount]
        }
    } else {
        _name
    };

    if (_includeIcon && {_icon isNotEqualTo ""}) then {
        format ["<img image='%1' size='1'/> <t color='%2'>%3</t>", _icon, _color, _text]
    } else {
        format ["<t color='%1'>%2</t>", _color, _text]
    }
