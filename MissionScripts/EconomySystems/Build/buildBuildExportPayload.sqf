/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - buildBuildExportPayload
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_buildBuildExportPayload via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_includeBuilt", false]];

        private _catalog = call Waldo_fnc_EcoBuild_getBuildCatalog;
        private _payloadCatalog = [];

        {
            private _entry = +_x;
            _entry set [7, false];
            _payloadCatalog pushBack _entry;
        } forEach _catalog;

        str ["WaldoEcoBuild_BUILD_V3", false, _payloadCatalog]

