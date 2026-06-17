/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - refreshDropPointType
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_refreshDropPointType via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_disp", displayNull]];

        if (isNull _disp) exitWith {};

        private _choices = call Waldo_fnc_EcoBuy_getDropPointTypeChoices;
        private _count = count _choices;
        if (_count <= 0) exitWith {};

        private _index = _disp getVariable ["WaldoEcoBuy_DropTypeIndex", 2];
        if (_index < 0) then {_index = _count - 1;};
        if (_index >= _count) then {_index = 0;};
        _disp setVariable ["WaldoEcoBuy_DropTypeIndex", _index];

        private _valueCtrl = _disp getVariable ["WaldoEcoBuy_DropTypeValue", controlNull];
        if (!isNull _valueCtrl) then {
            _valueCtrl ctrlSetText (_choices select _index);
            _valueCtrl ctrlCommit 0;
        };

