/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - getPlayerConstructionAimPos
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_getPlayerConstructionAimPos via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        private _pos = screenToWorld [0.5, 0.5];
        if ((count _pos) < 3) then {
            _pos = [_pos select 0, _pos select 1, 0];
        };
        _pos set [2, 0 max (_pos select 2)];
        _pos

