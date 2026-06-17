/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - populateResearchConfigList
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_populateResearchConfigList via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_disp"];

        if (isNull _disp) exitWith {};

        private _list = _disp getVariable ["WaldoEcoResearch_ConfigList", controlNull];
        if (isNull _list) exitWith {};

        lbClear _list;

        {
            private _row = _x;
            private _index = _list lbAdd (_row param [0, "Research"]);
            _list lbSetData [_index, _row param [0, "Research"]];
            _list lbSetPicture [_index, _row param [5, ""]];
            if ([_row, call Waldo_fnc_EcoResearch_getResearchCatalog] call Waldo_fnc_EcoResearch_hasResearchEntryError) then {
                _list lbSetColor [_index, [1, 0.25, 0.25, 1]];
            };
            if (_row param [7, false]) then {
                _list lbSetTextRight [_index, "DONE"];
            };
        } forEach (call Waldo_fnc_EcoResearch_getResearchCatalog);

        private _selected = _disp getVariable ["WaldoEcoResearch_ConfigSelectedIndex", -1];
        if (_selected >= count (call Waldo_fnc_EcoResearch_getResearchCatalog)) then {
            _selected = (count (call Waldo_fnc_EcoResearch_getResearchCatalog)) - 1;
        };

        if (_selected >= 0) then {
            _list lbSetCurSel _selected;
        };

