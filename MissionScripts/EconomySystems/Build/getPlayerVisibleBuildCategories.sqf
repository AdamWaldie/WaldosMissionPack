/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - getPlayerVisibleBuildCategories
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_getPlayerVisibleBuildCategories via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

