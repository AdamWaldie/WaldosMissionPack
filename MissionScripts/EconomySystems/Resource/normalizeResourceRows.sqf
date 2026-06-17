/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - normalizeResourceRows
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_normalizeResourceRows via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_rows", []]];

    private _types = call Waldo_fnc_EcoResource_getResourceTypes;
    private _result = [];

    {
        private _name = [(_x param [0, ""])] call Waldo_fnc_EcoResource_normalizeResourceName;
        private _amount = floor (_x param [1, 0]);
        if (_name isEqualTo "") then {continue;};
        if (_amount <= 0) then {continue;};
        if ((_types find _name) < 0) then {continue;};

        private _existing = _result findIf {((_x param [0, ""]) isEqualTo _name)};
        if (_existing < 0) then {
            _result pushBack [_name, _amount];
        } else {
            _result set [_existing, [_name, ((_result select _existing) param [1, 0]) + _amount]];
        };
    } forEach _rows;

    _result
