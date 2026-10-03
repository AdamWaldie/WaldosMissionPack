/*
 * Author: WaldoTheWarfighter
 * Filters the Construction catalog to entries visible to a side/category.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (optional, default: "NONE")
 * 1: _categoryFilter <STRING> - category filter (optional, default: "ALL")
 *
 * Return Value:
 * <ARRAY> visible build rows.
 *
 * Example:
 * [_sideKey, _categoryFilter] call Waldo_fnc_EcoBuild_getPlayerVisibleBuildCatalog;
 * Locality/Authority: Interface client; read-only filtering of the published catalog.
 * Repeat/JIP Behaviour: Repeat-safe; JIP uses current catalog state.
 * Current Callers: EcoBuild_getPlayerVisibleBuildCategories; available to custom pickers.
 * Result: Entries outside the requested category or side are omitted.
 */

        params [["_sideKey", "NONE"], ["_categoryFilter", "ALL"]];

        private _catalog = (call Waldo_fnc_EcoBuild_getValidBuildCatalog) select {
            [_x, _sideKey] call Waldo_fnc_EcoBuild_isBuildAvailableForSide
        };

        if (_categoryFilter in ["", "ALL"]) exitWith {_catalog};

        _catalog select {
            (toLower (_x param [21, ""])) isEqualTo (toLower _categoryFilter)
        }

