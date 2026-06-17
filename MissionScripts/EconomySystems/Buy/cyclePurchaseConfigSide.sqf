/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - cyclePurchaseConfigSide
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_cyclePurchaseConfigSide via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_disp", displayNull], ["_delta", 0]];

        if (isNull _disp) exitWith {};

        private _choices = call Waldo_fnc_EcoBuy_getPurchaseSideChoices;
        private _count = count _choices;
        if (_count <= 0) exitWith {};

        private _index = _disp getVariable ["WaldoEcoBuy_ConfigSideIndex", 0];
        _index = (_index + _delta) mod _count;
        if (_index < 0) then {_index = _index + _count;};
        _disp setVariable ["WaldoEcoBuy_ConfigSideIndex", _index];
        [_disp] call Waldo_fnc_EcoBuy_refreshPurchaseConfigSide;

