/*
 * Author: Waldo
 * Refresh purchase config type.
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
 * [_disp] call Waldo_fnc_EcoBuy_refreshPurchaseConfigType;
 */

        params [["_disp", displayNull]];

        if (isNull _disp) exitWith {};

        private _choices = call Waldo_fnc_EcoBuy_getPurchaseTypeChoices;
        private _count = count _choices;
        if (_count <= 0) exitWith {};

        private _index = _disp getVariable ["WaldoEcoBuy_ConfigTypeIndex", 0];
        if (_index < 0) then {_index = _count - 1;};
        if (_index >= _count) then {_index = 0;};
        _disp setVariable ["WaldoEcoBuy_ConfigTypeIndex", _index];

        private _valueCtrl = _disp getVariable ["WaldoEcoBuy_ConfigTypeValue", controlNull];
        if (!isNull _valueCtrl) then {
            _valueCtrl ctrlSetText (_choices select _index);
            _valueCtrl ctrlCommit 0;
        };

