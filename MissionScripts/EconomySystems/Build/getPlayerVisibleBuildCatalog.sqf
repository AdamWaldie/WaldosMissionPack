/*
 * Author: Waldo
 * Get player visible build catalog.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (optional, default: "NONE")
 * 1: _categoryFilter <STRING> - category filter (optional, default: "ALL")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_sideKey, _categoryFilter] call Waldo_fnc_EcoBuild_getPlayerVisibleBuildCatalog;
 */

        params [["_sideKey", "NONE"], ["_categoryFilter", "ALL"]];

        private _catalog = (call Waldo_fnc_EcoBuild_getValidBuildCatalog) select {
            [_x, _sideKey] call Waldo_fnc_EcoBuild_isBuildAvailableForSide
        };

        if (_categoryFilter in ["", "ALL"]) exitWith {_catalog};

        _catalog select {
            (toLower (_x param [21, ""])) isEqualTo (toLower _categoryFilter)
        }

