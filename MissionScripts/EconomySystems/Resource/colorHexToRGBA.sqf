/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - colorHexToRGBA
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_colorHexToRGBA via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_hex", "#FFFFFF"], ["_alpha", 1]];

    private _safeHex = [_hex] call Waldo_fnc_EcoResource_normalizeResourceColor;
    private _raw = _safeHex select [1, 6];
    if ((count _raw) isNotEqualTo 6) exitWith {[1, 1, 1, _alpha]};

    private _chars = toArray _raw;
    private _digitValue = {
        params [["_code", 48]];
        if (_code >= 48 && {_code <= 57}) exitWith {_code - 48};
        if (_code >= 65 && {_code <= 70}) exitWith {_code - 55};
        0
    };

    private _pairToFloat = {
        params ["_codes"];
        ((([_codes select 0] call _digitValue) * 16) + ([_codes select 1] call _digitValue)) / 255
    };

    [
        [(_chars select [0, 2])] call _pairToFloat,
        [(_chars select [2, 2])] call _pairToFloat,
        [(_chars select [4, 2])] call _pairToFloat,
        _alpha
    ]
