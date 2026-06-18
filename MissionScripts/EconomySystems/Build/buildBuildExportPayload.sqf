/*
 * Author: Waldo
 * Build build export payload.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _includeBuilt <BOOL> - include built (optional, default: false)
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_includeBuilt] call Waldo_fnc_EcoBuild_buildBuildExportPayload;
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

