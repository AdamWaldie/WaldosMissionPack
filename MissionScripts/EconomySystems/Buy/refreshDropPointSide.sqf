/*
 * Author: Waldo
 * Refresh drop point side.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoBuy_refreshDropPointSide;
 */

        params [["_disp", displayNull]];

        if (isNull _disp) exitWith {};

        private _choices = call Waldo_fnc_EcoBuy_getDropPointSideChoices;
        private _count = count _choices;
        if (_count <= 0) exitWith {};

        private _index = _disp getVariable ["WaldoEcoBuy_DropSideIndex", 0];
        if (_index < 0) then {_index = _count - 1;};
        if (_index >= _count) then {_index = 0;};
        _disp setVariable ["WaldoEcoBuy_DropSideIndex", _index];

        private _valueCtrl = _disp getVariable ["WaldoEcoBuy_DropSideValue", controlNull];
        if (!isNull _valueCtrl) then {
            _valueCtrl ctrlSetText ([(_choices select _index)] call Waldo_fnc_EcoBuy_getDropPointSideLabel);
            _valueCtrl ctrlCommit 0;
        };

