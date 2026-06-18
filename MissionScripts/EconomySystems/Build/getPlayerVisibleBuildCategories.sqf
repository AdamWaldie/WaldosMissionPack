/*
 * Author: Waldo
 * Get player visible build categories.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (optional, default: "NONE")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_sideKey] call Waldo_fnc_EcoBuild_getPlayerVisibleBuildCategories;
 */

        params [["_sideKey", "NONE"]];

        private _catalog = [_sideKey, "ALL"] call Waldo_fnc_EcoBuild_getPlayerVisibleBuildCatalog;
        private _categories = ["ALL"];

        {
            private _category = [_x param [21, ""]] call Waldo_fnc_EcoCore_trimString;
            if (_category isEqualTo "") then {continue;};
            if ((_categories findIf {(toLower _x) isEqualTo (toLower _category)}) >= 0) then {continue;};
            _categories pushBack _category;
        } forEach _catalog;

        _categories

