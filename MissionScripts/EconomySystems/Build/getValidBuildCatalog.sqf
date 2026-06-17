/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - getValidBuildCatalog
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_getValidBuildCatalog via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        private _catalog = call Waldo_fnc_EcoBuild_getBuildCatalog;
        _catalog select {
            !([_x, _catalog] call Waldo_fnc_EcoBuild_hasBuildEntryError)
        }

