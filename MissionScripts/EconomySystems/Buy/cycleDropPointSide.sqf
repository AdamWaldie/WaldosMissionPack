/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - cycleDropPointSide
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_cycleDropPointSide via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_disp", displayNull], ["_delta", 0]];

        if (isNull _disp) exitWith {};

        private _choices = call Waldo_fnc_EcoBuy_getDropPointSideChoices;
        private _count = count _choices;
        if (_count <= 0) exitWith {};

        private _index = _disp getVariable ["WaldoEcoBuy_DropSideIndex", 0];
        _index = (_index + _delta) mod _count;
        if (_index < 0) then {_index = _index + _count;};
        _disp setVariable ["WaldoEcoBuy_DropSideIndex", _index];
        [_disp] call Waldo_fnc_EcoBuy_refreshDropPointSide;

