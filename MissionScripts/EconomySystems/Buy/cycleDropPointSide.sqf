/*
 * Author: Waldo
 * Cycle drop point side.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 * 1: _delta <SCALAR> - delta (optional, default: 0)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, _delta] call Waldo_fnc_EcoBuy_cycleDropPointSide;
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

