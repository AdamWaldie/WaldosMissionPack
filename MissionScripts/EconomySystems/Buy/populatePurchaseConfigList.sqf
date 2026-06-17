/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - populatePurchaseConfigList
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_populatePurchaseConfigList via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_disp", displayNull]];

        if (isNull _disp) exitWith {};

        private _list = _disp getVariable ["WaldoEcoBuy_ConfigList", controlNull];
        if (isNull _list) exitWith {};

        lbClear _list;

        private _catalog = call Waldo_fnc_EcoBuy_getPurchaseCatalog;
        {
            private _entry = _x;
            private _index = _list lbAdd (_entry param [0, "Purchase"]);
            _list lbSetData [_index, _entry param [0, "Purchase"]];
            _list lbSetPicture [_index, _entry param [7, ""]];
            _list lbSetTextRight [_index, _entry param [5, "Ground"]];
            if ([_entry, _catalog] call Waldo_fnc_EcoBuy_hasPurchaseEntryError) then {
                _list lbSetColor [_index, [1, 0.25, 0.25, 1]];
            };
        } forEach _catalog;

        private _selected = _disp getVariable ["WaldoEcoBuy_ConfigSelectedIndex", -1];
        if (_selected >= count _catalog) then {
            _selected = (count _catalog) - 1;
        };

        if (_selected >= 0) then {
            _list lbSetCurSel _selected;
        };

