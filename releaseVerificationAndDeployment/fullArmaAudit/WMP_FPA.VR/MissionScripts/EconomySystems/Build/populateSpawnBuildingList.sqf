/*
 * Author: WaldoTheWarfighter
 * Lists valid build definitions in the curator building-spawn prompt.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _disp <DISPLAY> - spawn prompt
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoBuild_populateSpawnBuildingList;
 * Locality/Authority: Curator interface client; reads published catalog.
 * Repeat/JIP Behaviour: Repeat-safe redraw; no JIP UI state.
 * Current Callers: Building-spawn prompt open and filter controls.
 * Result: Invalid definitions are excluded from the selectable list.
 */

        params ["_disp"];

        if (isNull _disp) exitWith {};

        private _list = _disp getVariable ["WaldoEcoBuild_SpawnList", controlNull];
        if (isNull _list) exitWith {};

        lbClear _list;

        private _catalog = call Waldo_fnc_EcoBuild_getValidBuildCatalog;
        {
            private _index = _list lbAdd (_x param [0, "Buildable"]);
            _list lbSetData [_index, _x param [0, "Buildable"]];
            _list lbSetPicture [_index, _x param [5, ""]];
            _list lbSetColor [_index, [1, 1, 1, 1]];
        } forEach _catalog;

        private _selected = _disp getVariable ["WaldoEcoBuild_SpawnSelectedIndex", 0];
        if (_selected < 0) then {_selected = 0;};
        if (_selected >= count _catalog) then {_selected = (count _catalog) - 1;};

        if (_selected >= 0) then {
            _list lbSetCurSel _selected;
        };

