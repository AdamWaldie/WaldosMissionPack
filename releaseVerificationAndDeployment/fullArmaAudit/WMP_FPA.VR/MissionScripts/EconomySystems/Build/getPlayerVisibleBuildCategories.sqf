/*
 * Author: WaldoTheWarfighter
 * Lists categories represented in the side-visible Construction catalog.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (optional, default: "NONE")
 *
 * Return Value:
 * <ARRAY of STRING> category names.
 *
 * Example:
 * [_sideKey] call Waldo_fnc_EcoBuild_getPlayerVisibleBuildCategories;
 * Locality/Authority: Interface client; read-only catalog grouping.
 * Repeat/JIP Behaviour: Repeat-safe; JIP uses current published catalog.
 * Current Callers: No in-pack caller; available for custom Construction category pickers.
 * Result: Returns each available category once.
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

