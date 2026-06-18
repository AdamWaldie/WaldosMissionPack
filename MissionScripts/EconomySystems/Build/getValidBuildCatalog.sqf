/*
 * Author: Waldo
 * Get valid build catalog.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [] call Waldo_fnc_EcoBuild_getValidBuildCatalog;
 */

        private _catalog = call Waldo_fnc_EcoBuild_getBuildCatalog;
        _catalog select {
            !([_x, _catalog] call Waldo_fnc_EcoBuild_hasBuildEntryError)
        }

