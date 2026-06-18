/*
 * Author: Waldo
 * Set build catalog local.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _catalog <ARRAY> - catalog (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_catalog] call Waldo_fnc_EcoBuild_setBuildCatalogLocal;
 */

        params [["_catalog", []]];
        missionNamespace setVariable ["WaldoEcoBuild_BuildCatalog", [_catalog] call Waldo_fnc_EcoBuild_normalizeBuildCatalog];

