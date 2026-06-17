/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - getPlayerVisibleBuildCatalog
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_getPlayerVisibleBuildCatalog via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_sideKey", "NONE"], ["_categoryFilter", "ALL"]];

        private _catalog = (call Waldo_fnc_EcoBuild_getValidBuildCatalog) select {
            [_x, _sideKey] call Waldo_fnc_EcoBuild_isBuildAvailableForSide
        };

        if (_categoryFilter in ["", "ALL"]) exitWith {_catalog};

        _catalog select {
            (toLower (_x param [21, ""])) isEqualTo (toLower _categoryFilter)
        }

