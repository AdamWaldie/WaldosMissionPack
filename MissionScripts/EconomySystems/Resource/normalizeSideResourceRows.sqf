/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - normalizeSideResourceRows
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_normalizeSideResourceRows via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_rows", "_types"];

    private _normalized = [];

    {
        private _typeName = _x;
        private _existingIndex = _rows findIf {
            ((_x param [0, ""]) isEqualTo _typeName)
        };

        private _value = 0;
        if (_existingIndex >= 0) then {
            _value = (_rows select _existingIndex) param [1, 0];
        };

        _normalized pushBack [_typeName, 0 max (floor _value)];
    } forEach _types;

    _normalized
