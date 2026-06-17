/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - populateBuildConfigList
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_populateBuildConfigList via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_disp"];

        if (isNull _disp) exitWith {};

        private _list = _disp getVariable ["WaldoEcoBuild_ConfigList", controlNull];
        if (isNull _list) exitWith {};

        lbClear _list;

        private _catalog = call Waldo_fnc_EcoBuild_getBuildCatalog;
        {
            private _entry = _x;
            private _index = _list lbAdd (_entry param [0, "Buildable"]);
            _list lbSetData [_index, _entry param [0, "Buildable"]];
            _list lbSetPicture [_index, _entry param [5, ""]];
            if ([_entry, _catalog] call Waldo_fnc_EcoBuild_hasBuildEntryError) then {
                _list lbSetColor [_index, [1, 0.25, 0.25, 1]];
            };
        } forEach _catalog;

        private _selected = _disp getVariable ["WaldoEcoBuild_ConfigSelectedIndex", -1];
        if (_selected >= count _catalog) then {
            _selected = (count _catalog) - 1;
        };

        if (_selected >= 0) then {
            _list lbSetCurSel _selected;
        };

